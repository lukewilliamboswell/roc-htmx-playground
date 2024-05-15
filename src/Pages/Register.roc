interface Pages.Register
    exposes [view]
    imports [
        html.Html.{ header, table, thead, form, tbody, h1, h5, td, th, tr, nav, meta, span, link, body, button, a, input, div, text, ul, li, label },
        html.Attribute.{ attribute, src, id, href, rel, name, integrity, crossorigin, action, method, class, value, role, for, width, height },
        Model.{ Session },
        Layout.{ layout },
        NavLinks,
    ]

view : {
    session : Session,
    user : [Fresh, UserAlreadyExists Str, UserNotProvided],
    email : [Valid, Invalid Str, NotProvided],
} -> Html.Node
view = \{ session, user, email } ->

    (usernameInputClass, usernameValidationClass, usernameValidationText) =
        when user is
            Fresh -> ("form-control", "valid-feedback", "")
            UserAlreadyExists str -> ("form-control is-invalid", "invalid-feedback", "Username $(str) is already taken")
            UserNotProvided -> ("form-control is-invalid", "invalid-feedback", "Username is required")

    (emailInputClass, emailValidationClass, emailValidationText) =
        when email is
            Valid -> ("form-control", "valid-feedback", "")
            Invalid str -> ("form-control is-invalid", "invalid-feedback", "$(str) is not a valid email address")
            NotProvided -> ("form-control is-invalid", "invalid-feedback", "Email is required")

    layout
        {
            session,
            description: "REGISTRATION PAGE",
            title: "REGISTER",
            navLinks: NavLinks.navLinks "Register",
        }
        [
            div [class "container"] [
                div [class "row justify-content-center"] [
                    div [class "col-md-6 card"] [
                        div [class "card-body"] [
                            h5 [class "card-title"] [text "Registration Form"],
                            form [class "container-fluid", action "/register", method "post"] [
                                div [class "col-auto"] [
                                    label [class "col-form-label", for "registerUsername"] [text "Username"],
                                ],
                                div [class "col-auto"] [
                                    input [class usernameInputClass, (attribute "type") "text", (attribute "required") "", id "registerUsername", name "user"],
                                    div [class usernameValidationClass] [text usernameValidationText],
                                ],
                                div [class "col-auto"] [
                                    label [class "col-form-label", for "registerEmail"] [text "Email"],
                                ],
                                div [class "col-auto"] [
                                    input [class emailInputClass, (attribute "type") "email", (attribute "required") "", id "registerEmail", name "email"],
                                    div [class emailValidationClass] [text emailValidationText],
                                ],
                                div [class "col-auto"] [
                                    label [class "col-form-label", for "registerPassword"] [text "Password"],
                                ],
                                div [class "col-auto"] [
                                    input [class "form-control", (attribute "type") "password", (attribute "required") "", id "registerPassword", name "pass"],
                                ],
                                div [class "col-auto"] [
                                    label [class "col-form-label", for "confirmPassword"] [text "Confirm Password"],
                                ],
                                div [class "col-auto"] [
                                    input [class "form-control", (attribute "type") "password", (attribute "required") "", id "confirmPassword", name "confirmPass"],
                                ],
                                div [class "col-auto mt-2"] [
                                    button [(attribute "type") "submit", class "btn btn-primary"] [text "Register"],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]
