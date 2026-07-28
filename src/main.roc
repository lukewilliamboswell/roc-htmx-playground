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
import "site.js" as site_file : List(U8)
import "../vendor/bootstrap.bundle-5-3-2.min.js" as bootstrap_js_file : List(U8)
import "../vendor/bootstrap-5-3-2.min.css" as bootstrap_css_file : List(U8)
import "../vendor/htmx-2-0-3.min.js" as htmx_js_file : List(U8)

import Db
import Models
import Pages

Context : { db : Sqlite.Db }

AppError : [NewSession(I64), Unauthorized, BadRequest(Str), NotFound(Str), AppErr(Str)]

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64), ..])
init! = || {
	db_path = match Env.var!("DB_PATH") {
		Ok(path) => Path.from_os_str(path)
		Err(_) => return Err(Exit(2))
	}
	db = Sqlite.open!(Sqlite.default_config(db_path)) ? |_| Exit(2)

	Ok({
		config: Server.default_config,
		context: { db: db },
	})
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str), ..])
respond! = |request, { db }| {
	logRequest!(request) ? |err| ServerErr(Str.inspect(err))

	response = match handleRequest!(request, db) {
		Ok(value) => value
		Err(NewSession(id)) =>
			redirectWithHeaders(
				request.target(),
				[{ name: "Set-Cookie", value: "sessionId=${id.to_str()}; Path=/; HttpOnly; SameSite=Lax" }],
			)
		Err(Unauthorized) => htmlResponse(401, Pages.unauthorized, [])
		Err(BadRequest(message)) => textResponse(400, message)
		Err(NotFound(target)) => {
			Stderr.line!("404 Not Found ${target}") ?? {}
			textResponse(404, "Not Found")
		}
		Err(err) => {
			Stderr.line!("SERVER ERROR ${Str.inspect(err)}") ?? {}
			textResponse(500, "Internal Server Error")
		}
	}

	Ok(Server.respond(response))
}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64), ..])
shutdown! = |_reason, _context| Ok({})

handleRequest! : Server.Request, Sqlite.Db => Try(Response, AppError)
handleRequest! = |request, db| {
	url = Url.resolve(appOrigin, request.target()) ? |_| BadRequest("Invalid request target")
	segments = Str.split_on(Url.path(url), "/")

	match (request.method(), segments) {
		(GET, ["", ""]) => {
			session = getSession!(request, db)?
			Ok(htmlResponse(200, Pages.home(session), []))
		}
		(GET, ["", "robots.txt"]) => Ok(bytesResponse(200, robots_txt, "text/plain; charset=utf-8"))
		(GET, ["", "styles.css"]) => Ok(bytesResponse(200, styles_file, "text/css; charset=utf-8"))
		(GET, ["", "site.js"]) => Ok(bytesResponse(200, site_file, "text/javascript; charset=utf-8"))
		(GET, ["", "bootstrap.bundle.min.js"]) =>
			Ok(bytesResponse(200, bootstrap_js_file, "text/javascript; charset=utf-8"))
		(GET, ["", "bootstrap.min.css"]) =>
			Ok(bytesResponse(200, bootstrap_css_file, "text/css; charset=utf-8"))
		(GET, ["", "htmx.min.js"]) =>
			Ok(bytesResponse(200, htmx_js_file, "text/javascript; charset=utf-8"))

		(GET, ["", "register"]) => Ok(htmlResponse(200, Pages.register("", "", ""), []))
		(POST, ["", "register"]) => register!(request, db)

		(GET, ["", "login"]) => {
			session = getSession!(request, db)?
			Ok(htmlResponse(200, Pages.login(session, "", ""), []))
		}
		(POST, ["", "login"]) => login!(request, db)
		(POST, ["", "logout"]) => logout!(db)

		(GET, ["", "task", "new"]) => Ok(redirect("/task"))
		(GET, ["", "task"]) => todoPage!(request, db)
		(GET, ["", "task", "list"]) => todoList!(db, "")
		(POST, ["", "task", "search"]) => searchTodos!(request, db)
		(POST, ["", "task", "new"]) => createTodo!(request, db)
		(POST, ["", "task", id, "delete"]) => deleteTodo!(db, id)
		(PUT, ["", "task", id, "complete"]) => updateTodo!(db, id, "Completed")
		(PUT, ["", "task", id, "in-progress"]) => updateTodo!(db, id, "In-Progress")

		(GET, ["", "treeview"]) => treePage!(request, db)
		(GET, ["", "user"]) => usersPage!(request, db)

		(GET, ["", "bigTask"]) => bigTaskPage!(request, db, url)
		(GET, ["", "bigTask", "downloadCsv"]) => Ok(csvResponse())
		(PUT, ["", "bigTask", "customerId", id]) => updateBigTaskCustomer!(request, db, id)
		(PUT, ["", "bigTask", "dateCreated", id]) => updateBigTaskDate!(request, db, id)
		(PUT, ["", "bigTask", "status", id]) => updateBigTaskStatus!(request, db, id)

		_ => Err(NotFound(request.target()))
	}
}

