app [Context, program] {
	pf: platform "../../basic-webserver/platform/main.roc",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	gregorian: "https://cdn.jasperwoudenberg.com/roc-gregorian-v1.0.0-rc.2/Ce3xuHN92F5oGRuzjUTmm65jULAEj8pvvrTBmZJzE1M4.tar.zst",
}

import pf.Env
import pf.OsStr
import pf.Path
import pf.Server
import pf.Sqlite
import pf.Stdout
import pf.Url
import http.Response

import AppError
import Actor
import Authentication
import AuthHandler
import BigTask
import BigTaskHandler
import BigTaskStore
import Company
import CompanyHandler
import CompanyStore
import DateTime
import HomeView
import Http
import MemberStore
import Person
import PersonHandler
import PersonStore
import Route
import Session
import SessionHandler
import SessionStore
import Todo
import TodoHandler
import TodoStore
import UserHandler
import UserStore
import Workspace
import WorkspaceStore
import WorkTask
import WorkTaskHandler
import WorkTaskStore

## The composition root owns concrete adapter selection. Feature handlers only
## receive the stores they actually use.
Context := {
	authMode : Authentication.Mode,
	db : Sqlite.Db,
	sessionStore : SessionStore,
	memberStore : MemberStore,
	workspace : Workspace,
	userStore : UserStore,
	todoStore : TodoStore,
	bigTaskStore : BigTaskStore,
	companyStore : CompanyStore,
	personStore : PersonStore,
	workTaskStore : WorkTaskStore,
}

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64), ..])
init! = || {
	db_path = match Env.var!("DB_PATH") {
		Ok(path) => Path.from_os_str(path)
		Err(_) => return Err(Exit(2))
	}
	db = Sqlite.open!(Sqlite.default_config(db_path)) ? |_| Exit(2)
	schema_version : I64
	schema_version = Sqlite.query!({
		db,
		query: "PRAGMA user_version;",
		params: {},
		limits: Sqlite.default_query_limits,
	}) ? |_| Exit(2)
	if schema_version != 1 {
		Stdout.line!("Database schema version must be 1, received ${schema_version.to_str()}") ? |_| Exit(2)
		return Err(Exit(2))
	}
	public_origin = match Env.var!("PUBLIC_ORIGIN") {
		Ok(value) => OsStr.display(value)
		Err(_) => return Err(Exit(2))
	}
	auth_mode = Authentication.Mode.from_public_origin(public_origin)
		? |_| Exit(2)
	workspace_store = WorkspaceStore.new(db)
	workspace = WorkspaceStore.load!(workspace_store) ? |_| Exit(2)
	configured_timezone = match Env.var!("TZ") {
		Ok(value) => OsStr.display(value)
		Err(_) => ""
	}
	if !Workspace.timezone_matches(workspace, configured_timezone) {
		Stdout.line!(
			"TZ must match workspace timezone ${workspace.timezone.to_str()}, received ${configured_timezone}",
		) ? |_| Exit(2)
		return Err(Exit(2))
	}
	asset_path = match Env.var!("ASSET_PATH") {
		Ok(path) => Path.from_os_str(path)
		Err(_) => Path.utf8("dist/assets")
	}
	asset_files = Server.file_root({ id: "assets", path: asset_path })
	listen_port = match Env.var!("PORT") {
		Ok(value) => U16.from_str(OsStr.display(value)) ?? 8000
		Err(_) => 8000
	}
	config_with_listen = Server.with_listen(
		Server.default_config,
		{ host: "127.0.0.1", port: listen_port },
	)
	config_with_files = Server.with_file_roots(config_with_listen, [asset_files])
	config = Server.with_native_routes(
		config_with_files,
		{
			files: [
				Server.static_mount_with_cache({
					at: "/assets",
					files: asset_files,
					cache: Server.public_for(31_536_000),
				}),
			],
			liveness: [],
			readiness: [],
		},
	)

	Ok({
		config,
		context: Context.{
			authMode: auth_mode,
			db,
			sessionStore: SessionStore.new(db),
			memberStore: MemberStore.new(db),
			workspace,
			userStore: UserStore.new(db),
			todoStore: TodoStore.new(db),
			bigTaskStore: BigTaskStore.new(db),
			companyStore: CompanyStore.new(db),
			personStore: PersonStore.new(db),
			workTaskStore: WorkTaskStore.new(db),
		},
	})
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str), ..])
respond! = |request, context| {
	log_request!(request) ? |err| ServerErr(Str.inspect(err))

	response = match resource_target(request.target()) {
		Ok(target) =>
			match Url.resolve(app_origin, target) {
				Ok(url) => route_request!(request, context, target, url)
				Err(_) =>
					error_with_auth!(
						request,
						context,
						AppError.BadRequest("Invalid request target"),
					)
				}
		Err(_) =>
			error_with_auth!(
				request,
				context,
				AppError.BadRequest("Invalid request target"),
			)
		}

	Ok(Server.respond(response))
}

