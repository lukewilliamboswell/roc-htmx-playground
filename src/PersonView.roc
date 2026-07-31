import pf.Attribute
import pf.Html

import Activity
import Actor
import Company
import Design
import FormView
import Icon
import Layout
import Person
import Route
import Web
import WorkTask
import WorkTaskView

PersonView :: [].{
	PhoneInput : {
		label : Str,
		value : Str,
	}

	Form := {
		name : Str,
		company : Str,
		jobTitle : Str,
		owner : Str,
		lifecycle : Str,
		source : Str,
		context : Str,
		emails : List(Str),
		phones : List(PhoneInput),
		originCompany : Str,
		aiRunId : Str,
	}

	ScannerReview : {
		company : Str,
		website : Str,
		address : Str,
		confidence : I64,
		warnings : List(Str),
	}

	Scanner := [
		Hidden,
		Ready(
			{
				grantId : Str,
				message : Str,
				error : Bool,
				review : [NoReview, Review(ScannerReview)],
			},
		),
	]

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
				people_table(people, filter),
			],
		)

	detail : Actor, Person, List(WorkTask), List(Activity) -> Html.Node
	detail = |actor, person, tasks, history|
		Layout.page(
			actor.session,
			Route.Page.People,
			[
				Layout.back_link(Route.Page.People, "People"),
				Html.h1(
					[Design.pageTitle, Design.backLinkedPageTitle],
					[Html.text(person.name.to_str())],
				),
				Html.div(
					[Design.pageActions],
					[
						Web.link(
							Route.Location.PersonEdit(person.id),
							[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
							[Html.text("Edit person")],
						),
					],
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
									("Created", person.createdAt.to_str()),
									("Last changed by", person.updatedByName),
									("Last changed", person.updatedAt.to_str()),
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
					Route.TaskContext.PersonRecord(person.id),
				),
				activity_section(history),
			],
		)

	new_page : Actor, List(Company), [None, Some(Company)], Form, Str, List(Person.Match) -> Html.Node
	new_page = |actor, companies, origin, form, validation, matches|
		form_page(actor, companies, origin, None, form, validation, matches, Scanner.Hidden)

	new_page_with_scanner : Actor, List(Company), [None, Some(Company)], Form, Str, List(Person.Match), Scanner -> Html.Node
	new_page_with_scanner = |actor, companies, origin, form, validation, matches, scanner|
		form_page(actor, companies, origin, None, form, validation, matches, scanner)

	edit_page : Actor, List(Company), Person, Form, Str -> Html.Node
	edit_page = |actor, companies, person, form, validation|
		form_page(actor, companies, None, Some(person), form, validation, [], Scanner.Hidden)
}

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

