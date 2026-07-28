import pf.Attribute
import pf.Html

import Design
import Layout
import Route
import Session
import User

UserView :: [].{
	page : Session, List(User) -> Html.Node
	page = |session, users|
		Layout.page(
			session,
			Route.Page.Users,
			[
				Html.h1([Design.pageTitle], [Html.text("Users")]),
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
												header_cell("ID"),
												header_cell("Name"),
												header_cell("Email"),
											],
										),
									],
								),
								Html.tbody(
									[Design.tableBody],
									if users.is_empty() {
										[empty_row("3", "No users have registered yet.")]
									} else {
										users.map(user_row)
									},
								),
							],
						),
					],
				),
			],
		)
}

user_row : User -> Html.Node
user_row = |user|
	Html.tr(
		[Design.tableRow],
		[
			table_cell(user.id.to_str()),
			table_cell(user.name.to_str()),
			table_cell(user.email.to_str()),
		],
	)

header_cell : Str -> Html.Node
header_cell = |label| Html.th([Design.tableHeader], [Html.text(label)])

table_cell : Str -> Html.Node
table_cell = |value| Html.td([Design.tableCell], [Html.text(value)])

empty_row : Str, Str -> Html.Node
empty_row = |columns, message|
	Html.tr(
		[],
		[Html.td([Design.emptyState, attribute("colspan", columns)], [Html.text(message)])],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
