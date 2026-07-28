import pf.Attribute
import pf.Html

import Activity
import Actor
import Company
import Design
import Layout
import Person
import Route
import Web
import WorkTask
import WorkTaskView

CompanyView :: [].{
	PageModel := {
		actor : Actor,
		companies : List(Company),
		filter : Company.Filter,
	}

	Form := {
		name : Str,
		owner : Str,
		lifecycle : Str,
		website : Str,
		phone : Str,
		source : Str,
		context : Str,
	}

	page : PageModel -> Html.Node
	page = |model|
		Layout.page(
			model.actor.session,
			Route.Page.Companies,
			[
				Html.div(
					[Design.pageHeader],
					[
						Html.div(
							[],
							[
								Html.h1([Design.pageTitle], [Html.text("Companies")]),
								Html.p(
									[Design.lead],
									[Html.text("Shared business relationships and their current follow-up context.")],
								),
							],
						),
						Web.link(
							Route.Page.CompanyNew,
							[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular)],
							[Html.text("New company")],
						),
					],
				),
				search_form(model.filter),
				company_table(model.companies, model.filter),
			],
		)

	new_page : Actor, Form, Str -> Html.Node
	new_page = |actor, form, validation|
		company_form_page(actor, form, validation, [])

	duplicate_page : Actor, Form, List(Company.Match) -> Html.Node
	duplicate_page = |actor, form, matches|
		company_form_page(actor, form, "", matches)

	edit_page : Actor, Company, Form, Str -> Html.Node
	edit_page = |actor, company, form, validation|
		edit_form_page(actor, company, form, validation, False)

	conflict_page : Actor, Company, Form -> Html.Node
	conflict_page = |actor, current, attempted|
		edit_form_page(actor, current, attempted, "", True)

	detail : Actor, Company, List(Person), List(WorkTask), List(Activity) -> Html.Node
	detail = |actor, company, people, tasks, history|
		Layout.page(
			actor.session,
			Route.Page.Companies,
			[
				Web.link(
					Route.Page.Companies,
					[Design.navLink],
					[Html.text("← Companies")],
				),
				Html.h1(
					[Design.pageTitle, Design.backLinkedPageTitle],
					[Html.text(company.name.to_str())],
				),
				Web.link(
					Route.Location.CompanyEdit(company.id),
					[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
					[Html.text("Edit company")],
				),
				Html.div(
					[Design.detailGrid],
					[
						Html.element(
							"section",
							[Design.detailPrimaryCard],
							[
								Html.h2([Design.sectionHeading], [Html.text("Relationship")]),
								detail_list([
									("Lifecycle", company.lifecycle.to_label()),
									("Owner", company.ownerName),
									("Source", display_optional(company.sourceName)),
									("Website", display_optional(company.website)),
									("Phone", display_optional(company.phone)),
									("Context", display_optional(company.context)),
								]),
							],
						),
						Html.element(
							"aside",
							[Design.detailCard],
							[
								Html.h2([Design.sectionHeading], [Html.text("Record")]),
								detail_list([
									("Created by", company.createdByName),
									("Created", company.createdAt.to_str()),
									("Last changed by", company.updatedByName),
									("Last changed", company.updatedAt.to_str()),
								]),
							],
						),
					],
				),
				people_section(company, people),
				WorkTaskView.related_section(
					actor,
					tasks,
					Route.PostAction.CreateCompanyTask(company.id),
					Route.TaskContext.CompanyRecord(company.id),
				),
				activity_section(history),
			],
		)
}

