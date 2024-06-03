module [view]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td, h2, svg]
import html.Attribute exposing [class, role]
import Layout
import Model
import NavLinks
import Bootstrap

view : { session : Model.Session, tasks : List Model.BigTask } -> Html.Node
view = \{ session, tasks } ->

    # bigTaskTable =
    #    if List.isEmpty tasks then
    #        div [class "alert alert-info m-2", role "alert"] [text "There are Nil tasks to display."]
    #    else
    #        div [class "row"] (List.map tasks viewBigTask)

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

exampleTable = \tasks ->
    Bootstrap.newTable {
        headings : [
            {label: "Reference ID", sorted: None},
            {label: "Customer ID", sorted: None},
            {label: "Date Created", sorted: None},
            {label: "Date Modified", sorted: None},
            {label: "Title", sorted: None},
            {label: "Description", sorted: None},
            {label: "Status", sorted: None},
            {label: "Priority", sorted: None},
            {label: "Scheduled Start Date", sorted: None},
            {label: "Scheduled End Date", sorted: None},
            {label: "Actual Start Date", sorted: None},
            {label: "Actual End Date", sorted: None},
            {label: "System Name", sorted: None},
            {label: "Location", sorted: None},
            {label: "File Reference", sorted: None},
            {label: "Comments", sorted: None},
            ],
        rows : tasks,
        renderValue : renderTaskValue,
    }
    |> Bootstrap.renderTable

    #{
    #    id : I64,
    #    referenceId : Str,
    #    customerReferenceId : Str,
    #    dateCreated : Date,
    #    dateModified : Date,
    #    title : Str,
    #    description : Str,
    #    status : Status,
    #    priority : Priority,
    #    scheduledStartDate : Date,
    #    scheduledEndDate : Date,
    #    actualStartDate : Date,
    #    actualEndDate : Date,
    #    systemName : Str,
    #    location : Str,
    #    fileReference : Str,
    #    comments : Str,
    #}

renderTaskValue = \task, column ->
    when column is
        "Reference ID" -> Html.text task.referenceId
        "Customer ID" -> Html.text task.referenceId
        "Date Created" -> Html.text task.referenceId
        "Date Modified" -> Html.text task.referenceId
        "Title" -> Html.text task.referenceId
        "Description" -> Html.text task.referenceId
        "Status" -> Html.text task.referenceId
        "Priority" -> Html.text task.referenceId
        "Scheduled Start Date" -> Html.text task.referenceId
        "Scheduled End Date" -> Html.text task.referenceId
        "Actual Start Date" -> Html.text task.referenceId
        "Actual End Date" -> Html.text task.referenceId
        "System Name" -> Html.text task.referenceId
        "Location" -> Html.text task.referenceId
        "File Reference" -> Html.text task.referenceId
        "Comments" -> Html.text task.referenceId
        _ -> crash "unreachable, column not found"

# <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-sort-up" viewBox="0 0 16 16">
#  <path d="M3.5 12.5a.5.5 0 0 1-1 0V3.707L1.354 4.854a.5.5 0 1 1-.708-.708l2-1.999.007-.007a.5.5 0 0 1 .7.006l2 2a.5.5 0 1 1-.707.708L3.5 3.707zm3.5-9a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 0 1h-7a.5.5 0 0 1-.5-.5M7.5 6a.5.5 0 0 0 0 1h5a.5.5 0 0 0 0-1zm0 3a.5.5 0 0 0 0 1h3a.5.5 0 0 0 0-1zm0 3a.5.5 0 0 0 0 1h1a.5.5 0 0 0 0-1z"/>
# </svg>
sortIcon =
    svg
        [
            (Attribute.attribute "xmlns") "http://www.w3.org/2000/svg",
            (Attribute.attribute "width") "16",
            (Attribute.attribute "height") "16",
            (Attribute.attribute "fill") "currentColor",
            (Attribute.attribute  "viewBox") "0 0 16 16",
        ]
        [
            (Html.element "path") [
                (Attribute.attribute "d") "M3.5 12.5a.5.5 0 0 1-1 0V3.707L1.354 4.854a.5.5 0 1 1-.708-.708l2-1.999.007-.007a.5.5 0 0 1 .7.006l2 2a.5.5 0 1 1-.707.708L3.5 3.707zm3.5-9a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 0 1h-7a.5.5 0 0 1-.5-.5M7.5 6a.5.5 0 0 0 0 1h5a.5.5 0 0 0 0-1zm0 3a.5.5 0 0 0 0 1h3a.5.5 0 0 0 0-1zm0 3a.5.5 0 0 0 0 1h1a.5.5 0 0 0 0-1z",
            ] [],
        ]