register! : Server.Request, Sqlite.Db => Try(Response, AppError)
register! = |request, db| {
	form = readForm!(request)?
	username = Dict.get(form, "user") ?? ""
	email = Dict.get(form, "email") ?? ""

	if Str.is_empty(Str.trim(username)) or Str.is_empty(Str.trim(email)) {
		Ok(htmlResponse(400, Pages.register(username, email, "Username and email are required."), []))
	} else {
		match Db.registerUser!(db, username, email) {
			Ok({}) => Ok(redirect("/login"))
			Err(UserAlreadyExists) =>
				Ok(htmlResponse(409, Pages.register(username, email, "That username is already registered."), []))
			Err(err) => Err(AppErr(Str.inspect(err)))
		}
	}
}

login! : Server.Request, Sqlite.Db => Try(Response, AppError)
login! = |request, db| {
	session = getSession!(request, db)?
	form = readForm!(request)?
	username = Dict.get(form, "user") ?? ""

	if Str.is_empty(Str.trim(username)) {
		Ok(htmlResponse(400, Pages.login(session, username, "Username is required."), []))
	} else {
		match Db.login!(db, session.id, username) {
			Ok({}) => Ok(redirect("/"))
			Err(UserNotFound) =>
				Ok(htmlResponse(404, Pages.login(session, username, "No user with that name was found."), []))
			Err(err) => Err(AppErr(Str.inspect(err)))
		}
	}
}

logout! : Sqlite.Db => Try(Response, AppError)
logout! = |db| {
	id = Db.newSession!(db) ? |err| AppErr(Str.inspect(err))
	Ok(
		redirectWithHeaders(
			"/",
			[{ name: "Set-Cookie", value: "sessionId=${id.to_str()}; Path=/; HttpOnly; SameSite=Lax" }],
		),
	)
}

todoPage! : Server.Request, Sqlite.Db => Try(Response, AppError)
todoPage! = |request, db| {
	session = getSession!(request, db)?
	todos = Db.listTodos!(db, "") ? |err| AppErr(Str.inspect(err))
	Ok(htmlResponse(200, Pages.todos(session, todos, ""), []))
}

todoList! : Sqlite.Db, Str => Try(Response, AppError)
todoList! = |db, filter| {
	todos = Db.listTodos!(db, filter) ? |err| AppErr(Str.inspect(err))
	Ok(htmlResponse(200, Pages.todoList(todos, filter), []))
}

searchTodos! : Server.Request, Sqlite.Db => Try(Response, AppError)
searchTodos! = |request, db| {
	form = readForm!(request)?
	filter = Dict.get(form, "filterTasks") ?? ""
	todoList!(db, filter)
}

createTodo! : Server.Request, Sqlite.Db => Try(Response, AppError)
createTodo! = |request, db| {
	form = readForm!(request)?
	task = Dict.get(form, "task") ?? ""
	status = Dict.get(form, "status") ?? "Not Started"

	match Db.createTodo!(db, task, status) {
		Ok({}) => Ok(redirect("/task"))
		Err(TaskWasEmpty) => Ok(redirect("/task"))
		Err(err) => Err(AppErr(Str.inspect(err)))
	}
}

deleteTodo! : Sqlite.Db, Str => Try(Response, AppError)
deleteTodo! = |db, idText| {
	id = parseId(idText)?
	Db.deleteTodo!(db, id) ? |err| AppErr(Str.inspect(err))
	todoList!(db, "")
}