## Native `/assets` requests are handled by basic-webserver before this point.
## The remaining app-owned file is dispatched before session lookup. Every
## other application response resolves authentication exactly once.
route_request! : Server.Request, Context, Str, Url => Response
route_request! = |request, context, target, url|
	if Url.path(url) == "/healthz" {
		health_response!(context.db)
	} else {
		match Route.parse(request, target, url) {
			Ok(Route.Serve(asset)) => asset_response(asset)
			Ok(route) => route_with_session!(request, context, route)
			Err(parse_error) =>
				error_with_auth!(
					request,
					context,
					parse_error_to_app_error(parse_error),
				)
			}
	}

route_with_session! : Server.Request, Context, Route => Response
route_with_session! = |request, context, route|
	match resolve_auth!(request, context) {
		Err(error) => Http.error_response_for!(request, Session.anonymous, error)
		Ok({ session, setCookie }) => {
			response = match dispatch!(request, context, session, route) {
				Ok(value) => value
				Err(error) => Http.error_response_for!(request, session, error)
			}

			if setCookie {
				cookie = Http.session_cookie(session.id)
				Response.add_header(response, cookie.name, cookie.value)
			} else {
				response
			}
		}
	}

error_with_auth! : Server.Request, Context, AppError => Response
error_with_auth! = |request, context, route_error|
	match resolve_auth!(request, context) {
		Err(auth_error) =>
			Http.error_response_for!(request, Session.anonymous, auth_error)
		Ok({ session, .. }) =>
			Http.error_response_for!(request, session, route_error)
		}

resolve_auth! : Server.Request, Context => Try(SessionHandler.State, AppError)
resolve_auth! = |request, context|
	match context.authMode {
		Authentication.Mode.Development(_) =>
			SessionHandler.resolve!(request, context.sessionStore)
		Authentication.Mode.Tailscale(_) => {
			identity = Authentication.tailscale_identity(request.headers())
				? |_| AppError.Forbidden
			match MemberStore.find_active_by_email!(context.memberStore, identity.login) {
				Ok(member) =>
					Ok({
						session: Session.trusted(member),
						setCookie: Bool.False,
					})
				Err(MemberNotFound) => Err(AppError.Forbidden)
				Err(InactiveMember) => Err(AppError.Forbidden)
				Err(DbErr(error)) => Err(AppError.from(error))
			}
		}
	}

health_response! : Sqlite.Db => Response
health_response! = |db| {
	version : Try(I64, _)
	version = Sqlite.query!({
		db,
		query: "PRAGMA user_version;",
		params: {},
		limits: Sqlite.default_query_limits,
	})
	match version {
		Ok(1) =>
			Response.from_status(200)
				.with_headers([
					{ name: "Content-Type", value: "text/plain; charset=utf-8" },
					{ name: "Cache-Control", value: "no-store" },
				])
				.with_body("ok\n".to_utf8())
		_ =>
			Response.from_status(503)
				.with_headers([
					{ name: "Content-Type", value: "text/plain; charset=utf-8" },
					{ name: "Cache-Control", value: "no-store" },
				])
				.with_body("unavailable\n".to_utf8())
		}
}

dispatch! : Server.Request, Context, Session, Route => Try(Response, AppError)
dispatch! = |request, context, session, route|
	match route {
		Route.Visit(location) => visit!(context, session, location)
		Route.Post(action) => {
			Http.require_same_origin(
				request,
				Authentication.Mode.public_origin(context.authMode),
			)?
			post!(request, context, session, action)
		}
		Route.Put(action) => {
			Http.require_same_origin(
				request,
				Authentication.Mode.public_origin(context.authMode),
			)?
			put!(request, context, session, action)
		}
		Route.Serve(asset) => Ok(asset_response(asset))
	}

