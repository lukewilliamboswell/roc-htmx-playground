Member := {
	id : Id,
	name : Name,
	email : Email,
	active : Bool,
}.{
	Id :: Str.{
		from_str : Str -> Try(Id, [InvalidMemberId])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() {
				Err(InvalidMemberId)
			} else {
				Ok(Id.(trimmed))
			}
		}

		to_str : Id -> Str
		to_str = |Id.(value)| value

		from_storage : Str -> Id
		from_storage = |value| Id.(value)

		is_eq : _
	}

	Name :: Str.{
		from_str : Str -> Try(Name, [NameWasEmpty])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() {
				Err(NameWasEmpty)
			} else {
				Ok(Name.(trimmed))
			}
		}

		to_str : Name -> Str
		to_str = |Name.(value)| value

		is_eq : _
	}

	Email :: Str.{
		from_str : Str -> Try(Email, [EmailWasEmpty])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() {
				Err(EmailWasEmpty)
			} else {
				Ok(Email.(trimmed))
			}
		}

		to_str : Email -> Str
		to_str = |Email.(value)| value

		is_eq : _
	}

	Registration := {
		name : Name,
		email : Email,
	}.{
		is_eq : _
	}

	RegisterError(err) := [InvalidRegistration, StoreFailure(err)]

	LoginError(err) := [InvalidName, StoreFailure(err)]

	register : Str, Str -> Try(Registration, [NameWasEmpty, EmailWasEmpty])
	register = |name, email|
		match Name.from_str(name) {
			Err(NameWasEmpty) => Err(NameWasEmpty)
			Ok(valid_name) =>
				match Email.from_str(email) {
					Err(EmailWasEmpty) => Err(EmailWasEmpty)
					Ok(valid_email) =>
						Ok(Registration.{ name: valid_name, email: valid_email })
					}
			}

	complete_registration : Try({}, err) -> Try({}, RegisterError(err))
	complete_registration = |stored|
		match stored {
			Ok({}) => Ok({})
			Err(error) => Err(RegisterError.StoreFailure(error))
		}

	complete_login : Try({}, err) -> Try({}, LoginError(err))
	complete_login = |stored|
		match stored {
			Ok({}) => Ok({})
			Err(error) => Err(LoginError.StoreFailure(error))
		}

	from_storage : Str, Str, Str, I64 -> Member
	from_storage = |id, name, email, active|
		Member.{
			id: Id.(id),
			name: Name.(name),
			email: Email.(email),
			active: active == 1,
		}
}

expect Member.register("  Ada  ", " ada@example.com ").is_ok()
expect Member.register(" ", "ada@example.com") == Err(NameWasEmpty)
expect match Member.Id.from_str("member-ada") {
	Ok(id) => id.to_str() == "member-ada"
	Err(_) => False
}
