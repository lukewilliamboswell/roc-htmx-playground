import pf.Html
import pf.MultipartFormData
import pf.Server
import pf.Stderr
import http.Response

import AppError
import ErrorView
import Session

## HTTP representation concerns shared by feature handlers and the application
## entry point. Domain and view modules deliberately do not import this module.
Http := [].{
	Header : { name : Str, value : Str }

	html : U16, Html.Node, List(Header) -> Response
	html = |status, node, extra_headers|
		Response.from_status(status)
			.with_headers(
				[{ name: "Content-Type", value: "text/html; charset=utf-8" }].concat(extra_headers),
			)
			.with_body(Html.render(node).to_utf8())

	bytes : U16, List(U8), Str -> Response
	bytes = |status, body, content_type|
		Response.from_status(status)
			.with_headers([
				{ name: "Content-Type", value: content_type },
				{ name: "Cache-Control", value: "max-age=120" },
			])
			.with_body(body)

	cacheable_bytes : U16, List(U8), Str -> Response
	cacheable_bytes = |status, body, content_type|
		Response.from_status(status)
			.with_headers([
				{ name: "Content-Type", value: content_type },
				{ name: "Cache-Control", value: "public, max-age=31536000, immutable" },
			])
			.with_body(body)

	read_form! : Server.Request => Try(Dict(Str, Str), AppError)
	read_form! = |request| {
		body = request.body().with_limit(64 * 1024).read_all!()
			? |err| AppError.BadRequest("Unable to read form body: ${Str.inspect(err)}")
		parse_form(body)
	}

	parse_form : List(U8) -> Try(Dict(Str, Str), AppError)
	parse_form = |body|
		MultipartFormData.parse_form_url_encoded(body)
			.map_err(|_| AppError.BadRequest("Malformed URL-encoded form data"))

	require_login : Session -> Try({}, AppError)
	require_login = |session|
		match session.user {
			Session.Auth.Guest => Err(AppError.Unauthorized)
			Session.Auth.LoggedIn(_) => Ok({})
		}

	session_id : Server.Request -> Try(Session.Id, [InvalidSessionCookie])
	session_id = |request| session_id_from_headers(request.headers())

	session_id_from_headers : List(Header) -> Try(Session.Id, [InvalidSessionCookie])
	session_id_from_headers = |headers| {
		header = headers
			.find_first(|item| item.name.with_ascii_lowercased() == "cookie")
			.map_err(|_| InvalidSessionCookie)?
		cookie = header.value.split_on(";")
			.find_first(|item| item.trim().starts_with("sessionId="))
			.map_err(|_| InvalidSessionCookie)?
		parts = cookie.trim().split_on("=")
		match parts {
			["sessionId", value] =>
				match Session.Id.from_str(value) {
					Ok(id) => Ok(id)
					Err(_) => Err(InvalidSessionCookie)
				}
			_ => Err(InvalidSessionCookie)
		}
	}

	expect {
		form = Http.parse_form("username=Ada+Lovelace&email=ada%40example.com".to_utf8())
		match form {
			Ok(fields) =>
				fields.get("username") == Ok("Ada Lovelace")
					and fields.get("email") == Ok("ada@example.com")
			Err(_) => False
		}
	}

	expect {
		parsed = Http.session_id_from_headers([
			{ name: "Cookie", value: "theme=dark; sessionId=42; compact=true" },
		])
		match parsed {
			Ok(id) => Session.Id.to_i64(id) == 42
			Err(_) => False
		}
	}

	expect Http.session_id_from_headers([]) == Err(InvalidSessionCookie)
	expect Http.require_login(Session.guest(Session.Id.from_i64(1))) == Err(AppError.Unauthorized)

	session_cookie : Session.Id -> Header
	session_cookie = |id| {
		name: "Set-Cookie",
		value: "sessionId=${id.to_str()}; Path=/; HttpOnly; SameSite=Lax",
	}

	error_response! : Session, AppError => Response
	error_response! = |session, error|
		match error {
			AppError.Unauthorized => html(401, ErrorView.unauthorized(session), [])
			AppError.BadRequest(message) => html(400, ErrorView.bad_request(session, message), [])
			AppError.NotFound(target) => {
				Stderr.line!("404 Not Found ${target}") ?? {}
				html(404, ErrorView.not_found(session), [])
			}
			AppError.Internal(message) => {
				Stderr.line!("SERVER ERROR ${message}") ?? {}
				html(500, ErrorView.server_error(session), [])
			}
		}
}
