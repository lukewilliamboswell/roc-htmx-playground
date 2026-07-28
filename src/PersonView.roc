import pf.Attribute
import pf.Html

import Actor
import Company
import Design
import Layout
import Person
import Route
import Web
import WorkTask
import WorkTaskView

PersonView :: [].{
	Form := {
		name : Str,
		company : Str,
		jobTitle : Str,
		lifecycle : Str,
		source : Str,
		context : Str,
		email : Str,
		phone : Str,
	}

	page : Actor, List(Person), Person.Filter -> Html.Node
	page = |actor, people, filter|
		Layout.page(
			actor.session,
			Route.Page.People,
			[
				Html.div(
					[Design.pageHeader],
					[
						Html.div(
							[],
							[
								Html.h1([Design.pageTitle], [Html.text("People")]),
								Html.p(
									[Design.lead],
									[Html.text("The people your team follows up with, with or without a company.")],
								),
							],
						),
						Web.link(
							Route.Page.PersonNew,
							[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular)],
							[Html.text("New person")],
						),
					],
				),
				search_form(filter),
				people_table(people),
			],
		)

	detail : Actor, Person, List(WorkTask) -> Html.Node
	detail = |actor, person, tasks|
		Layout.page(
			actor.session,
			Route.Page.People,
			[
				Web.link(Route.Page.People, [Design.navLink], [Html.text("← People")]),
				Html.h1(
					[Design.pageTitle, Design.backLinkedPageTitle],
					[Html.text(person.name.to_str())],
				),
				Web.link(
					Route.Location.PersonEdit(person.id),
					[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
					[Html.text("Edit person")],
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
									("Company", optional(person.companyName)),
									("Role or title", optional(person.jobTitle)),
									("Lifecycle", person.lifecycle.to_label()),
									("Owner", person.ownerName),
									("Source", optional(person.sourceName)),
									("Context", optional(person.context)),
								]),
							],
						),
						Html.element(
							"aside",
							[Design.detailCard],
							[
								Html.h2([Design.sectionHeading], [Html.text("Record")]),
								detail_list([
									("Created by", person.createdByName),
									("Created", person.createdAt),
									("Last changed by", person.updatedByName),
									("Last changed", person.updatedAt),
								]),
							],
						),
					],
				),
				contact_section(person, Email),
				contact_section(person, Phone),
				WorkTaskView.related_section(
					actor,
					tasks,
					Route.PostAction.CreatePersonTask(person.id),
				),
			],
		)

	new_page : Actor, List(Company), Form, Str, List(Person.Match) -> Html.Node
	new_page = |actor, companies, form, validation, matches|
		form_page(actor, companies, None, form, validation, matches)

	edit_page : Actor, List(Company), Person, Form, Str -> Html.Node
	edit_page = |actor, companies, person, form, validation|
		form_page(actor, companies, Some(person), form, validation, [])
}

form_page : Actor, List(Company), [None, Some(Person)], PersonView.Form, Str, List(Person.Match) -> Html.Node
form_page = |actor, companies, existing, form, validation, matches| {
	editing = match existing {
		Some(_) => True
		None => False
	}
	Layout.page(
		actor.session,
		if editing {
			Route.Page.People
		} else {
			Route.Page.PersonNew
		},
		[
			Web.link(Route.Page.People, [Design.navLink], [Html.text("← People")]),
			Html.h1(
				[Design.pageTitle, Design.backLinkedPageTitle],
				[
					Html.text(
						if editing {
							"Edit person"
						} else {
							"New person"
						},
					),
				],
			),
			if validation.is_empty() {
				Html.text("")
			} else {
				Html.p([Design.validation], [Html.text(validation)])
			},
			if matches.is_empty() {
				Html.text("")
			} else {
				match_panel(matches)
			},
			Web.post_form(
				match existing {
					Some(person) => Route.PostAction.UpdatePerson(person.id)
					None if matches.is_empty() => Route.PostAction.PreviewPerson
					None => Route.PostAction.CreatePerson
				},
				[Design.newRecordForm],
				[
					match existing {
						Some(person) =>
							Html.input([
								Attribute.type("hidden"),
								Attribute.name(Route.PersonInput.to_name(Route.PersonInput.Version)),
								Attribute.value(person.version.to_str()),
							])
						None => Html.text("")
					},
					text_field("Name", Route.PersonInput.Name, form.name, "Ada Lovelace"),
					text_field("Role or title", Route.PersonInput.JobTitle, form.jobTitle, "Operations lead"),
					select_field(
						"Company",
						Route.PersonInput.Company,
						form.company,
						[("", "No company")].concat(
							companies.map(|company| (company.id.to_str(), company.name.to_str())),
						),
					),
					select_field(
						"Lifecycle",
						Route.PersonInput.Lifecycle,
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
						Route.PersonInput.Source,
						form.source,
						[("", "Not recorded")].concat(
							actor.workspace.sources.map(|source| (source.id.to_str(), source.name)),
						),
					),
					if editing {
						Html.text("")
					} else {
						Html.div(
							[],
							[
								text_field("Email", Route.PersonInput.Email, form.email, "ada@example.com"),
								text_field("Phone", Route.PersonInput.Phone, form.phone, "+61 3 9000 0000"),
							],
						)
					},
					Html.div(
						[Design.field],
						[
							Html.label(
								[Attribute.for_(Route.PersonInput.to_name(Route.PersonInput.Context)), Design.label],
								[Html.text("Relationship context")],
							),
							Html.element(
								"textarea",
								[
									Attribute.id(Route.PersonInput.to_name(Route.PersonInput.Context)),
									Attribute.name(Route.PersonInput.to_name(Route.PersonInput.Context)),
									attribute("rows", "4"),
									Design.input,
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
							Attribute.name(Route.PersonInput.to_name(Route.PersonInput.ConfirmDistinct)),
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
								if editing {
									"Save person"
								} else if matches.is_empty() {
									"Check and save person"
								} else {
									"Create as a separate person"
								},
							),
						],
					),
				],
			),
		],
	)
}

contact_section : Person, [Email, Phone] -> Html.Node
contact_section = |person, kind| {
	methods = match kind {
		Email => person.emails
		Phone => person.phones
	}
	title = match kind {
		Email => "Email addresses"
		Phone => "Phone numbers"
	}
	action = match kind {
		Email => Route.PostAction.AddPersonEmail(person.id)
		Phone => Route.PostAction.AddPersonPhone(person.id)
	}
	Html.element(
		"section",
		[Design.contentSection],
		[
			Html.h2([Design.sectionHeading], [Html.text(title)]),
			Html.ul(
				[Design.contactList],
				if methods.is_empty() {
					[Html.li([Design.secondaryText], [Html.text("None recorded.")])]
				} else {
					methods.map(
						|method|
							Html.li(
								[Design.contactRow],
								[
									Html.div(
										[],
										[
											Html.p([], [Html.text(method.value)]),
											Html.p(
												[Design.contactMeta],
												[
													Html.text(
														if method.primary {
															"${method.label} · Primary"
														} else {
															method.label
														},
													),
												],
											),
										],
									),
									Web.post_form(
										match kind {
											Email => Route.PostAction.DeletePersonEmail(person.id, method.id)
											Phone => Route.PostAction.DeletePersonPhone(person.id, method.id)
										},
										[],
										[
											Html.button(
												[Attribute.type("submit"), Design.dangerLinkButton],
												[Html.text("Remove")],
											),
										],
									),
								],
							),
					)
				},
			),
			Web.post_form(
				action,
				[Design.inlineForm],
				[
					text_field("Label", Route.PersonInput.Label, "Work", "Work"),
					text_field("Value", Route.PersonInput.Value, "", ""),
					Html.label(
						[Design.checkboxLabel],
						[
							Html.input([
								Attribute.type("checkbox"),
								Attribute.name(Route.PersonInput.to_name(Route.PersonInput.Primary)),
								Attribute.value("yes"),
							]),
							Html.text("Make primary"),
						],
					),
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular),
						],
						[Html.text("Add")],
					),
				],
			),
		],
	)
}

