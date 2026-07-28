import pf.Attribute
import pf.Html

import BigTask
import Design
import Layout
import Route
import Session
import Web

BigTaskTarget := [Results].{
	to_selector : BigTaskTarget -> Str
	to_selector = |_| "#big-task-results"

	to_id : BigTaskTarget -> Str
	to_id = |_| "big-task-results"
}

BigTaskView :: [].{
	PageModel := {
		session : Session,
		tasks : List(BigTask),
		query : BigTask.Query,
		total : I64,
	}

	EditorModel := {
		id : BigTask.Id,
		field : BigTask.Field,
		label : Str,
		value : Str,
		validation : Str,
	}

	page : PageModel -> Html.Node
	page = |model|
		Layout.page(
			model.session,
			Route.Page.BigTasks,
			[
				Html.h1([Design.pageTitle], [Html.text("Big Task Table")]),
				Web.link(
					Route.Location.BigTaskCsv,
					[
						Design.downloadButton,
						attribute("download", ""),
					],
					[Html.text("Download CSV")],
				),
				results(model),
			],
		)

	editor : EditorModel -> Html.Node
	editor = |model|
		match model.field {
			BigTask.Field.StatusField => status_editor(model)
			BigTask.Field.CustomerReferenceField => input_editor(model, "text")
			BigTask.Field.DateCreatedField => input_editor(model, "date")
		}

	results : PageModel -> Html.Node
	results = |model|
		Html.div(
			[
				Attribute.id(BigTaskTarget.to_id(BigTaskTarget.Results)),
				Web.hx_history_element,
			],
			[table(model), pagination(model)],
		)
}

table : BigTaskView.PageModel -> Html.Node
table = |model|
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
									sort_header("Reference", BigTask.SortColumn.ByReferenceId, model),
									sort_header("Customer", BigTask.SortColumn.ByCustomerReferenceId, model),
									sort_header("Created", BigTask.SortColumn.ByDateCreated, model),
									sort_header("Title", BigTask.SortColumn.ByTitle, model),
									sort_header("Status", BigTask.SortColumn.ByStatus, model),
									sort_header("Priority", BigTask.SortColumn.ByPriority, model),
									header_cell("Description"),
								],
							),
						],
					),
					Html.tbody(
						[Design.tableBody],
						if model.tasks.is_empty() {
							[empty_row()]
						} else {
							model.tasks.map(row)
						},
					),
				],
			),
		],
	)

sort_header : Str, BigTask.SortColumn, BigTaskView.PageModel -> Html.Node
sort_header = |label, column, model| {
	active = model.query.sortBy == column
	ascending = model.query.sortDirection == BigTask.SortDirection.Ascending
	next_direction = if active and ascending {
		BigTask.SortDirection.Descending
	} else {
		BigTask.SortDirection.Ascending
	}
	next_query = BigTask.Query.{
		page: BigTask.Page.default,
		items: model.query.items,
		sortBy: column,
		sortDirection: next_direction,
	}
	aria_sort = if active and ascending {
		"ascending"
	} else if active {
		"descending"
	} else {
		"none"
	}
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
		[
			Design.sortableHeader,
			attribute("scope", "col"),
			attribute("aria-sort", aria_sort),
		],
		[
			Web.link(
				Route.Location.BigTasks(next_query),
				[
					Design.sortableHeaderButton,
				].concat(results_navigation(Route.Location.BigTasks(next_query))),
				[
					Html.text(label),
					Html.span(
						[indicator, attribute("aria-hidden", "true")],
						[Html.text(arrow)],
					),
				],
			),
		],
	)
}

pagination : BigTaskView.PageModel -> Html.Node
pagination = |model| {
	items = model.query.items.to_i64()
	page = model.query.page.to_i64()
	last_page = if items > 0 {
		count = (model.total + items - 1) / items
		if count < 1 {
			1
		} else {
			count
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
						"Page ${page.to_str()} of ${last_page.to_str()} · ${model.total.to_str()} total rows",
					),
				],
			),
			Html.div(
				[Design.paginationLinks],
				[
					page_link("Previous", model, page - 1, page > 1),
					page_link("Next", model, page + 1, page < last_page),
				],
			),
		],
	)
}

