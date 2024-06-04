module [view]

import html.Html exposing [div, text, h1, p]
import html.Attribute exposing [class]
import Layout

view : {} -> Html.Node
view = \{} ->
    Layout.page
        {
            description: "Unauthorised",
            title: "Unauthorised",
        }
        [
            div [class "container"] [
                div [class "row align-items-center justify-content-center"] [
                    div [class "mt-5 mr-1 ml-1"] [
                        h1 [] [text "Unauthorised"],
                        p [] [text "You are not authorised to view this resource, please contact and administrator."],
                        p [] [text "HINT -- try logging in with user 'Henry'"],
                    ],
                ],
            ],
        ]
