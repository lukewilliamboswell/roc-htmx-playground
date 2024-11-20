module [respond]

import pf.Http exposing [Request, Response]
import Sql.BigTask
import Views.BigTask
import Views.Bootstrap
import Models.Session exposing [Session]
import Models.BigTask
import Helpers exposing [respondHtml, decodeFormValues, parseQueryParams]

respond : {req : Request, urlSegments : List Str, dbPath : Str, session : Session} -> Task Response _
respond = \{ req, urlSegments, dbPath, session } ->

    # confirm the user is Authenticated, these routes are all protected
    Models.Session.isAuthenticated session.user |> Task.fromResult!

    when (req.method, urlSegments) is
        (Get, []) ->

            queryParams =
                    req.url
                    |> parseQueryParams
                    |> Result.withDefault (Dict.empty {})

            # First check for the updateItemsPerPage form value,
            # if not present then check for the items URL parameter,
            # if not provided default to 25
            items =
                queryParams
                |> Dict.get "updateItemsPerPage"
                |> Result.try Str.toI64
                |> Result.onErr \_ ->
                    queryParams
                    |> Dict.get "items"
                    |> Result.try Str.toI64
                |> Result.withDefault 25

            page =
                queryParams
                |> Dict.get "page"
                |> Result.try Str.toI64
                |> Result.withDefault 1

            sortBy =
                queryParams
                |> Dict.get "sortBy"
                |> Result.withDefault "ID"

            sortDirection =
                when Dict.get queryParams "sortDirection" is
                    Ok "asc" -> ASCENDING
                    Ok "ASC" -> ASCENDING
                    Ok "desc" -> DESCENDING
                    Ok "DESC" -> DESCENDING
                    _ -> ASCENDING

            tasks = Sql.BigTask.list! {
                dbPath,
                page,
                items,
                sortBy,
                sortDirection,
            }

            total = Sql.BigTask.total! { dbPath }

            sortDirectionStr =
                when sortDirection is
                    ASCENDING -> "asc"
                    DESCENDING -> "desc"

            updateURL = "/bigTask?page=$(Num.toStr page)&items=$(Num.toStr items)&sortBy=$(sortBy)&sortDirection=$(sortDirectionStr)"

            Views.BigTask.page {
                session,
                tasks,
                sortBy,
                sortDirection,
                pagination : {
                    page,
                    items,
                    total,
                    baseHref: "/bigTask?",
                },
            }
            |> respondHtml [{name : "HX-Push-Url", value : updateURL}]

        (Put, ["customerId", idStr]) ->

            values = decodeFormValues! req.body

            id = decodeBigTaskId! idStr

            validation =
                Dict.get values "CustomerReferenceID"
                |> Result.mapErr \_ -> BadRequest (MissingField "CustomerReferenceID")
                |> Result.try \cridstr ->
                    when Str.toI64 cridstr is
                        # just an example... just check it's in range 0-100,000
                        Ok i64 if i64 > 0 && i64 < 100000 -> Ok Valid
                        _ -> Ok (Invalid "must be a number between 0 and 100,000")
                |> Task.fromResult!

            updateBigTaskOnlyIfValid! validation {dbPath, id, values}

            {
                updateUrl : "/bigTask/customerId/$(idStr)",
                inputs : [{
                    name : "CustomerReferenceID",
                    id : "customer-id-$(idStr)",
                    # use the provided value here so we keep the user's input
                    value : Text (Dict.get values "CustomerReferenceID" |> Result.withDefault ""),
                    validation,
                }],
            }
            |> Views.Bootstrap.newDataTableForm
            |> Views.Bootstrap.renderDataTableForm
            |> respondHtml []

        (Put, ["dateCreated", idStr]) ->

            values = decodeFormValues! req.body

            id = decodeBigTaskId! idStr

            validation =
                Dict.get values "DateCreated"
                |> Result.mapErr \_ -> BadRequest (MissingField "DateCreated")
                |> Result.try Models.BigTask.parseDate
                |> Result.map \_ -> Valid
                |> Result.mapErr \_ -> Invalid "must be date format yyyy-mm-dd"
                |> Task.fromResult!

            updateBigTaskOnlyIfValid! validation {dbPath, id, values}

            {
                updateUrl : "/bigTask/dateCreated/$(idStr)",
                inputs : [{
                    name : "DateCreated",
                    id : "date-created-$(idStr)",
                    # use the provided value here so we keep the user's input
                    value : Date (Dict.get values "DateCreated" |> Result.withDefault ""),
                    validation,
                }],
            }
            |> Views.Bootstrap.newDataTableForm
            |> Views.Bootstrap.renderDataTableForm
            |> respondHtml []

        (Put, ["status", idStr]) ->

            values = decodeFormValues! req.body

            id = decodeBigTaskId! idStr

            validation =
                Dict.get values "Status"
                |> Result.mapErr \_ -> BadRequest (MissingField "Status")
                |> Result.try Models.BigTask.parseStatus
                |> Result.map \_ -> Valid
                |> Result.mapErr \_ -> Invalid "must be 'Raised|Completed|Deferred|Approved|In-Progress'"
                |> Task.fromResult!

            updateBigTaskOnlyIfValid! validation {dbPath, id, values}

            selectedIndex =
                Dict.get values "Status"
                |> Result.try \selected -> Models.BigTask.statusOptionIndex selected
                |> Task.fromResult!

            {
                updateUrl : "/bigTask/status/$(idStr)",
                inputs : [{
                    name : "Status",
                    id : "status-$(idStr)",
                    # use the provided value here so we keep the user's input
                    value : Choice {
                        selected: selectedIndex,
                        options: Models.BigTask.statusOptions
                    },
                    validation,
                }],
            }
            |> Views.Bootstrap.newDataTableForm
            |> Views.Bootstrap.renderDataTableForm
            |> respondHtml []

        (Get, ["downloadCsv"]) ->

            data =
                """
                ID, CustomerReferenceID, DateCreated, Status
                1, 12345, 2021-01-01, Raised
                2, 67890, 2021-01-02, Completed
                3, 54321, 2021-01-03, Deferred
                """
                |> Str.toUtf8

            Task.ok {
                status: 200u16,
                headers: [
                    { name: "Content-Type", value: "text/plain" },
                    { name: "Content-Disposition", value: "attachment; filename=table.csv" },
                    { name: "Content-Length", value: "$(List.len data |> Num.toStr)" },
                ],
                body: data,
            }

        _ -> Task.err (URLNotFound req.url)

decodeBigTaskId = \idStr ->
    Str.toI64 idStr
    |> Result.mapErr \_ -> BadRequest (InvalidBigTaskID idStr "expected a valid 64-bit integer")
    |> Task.fromResult

updateBigTaskOnlyIfValid = \validation, {dbPath, id, values} ->
    if validation == Valid then
        Sql.BigTask.update {dbPath, id, values}
    else
        Task.ok {}
