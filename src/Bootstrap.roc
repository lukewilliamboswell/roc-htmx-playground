module [
    DataTableForm,
    newDataTableForm,
    renderDataTableForm,
    DataTable,
    newTable,
    renderTable,
]

import html.Html exposing [div, text, table, thead, tbody, tr, th, td]
import html.Attribute exposing [attribute, class, style]

DataTableInputValidation : [None, Valid, Invalid Str]

DataTableForm := {
    updateUrl : Str,
    inputs : List {
        name : Str,
        id : Str,
        value : [Text Str, Date Str, Choice {selected: Str, others: List Str}],
        validation : DataTableInputValidation,
    },
}

newDataTableForm = @DataTableForm

renderDataTableForm : DataTableForm -> Html.Node
renderDataTableForm = \@DataTableForm {updateUrl, inputs} ->

    renderFormSection = \{name,id,value,validation} ->
        when value is
            Text str -> renderTextSection {name,id,str,validation}
            Date str -> renderDateSection {name,id,str,validation}
            Choice {selected, others} -> renderChoiceSection {name,id,selected, others,validation}

    Html.form [
        (attribute "hx-put") updateUrl,
        (attribute "hx-trigger") "input delay:250ms",
        (attribute "hx-swap") "outerHTML",
    ] (
        inputs
        |> List.map renderFormSection
        |> List.join
    )

renderTextSection = \{name,id,str,validation} ->
        [
            Html.label [Attribute.for id, Attribute.hidden ""] [Html.text name],
            (Html.element "input") [
                Attribute.type "text",
                class "form-control $(validationClass validation)",
                Attribute.id id,
                Attribute.name name,
                Attribute.value str,
            ] [],
            validationMsg validation
        ]

renderDateSection = \{name,id,str,validation} ->
    [
        Html.label [Attribute.for id, Attribute.hidden ""] [Html.text name],
        (Html.element "input") [
            Attribute.type "date",
            class "form-control $(validationClass validation)",
            Attribute.id id,
            Attribute.name name,
            Attribute.value str,
        ] [],
        validationMsg validation
    ]

renderChoiceSection = \{name,id,selected, others,validation} ->

    renderOption = \isSelected, value ->
        if isSelected then
            (Html.element "option") [(attribute "selected") ""] [Html.text value]
        else
            (Html.element "option") [] [Html.text value]

    options =
        [renderOption Bool.true selected]
        |> List.concat (List.map others \value -> renderOption Bool.false value)

    [
        Html.label [Attribute.for id, Attribute.hidden ""] [Html.text name],
        (Html.element "select") [
            class "form-select $(validationClass validation)",
            Attribute.id id,
            Attribute.name name,
        ] options,
        validationMsg validation
    ]

validationClass : DataTableInputValidation -> Str
validationClass = \validation ->
    when validation is
        None -> ""
        Valid -> "is-valid"
        Invalid _ -> "is-invalid"

validationMsg : DataTableInputValidation -> Html.Node
validationMsg = \validation ->
    when validation is
            None -> div [] []
            Valid -> div [] []
            Invalid msg -> div [class "text-danger mt-1"] [text msg]

Heading a : {
    label : Str,
    sorted : [None, Asc, Desc],
    renderValueFn : a -> Html.Node,
    width : [None, Pt U16, Px U16, Rem U16]
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
renderHeadings = \headings ->
    List.map headings \{label, width} ->
        attrs =
            when width is
                None -> [class "text-nowrap w-auto"]
                Pt size -> [class "text-nowrap w-auto", style "min-width:$(Num.toStr size)pt;"]
                Px size -> [class "text-nowrap w-auto", style "min-width:$(Num.toStr size)px;"]
                Rem size -> [class "text-nowrap w-auto", style "min-width:$(Num.toStr size)rem;"]

        th attrs [text label]

renderRows : List a, List (Heading a) -> List Html.Node
renderRows = \rows, headings ->

    renderRow : a -> List Html.Node
    renderRow = \row ->
        List.map headings \{renderValueFn} -> td [] [renderValueFn row]

    List.map rows \row -> tr [] (renderRow row)
