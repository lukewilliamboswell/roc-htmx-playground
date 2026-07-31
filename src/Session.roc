import Member

Session := {
	id : Id,
	user : Auth,
}.{
	Id :: I64.{
		from_i64 : I64 -> Id
		from_i64 = |value| Id.(value)

		from_str : Str -> Try(Id, [InvalidSessionId(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) => Ok(Id.(number))
				Err(_) => Err(InvalidSessionId(value))
			}

		to_i64 : Id -> I64
		to_i64 = |Id.(value)| value

		to_str : Id -> Str
		to_str = |Id.(value)| value.to_str()

		is_eq : _
	}

	IdentitySource := [Development, Production].{
		is_eq : _
	}

	Auth := [Guest, Trusted(Member, IdentitySource)].{
		is_eq : _
	}

	FindError(err) := [NotFound, Inactive, StoreFailure(err)]

	anonymous : Session
	anonymous = Session.{ id: Id.from_i64(0), user: Guest }

	guest : Id -> Session
	guest = |id| Session.{ id, user: Guest }

	trusted : Member, IdentitySource -> Session
	trusted = |member, source| Session.{ id: Id.from_i64(0), user: Trusted(member, source) }

	is_logged_in : Session -> Bool
	is_logged_in = |session|
		match session.user {
			Guest => False
			Trusted(_, _) => True
		}
}

expect match Session.Id.from_str("42") {
	Ok(id) => id.to_i64() == 42
	Err(_) => False
}
expect Session.Id.from_str("not-an-id").is_err()
