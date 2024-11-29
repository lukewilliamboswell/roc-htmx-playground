module [page]

import html.Html exposing [div, h1, h2, h3, a, p, text, ul, li]
import html.Attribute exposing [href, class]
import Models.Session exposing [Session]
import Views.Layout exposing [layout]
import Models.NavLinks

page : { session : Session } -> Html.Node
page = \{ session } ->
    layout
        {
            user: session.user,
            description: "HOME PAGE",
            title: "HOME",
            navLinks: Models.NavLinks.navLinks "Home",
        }
        [
            div [class "container mt-5"] [
                div [class "row justify-content-center"] [
                    div [class "col-lg-8"] [
                        h1 [class "display-4 mb-4"] [text "Roc + HTMX Web App"],
                        p [class "lead"] [text "Welcome to the Roc + HTMX example web app!"],
                        p [] [
                            text "This web application provides a simple yet effective demonstration of structuring an application. It allows you to create, update, and delete tasks, mark them as complete, and track your productivity efficiently.",
                        ],
                        div [class "alert alert-info mt-4"] [
                            p [class "mb-0"] [
                                text "The site is styled using Bootstrap 5. It supports both light and dark modes using JavaScript.",
                            ],
                        ],
                        div [class "card mt-4"] [
                            div [class "card-body"] [
                                h2 [class "card-title"] [text "Goals of the Demo App"],
                                p [class "card-text"] [
                                    text "This demo app is designed to:",
                                ],
                                ul [class "list-unstyled"] [
                                    li [class "mb-2"] [
                                        text "✔️ Explore ",
                                        a [href "https://www.roc-lang.org"] [text "Roc"],
                                        text " and ",
                                        a [href "https://htmx.org"] [text "HTMX"],
                                        text " for app development.",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Test new features to add to ",
                                        a [href "https://github.com/roc-lang/basic-webserver"] [text "roc-lang/basic-webserver"],
                                        text ".",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Tinker and have fun building a web app.",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Learn new concepts and share knowledge with others.",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Mature the basic-webserver platform to be more \"production ready\".",
                                    ],
                                ],
                            ],
                        ],
                        div [class "card mt-4"] [
                            div [class "card-body"] [
                                h3 [class "card-title"] [text "Features"],
                                ul [class "list-unstyled"] [
                                    li [class "mb-2"] [
                                        text "✔️ Create new tasks",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ View all tasks",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Update task details",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Delete tasks",
                                    ],
                                    li [class "mb-2"] [
                                        text "✔️ Mark tasks as complete",
                                    ],
                                ],
                            ],
                        ],
                        div [class "alert alert-warning mt-4"] [
                            p [class "mb-0"] [
                                text "The app includes a small example of how to use Nested Sets to represent hierarchical data in a database. The tree view page demonstrates rendering nested data on a web page. All data is stored in a Sqlite3 database, supported by the basic-webserver platform.",
                            ],
                        ],
                        div [class "alert alert-danger mt-4"] [
                            p [class "mb-0"] [
                                text "To access the \"BigTask\" link, you need to be logged in as a user. Otherwise, you will see an unauthorized message.",
                            ],
                        ],
                        p [class "mt-4"] [
                            text "You are welcome to contribute ideas or feedback on how to improve this app.",
                        ],
                    ],
                ],
            ],
        ]
