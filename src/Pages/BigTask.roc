module [view]

import html.Html exposing [div, text]
import html.Attribute exposing [class, role]
import Layout
import Model
import NavLinks

view : {session : Model.Session, tasks: List Model.BigTask} -> Html.Node
view = \{session, tasks} ->

    bigTaskTable =
        if List.isEmpty tasks then
            div [class "alert alert-info m-2", role "alert"] [text "There are Nil tasks to display."]
        else
            div [class "row"] (List.map tasks viewBigTask)

    Layout.layout
        {
            session,
            description: "Just making a big table",
            title: "BigTask",
            navLinks: NavLinks.navLinks "BigTask",
        }
        [
            div [class "container"] [
                div [class "row align-items-center justify-content-center"] [
                    Html.h1 [] [Html.text "Big Task Table"],
                    Html.p [] [text "This table is big and has many tasks, each task is a big task..."],
                ],
                bigTaskTable,
            ],
        ]

viewBigTask : Model.BigTask -> Html.Node
viewBigTask = \task ->
    Html.p [] [text "A task $(task.description)"]
