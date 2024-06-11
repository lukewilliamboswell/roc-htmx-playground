module [respond]

import pf.Task exposing [Task]
import pf.Http exposing [Request, Response]
import pf.Stdout
import Sql.BigTask
import Views.BigTask
import Views.Bootstrap
import Models.Session exposing [Session]
import Models.BigTask
import Helpers exposing [respondHtml, decodeFormValues]

respond : {req : Request, urlSegments : List Str, dbPath : Str, session : Session} -> Task Response _
respond = \{ req, urlSegments, dbPath, session } ->

    # confirm the user is Authenticated, these routes are all protected
    Models.Session.isAuthenticated session.user |> Task.fromResult!

    when (req.method, urlSegments) is
        (Get, []) ->

            Stdout.line! "GOT SESISON IN CONTROLLER: $(Inspect.toStr session)"

            tasks = Sql.BigTask.list! {
                dbPath,
                page: Num.toI64 1,
                items: Num.toI64 25,
            }

            total = Sql.BigTask.total! { dbPath }

            Views.BigTask.page {
                session,
                tasks,
                pagination : {
                    page: Num.toI64 1,
                    items: Num.toI64 25,
                    total,
                    baseHref: "/bigTask?",
                },
            }
            |> respondHtml

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
            |> respondHtml

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
            |> respondHtml

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
            |> respondHtml

        (Post, ["dataTable", "itemsPerPage"]) ->

            #values = decodeFormValues! req.body

            #itemsPerPage =
            #    values
            #    |> Dict.get "itemsPerPage"
            #    |> Result.try Str.toU64
            #    |> Result.mapErr \_ -> BadRequest (ExpectedFormValue "itemsPerPage" req.body)
            #    |> Task.fromResult!

            #newSession = { session }

            Task.err TodoDataTableItemsPerPage

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
