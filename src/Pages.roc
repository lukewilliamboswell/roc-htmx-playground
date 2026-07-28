import pf.Attribute
import pf.Html

import Models

Pages := [].{
	home : Models.Session -> Html.Node
	home = |session|
		simplePage(
			session,
			"Home",
			[
				Html.h1([], [Html.text("Roc + htmx playground")]),
				Html.p([Attribute.class("lead")], [Html.text("Running on basic-webserver 0.14.0.")]),
				Html.div(
					[Attribute.class("d-flex gap-2")],
					[
						Html.a([Attribute.href("/task"), Attribute.class("btn btn-primary")], [Html.text("Tasks")]),
						Html.a([Attribute.href("/treeview"), Attribute.class("btn btn-outline-primary")], [Html.text("Tree")]),
						Html.a([Attribute.href("/bigTask"), Attribute.class("btn btn-outline-primary")], [Html.text("BigTask")]),
					],
				),
			],
		)

	login : Models.Session, Str, Str -> Html.Node
	login = |session, username, error|
		simplePage(
			session,
			"Login",
			[
				Html.h1([], [Html.text("Login")]),
				errorMessage(error),
				Html.form(
					[Attribute.action("/login"), Attribute.method("post")],
					[
						textInput("Username", "user", "text", username),
						Html.button([Attribute.type("submit"), Attribute.class("btn btn-primary")], [Html.text("Login")]),
					],
				),
			],
		)

	register : Str, Str, Str -> Html.Node
	register = |username, email, error|
		simplePage(
			Models.anonymousSession,
			"Register",
			[
				Html.h1([], [Html.text("Register")]),
				errorMessage(error),
				Html.form(
					[Attribute.action("/register"), Attribute.method("post")],
					[
						textInput("Username", "user", "text", username),
						textInput("Email", "email", "email", email),
						Html.button([Attribute.type("submit"), Attribute.class("btn btn-primary")], [Html.text("Register")]),
					],
				),
			],
		)

	todos : Models.Session, List(Models.Todo), Str -> Html.Node
	todos = |session, todoRows, filter|
		simplePage(
			session,
			"Tasks",
			[
				Html.h1([], [Html.text("Tasks")]),
				Html.form(
					[
						attribute("hx-post", "/task/search"),
						attribute("hx-trigger", "input delay:250ms"),
						attribute("hx-target", "#todo-list"),
					],
					[
						Html.input([
							Attribute.name("filterTasks"),
							Attribute.value(filter),
							Attribute.class("form-control mb-3"),
							attribute("placeholder", "Filter tasks"),
						]),
					],
				),
				todoListNode(todoRows),
				newTodoForm(),
			],
		)

	todoList : List(Models.Todo), Str -> Html.Node
	todoList = |todoRows, _filter| todoListNode(todoRows)

	users : Models.Session, List(Models.User) -> Html.Node
	users = |session, userRows|
		simplePage(
			session,
			"Users",
			[
				Html.h1([], [Html.text("Users")]),
				Html.table(
					[Attribute.class("table table-striped")],
					[
						Html.thead([], [Html.tr([], [headerCell("ID"), headerCell("Name"), headerCell("Email")])]),
						Html.tbody(
							[],
							userRows.map(
								|user|
									Html.tr(
										[],
										[
											tableCell(user.id.to_str()),
											tableCell(user.name),
											tableCell(user.email),
										],
									),
							),
						),
					],
				),
			],
		)

	tree : Models.Session, Models.Tree(Models.Todo) -> Html.Node
	tree = |session, taskTree|
		simplePage(
			session,
			"Tree",
			[
				Html.h1([], [Html.text("Task hierarchy")]),
				Html.ul([Attribute.class("todo-tree-ul")], [renderTree(taskTree)]),
			],
		)

	unauthorized : Html.Node
	unauthorized = simplePage(Models.anonymousSession, "Unauthorized", [Html.h1([], [Html.text("Unauthorized")])])

	bigTasks : {
		session : Models.Session,
		tasks : List(Models.BigTask),
		page : I64,
		items : I64,
		total : I64,
		sortBy : Str,
		sortDirection : Models.SortDirection,
	} -> Html.Node
	bigTasks = |model|
		simplePage(
			model.session,
			"BigTask",
			[
				Html.h1([], [Html.text("Big Task Table")]),
				Html.a(
					[
						Attribute.href("/bigTask/downloadCsv"),
						Attribute.class("btn btn-success mb-3"),
						attribute("download", ""),
					],
					[Html.text("Download CSV")],
				),
				bigTaskTable(model.tasks, model.sortBy, model.sortDirection),
				Html.p(
					[],
					[
						Html.text(
							"Page ${model.page.to_str()} · ${model.total.to_str()} total rows",
						),
					],
				),
			],
		)

	bigTaskInput : Str, Str, Str, Str, Str -> Html.Node
	bigTaskInput = |updateUrl, name, kind, value, validation|
		editInput(updateUrl, name, kind, value, validation)

	bigTaskStatus : Str, Str, Str -> Html.Node
	bigTaskStatus = |updateUrl, value, validation| editStatus(updateUrl, value, validation)
}

