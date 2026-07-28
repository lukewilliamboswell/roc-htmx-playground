import pf.Attribute
import pf.Html

import Design
import Layout
import Route
import Session
import Web

AuthView :: [].{
	login : Session, Str, Str -> Html.Node
	login = |session, username, error|
		Layout.page(
			session,
			Route.Page.Login,
			[
				Html.h1([Design.pageTitle], [Html.text("Login")]),
				error_message(error),
				Web.post_form(
					Route.PostAction.Login,
					[Design.form],
					[
						text_input("Username", Route.AuthInput.Username, "text", username),
						Html.button(
							[
								Attribute.type("submit"),
								Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular),
							],
							[Html.text("Login")],
						),
					],
				),
			],
		)

	register : Session, Str, Str, Str -> Html.Node
	register = |session, username, email, error|
		Layout.page(
			session,
			Route.Page.Register,
			[
				Html.h1([Design.pageTitle], [Html.text("Register")]),
				error_message(error),
				Web.post_form(
					Route.PostAction.Register,
					[Design.form],
					[
						text_input("Username", Route.AuthInput.Username, "text", username),
						text_input("Email", Route.AuthInput.Email, "email", email),
						Html.button(
							[
								Attribute.type("submit"),
								Design.button(Design.ButtonTone.Primary, Design.ButtonSize.Regular),
							],
							[Html.text("Register")],
						),
					],
				),
			],
		)
}

text_input : Str, Route.AuthInput, Str, Str -> Html.Node
text_input = |label, input, kind, value| {
	name = input.to_name()
	Html.div(
		[Design.field],
		[
			Html.label([Attribute.for_(name), Design.label], [Html.text(label)]),
			Html.input([
				Attribute.id(name),
				Attribute.name(name),
				Attribute.type(kind),
				Attribute.value(value),
				Design.input,
				attribute("required", ""),
			]),
		],
	)
}

error_message : Str -> Html.Node
error_message = |message|
	if message.is_empty() {
		Html.div([], [])
	} else {
		Html.div([Design.validation], [Html.text(message)])
	}

attribute : Str, Str -> Attribute.Attribute
attribute = |name, value| Attribute.attribute(name, value)
