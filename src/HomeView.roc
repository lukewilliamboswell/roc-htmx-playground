import pf.Attribute
import pf.Html

import Design
import Icon
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
					[Design.hero, attribute("aria-labelledby", "home-heading")],
					[
						Html.div(
							[Design.heroCopy],
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
						hero_visual(),
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
							Icon.building,
							"Companies",
							"Track business relationships, lifecycle, ownership, people, and open work.",
							Route.Page.Companies,
						),
						feature_card(
							Icon.users,
							"People",
							"Keep independent or company-linked contacts with multiple email addresses and phone numbers.",
							Route.Page.People,
						),
						feature_card(
							Icon.checkCircle,
							"My Work",
							"See overdue, due-today, and upcoming follow-ups in the workspace timezone.",
							Route.Page.Work,
						),
					],
				),
			],
		)
}

## The hero photograph is decorative, so it carries an empty alt text and the
## heading alone describes the page. Widths are declared so the browser can
## pick a variant before layout, and intrinsic dimensions are supplied so the
## surrounding copy never shifts once the image arrives.
hero_visual : () -> Html.Node
hero_visual = ||
	Html.div(
		[Design.heroVisual],
		[
			Html.void_element(
				"img",
				[
					Web.asset_src(Route.Asset.Hero(Route.HeroPhoto.Width960)),
					attribute("srcset", hero_srcset()),
					attribute("sizes", "(min-width: 1024px) 50vw, 100vw"),
					attribute("alt", ""),
					Attribute.width("960"),
					Attribute.height("720"),
					attribute("decoding", "async"),
					Design.heroImage,
				],
			),
			Html.p(
				[Design.photoCredit],
				[
					Html.text("Photo: "),
					Html.a(
						[
							Attribute.href("https://unsplash.com/photos/an-open-notebook-and-pens-on-a-desk-hBdaqrr5Z3k"),
							Attribute.rel("noopener noreferrer"),
							Design.photoCreditLink,
						],
						[Html.text("Kelly Sikkema")],
					),
				],
			),
		],
	)

hero_srcset : () -> Str
hero_srcset = ||
	Str.join_with(
		Route.HeroPhoto.responsive_set.map(
			|photo|
				"${Route.Asset.to_src(Route.Asset.Hero(photo))} ${Route.HeroPhoto.to_width(photo)}w",
		),
		", ",
	)

feature_card : (Attribute.Attribute -> Html.Node), Str, Str, Route.Page -> Html.Node
feature_card = |icon, title, description, location|
	Web.link(
		location,
		[Design.featureCard],
		[
			Html.span([Design.featureIconFrame], [icon(Design.featureIcon)]),
			Html.h3([Design.featureTitle], [Html.text(title)]),
			Html.p([Design.featureText], [Html.text(description)]),
			Html.p([Design.featureLink], [Html.text("Open →")]),
		],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
