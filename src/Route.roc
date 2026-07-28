import pf.Server
import pf.Url

import BigTask
import Todo

## The complete HTTP vocabulary owned by the application.
##
## Runtime request dispatch is a closed tag union because the request method
## and URL are runtime data. URL generation is exposed on the narrower nested
## types so views cannot use a mutation action as a normal link.
Route := [
	Visit(Location),
	Post(PostAction),
	Put(PutAction),
	Serve(Asset),
].{
	Page := [
		Home,
		Register,
		Login,
		Todos,
		TodoTree,
		Users,
		BigTasks,
	].{
		is_eq : _

		title : Page -> Str
		title = |page|
			match page {
				Home => "Home"
				Register => "Register"
				Login => "Login"
				Todos => "Tasks"
				TodoTree => "Tree"
				Users => "Users"
				BigTasks => "BigTask"
			}

		to_href : Page -> Str
		to_href = |page|
			match page {
				Home => "/"
				Register => "/register"
				Login => "/login"
				Todos => "/task"
				TodoTree => "/treeview"
				Users => "/user"
				BigTasks => "/bigTask"
			}
	}

	## GET locations which are not fully described by a page identity.
	##
	## `TodoNewCompatibility` preserves the existing GET `/task/new` redirect.
	## It is intentionally not a `Page`, so application navigation does not
	## present that compatibility endpoint as a real page.
	Location := [
		AtPage(Page),
		TodoList,
		TodoNewCompatibility,
		BigTasks(BigTask.Query),
		BigTaskCsv,
	].{
		to_href : Location -> Str
		to_href = |location|
			match location {
				AtPage(page) => Page.to_href(page)
				TodoList => "/task/list"
				TodoNewCompatibility => "/task/new"
				BigTasks(query) => "/bigTask?${BigTask.Query.to_query(query)}"
				BigTaskCsv => "/bigTask/downloadCsv"
			}
	}

	PostAction := [
		Register,
		Login,
		Logout,
		SearchTodos,
		CreateTodo,
		DeleteTodo(Todo.Id),
	].{
		to_post_url : PostAction -> Str
		to_post_url = |action|
			match action {
				Register => "/register"
				Login => "/login"
				Logout => "/logout"
				SearchTodos => "/task/search"
				CreateTodo => "/task/new"
				DeleteTodo(id) => "/task/${Todo.Id.to_str(id)}/delete"
			}
	}

	PutAction := [
		CompleteTodo(Todo.Id),
		StartTodo(Todo.Id),
		UpdateBigTask(BigTask.Id, BigTask.Field),
	].{
		to_put_url : PutAction -> Str
		to_put_url = |action|
			match action {
				CompleteTodo(id) => "/task/${Todo.Id.to_str(id)}/complete"
				StartTodo(id) => "/task/${Todo.Id.to_str(id)}/in-progress"
				UpdateBigTask(id, field) =>
					"/bigTask/${big_task_field_segment(field)}/${BigTask.Id.to_str(id)}"
				}
	}

	## Names used by application-owned forms. These remain strings on the wire,
	## but views and handlers share a closed vocabulary instead of duplicating
	## string literals.
	AuthInput := [Username, Email].{
		to_name : AuthInput -> Str
		to_name = |input|
			match input {
				Username => "user"
				Email => "email"
			}
	}

	TodoInput := [Filter, Task, Status].{
		to_name : TodoInput -> Str
		to_name = |input|
			match input {
				Filter => "filterTasks"
				Task => "task"
				Status => "status"
			}
	}

	Asset := [
		Robots,
		Stylesheet,
		Htmx,
		PlanningDesk,
		PlanningDesk480,
		PlanningDesk640,
		PlanningDesk720,
		PlanningDesk960,
		TasksIcon,
		UsersIcon,
		TreeIcon,
		TableIcon,
	].{
		to_src : Asset -> Str
		to_src = |asset|
			match asset {
				Robots => "/robots.txt"
				Stylesheet => "/assets/styles.css?v=20260728"
				Htmx => "/assets/htmx.min.js?v=4.0.0-beta6"
				PlanningDesk => "/assets/planning-desk.webp"
				PlanningDesk480 => "/assets/planning-desk-480.webp"
				PlanningDesk640 => "/assets/planning-desk-640.webp"
				PlanningDesk720 => "/assets/planning-desk-720.webp"
				PlanningDesk960 => "/assets/planning-desk-960.webp"
				TasksIcon => "/assets/icons/tasks.svg"
				UsersIcon => "/assets/icons/users.svg"
				TreeIcon => "/assets/icons/tree.svg"
				TableIcon => "/assets/icons/table.svg"
			}
	}

	ParseError := [
		InvalidTodoId(Str),
		InvalidBigTaskId(Str),
		NotFound(Str),
	]

	Method := [Get, Post, Put, Other].{
		is_eq : _
	}

	parse : Server.Request, Url -> Try(Route, ParseError)
	parse = |request, url|
		parse_parts(method_from_request(request), request.target(), url)

	## Pure routing core. `parse` is the normal application entry point;
	## `parse_parts` allows route behavior to be tested without constructing
	## the platform's opaque `Server.Request`.
	parse_parts : Method, Str, Url -> Try(Route, ParseError)
	parse_parts = |method, target, url| {
		segments = Url.path(url).split_on("/")

		match (method, segments) {
			(Get, ["", ""]) => Ok(Visit(AtPage(Home)))

			(Get, ["", "register"]) => Ok(Visit(AtPage(Register)))
			(Post, ["", "register"]) => Ok(Post(Register))

			(Get, ["", "login"]) => Ok(Visit(AtPage(Login)))
			(Post, ["", "login"]) => Ok(Post(Login))
			(Post, ["", "logout"]) => Ok(Post(Logout))

			(Get, ["", "task"]) => Ok(Visit(AtPage(Todos)))
			(Get, ["", "task", "list"]) => Ok(Visit(TodoList))
			(Get, ["", "task", "new"]) => Ok(Visit(TodoNewCompatibility))
			(Post, ["", "task", "search"]) => Ok(Post(SearchTodos))
			(Post, ["", "task", "new"]) => Ok(Post(CreateTodo))
			(Post, ["", "task", id, "delete"]) =>
				match parse_todo_id(id) {
					Ok(parsed) => Ok(Post(DeleteTodo(parsed)))
					Err(err) => Err(err)
				}
			(Put, ["", "task", id, "complete"]) =>
				match parse_todo_id(id) {
					Ok(parsed) => Ok(Put(CompleteTodo(parsed)))
					Err(err) => Err(err)
				}
			(Put, ["", "task", id, "in-progress"]) =>
				match parse_todo_id(id) {
					Ok(parsed) => Ok(Put(StartTodo(parsed)))
					Err(err) => Err(err)
				}

			(Get, ["", "treeview"]) => Ok(Visit(AtPage(TodoTree)))
			(Get, ["", "user"]) => Ok(Visit(AtPage(Users)))

			(Get, ["", "bigTask"]) =>
				{
					query = BigTask.Query.from_pairs(Url.query_pairs(url))
					Ok(Visit(BigTasks(query)))
				}
			(Get, ["", "bigTask", "downloadCsv"]) => Ok(Visit(BigTaskCsv))
			(Put, ["", "bigTask", "customerId", id]) =>
				parse_big_task_update(id, BigTask.Field.CustomerReferenceField)
			(Put, ["", "bigTask", "dateCreated", id]) =>
				parse_big_task_update(id, BigTask.Field.DateCreatedField)
			(Put, ["", "bigTask", "status", id]) =>
				parse_big_task_update(id, BigTask.Field.StatusField)

			(Get, ["", "robots.txt"]) => Ok(Serve(Robots))

			_ => Err(NotFound(target))
		}
	}
}