edit_form_page : Actor, Company, CompanyView.Form, Str, Bool -> Html.Node
edit_form_page = |actor, company, form, validation, conflict|
	Layout.page(
		actor.session,
		Route.Page.Companies,
		[
			Web.link(
				Route.Location.CompanyDetail(company.id),
				[Design.navLink],
				[Html.text("← ${company.name.to_str()}")],
			),
			Html.h1([Design.pageTitle, Design.backLinkedPageTitle], [Html.text("Edit company")]),
			if conflict {
				Html.element(
					"section",
					[Design.warningPanel],
					[
						Html.h2(
							[Design.warningHeading],
							[Html.text("This company changed while you were editing")],
						),
						Html.p(
							[Design.warningText],
							[
								Html.text(
									"The form below contains your attempted values. The current saved lifecycle is ${company.lifecycle.to_label()} and the current owner is ${company.ownerName}. Review and submit again to apply your values.",
								),
							],
						),
					],
				)
			} else {
				Html.text("")
			},
			if validation.is_empty() {
				Html.text("")
			} else {
				validation_summary("company-form-error", validation)
			},
			Web.post_form(
				Route.PostAction.UpdateCompany(company.id),
				[Design.recordForm],
				[
					Html.input([
						Attribute.type("hidden"),
						Attribute.name(Route.CompanyInput.to_name(Route.CompanyInput.Version)),
						Attribute.value(company.version.to_str()),
					]),
					text_field("Company name", Route.CompanyInput.Name, form.name, "Acme Studio"),
					text_field("Website", Route.CompanyInput.Website, form.website, "https://acme.example"),
					text_field("Phone", Route.CompanyInput.Phone, form.phone, "+61 3 9000 0000"),
					select_field(
						"Owner",
						Route.CompanyInput.Owner,
						form.owner,
						actor.workspace.members.map(|member| (member.id.to_str(), member.name.to_str())),
					),
					select_field(
						"Lifecycle",
						Route.CompanyInput.Lifecycle,
						form.lifecycle,
						[
							("lead", "Lead"),
							("prospect", "Prospect"),
							("customer", "Customer"),
							("inactive", "Inactive"),
						],
					),
					select_field(
						"Source",
						Route.CompanyInput.Source,
						form.source,
						[("", "Not recorded")].concat(
							actor.workspace.sources.map(|source| (source.id.to_str(), source.name)),
						),
					),
					Html.div(
						[Design.field],
						[
							Html.label(
								[Attribute.for_(Route.CompanyInput.to_name(Route.CompanyInput.Context)), Design.label],
								[Html.text("Relationship context")],
							),
							Html.element(
								"textarea",
								[
									Attribute.id(Route.CompanyInput.to_name(Route.CompanyInput.Context)),
									Attribute.name(Route.CompanyInput.to_name(Route.CompanyInput.Context)),
									Design.input,
									attribute("rows", "4"),
								],
								[Html.text(form.context)],
							),
						],
					),
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular),
						],
						[Html.text("Save company")],
					),
				],
			),
		],
	)

people_section : Company, List(Person) -> Html.Node
people_section = |company, people|
	Html.element(
		"section",
		[Design.contentSection],
		[
			Html.div(
				[Design.pageHeader],
				[
					Html.h2([Design.sectionHeading], [Html.text("People")]),
					Web.link(
						Route.Location.PersonNewForCompany(company.id),
						[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Small)],
						[Html.text("Add person")],
					),
				],
			),
			Html.ul(
				[Design.contactList],
				if people.is_empty() {
					[Html.li([Design.secondaryText], [Html.text("No people are associated with this company.")])]
				} else {
					people.map(
						|person|
							Html.li(
								[Design.contactRow],
								[
									Web.link(
										Route.Location.PersonDetail(person.id),
										[Design.recordLink],
										[Html.text(person.name.to_str())],
									),
									Html.p(
										[Design.secondaryText],
										[Html.text(display_optional(person.jobTitle))],
									),
								],
							),
					)
				},
			),
		],
	)

