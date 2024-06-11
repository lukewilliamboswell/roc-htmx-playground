module [page]

import html.Html exposing [div, text]
import html.Attribute exposing [class]
import Views.Layout
import Models.Session exposing [Session]
import Models.BigTask exposing [BigTask]
import Models.NavLinks
import Views.Bootstrap

page : {
    session : Session,
    tasks : List BigTask,
    pagination : {page : I64, items : I64, total : I64, baseHref : Str},
} -> Html.Node
page = \{ session, tasks, pagination } ->
    Views.Layout.layout
        {
            user: session.user,
            description: "Just making a big table",
            title: "BigTask",
            navLinks: Models.NavLinks.navLinks "BigTask",
        }
        [
            div [ class "container-fluid" ] [
                div [class "row align-items-center justify-content-center"] [
                    Html.h1 [] [Html.text "Big Task Table"],
                    Html.p [] [text "This table is big and has many tasks, each task is a big task..."],
                ],
                div [class "row"] [Views.Bootstrap.renderTable dataTable tasks],
                div [class "row"] [
                        paginationView {
                            page : pagination.page,
                            items : pagination.items,
                            total : pagination.total,
                            baseHref : pagination.baseHref,
                            rowCount : Num.toU64 (tasks |> List.map (\_ -> 1) |> List.sum),
                            startRow : Num.toU64 (((pagination.page-1)*pagination.items) + 1),
                        },
                ]
            ],

        ]

paginationView = \{page : pageNumber,items,total,baseHref,rowCount,startRow} ->
    {
        description : "BigTable pagination",
        links: paginationLinks {page: pageNumber, items, total, baseHref},
        rowCount,
        startRow,
        totalRowCount : Num.toU64 total,
        currItemsPerPage : Num.toU64 items,
        minItemsPerPage : 1,
        maxItemsPerPage : 10000,
    }
    |> Views.Bootstrap.newPagination
    |> Views.Bootstrap.renderPagination

dataTable : Views.Bootstrap.DataTable BigTask
dataTable = Views.Bootstrap.newTable {
    headings : [
            {
                label: "Reference ID",
                sorted: None,
                renderValueFn: \task -> Html.text task.referenceId,
                width: None,
            },
            {
                label: "Customer ID",
                sorted: Sortable,
                renderValueFn: \task ->
                    idStr = Num.toStr task.id
                    {
                        updateUrl : "/bigTask/customerId/$(idStr)",
                        inputs : [{
                            name : "CustomerReferenceID",
                            id : "customer-id-$(idStr)",
                            value : Text task.customerReferenceId,
                            validation : None,
                        }],
                    }
                    |> Views.Bootstrap.newDataTableForm
                    |> Views.Bootstrap.renderDataTableForm,
                width: None,

            },
            {
                label: "Date Created",
                sorted: None,
                renderValueFn: \task ->
                    idStr = Num.toStr task.id
                    {
                        updateUrl : "/bigTask/dateCreated/$(idStr)",
                        inputs : [{
                            name : "DateCreated",
                            id : "date-created-$(idStr)",
                            value : Date (Models.BigTask.dateToStr task.dateCreated),
                            validation : None,
                        }],
                    }
                    |> Views.Bootstrap.newDataTableForm
                    |> Views.Bootstrap.renderDataTableForm,
                width: Rem 10,
            },
            {
                label: "Date Modified",
                sorted: None,
                renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.dateCreated),
                width: None,
            },
            {
                label: "Title",
                sorted: None,
                renderValueFn: \task -> Html.text task.title,
                width: Rem 12,
            },
            {
                label: "Description",
                sorted: None,
                renderValueFn: \task -> Html.text task.description,
                width: Rem 12,
            },
            {
                label: "Status",
                sorted: None,
                renderValueFn: \task ->
                    idStr = Num.toStr task.id
                    {
                        updateUrl : "/bigTask/status/$(idStr)",
                        inputs : [{
                            name : "Status",
                            id : "status-$(idStr)",
                            value : Choice {
                                selected:
                                    task.status
                                    |> Models.BigTask.statusToStr
                                    |> Models.BigTask.statusOptionIndex
                                    |> Result.withDefault 0,
                                options: Models.BigTask.statusOptions
                            },
                            validation : None,
                        }],
                    }
                    |> Views.Bootstrap.newDataTableForm
                    |> Views.Bootstrap.renderDataTableForm,
                width: Rem 10,
            },
            {
                label: "Priority",
                sorted: None,
                renderValueFn: \task -> Html.text (Models.BigTask.priorityToStr task.priority),
                width: None,
            },
            {
                label: "Scheduled Start Date",
                sorted: None,
                renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.scheduledStartDate),
                width: None,
            },
            {
                label: "Scheduled End Date",
                sorted: None,
                renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.scheduledEndDate),
                width: None,
            },
            {
                label: "Actual Start Date",
                sorted: None,
                renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.actualStartDate),
                width: None,
            },
            {
                label: "Actual End Date",
                sorted: None,
                renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.actualEndDate),
                width: None,
            },
            {
                label: "System Name",
                sorted: None,
                renderValueFn: \task -> Html.text task.systemName,
                width: None,
            },
            {
                label: "Location",
                sorted: None,
                renderValueFn: \task -> Html.text task.location,
                width: Rem 8,
            },
            {
                label: "File Reference",
                sorted: None,
                renderValueFn: \task -> Html.text task.fileReference,
                width: None,
            },
            {
                label: "Comments",
                sorted: None,
                renderValueFn: \task -> Html.text task.comments,
                width: Rem 20,
            },
        ],
}

# items is the number of items per page
# page is the current page
# page is 1-indexed
paginationLinks : {page : I64, items : I64, total : I64, baseHref : Str} -> List {
    disabled : Bool,
    active : Bool,
    href : Str,
    label : Str,
}
paginationLinks = \{page: pageNumber, items, total, baseHref} ->

    totalPages = Num.ceiling ((Num.toFrac total) / (Num.toFrac items)) |> Num.toI64

    # Previous
    prev = {
        disabled: pageNumber == 1,
        active: Bool.false,
        href: if pageNumber == 1 then "#" else "$(baseHref)page=$(Num.toStr (pageNumber - 1))&items=$(Num.toStr items)",
        label: "Previous",
    }

    # Numbered  -3 -2 -1 current +1 +2 +3
    numbered =
        List.range {
                start: At (Num.max 1 (pageNumber - 3)),
                end: At (Num.min totalPages (pageNumber + 3)),
            }
        |> List.map \n -> {
            disabled: Bool.false,
            active: n == pageNumber,
            href: if n == pageNumber then "#" else "$(baseHref)page=$(Num.toStr n)&items=$(Num.toStr items)",
            label: Num.toStr n,
        }

    # Current
    current = {
        disabled: Bool.false,
        active: Bool.true,
        href: "#",
        label: Num.toStr pageNumber,
    }

    # Next
    next = {
        disabled: pageNumber == totalPages,
        active: Bool.false,
        href: if pageNumber == totalPages then "#" else "$(baseHref)page=$(Num.toStr (pageNumber + 1))&items=$(Num.toStr items)",
        label: "Next",
    }

    if totalPages <= 7 then
        numbered
    else
        [prev,current,next]
