app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.14.0/9mrSfhWKEXsrPUW2oHdZZGov1oMRryvvACDT8p7E97PY.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Env
import pf.Html
import pf.MultipartFormData
import pf.Path
import pf.Server
import pf.Sqlite
import pf.Stderr
import pf.Stdout
import pf.Url
import pf.Utc
import http.Response
import "site.css" as styles_file : List(U8)
import "../vendor/htmx-4-0-0-beta6.min.js" as htmx_js_file : List(U8)

import Db
import Models
import Pages

Context := { db : Sqlite.Db }

AppError := [Unauthorized, BadRequest(Str), NotFound(Str), AppErr(Str)]

Header : { name : Str, value : Str }

BigTaskField := [CustomerReferenceField, CreatedDateField, StatusField].{
	form_name : BigTaskField -> Str
	form_name = |field|
		match field {
			CustomerReferenceField => "CustomerReferenceID"
			CreatedDateField => "DateCreated"
			StatusField => "Status"
		}

	validate : BigTaskField, Str -> Try({}, Str)
	validate = |field, value|
		match field {
			CustomerReferenceField =>
				match I64.from_str(value) {
					Ok(number) if number > 0 and number < 100_000 => Ok({})
					_ => Err("Must be a number between 0 and 100,000.")
				}
			CreatedDateField =>
				if validDate(value) {
					Ok({})
				} else {
					Err("Must use date format yyyy-mm-dd.")
				}
			StatusField =>
				if ["Raised", "Completed", "Deferred", "Approved", "In-Progress"].contains(value) {
					Ok({})
				} else {
					Err("Choose a valid status.")
				}
			}

	to_update : BigTaskField, Str -> Models.BigTaskUpdate
	to_update = |field, value|
		match field {
			CustomerReferenceField => CustomerReferenceId(value)
			CreatedDateField => DateCreated(value)
			StatusField => Status(value)
		}

	editor : BigTaskField, { idText : Str, value : Str, validation : Str } -> Html.Node
	editor = |field, { idText, value, validation }|
		match field {
			CustomerReferenceField =>
				Pages.bigTaskInput({
					updateUrl: "/bigTask/customerId/${idText}",
					name: "CustomerReferenceID",
					label: "Customer reference",
					kind: "text",
					value,
					validation,
				})
			CreatedDateField =>
				Pages.bigTaskInput({
					updateUrl: "/bigTask/dateCreated/${idText}",
					name: "DateCreated",
					label: "Date created",
					kind: "date",
					value,
					validation,
				})
			StatusField =>
				Pages.bigTaskStatus({
					updateUrl: "/bigTask/status/${idText}",
					label: "Status",
					value,
					validation,
				})
			}
}

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64), ..])
init! = || {
	db_path = match Env.var!("DB_PATH") {
		Ok(path) => Path.from_os_str(path)
		Err(_) => return Err(Exit(2))
	}
	db = Sqlite.open!(Sqlite.default_config(db_path)) ? |_| Exit(2)
	asset_files = Server.file_root({ id: "assets", path: Path.utf8("assets") })
	config_with_files = Server.with_file_roots(Server.default_config, [asset_files])
	config = Server.with_native_routes(
		config_with_files,
		[
			Server.static_mount_with_cache({
				at: "/assets",
				files: asset_files,
				cache: Server.public_for(31_536_000),
			}),
		],
	)
	Ok({
		config,
		context: Context.{ db: db },
	})
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str), ..])
respond! = |request, { db }| {
	logRequest!(request) ? |err| ServerErr(Str.inspect(err))

	response = match Url.resolve(appOrigin, request.target()) {
		Ok(url) => routeRequest!(request, db, url)
		Err(_) => errorResponse!(request, Models.anonymousSession, BadRequest("Invalid request target"))
	}

	Ok(Server.respond(response))
}

## The /assets mount is handled natively by the platform before respond! is
## called. The remaining app-owned static routes never touch the session store.
## Every other route resolves the session once, here, so that handlers and
## error pages share the same one and render the same navigation.
routeRequest! : Server.Request, Sqlite.Db, Url => Response
routeRequest! = |request, db, url| {
	segments = Url.path(url).split_on("/")

	match assetResponse(request, segments) {
		Ok(asset) => asset
		Err(NotAnAsset) =>
			match getSession!(request, db) {
				Ok({ session, setCookie }) => {
					response = match handleRequest!(request, db, url, segments, session) {
						Ok(value) => value
						Err(err) => errorResponse!(request, session, err)
					}

					if setCookie {
						cookie = sessionCookie(session.id)
						Response.add_header(response, cookie.name, cookie.value)
					} else {
						response
					}
				}
				Err(err) => errorResponse!(request, Models.anonymousSession, err)
			}
		}
}

