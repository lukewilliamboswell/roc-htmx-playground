import pf.Attribute
import pf.Html

import Design
import Layout
import Route
import Session
import Todo
import Web

TodoTarget := [TodoList].{
	to_selector : TodoTarget -> Str
	to_selector = |_| "#todo-list"

	to_id : TodoTarget -> Str
	to_id = |_| "todo-list"
}

TodoView :: [].{
	PageModel := {
		session : Session,
		todos : List(Todo),
		filter : Todo.Filter,
	}

	page : PageModel -> Html.Node
	page = |model| {
		filter_name = Route.TodoInput.to_name(Route.TodoInput.Filter)
		Layout.page(
			model.session,
			Route.Page.Todos,
			[
				Html.h1([Design.pageTitle], [Html.text("Tasks")]),
				Html.form(
					[
						Web.hx_post(Route.PostAction.SearchTodos),
						attribute("hx-trigger", "input delay:250ms"),
						Web.hx_target(TodoTarget.TodoList),
						Web.hx_swap(Web.Swap.OuterHtml),
					],
					[
						Html.label([Attribute.for_(filter_name), Design.srOnly], [Html.text("Filter tasks")]),
						Html.input([
							Attribute.id(filter_name),
							Attribute.name(filter_name),
							Attribute.value(model.filter.to_str()),
							Design.searchInput,
							attribute("placeholder", "Filter tasks"),
						]),
					],
				),
				list_fragment(model.todos),
				new_form(),
			],
		)
	}

	list_fragment : List(Todo) -> Html.Node
	list_fragment = |todos|
		Html.div(
			[Attribute.id(TodoTarget.to_id(TodoTarget.TodoList)), Design.tableScroll],
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
										header_cell("Task"),
										header_cell("Status"),
										header_cell("Actions"),
									],
								),
							],
						),
						Html.tbody(
							[Design.tableBody],
							if todos.is_empty() {
								[empty_row("3", "No tasks to show.")]
							} else {
								todos.map(todo_row)
							},
						),
					],
				),
			],
		)

	tree_page : Session, Todo.Tree(Todo) -> Html.Node
	tree_page = |session, tree|
		Layout.page(
			session,
			Route.Page.TodoTree,
			[
				Html.h1([Design.pageTitle], [Html.text("Task hierarchy")]),
				Html.ul([Design.tree], [render_tree(tree)]),
			],
		)
}

todo_row : Todo -> Html.Node
todo_row = |todo|
	Html.tr(
		[Design.tableRow],
		[
			table_cell(todo.task.to_str()),
			Html.td(
				[Design.tableCell],
				[
					Html.span(
						[Design.badge(status_tone(todo.status))],
						[Html.text(todo.status.to_str())],
					),
				],
			),
			Html.td(
				[Design.tableCell],
				[
					Html.div(
						[Design.tableActions],
						[
							put_action_button(
								"Complete",
								Route.PutAction.CompleteTodo(todo.id),
								Design.ButtonTone.Success,
								todo.status != Todo.Status.Completed,
							),
							put_action_button(
								"In progress",
								Route.PutAction.StartTodo(todo.id),
								Design.ButtonTone.Warning,
								todo.status != Todo.Status.InProgress,
							),
							post_action_button(
								"Delete",
								Route.PostAction.DeleteTodo(todo.id),
								Design.ButtonTone.Danger,
							),
						],
					),
				],
			),
		],
	)

status_tone : Todo.Status -> Design.BadgeTone
status_tone = |status|
	match status {
		Todo.Status.Completed => Design.BadgeTone.Done
		Todo.Status.InProgress => Design.BadgeTone.Active
		Todo.Status.NotStarted => Design.BadgeTone.Neutral
	}

put_action_button : Str, Route.PutAction, Design.ButtonTone, Bool -> Html.Node
put_action_button = |label, action, tone, enabled|
	if enabled {
		Html.button(
			[
				Design.button(tone, Design.ButtonSize.Small),
				Web.hx_put(action),
				Web.hx_target(TodoTarget.TodoList),
				Web.hx_swap(Web.Swap.OuterHtml),
			],
			[Html.text(label)],
		)
	} else {
		disabled_action_button(label, tone)
	}

post_action_button : Str, Route.PostAction, Design.ButtonTone -> Html.Node
post_action_button = |label, action, tone|
	Html.button(
		[
			Design.button(tone, Design.ButtonSize.Small),
			Web.hx_post(action),
			Web.hx_target(TodoTarget.TodoList),
			Web.hx_swap(Web.Swap.OuterHtml),
		],
		[Html.text(label)],
	)

disabled_action_button : Str, Design.ButtonTone -> Html.Node
disabled_action_button = |label, tone|
	Html.button(
		[
			Attribute.type("button"),
			Design.button(tone, Design.ButtonSize.Small),
			attribute("disabled", ""),
		],
		[Html.text(label)],
	)

new_form : () -> Html.Node
new_form = || {
	task_name = Route.TodoInput.to_name(Route.TodoInput.Task)
	status_name = Route.TodoInput.to_name(Route.TodoInput.Status)
	Web.post_form(
		Route.PostAction.CreateTodo,
		[Design.todoForm],
		[
			Html.div(
				[Design.todoTask],
				[
					Html.label([Attribute.for_(task_name), Design.srOnly], [Html.text("New task")]),
					Html.input([
						Attribute.id(task_name),
						Attribute.name(task_name),
						Design.input,
						attribute("placeholder", "New task"),
						attribute("required", ""),
					]),
				],
			),
			Html.div(
				[Design.todoStatus],
				[
					Html.label([Attribute.for_(status_name), Design.srOnly], [Html.text("Status")]),
					Html.select(
						[Attribute.id(status_name), Attribute.name(status_name), Design.select],
						[
							status_option(Todo.Status.NotStarted),
							status_option(Todo.Status.InProgress),
							status_option(Todo.Status.Completed),
						],
					),
				],
			),
			Html.div(
				[Design.todoSubmit],
				[
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Full),
						],
						[Html.text("Add")],
					),
				],
			),
		],
	)
}

status_option : Todo.Status -> Html.Node
status_option = |status|
	Html.option(
		[Attribute.value(status.to_str())],
		[Html.text(status.to_str())],
	)

render_tree : Todo.Tree(Todo) -> Html.Node
render_tree = |tree|
	match tree {
		Empty => Html.li([Design.emptyState], [Html.text("No tasks to show.")])
		Node(todo, children) =>
			Html.li(
				[],
				[
					Html.text("${todo.task.to_str()} (${todo.status.to_str()})"),
					Html.ul([Design.treeChildren], children.map(render_tree)),
				],
			)
		}

empty_row : Str, Str -> Html.Node
empty_row = |columns, message|
	Html.tr(
		[],
		[Html.td([Design.emptyState, attribute("colspan", columns)], [Html.text(message)])],
	)

header_cell : Str -> Html.Node
header_cell = |label|
	Html.th(
		[Design.tableHeader, attribute("scope", "col")],
		[Html.text(label)],
	)

table_cell : Str -> Html.Node
table_cell = |value| Html.td([Design.tableCell], [Html.text(value)])

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