visit! : Context, Session, Route.Location => Try(Response, AppError)
visit! = |context, session, location|
	match location {
		Route.Location.AtPage(page) =>
			match page {
				Route.Page.Home => Ok(Http.html(200, HomeView.page(session), []))
				Route.Page.Register if Authentication.Mode.is_development(context.authMode) =>
					Ok(AuthHandler.register_page(session))
				Route.Page.Register => Err(AppError.NotFound("registration"))
				Route.Page.Login if Authentication.Mode.is_development(context.authMode) =>
					Ok(AuthHandler.login_page(session))
				Route.Page.Login => Err(AppError.NotFound("login"))
				Route.Page.Todos =>
					TodoHandler.page!(context.todoStore, session, Todo.Filter.empty)
				Route.Page.TodoTree => TodoHandler.tree_page!(context.todoStore, session)
				Route.Page.Users => UserHandler.page!(context.userStore, session)
				Route.Page.Companies =>
					CompanyHandler.page!(
						context.companyStore,
						actor_from_session(session, context.workspace)?,
						Company.Filter.empty,
					)
				Route.Page.CompanyNew =>
					Ok(
						CompanyHandler.new_page(
							actor_from_session(session, context.workspace)?,
						),
					)
				Route.Page.People =>
					PersonHandler.page!(
						context.personStore,
						actor_from_session(session, context.workspace)?,
						Person.Filter.empty,
					)
				Route.Page.PersonNew =>
					PersonHandler.new_page!(
						context.companyStore,
						actor_from_session(session, context.workspace)?,
						None,
					)
				Route.Page.Work =>
					WorkTaskHandler.page!(
						context.workTaskStore,
						actor_from_session(session, context.workspace)?,
					)
				Route.Page.BigTasks =>
					BigTaskHandler.page!(context.bigTaskStore, BigTask.Query.default, session)
				}
		Route.Location.TodoList => TodoHandler.list!(context.todoStore, Todo.Filter.empty)
		Route.Location.TodoSearch(filter) =>
			TodoHandler.page!(context.todoStore, session, filter)
		Route.Location.TodoNewCompatibility => Ok(TodoHandler.new_compatibility())
		Route.Location.BigTasks(query) =>
			BigTaskHandler.page!(context.bigTaskStore, query, session)
		Route.Location.BigTaskCsv => Ok(BigTaskHandler.csv())
		Route.Location.CompanySearch(filter) =>
			CompanyHandler.page!(
				context.companyStore,
				actor_from_session(session, context.workspace)?,
				filter,
			)
		Route.Location.CompanyDetail(id) =>
			CompanyHandler.detail!(
				context.companyStore,
				context.personStore,
				context.workTaskStore,
				actor_from_session(session, context.workspace)?,
				id,
			)
		Route.Location.CompanyEdit(id) =>
			CompanyHandler.edit_page!(
				context.companyStore,
				actor_from_session(session, context.workspace)?,
				id,
			)
		Route.Location.PersonSearch(filter) =>
			PersonHandler.page!(
				context.personStore,
				actor_from_session(session, context.workspace)?,
				filter,
			)
		Route.Location.PersonDetail(id) =>
			PersonHandler.detail!(
				context.personStore,
				context.workTaskStore,
				actor_from_session(session, context.workspace)?,
				id,
			)
		Route.Location.PersonEdit(id) =>
			PersonHandler.edit_page!(
				context.personStore,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
				id,
			)
		Route.Location.PersonNewForCompany(company_id) =>
			PersonHandler.new_page!(
				context.companyStore,
				actor_from_session(session, context.workspace)?,
				Some(company_id),
			)
		}

actor_from_session : Session, Workspace -> Try(Actor, AppError)
actor_from_session = |session, workspace|
	match Actor.from_session(session, workspace) {
		Ok(actor) => Ok(actor)
		Err(_) => Err(AppError.Unauthorized)
	}