assetResponse : Server.Request, List(Str) -> Try(Response, [NotAnAsset])
assetResponse = |request, segments|
	match (request.method(), segments) {
		(GET, ["", "robots.txt"]) => Ok(bytesResponse(200, robots_txt, "text/plain; charset=utf-8"))
		(GET, ["", "styles.css"]) => Ok(cacheableBytesResponse(200, styles_file, "text/css; charset=utf-8"))
		(GET, ["", "htmx.min.js"]) =>
			Ok(cacheableBytesResponse(200, htmx_js_file, "text/javascript; charset=utf-8"))
		_ => Err(NotAnAsset)
	}

errorResponse! : Server.Request, Models.Session, AppError => Response
errorResponse! = |_request, session, error|
	match error {
		Unauthorized => htmlResponse(401, Pages.unauthorized(session), [])
		BadRequest(message) => htmlResponse(400, Pages.badRequest(session, message), [])
		NotFound(target) => {
			Stderr.line!("404 Not Found ${target}") ?? {}
			htmlResponse(404, Pages.notFound(session), [])
		}
		AppErr(message) => {
			Stderr.line!("SERVER ERROR ${message}") ?? {}
			htmlResponse(500, Pages.serverError(session), [])
		}
	}

sessionCookie : I64 -> Header
sessionCookie = |id| {
	name: "Set-Cookie",
	value: "sessionId=${id.to_str()}; Path=/; HttpOnly; SameSite=Lax",
}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64), ..])
shutdown! = |_reason, _context| Ok({})

handleRequest! : Server.Request, Sqlite.Db, Url, List(Str), Models.Session => Try(Response, AppError)
handleRequest! = |request, db, url, segments, session|
	match (request.method(), segments) {
		(GET, ["", ""]) => Ok(htmlResponse(200, Pages.home(session), []))

		(GET, ["", "register"]) => Ok(htmlResponse(200, Pages.register(session, "", "", ""), []))
		(POST, ["", "register"]) => register!(request, db, session)

		(GET, ["", "login"]) => Ok(htmlResponse(200, Pages.login(session, "", ""), []))
		(POST, ["", "login"]) => login!(request, db, session)
		(POST, ["", "logout"]) => logout!(db)

		(GET, ["", "task", "new"]) => Ok(redirect("/task"))
		(GET, ["", "task"]) => todoPage!(db, session)
		(GET, ["", "task", "list"]) => todoList!(db, "")
		(POST, ["", "task", "search"]) => searchTodos!(request, db)
		(POST, ["", "task", "new"]) => createTodo!(request, db)
		(POST, ["", "task", id, "delete"]) => deleteTodo!(db, id)
		(PUT, ["", "task", id, "complete"]) => updateTodo!(db, id, "Completed")
		(PUT, ["", "task", id, "in-progress"]) => updateTodo!(db, id, "In-Progress")

		(GET, ["", "treeview"]) => treePage!(db, session)
		(GET, ["", "user"]) => usersPage!(db, session)

		(GET, ["", "bigTask"]) => bigTaskPage!(db, url, session)
		(GET, ["", "bigTask", "downloadCsv"]) => Ok(csvResponse())
		(PUT, ["", "bigTask", "customerId", id]) =>
			updateBigTask!(request, db, id, CustomerReferenceField, session)
		(PUT, ["", "bigTask", "dateCreated", id]) =>
			updateBigTask!(request, db, id, CreatedDateField, session)
		(PUT, ["", "bigTask", "status", id]) => updateBigTask!(request, db, id, StatusField, session)

		_ => Err(NotFound(request.target()))
	}

register! : Server.Request, Sqlite.Db, Models.Session => Try(Response, AppError)
register! = |request, db, session| {
	form = readForm!(request)?
	username = form.get("user") ?? ""
	email = form.get("email") ?? ""

	if username.trim().is_empty() or email.trim().is_empty() {
		Ok(
			htmlResponse(
				400,
				Pages.register(session, username, email, "Username and email are required."),
				[],
			),
		)
	} else {
		match Db.registerUser!(db, username, email) {
			Ok({}) => Ok(redirect("/login"))
			Err(UserAlreadyExists) =>
				Ok(
					htmlResponse(
						409,
						Pages.register(session, username, email, "That username is already registered."),
						[],
					),
				)
			Err(err) => Err(appError(err))
		}
	}
}

login! : Server.Request, Sqlite.Db, Models.Session => Try(Response, AppError)
login! = |request, db, session| {
	form = readForm!(request)?
	username = form.get("user") ?? ""

	if username.trim().is_empty() {
		Ok(htmlResponse(400, Pages.login(session, username, "Username is required."), []))
	} else {
		match Db.login!(db, session.id, username) {
			Ok({}) => Ok(redirect("/"))
			Err(UserNotFound) =>
				Ok(htmlResponse(404, Pages.login(session, username, "No user with that name was found."), []))
			Err(err) => Err(appError(err))
		}
	}
}

