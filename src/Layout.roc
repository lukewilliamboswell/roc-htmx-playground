import pf.Attribute
import pf.Html

import Design
import Route
import Session
import Web

## Shared document chrome for full HTML pages.
##
## `page` is the convenient entry point for navigable application pages.
## `document` is intentionally generic so non-routable documents, such as
## error pages, can still provide a typed title through static dispatch.
Layout := [].{
	document : Session, page, List(Route.Asset), List(Html.Node) -> Html.Node
		where [
			page.title : page -> Str,
		]
	document = |session, page_identity, scripts, children|
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
						Html.title([], [Html.text(page_identity.title())]),
						Html.link([
							Attribute.rel("icon"),
							Web.asset_href(Route.Asset.TasksIcon),
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
						navbar(session),
						Html.main([Design.page], children),
					],
				),
			],
		)

	page : Session, Route.Page, List(Html.Node) -> Html.Node
	page = |session, page_identity, children| {
		scripts = match page_identity {
			Route.Page.Todos => [Route.Asset.Htmx]
			Route.Page.BigTasks => [Route.Asset.Htmx]
			Route.Page.Companies => [Route.Asset.Htmx]
			Route.Page.People => [Route.Asset.Htmx]
			_ => []
		}

		document(session, page_identity, scripts, children)
	}
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

navbar : Session -> Html.Node
navbar = |session|
	Html.nav(
		[Design.nav],
		[
			Html.div(
				[Design.navInner],
				[
					Web.link(Route.Page.Home, [Design.brand], [Html.text("Enquiry CRM")]),
					Html.ul(
						[Design.navLinks],
						[
							nav_item("Companies", Route.Page.Companies),
							nav_item("People", Route.Page.People),
							nav_item("My Work", Route.Page.Work),
						],
					),
					auth_controls(session),
				],
			),
		],
	)

nav_item : Str, Route.Page -> Html.Node
nav_item = |label, location|
	Html.li(
		[],
		[Web.link(location, [Design.navLink], [Html.text(label)])],
	)

auth_controls : Session -> Html.Node
auth_controls = |session|
	match session.user {
		Session.Auth.Guest =>
			Html.div(
				[Design.auth],
				[
					Web.link(
						Route.Page.Login,
						[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Small)],
						[Html.text("Login")],
					),
					Web.link(
						Route.Page.Register,
						[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Small)],
						[Html.text("Register")],
					),
				],
			)
		Session.Auth.LoggedIn(member) =>
			Web.post_form(
				Route.PostAction.Logout,
				[Design.auth],
				[
					Html.span([Design.userName], [Html.text(member.name.to_str())]),
					Html.button(
						[
							Attribute.type("submit"),
							Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Small),
						],
						[Html.text("Logout")],
					),
				],
			)
		}

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
