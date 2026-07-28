import pf.Attribute
import pf.Html

import Actor
import Design
import Layout
import Route
import Web
import WorkTask

WorkTaskTarget := [RelatedTasks, Feedback].{
	to_selector : WorkTaskTarget -> Str
	to_selector = |target|
		match target {
			RelatedTasks => "#related-open-tasks"
			Feedback => "#related-task-feedback"
		}

	to_id : WorkTaskTarget -> Str
	to_id = |target|
		match target {
			RelatedTasks => "related-open-tasks"
			Feedback => "related-task-feedback"
		}
}

WorkTaskView := [].{
	page : Actor, List(WorkTask) -> Html.Node
	page = |actor, tasks|
		Layout.page(
			actor.session,
			Route.Page.Work,
			[
				Html.h1([Design.pageTitle], [Html.text("My Work")]),
				Html.p(
					[Design.lead],
					[
						Html.text(
							"Open follow-ups grouped in ${actor.workspace.timezone.to_str()}.",
						),
					],
				),
				Html.div(
					[Design.workGrid],
					[
						bucket("Overdue", tasks.keep_if(|task| task.bucket == WorkTask.Bucket.Overdue), True),
						bucket("Due today", tasks.keep_if(|task| task.bucket == WorkTask.Bucket.Today), False),
						bucket("Upcoming", tasks.keep_if(|task| task.bucket == WorkTask.Bucket.Upcoming), False),
					],
				),
			],
		)

	related_section : Actor, List(WorkTask), Route.PostAction, Route.TaskContext -> Html.Node
	related_section = |actor, tasks, create_action, completion_context|
		Html.element(
			"section",
			[
				Attribute.id(WorkTaskTarget.to_id(WorkTaskTarget.RelatedTasks)),
				Design.contentSection,
			],
			[
				Html.h2([Design.sectionHeading], [Html.text("Open tasks")]),
				Html.div(
					[
						Attribute.id(WorkTaskTarget.to_id(WorkTaskTarget.Feedback)),
						attribute("aria-live", "assertive"),
					],
					[],
				),
				Html.p(
					[Design.contentSectionText],
					[Html.text("Due times use ${actor.workspace.timezone.to_str()}.")],
				),
				task_list(tasks, completion_context, True),
				task_form(actor, create_action),
			],
		)
}

bucket : Str, List(WorkTask), Bool -> Html.Node
bucket = |title, tasks, overdue|
	Html.element(
		"section",
		[
			if overdue {
				Design.overdueBucket
			} else {
				Design.workBucket
			},
		],
		[
			Html.h2([Design.sectionHeading], [Html.text(title)]),
			task_list(tasks, Route.TaskContext.WorkList, False),
		],
	)

task_list : List(WorkTask), Route.TaskContext, Bool -> Html.Node
task_list = |tasks, completion_context, enhanced|
	Html.ul(
		[Design.taskList],
		if tasks.is_empty() {
			[Html.li([Design.secondaryText], [Html.text("No tasks in this group.")])]
		} else {
			tasks.map(|task| task_item(task, completion_context, enhanced))
		},
	)

task_item : WorkTask, Route.TaskContext, Bool -> Html.Node
task_item = |task, completion_context, enhanced|
	Html.li(
		[Design.taskItem],
		[
			Html.p([Design.taskSubject], [Html.text(task.subject.to_str())]),
			Html.div(
				[Design.taskMeta],
				[
					Html.p([Design.taskDue], [Html.text("Due: ${task.dueLocal.to_str()}")]),
					Html.p([], [Html.text("Assignee: ${task.assigneeName}")]),
					Html.p([], [Html.text("Type: ${task_type_label(task)}")]),
					Html.p([Design.taskRelated], [Html.text("Related to: ${related_label(task)}")]),
					Html.p([], [Html.text("Context: ${context_label(task)}")]),
				],
			),
			Web.post_form(
				Route.PostAction.CompleteTask(task.id, completion_context),
				complete_form_attributes(
					Route.PostAction.CompleteTask(task.id, completion_context),
					enhanced,
				),
				[
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Success, Design.ButtonSize.Small),
						],
						[
							Html.text("Complete"),
							if enhanced {
								Html.span(
									[
										Design.taskRequestStatus,
										attribute("role", "status"),
										attribute("aria-live", "polite"),
									],
									[Html.text("Completing…")],
								)
							} else {
								Html.text("")
							},
						],
					),
				],
			),
		],
	)

