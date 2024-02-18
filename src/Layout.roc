interface Layout
    exposes [layout]
    imports [
        html.Html.{ element, header, table, thead, form, tbody, h1, h5, td, th, tr, nav, meta, nav, button, span, link, body, button, a, input, div, text, ul, li, label },
        html.Attribute.{ attribute, src, id, href, rel, name, integrity, crossorigin, action, method, class, value, role, for, width, height },
        Model.{Session},
        NavLinks.{NavLink},
    ]

layout : {session : Session, description: Str, title: Str, navLinks : List NavLink}, List Html.Node -> Html.Node
layout = \{session, description, title, navLinks}, children ->

    loginOrUser = 
        when session.user is 
            Guest -> 
                form [class "d-flex"] [
                    button [
                        class "btn btn-secondary", 
                        (attribute "hx-get") "/login", 
                        (attribute "hx-target") "body", 
                        (attribute "hx-push-url") "true",
                    ] [ text "Login"]
                ]
            LoggedIn username -> 
                div [class "d-flex"] [
                    span [class "align-self-center d-none d-sm-block"] [personIcon],
                    span [class "align-self-center d-none d-sm-block me-3"] [text username],
                    button [
                        class "btn btn-secondary", 
                        (attribute "hx-post") "/logout", 
                        (attribute "hx-target") "body", 
                        (attribute "hx-push-url") "true",
                    ] [text "Logout"],
                ]

    Html.html [(attribute "lang") "en",  (attribute "data-bs-theme") "auto"] [
        Html.head [] [
            (element "title") [] [text title],
            meta [(attribute "charset") "UTF-8"] [],
            meta [name "description", (attribute "content") description] [],
            meta [name "viewport", (attribute "content") "width=device-width, initial-scale=1"] [],
            link [
                rel "stylesheet",
                href "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css",
                integrity "sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN",
                crossorigin "anonymous",
            ] [],
            link [
                rel "stylesheet",
                href "/styles.css",
            ] [],
            # The scripts are here to prevent these being loaded each time htmx swaps content of the body
            (element "script") [
                src "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js",
                integrity "sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL",
                crossorigin "anonymous",
            ] [],
            (element "script") [
                src "https://unpkg.com/htmx.org@1.9.9",
                integrity "sha384-QFjmbokDn2DjBjq+fM+8LUIVrAgqcNW2s0PjAxHETgRn9l4fvX31ZxDxvwQnyMOX",
                crossorigin "anonymous",
            ] [],
            (element "script") [
                src "/site.js",
            ] [],
        ],
        body [(attribute "hx-boost") "true"] [
            header [] [
                nav [class "navbar navbar-expand-sm mb-5"] [
                    div [class "container-fluid"] [
                        
                        button [
                            class "navbar-toggler",
                            (attribute "type") "button",
                            (attribute "data-bs-toggle") "collapse",
                            (attribute "data-bs-target") "#navbarNav",
                            (attribute "aria-controls") "navbarNav",
                            (attribute "aria-expanded") "false",
                            (attribute "aria-label") "Toggle navigation",
                        ][
                            span [class "navbar-toggler-icon"] []
                        ],
                        div [class "collapse navbar-collapse", id "navbarNav"] [
                            a [class "navbar-brand", href "/"] [text "Roc+HTMX"],
                            ul [class "navbar-nav me-auto"] (
                                List.map navLinks \curr ->
                                    li [class "nav-item"] [
                                        when curr is 
                                            Active config ->
                                                a [
                                                    class "nav-link active", 
                                                    (attribute "aria-current") "page", 
                                                    href config.href,
                                                    (attribute "hx-push-url") "true",
                                                ] [text config.label] 
                                            Inactive config ->
                                                a [
                                                    class "nav-link", 
                                                    href config.href,
                                                    (attribute "hx-push-url") "true",
                                                ]  [text config.label]
                                    ]
                            ),
                            loginOrUser,
                        ],
                    ],
                ],
            ],
            (element "main") [] children, 
        ],
    ]

personIcon = 
    Html.svg [
        (attribute "xmlns") "http://www.w3.org/2000/svg",
        width "16",
        height "16",
        class "me-2",
        (attribute "viewBox") "0 0 16 16",
    ][(element "path") [(attribute "d") "M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6m2-3a2 2 0 1 1-4 0 2 2 0 0 1 4 0m4 8c0 1-1 1-1 1H3s-1 0-1-1 1-4 6-4 6 3 6 4m-1-.004c-.001-.246-.154-.986-.832-1.664C11.516 10.68 10.289 10 8 10c-2.29 0-3.516.68-4.168 1.332-.678.678-.83 1.418-.832 1.664z"] []]
