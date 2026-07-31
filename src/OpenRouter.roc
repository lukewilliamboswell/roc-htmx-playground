import pf.Http
import http.Request
import http.Response

import AiPrompts
import AiStore
import AppConfig
import Base64
import BusinessCard

OpenRouter := [].{
	endpoint : Str
	endpoint = "https://openrouter.ai/api/v1/chat/completions"

	extract_business_card! : AppConfig.OpenRouter, List(U8) => Try(BusinessCard.Result, BusinessCard.Error)
	extract_business_card! = |provider, image| {
		request_body = business_card_request(provider.model, image)
		request = Request.from_method(POST)
			.with_uri(endpoint)
			.add_header("Authorization", "Bearer ${provider.apiKey}")
			.add_header("Content-Type", "application/json")
			.add_header("X-OpenRouter-Title", "Enquiry CRM business card scanner")
			.with_body(request_body.to_utf8())
		http_config = Http.with_max_response_bytes(
			Http.with_timeout_millis(Http.default_config, 45_000),
			256 * 1024,
		)
		response = Http.send_with!(request, http_config)
			? |_| BusinessCard.Error.Transport
		status = Response.status(response)
		if status < 200 or status >= 300 {
			return Err(BusinessCard.Error.Provider(status))
		}
		body = Str.from_utf8(Response.body(response))
			? |_| BusinessCard.Error.InvalidResponse
		decoded : OpenRouterResponse
		decoded = Json.parse(body)
			? |_| BusinessCard.Error.InvalidResponse
		choice = decoded.choices.first()
			? |_| BusinessCard.Error.InvalidResponse
		match choice.message.refusal {
			Ok(Ok(value)) if !value.trim().is_empty() =>
				return Err(BusinessCard.Error.Refused)
			_ => {}
		}
		content = match choice.message.content {
			Ok(value) if !value.trim().is_empty() => value
			_ => return Err(BusinessCard.Error.InvalidResponse)
		}
		contact = BusinessCard.from_json(content)?
		reasoning_tokens = match decoded.usage.completion_tokens_details {
			Ok(details) => optional_i64(details.reasoning_tokens)
			Err(Missing) => -1
		}
		cached_tokens = match decoded.usage.prompt_tokens_details {
			Ok(details) => optional_i64(details.cached_tokens)
			Err(Missing) => -1
		}
		cost_nanos = (decoded.usage.cost * 1_000_000_000).to_i64_try() ?? -1
		Ok(
			BusinessCard.Result.{
				contact,
				providerRequestId: bounded(decoded.id, 200),
				returnedModel: bounded(decoded.model, 200),
				usage: AiStore.Usage.{
					promptTokens: decoded.usage.prompt_tokens,
					completionTokens: decoded.usage.completion_tokens,
					totalTokens: decoded.usage.total_tokens,
					reasoningTokens: reasoning_tokens,
					cachedTokens: cached_tokens,
					costCreditsNanos: cost_nanos,
				},
			},
		)
	}

	business_card_request : Str, List(U8) -> Str
	business_card_request = |model, image| {
		prompt = AiPrompts.business_card
		image_url = "data:image/jpeg;base64,${Base64.encode(image)}"
		(
			\\{
			\\  "model": ${Json.to_str(model)},
			\\  "stream": false,
			\\  "max_completion_tokens": 1500,
			\\  "reasoning": {"effort": "low", "exclude": true},
			\\  "provider": {
			\\    "require_parameters": true,
			\\    "zdr": true,
			\\    "data_collection": "deny"
			\\  },
			\\  "messages": [
			\\    {"role": "system", "content": ${Json.to_str(prompt.system)}},
			\\    {
			\\      "role": "user",
			\\      "content": [
			\\        {"type": "text", "text": ${Json.to_str(prompt.user)}},
			\\        {"type": "image_url", "image_url": {"url": ${Json.to_str(image_url)}}}
			\\      ]
			\\    }
			\\  ],
			\\  "response_format": {
			\\    "type": "json_schema",
			\\    "json_schema": {
			\\      "name": "business_card_contact",
			\\      "strict": true,
			\\      "schema": ${prompt.schema}
			\\    }
			\\  }
			\\}
			,
		)
	}
}

OpenRouterResponse : {
	id : Str,
	model : Str,
	choices : List(
		{
			message : {
				content : Try(Str, [Null]),
				refusal : Try(Try(Str, [Null]), [Missing]),
			},
		},
	),
	usage : {
		prompt_tokens : I64,
		completion_tokens : I64,
		total_tokens : I64,
		cost : F64,
		completion_tokens_details : Try(
			{
				reasoning_tokens : Try(I64, [Missing]),
			},
			[Missing],
		),
		prompt_tokens_details : Try(
			{
				cached_tokens : Try(I64, [Missing]),
			},
			[Missing],
		),
	},
}

optional_i64 : Try(I64, [Missing]) -> I64
optional_i64 = |value|
	match value {
		Ok(found) => found
		Err(Missing) => -1
	}

bounded : Str, U64 -> Str
bounded = |value, maximum|
	Str.from_utf8_lossy(value.trim().to_utf8().take_first(maximum))

expect {
	body = OpenRouter.business_card_request("openai/gpt-5.6-luna", [255, 216, 255])
	body.contains("\"model\": \"openai/gpt-5.6-luna\"")
		and body.contains("\"zdr\": true")
			and body.contains("\"data_collection\": \"deny\"")
				and body.contains("\"effort\": \"low\"")
					and body.contains("data:image/jpeg;base64,/9j/")
						and !body.contains("\"temperature\"")
}