post! : Server.Request, Context, Session, Route.PostAction => Try(Response, AppError)
post! = |request, context, session, action|
	match action {
		Route.PostAction.Register if Authentication.Mode.is_development(context.authMode) =>
			AuthHandler.register!(request, context.memberStore, session)
		Route.PostAction.Register => Err(AppError.Forbidden)
		Route.PostAction.Login if Authentication.Mode.is_development(context.authMode) =>
			AuthHandler.login!(request, context.memberStore, session)
		Route.PostAction.Login => Err(AppError.Forbidden)
		Route.PostAction.Logout if Authentication.Mode.is_development(context.authMode) =>
			AuthHandler.logout!(context.sessionStore)
		Route.PostAction.Logout => Err(AppError.Forbidden)
		Route.PostAction.CreateTodo =>
			TodoHandler.create!(request, context.todoStore)
		Route.PostAction.DeleteTodo(id) =>
			TodoHandler.delete!(context.todoStore, id)
		Route.PostAction.PreviewCompany =>
			CompanyHandler.preview!(
				request,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
			)
		Route.PostAction.CreateCompany =>
			CompanyHandler.create!(
				request,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
			)
		Route.PostAction.UpdateCompany(id) =>
			CompanyHandler.update!(
				request,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
				id,
			)
		Route.PostAction.PreviewPerson =>
			PersonHandler.preview!(
				request,
				context.personStore,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
			)
		Route.PostAction.CreatePerson =>
			PersonHandler.create!(
				request,
				context.personStore,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
			)
		Route.PostAction.UpdatePerson(id) =>
			PersonHandler.update!(
				request,
				context.personStore,
				context.companyStore,
				actor_from_session(session, context.workspace)?,
				id,
			)
		Route.PostAction.AddPersonEmail(id) => {
			_ = actor_from_session(session, context.workspace)?
			PersonHandler.add_contact!(request, context.personStore, id, Email)
		}
		Route.PostAction.AddPersonPhone(id) => {
			_ = actor_from_session(session, context.workspace)?
			PersonHandler.add_contact!(request, context.personStore, id, Phone)
		}
		Route.PostAction.PromotePersonEmail(id, contact_id) => {
			_ = actor_from_session(session, context.workspace)?
			PersonHandler.make_primary!(context.personStore, id, Email, contact_id)
		}
		Route.PostAction.PromotePersonPhone(id, contact_id) => {
			_ = actor_from_session(session, context.workspace)?
			PersonHandler.make_primary!(context.personStore, id, Phone, contact_id)
		}
		Route.PostAction.DeletePersonEmail(id, contact_id) => {
			_ = actor_from_session(session, context.workspace)?
			PersonHandler.delete_contact!(context.personStore, id, Email, contact_id)
		}
		Route.PostAction.DeletePersonPhone(id, contact_id) => {
			_ = actor_from_session(session, context.workspace)?
			PersonHandler.delete_contact!(context.personStore, id, Phone, contact_id)
		}
		Route.PostAction.CreateCompanyTask(id) =>
			WorkTaskHandler.create!(
				request,
				context.workTaskStore,
				actor_from_session(session, context.workspace)?,
				WorkTask.Related.Company(id.to_str()),
			)
		Route.PostAction.CreatePersonTask(id) =>
			WorkTaskHandler.create!(
				request,
				context.workTaskStore,
				actor_from_session(session, context.workspace)?,
				WorkTask.Related.Person(id.to_str()),
			)
		Route.PostAction.CompleteTask(id, task_context) =>
			WorkTaskHandler.complete!(
				context.workTaskStore,
				actor_from_session(session, context.workspace)?,
				id,
				task_context,
			)
		}

put! : Server.Request, Context, Session, Route.PutAction => Try(Response, AppError)
put! = |request, context, session, action|
	match action {
		Route.PutAction.CompleteTodo(id) =>
			TodoHandler.update!(context.todoStore, id, Todo.Status.Completed)
		Route.PutAction.StartTodo(id) =>
			TodoHandler.update!(context.todoStore, id, Todo.Status.InProgress)
		Route.PutAction.UpdateBigTask(id, field) =>
			BigTaskHandler.update!(
				request,
				context.bigTaskStore,
				session,
				id,
				field,
			)
		}

parse_error_to_app_error : Route.ParseError -> AppError
parse_error_to_app_error = |error|
	match error {
		Route.ParseError.InvalidTodoId(value) =>
			AppError.BadRequest("Expected a valid task id, received ${value}")
		Route.ParseError.InvalidBigTaskId(value) =>
			AppError.BadRequest("Expected a valid BigTask id, received ${value}")
		Route.ParseError.NotFound(target) => AppError.NotFound(target)
	}

asset_response : Route.Asset -> Response
asset_response = |asset|
	match asset {
		Route.Asset.Robots => Http.bytes(200, robots_txt, "text/plain; charset=utf-8")

		## Native assets never reach `respond!`. Listing them explicitly keeps
		## this match exhaustive if the asset vocabulary grows.
		Route.Asset.Stylesheet => Response.from_status(404)
		Route.Asset.Htmx => Response.from_status(404)
		Route.Asset.Interactions => Response.from_status(404)
		Route.Asset.PlanningDesk => Response.from_status(404)
		Route.Asset.PlanningDesk480 => Response.from_status(404)
		Route.Asset.PlanningDesk640 => Response.from_status(404)
		Route.Asset.PlanningDesk720 => Response.from_status(404)
		Route.Asset.PlanningDesk960 => Response.from_status(404)
		Route.Asset.TasksIcon => Response.from_status(404)
		Route.Asset.UsersIcon => Response.from_status(404)
		Route.Asset.TreeIcon => Response.from_status(404)
		Route.Asset.TableIcon => Response.from_status(404)
	}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64), ..])
shutdown! = |_reason, _context| Ok({})

log_request! : Server.Request => Try({}, _)
log_request! = |request| {
	date = DateTime.now_utc!()
	Stdout.line!("${date} ${Str.inspect(request.method())} ${Str.inspect(request.target())}")
}

resource_target : Server.Target -> Try(Str, [UnsupportedRequestTarget])
resource_target = |target|
	match target {
		Resource({ raw_path, raw_query }) =>
			Ok(
				match raw_query {
					Absent => raw_path
					Present(query) => "${raw_path}?${query}"
				},
			)
		_ => Err(UnsupportedRequestTarget)
	}

app_origin : Url
app_origin = "http://localhost"

robots_txt : List(U8)
robots_txt = (
	\\User-agent: *
	\\Allow: /
	,
).to_utf8()
