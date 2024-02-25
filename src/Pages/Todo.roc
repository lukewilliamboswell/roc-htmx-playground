interface Pages.Todo
    exposes [
        view,
        listTodoView,
    ]
    imports [
        html.Html.{ element, header, table, thead, form, tbody, h1, h5, td, th, tr, nav, meta, nav, button, span, body, button, a, input, div, text, ul, li, label },
        html.Attribute.{ attribute, id, href, rel, name, action, method, class, value, role, for, width, height },
        Model.{ Session, Todo },
        Layout.{ layout },
        NavLinks,
    ]

view : { todos : List Todo, searchQuery : Str, session : Session } -> Html.Node
view = \{ todos, searchQuery, session } ->

    headerText =
        when session.user is
            Guest -> "Guest Task List"
            LoggedIn username -> "$(username)'s Task List"

    layout
        {
            session,
            description: "TASK PAGE",
            title: "TASK",
            navLinks: NavLinks.navLinks "Tasks",
        }
        [
            div [class "container-fluid"] [
                div [class "row justify-content-center"] [
                    div [class "col-md-9"] [
                        h1 [] [text headerText],
                    ],
                    div [class "col-md-9"] [
                        createAppTaskView,
                        input
                            [
                                class "form-control mt-2",
                                name "filterTasks",
                                (attribute "type") "text",
                                (attribute "placeholder") "Search",
                                (attribute "type") "text",
                                value searchQuery,
                                name "taskSearch",
                                (attribute "hx-post") "/task/search",
                                (attribute "hx-trigger") "input changed delay:500ms, search",
                                (attribute "hx-target") "#taskTable",
                                if Str.isEmpty searchQuery then id "nothing" else (attribute "autofocus") "",
                            ]
                            [],
                        listTodoView { todos, searchQuery },
                    ],
                ],
            ],
        ]

listTodoView : { todos : List Todo, searchQuery : Str } -> Html.Node
listTodoView = \{ todos, searchQuery } ->
    if List.isEmpty todos && Str.isEmpty searchQuery then
        div [class "alert alert-info mt-2", role "alert"] [text "Nil todos, add a task to get started."]
    else if List.isEmpty todos then
        div [class "alert alert-info mt-2", role "alert"] [text "There are Nil todos matching your query."]
    else
        tableRows = List.map todos \task ->

            completeButtonBaseAttr = [
                (attribute "hx-put") "/task/$(Num.toStr task.id)/complete",
                (attribute "aria-label") "complete task",
                (attribute "style") "float: center;",
                (attribute "type") "button",
                class "btn btn-primary mx-2",
            ]

            completeButton =
                when task.status is
                    "Completed" -> div [] []
                    _ -> 
                        (element "button")
                            completeButtonBaseAttr
                            [text "Complete"]

            tr [] [
                td [(attribute "scope") "row", class "col-6"] [text task.task],
                td [class "col-3 text-nowrap"] [text task.status],
                td [class "col-3"] [
                    div [class "d-flex justify-content-center"] [
                        completeButton,
                        (element "button")
                            [
                                (attribute "hx-post") "/task/$(Num.toStr task.id)/delete",
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
                tbody [] tableRows,
            ]

createAppTaskView : Html.Node
createAppTaskView =
    form [action "/task/new", method "post"] [
        div [class "input-group mb-3"] [
            input
                [
                    id "task",
                    name "task",
                    (attribute "type") "text",
                    class "form-control",
                    (attribute "placeholder") "Describe a new task",
                    (attribute "required") "",
                ]
                [],
            label [for "task", class "d-none"] [text "input the task description"],
            input [name "status", value "In-Progress", (attribute "type") "text", class "d-none"] [], # hidden form input
            button [(attribute "type") "submit", class "btn btn-primary"] [text "Add"],
        ],
    ]
