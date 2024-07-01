module [page]

import html.Html exposing [div, a, text]
import html.Attribute exposing [attribute, class, type, href]
import Views.Layout
import Models.Session exposing [Session]
import Models.BigTask exposing [BigTask]
import Models.NavLinks
import Views.Bootstrap exposing [DataTableColumn]

page :
    {
        session : Session,
        tasks : List BigTask,
        sortBy : Str,
        sortDirection : [ASCENDING, DESCENDING],
        pagination : { page : I64, items : I64, total : I64, baseHref : Str },
    }
    -> Html.Node
page = \{ session, tasks, pagination, sortBy, sortDirection } ->
    Views.Layout.layout
        {
            user: session.user,
            description: "Just making a big table",
            title: "BigTask",
            navLinks: Models.NavLinks.navLinks "BigTask",
        }
        [
            div [class "container-fluid"] [
                div [class "row align-items-center justify-content-center"] [
                    Html.h1 [] [Html.text "Big Task Table"],
                    Html.p [] [text "This table is big and has many tasks, each task is a big task..."],
                ],
                div [class "row"] [
                    div [class "inline-block m-2"] [
                        a [
                            type "button",
                            class "btn btn-success",
                            href "/bigTask/downloadCsv",
                            (attribute "download") "",
                            (attribute "hx-disable") "",
                            (attribute "aria-label") "Download Button",
                        ] [
                            text "Download CSV",
                        ],
                    ],
                ],
                div [class "row"] [
                    Views.Bootstrap.renderDataTable (columns { sortBy, sortDirection }) tasks
                ],
                div [class "row"] [
                    paginationView {
                        page: pagination.page,
                        items: pagination.items,
                        total: pagination.total,
                        baseHref: pagination.baseHref,
                        rowCount: Num.toU64 (tasks |> List.map (\_ -> 1) |> List.sum),
                        startRow: Num.toU64 (((pagination.page - 1) * pagination.items) + 1),
                    },
                ],
            ],
        ]

paginationView = \{ page: pageNumber, items, total, baseHref, rowCount, startRow } ->
    {
        description: "BigTable pagination",
        links: paginationLinks { page: pageNumber, items, total, baseHref },
        rowCount,
        startRow,
        totalRowCount: Num.toU64 total,
        currItemsPerPage: Num.toU64 items,
        minItemsPerPage: 1,
        maxItemsPerPage: 10000,
    }
    |> Views.Bootstrap.newPagination
    |> Views.Bootstrap.renderPagination

columns :
    {
        sortBy : Str,
        sortDirection : [ASCENDING, DESCENDING],
    }
    -> List (DataTableColumn BigTask)
columns = \{ sortBy, sortDirection } ->

    sortedArg = \name ->
        if name == sortBy then
            when sortDirection is
                ASCENDING -> Ascending
                DESCENDING -> Descending
        else
            Sortable

    [
        {
            label: "Reference ID",
            name: "ReferenceID",
            sorted: None,
            renderValueFn: \task -> Html.text task.referenceId,
            width: None,
        },
        {
            label: "Customer ID",
            name: "CustomerReferenceID",
            sorted: sortedArg "CustomerReferenceID",
            renderValueFn: \task ->
                idStr = Num.toStr task.id
                {
                    updateUrl: "/bigTask/customerId/$(idStr)",
                    inputs: [
                        {
                            name: "CustomerReferenceID",
                            id: "customer-id-$(idStr)",
                            value: Text task.customerReferenceId,
                            validation: None,
                        },
                    ],
                }
                |> Views.Bootstrap.newDataTableForm
                |> Views.Bootstrap.renderDataTableForm,
            width: None,

        },
        {
            label: "Date Created",
            name: "DateCreated",
            sorted: sortedArg "DateCreated",
            renderValueFn: \task ->
                idStr = Num.toStr task.id
                {
                    updateUrl: "/bigTask/dateCreated/$(idStr)",
                    inputs: [
                        {
                            name: "DateCreated",
                            id: "date-created-$(idStr)",
                            value: Date (Models.BigTask.dateToStr task.dateCreated),
                            validation: None,
                        },
                    ],
                }
                |> Views.Bootstrap.newDataTableForm
                |> Views.Bootstrap.renderDataTableForm,
            width: Rem 10,
        },
        {
            label: "Date Modified",
            name: "DateModified",
            sorted: sortedArg "DateModified",
            renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.dateCreated),
            width: None,
        },
        {
            label: "Title",
            name: "Title",
            sorted: sortedArg "Title",
            renderValueFn: \task -> Html.text task.title,
            width: Rem 12,
        },
        {
            label: "Description",
            name: "Description",
            sorted: sortedArg "Description",
            renderValueFn: \task -> Html.text task.description,
            width: Rem 12,
        },
        {
            label: "Status",
            name: "Status",
            sorted: sortedArg "Status",
            renderValueFn: \task ->
                idStr = Num.toStr task.id
                {
                    updateUrl: "/bigTask/status/$(idStr)",
                    inputs: [
                        {
                            name: "Status",
                            id: "status-$(idStr)",
                            value: Choice {
                                selected: task.status
                                |> Models.BigTask.statusToStr
                                |> Models.BigTask.statusOptionIndex
                                |> Result.withDefault 0,
                                options: Models.BigTask.statusOptions,
                            },
                            validation: None,
                        },
                    ],
                }
                |> Views.Bootstrap.newDataTableForm
                |> Views.Bootstrap.renderDataTableForm,
            width: Rem 10,
        },
        {
            label: "Priority",
            name: "Priority",
            sorted: sortedArg "Priority",
            renderValueFn: \task -> Html.text (Models.BigTask.priorityToStr task.priority),
            width: None,
        },
        {
            label: "Scheduled Start Date",
            name: "ScheduledStartDate",
            sorted: sortedArg "ScheduledStartDate",
            renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.scheduledStartDate),
            width: None,
        },
        {
            label: "Scheduled End Date",
            name: "ScheduledEndDate",
            sorted: sortedArg "ScheduledEndDate",
            renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.scheduledEndDate),
            width: None,
        },
        {
            label: "Actual Start Date",
            name: "ActualStartDate",
            sorted: sortedArg "ActualStartDate",
            renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.actualStartDate),
            width: None,
        },
        {
            label: "Actual End Date",
            name: "ActualEndDate",
            sorted: sortedArg "ActualEndDate",
            renderValueFn: \task -> Html.text (Models.BigTask.dateToStr task.actualEndDate),
            width: None,
        },
        {
            label: "System Name",
            name: "SystemName",
            sorted: sortedArg "SystemName",
            renderValueFn: \task -> Html.text task.systemName,
            width: None,
        },
        {
            label: "Location",
            name: "Location",
            sorted: sortedArg "Location",
            renderValueFn: \task -> Html.text task.location,
            width: Rem 8,
        },
        {
            label: "File Reference",
            name: "FileReference",
            sorted: sortedArg "FileReference",
            renderValueFn: \task -> Html.text task.fileReference,
            width: None,
        },
        {
            label: "Comments",
            name: "Comments",
            sorted: sortedArg "Comments",
            renderValueFn: \task -> Html.text task.comments,
            width: Rem 20,
        },
    ]

# items is the number of items per page
# page is the current page
# page is 1-indexed
paginationLinks : { page : I64, items : I64, total : I64, baseHref : Str }
    -> List {
        disabled : Bool,
        active : Bool,
        href : Str,
        label : Str,
    }
paginationLinks = \{ page: pageNumber, items, total, baseHref } ->

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
        [prev, current, next]
