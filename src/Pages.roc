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
		label : Str,
		kind : Str,
		value : Str,
		validation : Str,
	}

	StatusInput : {
		updateUrl : Str,
		label : Str,
		value : Str,
		validation : Str,
	}

	home : Models.Session -> Html.Node
	home = |session|
		simplePage(
			session,
			"Home",
			[
				Html.element(
					"section",
					[Design.hero, attribute("aria-labelledby", "home-heading")],
					[
						Html.div(
							[Design.heroCopy],
							[
								Html.p([Design.eyebrow], [Html.text("A tiny server with real app patterns")]),
								Html.h1(
									[Attribute.id("home-heading"), Design.heroTitle],
									[Html.text("Build useful things with Roc + htmx")],
								),
								Html.p(
									[Design.heroLead],
									[
										Html.text(
											"Explore forms, live updates, SQLite data, sessions, and now embedded image assets—all on basic-webserver 0.14.0.",
										),
									],
								),
								Html.div(
									[Design.heroActions],
									[
										Html.a([Attribute.href("/task"), Design.button(Primary, Regular)], [Html.text("Explore tasks")]),
										Html.a([Attribute.href("/treeview"), Design.button(Outline, Regular)], [Html.text("View hierarchy")]),
									],
								),
							],
						),
						Html.element(
							"figure",
							[Design.heroVisual],
							[
								image(
									"/assets/planning-desk.webp",
									"An open notebook beside pens and a small plant on a desk",
									Design.heroImage,
									"1600",
									"1067",
								),
								Html.element(
									"figcaption",
									[Design.photoCredit],
									[
										Html.text("Photo by "),
										externalLink("Kelly Sikkema", "https://unsplash.com/@kellysikkema"),
										Html.text(" on "),
										externalLink(
											"Unsplash",
											"https://unsplash.com/photos/an-open-notebook-and-pens-on-a-desk-hBdaqrr5Z3k",
										),
									],
								),
							],
						),
					],
				),
				Html.h2([Design.featureHeading], [Html.text("Four ways to explore the playground")]),
				Html.p(
					[Design.featureLead],
					[
						Html.text(
							"Each area demonstrates a pattern a production app is likely to need, with a reusable vector icon served by Roc.",
						),
					],
				),
				Html.div(
					[Design.featureGrid],
					[
						featureCard(
							"Tasks",
							"Create, filter, update, and delete work with focused htmx swaps.",
							"/task",
							"/assets/icons/tasks.svg",
						),
						featureCard(
							"Users",
							"See registered accounts and the shared session-aware navigation.",
							"/user",
							"/assets/icons/users.svg",
						),
						featureCard(
							"Hierarchy",
							"Render nested task relationships as an accessible server-built tree.",
							"/treeview",
							"/assets/icons/tree.svg",
						),
						featureCard(
							"BigTask",
							"Exercise sorting, pagination, inline editing, and CSV download.",
							"/bigTask",
							"/assets/icons/table.svg",
						),
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
					[Attribute.action("/login"), Attribute.method("post"), Design.form],
					[
						textInput("Username", "user", "text", username),
						Html.button([Attribute.type("submit"), Design.button(Primary, Regular)], [Html.text("Login")]),
					],
				),
			],
		)

	register : Models.Session, Str, Str, Str -> Html.Node
	register = |session, username, email, error|
		simplePage(
			session,
			"Register",
			[
				Html.h1([Design.pageTitle], [Html.text("Register")]),
				errorMessage(error),
				Html.form(
					[Attribute.action("/register"), Attribute.method("post"), Design.form],
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
						Html.label([Attribute.for_("filterTasks"), Design.srOnly], [Html.text("Filter tasks")]),
						Html.input([
							Attribute.id("filterTasks"),
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
					[Design.tableScroll],
					[
						Html.table(
							[Design.table],
							[
								Html.thead([Design.tableHead], [Html.tr([], [headerCell("ID"), headerCell("Name"), headerCell("Email")])]),
								Html.tbody(
									[Design.tableBody],
									if userRows.len() == 0 {
										[emptyRow("3", "No users have registered yet.")]
									} else {
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
										)
									},
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

	unauthorized : Models.Session -> Html.Node
	unauthorized = |session|
		simplePage(
			session,
			"Unauthorized",
			[
				Html.h1([Design.pageTitle], [Html.text("Unauthorized")]),
				Html.p([Design.lead], [Html.text("You need to be signed in to view this page.")]),
				Html.div(
					[Design.actions],
					[
						Html.a([Attribute.href("/login"), Design.button(Primary, Regular)], [Html.text("Login")]),
						Html.a([Attribute.href("/register"), Design.button(Outline, Regular)], [Html.text("Register")]),
					],
				),
			],
		)

	notFound : Models.Session -> Html.Node
	notFound = |session|
		errorPage(
			session,
			"Not Found",
			"Page not found",
			"We could not find the page you were looking for.",
		)

	badRequest : Models.Session, Str -> Html.Node
	badRequest = |session, message|
		errorPage(session, "Bad Request", "That request could not be processed", message)

	serverError : Models.Session -> Html.Node
	serverError = |session|
		errorPage(
			session,
			"Server Error",
			"Something went wrong",
			"The server hit an unexpected error. Please try again.",
		)

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
				bigTaskTable(model),
				paginationBar(model),
			],
		)

	bigTaskInput : EditInput -> Html.Node
	bigTaskInput = |model| editInput(model)

	bigTaskStatus : StatusInput -> Html.Node
	bigTaskStatus = |model| editStatus(model)
}

simplePage : Models.Session, Str, List(Html.Node) -> Html.Node
simplePage = |session, title, children| {
	scripts = if title == "Tasks" or title == "BigTask" {
		[
			Html.element(
				"script",
				[
					Attribute.src("/htmx.min.js?v=4.0.0-beta6"),
					attribute("defer", ""),
				],
				[],
			),
		]
	} else {
		[]
	}

	Html.html(
		[attribute("lang", "en")],
		[
			Html.head(
				[],
				[
					Html.meta([attribute("charset", "utf-8")]),
					Html.meta([Attribute.name("viewport"), attribute("content", "width=device-width, initial-scale=1")]),
					Html.meta([
						Attribute.name("description"),
						attribute(
							"content",
							"Explore a server-rendered Roc and htmx application with tasks, sessions, SQLite data, and native static assets.",
						),
					]),
					Html.title([], [Html.text(title)]),
					Html.link([Attribute.rel("icon"), Attribute.href("/assets/icons/tasks.svg"), attribute("type", "image/svg+xml")]),
					Html.link([Attribute.rel("stylesheet"), Attribute.href("/styles.css?v=20260728")]),
				].concat(scripts),
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
}

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

featureCard : Str, Str, Str, Str -> Html.Node
featureCard = |title, description, href, iconSrc|
	Html.a(
		[Attribute.href(href), Design.featureCard],
		[
			Html.div(
				[Design.featureIconFrame],
				[decorativeImage(iconSrc, Design.featureIcon, "24", "24")],
			),
			Html.h3([Design.featureTitle], [Html.text(title)]),
			Html.p([Design.featureText], [Html.text(description)]),
			Html.p([Design.featureLink], [Html.text("Open demo →")]),
		],
	)

image : Str, Str, Attribute.Attribute, Str, Str -> Html.Node
image = |src, alt, style, width, height|
	Html.element(
		"img",
		[
			Attribute.src(src),
			attribute(
				"srcset",
				"/assets/planning-desk-480.webp 480w, /assets/planning-desk-640.webp 640w, /assets/planning-desk-720.webp 720w, /assets/planning-desk-960.webp 960w, /assets/planning-desk.webp 1600w",
			),
			attribute(
				"sizes",
				"(min-width: 1280px) 640px, (min-width: 1024px) 50vw, calc(100vw - 2rem)",
			),
			attribute("alt", alt),
			attribute("width", width),
			attribute("height", height),
			attribute("decoding", "async"),
			attribute("fetchpriority", "high"),
			style,
		],
		[],
	)

decorativeImage : Str, Attribute.Attribute, Str, Str -> Html.Node
decorativeImage = |src, style, width, height|
	Html.element(
		"img",
		[
			Attribute.src(src),
			attribute("alt", ""),
			attribute("aria-hidden", "true"),
			attribute("width", width),
			attribute("height", height),
			style,
		],
		[],
	)

externalLink : Str, Str -> Html.Node
externalLink = |label, href|
	Html.a(
		[
			Attribute.href(href),
			attribute("target", "_blank"),
			attribute("rel", "noopener noreferrer"),
			Design.photoCreditLink,
		],
		[Html.text(label)],
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

errorPage : Models.Session, Str, Str, Str -> Html.Node
errorPage = |session, title, heading, message|
	simplePage(
		session,
		title,
		[
			Html.h1([Design.pageTitle], [Html.text(heading)]),
			Html.p([Design.lead], [Html.text(message)]),
			Html.div(
				[Design.actions],
				[Html.a([Attribute.href("/"), Design.button(Primary, Regular)], [Html.text("Back to home")])],
			),
		],
	)

errorMessage : Str -> Html.Node
errorMessage = |message|
	if message.is_empty() {
		Html.div([], [])
	} else {
		Html.div([Design.validation], [Html.text(message)])
	}

emptyRow : Str, Str -> Html.Node
emptyRow = |columns, message|
	Html.tr(
		[],
		[Html.td([Design.emptyState, attribute("colspan", columns)], [Html.text(message)])],
	)

todoListNode : List(Models.Todo) -> Html.Node
todoListNode = |todoRows|
	Html.div(
		[Attribute.id("todo-list"), Design.tableScroll],
		[
			Html.table(
				[Design.table],
				[
					Html.thead([Design.tableHead], [Html.tr([], [headerCell("Task"), headerCell("Status"), headerCell("Actions")])]),
					Html.tbody(
						[Design.tableBody],
						if todoRows.len() == 0 {
							[emptyRow("3", "No tasks to show.")]
						} else {
							todoRows.map(todoRow)
						},
					),
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
			Html.td(
				[Design.tableCell],
				[Html.span([Design.badge(statusTone(todo.status))], [Html.text(todo.status)])],
			),
			Html.td(
				[Design.tableCell],
				[
					Html.div(
						[Design.tableActions],
						[
							actionButton("Complete", "/task/${id}/complete", "hx-put", Success, todo.status != "Completed"),
							actionButton("In progress", "/task/${id}/in-progress", "hx-put", Warning, todo.status != "In-Progress"),
							actionButton("Delete", "/task/${id}/delete", "hx-post", Danger, Bool.True),
						],
					),
				],
			),
		],
	)
}

statusTone : Str -> Design.BadgeTone
statusTone = |status|
	match status {
		"Completed" => Done
		"In-Progress" => Active
		_ => Neutral
	}

actionButton : Str, Str, Str, Design.ButtonTone, Bool -> Html.Node
actionButton = |label, url, hxMethod, tone, enabled|
	if enabled {
		Html.button(
			[
				Design.button(tone, Small),
				attribute(hxMethod, url),
				attribute("hx-target", "#todo-list"),
				attribute("hx-swap", "outerHTML"),
			],
			[Html.text(label)],
		)
	} else {
		Html.button(
			[
				Attribute.type("button"),
				Design.button(tone, Small),
				attribute("disabled", ""),
			],
			[Html.text(label)],
		)
	}

newTodoForm : () -> Html.Node
newTodoForm = ||
	Html.form(
		[Attribute.action("/task/new"), Attribute.method("post"), Design.todoForm],
		[
			Html.div(
				[Design.todoTask],
				[
					Html.label([Attribute.for_("task"), Design.srOnly], [Html.text("New task")]),
					Html.input([
						Attribute.id("task"),
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
					Html.label([Attribute.for_("status"), Design.srOnly], [Html.text("Status")]),
					Html.select(
						[Attribute.id("status"), Attribute.name("status"), Design.select],
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
		Empty => Html.li([Design.emptyState], [Html.text("No tasks to show.")])
		Node(todo, children) =>
			Html.li(
				[],
				[
					Html.text("${todo.task} (${todo.status})"),
					Html.ul([Design.treeChildren], children.map(renderTree)),
				],
			)
		}

bigTaskTable : Pages.BigTaskPage -> Html.Node
bigTaskTable = |model|
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
									sortHeader("Reference", ByReferenceId, model),
									sortHeader("Customer", ByCustomerReferenceId, model),
									sortHeader("Created", ByDateCreated, model),
									sortHeader("Title", ByTitle, model),
									sortHeader("Status", ByStatus, model),
									sortHeader("Priority", ByPriority, model),
									headerCell("Description"),
								],
							),
						],
					),
					Html.tbody(
						[Design.tableBody],
						if model.tasks.len() == 0 {
							[emptyRow("7", "No tasks on this page.")]
						} else {
							model.tasks.map(bigTaskRow)
						},
					),
				],
			),
		],
	)

sortHeader : Str, Models.SortColumn, Pages.BigTaskPage -> Html.Node
sortHeader = |label, column, model| {
	active = model.sortBy == column
	ascending = model.sortDirection == Ascending
	next = if active and ascending {
		"desc"
	} else {
		"asc"
	}
	ariaSort = if active and ascending {
		"ascending"
	} else if active {
		"descending"
	} else {
		"none"
	}
	# Geometric-shape triangles avoid the emoji presentation that arrow
	# codepoints pick up from the sans-serif stack's colour emoji fonts.
	arrow = if active and ascending {
		"▲"
	} else if active {
		"▼"
	} else {
		"▾"
	}
	indicator = if active {
		Design.sortIndicatorActive
	} else {
		Design.sortIndicator
	}

	Html.th(
		[Design.sortableHeader, attribute("scope", "col"), attribute("aria-sort", ariaSort)],
		[
			Html.button(
				[
					Attribute.type("button"),
					Design.sortableHeaderButton,
					attribute(
						"hx-get",
						"/bigTask?items=${model.items.to_str()}&sortBy=${column.to_str()}&sortDirection=${next}",
					),
					attribute("hx-target", "body"),
				],
				[
					Html.text(label),
					Html.span([indicator, attribute("aria-hidden", "true")], [Html.text(arrow)]),
				],
			),
		],
	)
}

paginationBar : Pages.BigTaskPage -> Html.Node
paginationBar = |model| {
	lastPage = if model.items > 0 {
		pages = (model.total + model.items - 1) / model.items
		if pages < 1 {
			1
		} else {
			pages
		}
	} else {
		1
	}

	Html.div(
		[Design.pagination],
		[
			Html.p(
				[Design.paginationInfo],
				[
					Html.text(
						"Page ${model.page.to_str()} of ${lastPage.to_str()} · ${model.total.to_str()} total rows",
					),
				],
			),
			Html.div(
				[Design.paginationLinks],
				[
					pageLink("Previous", bigTaskPageUrl(model, model.page - 1), model.page > 1),
					pageLink("Next", bigTaskPageUrl(model, model.page + 1), model.page < lastPage),
				],
			),
		],
	)
}

bigTaskPageUrl : Pages.BigTaskPage, I64 -> Str
bigTaskPageUrl = |model, target|
	"/bigTask?page=${target.to_str()}&items=${model.items.to_str()}&sortBy=${model.sortBy.to_str()}&sortDirection=${model.sortDirection.to_str()}"

pageLink : Str, Str, Bool -> Html.Node
pageLink = |label, url, enabled|
	if enabled {
		Html.a([Attribute.href(url), Design.paginationLink], [Html.text(label)])
	} else {
		Html.span(
			[Design.paginationDisabled, attribute("aria-disabled", "true")],
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
						label: "Customer reference for task ${task.referenceId}",
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
						label: "Date created for task ${task.referenceId}",
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
						label: "Status for task ${task.referenceId}",
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
editInput = |{ updateUrl, name, label, kind, value, validation }|
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
				attribute("aria-label", label),
				Design.input,
			]),
			errorMessage(validation),
		],
	)

editStatus : Pages.StatusInput -> Html.Node
editStatus = |{ updateUrl, label, value: selected, validation }|
	Html.form(
		[
			attribute("hx-put", updateUrl),
			attribute("hx-trigger", "change"),
			attribute("hx-swap", "outerHTML"),
		],
		[
			Html.select(
				[Attribute.name("Status"), attribute("aria-label", label), Design.select],
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
headerCell = |value| Html.th([Design.tableHeader, attribute("scope", "col")], [Html.text(value)])

tableCell : Str -> Html.Node
tableCell = |value| Html.td([Design.tableCell], [Html.text(value)])

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