company_form_page : Actor, CompanyView.Form, Str, List(Company.Match) -> Html.Node
company_form_page = |actor, form, validation, matches|
	Layout.page(
		actor.session,
		Route.Page.CompanyNew,
		[
			Web.link(Route.Page.Companies, [Design.navLink], [Html.text("← Companies")]),
			Html.h1([Design.pageTitle, Design.backLinkedPageTitle], [Html.text("New company")]),
			Html.p(
				[Design.lead],
				[Html.text("Capture the relationship now; only the company name is required.")],
			),
			if validation.is_empty() {
				Html.text("")
			} else {
				validation_summary("company-form-error", validation)
			},
			if matches.is_empty() {
				Html.text("")
			} else {
				duplicate_panel(matches)
			},
			Web.post_form(
				if matches.is_empty() {
					Route.PostAction.PreviewCompany
				} else {
					Route.PostAction.CreateCompany
				},
				[Design.newRecordForm],
				[
					text_field("Company name", Route.CompanyInput.Name, form.name, "Acme Studio"),
					text_field("Website", Route.CompanyInput.Website, form.website, "https://acme.example"),
					text_field("Phone", Route.CompanyInput.Phone, form.phone, "+61 3 9000 0000"),
					select_field(
						"Owner",
						Route.CompanyInput.Owner,
						form.owner,
						actor.workspace.members.map(|member| (member.id.to_str(), member.name.to_str())),
					),
					select_field(
						"Lifecycle",
						Route.CompanyInput.Lifecycle,
						form.lifecycle,
						[
							("lead", "Lead"),
							("prospect", "Prospect"),
							("customer", "Customer"),
							("inactive", "Inactive"),
						],
					),
					select_field(
						"Source",
						Route.CompanyInput.Source,
						form.source,
						[("", "Not recorded")].concat(
							actor.workspace.sources.map(|source| (source.id.to_str(), source.name)),
						),
					),
					Html.div(
						[Design.field],
						[
							Html.label(
								[Attribute.for_(Route.CompanyInput.to_name(Route.CompanyInput.Context)), Design.label],
								[Html.text("Relationship context")],
							),
							Html.element(
								"textarea",
								[
									Attribute.id(Route.CompanyInput.to_name(Route.CompanyInput.Context)),
									Attribute.name(Route.CompanyInput.to_name(Route.CompanyInput.Context)),
									Design.input,
									attribute("rows", "4"),
								],
								[Html.text(form.context)],
							),
						],
					),
					if matches.is_empty() {
						Html.text("")
					} else {
						Html.input([
							Attribute.type("hidden"),
							Attribute.name(Route.CompanyInput.to_name(Route.CompanyInput.ConfirmDistinct)),
							Attribute.value("yes"),
						])
					},
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular),
						],
						[
							Html.text(
								if matches.is_empty() {
									"Check and save company"
								} else {
									"Create as a separate company"
								},
							),
						],
					),
				],
			),
		],
	)

duplicate_panel : List(Company.Match) -> Html.Node
duplicate_panel = |matches|
	Html.element(
		"section",
		[Design.warningPanelSpaced],
		[
			Html.h2([Design.warningSectionHeading], [Html.text("Check possible duplicates")]),
			Html.p(
				[Design.warningText],
				[Html.text("Review these existing companies before creating another record.")],
			),
			Html.ul(
				[Design.matchList],
				matches.map(
					|candidate|
						Html.li(
							[Design.matchItem],
							[
								Web.link(
									Route.Location.CompanyDetail(candidate.company.id),
									[Design.recordLink],
									[Html.text(candidate.company.name.to_str())],
								),
								Html.p(
									[Design.secondaryText],
									[Html.text("${candidate.strength.to_label()}: ${candidate.reason.to_label()}")],
								),
							],
						),
				),
			),
		],
	)

text_field : Str, Route.CompanyInput, Str, Str -> Html.Node
text_field = |label, input, value, placeholder|
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(input.to_name()), Design.label], [Html.text(label)]),
			Html.input([
				Attribute.id(input.to_name()),
				Attribute.name(input.to_name()),
				Attribute.value(value),
				attribute("placeholder", placeholder),
				Design.input,
			]),
		],
	)

select_field : Str, Route.CompanyInput, Str, List((Str, Str)) -> Html.Node
select_field = |label, input, selected, options|
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(input.to_name()), Design.label], [Html.text(label)]),
			Html.select(
				[Attribute.id(input.to_name()), Attribute.name(input.to_name()), Design.select],
				options.map(
					|(value, option_label)|
						Html.option(
							if value == selected {
								[Attribute.value(value), attribute("selected", "")]
							} else {
								[Attribute.value(value)]
							},
							[Html.text(option_label)],
						),
				),
			),
		],
	)

