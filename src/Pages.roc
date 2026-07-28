import pf.Attribute
import pf.Html

import Design
import Models

Pages :: [].{
	BigTaskPage : {
		session : Models.Session,
		tasks : List(Models.BigTask),
		page : I64,
		items : I64,
		total : I64,
		sortBy : Models.SortColumn,
		sortDirection : Models.SortDirection,
	}

	EditInput : {
		updateUrl : Str,
		name : Str,
		kind : Str,
		value : Str,
		validation : Str,
	}

	StatusInput : {
		updateUrl : Str,
		value : Str,
		validation : Str,
	}

	home : Models.Session -> Html.Node
	home = |session|
		simplePage(
			session,
			"Home",
			[
				Html.h1([Design.pageTitle], [Html.text("Roc + htmx playground")]),
				Html.p([Design.lead], [Html.text("Running on basic-webserver 0.14.0.")]),
				Html.div(
					[Design.actions],
					[
						Html.a([Attribute.href("/task"), Design.button(Primary, Regular)], [Html.text("Tasks")]),
						Html.a([Attribute.href("/treeview"), Design.button(Outline, Regular)], [Html.text("Tree")]),
						Html.a([Attribute.href("/bigTask"), Design.button(Outline, Regular)], [Html.text("BigTask")]),
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
				Html.h1([Design.pageTitle], [Html.text("Login")]),
				errorMessage(error),
				Html.form(
					[Attribute.action("/login"), Attribute.method("post")],
					[
						textInput("Username", "user", "text", username),
						Html.button([Attribute.type("submit"), Design.button(Primary, Regular)], [Html.text("Login")]),
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
				Html.h1([Design.pageTitle], [Html.text("Register")]),
				errorMessage(error),
				Html.form(
					[Attribute.action("/register"), Attribute.method("post")],
					[
						textInput("Username", "user", "text", username),
						textInput("Email", "email", "email", email),
						Html.button([Attribute.type("submit"), Design.button(Primary, Regular)], [Html.text("Register")]),
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
				Html.h1([Design.pageTitle], [Html.text("Tasks")]),
				Html.form(
					[
						attribute("hx-post", "/task/search"),
						attribute("hx-trigger", "input delay:250ms"),
						attribute("hx-target", "#todo-list"),
						attribute("hx-swap", "outerHTML"),
					],
					[
						Html.input([
							Attribute.name("filterTasks"),
							Attribute.value(filter),
							Design.searchInput,
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
				Html.h1([Design.pageTitle], [Html.text("Users")]),
				Html.div(
					[Design.tableFrame],
					[
						Html.table(
							[Design.table],
							[
								Html.thead([Design.tableHead], [Html.tr([], [headerCell("ID"), headerCell("Name"), headerCell("Email")])]),
								Html.tbody(
									[Design.tableBody],
									userRows.map(
										|user|
											Html.tr(
												[Design.tableRow],
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
				),
			],
		)

	tree : Models.Session, Models.Tree(Models.Todo) -> Html.Node
	tree = |session, taskTree|
		simplePage(
			session,
			"Tree",
			[
				Html.h1([Design.pageTitle], [Html.text("Task hierarchy")]),
				Html.ul([Design.tree], [renderTree(taskTree)]),
			],
		)

	unauthorized : Html.Node
	unauthorized = simplePage(Models.anonymousSession, "Unauthorized", [Html.h1([Design.pageTitle], [Html.text("Unauthorized")])])

	bigTasks : BigTaskPage -> Html.Node
	bigTasks = |model|
		simplePage(
			model.session,
			"BigTask",
			[
				Html.h1([Design.pageTitle], [Html.text("Big Task Table")]),
				Html.a(
					[
						Attribute.href("/bigTask/downloadCsv"),
						Design.downloadButton,
						attribute("download", ""),
					],
					[Html.text("Download CSV")],
				),
				bigTaskTable(model.tasks, model.sortBy, model.sortDirection),
				Html.p(
					[Design.pagination],
					[
						Html.text(
							"Page ${model.page.to_str()} · ${model.total.to_str()} total rows",
						),
					],
				),
			],
		)

	bigTaskInput : EditInput -> Html.Node
	bigTaskInput = |model| editInput(model)

	bigTaskStatus : StatusInput -> Html.Node
	bigTaskStatus = |model| editStatus(model)
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
					Html.link([Attribute.rel("stylesheet"), Attribute.href("/styles.css")]),
					Html.element("script", [Attribute.src("/htmx.min.js")], []),
				],
			),
			Html.body(
				[Design.body],
				[
					navbar(session),
					Html.main([Design.page], children),
				],
			),
		],
	)

navbar : Models.Session -> Html.Node
navbar = |session|
	Html.nav(
		[Design.nav],
		[
			Html.div(
				[Design.navInner],
				[
					Html.a([Design.brand, Attribute.href("/")], [Html.text("Roc + htmx")]),
					Html.ul(
						[Design.navLinks],
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
		[],
		[Html.a([Design.navLink, Attribute.href(href)], [Html.text(label)])],
	)

authControls : Models.Session -> Html.Node
authControls = |session|
	match session.user {
		Guest =>
			Html.div(
				[Design.auth],
				[
					Html.a([Attribute.href("/login"), Design.button(Outline, Small)], [Html.text("Login")]),
					Html.a([Attribute.href("/register"), Design.button(Primary, Small)], [Html.text("Register")]),
				],
			)
		LoggedIn(name) =>
			Html.form(
				[Attribute.action("/logout"), Attribute.method("post"), Design.auth],
				[
					Html.span([Design.userName], [Html.text(name)]),
					Html.button([Attribute.type("submit"), Design.button(Outline, Small)], [Html.text("Logout")]),
				],
			)
		}

textInput : Str, Str, Str, Str -> Html.Node
textInput = |label, name, kind, value|
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(name), Design.label], [Html.text(label)]),
			Html.input([
				Attribute.id(name),
				Attribute.name(name),
				Attribute.type(kind),
				Attribute.value(value),
				Design.input,
				attribute("required", ""),
			]),
		],
	)

errorMessage : Str -> Html.Node
errorMessage = |message|
	if message.is_empty() {
		Html.div([], [])
	} else {
		Html.div([Design.validation], [Html.text(message)])
	}

todoListNode : List(Models.Todo) -> Html.Node
todoListNode = |todoRows|
	Html.div(
		[Attribute.id("todo-list"), Design.tableFrame],
		[
			Html.table(
				[Design.table],
				[
					Html.thead([Design.tableHead], [Html.tr([], [headerCell("Task"), headerCell("Status"), headerCell("Actions")])]),
					Html.tbody([Design.tableBody], todoRows.map(todoRow)),
				],
			),
		],
	)

todoRow : Models.Todo -> Html.Node
todoRow = |todo| {
	id = todo.id.to_str()
	Html.tr(
		[Design.tableRow],
		[
			tableCell(todo.task),
			tableCell(todo.status),
			Html.td(
				[Design.tableCell],
				[
					Html.div(
						[Design.tableActions],
						[
							actionButton("Complete", "/task/${id}/complete", "hx-put", Success),
							actionButton("In progress", "/task/${id}/in-progress", "hx-put", Warning),
							Html.button(
								[
									Design.button(Danger, Small),
									attribute("hx-post", "/task/${id}/delete"),
									attribute("hx-target", "#todo-list"),
									attribute("hx-swap", "outerHTML"),
								],
								[Html.text("Delete")],
							),
						],
					),
				],
			),
		],
	)
}

actionButton : Str, Str, Str, Design.ButtonTone -> Html.Node
actionButton = |label, url, hxMethod, tone|
	Html.button(
		[
			Design.button(tone, Small),
			attribute(hxMethod, url),
			attribute("hx-target", "#todo-list"),
			attribute("hx-swap", "outerHTML"),
		],
		[Html.text(label)],
	)

newTodoForm : () -> Html.Node
newTodoForm = ||
	Html.form(
		[Attribute.action("/task/new"), Attribute.method("post"), Design.todoForm],
		[
			Html.div(
				[Design.todoTask],
				[
					Html.input([
						Attribute.name("task"),
						Design.input,
						attribute("placeholder", "New task"),
						attribute("required", ""),
					]),
				],
			),
			Html.div(
				[Design.todoStatus],
				[
					Html.select(
						[Attribute.name("status"), Design.select],
						[
							selectOption("Not Started", False),
							selectOption("In-Progress", False),
							selectOption("Completed", False),
						],
					),
				],
			),
			Html.div(
				[Design.todoSubmit],
				[Html.button([Attribute.type("submit"), Design.button(Primary, Full)], [Html.text("Add")])],
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
					Html.ul([Design.treeChildren], children.map(renderTree)),
				],
			)
		}

bigTaskTable : List(Models.BigTask), Models.SortColumn, Models.SortDirection -> Html.Node
bigTaskTable = |taskRows, sortBy, direction|
	Html.div(
		[Design.tableScroll],
		[
			Html.table(
				[Design.table],
				[
					Html.thead(
						[Design.tableHead],
						[
							Html.tr(
								[],
								[
									sortHeader("Reference", ByReferenceId, sortBy, direction),
									sortHeader("Customer", ByCustomerReferenceId, sortBy, direction),
									sortHeader("Created", ByDateCreated, sortBy, direction),
									sortHeader("Title", ByTitle, sortBy, direction),
									sortHeader("Status", ByStatus, sortBy, direction),
									sortHeader("Priority", ByPriority, sortBy, direction),
									headerCell("Description"),
								],
							),
						],
					),
					Html.tbody([Design.tableBody], taskRows.map(bigTaskRow)),
				],
			),
		],
	)

sortHeader : Str, Models.SortColumn, Models.SortColumn, Models.SortDirection -> Html.Node
sortHeader = |label, column, selected, direction| {
	next = if selected == column and direction == Ascending {
		"desc"
	} else {
		"asc"
	}
	Html.th(
		[
			attribute("hx-get", "/bigTask?sortBy=${column.to_str()}&sortDirection=${next}"),
			attribute("hx-target", "body"),
			Design.sortableHeader,
		],
		[Html.text(label)],
	)
}

bigTaskRow : Models.BigTask -> Html.Node
bigTaskRow = |task| {
	id = task.id.to_str()
	Html.tr(
		[Design.tableRow],
		[
			tableCell(task.referenceId),
			Html.td(
				[Design.tableCellWide],
				[
					editInput({
						updateUrl: "/bigTask/customerId/${id}",
						name: "CustomerReferenceID",
						kind: "text",
						value: task.customerReferenceId,
						validation: "",
					}),
				],
			),
			Html.td(
				[Design.tableCellWide],
				[
					editInput({
						updateUrl: "/bigTask/dateCreated/${id}",
						name: "DateCreated",
						kind: "date",
						value: task.dateCreated,
						validation: "",
					}),
				],
			),
			tableCell(task.title),
			Html.td(
				[Design.tableCellWide],
				[
					editStatus({
						updateUrl: "/bigTask/status/${id}",
						value: task.status,
						validation: "",
					}),
				],
			),
			tableCell(task.priority),
			tableCell(task.description),
		],
	)
}

editInput : Pages.EditInput -> Html.Node
editInput = |{ updateUrl, name, kind, value, validation }|
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
				Design.input,
			]),
			errorMessage(validation),
		],
	)

editStatus : Pages.StatusInput -> Html.Node
editStatus = |{ updateUrl, value: selected, validation }|
	Html.form(
		[
			attribute("hx-put", updateUrl),
			attribute("hx-trigger", "change"),
			attribute("hx-swap", "outerHTML"),
		],
		[
			Html.select(
				[Attribute.name("Status"), Design.select],
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
headerCell = |value| Html.th([Design.tableHeader], [Html.text(value)])

tableCell : Str -> Html.Node
tableCell = |value| Html.td([Design.tableCell], [Html.text(value)])

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
