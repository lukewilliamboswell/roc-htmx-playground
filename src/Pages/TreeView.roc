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
                    ul [class "todo-tree-ul"] [
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
                    checkboxElem todo.task Checked
                else 
                    checkboxElem todo.task NotChecked

            li [] [
                span [] [checkbox],
                ul [class "todo-tree-ul"] (List.map children nodesView),
            ]

checkboxElem = \str, check ->
    withCheck = \attrs ->
        when check is 
            Checked -> List.append attrs ((attribute "checked") "")
            NotChecked -> attrs

    Html.div [class "form-check"] [
        Html.input (withCheck [
            class "form-check-input",
            (attribute "type") "checkbox",
            (attribute "value") "",
        ]) [],
        Html.label [
            class "form-check-label",
        ] [
            Html.text str
        ],
    ]