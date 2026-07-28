import pf.Server
import http.Response

import AppError
import AuthView
import Http
import Route
import Session
import SessionStore
import User
import UserStore
import Web

AuthHandler := [].{
	login_page : Session -> Response
	login_page = |session| Http.html(200, AuthView.login(session, "", ""), [])

	register_page : Session -> Response
	register_page = |session| Http.html(200, AuthView.register(session, "", "", ""), [])

	register! : Server.Request, UserStore, Session => Try(Response, AppError)
	register! = |request, store, session| {
		form = Http.read_form!(request)?
		AuthHandler.register_form!(form, store, session)
	}

	register_form! : Dict(Str, Str), store, Session => Try(Response, AppError)
		where [
			store.register! : store, User.Registration => Try({}, [UserAlreadyExists, ..err]),
		]
	register_form! = |form, store, session| {
		username = form.get(Route.AuthInput.to_name(Route.AuthInput.Username)) ?? ""
		email = form.get(Route.AuthInput.to_name(Route.AuthInput.Email)) ?? ""

		result = User.register!(store, username, email)
		AuthHandler.registration_response(session, username, email, result)
	}

	registration_response : Session, Str, Str, Try({}, User.RegisterError([UserAlreadyExists, ..err])) -> Try(Response, AppError)
	registration_response = |session, username, email, result|
		match result {
			Err(User.RegisterError.InvalidRegistration) =>
				Ok(
					Http.html(
						400,
						AuthView.register(
							session,
							username,
							email,
							"Username and email are required.",
						),
						[],
					),
				)
			Ok({}) => Ok(Web.redirect(Route.Page.Login))
			Err(User.RegisterError.StoreFailure(UserAlreadyExists)) =>
				Ok(
					Http.html(
						409,
						AuthView.register(
							session,
							username,
							email,
							"That username is already registered.",
						),
						[],
					),
				)
			Err(User.RegisterError.StoreFailure(err)) => Err(AppError.from(err))
		}

	login! : Server.Request, UserStore, Session => Try(Response, AppError)
	login! = |request, store, session| {
		form = Http.read_form!(request)?
		AuthHandler.login_form!(form, store, session)
	}

	login_form! : Dict(Str, Str), store, Session => Try(Response, AppError)
		where [
			store.login! : store, Session.Id, User.Name => Try({}, [UserNotFound, ..err]),
		]
	login_form! = |form, store, session| {
		username = form.get(Route.AuthInput.to_name(Route.AuthInput.Username)) ?? ""

		result = User.login!(store, session.id, username)
		AuthHandler.login_response(session, username, result)
	}

	login_response : Session, Str, Try({}, User.LoginError([UserNotFound, ..err])) -> Try(Response, AppError)
	login_response = |session, username, result|
		match result {
			Err(User.LoginError.InvalidName) =>
				Ok(
					Http.html(
						400,
						AuthView.login(session, username, "Username is required."),
						[],
					),
				)
			Ok({}) => Ok(Web.redirect(Route.Page.Home))
			Err(User.LoginError.StoreFailure(UserNotFound)) =>
				Ok(
					Http.html(
						404,
						AuthView.login(
							session,
							username,
							"No user with that name was found.",
						),
						[],
					),
				)
			Err(User.LoginError.StoreFailure(err)) => Err(AppError.from(err))
		}

	logout! : store => Try(Response, AppError)
		where [
			store.create! : store => Try(Session.Id, err),
		]
	logout! = |store| {
		Store : store
		created = Store.create!(store)
		AuthHandler.logout_response(created)
	}

	logout_response : Try(Session.Id, err) -> Try(Response, AppError)
	logout_response = |created|
		match created {
			Ok(id) =>
				Ok(
					Web.redirect_with_headers(
						Route.Page.Home,
						[Http.session_cookie(id)],
					),
				)
			Err(err) => Err(AppError.from(err))
		}
}

expect {
	session = Session.guest(Session.Id.from_i64(1))
	result = AuthHandler.registration_response(
		session,
		"",
		"",
		Err(User.RegisterError.InvalidRegistration),
	)
	match result {
		Ok(response) =>
			Response.status(response) == 400
				and Str.from_utf8_lossy(Response.body(response))
					.contains("Username and email are required.")
		Err(_) => False
	}
}

expect {
	session = Session.guest(Session.Id.from_i64(1))
	result = AuthHandler.registration_response(
		session,
		"Ada",
		"ada@example.com",
		Err(User.RegisterError.StoreFailure(UserAlreadyExists)),
	)
	match result {
		Ok(response) =>
			Response.status(response) == 409
				and Str.from_utf8_lossy(Response.body(response))
					.contains("already registered")
		Err(_) => False
	}
}

expect {
	session = Session.guest(Session.Id.from_i64(1))
	result = AuthHandler.registration_response(session, "Ada", "ada@example.com", Ok({}))
	match result {
		Ok(response) =>
			Response.status(response) == 303
				and Response.headers(response).find_first(|header| header.name == "Location")
					== Ok({ name: "Location", value: "/login" })
		Err(_) => False
	}
}

expect {
	session = Session.guest(Session.Id.from_i64(1))
	result = AuthHandler.login_response(
		session,
		"Missing",
		Err(User.LoginError.StoreFailure(UserNotFound)),
	)
	match result {
		Ok(response) =>
			Response.status(response) == 404
				and Str.from_utf8_lossy(Response.body(response))
					.contains("No user with that name was found.")
		Err(_) => False
	}
}

expect {
	result = AuthHandler.logout_response(Ok(Session.Id.from_i64(99)))
	match result {
		Ok(response) =>
			Response.headers(response).find_first(|header| header.name == "Set-Cookie")
				== Ok({
					name: "Set-Cookie",
					value: "sessionId=99; Path=/; HttpOnly; SameSite=Lax",
				})
		Err(_) => False
	}
}
