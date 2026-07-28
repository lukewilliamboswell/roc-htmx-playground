import Session

User := {
	id : Id,
	name : Name,
	email : Email,
}.{
	Id :: I64.{
		from_i64 : I64 -> Id
		from_i64 = |value| Id.(value)

		from_str : Str -> Try(Id, [InvalidUserId(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) => Ok(Id.(number))
				Err(_) => Err(InvalidUserId(value))
			}

		to_i64 : Id -> I64
		to_i64 = |Id.(value)| value

		to_str : Id -> Str
		to_str = |id| id.to_i64().to_str()

		is_eq : _
	}

	Name :: Str.{
		from_str : Str -> Try(Name, [NameWasEmpty])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() {
				Err(NameWasEmpty)
			} else {
				Ok(Name.(value))
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
				Ok(Email.(value))
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

	register : Str, Str -> Try(Registration, [NameWasEmpty, EmailWasEmpty])
	register = |name, email|
		match Name.from_str(name) {
			Err(NameWasEmpty) => Err(NameWasEmpty)
			Ok(valid_name) =>
				match Email.from_str(email) {
					Err(EmailWasEmpty) => Err(EmailWasEmpty)
					Ok(valid_email) => Ok(Registration.{ name: valid_name, email: valid_email })
				}
			}

	register! : store, Str, Str => Try({}, RegisterError(err))
		where [
			store.register! : store, Registration => Try({}, err),
		]
	register! = |store, name, email| {
		Store : store
		match User.register(name, email) {
			Err(_) => Err(RegisterError.InvalidRegistration)
			Ok(registration) => {
				stored = Store.register!(store, registration)
				User.complete_registration(stored)
			}
		}
	}

	login! : store, Session.Id, Str => Try({}, LoginError(err))
		where [
			store.login! : store, Session.Id, Name => Try({}, err),
		]
	login! = |store, session_id, username| {
		Store : store
		match Name.from_str(username) {
			Err(_) => Err(LoginError.InvalidName)
			Ok(name) => {
				stored = Store.login!(store, session_id, name)
				User.complete_login(stored)
			}
		}
	}

	from_storage : I64, Str, Str -> User
	from_storage = |id, name, email|
		User.{
			id: Id.from_i64(id),
			name: Name.(name),
			email: Email.(email),
		}
}

expect User.register("  Ada  ", " ada@example.com ").is_ok()
expect User.register(" ", "ada@example.com") == Err(NameWasEmpty)
expect match User.complete_registration(Err(Duplicate)) {
	Err(User.RegisterError.StoreFailure(Duplicate)) => True
	_ => False
}
expect match User.complete_login(Err(Missing)) {
	Err(User.LoginError.StoreFailure(Missing)) => True
	_ => False
}
