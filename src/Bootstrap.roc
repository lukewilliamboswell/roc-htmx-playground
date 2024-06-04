module [
    DataTableForm,
    newDataTableForm,
    renderDataTableForm,
    DataTable,
    newTable,
    renderTable,
]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td]
import html.Attribute exposing [class]

DataTableForm := {
    updateUrl : Str,
    inputs : List {
        name : Str,
        id : Str,
        value : Str,
    },
    errors : List Str,
}

newDataTableForm = @DataTableForm

renderDataTableForm : DataTableForm -> Html.Node
renderDataTableForm = \@DataTableForm {updateUrl, inputs, errors} ->

    renderInput = \{name,id,value} ->
        [
            Html.label [Attribute.for id, Attribute.hidden ""] [Html.text name],
            (Html.element "input") [
                Attribute.type "text",
                class "form-control",
                Attribute.id id,
                Attribute.name name,
                Attribute.value value,
            ] []
        ]

    Html.form [
        (Attribute.attribute "hx-put") updateUrl,
        (Attribute.attribute "hx-trigger") "input delay:250ms",
        (Attribute.attribute "hx-swap") "outerHTML",
    ] (
        inputs
        |> List.map renderInput
        |> List.concat [List.map errors \error -> div [class "alert alert-danger mt-1"] [text error]]
        |> List.join
    )

Heading a : {
    label : Str,
    sorted : [None, Asc, Desc],
    renderValueFn : a -> Html.Node,
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

    renderRow : a -> List Html.Node
    renderRow = \row ->
        List.map headings \{renderValueFn} -> td [] [renderValueFn row]

    List.map rows \row -> tr [] (renderRow row)