search_form : Company.Filter -> Html.Node
search_form = |filter|
	Html.form(
		[
			Attribute.action(Route.Page.to_href(Route.Page.Companies)),
			Attribute.method("get"),
			attribute("role", "search"),
			Design.searchForm,
		],
		[
			Html.label(
				[Attribute.for_("company-search"), Design.label],
				[Html.text("Search companies")],
			),
			Html.div(
				[Design.searchControls],
				[
					Html.input([
						Attribute.id("company-search"),
						Attribute.name("q"),
						Attribute.type("search"),
						Attribute.value(filter.to_str()),
						attribute("placeholder", "Name, website, or phone"),
						Design.searchInput,
					]),
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular),
						],
						[Html.text("Search")],
					),
				],
			),
		],
	)

company_table : List(Company), Company.Filter -> Html.Node
company_table = |companies, filter|
	if companies.is_empty() {
		company_empty_state(filter)
	} else {
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
										header_cell("Company"),
										header_cell("Lifecycle"),
										header_cell("Owner"),
										header_cell("Last changed"),
									],
								),
							],
						),
						Html.tbody(
							[Design.tableBody],
							companies.map(company_row),
						),
					],
				),
			],
		)
	}

company_empty_state : Company.Filter -> Html.Node
company_empty_state = |filter|
	Html.div(
		[Design.emptyStatePanel],
		if filter.to_str().is_empty() {
			[
				Html.p(
					[Design.emptyStateText],
					[Html.text("No companies have been recorded yet. Use New company to capture the first relationship.")],
				),
			]
		} else {
			[
				Html.p(
					[Design.emptyStateText],
					[Html.text("No companies match “${filter.to_str()}”. Clear the search to see every company.")],
				),
				Html.div(
					[Design.emptyStateActions],
					[
						Web.link(
							Route.Page.Companies,
							[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
							[Html.text("Clear search")],
						),
					],
				),
			]
		},
	)

company_row : Company -> Html.Node
company_row = |company|
	Html.tr(
		[Design.tableRow],
		[
			Html.td(
				[Design.tableCell],
				[
					Web.link(
						Route.Location.CompanyDetail(company.id),
						[Design.recordLink],
						[Html.text(company.name.to_str())],
					),
				],
			),
			Html.td(
				[Design.tableCell],
				[
					Html.span(
						[Design.badge(Design.BadgeTone.Neutral)],
						[Html.text(company.lifecycle.to_label())],
					),
				],
			),
			Html.td([Design.tableCell], [Html.text(company.ownerName)]),
			Html.td([Design.tableCell], [Html.text(company.updatedAt.to_str())]),
		],
	)

header_cell : Str -> Html.Node
header_cell = |label|
	Html.th([Design.tableHeader], [Html.text(label)])

detail_list : List((Str, Str)) -> Html.Node
detail_list = |items|
	Html.element(
		"dl",
		[Design.detailList],
		items.map(
			|(label, value)|
				Html.div(
					[],
					[
						Html.element("dt", [Design.detailTerm], [Html.text(label)]),
						Html.element("dd", [Design.detailValue], [Html.text(value)]),
					],
				),
		),
	)

activity_section : List(Activity) -> Html.Node
activity_section = |history|
	Html.element(
		"section",
		[Design.contentSection],
		[
			Html.h2([Design.sectionHeading], [Html.text("History")]),
			Html.ul(
				[Design.taskList],
				if history.is_empty() {
					[Html.li([Design.secondaryText], [Html.text("No recorded changes yet.")])]
				} else {
					history.map(
						|activity|
							Html.li(
								[Design.taskItem],
								[
									Html.p([], [Html.text(Activity.summary(activity))]),
									Html.p(
										[Design.activityMeta],
										[Html.text("${activity.createdByName} · ${activity.occurredAt.to_str()}")],
									),
								],
							),
					)
				},
			),
		],
	)

display_optional : Str -> Str
display_optional = |value|
	if value.is_empty() {
		"Not recorded"
	} else {
		value
	}

validation_summary : Str, Str -> Html.Node
validation_summary = |id, message|
	Html.p(
		[
			Attribute.id(id),
			attribute("role", "alert"),
			attribute("tabindex", "-1"),
			attribute("autofocus", ""),
			Design.validation,
		],
		[Html.text(message)],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