simplePage : Models.Session, Str, List(Html.Node) -> Html.Node
simplePage = |session, title, children|
	Html.html(
		[attribute("lang", "en")],
		[
			Html.head(
				[],
				[
					Html.meta([attribute("charset", "utf-8")]),
					Html.meta([Attribute.name("viewport"), attribute("content", "width=device-width, initial-scale=1")]),
					Html.title([], [Html.text(title)]),
					Html.link([Attribute.rel("stylesheet"), Attribute.href("/bootstrap.min.css")]),
					Html.link([Attribute.rel("stylesheet"), Attribute.href("/styles.css")]),
					Html.element("script", [Attribute.src("/htmx.min.js")], []),
					Html.element("script", [Attribute.src("/site.js")], []),
				],
			),
			Html.body(
				[],
				[
					navbar(session),
					Html.main([Attribute.class("container py-4")], children),
					Html.element("script", [Attribute.src("/bootstrap.bundle.min.js")], []),
				],
			),
		],
	)

navbar : Models.Session -> Html.Node
navbar = |session|
	Html.nav(
		[Attribute.class("navbar navbar-expand bg-body-tertiary border-bottom")],
		[
			Html.div(
				[Attribute.class("container-fluid")],
				[
					Html.a([Attribute.class("navbar-brand"), Attribute.href("/")], [Html.text("Roc + htmx")]),
					Html.ul(
						[Attribute.class("navbar-nav me-auto")],
						[
							navItem("Tasks", "/task"),
							navItem("Users", "/user"),
							navItem("Tree", "/treeview"),
							navItem("BigTask", "/bigTask"),
						],
					),
					authControls(session),
				],
			),
		],
	)

navItem : Str, Str -> Html.Node
navItem = |label, href|
	Html.li(
		[Attribute.class("nav-item")],
		[Html.a([Attribute.class("nav-link"), Attribute.href(href)], [Html.text(label)])],
	)

authControls : Models.Session -> Html.Node
authControls = |session|
	match session.user {
		Guest =>
			Html.div(
				[Attribute.class("d-flex gap-2")],
				[
					Html.a([Attribute.href("/login"), Attribute.class("btn btn-outline-primary")], [Html.text("Login")]),
					Html.a([Attribute.href("/register"), Attribute.class("btn btn-primary")], [Html.text("Register")]),
				],
			)
		LoggedIn(name) =>
			Html.form(
				[Attribute.action("/logout"), Attribute.method("post"), Attribute.class("d-flex gap-2 align-items-center")],
				[
					Html.span([], [Html.text(name)]),
					Html.button([Attribute.type("submit"), Attribute.class("btn btn-outline-secondary")], [Html.text("Logout")]),
				],
			)
		}

textInput : Str, Str, Str, Str -> Html.Node
textInput = |label, name, kind, value|
	Html.div(
		[Attribute.class("mb-3")],
		[
			Html.label([Attribute.for_(name), Attribute.class("form-label")], [Html.text(label)]),
			Html.input([
				Attribute.id(name),
				Attribute.name(name),
				Attribute.type(kind),
				Attribute.value(value),
				Attribute.class("form-control"),
				attribute("required", ""),
			]),
		],
	)

errorMessage : Str -> Html.Node
errorMessage = |message|
	if Str.is_empty(message) {
		Html.div([], [])
	} else {
		Html.div([Attribute.class("alert alert-danger")], [Html.text(message)])
	}

todoListNode : List(Models.Todo) -> Html.Node
todoListNode = |todoRows|
	Html.div(
		[Attribute.id("todo-list")],
		[
			Html.table(
				[Attribute.class("table table-striped align-middle")],
				[
					Html.thead([], [Html.tr([], [headerCell("Task"), headerCell("Status"), headerCell("Actions")])]),
					Html.tbody([], todoRows.map(todoRow)),
				],
			),
		],
	)

todoRow : Models.Todo -> Html.Node
todoRow = |todo| {
	id = todo.id.to_str()
	Html.tr(
		[],
		[
			tableCell(todo.task),
			tableCell(todo.status),
			Html.td(
				[],
				[
					actionButton("Complete", "/task/${id}/complete", "hx-put", "btn-outline-success"),
					actionButton("In progress", "/task/${id}/in-progress", "hx-put", "btn-outline-warning"),
					Html.button(
						[
							Attribute.class("btn btn-sm btn-outline-danger ms-1"),
							attribute("hx-post", "/task/${id}/delete"),
							attribute("hx-target", "#todo-list"),
						],
						[Html.text("Delete")],
					),
				],
			),
		],
	)
}

actionButton : Str, Str, Str, Str -> Html.Node
actionButton = |label, url, hxMethod, className|
	Html.button(
		[
			Attribute.class("btn btn-sm ${className} ms-1"),
			attribute(hxMethod, url),
		],
		[Html.text(label)],
	)

