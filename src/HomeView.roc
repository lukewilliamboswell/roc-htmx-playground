import pf.Attribute
import pf.Html

import Design
import Layout
import Route
import Session
import Web

HomeView :: [].{
	page : Session -> Html.Node
	page = |session|
		Layout.page(
			session,
			Route.Page.Home,
			[
				Html.element(
					"section",
					[Design.crmHero, attribute("aria-labelledby", "home-heading")],
					[
						Html.div(
							[Design.crmHeroCopy],
							[
								Html.p([Design.eyebrow], [Html.text("Company enquiry CRM")]),
								Html.h1(
									[Attribute.id("home-heading"), Design.heroTitle],
									[Html.text("Know who needs a follow-up next")],
								),
								Html.p(
									[Design.heroLead],
									[
										Html.text(
											"Keep company enquiries, the people behind them, and every promised next action in one shared workspace.",
										),
									],
								),
								Html.div(
									[Design.heroActions],
									[
										Web.link(
											Route.Page.CompanyNew,
											[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular)],
											[Html.text("Capture an enquiry")],
										),
										Web.link(
											Route.Page.Work,
											[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
											[Html.text("Open My Work")],
										),
									],
								),
							],
						),
					],
				),
				Html.h2([Design.featureHeading], [Html.text("One place for relationship work")]),
				Html.p(
					[Design.featureLead],
					[
						Html.text(
							"Capture only what you know, avoid accidental duplicates, and make every follow-up visible to the team.",
						),
					],
				),
				Html.div(
					[Design.featureGrid],
					[
						feature_card(
							"Companies",
							"Track business relationships, lifecycle, ownership, people, and open work.",
							Route.Page.Companies,
						),
						feature_card(
							"People",
							"Keep independent or company-linked contacts with multiple email addresses and phone numbers.",
							Route.Page.People,
						),
						feature_card(
							"My Work",
							"See overdue, due-today, and upcoming follow-ups in the workspace timezone.",
							Route.Page.Work,
						),
					],
				),
			],
		)
}

feature_card : Str, Str, Route.Page -> Html.Node
feature_card = |title, description, location|
	Web.link(
		location,
		[Design.featureCard],
		[
			Html.h3([Design.featureTitle], [Html.text(title)]),
			Html.p([Design.featureText], [Html.text(description)]),
			Html.p([Design.featureLink], [Html.text("Open →")]),
		],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