form_page : Actor, List(Company), [None, Some(Company)], [None, Some(Person)], PersonView.Form, Str, List(Person.Match), PersonView.Scanner -> Html.Node
form_page = |actor, companies, origin, existing, form, validation, matches, scanner| {
	editing = match existing {
		Some(_) => True
		None => False
	}
	cancel_location = match existing {
		Some(person) => Route.Location.PersonDetail(person.id)
		None =>
			match origin {
				Some(company) => Route.Location.CompanyDetail(company.id)
				None => Route.Location.AtPage(Route.Page.People)
			}
		}
	parent_label = match existing {
		Some(person) => person.name.to_str()
		None =>
			match origin {
				Some(company) => company.name.to_str()
				None => "People"
			}
		}
	Layout.page(
		actor.session,
		if editing {
			Route.Page.People
		} else {
			Route.Page.PersonNew
		},
		[
			Layout.back_link(cancel_location, parent_label),
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
			if editing {
				Html.text("")
			} else {
				Html.p(
					[Design.lead],
					[
						Html.text(
							"Only a name is required. Add an email or phone when known to make follow-up and duplicate checking more reliable.",
						),
					],
				)
			},
			if editing {
				Html.text("")
			} else {
				scanner_panel(scanner)
			},
			if validation.is_empty() {
				Html.text("")
			} else {
				validation_summary("person-form-error", validation)
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
				[Attribute.id("person-record-form"), Design.newRecordForm],
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
					match origin {
						Some(company) =>
							Html.input([
								Attribute.type("hidden"),
								Attribute.name(Route.PersonInput.to_name(Route.PersonInput.OriginCompany)),
								Attribute.value(company.id.to_str()),
							])
						None => Html.text("")
					},
					FormView.required_text_field("Name", Route.PersonInput.Name, form.name, "Ada Lovelace"),
					FormView.text_field("Role or title", Route.PersonInput.JobTitle, form.jobTitle, "Operations lead"),
					FormView.select_field(
						"Company",
						Route.PersonInput.Company,
						form.company,
						[("", "No company")].concat(
							companies.map(|company| (company.id.to_str(), company.name.to_str())),
						),
					),
					FormView.select_field(
						"Owner",
						Route.PersonInput.Owner,
						form.owner,
						actor.workspace.members.map(|member| (member.id.to_str(), member.name.to_str())),
					),
					FormView.select_field(
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
					FormView.select_field(
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
						new_contact_fields(form)
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
					if form.aiRunId.is_empty() {
						Html.text("")
					} else {
						Html.input([
							Attribute.type("hidden"),
							Attribute.name("aiRunId"),
							Attribute.value(form.aiRunId),
						])
					},
					Html.div(
						[Design.actions],
						[
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
							Web.link(
								cancel_location,
								[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
								[Html.text("Cancel")],
							),
						],
					),
				],
			),
		],
	)
}

scanner_panel : PersonView.Scanner -> Html.Node
scanner_panel = |scanner|
	match scanner {
		PersonView.Scanner.Hidden => Html.text("")
		PersonView.Scanner.Ready(state) =>
			Html.element(
				"section",
				[Attribute.id("business-card-scanner"), Design.scannerPanel],
				[
					Html.h2([Design.sectionHeading], [Html.text("Scan a business card")]),
					Html.p(
						[Design.contentSectionText],
						[
							Html.text(
								"Take a photo or choose an image. It is sent to the configured AI provider for extraction and is not stored by the CRM.",
							),
						],
					),
					if state.message.is_empty() {
						Html.text("")
					} else {
						Html.p(
							if state.error {
								[Design.scannerError, attribute("role", "alert")]
							} else {
								[Design.scannerSuccess, attribute("role", "status")]
							},
							[Html.text(state.message)],
						)
					},
					scanner_review(state.review),
					Html.div(
						[
							Attribute.id("business-card-client-status"),
							attribute("role", "status"),
							attribute("aria-live", "polite"),
							Design.scannerClientStatus,
						],
						[],
					),
					Web.post_form(
						Route.PostAction.ScanBusinessCard,
						[
							Design.scannerForm,
							attribute("enctype", "multipart/form-data"),
							attribute("hx-post", Route.PostAction.to_post_url(Route.PostAction.ScanBusinessCard)),
							attribute("hx-encoding", "multipart/form-data"),
							attribute("hx-include", "#person-record-form"),
							attribute("hx-target", "main"),
							attribute("hx-select", "main"),
							attribute("hx-swap", "outerHTML"),
							attribute("hx-status:4xx", "target:main select:main swap:outerHTML"),
							attribute("hx-status:5xx", "target:main select:main swap:outerHTML"),
							attribute("data-business-card-form", ""),
							attribute("data-busy-target", "business-card-scanner"),
						],
						[
							Html.input([
								Attribute.type("hidden"),
								Attribute.name("scanGrant"),
								Attribute.value(state.grantId),
							]),
							Html.input([
								Attribute.type("hidden"),
								Attribute.name("imagePrepared"),
								Attribute.value("no"),
								attribute("data-business-card-prepared", ""),
							]),
							Html.div(
								[Design.field],
								[
									Html.label(
										[Attribute.for_("cardImage"), Design.label],
										[Html.text("Business card image")],
									),
									Html.input([
										Attribute.id("cardImage"),
										Attribute.name("cardImage"),
										attribute("type", "file"),
										attribute("accept", "image/*"),
										attribute("capture", "environment"),
										attribute("required", ""),
										attribute("data-business-card-input", ""),
										Design.input,
									]),
									Html.p(
										[Design.fieldHelp],
										[Html.text("The browser removes image metadata and reduces large photos before upload.")],
									),
									Html.element(
										"img",
										[
											Attribute.id("business-card-preview"),
											attribute("alt", "Preview of the selected business card"),
											attribute("hidden", ""),
											attribute("data-business-card-preview", ""),
											Design.scannerPreview,
										],
										[],
									),
								],
							),
							Html.button(
								[
									Attribute.type("submit"),
									Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular),
									attribute("data-business-card-submit", ""),
								],
								[Html.text("Extract contact details")],
							),
						],
					),
				],
			)
		}

scanner_review : [NoReview, Review(PersonView.ScannerReview)] -> Html.Node
scanner_review = |review|
	match review {
		NoReview => Html.text("")
		Review(value) =>
			Html.div(
				if value.confidence < 650 {
					[Design.scannerReviewWarning]
				} else {
					[Design.scannerReview]
				},
				[
					Html.p(
						[Design.scannerReviewHeading],
						[Html.text("Extraction confidence: ${(value.confidence // 10).to_str()}%")],
					),
					review_line("Company on card", value.company),
					review_line("Website", value.website),
					review_line("Address", value.address),
					if value.warnings.is_empty() {
						Html.text("")
					} else {
						Html.div(
							[],
							[
								Html.p([Design.label], [Html.text("Warnings")]),
								Html.ul(
									[Design.scannerWarnings],
									value.warnings.map(|warning| Html.li([], [Html.text(warning)])),
								),
							],
						)
					},
				],
			)
		}

review_line : Str, Str -> Html.Node
review_line = |label, value|
	if value.is_empty() {
		Html.text("")
	} else {
		Html.p(
			[Design.scannerReviewLine],
			[Html.element("strong", [], [Html.text("${label}: ")]), Html.text(value)],
		)
	}

new_contact_fields : PersonView.Form -> Html.Node
new_contact_fields = |form|
	Html.div(
		[],
		[
			FormView.text_field(
				"Email",
				Route.PersonInput.Email,
				list_value(form.emails, 0),
				"ada@example.com",
			),
			named_phone_field("Phone", "phone", "phoneType", "phone", phone_value(form.phones, 0)),
			Html.element(
				"details",
				[Design.helpDisclosure],
				[
					Html.element(
						"summary",
						[Design.helpSummary],
						[Html.text("Additional email addresses and phone numbers")],
					),
					Html.div(
						[Design.helpList],
						List.fold(
							[1, 2, 3, 4],
							[],
							|fields, index| {
								number = (index + 1).to_str()
								fields.concat([
									named_text_field(
										"Email ${number}",
										"email${number}",
										"person-email-${number}",
										list_value(form.emails, index),
										"",
										"email",
									),
									named_phone_field(
										"Phone ${number}",
										"phone${number}",
										"phoneType${number}",
										"person-phone-${number}",
										phone_value(form.phones, index),
									),
								])
							},
						),
					),
				],
			),
		],
	)

named_phone_field : Str, Str, Str, Str, PersonView.PhoneInput -> Html.Node
named_phone_field = |label, name, type_name, id, phone|
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(id), Design.label], [Html.text(label)]),
			Html.div(
				[Design.contactInputRow],
				[
					Html.select(
						[
							Attribute.id("${id}-type"),
							Attribute.name(type_name),
							Design.contactTypeSelect,
						],
						["Work", "Mobile", "Fax", "Home", "Other"].map(
							|option|
								Html.option(
									if option == phone.label {
										[Attribute.value(option), attribute("selected", "")]
									} else {
										[Attribute.value(option)]
									},
									[Html.text(option)],
								),
						),
					),
					Html.input([
						Attribute.id(id),
						Attribute.name(name),
						Attribute.value(phone.value),
						attribute("type", "tel"),
						attribute("placeholder", "+61 3 9000 0000"),
						Design.input,
					]),
				],
			),
		],
	)