updateTodo! : Sqlite.Db, Str, Str => Try(Response, AppError)
updateTodo! = |db, idText, status| {
	id = parseId(idText)?
	Db.updateTodo!(db, id, status) ? |err| AppErr(Str.inspect(err))
	Ok(
		Response.from_status(200)
			.with_headers([{ name: "HX-Trigger", value: "todosUpdated" }]),
	)
}

treePage! : Server.Request, Sqlite.Db => Try(Response, AppError)
treePage! = |request, db| {
	session = getSession!(request, db)?
	tree = Db.todoTree!(db, 1) ? |err| AppErr(Str.inspect(err))
	Ok(htmlResponse(200, Pages.tree(session, tree), []))
}

usersPage! : Server.Request, Sqlite.Db => Try(Response, AppError)
usersPage! = |request, db| {
	session = getSession!(request, db)?
	users = Db.listUsers!(db) ? |err| AppErr(Str.inspect(err))
	Ok(htmlResponse(200, Pages.users(session, users), []))
}

bigTaskPage! : Server.Request, Sqlite.Db, Url => Try(Response, AppError)
bigTaskPage! = |request, db, url| {
	session = getSession!(request, db)?
	requireLogin(session)?
	params = Dict.from_list(Url.query_pairs(url))
	page = positiveParam(params, "page", 1)
	items = positiveParam(params, "updateItemsPerPage", positiveParam(params, "items", 25))
	sortBy = Dict.get(params, "sortBy") ?? "ID"
	sortDirection = match Str.with_ascii_lowercased(Dict.get(params, "sortDirection") ?? "asc") {
		"desc" => Descending
		_ => Ascending
	}
	tasks = Db.listBigTasks!(db, page, items, sortBy, sortDirection) ? |err| AppErr(Str.inspect(err))
	total = Db.totalBigTasks!(db) ? |err| AppErr(Str.inspect(err))
	directionText = match sortDirection {
		Ascending => "asc"
		Descending => "desc"
	}
	pushUrl = "/bigTask?page=${page.to_str()}&items=${items.to_str()}&sortBy=${sortBy}&sortDirection=${directionText}"

	Ok(
		htmlResponse(
			200,
			Pages.bigTasks({ session, tasks, page, items, total, sortBy, sortDirection }),
			[{ name: "HX-Push-Url", value: pushUrl }],
		),
	)
}

updateBigTaskCustomer! : Server.Request, Sqlite.Db, Str => Try(Response, AppError)
updateBigTaskCustomer! = |request, db, idText| {
	session = getSession!(request, db)?
	requireLogin(session)?
	id = parseId(idText)?
	form = readForm!(request)?
	value = Dict.get(form, "CustomerReferenceID") ?? ""
	valid = match I64.from_str(value) {
		Ok(number) => number > 0 and number < 100_000
		Err(_) => False
	}

	if valid {
		Db.updateBigTask!(db, id, CustomerReferenceId(value)) ? |err| AppErr(Str.inspect(err))
		Ok(htmlResponse(200, Pages.bigTaskInput("/bigTask/customerId/${idText}", "CustomerReferenceID", "text", value, ""), []))
	} else {
		Ok(
			htmlResponse(
				422,
				Pages.bigTaskInput(
					"/bigTask/customerId/${idText}",
					"CustomerReferenceID",
					"text",
					value,
					"Must be a number between 0 and 100,000.",
				),
				[],
			),
		)
	}
}

updateBigTaskDate! : Server.Request, Sqlite.Db, Str => Try(Response, AppError)
updateBigTaskDate! = |request, db, idText| {
	session = getSession!(request, db)?
	requireLogin(session)?
	id = parseId(idText)?
	form = readForm!(request)?
	value = Dict.get(form, "DateCreated") ?? ""

	if validDate(value) {
		Db.updateBigTask!(db, id, DateCreated(value)) ? |err| AppErr(Str.inspect(err))
		Ok(htmlResponse(200, Pages.bigTaskInput("/bigTask/dateCreated/${idText}", "DateCreated", "date", value, ""), []))
	} else {
		Ok(
			htmlResponse(
				422,
				Pages.bigTaskInput(
					"/bigTask/dateCreated/${idText}",
					"DateCreated",
					"date",
					value,
					"Must use date format yyyy-mm-dd.",
				),
				[],
			),
		)
	}
}

