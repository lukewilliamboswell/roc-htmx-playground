app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.14.0/9mrSfhWKEXsrPUW2oHdZZGov1oMRryvvACDT8p7E97PY.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Env
import pf.Path
import pf.Server
import pf.Sqlite
import pf.Stderr
import pf.Stdout
import http.Response
import "../db/init.sql" as init_schema : Str
import "../db/test-fixtures.sql" as test_fixtures : Str

import BigTask
import BigTaskStore
import Member
import MemberStore
import Session
import SessionStore
import Todo
import TodoStore
import User
import UserStore
import WorkspaceStore

Context := {}

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64), ..])
init! = || {
	test_db_path = Path.join(
		Env.temp_dir!(),
		"roc-htmx-playground-platform-test.sqlite",
	)
	if test_db_path.is_file!() ? |_| Exit(1) {
		test_db_path.delete!() ? |_| Exit(1)
	}
	default = Sqlite.default_config(test_db_path)
	opened = Sqlite.open!({
		..default,
		max_connections: 1,
		journal_mode: Delete,
	})
	db = match opened {
		Err(error) => {
			Stderr.line!("database open failed: ${Str.inspect(error)}") ? |_| Exit(1)
			return Err(Exit(1))
		}
		Ok(value) => value
	}
	match load_schema!(db, init_schema.split_on(";")) {
		Err(error) => {
			Stderr.line!("schema failed: ${Str.inspect(error)}") ? |_| Exit(2)
			return Err(Exit(2))
		}
		Ok({}) => {}
	}
	match load_schema!(db, test_fixtures.split_on(";")) {
		Err(error) => {
			Stderr.line!("fixtures failed: ${Str.inspect(error)}") ? |_| Exit(2)
			return Err(Exit(2))
		}
		Ok({}) => {}
	}
	Stdout.line!("schema: ok") ? |_| Exit(3)
	test_workspace!(db)
	Stdout.line!("workspace: ok") ? |_| Exit(3)
	test_sessions_and_users!(db)
	Stdout.line!("sessions and users: ok") ? |_| Exit(3)
	test_todos!(db)
	Stdout.line!("todos: ok") ? |_| Exit(3)
	test_big_tasks!(db)
	Stdout.line!("big tasks: ok") ? |_| Exit(3)
	Err(Exit(0))
}

test_workspace! : Sqlite.Db => {}
test_workspace! = |db| {
	loaded = WorkspaceStore.load!(WorkspaceStore.new(db))
	expect match loaded {
		Ok(workspace) =>
			workspace.name == "Example CRM"
				and workspace.currency.to_str() == "AUD"
					and workspace.timezone.to_str() == "Australia/Melbourne"
						and workspace.sources.len() == 6
							and workspace.taskTypes.len() == 5
		Err(_) => False
	}
}

respond! = |_request, _context| Ok(Server.respond(Response.from_status(204)))

shutdown! = |_reason, _context| Ok({})

load_schema! : Sqlite.Db, List(Str) => Try({}, Sqlite.QueryError)
load_schema! = |db, statements|
	match statements {
		[] => Ok({})
		[statement, .. as rest] => {
			sql = statement.trim()
			if sql.is_empty() {
				load_schema!(db, rest)
			} else {
				Sqlite.execute!({ db, query: sql, params: {} })?
				load_schema!(db, rest)
			}
		}
	}

test_sessions_and_users! : Sqlite.Db => {}
test_sessions_and_users! = |db| {
	sessions = SessionStore.new(db)
	members = MemberStore.new(db)
	users = UserStore.new(db)

	created = SessionStore.create!(sessions)
	expect match created {
		Ok(id) => id.to_i64() == 1
		Err(_) => False
	}
	session_id = created ?? Session.Id.from_i64(0)

	guest = SessionStore.find!(sessions, session_id)
	expect match guest {
		Ok(session) => !session.is_logged_in()
		Err(_) => False
	}

	registration = Member.register("Ada", "ada@example.com")
	registered = match registration {
		Ok(value) => MemberStore.register!(members, value)
		Err(_) => Err(MemberAlreadyExists)
	}
	expect registered.is_ok()

	duplicate_registration = Member.register("Ada", "other@example.com")
	duplicate = match duplicate_registration {
		Ok(value) => MemberStore.register!(members, value)
		Err(_) => Err(MemberAlreadyExists)
	}
	expect match duplicate {
		Err(MemberAlreadyExists) => True
		_ => False
	}

	listed = MemberStore.list_active!(members)
	expect match listed {
		Ok([member1, member2, member3]) =>
			[member1, member2, member3].any(
				|member|
					member.name.to_str() == "Ada"
						and member.email.to_str() == "ada@example.com",
			)
		_ => False
	}

	legacy_users = UserStore.list!(users)
	expect match legacy_users {
		Ok([_, _]) => True
		_ => False
	}

	logged_in = match registration {
		Ok(value) => MemberStore.login!(members, session_id, value.name)
		Err(_) => Err(MemberNotFound)
	}
	expect logged_in.is_ok()
	resolved = SessionStore.find!(sessions, session_id)
	expect match resolved {
		Ok(session) =>
			match session.user {
				Session.Auth.LoggedIn(member) => member.name.to_str() == "Ada"
				_ => False
			}
		Err(_) => False
	}

	ada_id = match resolved {
		Ok(session) =>
			match session.user {
				Session.Auth.LoggedIn(member) => member.id.to_str()
				_ => ""
			}
		Err(_) => ""
	}
	deactivated = Sqlite.execute!({
		db,
		query: "UPDATE members SET active = 0 WHERE member_id = :memberId;",
		params: { memberId: ada_id },
	})
	expect deactivated.is_ok()
	inactive_session = SessionStore.find!(sessions, session_id)
	expect match inactive_session {
		Err(Session.FindError.Inactive) => True
		_ => False
	}

	missing = SessionStore.find!(sessions, Session.Id.from_i64(999))
	expect match missing {
		Err(Session.FindError.NotFound) => True
		_ => False
	}
}