match_panel : List(Person.Match) -> Html.Node
match_panel = |matches|
	Html.element(
		"section",
		[Design.warningPanelSpaced],
		[
			Html.h2([Design.warningSectionHeading], [Html.text("Check possible duplicates")]),
			Html.ul(
				[Design.matchList],
				matches.map(
					|candidate|
						Html.li(
							[Design.matchItem],
							[
								Web.link(
									Route.Location.PersonDetail(candidate.person.id),
									[Design.recordLink],
									[Html.text(candidate.person.name.to_str())],
								),
								Html.p(
									[Design.warningText],
									[Html.text("${candidate.strength.to_label()}: ${candidate.reason}")],
								),
							],
						),
				),
			),
		],
	)

search_form : Person.Filter -> Html.Node
search_form = |filter|
	Html.form(
		[
			Attribute.action(Route.Page.to_href(Route.Page.People)),
			Attribute.method("get"),
			Design.searchForm,
		],
		[
			Html.label([Attribute.for_("people-search"), Design.label], [Html.text("Search people")]),
			Html.input([
				Attribute.id("people-search"),
				Attribute.name("q"),
				Attribute.type("search"),
				Attribute.value(filter.to_str()),
				attribute("placeholder", "Name, email, or phone"),
				Design.searchInput,
			]),
		],
	)

people_table : List(Person) -> Html.Node
people_table = |people|
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
									header_cell("Person"),
									header_cell("Company"),
									header_cell("Primary contact"),
									header_cell("Owner"),
									header_cell("Lifecycle"),
								],
							),
						],
					),
					Html.tbody(
						[Design.tableBody],
						if people.is_empty() {
							[
								Html.tr(
									[],
									[Html.td([Design.emptyState, attribute("colspan", "5")], [Html.text("No people match this view.")])],
								),
							]
						} else {
							people.map(person_row)
						},
					),
				],
			),
		],
	)

person_row : Person -> Html.Node
person_row = |person|
	Html.tr(
		[Design.tableRow],
		[
			Html.td(
				[Design.tableCell],
				[
					Web.link(
						Route.Location.PersonDetail(person.id),
						[Design.recordLink],
						[Html.text(person.name.to_str())],
					),
				],
			),
			Html.td([Design.tableCell], [Html.text(optional(person.companyName))]),
			Html.td(
				[Design.tableCell],
				[Html.text(optional(primary_contact(person)))],
			),
			Html.td([Design.tableCell], [Html.text(person.ownerName)]),
			Html.td([Design.tableCell], [Html.text(person.lifecycle.to_label())]),
		],
	)

text_field : Str, Route.PersonInput, Str, Str -> Html.Node
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

select_field : Str, Route.PersonInput, Str, List((Str, Str)) -> Html.Node
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

header_cell : Str -> Html.Node
header_cell = |label| Html.th([Design.tableHeader], [Html.text(label)])

optional : Str -> Str
optional = |value| if value.is_empty() {
	"Not recorded"
} else {
	value
}

primary_contact : Person -> Str
primary_contact = |person| {
	email = Person.primary_value(person.emails)
	if email.is_empty() {
		Person.primary_value(person.phones)
	} else {
		email
	}
}

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