named_text_field : Str, Str, Str, Str, Str, Str -> Html.Node
named_text_field = |label, name, id, value, placeholder, kind|
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(id), Design.label], [Html.text(label)]),
			Html.input([
				Attribute.id(id),
				Attribute.name(name),
				Attribute.value(value),
				attribute("type", kind),
				attribute("placeholder", placeholder),
				Design.input,
			]),
		],
	)

list_value : List(Str), U64 -> Str
list_value = |values, index| values.get(index) ?? ""

phone_value : List(PersonView.PhoneInput), U64 -> PersonView.PhoneInput
phone_value = |values, index|
	values.get(index) ?? { label: "Work", value: "" }

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
	field_prefix = match kind {
		Email => "person-email"
		Phone => "person-phone"
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
									contact_actions(person, kind, method),
								],
							),
					)
				},
			),
			Web.post_form(
				action,
				[Design.inlineForm],
				[
					FormView.text_field_with_id(
						"Label",
						Route.PersonInput.Label,
						"${field_prefix}-label",
						"Work",
						"Work",
					),
					FormView.required_text_field_with_id(
						"Value",
						Route.PersonInput.Value,
						"${field_prefix}-value",
						"",
						"",
					),
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
							Design.inlineFormAction,
						],
						[Html.text("Add")],
					),
				],
			),
		],
	)
}

