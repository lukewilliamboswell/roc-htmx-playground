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
        value : [String Str, Date Str],
        valid : [None, Valid, Invalid Str],
    },
}

newDataTableForm = @DataTableForm

renderDataTableForm : DataTableForm -> Html.Node
renderDataTableForm = \@DataTableForm {updateUrl, inputs} ->

    renderInput = \{name,id,value,valid} ->

        (valueAttr, typeAttr) =
            when value is
                String str -> (Attribute.value str, Attribute.type "text")
                Date str -> (Attribute.value str, Attribute.type "date")

        classAttr =
            when valid is
                None -> class "form-control"
                Valid -> class "form-control is-valid"
                Invalid _ -> class "form-control is-invalid"

        [
            Html.label [Attribute.for id, Attribute.hidden ""] [Html.text name],
            (Html.element "input") [
                typeAttr,
                classAttr,
                Attribute.id id,
                Attribute.name name,
                valueAttr,
            ] [],
            when valid is
                None -> div [] []
                Valid -> div [] []
                Invalid msg -> div [class "text-danger mt-1"] [text msg]
        ]

    Html.form [
        (Attribute.attribute "hx-put") updateUrl,
        (Attribute.attribute "hx-trigger") "input delay:250ms",
        (Attribute.attribute "hx-swap") "outerHTML",
    ] (
        inputs
        |> List.map renderInput
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
