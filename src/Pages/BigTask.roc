module [view]

import html.Html exposing [div, text]
import html.Attribute exposing [class]
import Layout

view : {} -> Html.Node
view = \{} ->
    Layout.page
        {
            description: "Just making a big table",
            title: "BigTask",
        }
        [
            div [class "container"] [
                div [class "row align-items-center justify-content-center"] [
                    div [class "mt-5 mr-1 ml-1"] [
                        Html.h1 [] [Html.text "Big Task"],
                        Html.p [] [text "TODO"],
                    ],
                ],
            ],
        ]
