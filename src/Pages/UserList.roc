interface Pages.UserList
    exposes [
        view,
    ]
    imports [
        html.Html.{ element, h1, td, th, tr, table, thead, tbody, div, text },
        html.Attribute.{ class, id },
        Model.{ User, Session },
        Layout.{ layout },
        NavLinks,
    ]

view : { users : List User, session : Session } -> Html.Node
view = \{ users, session } ->

    headerText = "User List"

    layout
        {
            session,
            description: "USER LIST PAGE",
            title: "Users",
            navLinks: NavLinks.navLinks "Users",
        }
        [
            div [class "container-fluid"] [
                div [class "row justify-content-center"] [
                    div [class "col-md-9"] [
                        h1 [] [text headerText],
                    ],
                    div [class "col-md-9"] [
                        table
                            [
                                id "userTable",
                                class "table table-striped table-hover table-sm mt-2",
                            ]
                            [
                                thead [] [
                                    tr [] [
                                        th [class "col-3"] [text "User ID"],
                                        th [class "col-3"] [text "Name"],
                                        th [class "col-3"] [text "Email"],
                                    ],
                                ],
                                tbody
                                    []
                                    (
                                        users
                                        |> List.map \user ->
                                            tr [] [
                                                td [] [text (Num.toStr user.id)],
                                                td [] [text user.name],
                                                td [] [text user.email],
                                            ]
                                    ),
                            ],
                    ],
                ],
            ],
        ]
