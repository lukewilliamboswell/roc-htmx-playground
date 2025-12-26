module [page]

import html.Html
import html.Attribute exposing [attribute, class]
import Models.Session exposing [Session]
import Models.NestedSet exposing [Tree]
import Models.Todo exposing [Todo]
import Models.NavLinks
import Views.Layout exposing [layout]

page :
    {
        session : Session,
        nodes : Tree Todo,
    }
    -> Html.Node
page = \{ session, nodes } ->
    layout
        {
            user: session.user,
            description: "TREE VIEW PAGE",
            title: "TREE VIEW",
            navLinks: Models.NavLinks.navLinks "Tree",
        }
        [
            Html.div
                [
                    class "container",
                    (attribute "hx-get") "/treeview",
                    (attribute "hx-target") "body",
                    (attribute "hx-trigger") "todosUpdated from:body",
                ]
                [
                    Html.div [class "row justify-content-center"] [
                        Html.ul
                            [
                                class "todo-tree-ul",

                            ]
                            [
                                nodesView nodes,
                            ],
                    ],
                ],
        ]

nodesView : Tree Todo -> Html.Node
nodesView = \node ->
    when node is
        Empty -> Html.li [] [Html.text "EMPTY"]
        Node todo children ->
            checkbox =
                if todo.status == "Completed" then
                    checkboxElem todo.task (Num.to_str todo.id) Checked
                else
                    checkboxElem todo.task (Num.to_str todo.id) NotChecked

            Html.li [] [
                Html.span [] [checkbox],
                Html.ul [class "todo-tree-ul"] (List.map children nodesView),
            ]

checkboxElem = \str, taskIdStr, check ->
    checkAttrs =
        when check is
            Checked ->
                [
                    (attribute "hx-put") "/task/$(taskIdStr)/in-progress",
                    class "form-check-input",
                    (attribute "type") "checkbox",
                    (attribute "value") "",
                    (attribute "checked") "",
                ]

            NotChecked ->
                [
                    (attribute "hx-put") "/task/$(taskIdStr)/complete",
                    class "form-check-input",
                    (attribute "type") "checkbox",
                    (attribute "value") "",
                ]

    Html.div [class "form-check"] [
        Html.input checkAttrs,
        Html.label
            [
                class "form-check-label",
            ]
            [
                Html.text str,
            ],
    ]
