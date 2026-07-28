import pf.Attribute
import pf.Html

import Design
import Layout
import Route
import Session
import Web

ErrorView :: [].{
	unauthorized : Session -> Html.Node
	unauthorized = |session|
		document(
			session,
			Unauthorized,
			"Unauthorized",
			"You need to be signed in to view this page.",
			[
				Web.link(
					Route.Page.Login,
					[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular)],
					[Html.text("Login")],
				),
				Web.link(
					Route.Page.Register,
					[Design.button(Design.ButtonTone.Outline, Design.ButtonSize.Regular)],
					[Html.text("Register")],
				),
			],
		)

	not_found : Session -> Html.Node
	not_found = |session|
		document(
			session,
			NotFound,
			"Page not found",
			"We could not find the page you were looking for.",
			[home_link()],
		)

	forbidden : Session -> Html.Node
	forbidden = |session|
		document(
			session,
			Forbidden,
			"Request forbidden",
			"The request did not pass this site's security checks.",
			[home_link()],
		)

	bad_request : Session, Str -> Html.Node
	bad_request = |session, message|
		document(
			session,
			BadRequest,
			"That request could not be processed",
			message,
			[home_link()],
		)

	server_error : Session -> Html.Node
	server_error = |session|
		document(
			session,
			ServerError,
			"Something went wrong",
			"The server hit an unexpected error. Please try again.",
			[home_link()],
		)
}

ErrorPage := [Unauthorized, Forbidden, NotFound, BadRequest, ServerError].{
	title : ErrorPage -> Str
	title = |page|
		match page {
			Unauthorized => "Unauthorized"
			Forbidden => "Forbidden"
			NotFound => "Not Found"
			BadRequest => "Bad Request"
			ServerError => "Server Error"
		}
}

document : Session, ErrorPage, Str, Str, List(Html.Node) -> Html.Node
document = |session, page_identity, heading, message, actions|
	Layout.document(
		session,
		page_identity,
		[],
		[
			Html.element(
				"section",
				[
					Attribute.id(Web.ErrorTarget.to_id(Web.ErrorTarget.RequestError)),
					attribute("role", "alert"),
				],
				[
					Html.h1([Design.pageTitle], [Html.text(heading)]),
					Html.p([Design.lead], [Html.text(message)]),
				],
			),
			Html.div([Design.actions], actions),
		],
	)

home_link : () -> Html.Node
home_link = ||
	Web.link(
		Route.Page.Home,
		[Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular)],
		[Html.text("Back to home")],
	)

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