logout! : Sqlite.Db => Try(Response, AppError)
logout! = |db| {
	id = Db.newSession!(db) ? appError
	Ok(redirectWithHeaders("/", [sessionCookie(id)]))
}

todoPage! : Sqlite.Db, Models.Session => Try(Response, AppError)
todoPage! = |db, session| {
	todos = Db.listTodos!(db, "") ? appError
	Ok(htmlResponse(200, Pages.todos(session, todos, ""), []))
}

todoList! : Sqlite.Db, Str => Try(Response, AppError)
todoList! = |db, filter| {
	todos = Db.listTodos!(db, filter) ? appError
	Ok(htmlResponse(200, Pages.todoList(todos, filter), []))
}

searchTodos! : Server.Request, Sqlite.Db => Try(Response, AppError)
searchTodos! = |request, db| {
	form = readForm!(request)?
	filter = form.get("filterTasks") ?? ""
	todoList!(db, filter)
}

createTodo! : Server.Request, Sqlite.Db => Try(Response, AppError)
createTodo! = |request, db| {
	form = readForm!(request)?
	task = form.get("task") ?? ""
	status = form.get("status") ?? "Not Started"

	match Db.createTodo!(db, task, status) {
		Ok({}) => Ok(redirect("/task"))
		Err(TaskWasEmpty) => Ok(redirect("/task"))
		Err(err) => Err(appError(err))
	}
}

deleteTodo! : Sqlite.Db, Str => Try(Response, AppError)
deleteTodo! = |db, idText| {
	id = parseId(idText)?
	Db.deleteTodo!(db, id) ? appError
	todoList!(db, "")
}

updateTodo! : Sqlite.Db, Str, Str => Try(Response, AppError)
updateTodo! = |db, idText, status| {
	id = parseId(idText)?
	Db.updateTodo!(db, id, status) ? appError
	todoList!(db, "")
}

treePage! : Sqlite.Db, Models.Session => Try(Response, AppError)
treePage! = |db, session| {
	tree = Db.todoTree!(db, 1) ? appError
	Ok(htmlResponse(200, Pages.tree(session, tree), []))
}

usersPage! : Sqlite.Db, Models.Session => Try(Response, AppError)
usersPage! = |db, session| {
	users = Db.listUsers!(db) ? appError
	Ok(htmlResponse(200, Pages.users(session, users), []))
}

bigTaskPage! : Sqlite.Db, Url, Models.Session => Try(Response, AppError)
bigTaskPage! = |db, url, session| {
	requireLogin(session)?
	params = Dict.from_list(Url.query_pairs(url))
	page = positiveParam(params, "page", 1)
	items = positiveParam(params, "updateItemsPerPage", positiveParam(params, "items", 25))
	sortBy = Models.SortColumn.from_str(params.get("sortBy") ?? "ID")
	sortDirection = Models.SortDirection.from_str(params.get("sortDirection") ?? "asc")
	tasks = Db.listBigTasks!(db, page, items, sortBy, sortDirection) ? appError
	total = Db.totalBigTasks!(db) ? appError
	pushUrl = "/bigTask?page=${page.to_str()}&items=${items.to_str()}&sortBy=${sortBy.to_str()}&sortDirection=${sortDirection.to_str()}"

	Ok(
		htmlResponse(
			200,
			Pages.bigTasks({ session, tasks, page, items, total, sortBy, sortDirection }),
			[{ name: "HX-Push-Url", value: pushUrl }],
		),
	)
}

updateBigTask! : Server.Request, Sqlite.Db, Str, BigTaskField, Models.Session => Try(Response, AppError)
updateBigTask! = |request, db, idText, field, session| {
	requireLogin(session)?
	id = parseId(idText)?
	form = readForm!(request)?
	value = form.get(field.form_name()) ?? ""

	match field.validate(value) {
		Ok({}) => {
			Db.updateBigTask!(db, id, field.to_update(value)) ? appError
			editor = field.editor({ idText, value, validation: "" })
			Ok(htmlResponse(200, editor, []))
		}
		Err(validation) => {
			editor = field.editor({ idText, value, validation })
			Ok(
				htmlResponse(
					422,
					editor,
					[],
				),
			)
		}
	}
}

getSession! : Server.Request, Sqlite.Db => Try({ session : Models.Session, setCookie : Bool }, AppError)
getSession! = |request, db|
	match sessionId(request) {
		Ok(id) =>
			match Db.getSession!(db, id) {
				Ok(session) => Ok({ session, setCookie: False })
				Err(SessionNotFound) => newGuestSession!(db)
				Err(err) => Err(appError(err))
			}
		Err(_) => newGuestSession!(db)
	}

