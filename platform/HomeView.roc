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
										Web.link(
											Route.Page.Todos,
											[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular)],
											[Html.text("Explore tasks")],
										),
										Web.link(
											Route.Page.TodoTree,
											[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
											[Html.text("View hierarchy")],
										),
									],
								),
							],
						),
						Html.element(
							"figure",
							[Design.heroVisual],
							[
								hero_image(),
								Html.element(
									"figcaption",
									[Design.photoCredit],
									[
										Html.text("Photo by "),
										external_link("Kelly Sikkema", "https://unsplash.com/@kellysikkema"),
										Html.text(" on "),
										external_link(
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
						feature_card(
							"Tasks",
							"Create, filter, update, and delete work with focused htmx swaps.",
							Route.Page.Todos,
							Route.Asset.TasksIcon,
						),
						feature_card(
							"Users",
							"See registered accounts and the shared session-aware navigation.",
							Route.Page.Users,
							Route.Asset.UsersIcon,
						),
						feature_card(
							"Hierarchy",
							"Render nested task relationships as an accessible server-built tree.",
							Route.Page.TodoTree,
							Route.Asset.TreeIcon,
						),
						feature_card(
							"BigTask",
							"Exercise sorting, pagination, inline editing, and CSV download.",
							Route.Page.BigTasks,
							Route.Asset.TableIcon,
						),
					],
				),
			],
		)
}

feature_card : Str, Str, Route.Page, Route.Asset -> Html.Node
feature_card = |title, description, location, icon|
	Web.link(
		location,
		[Design.featureCard],
		[
			Html.div(
				[Design.featureIconFrame],
				[decorative_image(icon, Design.featureIcon, "24", "24")],
			),
			Html.h3([Design.featureTitle], [Html.text(title)]),
			Html.p([Design.featureText], [Html.text(description)]),
			Html.p([Design.featureLink], [Html.text("Open demo →")]),
		],
	)

hero_image : () -> Html.Node
hero_image = ||
	Html.element(
		"img",
		[
			Web.asset_src(Route.Asset.PlanningDesk),
			attribute(
				"srcset",
				"${asset_path(Route.Asset.PlanningDesk480)} 480w, ${asset_path(Route.Asset.PlanningDesk640)} 640w, ${asset_path(Route.Asset.PlanningDesk720)} 720w, ${asset_path(Route.Asset.PlanningDesk960)} 960w, ${asset_path(Route.Asset.PlanningDesk)} 1600w",
			),
			attribute(
				"sizes",
				"(min-width: 1280px) 640px, (min-width: 1024px) 50vw, calc(100vw - 2rem)",
			),
			attribute("alt", "An open notebook beside pens and a small plant on a desk"),
			attribute("width", "1600"),
			attribute("height", "1067"),
			attribute("decoding", "async"),
			attribute("fetchpriority", "high"),
			Design.heroImage,
		],
		[],
	)

asset_path : Route.Asset -> Str
asset_path = |asset| asset.to_src()

decorative_image : Route.Asset, Attribute.Attribute, Str, Str -> Html.Node
decorative_image = |asset, style, width, height|
	Html.element(
		"img",
		[
			Web.asset_src(asset),
			attribute("alt", ""),
			attribute("aria-hidden", "true"),
			attribute("width", width),
			attribute("height", height),
			style,
		],
		[],
	)

external_link : Str, Str -> Html.Node
external_link = |label, href|
	Html.a(
		[
			Attribute.href(href),
			attribute("target", "_blank"),
			attribute("rel", "noopener noreferrer"),
			Design.photoCreditLink,
		],
		[Html.text(label)],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
