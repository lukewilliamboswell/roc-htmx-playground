module [
    DataTable,
    newTable,
    renderTable,
]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td]
import html.Attribute exposing [class]

Heading a : {
    label : Str,
    sorted : [None, Asc, Desc],
    renderValueFn : a, U64 -> Html.Node,
}

DataTable a := {
    headings : List (Heading a),
}

# todo validate lenth and type of rows against headings
newTable = @DataTable

renderTable : DataTable a, List a -> Html.Node
renderTable = \@DataTable {headings}, rows ->
    div [class "container-fluid"] [
        div [class "row"] [
            div [class "col-12"] [
                div [class "table-responsive"] [
                    table [class "table table-striped table-bordered"] [
                        thead [] [tr [] (renderHeadings headings)],
                        tbody [] (renderRows rows headings),
                    ],
                ],
            ],
        ],
    ]

renderHeadings : List (Heading a) -> List Html.Node
renderHeadings = \headings -> List.map headings \{label} -> th [class "text-nowrap w-auto"] [text label]

renderRows : List a, List (Heading a) -> List Html.Node
renderRows = \rows, headings ->

    renderRow : a, U64 -> List Html.Node
    renderRow = \row, idx ->
        List.map headings \{renderValueFn} -> td [] [renderValueFn row idx]

    List.mapWithIndex rows \row, idx -> tr [] (renderRow row idx)