method_from_request : Server.Request -> Route.Method
method_from_request = |request|
	match request.method() {
		GET => Route.Method.Get
		POST => Route.Method.Post
		PUT => Route.Method.Put
		_ => Route.Method.Other
	}

parse_todo_id : Str -> Try(Todo.Id, Route.ParseError)
parse_todo_id = |text|
	match Todo.Id.from_str(text) {
		Ok(id) => Ok(id)
		Err(_) => Err(Route.ParseError.InvalidTodoId(text))
	}

parse_big_task_update : Str, BigTask.Field -> Try(Route, Route.ParseError)
parse_big_task_update = |text, field|
	match BigTask.Id.from_str(text) {
		Ok(id) => Ok(Route.Put(Route.PutAction.UpdateBigTask(id, field)))
		Err(_) => Err(Route.ParseError.InvalidBigTaskId(text))
	}

big_task_field_segment : BigTask.Field -> Str
big_task_field_segment = |field| BigTask.Field.to_url_segment(field)

expect Route.Page.to_href(Route.Page.Todos) == "/task"

expect {
	id = Todo.Id.from_i64(42)
	Route.PostAction.to_post_url(Route.PostAction.DeleteTodo(id)) == "/task/42/delete"
}

expect {
	result = Route.parse_parts(
		Route.Method.Post,
		"/task/42/delete",
		"http://localhost/task/42/delete",
	)
	match result {
		Ok(Route.Post(Route.PostAction.DeleteTodo(id))) => Todo.Id.to_i64(id) == 42
		_ => False
	}
}

expect {
	result = Route.parse_parts(
		Route.Method.Get,
		"/bigTask?page=3&items=10&sortBy=Title&sortDirection=desc",
		"http://localhost/bigTask?page=3&items=10&sortBy=Title&sortDirection=desc",
	)
	match result {
		Ok(Route.Visit(Route.Location.BigTasks(query))) =>
			BigTask.Page.to_i64(query.page) == 3
				and BigTask.ItemsPerPage.to_i64(query.items) == 10
		_ => False
	}
}

expect {
	result = Route.parse_parts(
		Route.Method.Put,
		"/task/not-an-id/complete",
		"http://localhost/task/not-an-id/complete",
	)
	match result {
		Err(Route.ParseError.InvalidTodoId("not-an-id")) => True
		_ => False
	}
}
