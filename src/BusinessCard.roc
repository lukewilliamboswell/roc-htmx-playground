import AiStore
import Person

BusinessCard := {
	fullName : Str,
	firstName : Str,
	lastName : Str,
	jobTitle : Str,
	company : Str,
	emails : List(Str),
	phones : List(Phone),
	website : Str,
	address : Address,
	confidence : F64,
	warnings : List(Str),
}.{
	Phone := {
		display : Str,
		e164 : Str,
		kind : Str,
	}

	Address := {
		street : Str,
		city : Str,
		stateOrRegion : Str,
		postalCode : Str,
		country : Str,
	}

	Result := {
		contact : BusinessCard,
		providerRequestId : Str,
		returnedModel : Str,
		usage : AiStore.Usage,
	}

	Error := [
		Transport,
		Provider(U16),
		Refused,
		InvalidResponse,
	]

	phone_label : Phone -> Str
	phone_label = |phone|
		match phone.kind {
			"mobile" => "Mobile"
			"fax" => "Fax"
			"home" => "Home"
			"work" => "Work"
			_ => "Other"
		}

	address_lines : Address -> List(Str)
	address_lines = |address| {
		region = Str.join_with(
			[address.city, address.stateOrRegion, address.postalCode]
				.keep_if(|value| !value.is_empty()),
			", ",
		)
		[address.street, region, address.country]
			.keep_if(|value| !value.is_empty())
	}

	quality_permille : BusinessCard -> I64
	quality_permille = |card|
		(card.confidence * 1000).to_i64_try() ?? 0

	from_json : Str -> Try(BusinessCard, Error)
	from_json = |content| decode_json(content)
}

RawPhone : {
	display : Str,
	e164 : Try(Str, [Null]),
	type : Str,
}

RawAddress : {
	street : Try(Str, [Null]),
	city : Try(Str, [Null]),
	state_or_region : Try(Str, [Null]),
	postal_code : Try(Str, [Null]),
	country : Try(Str, [Null]),
}

RawBusinessCard : {
	full_name : Try(Str, [Null]),
	first_name : Try(Str, [Null]),
	last_name : Try(Str, [Null]),
	job_title : Try(Str, [Null]),
	company : Try(Str, [Null]),
	emails : List(Str),
	phone_numbers : List(RawPhone),
	website : Try(Str, [Null]),
	address : RawAddress,
	overall_confidence : F64,
	warnings : List(Str),
}

decode_json : Str -> Try(BusinessCard, BusinessCard.Error)
decode_json = |content| {
	raw : RawBusinessCard
	raw = Json.parse(content) ? |_| BusinessCard.Error.InvalidResponse
	if !raw_is_valid(raw) {
		return Err(BusinessCard.Error.InvalidResponse)
	}
	card = BusinessCard.{
		fullName: nullable(raw.full_name),
		firstName: nullable(raw.first_name),
		lastName: nullable(raw.last_name),
		jobTitle: nullable(raw.job_title),
		company: nullable(raw.company),
		emails: deduplicate(
			raw.emails.map(|email| Person.normalized_email(email)),
			[],
		),
		phones: deduplicate_phones(
			raw.phone_numbers.map(
				|phone|
					BusinessCard.Phone.{
						display: phone.display.trim(),
						e164: nullable(phone.e164),
						kind: phone.type.trim(),
					},
			),
			[],
		),
		website: nullable(raw.website),
		address: BusinessCard.Address.{
			street: nullable(raw.address.street),
			city: nullable(raw.address.city),
			stateOrRegion: nullable(raw.address.state_or_region),
			postalCode: nullable(raw.address.postal_code),
			country: nullable(raw.address.country),
		},
		confidence: raw.overall_confidence,
		warnings: raw.warnings.map(Str.trim),
	}
	Ok(card)
}

nullable : Try(Str, [Null]) -> Str
nullable = |value|
	match value {
		Ok(found) => found.trim()
		Err(Null) => ""
	}

