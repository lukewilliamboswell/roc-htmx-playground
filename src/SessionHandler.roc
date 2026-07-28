import pf.Server

import AppError
import Http
import Session

## Resolve one request's session through the two store capabilities this
## workflow needs. `resolve_from_id!` keeps cookie parsing at the HTTP boundary
## while making the session decision independently testable.
SessionHandler := [].{
	State := {
		session : Session,
		setCookie : Bool,
	}

	CookieAction := [Find(Session.Id), CreateGuest]

	FindAction(err) := [Use(Session), CreateGuest, FindFailure(err)]

	cookie_action : Try(Session.Id, cookie_err) -> CookieAction
	cookie_action = |parsed_id|
		match parsed_id {
			Ok(id) => CookieAction.Find(id)
			Err(_) => CookieAction.CreateGuest
		}

	find_action : Try(Session, [SessionNotFound, ..err]) -> FindAction([SessionNotFound, ..err])
	find_action = |found|
		match found {
			Ok(session) => FindAction.Use(session)
			Err(SessionNotFound) => FindAction.CreateGuest
			Err(error) => FindAction.FindFailure(error)
		}

	resolve! : Server.Request, store => Try(State, AppError)
		where [
			store.find! : store, Session.Id => Try(Session, [SessionNotFound, ..find_err]),
			store.create! : store => Try(Session.Id, create_err),
		]
	resolve! = |request, store|
		SessionHandler.resolve_from_id!(Http.session_id(request), store)

	resolve_from_id! : Try(Session.Id, cookie_err), store => Try(State, AppError)
		where [
			store.find! : store, Session.Id => Try(Session, [SessionNotFound, ..find_err]),
			store.create! : store => Try(Session.Id, create_err),
		]
	resolve_from_id! = |parsed_id, store| {
		Store : store
		match SessionHandler.cookie_action(parsed_id) {
			CookieAction.Find(id) => {
				found = Store.find!(store, id)
				match SessionHandler.find_action(found) {
					FindAction.Use(session) => Ok({ session, setCookie: False })
					FindAction.CreateGuest => new_guest!(store)
					FindAction.FindFailure(error) => Err(AppError.from(error))
				}
			}
			CookieAction.CreateGuest => new_guest!(store)
		}
	}
}

new_guest! : store => Try(SessionHandler.State, AppError)
	where [
		store.create! : store => Try(Session.Id, err),
	]
new_guest! = |store| {
	Store : store
	match Store.create!(store) {
		Ok(id) => Ok({ session: Session.guest(id), setCookie: True })
		Err(error) => Err(AppError.from(error))
	}
}

expect match SessionHandler.cookie_action(Ok(Session.Id.from_i64(42))) {
	SessionHandler.CookieAction.Find(id) => Session.Id.to_i64(id) == 42
	_ => False
}

expect match SessionHandler.cookie_action(Err(InvalidCookie)) {
	SessionHandler.CookieAction.CreateGuest => True
	_ => False
}

expect match SessionHandler.find_action(Err(SessionNotFound)) {
	SessionHandler.FindAction.CreateGuest => True
	_ => False
}

expect match SessionHandler.find_action(Err(DatabaseUnavailable)) {
	SessionHandler.FindAction.FindFailure(DatabaseUnavailable) => True
	_ => False
}
