import pf.Server
import http.Response

import AppError
import AuthView
import Http
import Member
import MemberStore
import Route
import Session
import SessionStore
import Web

RegistrationForm := {
	username : Str,
	email : Str,
}

LoginForm := {
	username : Str,
}

AuthHandler := [].{
	login_page : Session -> Response
	login_page = |session|
		Http.html(
			200,
			AuthView.login(session, AuthView.LoginModel.{ username: "", error: "" }),
			[],
		)

	register_page : Session -> Response
	register_page = |session|
		Http.html(
			200,
			AuthView.register(
				session,
				AuthView.RegistrationModel.{ username: "", email: "", error: "" },
			),
			[],
		)

	register! : Server.Request, MemberStore, Session => Try(Response, AppError)
	register! = |request, store, session| {
		form = Http.read_form!(request)?
		AuthHandler.register_form!(form, store, session)
	}

	register_form! : Dict(Str, Str), store, Session => Try(Response, AppError)
		where [
			store.register! : store, Member.Registration => Try({}, [MemberAlreadyExists, ..err]),
		]
	register_form! = |form, store, session| {
		Store : store
		input = AuthHandler.registration_form(form)

		result = match Member.register(input.username, input.email) {
			Err(_) => Err(Member.RegisterError.InvalidRegistration)
			Ok(registration) => Member.complete_registration(Store.register!(store, registration))
		}
		AuthHandler.registration_response(session, input, result)
	}

	registration_form : Dict(Str, Str) -> RegistrationForm
	registration_form = |form| RegistrationForm.{
		username: form.get(Route.AuthInput.to_name(Route.AuthInput.Username)) ?? "",
		email: form.get(Route.AuthInput.to_name(Route.AuthInput.Email)) ?? "",
	}

	registration_response : Session, RegistrationForm, Try({}, Member.RegisterError([MemberAlreadyExists, ..err])) -> Try(Response, AppError)
	registration_response = |session, input, result|
		match result {
			Err(Member.RegisterError.InvalidRegistration) =>
				Ok(
					Http.html(
						400,
						AuthView.register(
							session,
							AuthView.RegistrationModel.{
								username: input.username,
								email: input.email,
								error: "Username and email are required.",
							},
						),
						[],
					),
				)
			Ok({}) => Ok(Web.redirect(Route.Page.Login))
			Err(Member.RegisterError.StoreFailure(MemberAlreadyExists)) =>
				Ok(
					Http.html(
						409,
						AuthView.register(
							session,
							AuthView.RegistrationModel.{
								username: input.username,
								email: input.email,
								error: "That username is already registered.",
							},
						),
						[],
					),
				)
			Err(Member.RegisterError.StoreFailure(err)) => Err(AppError.from(err))
		}

	login! : Server.Request, MemberStore, Session => Try(Response, AppError)
	login! = |request, store, session| {
		form = Http.read_form!(request)?
		AuthHandler.login_form!(form, store, session)
	}

	login_form! : Dict(Str, Str), store, Session => Try(Response, AppError)
		where [
			store.login! : store, Session.Id, Member.Name => Try({}, [MemberNotFound, InactiveMember, ..err]),
		]
	login_form! = |form, store, session| {
		Store : store
		input = AuthHandler.login_form(form)

		result = match Member.Name.from_str(input.username) {
			Err(_) => Err(Member.LoginError.InvalidName)
			Ok(name) => Member.complete_login(Store.login!(store, session.id, name))
		}
		AuthHandler.login_response(session, input, result)
	}

	login_form : Dict(Str, Str) -> LoginForm
	login_form = |form| LoginForm.{
		username: form.get(Route.AuthInput.to_name(Route.AuthInput.Username)) ?? "",
	}

	login_response : Session, LoginForm, Try({}, Member.LoginError([MemberNotFound, InactiveMember, ..err])) -> Try(Response, AppError)
	login_response = |session, input, result|
		match result {
			Err(Member.LoginError.InvalidName) =>
				Ok(
					Http.html(
						400,
						AuthView.login(
							session,
							AuthView.LoginModel.{
								username: input.username,
								error: "Username is required.",
							},
						),
						[],
					),
				)
			Ok({}) => Ok(Web.redirect(Route.Page.Home))
			Err(Member.LoginError.StoreFailure(MemberNotFound)) =>
				Ok(
					Http.html(
						404,
						AuthView.login(
							session,
							AuthView.LoginModel.{
								username: input.username,
								error: "No user with that name was found.",
							},
						),
						[],
					),
				)
			Err(Member.LoginError.StoreFailure(InactiveMember)) =>
				Ok(
					Http.html(
						401,
						AuthView.login(
							session,
							AuthView.LoginModel.{
								username: input.username,
								error: "That member is inactive.",
							},
						),
						[],
					),
				)
			Err(Member.LoginError.StoreFailure(err)) => Err(AppError.from(err))
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
		RegistrationForm.{ username: "", email: "" },
		Err(Member.RegisterError.InvalidRegistration),
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
		RegistrationForm.{ username: "Ada", email: "ada@example.com" },
		Err(Member.RegisterError.StoreFailure(MemberAlreadyExists)),
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
	result = AuthHandler.registration_response(
		session,
		RegistrationForm.{ username: "Ada", email: "ada@example.com" },
		Ok({}),
	)
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
		LoginForm.{ username: "Missing" },
		Err(Member.LoginError.StoreFailure(MemberNotFound)),
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