raw_is_valid : RawBusinessCard -> Bool
raw_is_valid = |raw|
	nullable_within(raw.full_name, 200)
		and nullable_within(raw.first_name, 100)
			and nullable_within(raw.last_name, 100)
				and nullable_within(raw.job_title, 200)
					and nullable_within(raw.company, 200)
						and raw.emails.len() <= 5
							and !raw.emails.any(|email| email.to_utf8().len() > 320)
								and raw.phone_numbers.len() <= 5
									and !raw.phone_numbers.any(
										|phone|
											phone.display.trim().is_empty()
												or phone.display.to_utf8().len() > 64
													or !nullable_within(phone.e164, 64)
														or !valid_e164(phone.e164)
															or !valid_phone_type(phone.type),
									)
										and nullable_within(raw.website, 2048)
											and nullable_within(raw.address.street, 300)
												and nullable_within(raw.address.city, 200)
													and nullable_within(raw.address.state_or_region, 200)
														and nullable_within(raw.address.postal_code, 40)
															and nullable_within(raw.address.country, 200)
																and raw.overall_confidence >= 0
																	and raw.overall_confidence <= 1
																		and raw.warnings.len() <= 10
																			and !raw.warnings.any(|warning| warning.to_utf8().len() > 500)

nullable_within : Try(Str, [Null]), U64 -> Bool
nullable_within = |value, maximum|
	match value {
		Ok(found) => found.to_utf8().len() <= maximum
		Err(Null) => True
	}

valid_e164 : Try(Str, [Null]) -> Bool
valid_e164 = |value|
	match value {
		Err(Null) => True
		Ok(found) => {
			bytes = found.to_utf8()
			match bytes {
				[43, first, .. as rest] =>
					bytes.len() <= 16
						and first >= 49
							and first <= 57
								and !rest.any(|byte| byte < 48 or byte > 57)
				_ => False
			}
		}
	}

valid_phone_type : Str -> Bool
valid_phone_type = |kind|
	["mobile", "work", "fax", "home", "other", "unknown"].contains(kind)

deduplicate : List(Str), List(Str) -> List(Str)
deduplicate = |values, unique|
	match values {
		[] => unique.take_first(5)
		[value, .. as rest] if value.is_empty() or unique.contains(value) =>
			deduplicate(rest, unique)
		[value, .. as rest] => deduplicate(rest, unique.append(value))
	}

deduplicate_phones : List(BusinessCard.Phone), List(BusinessCard.Phone) -> List(BusinessCard.Phone)
deduplicate_phones = |values, unique|
	match values {
		[] => unique.take_first(5)
		[value, .. as rest] if value.display.is_empty() =>
			deduplicate_phones(rest, unique)
		[value, .. as rest] if unique.any(|existing| Person.normalized_phone(existing.display) == Person.normalized_phone(value.display)) =>
			deduplicate_phones(rest, unique)
		[value, .. as rest] => deduplicate_phones(rest, unique.append(value))
	}

expect {
	card = BusinessCard.from_json((
		\\{"full_name":"Ada Lovelace","first_name":"Ada","last_name":"Lovelace","job_title":"Mathematician","company":null,"emails":["ADA@EXAMPLE.COM"],"phone_numbers":[],"website":null,"address":{"street":null,"city":null,"state_or_region":null,"postal_code":null,"country":null},"overall_confidence":0.9,"warnings":[]}
		,
	))
	match card {
		Ok(value) => value.fullName == "Ada Lovelace" and value.emails == ["ada@example.com"]
		Err(_) => False
	}
}

expect {
	too_many_emails = BusinessCard.from_json((
		\\{"full_name":null,"first_name":null,"last_name":null,"job_title":null,"company":null,"emails":["a@x.test","b@x.test","c@x.test","d@x.test","e@x.test","f@x.test"],"phone_numbers":[],"website":null,"address":{"street":null,"city":null,"state_or_region":null,"postal_code":null,"country":null},"overall_confidence":0.9,"warnings":[]}
		,
	))
	match too_many_emails {
		Err(BusinessCard.Error.InvalidResponse) => True
		_ => False
	}
}