complete_form_attributes : Route.PostAction, Bool -> List(Attribute.Attribute)
complete_form_attributes = |action, enhanced|
	if enhanced {
		[
			Design.taskActions,
			Web.hx_post(action),
			Web.hx_target(WorkTaskTarget.RelatedTasks),
			Web.hx_select(WorkTaskTarget.RelatedTasks),
			Web.hx_swap(Web.Swap.OuterHtml),
			Web.hx_sync_first,
			Web.network_errors_to(WorkTaskTarget.Feedback),
		].concat(Web.hx_errors_to(WorkTaskTarget.Feedback))
	} else {
		[Design.taskActions]
	}

task_form : Actor, Route.PostAction -> Html.Node
task_form = |actor, action|
	Web.post_form(
		action,
		[Design.inlineForm],
		[
			field("Subject", Route.TaskInput.Subject, "Follow up"),
			Html.div(
				[Design.field],
				[
					Html.label(
						[Attribute.for_(Route.TaskInput.to_name(Route.TaskInput.DueLocal)), Design.label],
						[Html.text("Due in ${actor.workspace.timezone.to_str()}")],
					),
					Html.input([
						Attribute.id(Route.TaskInput.to_name(Route.TaskInput.DueLocal)),
						Attribute.name(Route.TaskInput.to_name(Route.TaskInput.DueLocal)),
						Attribute.type("datetime-local"),
						Design.input,
					]),
				],
			),
			Html.div(
				[Design.field],
				[
					Html.label(
						[Attribute.for_(Route.TaskInput.to_name(Route.TaskInput.Assignee)), Design.label],
						[Html.text("Assignee")],
					),
					Html.select(
						[
							Attribute.id(Route.TaskInput.to_name(Route.TaskInput.Assignee)),
							Attribute.name(Route.TaskInput.to_name(Route.TaskInput.Assignee)),
							Design.select,
						],
						actor.workspace.members.map(
							|member|
								Html.option(
									if member.id == actor.member.id {
										[Attribute.value(member.id.to_str()), attribute("selected", "")]
									} else {
										[Attribute.value(member.id.to_str())]
									},
									[Html.text(member.name.to_str())],
								),
						),
					),
				],
			),
			Html.div(
				[Design.field],
				[
					Html.label(
						[Attribute.for_(Route.TaskInput.to_name(Route.TaskInput.TaskType)), Design.label],
						[Html.text("Task type")],
					),
					Html.select(
						[
							Attribute.id(Route.TaskInput.to_name(Route.TaskInput.TaskType)),
							Attribute.name(Route.TaskInput.to_name(Route.TaskInput.TaskType)),
							Design.select,
						],
						[Html.option([Attribute.value("")], [Html.text("Not specified")])].concat(
							actor.workspace.taskTypes.map(
								|task_type|
									Html.option(
										[Attribute.value(task_type.id.to_str())],
										[Html.text(task_type.name)],
									),
							),
						),
					),
				],
			),
			field("Context", Route.TaskInput.Context, "What needs to happen?"),
			Html.button(
				[
					Attribute.type("submit"),
					Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular),
					Design.inlineFormAction,
				],
				[Html.text("Schedule task")],
			),
		],
	)

field : Str, Route.TaskInput, Str -> Html.Node
field = |label, input, placeholder|
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(input.to_name()), Design.label], [Html.text(label)]),
			Html.input([
				Attribute.id(input.to_name()),
				Attribute.name(input.to_name()),
				attribute("placeholder", placeholder),
				Design.input,
			]),
		],
	)

related_label : WorkTask -> Str
related_label = |task|
	if !task.personName.is_empty() {
		task.personName
	} else if !task.companyName.is_empty() {
		task.companyName
	} else {
		"Related CRM record"
	}

task_type_label : WorkTask -> Str
task_type_label = |task|
	if task.taskTypeName.is_empty() {
		"Not specified"
	} else {
		task.taskTypeName
	}

context_label : WorkTask -> Str
context_label = |task|
	if task.context.is_empty() {
		"Not provided"
	} else {
		task.context
	}

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