contact_actions : Person, [Email, Phone], Person.ContactMethod -> Html.Node
contact_actions = |person, kind, method| {
	promote = if method.primary {
		[]
	} else {
		[
			Web.post_form(
				match kind {
					Email => Route.PostAction.PromotePersonEmail(person.id, method.id)
					Phone => Route.PostAction.PromotePersonPhone(person.id, method.id)
				},
				[],
				[
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Small),
						],
						[Html.text("Make primary")],
					),
				],
			),
		]
	}
	remove = Web.post_form(
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
	)
	Html.div([Design.contactActions], promote.append(remove))
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
									[Html.text("${candidate.strength.to_label()}: ${candidate.reason.to_label()}")],
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
			attribute("role", "search"),
			Design.searchForm,
		],
		[
			Html.label([Attribute.for_("people-search"), Design.label], [Html.text("Search people")]),
			Html.div(
				[Design.searchControls],
				[
					Html.input([
						Attribute.id("people-search"),
						Attribute.name("q"),
						Attribute.type("search"),
						Attribute.value(filter.to_str()),
						attribute("placeholder", "Name, email, or phone"),
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

people_table : List(Person), Person.Filter -> Html.Node
people_table = |people, filter|
	if people.is_empty() {
		people_empty_state(filter)
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
										header_cell("Person"),
										header_cell("Company"),
										header_cell("Primary contact"),
										header_cell("Owner"),
										header_cell("Lifecycle"),
									],
								),
							],
						),
						Html.tbody([Design.tableBody], people.map(person_row)),
					],
				),
			],
		)
	}

people_empty_state : Person.Filter -> Html.Node
people_empty_state = |filter|
	Html.div(
		[Design.emptyStatePanel],
		if filter.to_str().is_empty() {
			[
				Html.span([Design.emptyStateIcon], [Icon.users(Design.emptyStateIconGlyph)]),
				Html.p(
					[Design.emptyStateText],
					[Html.text("No people have been recorded yet. Use New person to capture the first relationship.")],
				),
			]
		} else {
			[
				Html.span([Design.emptyStateIcon], [Icon.searchOff(Design.emptyStateIconGlyph)]),
				Html.p(
					[Design.emptyStateText],
					[Html.text("No people match “${filter.to_str()}”. Clear the search to see every person.")],
				),
				Html.div(
					[Design.emptyStateActions],
					[
						Web.link(
							Route.Page.People,
							[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
							[Html.text("Clear search")],
						),
					],
				),
			]
		},
	)

person_row : Person -> Html.Node
person_row = |person|
	Html.tr(
		[Design.tableRow],
		[
			Html.td(
				[Design.tableCellPrimary],
				[
					Web.link(
						Route.Location.PersonDetail(person.id),
						[Design.recordCardLink],
						[
							Html.text(person.name.to_str()),
							Icon.chevronRight(Design.recordCardChevron),
						],
					),
				],
			),
			labelled_cell("Company", Html.text(optional(person.companyName))),
			labelled_cell("Contact", Html.text(optional(primary_contact(person)))),
			labelled_cell("Owner", Html.text(person.ownerName)),
			labelled_cell("Lifecycle", Html.text(person.lifecycle.to_label())),
		],
	)

## Below `sm` the header row is hidden, so each cell carries its own column
## name; from `sm` up the label is hidden and the header row names the column.
labelled_cell : Str, Html.Node -> Html.Node
labelled_cell = |label, value|
	Html.td(
		[Design.tableCell],
		[
			Html.span([Design.cellLabel], [Html.text(label)]),
			value,
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
