module [
    DataTable,
    newTable,
    renderTable,
]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td, h2, svg]
import html.Attribute exposing [class, role]

Heading a : {
    label : Str,
    sorted : [None, Asc, Desc],
    renderValue : a -> Html.Node,
}

DataTable a := {
    headings : List Heading,
    rows : List a,
}

# todo validate lenth and type of rows against headings
newTable = @DataTable

renderTable : DataTable a -> Html.Node
renderTable = \@DataTable {headings, rows} ->
    div [class "container-fluid"] [
        div [class "row"] [
            div [class "col-12"] [
                div [class "table-responsive"] [
                    table [class "table table-striped table-bordered"] [
                        thead [] [tr [] (renderHeadingNodes headings)],
                        #tbody [] (rowNodes rows headings),
                    ],
                ],
            ],
        ],
    ]

renderHeadingNodes : List (Heading a) -> List Html.Node
renderHeadingNodes = \headings -> List.map headings \{label} -> th [class "text-nowrap w-auto"] [text label]

#rowNodes : List (List Str), List Heading -> List Html.Node
#rowNodes = \rows, headings ->
#    rows
#    |> List.map \row ->
#        tr [] (
#            List.mapWithIndex headings \{label, renderValue}, index ->
#                when List.get row index is
#                    Ok value -> td [] [renderValue value]
#                    Err OutOfBounds -> crash "unreachable, row is too short -- should have been validated at creation"
#        )
