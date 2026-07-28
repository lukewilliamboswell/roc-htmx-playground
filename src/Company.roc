import Member
import Workspace

Company := {
	id : Id,
	name : Name,
	ownerId : Member.Id,
	ownerName : Str,
	lifecycle : Lifecycle,
	website : Str,
	phone : Str,
	sourceId : Str,
	sourceName : Str,
	context : Str,
	createdByName : Str,
	updatedByName : Str,
	createdAt : Str,
	updatedAt : Str,
	version : Version,
}.{
	Id :: Str.{
		from_str : Str -> Try(Id, [InvalidCompanyId])
		from_str = |value|
			if value.trim().is_empty() {
				Err(InvalidCompanyId)
			} else {
				Ok(Id.(value.trim()))
			}

		to_str : Id -> Str
		to_str = |Id.(value)| value

		from_storage : Str -> Id
		from_storage = |value| Id.(value)

		is_eq : _
	}

	Name :: Str.{
		from_str : Str -> Try(Name, [CompanyNameWasEmpty])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() {
				Err(CompanyNameWasEmpty)
			} else {
				Ok(Name.(trimmed))
			}
		}

		to_str : Name -> Str
		to_str = |Name.(value)| value

		match_key : Name -> NameKey
		match_key = |Name.(value)| NameKey.(value.with_ascii_lowercased())

		is_eq : _
	}

	NameKey :: Str.{
		to_str : NameKey -> Str
		to_str = |NameKey.(value)| value

		is_eq : _
	}

	Version :: I64.{
		initial : Version
		initial = Version.(1)

		from_i64 : I64 -> Version
		from_i64 = |value| Version.(value)

		from_str : Str -> Try(Version, [InvalidCompanyVersion])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) if number > 0 => Ok(Version.(number))
				_ => Err(InvalidCompanyVersion)
			}

		to_i64 : Version -> I64
		to_i64 = |Version.(value)| value

		to_str : Version -> Str
		to_str = |Version.(value)| value.to_str()

		is_eq : _
	}

	Lifecycle := [Lead, Prospect, Customer, Inactive].{
		from_str : Str -> Try(Lifecycle, [InvalidLifecycle(Str)])
		from_str = |value|
			match value.with_ascii_lowercased() {
				"lead" => Ok(Lead)
				"prospect" => Ok(Prospect)
				"customer" => Ok(Customer)
				"inactive" => Ok(Inactive)
				_ => Err(InvalidLifecycle(value))
			}

		from_storage : Str -> Lifecycle
		from_storage = |value|
			match value {
				"lead" => Lead
				"prospect" => Prospect
				"customer" => Customer
				"inactive" => Inactive
				_ => Inactive
			}

		to_str : Lifecycle -> Str
		to_str = |status|
			match status {
				Lead => "lead"
				Prospect => "prospect"
				Customer => "customer"
				Inactive => "inactive"
			}

		to_label : Lifecycle -> Str
		to_label = |status|
			match status {
				Lead => "Lead"
				Prospect => "Prospect"
				Customer => "Customer"
				Inactive => "Inactive"
			}

		is_eq : _
	}

	Filter :: Str.{
		from_str : Str -> Filter
		from_str = |value| Filter.(value.trim())

		to_str : Filter -> Str
		to_str = |Filter.(value)| value

		normalized : Filter -> Str
		normalized = |Filter.(value)| value.with_ascii_lowercased()

		empty : Filter
		empty = Filter.("")
	}

	New := {
		name : Name,
		ownerId : Member.Id,
		lifecycle : Lifecycle,
		website : Str,
		phone : Str,
		sourceId : Str,
		context : Str,
	}

	NewError := [NameWasEmpty, InvalidLifecycle(Str)]

	MatchStrength := [Strong, Weak].{
		to_label : MatchStrength -> Str
		to_label = |strength|
			match strength {
				Strong => "Strong match"
				Weak => "Possible match"
			}

		is_eq : _
	}

	Match := {
		company : Company,
		strength : MatchStrength,
		reason : Str,
	}

	FindError(err) := [NotFound, StoreFailure(err)]
	CreateError(err) := [DuplicateMatches(List(Match)), StoreFailure(err)]
	UpdateError(err) := [NotFound, Conflict(Company), StoreFailure(err)]

	new : Str, Member.Id, Str, Str, Str, Str, Str -> Try(New, NewError)
	new = |name, owner_id, lifecycle, website, phone, source_id, context|
		match Name.from_str(name) {
			Err(_) => Err(NewError.NameWasEmpty)
			Ok(valid_name) =>
				match Lifecycle.from_str(lifecycle) {
					Err(InvalidLifecycle(value)) => Err(NewError.InvalidLifecycle(value))
					Ok(valid_lifecycle) =>
						Ok(
							New.{
								name: valid_name,
								ownerId: owner_id,
								lifecycle: valid_lifecycle,
								website: website.trim(),
								phone: phone.trim(),
								sourceId: source_id,
								context: context.trim(),
							},
						)
					}
			}

	normalized_phone : Str -> Str
	normalized_phone = |value| {
		without_spaces = Str.join_with(value.trim().split_on(" "), "")
		without_hyphens = Str.join_with(without_spaces.split_on("-"), "")
		without_open = Str.join_with(without_hyphens.split_on("("), "")
		Str.join_with(without_open.split_on(")"), "")
	}

	website_domain : Str -> Str
	website_domain = |value| {
		lower = value.trim().with_ascii_lowercased()
		without_scheme = match lower.split_on("://") {
			[_, rest, ..] => rest
			_ => lower
		}
		host = without_scheme.split_on("/").first() ?? ""
		match host.split_on("www.") {
			["", rest, ..] => rest
			_ => host
		}
	}

	from_storage : {
		context : Str,
		createdAt : Str,
		createdByName : Str,
		id : Str,
		lifecycle : Str,
		name : Str,
		ownerId : Str,
		ownerName : Str,
		phone : Str,
		sourceId : Str,
		sourceName : Str,
		updatedAt : Str,
		updatedByName : Str,
		version : I64,
		website : Str,
	} -> Company
	from_storage = |row|
		Company.{
			id: Id.(row.id),
			name: Name.(row.name),
			ownerId: Member.Id.from_storage(row.ownerId),
			ownerName: row.ownerName,
			lifecycle: Lifecycle.from_storage(row.lifecycle),
			website: row.website,
			phone: row.phone,
			sourceId: row.sourceId,
			sourceName: row.sourceName,
			context: row.context,
			createdByName: row.createdByName,
			updatedByName: row.updatedByName,
			createdAt: row.createdAt,
			updatedAt: row.updatedAt,
			version: Version.(row.version),
		}
}

expect Company.Name.from_str("  Acme Studio ").is_ok()
expect Company.Name.from_str(" ").is_err()
expect {
	name = Company.Name.from_str("Mixed CASE Company") ?? Company.Name.("")
	key = name.match_key()
	name.to_str() == "Mixed CASE Company" and key.to_str() == "mixed case company"
}
expect Company.Lifecycle.from_str("customer") == Ok(Company.Lifecycle.Customer)
expect Company.normalized_phone("+61 (03) 9000-0000") == "+610390000000"
expect Company.website_domain("https://www.Acme.Example/about") == "acme.example"
