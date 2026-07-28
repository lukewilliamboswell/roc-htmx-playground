app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.14.0/9mrSfhWKEXsrPUW2oHdZZGov1oMRryvvACDT8p7E97PY.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Env
import pf.OsStr
import pf.Path
import pf.Server
import pf.Sqlite
import pf.Stdout
import pf.Url
import pf.Utc
import http.Response

import AppError
import Actor
import AuthHandler
import BigTask
import BigTaskHandler
import BigTaskStore
import Company
import CompanyHandler
import CompanyStore
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
		context: Context.{
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

	response = match Url.resolve(app_origin, request.target()) {
		Ok(url) => route_request!(request, context, url)
		Err(_) =>
			Http.error_response!(
				Session.anonymous,
				AppError.BadRequest("Invalid request target"),
			)
		}

	Ok(Server.respond(response))
}

## Native `/assets` requests are handled by basic-webserver before this point.
## The remaining app-owned file is dispatched before session lookup. Every
## application route resolves its session exactly once.
route_request! : Server.Request, Context, Url => Response
route_request! = |request, context, url|
	match Route.parse(request, url) {
		Ok(Route.Serve(asset)) => asset_response(asset)
		Ok(route) => route_with_session!(request, context, route)
		Err(parse_error) =>
			error_with_session!(
				request,
				context.sessionStore,
				parse_error_to_app_error(parse_error),
			)
		}

route_with_session! : Server.Request, Context, Route => Response
route_with_session! = |request, context, route|
	match SessionHandler.resolve!(request, context.sessionStore) {
		Err(error) => Http.error_response!(Session.anonymous, error)
		Ok({ session, setCookie }) => {
			response = match dispatch!(request, context, session, route) {
				Ok(value) => value
				Err(error) => Http.error_response!(session, error)
			}

			if setCookie {
				cookie = Http.session_cookie(session.id)
				Response.add_header(response, cookie.name, cookie.value)
			} else {
				response
			}
		}
	}

error_with_session! : Server.Request, SessionStore, AppError => Response
error_with_session! = |request, store, error|
	match SessionHandler.resolve!(request, store) {
		Ok({ session, .. }) => Http.error_response!(session, error)
		Err(session_error) => Http.error_response!(Session.anonymous, session_error)
	}

dispatch! : Server.Request, Context, Session, Route => Try(Response, AppError)
dispatch! = |request, context, session, route|
	match route {
		Route.Visit(location) => visit!(context, session, location)
		Route.Post(action) => post!(request, context, session, action)
		Route.Put(action) => put!(request, context, session, action)
		Route.Serve(asset) => Ok(asset_response(asset))
	}

visit! : Context, Session, Route.Location => Try(Response, AppError)
visit! = |context, session, location|
	match location {
		Route.Location.AtPage(page) =>
			match page {
				Route.Page.Home => Ok(Http.html(200, HomeView.page(session), []))
				Route.Page.Register => Ok(AuthHandler.register_page(session))
				Route.Page.Login => Ok(AuthHandler.login_page(session))
				Route.Page.Todos => TodoHandler.page!(context.todoStore, session)
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
						"",
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
				company_id.to_str(),
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
		Route.PostAction.Register =>
			AuthHandler.register!(request, context.memberStore, session)
		Route.PostAction.Login =>
			AuthHandler.login!(request, context.memberStore, session)
		Route.PostAction.Logout => AuthHandler.logout!(context.sessionStore)
		Route.PostAction.SearchTodos =>
			TodoHandler.search!(request, context.todoStore)
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
		Route.PostAction.AddPersonEmail(id) =>
			PersonHandler.add_contact!(request, context.personStore, id, Email)
		Route.PostAction.AddPersonPhone(id) =>
			PersonHandler.add_contact!(request, context.personStore, id, Phone)
		Route.PostAction.DeletePersonEmail(id, contact_id) =>
			PersonHandler.delete_contact!(context.personStore, id, Email, contact_id)
		Route.PostAction.DeletePersonPhone(id, contact_id) =>
			PersonHandler.delete_contact!(context.personStore, id, Phone, contact_id)
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
		Route.PostAction.CompleteTask(id) =>
			WorkTaskHandler.complete!(
				context.workTaskStore,
				actor_from_session(session, context.workspace)?,
				id,
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
	date = Utc.to_iso_8601(Utc.now!())
	Stdout.line!("${date} ${Str.inspect(request.method())} ${request.target()}")
}

app_origin : Url
app_origin = "http://localhost"

robots_txt : List(U8)
robots_txt = (
	\\User-agent: *
	\\Allow: /
	,
).to_utf8()
