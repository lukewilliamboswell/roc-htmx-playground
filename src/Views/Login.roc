module [page]

import html.Html exposing [form, h5,  button, a, input, div, text, label]
import html.Attribute exposing [attribute, id, href, name, action, method, class,  for]
import Models.Session exposing [Session]
import Views.Layout exposing [layout]
import Models.NavLinks

page :
    {
        session : Session {},
        user : [Fresh, UserNotProvided, UserNotFound Str],
    }
    -> Html.Node
page = \{ session, user } ->

    (usernameInputClass, usernameValidationClass, usernameValidationText) =
        when user is
            Fresh -> ("form-control", "invalid-feedback", "")
            UserNotFound str -> ("form-control is-invalid", "invalid-feedback", "Username $(str) not found")
            UserNotProvided -> ("form-control is-invalid", "invalid-feedback", "Missing username")

    layout
        {
            user: session.user,
            description: "LOGIN PAGE",
            title: "LOGIN",
            navLinks: Models.NavLinks.navLinks "Login",
        }
        [
            div [class "container"] [
                div [class "row justify-content-center"] [
                    div [class "col-md-6 card"] [
                        div [class "card-body"] [
                            h5 [class "card-title"] [text "Login Form"],
                            form [class "container-fluid", action "/login", method "post"] [
                                div [class "col-auto"] [
                                    label [class "col-form-label", for "loginUsername"] [text "Username"],
                                ],
                                div [class "col-auto"] [
                                    input [class usernameInputClass, (attribute "type") "username", (attribute "required") "", id "loginUsername", name "user"],
                                    div [class usernameValidationClass] [text usernameValidationText],
                                ],
                                div [class "col-auto"] [
                                    label [class "col-form-label", for "loginPassword"] [text "Password (not used)"],
                                ],
                                div [class "col-auto"] [
                                    input [class "form-control disabled", (attribute "type") "password", (attribute "disabled") "", id "loginPassword", name "pass"],
                                ],
                                div [class "col-auto mt-2"] [
                                    button [(attribute "type") "submit", (attribute "type") "button", class "btn btn-primary"] [text "Submit"],
                                ],
                                div [class "col-auto mt-3"] [
                                    a [href "/register", class "btn btn-outline-primary"] [text "Register"],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]
