import Company
import DateTime
import Member

Person := {
	id : Id,
	name : Name,
	companyId : Str,
	companyName : Str,
	jobTitle : Str,
	ownerId : Member.Id,
	ownerName : Str,
	lifecycle : Company.Lifecycle,
	sourceId : Str,
	sourceName : Str,
	context : Str,
	emails : List(ContactMethod),
	phones : List(ContactMethod),
	createdByName : Str,
	updatedByName : Str,
	createdAt : DateTime.Display,
	updatedAt : DateTime.Display,
	version : Company.Version,
}.{
	Id :: Str.{
		from_storage : Str -> Id
		from_storage = |value| Id.(value)

		to_str : Id -> Str
		to_str = |Id.(value)| value

		is_eq : _
	}

	Name :: Str.{
		from_str : Str -> Try(Name, [PersonNameWasEmpty])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() {
				Err(PersonNameWasEmpty)
			} else {
				Ok(Name.(trimmed))
			}
		}

		to_str : Name -> Str
		to_str = |Name.(value)| value

		normalized : Name -> Str
		normalized = |Name.(value)| value.with_ascii_lowercased()

		is_eq : _
	}

	Filter :: Str.{
		from_str : Str -> Filter
		from_str = |value| Filter.(value.trim())

		to_str : Filter -> Str
		to_str = |Filter.(value)| value

		empty : Filter
		empty = Filter.("")
	}

	ContactId :: Str.{
		from_storage : Str -> ContactId
		from_storage = |value| ContactId.(value)

		to_str : ContactId -> Str
		to_str = |ContactId.(value)| value

		is_eq : _
	}

	ContactMethod := {
		id : ContactId,
		label : Str,
		value : Str,
		primary : Bool,
	}

	New := {
		name : Name,
		companyId : Str,
		jobTitle : Str,
		ownerId : Member.Id,
		lifecycle : Company.Lifecycle,
		sourceId : Str,
		context : Str,
		email : Str,
		phone : Str,
	}

	NewError := [NameWasEmpty, InvalidLifecycle(Str)]

	MatchStrength := [Strong, Weak].{
		to_label : MatchStrength -> Str
		to_label = |strength|
			match strength {
				Strong => "Strong match"
				Weak => "Possible match"
			}
	}

	Match := {
		person : Person,
		strength : MatchStrength,
		reason : Str,
	}

	FindError(err) := [NotFound, StoreFailure(err)]
	CreateError(err) := [DuplicateMatches(List(Match)), StoreFailure(err)]
	UpdateError(err) := [NotFound, Conflict(Person), StoreFailure(err)]

	new : Str, Str, Str, Member.Id, Str, Str, Str, Str, Str -> Try(New, NewError)
	new = |name, company_id, job_title, owner_id, lifecycle, source_id, context, email, phone|
		match Name.from_str(name) {
			Err(_) => Err(NewError.NameWasEmpty)
			Ok(valid_name) =>
				match Company.Lifecycle.from_str(lifecycle) {
					Err(InvalidLifecycle(value)) => Err(NewError.InvalidLifecycle(value))
					Ok(valid_lifecycle) =>
						Ok(
							New.{
								name: valid_name,
								companyId: company_id.trim(),
								jobTitle: job_title.trim(),
								ownerId: owner_id,
								lifecycle: valid_lifecycle,
								sourceId: source_id,
								context: context.trim(),
								email: email.trim(),
								phone: phone.trim(),
							},
						)
					}
			}

	normalized_email : Str -> Str
	normalized_email = |value| value.trim().with_ascii_lowercased()

	normalized_phone : Str -> Str
	normalized_phone = Company.normalized_phone

	primary_value : List(ContactMethod) -> Str
	primary_value = |methods|
		match methods.find_first(|method| method.primary) {
			Ok(method) => method.value
			Err(_) =>
				match methods.first() {
					Ok(method) => method.value
					Err(_) => ""
				}
			}

	from_storage : {
		companyId : Str,
		companyName : Str,
		context : Str,
		createdAt : Str,
		createdByName : Str,
		id : Str,
		jobTitle : Str,
		lifecycle : Str,
		name : Str,
		ownerId : Str,
		ownerName : Str,
		sourceId : Str,
		sourceName : Str,
		updatedAt : Str,
		updatedByName : Str,
		version : I64,
	},
	List(ContactMethod),
	List(ContactMethod) -> Person
	from_storage = |row, emails, phones|
		Person.{
			id: Id.(row.id),
			name: Name.(row.name),
			companyId: row.companyId,
			companyName: row.companyName,
			jobTitle: row.jobTitle,
			ownerId: Member.Id.from_storage(row.ownerId),
			ownerName: row.ownerName,
			lifecycle: Company.Lifecycle.from_storage(row.lifecycle),
			sourceId: row.sourceId,
			sourceName: row.sourceName,
			context: row.context,
			emails,
			phones,
			createdByName: row.createdByName,
			updatedByName: row.updatedByName,
			createdAt: DateTime.Display.from_local_storage(row.createdAt),
			updatedAt: DateTime.Display.from_local_storage(row.updatedAt),
			version: Company.Version.from_i64(row.version),
		}

	contact_from_storage : Str, Str, Str, I64 -> ContactMethod
	contact_from_storage = |id, label, value, primary|
		ContactMethod.{
			id: ContactId.(id),
			label,
			value,
			primary: primary == 1,
		}
}

expect Person.Name.from_str(" Ada Lovelace ").is_ok()
expect Person.Name.from_str(" ").is_err()
expect Person.normalized_email(" Ada@Example.COM ") == "ada@example.com"
