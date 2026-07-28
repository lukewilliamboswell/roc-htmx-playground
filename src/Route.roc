import pf.Server
import pf.Url

import BigTask
import Company
import Person
import Todo
import WorkTask

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
		Companies,
		CompanyNew,
		People,
		PersonNew,
		Work,
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
				Companies => "Companies"
				CompanyNew => "New company"
				People => "People"
				PersonNew => "New person"
				Work => "My Work"
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
				Companies => "/companies"
				CompanyNew => "/companies/new"
				People => "/people"
				PersonNew => "/people/new"
				Work => "/work"
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
		TodoSearch(Todo.Filter),
		TodoNewCompatibility,
		BigTasks(BigTask.Query),
		BigTaskCsv,
		CompanySearch(Company.Filter),
		CompanyDetail(Company.Id),
		CompanyEdit(Company.Id),
		PersonSearch(Person.Filter),
		PersonDetail(Person.Id),
		PersonEdit(Person.Id),
		PersonNewForCompany(Company.Id),
	].{
		to_href : Location -> Str
		to_href = |location|
			match location {
				AtPage(page) => Page.to_href(page)
				TodoList => "/task/list"
				TodoSearch(filter) =>
					"/task?${TodoInput.to_name(TodoInput.Filter)}=${form_encode(filter.to_str())}"
				TodoNewCompatibility => "/task/new"
				BigTasks(query) => "/bigTask?${BigTask.Query.to_query(query)}"
				BigTaskCsv => "/bigTask/downloadCsv"
				CompanySearch(filter) =>
					"/companies?q=${form_encode(filter.to_str())}"
				CompanyDetail(id) => "/companies/${id.to_str()}"
				CompanyEdit(id) => "/companies/${id.to_str()}/edit"
				PersonSearch(filter) => "/people?q=${form_encode(filter.to_str())}"
				PersonDetail(id) => "/people/${id.to_str()}"
				PersonEdit(id) => "/people/${id.to_str()}/edit"
				PersonNewForCompany(id) => "/people/new?company=${form_encode(id.to_str())}"
			}
	}

	TaskContext := [
		WorkList,
		CompanyRecord(Company.Id),
		PersonRecord(Person.Id),
	].{
		is_eq : _

		to_location : TaskContext -> Location
		to_location = |context|
			match context {
				WorkList => AtPage(Page.Work)
				CompanyRecord(id) => CompanyDetail(id)
				PersonRecord(id) => PersonDetail(id)
			}
	}

	PostAction := [
		Register,
		Login,
		Logout,
		CreateTodo,
		DeleteTodo(Todo.Id),
		PreviewCompany,
		CreateCompany,
		UpdateCompany(Company.Id),
		PreviewPerson,
		CreatePerson,
		UpdatePerson(Person.Id),
		AddPersonEmail(Person.Id),
		AddPersonPhone(Person.Id),
		PromotePersonEmail(Person.Id, Person.ContactId),
		PromotePersonPhone(Person.Id, Person.ContactId),
		DeletePersonEmail(Person.Id, Person.ContactId),
		DeletePersonPhone(Person.Id, Person.ContactId),
		CreateCompanyTask(Company.Id),
		CreatePersonTask(Person.Id),
		CompleteTask(WorkTask.Id, TaskContext),
	].{
		to_post_url : PostAction -> Str
		to_post_url = |action|
			match action {
				Register => "/register"
				Login => "/login"
				Logout => "/logout"
				CreateTodo => "/task/new"
				DeleteTodo(id) => "/task/${Todo.Id.to_str(id)}/delete"
				PreviewCompany => "/companies/preview"
				CreateCompany => "/companies"
				UpdateCompany(id) => "/companies/${id.to_str()}"
				PreviewPerson => "/people/preview"
				CreatePerson => "/people"
				UpdatePerson(id) => "/people/${id.to_str()}"
				AddPersonEmail(id) => "/people/${id.to_str()}/emails"
				AddPersonPhone(id) => "/people/${id.to_str()}/phones"
				PromotePersonEmail(id, contact_id) =>
					"/people/${id.to_str()}/emails/${contact_id.to_str()}/primary"
				PromotePersonPhone(id, contact_id) =>
					"/people/${id.to_str()}/phones/${contact_id.to_str()}/primary"
				DeletePersonEmail(id, contact_id) =>
					"/people/${id.to_str()}/emails/${contact_id.to_str()}/delete"
				DeletePersonPhone(id, contact_id) =>
					"/people/${id.to_str()}/phones/${contact_id.to_str()}/delete"
				CreateCompanyTask(id) => "/companies/${id.to_str()}/tasks"
				CreatePersonTask(id) => "/people/${id.to_str()}/tasks"
				CompleteTask(id, context) =>
					match context {
						TaskContext.WorkList => "/tasks/${id.to_str()}/complete"
						TaskContext.CompanyRecord(company_id) =>
							"/companies/${company_id.to_str()}/tasks/${id.to_str()}/complete"
						TaskContext.PersonRecord(person_id) =>
							"/people/${person_id.to_str()}/tasks/${id.to_str()}/complete"
						}
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

	CompanyInput := [Name, Owner, Lifecycle, Website, Phone, Source, Context, ConfirmDistinct, Version].{
		to_name : CompanyInput -> Str
		to_name = |input|
			match input {
				Name => "name"
				Owner => "owner"
				Lifecycle => "lifecycle"
				Website => "website"
				Phone => "phone"
				Source => "source"
				Context => "context"
				ConfirmDistinct => "confirmDistinct"
				Version => "version"
			}
	}

	PersonInput := [Name, Company, JobTitle, Owner, Lifecycle, Source, Context, Email, Phone, ConfirmDistinct, Version, Label, Value, Primary].{
		to_name : PersonInput -> Str
		to_name = |input|
			match input {
				Name => "name"
				Company => "company"
				JobTitle => "jobTitle"
				Owner => "owner"
				Lifecycle => "lifecycle"
				Source => "source"
				Context => "context"
				Email => "email"
				Phone => "phone"
				ConfirmDistinct => "confirmDistinct"
				Version => "version"
				Label => "label"
				Value => "value"
				Primary => "primary"
			}
	}

	TaskInput := [Subject, DueLocal, Assignee, TaskType, Context].{
		to_name : TaskInput -> Str
		to_name = |input|
			match input {
				Subject => "subject"
				DueLocal => "dueLocal"
				Assignee => "assignee"
				TaskType => "taskType"
				Context => "context"
			}
	}

	Asset := [
		Robots,
		Stylesheet,
		Htmx,
		Interactions,
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
				Interactions => "/assets/interactions.js?v=20260728"
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

			(Get, ["", "task"]) => {
				filter = Todo.Filter.from_str(
					query_value(
						Url.query_pairs(url),
						TodoInput.to_name(TodoInput.Filter),
					),
				)
				if filter == Todo.Filter.empty {
					Ok(Visit(AtPage(Todos)))
				} else {
					Ok(Visit(TodoSearch(filter)))
				}
			}
			(Get, ["", "task", "list"]) => Ok(Visit(TodoList))
			(Get, ["", "task", "new"]) => Ok(Visit(TodoNewCompatibility))
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

			(Get, ["", "companies"]) => {
				filter = Route.company_filter(Url.query_pairs(url))
				if filter.to_str().is_empty() {
					Ok(Visit(AtPage(Companies)))
				} else {
					Ok(Visit(CompanySearch(filter)))
				}
			}
			(Get, ["", "companies", "new"]) => Ok(Visit(AtPage(CompanyNew)))
			(Post, ["", "companies", "preview"]) => Ok(Post(PreviewCompany))
			(Post, ["", "companies"]) => Ok(Post(CreateCompany))
			(Get, ["", "companies", id, "edit"]) =>
				Ok(Visit(CompanyEdit(Company.Id.from_storage(id))))
			(Post, ["", "companies", id]) =>
				Ok(Post(UpdateCompany(Company.Id.from_storage(id))))
			(Post, ["", "companies", id, "tasks"]) =>
				Ok(Post(CreateCompanyTask(Company.Id.from_storage(id))))
			(Post, ["", "companies", id, "tasks", task_id, "complete"]) =>
				Ok(
					Post(
						CompleteTask(
							WorkTask.Id.from_storage(task_id),
							TaskContext.CompanyRecord(Company.Id.from_storage(id)),
						),
					),
				)
			(Get, ["", "companies", id]) =>
				Ok(Visit(CompanyDetail(Company.Id.from_storage(id))))

			(Get, ["", "people"]) => {
				filter = Person.Filter.from_str(query_value(Url.query_pairs(url), "q"))
				if filter.to_str().is_empty() {
					Ok(Visit(AtPage(People)))
				} else {
					Ok(Visit(PersonSearch(filter)))
				}
			}
			(Get, ["", "people", "new"]) => {
				company_id = query_value(Url.query_pairs(url), "company")
				if company_id.is_empty() {
					Ok(Visit(AtPage(PersonNew)))
				} else {
					Ok(Visit(PersonNewForCompany(Company.Id.from_storage(company_id))))
				}
			}
			(Post, ["", "people", "preview"]) => Ok(Post(PreviewPerson))
			(Post, ["", "people"]) => Ok(Post(CreatePerson))
			(Get, ["", "people", id, "edit"]) =>
				Ok(Visit(PersonEdit(Person.Id.from_storage(id))))
			(Post, ["", "people", id]) =>
				Ok(Post(UpdatePerson(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "tasks"]) =>
				Ok(Post(CreatePersonTask(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "tasks", task_id, "complete"]) =>
				Ok(
					Post(
						CompleteTask(
							WorkTask.Id.from_storage(task_id),
							TaskContext.PersonRecord(Person.Id.from_storage(id)),
						),
					),
				)
			(Get, ["", "people", id]) =>
				Ok(Visit(PersonDetail(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "emails"]) =>
				Ok(Post(AddPersonEmail(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "phones"]) =>
				Ok(Post(AddPersonPhone(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "emails", contact_id, "primary"]) =>
				Ok(
					Post(
						PromotePersonEmail(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)
			(Post, ["", "people", id, "phones", contact_id, "primary"]) =>
				Ok(
					Post(
						PromotePersonPhone(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)
			(Post, ["", "people", id, "emails", contact_id, "delete"]) =>
				Ok(
					Post(
						DeletePersonEmail(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)

			(Get, ["", "work"]) => Ok(Visit(AtPage(Work)))
			(Post, ["", "tasks", id, "complete"]) =>
				Ok(Post(CompleteTask(WorkTask.Id.from_storage(id), TaskContext.WorkList)))
			(Post, ["", "people", id, "phones", contact_id, "delete"]) =>
				Ok(
					Post(
						DeletePersonPhone(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)

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

	company_filter : List((Str, Str)) -> Company.Filter
	company_filter = |pairs|
		Company.Filter.from_str(query_value(pairs, "q"))
}

query_value : List((Str, Str)), Str -> Str
query_value = |pairs, expected|
	match pairs.find_first(|(name, _)| name == expected) {
		Ok((_, value)) => value
		Err(_) => ""
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

form_encode : Str -> Str
form_encode = |input|
	Str.from_utf8_lossy(
		List.fold(
			Str.to_utf8(input),
			[],
			|out, byte|
				if byte == 32 {
					out.append(43)
				} else if is_form_unescaped(byte) {
					out.append(byte)
				} else {
					out
						.append(37)
						.append(hex_digit_byte(byte // 16))
						.append(hex_digit_byte(byte % 16))
				},
		),
	)

is_form_unescaped : U8 -> Bool
is_form_unescaped = |byte|
	(byte >= 48 and byte <= 57)
		or (byte >= 65 and byte <= 90)
			or (byte >= 97 and byte <= 122)
				or byte == 42
					or byte == 45
						or byte == 46
							or byte == 95

hex_digit_byte : U8 -> U8
hex_digit_byte = |value|
	if value < 10 {
		value + 48
	} else {
		value + 55
	}

expect Route.Page.to_href(Route.Page.Todos) == "/task"
expect Route.Location.to_href(
	Route.Location.TodoSearch(Todo.Filter.from_str("council permit")),
) == "/task?filterTasks=council+permit"
expect Route.Location.to_href(
	Route.Location.CompanySearch(Company.Filter.from_str("Acme Studio")),
) == "/companies?q=Acme+Studio"

expect {
	result = Route.parse_parts(
		Route.Method.Get,
		"/task?filterTasks=council+permit",
		"http://localhost/task?filterTasks=council+permit",
	)
	match result {
		Ok(Route.Visit(Route.Location.TodoSearch(filter))) =>
			filter == Todo.Filter.from_str("council permit")
		_ => False
	}
}

expect {
	id = Todo.Id.from_i64(42)
	Route.PostAction.to_post_url(Route.PostAction.DeleteTodo(id)) == "/task/42/delete"
}

expect {
	result = Route.parse_parts(
		Route.Method.Get,
		"/companies/company-acme",
		"http://localhost/companies/company-acme",
	)
	match result {
		Ok(Route.Visit(Route.Location.CompanyDetail(id))) =>
			id.to_str() == "company-acme"
		_ => False
	}
}

expect Route.Page.to_href(Route.Page.Work) == "/work"

expect {
	result = Route.parse_parts(
		Route.Method.Get,
		"/people/new?company=company-acme",
		"http://localhost/people/new?company=company-acme",
	)
	match result {
		Ok(Route.Visit(Route.Location.PersonNewForCompany(id))) =>
			id.to_str() == "company-acme"
		_ => False
	}
}

expect {
	result = Route.parse_parts(
		Route.Method.Post,
		"/tasks/task-follow-up/complete",
		"http://localhost/tasks/task-follow-up/complete",
	)
	match result {
		Ok(Route.Post(Route.PostAction.CompleteTask(id, context))) =>
			id.to_str() == "task-follow-up" and context == Route.TaskContext.WorkList
		_ => False
	}
}

expect {
	person_id = Person.Id.from_storage("person-ada")
	task_id = WorkTask.Id.from_storage("task-follow-up")
	action = Route.PostAction.CompleteTask(
		task_id,
		Route.TaskContext.PersonRecord(person_id),
	)
	parsed = Route.parse_parts(
		Route.Method.Post,
		action.to_post_url(),
		"http://localhost/people/person-ada/tasks/task-follow-up/complete",
	)
	match parsed {
		Ok(Route.Post(Route.PostAction.CompleteTask(actual_task, context))) =>
			actual_task == task_id
				and context == Route.TaskContext.PersonRecord(person_id)
		_ => False
	}
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