test_todos! : Sqlite.Db => {}
test_todos! = |db| {
	store = TodoStore.new(db)

	alpha_created = Todo.create!(store, "Alpha task", Todo.Status.NotStarted)
	expect alpha_created.is_ok()
	beta_created = Todo.create!(store, "Beta task", Todo.Status.InProgress)
	expect beta_created.is_ok()

	alpha = TodoStore.list!(store, Todo.Filter.from_str("Alpha"))
	expect match alpha {
		Ok([todo]) => todo.task.to_str() == "Alpha task"
		_ => False
	}

	beta = TodoStore.list!(store, Todo.Filter.from_str("Beta"))
	expect match beta {
		Ok([todo]) => todo.task.to_str() == "Beta task"
		_ => False
	}

	first_id = match alpha {
		Ok([first]) => first.id
		_ => Todo.Id.from_i64(0)
	}
	second_id = match beta {
		Ok([second]) => second.id
		_ => Todo.Id.from_i64(0)
	}

	status_updated = TodoStore.update_status!(store, first_id, Todo.Status.Completed)
	expect status_updated.is_ok()
	updated = TodoStore.list!(store, Todo.Filter.from_str("Alpha"))
	expect match updated {
		Ok([todo]) => todo.status == Todo.Status.Completed
		_ => False
	}

	tree = TodoStore.tree!(store, User.Id.from_i64(1))
	expect match tree {
		Ok(
			Todo.Tree.Node(
				root,
				[
					Todo.Tree.Node(first_child, []),
					Todo.Tree.Node(second_child, [Todo.Tree.Node(grandchild, [])]),
				],
			),
		) =>
			root.id == Todo.Id.from_i64(0)
				and first_child.id == Todo.Id.from_i64(1)
					and second_child.id == Todo.Id.from_i64(2)
						and grandchild.id == Todo.Id.from_i64(3)
		_ => False
	}

	deleted = TodoStore.delete!(store, second_id)
	expect deleted.is_ok()
	after_delete = TodoStore.list!(store, Todo.Filter.from_str("Beta"))
	expect match after_delete {
		Ok([]) => True
		_ => False
	}

	invalid_insert = Sqlite.execute!({
		db,
		query: "INSERT INTO tasks (id, task, status) VALUES (99, 'Invalid', 'Unknown');",
		params: {},
	})
	expect invalid_insert.is_ok()
	invalid_row = TodoStore.list!(store, Todo.Filter.from_str("Invalid"))
	expect match invalid_row {
		Err(InvalidStoredStatus("Unknown")) => True
		_ => False
	}
}

test_big_tasks! : Sqlite.Db => {}
test_big_tasks! = |db| {
	store = BigTaskStore.new(db)

	total = BigTaskStore.total!(store)
	expect total == Ok(100)

	query = BigTask.Query.{
		page: BigTask.Page.from_i64(2),
		items: BigTask.ItemsPerPage.from_i64(10),
		sortBy: BigTask.SortColumn.ById,
		sortDirection: BigTask.SortDirection.Ascending,
	}
	second_page = BigTaskStore.list!(store, query)
	expect match second_page {
		Ok([first, ..]) => first.id == BigTask.Id.from_i64(10)
		_ => False
	}

	id = BigTask.Id.from_i64(1)
	customer_updated = apply_update!(store, id, BigTask.update(BigTask.Field.CustomerReferenceField, "789"))
	expect customer_updated.is_ok()
	date_updated = apply_update!(store, id, BigTask.update(BigTask.Field.DateCreatedField, "2026-07-28"))
	expect date_updated.is_ok()
	big_task_status_updated = apply_update!(store, id, BigTask.update(BigTask.Field.StatusField, "Approved"))
	expect big_task_status_updated.is_ok()

	updated = BigTaskStore.list!(
		store,
		BigTask.Query.{
			page: BigTask.Page.from_i64(1),
			items: BigTask.ItemsPerPage.from_i64(2),
			sortBy: BigTask.SortColumn.ById,
			sortDirection: BigTask.SortDirection.Ascending,
		},
	)
	expect match updated {
		Ok([_, task]) =>
			task.id == id
				and BigTask.CustomerReference.to_str(task.customerReferenceId) == "789"
					and BigTask.Date.to_str(task.dateCreated) == "2026-07-28"
						and task.status == BigTask.Status.Approved
		_ => False
	}
}

apply_update! : BigTaskStore, BigTask.Id, Try(BigTask.Update, err) => Try({}, [InvalidUpdate, DbErr(Sqlite.QueryError)])
apply_update! = |store, id, update|
	match update {
		Err(_) => Err(InvalidUpdate)
		Ok(value) =>
			match BigTaskStore.update!(store, id, value) {
				Err(error) => Err(DbErr(error))
				Ok({}) => Ok({})
			}
		}
