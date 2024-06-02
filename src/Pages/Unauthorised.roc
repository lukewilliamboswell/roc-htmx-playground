module [view]

import html.Html exposing [div, text]
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
                        Html.h1 [] [Html.text "Unauthorised"],
                        Html.p [] [text "You are not authorised to view this resource, please contact and administrator."],
                    ],
                ],
            ],
        ]
