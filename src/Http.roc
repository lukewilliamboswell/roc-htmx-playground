import pf.Html
import pf.MultipartFormData
import pf.Server
import pf.Stderr
import http.Response

import AppError
import ErrorView
import Route
import Session
import Web

## HTTP representation concerns shared by feature handlers and the application
## entry point. Domain and view modules deliberately do not import this module.
Http := [].{
	Header : { name : Str, value : Str }

	html : U16, Html.Node, List(Header) -> Response
	html = |status, node, extra_headers|
		Response.from_status(status)
			.with_headers(
				[
					{ name: "Content-Type", value: "text/html; charset=utf-8" },
					{ name: "Cache-Control", value: "private, no-store" },
					{
						name: "Content-Security-Policy",
						value: "default-src 'self'; base-uri 'none'; connect-src 'self'; form-action 'self'; frame-ancestors 'none'; img-src 'self'; script-src 'self'; style-src 'self'",
					},
					{ name: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
					{ name: "X-Content-Type-Options", value: "nosniff" },
				].concat(extra_headers),
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
			Session.Auth.Trusted(_, _) => Ok({})
		}

	require_same_origin : Server.Request, Str -> Try({}, AppError)
	require_same_origin = |request, public_origin| require_same_origin_headers(request.headers(), public_origin)

	require_same_origin_headers : List(Header), Str -> Try({}, AppError)
	require_same_origin_headers = |headers, public_origin| {
		match header_value(headers, "origin") {
			Ok(origin) =>
				if origin == public_origin {
					Ok({})
				} else {
					Err(AppError.Forbidden)
				}
			Err(_) =>
				match header_value(headers, "referer") {
					Ok(referer) if referer.starts_with("${public_origin}/") =>
						Ok({})
					_ => Err(AppError.Forbidden)
				}
			}
	}

	header_value : List(Header), Str -> Try(Str, [MissingHeader])
	header_value = |headers, expected|
		match headers.find_first(|header| header.name.with_ascii_lowercased() == expected) {
			Ok(header) => Ok(header.value)
			Err(_) => Err(MissingHeader)
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

	expect Http.require_login(Session.guest(Session.Id.from_i64(1))) == Err(AppError.Unauthorized)
	expect Http.require_same_origin_headers(
		[
			{ name: "Host", value: "app.example" },
			{ name: "Origin", value: "https://app.example" },
		],
		"https://app.example",
	) == Ok({})
	expect Http.require_same_origin_headers(
		[
			{ name: "Host", value: "app.example" },
			{ name: "Origin", value: "https://attacker.example" },
		],
		"https://app.example",
	) == Err(AppError.Forbidden)

	error_response! : Session, AppError => Response
	error_response! = |session, error|
		error_response_for_headers!([], session, error)

	error_response_for! : Server.Request, Session, AppError => Response
	error_response_for! = |request, session, error|
		error_response_for_headers!(request.headers(), session, error)

	error_response_for_headers! : List(Header), Session, AppError => Response
	error_response_for_headers! = |_headers, session, error|
		match error {
			AppError.Unauthorized =>
				html(401, ErrorView.unauthorized(session), [])
			AppError.Forbidden => html(403, ErrorView.forbidden(session), [])
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

	is_htmx_request : List(Header) -> Bool
	is_htmx_request = |headers|
		headers.find_first(
			|header|
				header.name.with_ascii_lowercased() == "hx-request"
					and header.value.with_ascii_lowercased() == "true",
		).is_ok()
}

expect Http.is_htmx_request([{ name: "HX-Request", value: "true" }])
expect !Http.is_htmx_request([{ name: "HX-Request", value: "false" }])