newGuestSession! : Sqlite.Db => Try({ session : Models.Session, setCookie : Bool }, AppError)
newGuestSession! = |db| {
	id = Db.newSession!(db) ? appError
	Ok({
		session: Models.Session.{ id, user: Guest },
		setCookie: True,
	})
}

sessionId : Server.Request -> Try(I64, [InvalidSessionCookie])
sessionId = |request| {
	header = request.headers()
		.find_first(|item| item.name.with_ascii_lowercased() == "cookie")
		.map_err(|_| InvalidSessionCookie)?
	cookie = header.value.split_on(";")
		.find_first(|item| item.trim().starts_with("sessionId="))
		.map_err(|_| InvalidSessionCookie)?
	parts = cookie.trim().split_on("=")
	match parts {
		["sessionId", value] => I64.from_str(value).map_err(|_| InvalidSessionCookie)
		_ => Err(InvalidSessionCookie)
	}
}

requireLogin : Models.Session -> Try({}, AppError)
requireLogin = |session|
	match session.user {
		Guest => Err(Unauthorized)
		LoggedIn(_) => Ok({})
	}

readForm! : Server.Request => Try(Dict(Str, Str), AppError)
readForm! = |request| {
	body = request.body().with_limit(64 * 1024).read_all!()
		? |err| BadRequest("Unable to read form body: ${Str.inspect(err)}")
	MultipartFormData.parse_form_url_encoded(body)
		.map_err(|_| BadRequest("Malformed URL-encoded form data"))
}

parseId : Str -> Try(I64, AppError)
parseId = |value|
	I64.from_str(value).map_err(|_| BadRequest("Expected a valid numeric id"))

positiveParam : Dict(Str, Str), Str, I64 -> I64
positiveParam = |params, name, fallback|
	match params.get(name) {
		Ok(value) =>
			match I64.from_str(value) {
				Ok(number) if number > 0 => number
				_ => fallback
			}
		Err(_) => fallback
	}

validDate : Str -> Bool
validDate = |value|
	match value.split_on("-") {
		[year, month, day] =>
			year.to_utf8().len() == 4
				and month.to_utf8().len() == 2
					and day.to_utf8().len() == 2
						and I64.from_str(year).is_ok()
							and I64.from_str(month).is_ok()
								and I64.from_str(day).is_ok()
		_ => False
	}

appError : err -> AppError
appError = |err| AppErr(Str.inspect(err))

htmlResponse : U16, Html.Node, List(Header) -> Response
htmlResponse = |status, node, extraHeaders|
	Response.from_status(status)
		.with_headers(
			[{ name: "Content-Type", value: "text/html; charset=utf-8" }].concat(extraHeaders),
		)
		.with_body(Html.render(node).to_utf8())

bytesResponse : U16, List(U8), Str -> Response
bytesResponse = |status, body, contentType|
	Response.from_status(status)
		.with_headers([
			{ name: "Content-Type", value: contentType },
			{ name: "Cache-Control", value: "max-age=120" },
		])
		.with_body(body)

cacheableBytesResponse : U16, List(U8), Str -> Response
cacheableBytesResponse = |status, body, contentType|
	Response.from_status(status)
		.with_headers([
			{ name: "Content-Type", value: contentType },
			{ name: "Cache-Control", value: "public, max-age=31536000, immutable" },
		])
		.with_body(body)

redirect : Str -> Response
redirect = |location| redirectWithHeaders(location, [])

redirectWithHeaders : Str, List(Header) -> Response
redirectWithHeaders = |location, headers|
	Response.from_status(303)
		.with_headers([{ name: "Location", value: location }].concat(headers))

csvResponse : () -> Response
csvResponse = || {
	body = (
		\\ID,CustomerReferenceID,DateCreated,Status
		\\1,12345,2021-01-01,Raised
		\\2,67890,2021-01-02,Completed
		\\3,54321,2021-01-03,Deferred
		,
	).to_utf8()
	Response.from_status(200)
		.with_headers([
			{ name: "Content-Type", value: "text/csv; charset=utf-8" },
			{ name: "Content-Disposition", value: "attachment; filename=table.csv" },
			{ name: "Content-Length", value: body.len().to_str() },
		])
		.with_body(body)
}

logRequest! : Server.Request => Try({}, _)
logRequest! = |request| {
	date = Utc.to_iso_8601(Utc.now!())
	Stdout.line!("${date} ${Str.inspect(request.method())} ${request.target()}")
}

appOrigin : Url
appOrigin = "http://localhost"

robots_txt : List(U8)
robots_txt = (
	\\User-agent: *
	\\Allow: /
	,
).to_utf8()