page_link : Str, BigTaskView.PageModel, I64, Bool -> Html.Node
page_link = |label, model, target, enabled|
	if enabled {
		query = BigTask.Query.{
			page: BigTask.Page.from_i64(target),
			items: model.query.items,
			sortBy: model.query.sortBy,
			sortDirection: model.query.sortDirection,
		}
		Web.link(
			Route.Location.BigTasks(query),
			[Design.paginationLink].concat(results_navigation(Route.Location.BigTasks(query))),
			[Html.text(label)],
		)
	} else {
		Html.span(
			[
				Design.paginationDisabled,
				attribute("aria-disabled", "true"),
			],
			[Html.text(label)],
		)
	}

row : BigTask -> Html.Node
row = |task|
	Html.tr(
		[Design.tableRow],
		[
			table_cell(task.referenceId),
			Html.td(
				[Design.tableCellWide],
				[
					BigTaskView.editor({
						id: task.id,
						field: BigTask.Field.CustomerReferenceField,
						label: "Customer reference for task ${task.referenceId}",
						value: task.customerReferenceId.to_str(),
						validation: "",
					}),
				],
			),
			Html.td(
				[Design.tableCellWide],
				[
					BigTaskView.editor({
						id: task.id,
						field: BigTask.Field.DateCreatedField,
						label: "Date created for task ${task.referenceId}",
						value: task.dateCreated.to_str(),
						validation: "",
					}),
				],
			),
			table_cell(task.title),
			Html.td(
				[Design.tableCellWide],
				[
					BigTaskView.editor({
						id: task.id,
						field: BigTask.Field.StatusField,
						label: "Status for task ${task.referenceId}",
						value: task.status.to_str(),
						validation: "",
					}),
				],
			),
			table_cell(task.priority),
			table_cell(task.description),
		],
	)

input_editor : BigTaskView.EditorModel, Str -> Html.Node
input_editor = |model, kind|
	Html.form(
		editor_attributes(model),
		[
			Html.input([
				Attribute.name(model.field.form_name()),
				Attribute.type(kind),
				Attribute.value(model.value),
				attribute("aria-label", model.label),
				Design.input,
			]),
			error_message(model.validation),
		],
	)

status_editor : BigTaskView.EditorModel -> Html.Node
status_editor = |model|
	Html.form(
		editor_attributes(model),
		[
			Html.select(
				[
					Attribute.name(model.field.form_name()),
					attribute("aria-label", model.label),
					Design.select,
				],
				[
					status_option(BigTask.Status.Raised, model.value),
					status_option(BigTask.Status.Completed, model.value),
					status_option(BigTask.Status.Deferred, model.value),
					status_option(BigTask.Status.Approved, model.value),
					status_option(BigTask.Status.InProgress, model.value),
				],
			),
			error_message(model.validation),
		],
	)

editor_attributes : BigTaskView.EditorModel -> List(Attribute.Attribute)
editor_attributes = |model|
	[
		Web.hx_put(Route.PutAction.UpdateBigTask(model.id, model.field)),
		attribute(
			"hx-trigger",
			match model.field {
				BigTask.Field.StatusField => "change"
				_ => "input delay:250ms"
			},
		),
		Web.hx_swap(Web.Swap.OuterHtml),
	]

status_option : BigTask.Status, Str -> Html.Node
status_option = |status, selected| {
	value = status.to_str()
	Html.option(
		if value == selected {
			[Attribute.value(value), attribute("selected", "")]
		} else {
			[Attribute.value(value)]
		},
		[Html.text(value)],
	)
}

error_message : Str -> Html.Node
error_message = |message|
	if message.is_empty() {
		Html.div([], [])
	} else {
		Html.div([Design.validation], [Html.text(message)])
	}

empty_row : () -> Html.Node
empty_row = ||
	Html.tr(
		[],
		[
			Html.td(
				[Design.emptyState, attribute("colspan", "7")],
				[Html.text("No tasks on this page.")],
			),
		],
	)

header_cell : Str -> Html.Node
header_cell = |value|
	Html.th(
		[Design.tableHeader, attribute("scope", "col")],
		[Html.text(value)],
	)

table_cell : Str -> Html.Node
table_cell = |value| Html.td([Design.tableCell], [Html.text(value)])

results_navigation : Route.Location -> List(Attribute.Attribute)
results_navigation = |location|
	[
		Web.hx_get(location),
		Web.hx_target(BigTaskTarget.Results),
		Web.hx_select(BigTaskTarget.Results),
		Web.hx_swap(Web.Swap.OuterHtml),
	]

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
