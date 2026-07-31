import pf.Server
import http.Response

import Actor
import AiPrompts
import AiStore
import AppConfig
import AppError
import BusinessCard
import Company
import CompanyStore
import Http
import OpenRouter
import Person
import PersonHandler
import PersonView

BusinessCardHandler := [].{
	scan! : Server.Request, AiStore, CompanyStore, Actor, AppConfig.OpenRouter, Str => Try(Response, AppError)
	scan! = |request, ai_store, companies, actor, provider, release_id| {
		multipart = match Http.read_multipart!(request) {
			Ok(value) => value
			Err(Http.MultipartError.BodyTooLarge) =>
				return Err(AppError.BadRequest("The upload was too large."))
			Err(_) => return Err(AppError.BadRequest("Malformed business-card upload."))
		}
		form = PersonHandler.form_from_fields(multipart.fields)
		image_parts = multipart.files.keep_if(|file| file.fieldName == "cardImage")
		image = match image_parts {
			[file] => file
			_ =>
				return scanner_error!(
					ai_store,
					companies,
					actor,
					form,
					"Choose exactly one business-card image.",
					422,
				)
			}
		grant_id = multipart.fields.get("scanGrant") ?? ""
		claim = match AiStore.claim!(
			ai_store,
			actor.workspace.id,
			actor.member.id,
			AiPrompts.business_card.featureId,
			AiPrompts.business_card.promptId,
			release_id,
			provider.model,
			grant_id,
			image.data.len().to_i64_try() ?? 0,
		) {
			Ok(value) => value
			Err(AiStore.ClaimError.InvalidGrant) =>
				return scanner_error!(
					ai_store,
					companies,
					actor,
					form,
					"This scanner page expired or was already used. Try again.",
					409,
				)
			Err(AiStore.ClaimError.StoreFailure(error)) =>
				return Err(AppError.from(error))
			}
		if image.data.len() > 6 * 1024 * 1024 {
			AiStore.reject!(ai_store, claim.runId, "image_too_large")
				? AppError.from
			return scanner_error!(
				ai_store,
				companies,
				actor,
				form,
				"The processed image exceeds 6 MiB. Try a closer photo.",
				413,
			)
		}
		if image.contentType != "image/jpeg" or !is_jpeg(image.data) {
			AiStore.reject!(ai_store, claim.runId, "unsupported_image")
				? AppError.from
			return scanner_error!(
				ai_store,
				companies,
				actor,
				form,
				"The scanner accepts the browser-generated JPEG image only.",
				415,
			)
		}
		if multipart.fields.get("imagePrepared") != Ok("yes") {
			AiStore.reject!(ai_store, claim.runId, "image_not_prepared")
				? AppError.from
			return scanner_error!(
				ai_store,
				companies,
				actor,
				form,
				"The image was not privacy-processed in your browser. Enable JavaScript and try again.",
				422,
			)
		}
		match AiStore.begin_provider!(
			ai_store,
			actor.workspace.id,
			actor.member.id,
			claim.runId,
		) {
			Ok({}) => {}
			Err(AiStore.BeginError.MemberRateLimited) =>
				return scanner_error!(
					ai_store,
					companies,
					actor,
					form,
					"You have reached the limit of 30 scans per hour.",
					429,
				)
			Err(AiStore.BeginError.MemberBusy) =>
				return scanner_error!(
					ai_store,
					companies,
					actor,
					form,
					"Another scan is already running for you.",
					429,
				)
			Err(AiStore.BeginError.WorkspaceBusy) =>
				return scanner_error!(
					ai_store,
					companies,
					actor,
					form,
					"The scanner is busy. Try again shortly.",
					429,
				)
			Err(AiStore.BeginError.StoreFailure(error)) =>
				return Err(AppError.from(error))
			}
		extraction = match OpenRouter.extract_business_card!(provider, image.data) {
			Ok(value) => value
			Err(error) => {
				failure = provider_failure(error)
				AiStore.fail!(
					ai_store,
					claim.runId,
					failure.outcome,
					failure.providerStatus,
				) ? AppError.from
				return scanner_error!(
					ai_store,
					companies,
					actor,
					form,
					failure.message,
					failure.status,
				)
			}
		}
		AiStore.succeed!(
			ai_store,
			claim.runId,
			extraction.returnedModel,
			extraction.providerRequestId,
			extraction.usage,
			extraction.contact.quality_permille(),
		) ? AppError.from
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		merged = merge_form(form, extraction.contact, company_list, claim.runId)
		review = {
			company: extraction.contact.company,
			website: extraction.contact.website,
			address: Str.join_with(BusinessCard.address_lines(extraction.contact.address), "\n"),
			confidence: extraction.contact.quality_permille(),
			warnings: extraction.contact.warnings,
		}
		grant = AiStore.issue_grant!(
			ai_store,
			actor.workspace.id,
			actor.member.id,
			AiPrompts.business_card.featureId,
		) ? AppError.from
		PersonHandler.scanner_page!(
			companies,
			actor,
			merged,
			PersonView.Scanner.Ready({
				grantId: grant,
				message: "Contact details extracted. Review every field before saving.",
				error: False,
				review: Review(review),
			}),
			200,
		)
	}
}

