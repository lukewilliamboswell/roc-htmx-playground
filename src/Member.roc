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

	from_storage : Str, Str, Str, I64 -> Member
	from_storage = |id, name, email, active|
		Member.{
			id: Id.(id),
			name: Name.(name),
			email: Email.(email),
			active: active == 1,
		}
}

expect match Member.Id.from_str("member-ada") {
	Ok(id) => id.to_str() == "member-ada"
	Err(_) => False
}
