interface Pages.TreeView
    exposes [view]
    imports [
        html.Html.{ header, table, thead, form, tbody, h1, h5, td, th, tr, nav, meta, nav, button, span, link, body, button, a, input, div, text, ul, li, label },
        html.Attribute.{ attribute, src, id, href, rel, name, integrity, crossorigin, action, method, class, value, role, for, width, height },
        Model.{ Session, Todo, Tree },
        Layout.{ layout },
        NavLinks,
    ]

view : {
    session : Session,
    nodes : Tree Todo,
} -> Html.Node
view = \{ session, nodes } ->
    layout
        {
            session,
            description: "TREE VIEW PAGE",
            title: "TREE VIEW",
            navLinks: NavLinks.navLinks "TreeView",
        }
        [
            div [class "container"] [
                div [class "row justify-content-center"] [
                    ul [
                        class "todo-tree-ul",
                        (attribute "hx-get") "/treeview",
                        (attribute "hx-target") "body",
                        (attribute "hx-trigger") "todosUpdated from:body"
                    ] [
                        nodesView nodes 
                    ]
                ],
            ],
        ]

nodesView : Tree Todo -> Html.Node
nodesView = \node ->
    when node is
        Empty -> li [] [text "EMPTY"]
        Node todo children ->

            checkbox = 
                if todo.status == "Completed" then
                    checkboxElem todo.task (Num.toStr todo.id) Checked
                else 
                    checkboxElem todo.task (Num.toStr todo.id) NotChecked

            li [] [
                span [] [checkbox],
                ul [class "todo-tree-ul"] (List.map children nodesView),
            ]

checkboxElem = \str, taskIdStr, check ->
    
    (checkAttrs) = 
        when check is 
            Checked -> 
                ([
                    (attribute "hx-put") "/task/$(taskIdStr)/in-progress",
                    class "form-check-input",
                    (attribute "type") "checkbox",
                    (attribute "value") "",
                    (attribute "checked") "",
                ]) 
            NotChecked -> 
                ([
                    (attribute "hx-put") "/task/$(taskIdStr)/complete",
                    class "form-check-input",
                    (attribute "type") "checkbox",
                    (attribute "value") "",
                ])

    Html.div [class "form-check"] [
        Html.input checkAttrs [],
        Html.label [
            class "form-check-label",
        ] [
            Html.text str
        ],
    ]