module [
    DataTable,
    newTable,
    renderTable,
]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td, h2, svg]
import html.Attribute exposing [class, role]

DataTable a := {
    headings : List {
        label : Str,
        sorted : [None, Asc, Desc],
    },
    rows : List a,
    renderValue : a, Str -> Html.Node,
}

newTable = @DataTable

renderTable : DataTable a -> Html.Node
renderTable = \@DataTable {headings, rows, renderValue} ->

    headingNodes = headings |> List.map \{label} -> th [class "text-nowrap w-auto"] [text label]
    rowNodes = List.map rows \row -> tr [] (List.map headings \{label} -> td [] [renderValue row label])

    div [class "container-fluid"] [
        div [class "row"] [
            div [class "col-12"] [
                div [class "table-responsive"] [
                    table [class "table table-striped table-bordered"] [
                        thead [] [tr [] headingNodes],
                        tbody [] [],
                    ],
                ],
            ],
        ],
    ]
