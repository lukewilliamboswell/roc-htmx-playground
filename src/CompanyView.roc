import pf.Attribute
import pf.Html

import Actor
import Company
import Design
import Layout
import Route
import Web

CompanyView :: [].{
	PageModel := {
		actor : Actor,
		companies : List(Company),
		filter : Company.Filter,
	}

	Form := {
		name : Str,
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
					[attribute("class", "flex flex-wrap items-center justify-between gap-4")],
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
				company_table(model.companies),
			],
		)

	new_page : Actor, Form, Str -> Html.Node
	new_page = |actor, form, validation|
		company_form_page(actor, form, validation, [])

	duplicate_page : Actor, Form, List(Company.Match) -> Html.Node
	duplicate_page = |actor, form, matches|
		company_form_page(actor, form, "", matches)

	detail : Actor, Company -> Html.Node
	detail = |actor, company|
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
					[Design.pageTitle, attribute("class", "mt-4")],
					[Html.text(company.name.to_str())],
				),
				Html.div(
					[attribute("class", "grid gap-6 lg:grid-cols-3")],
					[
						Html.element(
							"section",
							[attribute("class", "rounded-xl border border-slate-200 bg-white p-5 shadow-sm lg:col-span-2")],
							[
								Html.h2([attribute("class", "text-lg font-semibold")], [Html.text("Relationship")]),
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
							[attribute("class", "rounded-xl border border-slate-200 bg-white p-5 shadow-sm")],
							[
								Html.h2([attribute("class", "text-lg font-semibold")], [Html.text("Record")]),
								detail_list([
									("Created by", company.createdByName),
									("Created", company.createdAt),
									("Last changed by", company.updatedByName),
									("Last changed", company.updatedAt),
								]),
							],
						),
					],
				),
				placeholder_section(
					"People",
					"Associated people will appear here in the next seam.",
				),
				placeholder_section(
					"Open tasks",
					"Scheduled follow-up will appear here in the task seam.",
				),
				placeholder_section(
					"History",
					"Owner and lifecycle changes will appear here once editing is enabled.",
				),
			],
		)
}

company_form_page : Actor, CompanyView.Form, Str, List(Company.Match) -> Html.Node
company_form_page = |actor, form, validation, matches|
	Layout.page(
		actor.session,
		Route.Page.CompanyNew,
		[
			Web.link(Route.Page.Companies, [Design.navLink], [Html.text("← Companies")]),
			Html.h1([Design.pageTitle, attribute("class", "mt-4")], [Html.text("New company")]),
			Html.p(
				[Design.lead],
				[Html.text("Capture the relationship now; only the company name is required.")],
			),
			if validation.is_empty() {
				Html.text("")
			} else {
				Html.p([Design.validation], [Html.text(validation)])
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
				[attribute("class", "mt-6 max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm")],
				[
					text_field("Company name", Route.CompanyInput.Name, form.name, "Acme Studio"),
					text_field("Website", Route.CompanyInput.Website, form.website, "https://acme.example"),
					text_field("Phone", Route.CompanyInput.Phone, form.phone, "+61 3 9000 0000"),
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
		[attribute("class", "mt-6 rounded-xl border border-amber-300 bg-amber-50 p-5")],
		[
			Html.h2([attribute("class", "text-lg font-semibold text-amber-950")], [Html.text("Check possible duplicates")]),
			Html.p(
				[attribute("class", "mt-1 text-sm text-amber-900")],
				[Html.text("Review these existing companies before creating another record.")],
			),
			Html.ul(
				[attribute("class", "mt-4 space-y-3")],
				matches.map(
					|candidate|
						Html.li(
							[attribute("class", "rounded-lg bg-white p-3")],
							[
								Web.link(
									Route.Location.CompanyDetail(candidate.company.id),
									[attribute("class", "font-semibold text-blue-700 hover:underline")],
									[Html.text(candidate.company.name.to_str())],
								),
								Html.p(
									[attribute("class", "text-sm text-slate-600")],
									[Html.text("${candidate.strength.to_label()}: ${candidate.reason}")],
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
			attribute("class", "mt-6"),
		],
		[
			Html.label(
				[Attribute.for_("company-search"), Design.label],
				[Html.text("Search companies")],
			),
			Html.input([
				Attribute.id("company-search"),
				Attribute.name("q"),
				Attribute.type("search"),
				Attribute.value(filter.to_str()),
				attribute("placeholder", "Name, website, or phone"),
				Design.searchInput,
			]),
		],
	)

company_table : List(Company) -> Html.Node
company_table = |companies|
	if companies.is_empty() {
		Html.div(
			[Design.emptyState],
			[Html.text("No companies match this view.")],
		)
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
						[attribute("class", "font-semibold text-blue-700 hover:underline")],
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
			Html.td([Design.tableCell], [Html.text(company.updatedAt)]),
		],
	)

header_cell : Str -> Html.Node
header_cell = |label|
	Html.th([Design.tableHeader], [Html.text(label)])

detail_list : List((Str, Str)) -> Html.Node
detail_list = |items|
	Html.element(
		"dl",
		[attribute("class", "mt-4 grid gap-4 sm:grid-cols-2")],
		items.map(
			|(label, value)|
				Html.div(
					[],
					[
						Html.element("dt", [attribute("class", "text-sm font-medium text-slate-500")], [Html.text(label)]),
						Html.element("dd", [attribute("class", "mt-1 text-sm text-slate-900")], [Html.text(value)]),
					],
				),
		),
	)

placeholder_section : Str, Str -> Html.Node
placeholder_section = |title, message|
	Html.element(
		"section",
		[attribute("class", "mt-6 rounded-xl border border-slate-200 bg-white p-5 shadow-sm")],
		[
			Html.h2([attribute("class", "text-lg font-semibold")], [Html.text(title)]),
			Html.p([attribute("class", "mt-2 text-sm text-slate-600")], [Html.text(message)]),
		],
	)

display_optional : Str -> Str
display_optional = |value|
	if value.is_empty() {
		"Not recorded"
	} else {
		value
	}

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