scanner_error! : AiStore, CompanyStore, Actor, PersonView.Form, Str, U16 => Try(Response, AppError)
scanner_error! = |ai_store, companies, actor, form, message, status| {
	grant = AiStore.issue_grant!(
		ai_store,
		actor.workspace.id,
		actor.member.id,
		AiPrompts.business_card.featureId,
	) ? AppError.from
	PersonHandler.scanner_page!(
		companies,
		actor,
		form,
		PersonView.Scanner.Ready({
			grantId: grant,
			message,
			error: True,
			review: NoReview,
		}),
		status,
	)
}

is_jpeg : List(U8) -> Bool
is_jpeg = |bytes|
	match bytes {
		[255, 216, 255, ..] => True
		_ => False
	}

merge_form : PersonView.Form, BusinessCard, List(Company), Str -> PersonView.Form
merge_form = |form, card, companies, run_id| {
	extracted_name = if !card.fullName.is_empty() {
		card.fullName
	} else {
		Str.join_with(
			[card.firstName, card.lastName].keep_if(|value| !value.is_empty()),
			" ",
		)
	}
	{
		..form,
		name: prefer_existing(form.name, extracted_name),
		jobTitle: prefer_existing(form.jobTitle, card.jobTitle),
		company: if form.company.is_empty() {
			matched_company(card, companies)
		} else {
			form.company
		},
		emails: padded_strings(
			merge_strings(form.emails, card.emails),
			5,
		),
		phones: padded_phones(
			merge_phones(
				form.phones,
				card.phones.map(
					|phone| {
						label: BusinessCard.phone_label(phone),
						value: phone.display,
					},
				),
			),
			5,
		),
		aiRunId: run_id,
	}
}

prefer_existing : Str, Str -> Str
prefer_existing = |existing, extracted|
	if existing.trim().is_empty() {
		extracted
	} else {
		existing
	}

merge_strings : List(Str), List(Str) -> List(Str)
merge_strings = |existing, extracted| {
	manual = existing.keep_if(|value| !value.trim().is_empty())
	List.fold(
		extracted,
		manual,
		|values, value|
			if value.trim().is_empty()
				or values.any(|present| Person.normalized_email(present) == Person.normalized_email(value)) {
				values
			} else {
				values.append(value)
			},
	).take_first(5)
}

merge_phones : List(PersonView.PhoneInput), List(PersonView.PhoneInput) -> List(PersonView.PhoneInput)
merge_phones = |existing, extracted| {
	manual = existing.keep_if(|phone| !phone.value.trim().is_empty())
	List.fold(
		extracted,
		manual,
		|values, phone|
			if phone.value.trim().is_empty()
				or values.any(
					|present|
						Person.normalized_phone(present.value)
							== Person.normalized_phone(phone.value),
				) {
				values
			} else {
				values.append(phone)
			},
	).take_first(5)
}

padded_strings : List(Str), U64 -> List(Str)
padded_strings = |values, length|
	if values.len() >= length {
		values.take_first(length)
	} else {
		padded_strings(values.append(""), length)
	}

padded_phones : List(PersonView.PhoneInput), U64 -> List(PersonView.PhoneInput)
padded_phones = |values, length|
	if values.len() >= length {
		values.take_first(length)
	} else {
		padded_phones(values.append({ label: "Work", value: "" }), length)
	}

matched_company : BusinessCard, List(Company) -> Str
matched_company = |card, companies| {
	name_matches = match Company.Name.from_str(card.company) {
		Ok(name) =>
			companies.keep_if(
				|company| company.name.match_key() == name.match_key(),
			)
		Err(_) => []
	}
	match name_matches {
		[company] => company.id.to_str()
		_ => {
			domain = Company.website_domain(card.website)
			domain_matches = if domain.is_empty() {
				[]
			} else {
				companies.keep_if(
					|company| Company.website_domain(company.website) == domain,
				)
			}
			match domain_matches {
				[company] => company.id.to_str()
				_ => ""
			}
		}
	}
}

provider_failure : BusinessCard.Error -> {
	message : Str,
	outcome : Str,
	providerStatus : I64,
	status : U16,
}
provider_failure = |error|
	match error {
		BusinessCard.Error.Transport => {
			message: "The AI provider could not be reached. Try again.",
			outcome: "provider_transport",
			providerStatus: 0,
			status: 503,
		}
		BusinessCard.Error.Provider(status) => {
			message: "The AI provider could not process this scan. Try again later.",
			outcome: "provider_http_${status.to_str()}",
			providerStatus: status.to_i64(),
			status: if status == 408 {
				504
			} else {
				502
			},
		}
		BusinessCard.Error.Refused => {
			message: "The image could not be processed as a business card.",
			outcome: "provider_refusal",
			providerStatus: 0,
			status: 422,
		}
		BusinessCard.Error.InvalidResponse => {
			message: "The AI provider returned an invalid extraction. Try another image.",
			outcome: "invalid_provider_response",
			providerStatus: 0,
			status: 502,
		}
	}

expect is_jpeg([255, 216, 255, 224])
expect !is_jpeg([137, 80, 78, 71])