updateBigTaskStatus! : Server.Request, Sqlite.Db, Str => Try(Response, AppError)
updateBigTaskStatus! = |request, db, idText| {
	session = getSession!(request, db)?
	requireLogin(session)?
	id = parseId(idText)?
	form = readForm!(request)?
	value = Dict.get(form, "Status") ?? ""
	valid = ["Raised", "Completed", "Deferred", "Approved", "In-Progress"].contains(value)

	if valid {
		Db.updateBigTask!(db, id, Status(value)) ? |err| AppErr(Str.inspect(err))
		Ok(htmlResponse(200, Pages.bigTaskStatus("/bigTask/status/${idText}", value, ""), []))
	} else {
		Ok(
			htmlResponse(
				422,
				Pages.bigTaskStatus("/bigTask/status/${idText}", value, "Choose a valid status."),
				[],
			),
		)
	}
}

getSession! : Server.Request, Sqlite.Db => Try(Models.Session, AppError)
getSession! = |request, db|
	match sessionId(request) {
		Ok(id) =>
			match Db.getSession!(db, id) {
				Ok(session) => Ok(session)
				Err(SessionNotFound) => {
					newId = Db.newSession!(db) ? |err| AppErr(Str.inspect(err))
					Err(NewSession(newId))
				}
				Err(err) => Err(AppErr(Str.inspect(err)))
			}
		Err(_) => {
			id = Db.newSession!(db) ? |err| AppErr(Str.inspect(err))
			Err(NewSession(id))
		}
	}

sessionId : Server.Request -> Try(I64, [InvalidSessionCookie])
sessionId = |request| {
	header = request.headers()
		.find_first(|item| Str.with_ascii_lowercased(item.name) == "cookie")
		.map_err(|_| InvalidSessionCookie)?
	cookie = Str.split_on(header.value, ";")
		.find_first(|item| Str.starts_with(Str.trim(item), "sessionId="))
		.map_err(|_| InvalidSessionCookie)?
	parts = Str.split_on(Str.trim(cookie), "=")
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
	match Dict.get(params, name) {
		Ok(value) =>
			match I64.from_str(value) {
				Ok(number) if number > 0 => number
				_ => fallback
			}
		Err(_) => fallback
	}

validDate : Str -> Bool
validDate = |value|
	match Str.split_on(value, "-") {
		[year, month, day] =>
			Str.to_utf8(year).len() == 4
				and Str.to_utf8(month).len() == 2
					and Str.to_utf8(day).len() == 2
						and I64.from_str(year).is_ok()
							and I64.from_str(month).is_ok()
								and I64.from_str(day).is_ok()
		_ => False
	}

htmlResponse = |status, node, extraHeaders|
	Response.from_status(status)
		.with_headers(
			[{ name: "Content-Type", value: "text/html; charset=utf-8" }].concat(extraHeaders),
		)
		.with_body(Str.to_utf8(Html.render(node)))

textResponse = |status, body|
	Response.from_status(status)
		.with_headers([{ name: "Content-Type", value: "text/plain; charset=utf-8" }])
		.with_body(Str.to_utf8(body))

bytesResponse = |status, body, contentType|
	Response.from_status(status)
		.with_headers([
			{ name: "Content-Type", value: contentType },
			{ name: "Cache-Control", value: "max-age=120" },
		])
		.with_body(body)

redirect = |location| redirectWithHeaders(location, [])

redirectWithHeaders = |location, headers|
	Response.from_status(303)
		.with_headers([{ name: "Location", value: location }].concat(headers))

csvResponse = || {
	body = Str.to_utf8(
		\\ID,CustomerReferenceID,DateCreated,Status
		\\1,12345,2021-01-01,Raised
		\\2,67890,2021-01-02,Completed
		\\3,54321,2021-01-03,Deferred
		,
	)
	Response.from_status(200)
		.with_headers([
			{ name: "Content-Type", value: "text/csv; charset=utf-8" },
			{ name: "Content-Disposition", value: "attachment; filename=table.csv" },
			{ name: "Content-Length", value: body.len().to_str() },
		])
		.with_body(body)
}

logRequest! = |request| {
	date = Utc.to_iso_8601(Utc.now!())
	Stdout.line!("${date} ${Str.inspect(request.method())} ${request.target()}")
}

appOrigin : Url
appOrigin = "http://localhost"

robots_txt : List(U8)
robots_txt = Str.to_utf8(
	\\User-agent: *
	\\Disallow: /
	,
)
