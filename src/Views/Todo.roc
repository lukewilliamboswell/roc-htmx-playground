module [
    page,
    list_todo_view,
]

import html.Html exposing [element, table, thead, form, tbody, h1, td, th, tr, button, input, div, text, label]
import html.Attribute exposing [attribute, id, name, action, method, class, value, role, for]
import Models.Session exposing [Session]
import Models.Todo exposing [Todo]
import Views.Layout exposing [layout]
import Models.NavLinks

page : { todos : List Todo, filter_query : Str, session : Session } -> Html.Node
page = \{ todos, filter_query, session } ->

    header_text =
        when session.user is
            Guest -> "Guest Task List"
            LoggedIn username -> "$(username)'s Task List"

    layout
        {
            user: session.user,
            description: "TASK PAGE",
            title: "TASK",
            navLinks: Models.NavLinks.navLinks "Tasks",
        }
        [
            div [class "container-fluid"] [
                div [class "row justify-content-center"] [
                    div [class "col-md-9"] [
                        h1 [] [text header_text],
                    ],
                    div [class "col-md-9"] [
                        create_app_task_view,
                        input [
                            class "form-control mt-2",
                            name "filterTasks",
                            (attribute "type") "text",
                            (attribute "placeholder") "Search",
                            (attribute "type") "text",
                            value filter_query,
                            name "taskSearch",
                            (attribute "hx-post") "/task/search",
                            (attribute "hx-trigger") "input changed delay:500ms, search",
                            (attribute "hx-target") "#taskTable",
                            if Str.is_empty filter_query then id "nothing" else (attribute "autofocus") "",
                        ],
                        list_todo_view { todos, filter_query },
                    ],
                ],
            ],
        ]

list_todo_view : { todos : List Todo, filter_query : Str } -> Html.Node
list_todo_view = \{ todos, filter_query } ->
    if List.is_empty todos && Str.is_empty filter_query then
        div [class "alert alert-info mt-2", role "alert"] [text "Nil todos, add a task to get started."]
    else if List.is_empty todos then
        div [class "alert alert-info mt-2", role "alert"] [text "There are Nil todos matching your query."]
    else
        table_rows = List.map todos \task ->

            complete_button_base_attr = [
                (attribute "hx-put") "/task/$(Num.to_str task.id)/complete",
                (attribute "aria-label") "complete task",
                (attribute "style") "float: center;",
                (attribute "type") "button",
                class "btn btn-primary mx-2",
            ]

            complete_button =
                when task.status is
                    "Completed" -> div [] []
                    _ ->
                        (element "button")
                            complete_button_base_attr
                            [text "Complete"]

            tr [] [
                td [(attribute "scope") "row", class "col-6"] [text task.task],
                td [class "col-3 text-nowrap"] [text task.status],
                td [class "col-3"] [
                    div [class "d-flex justify-content-center"] [
                        complete_button,
                        (element "button")
                            [
                                (attribute "hx-post") "/task/$(Num.to_str task.id)/delete",
                                (attribute "hx-target") "#taskTable",
                                (attribute "aria-label") "delete task",
                                (attribute "style") "float: center;",
                                (attribute "type") "button",
                                class "btn btn-danger mx-2",
                            ]
                            [text "Delete"],
                    ],
                ],
            ]

        table
            [
                id "taskTable",
                class "table table-striped table-hover table-sm mt-2",
                (attribute "hx-get") "/task/list",
                (attribute "hx-trigger") "todosUpdated from:body",
            ]
            [
                thead [] [
                    tr [] [
                        th [(attribute "scope") "col", class "col-6"] [text "Task"],
                        th [(attribute "scope") "col", class "col-3", (attribute "rowspan") "2"] [text "Status"],
                    ],
                ],
                tbody [] table_rows,
            ]

create_app_task_view : Html.Node
create_app_task_view =
    form [action "/task/new", method "post"] [
        div [class "input-group mb-3"] [
            input [
                id "task",
                name "task",
                (attribute "type") "text",
                class "form-control",
                (attribute "placeholder") "Describe a new task",
                (attribute "required") "",
            ],
            label [for "task", class "d-none"] [text "input the task description"],
            input [name "status", value "In-Progress", (attribute "type") "text", class "d-none"], # hidden form input
            button [(attribute "type") "submit", class "btn btn-primary"] [text "Add"],
        ],
    ]
