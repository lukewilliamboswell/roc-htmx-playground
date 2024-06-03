module [view]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td]
import html.Attribute exposing [class, role]
import Layout
import Model
import NavLinks
import Bootstrap

view : { session : Model.Session, tasks : List Model.BigTask } -> Html.Node
view = \{ session, tasks } ->
    Layout.layout
        {
            session,
            description: "Just making a big table",
            title: "BigTask",
            navLinks: NavLinks.navLinks "BigTask",
        }
        [
            div [class "container-fluid"] [
                div [class "row align-items-center justify-content-center"] [
                    Html.h1 [] [Html.text "Big Task Table"],
                    Html.p [] [text "This table is big and has many tasks, each task is a big task..."],
                ],
            ],
            exampleTable tasks,
        ]

exampleTable : List Model.BigTask -> Html.Node
exampleTable = \tasks ->
    Bootstrap.newTable {
        headings : [
                {
                    label: "Reference ID",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Customer ID",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Date Created",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Date Modified",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Title",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Description",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Status",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Priority",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Scheduled Start Date",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Scheduled End Date",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Actual Start Date",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Actual End Date",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "System Name",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Location",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "File Reference",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
                {
                    label: "Comments",
                    sorted: None,
                    renderValue: \task -> Html.text task.referenceId,
                },
            ],
        rows : tasks,
    }
    |> Bootstrap.renderTable