newTodoForm : () -> Html.Node
newTodoForm = ||
	Html.form(
		[Attribute.action("/task/new"), Attribute.method("post"), Attribute.class("row g-2")],
		[
			Html.div(
				[Attribute.class("col-md-8")],
				[
					Html.input([
						Attribute.name("task"),
						Attribute.class("form-control"),
						attribute("placeholder", "New task"),
						attribute("required", ""),
					]),
				],
			),
			Html.div(
				[Attribute.class("col-md-2")],
				[
					Html.select(
						[Attribute.name("status"), Attribute.class("form-select")],
						[
							selectOption("Not Started", False),
							selectOption("In-Progress", False),
							selectOption("Completed", False),
						],
					),
				],
			),
			Html.div(
				[Attribute.class("col-md-2")],
				[Html.button([Attribute.type("submit"), Attribute.class("btn btn-primary w-100")], [Html.text("Add")])],
			),
		],
	)

selectOption : Str, Bool -> Html.Node
selectOption = |value, selected|
	Html.option(
		if selected {
			[Attribute.value(value), attribute("selected", "")]
		} else {
			[Attribute.value(value)]
		},
		[Html.text(value)],
	)

renderTree : Models.Tree(Models.Todo) -> Html.Node
renderTree = |taskTree|
	match taskTree {
		Empty => Html.li([], [Html.text("Empty")])
		Node(todo, children) =>
			Html.li(
				[],
				[
					Html.text("${todo.task} (${todo.status})"),
					Html.ul([], children.map(renderTree)),
				],
			)
		}

bigTaskTable : List(Models.BigTask), Str, Models.SortDirection -> Html.Node
bigTaskTable = |taskRows, sortBy, direction|
	Html.div(
		[Attribute.class("table-responsive")],
		[
			Html.table(
				[Attribute.class("table table-striped table-sm table-bordered")],
				[
					Html.thead(
						[],
						[
							Html.tr(
								[],
								[
									sortHeader("Reference", "ReferenceID", sortBy, direction),
									sortHeader("Customer", "CustomerReferenceID", sortBy, direction),
									sortHeader("Created", "DateCreated", sortBy, direction),
									sortHeader("Title", "Title", sortBy, direction),
									sortHeader("Status", "Status", sortBy, direction),
									sortHeader("Priority", "Priority", sortBy, direction),
									headerCell("Description"),
								],
							),
						],
					),
					Html.tbody([], taskRows.map(bigTaskRow)),
				],
			),
		],
	)

sortHeader : Str, Str, Str, Models.SortDirection -> Html.Node
sortHeader = |label, column, selected, direction| {
	next = 
		if selected == column and direction == Ascending {
			"desc"
		} else {
			"asc"
		}
	Html.th(
		[
			attribute("hx-get", "/bigTask?sortBy=${column}&sortDirection=${next}"),
			attribute("hx-target", "body"),
			Attribute.style("cursor:pointer;"),
		],
		[Html.text(label)],
	)
}

bigTaskRow : Models.BigTask -> Html.Node
bigTaskRow = |task| {
	id = task.id.to_str()
	Html.tr(
		[],
		[
			tableCell(task.referenceId),
			Html.td([], [editInput("/bigTask/customerId/${id}", "CustomerReferenceID", "text", task.customerReferenceId, "")]),
			Html.td([], [editInput("/bigTask/dateCreated/${id}", "DateCreated", "date", task.dateCreated, "")]),
			tableCell(task.title),
			Html.td([], [editStatus("/bigTask/status/${id}", task.status, "")]),
			tableCell(task.priority),
			tableCell(task.description),
		],
	)
}

editInput : Str, Str, Str, Str, Str -> Html.Node
editInput = |updateUrl, name, kind, value, validation|
	Html.form(
		[
			attribute("hx-put", updateUrl),
			attribute("hx-trigger", "input delay:250ms"),
			attribute("hx-swap", "outerHTML"),
		],
		[
			Html.input([
				Attribute.name(name),
				Attribute.type(kind),
				Attribute.value(value),
				Attribute.class("form-control"),
			]),
			errorMessage(validation),
		],
	)

editStatus : Str, Str, Str -> Html.Node
editStatus = |updateUrl, selected, validation|
	Html.form(
		[
			attribute("hx-put", updateUrl),
			attribute("hx-trigger", "change"),
			attribute("hx-swap", "outerHTML"),
		],
		[
			Html.select(
				[Attribute.name("Status"), Attribute.class("form-select")],
				[
					selectOption("Raised", selected == "Raised"),
					selectOption("Completed", selected == "Completed"),
					selectOption("Deferred", selected == "Deferred"),
					selectOption("Approved", selected == "Approved"),
					selectOption("In-Progress", selected == "In-Progress"),
				],
			),
			errorMessage(validation),
		],
	)

headerCell : Str -> Html.Node
headerCell = |value| Html.th([], [Html.text(value)])

tableCell : Str -> Html.Node
tableCell = |value| Html.td([], [Html.text(value)])

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
