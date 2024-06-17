module [

    DataTableForm,
    newDataTableForm,
    renderDataTableForm,

    DataTableColumn,
    renderDataTable,

    Pagination,
    newPagination,
    renderPagination,

]

import html.Html exposing [element, div, text, table, thead, tbody, tr, th, td, nav, ul, li, a, span]
import html.Attribute exposing [Attribute, attribute, class, style, href]
import Views.Icons

styles : List Str -> Attribute
styles = \s -> s |> Str.joinWith " " |> Attribute.style

DataTableInputValidation : [None, Valid, Invalid Str]

DataTableForm := {
    updateUrl : Str,
    inputs : List {
        name : Str,
        id : Str,
        value : [Text Str, Date Str, Choice {selected: U64, options: List Str}],
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
            Choice {selected, options} -> renderChoiceSection {name,id,selected,options,validation}

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

renderChoiceSection = \{name,id,selected,options,validation} ->

    renderedOptions =
        List.mapWithIndex options \value, idx ->
            if idx == selected then
                (Html.element "option") [(attribute "selected") ""] [Html.text value]
            else
                (Html.element "option") [] [Html.text value]

    [
        Html.label [Attribute.for id, Attribute.hidden ""] [Html.text name],
        (Html.element "select") [
            class "form-select $(validationClass validation)",
            Attribute.id id,
            Attribute.name name,
        ] renderedOptions,
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

DataTableColumn a : {
    label : Str,
    name : Str,
    sorted : [None, Sortable, Ascending, Descending],
    renderValueFn : a -> Html.Node,
    width : [None, Pt U16, Px U16, Rem U16],
}

renderDataTable : List (DataTableColumn a), List a -> Html.Node
renderDataTable = \columns, rows ->
    div [class "container-fluid"] [
        div [class "row"] [
            div [class "col-12"] [
                div [class "table-responsive"] [
                    table [class "table table-striped table-sm table-bordered table-hover"] [
                        thead [] [tr [] (renderColumns columns)],
                        tbody [] (renderRows rows columns),
                    ],
                ],
            ],
        ],
    ]

renderColumns : List (DataTableColumn a) -> List Html.Node
renderColumns = \columns ->
    List.map columns \{label, name, width, sorted} ->

        minWidthStyle =
            when width is
                None -> ""
                Pt size -> "min-width:$(Num.toStr size)pt;"
                Px size -> "min-width:$(Num.toStr size)px;"
                Rem size -> "min-width:$(Num.toStr size)rem;"

        sortedIcon =
            when sorted is
                None -> text ""
                Sortable -> span [style "padding: 0 0.5rem;"] [Views.Icons.arrowDownUp]
                Ascending -> span [style "padding: 0 0.5rem;"] [Views.Icons.sortUp]
                Descending -> span [style "padding: 0 0.5rem;"] [Views.Icons.sortDown]

        sortDirection =
            when sorted is
                None -> ""
                Sortable -> "asc"
                # note the click will alternate direction
                Ascending -> "desc"
                Descending -> "asc"

        if sorted == None then
            th [
                class "text-nowrap w-auto",
                style minWidthStyle,
            ] [
                span [style "padding: 0 0.5rem;"] [text label],
            ]
        else
            th [
                class "text-nowrap w-auto",
                (Attribute.attribute "hx-get") "",
                (Attribute.attribute "hx-target") "body",
                (Attribute.attribute "hx-swap") "outerHTML",
                (Attribute.attribute "hx-vals")
                    """
                    {
                        "sortBy":"$(name)",
                        "sortDirection":"$(sortDirection)"
                    }
                    """,
                styles [minWidthStyle, "cursor:pointer;"],
            ] [
                sortedIcon,
                span [style "padding-right: 0.5rem;"] [text label],
            ]

renderRows : List a, List (DataTableColumn a) -> List Html.Node
renderRows = \rows, columns ->

    renderRow : a -> List Html.Node
    renderRow = \row ->
        List.map columns \{renderValueFn} -> td [] [renderValueFn row]

    List.map rows \row -> tr [] (renderRow row)

PaginationLink : {
    disabled : Bool,
    active : Bool,
    href : Str,
    label : Str,
}

Pagination := {
    description : Str,
    links : List PaginationLink,
    rowCount : U64,
    startRow : U64,
    totalRowCount : U64,
    currItemsPerPage : U64,
    minItemsPerPage : U64,
    maxItemsPerPage : U64,
}

newPagination = @Pagination

renderPaginationLink : PaginationLink -> Html.Node
renderPaginationLink = \link ->
    li [class "page-item $(if link.disabled then "disabled" else "") $(if link.active then "active" else "")"] [
        a [
            class "page-link",
            href link.href,
            if link.disabled then ((attribute "tabindex") "-1") else ((attribute "tabindex") "0"),
        ] [text link.label]
    ]

renderPagination : Pagination -> Html.Node
renderPagination = \@Pagination {description, links, rowCount, startRow,totalRowCount,currItemsPerPage,minItemsPerPage,maxItemsPerPage} ->
    nav [(attribute "aria-label") description] [
        div [
                class "d-inline-block",
                styles [
                    "margin-right: 1rem;",
                    "padding-top: 1px;",
                ]
            ] [
            div [class "input-group"] [
                div [class "input-group-prepend"] [
                    div [
                        class "input-group-text",
                        styles [
                            "border-top-right-radius: 0 !important;",
                            "border-bottom-right-radius: 0 !important;",
                            "height: 100%;",
                        ]
                    ] [Views.Icons.listOL]
                ],
                Html.form [
                    (attribute "hx-get") "", # reload the current URL, including the curent parameters
                    (attribute "hx-trigger") "input delay:500ms",
                    (attribute "hx-target") "body",
                    (attribute "hx-swap") "outerHTML",
                    (attribute "id") "formUpdateItemsPerPage",
                ] [
                    (element "input") [
                        Attribute.type "number",
                        Attribute.name "updateItemsPerPage",
                        class "form-control",
                        (attribute "id") "updateItemsPerPage",
                        Attribute.value "$(Num.toStr currItemsPerPage)",
                        Attribute.min "$(Num.toStr minItemsPerPage)",
                        Attribute.max "$(Num.toStr maxItemsPerPage)",
                        styles [
                            "border-top-right-radius: 5px;",
                            "border-bottom-right-radius: 5px;",
                        ],
                    ] []
                ],
            ]
        ],
        div [class "d-inline-block", styles ["margin-right: 1rem;"]] [
            ul [class "pagination"] (List.map links renderPaginationLink)
        ],
        div [class "d-inline-block"] [
            text "Showing rows $(Num.toStr startRow) to $(Num.toStr (startRow + rowCount - 1)) of $(Num.toStr totalRowCount) total rows"
        ],
    ]
