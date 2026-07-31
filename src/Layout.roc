import pf.Attribute
import pf.Html

import Design
import Icon
import Route
import Session
import Web

## Shared document chrome for full HTML pages.
##
## `page` is the convenient entry point for navigable application pages.
## `document` is intentionally generic so non-routable documents, such as
## error pages, can still provide a typed title through static dispatch.
Layout := [].{

	## The primary destination a document belongs to.
	##
	## Both navigation surfaces mark the current section, and a document that
	## belongs to none of them — the home page, or an error — marks nothing.
	## Deriving this once keeps the desktop links and the mobile tab bar from
	## disagreeing about where the reader is.
	Section := [Companies, People, Work, Unsectioned].{
		is_eq : _
	}

	document : Session, Section, page, List(Route.Asset), List(Html.Node) -> Html.Node
		where [
			page.title : page -> Str,
		]
	document = |session, section, page_identity, scripts, children|
		Html.html(
			[attribute("lang", "en")],
			[
				Html.head(
					[],
					[
						Html.meta([attribute("charset", "utf-8")]),
						Html.meta([Attribute.name("viewport"), attribute("content", "width=device-width, initial-scale=1")]),
						Html.meta([
							Attribute.name("description"),
							attribute(
								"content",
								"A focused CRM for company enquiries, people, and accountable follow-up.",
							),
						]),

						## Tint the mobile browser chrome to match the sticky header.
						Html.meta([Attribute.name("theme-color"), attribute("content", "#ffffff")]),
						Html.title([], [Html.text(page_identity.title())]),
						Html.link([
							Attribute.rel("icon"),
							Web.asset_href(Route.Asset.AppIcon),
							attribute("type", "image/svg+xml"),
						]),
						Html.link([
							Attribute.rel("stylesheet"),
							Web.asset_href(Route.Asset.Stylesheet),
						]),
					].concat(scripts.map(script)),
				),
				Html.body(
					[Design.body],
					[
						navbar(session, section),
						Html.main([Design.page], children),
						tab_bar(section),
					],
				),
			],
		)

	## A return affordance rendered above a detail or form heading.
	back_link : location, Str -> Html.Node
		where [
			location.to_href : location -> Str,
		]
	back_link = |location, label|
		Web.link(
			location,
			[Design.backLink],
			[Icon.arrowLeft(Design.backLinkIcon), Html.text(label)],
		)

	page : Session, Route.Page, List(Html.Node) -> Html.Node
	page = |session, page_identity, children| {
		scripts = match page_identity {
			Route.Page.Companies => [Route.Asset.Htmx, Route.Asset.Interactions]
			Route.Page.People => [Route.Asset.Htmx, Route.Asset.Interactions]
			_ => []
		}

		document(session, section_of(page_identity), page_identity, scripts, children)
	}
}

## A form belongs to the section it creates records in, so the reader keeps
## their place while capturing one.
section_of : Route.Page -> Layout.Section
section_of = |page|
	match page {
		Route.Page.Home => Layout.Section.Unsectioned
		Route.Page.Companies => Layout.Section.Companies
		Route.Page.CompanyNew => Layout.Section.Companies
		Route.Page.People => Layout.Section.People
		Route.Page.PersonNew => Layout.Section.People
		Route.Page.Work => Layout.Section.Work
	}

script : Route.Asset -> Html.Node
script = |asset|
	Html.element(
		"script",
		[
			Web.asset_src(asset),
			attribute("defer", ""),
		],
		[],
	)

navbar : Session, Layout.Section -> Html.Node
navbar = |session, section|
	Html.element(
		"header",
		[Design.nav],
		[
			Html.div(
				[Design.navInner],
				[
					Web.link(
						Route.Page.Home,
						[Design.brand],
						[
							Html.span([Design.brandMark], [Icon.listChecks(Design.brandMarkIcon)]),
							Html.text("Enquiry CRM"),
						],
					),
					Html.nav(
						[attribute("aria-label", "Primary")],
						[
							Html.ul(
								[Design.navLinks],
								destinations.map(|destination| nav_item(destination, section)),
							),
						],
					),
					auth_controls(session),
				],
			),
		],
	)

## Thumb-reachable navigation for small screens.
##
## This repeats the header's destinations, but only one of the two is ever
## rendered: the header links are `display: none` below `sm` and this bar is
## `display: none` from `sm` up, which removes the inactive one from the
## accessibility tree as well as from view. Marking either `aria-hidden`
## instead would leave focusable links that assistive technology is told to
## ignore, so the visibility rule is what keeps them from being announced
## twice.
tab_bar : Layout.Section -> Html.Node
tab_bar = |section|
	Html.nav(
		[Design.tabBar, attribute("aria-label", "Primary, compact")],
		[
			Html.div(
				[Design.tabBarInner],
				destinations.map(|destination| tab_item(destination, section)),
			),
		],
	)

Destination : {
	label : Str,
	location : Route.Page,
	section : Layout.Section,
	icon : Attribute.Attribute -> Html.Node,
}

destinations : List(Destination)
destinations = [
	{
		label: "Companies",
		location: Route.Page.Companies,
		section: Layout.Section.Companies,
		icon: Icon.building,
	},
	{
		label: "People",
		location: Route.Page.People,
		section: Layout.Section.People,
		icon: Icon.users,
	},
	{
		label: "My Work",
		location: Route.Page.Work,
		section: Layout.Section.Work,
		icon: Icon.checkCircle,
	},
]

nav_item : Destination, Layout.Section -> Html.Node
nav_item = |destination, section|
	Html.li(
		[],
		[
			Web.link(
				destination.location,
				if destination.section == section {
					[Design.navLinkActive, attribute("aria-current", "page")]
				} else {
					[Design.navLink]
				},
				[Html.text(destination.label)],
			),
		],
	)

tab_item : Destination, Layout.Section -> Html.Node
tab_item = |destination, section| {
	render_icon = destination.icon

	Web.link(
		destination.location,
		if destination.section == section {
			[Design.tabLinkActive]
		} else {
			[Design.tabLink]
		},
		[
			render_icon(Design.tabIcon),
			Html.span([], [Html.text(destination.label)]),
		],
	)
}

auth_controls : Session -> Html.Node
auth_controls = |session|
	match session.user {
		Session.Auth.Guest =>
			Html.div(
				[Design.auth],
				[],
			)
		Session.Auth.Trusted(member, source) =>
			Html.div(
				[Design.auth],
				[Html.span([Design.userName], [Html.text(member.name.to_str())])].concat(
					if source == Session.IdentitySource.Development {
						[Html.span([Design.devBadge], [Html.text("Dev mode")])]
					} else {
						[]
					},
				),
			)
		}

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
