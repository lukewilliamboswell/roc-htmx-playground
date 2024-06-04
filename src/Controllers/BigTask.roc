module [respond]

import pf.Task exposing [Task]
import pf.Http exposing [Request, Response]
import Sql.BigTask
import Pages.BigTask
import Bootstrap
import Model
import Helpers exposing [respondHtml, decodeFormValues]

respond : {req : Request, urlSegments : List Str, dbPath : Str, session : Model.Session} -> Task Response _
respond = \{ req, urlSegments, dbPath, session } ->

    # confirm the user is Authenticated, these routes are all protected
    Model.isAuthenticated session |> Task.fromResult!

    when (req.method, urlSegments) is
        (Get, []) ->

            tasks = Sql.BigTask.list! { dbPath }

            Pages.BigTask.view { session, tasks } |> respondHtml

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
                    id : idStr,
                    # use the provided value here so we keep the user's input
                    value : Text (Dict.get values "CustomerReferenceID" |> Result.withDefault ""),
                    validation,
                }],
            }
            |> Bootstrap.newDataTableForm
            |> Bootstrap.renderDataTableForm
            |> respondHtml

        (Put, ["dateCreated", idStr]) ->

            values = decodeFormValues! req.body

            id = decodeBigTaskId! idStr

            validation =
                Dict.get values "DateCreated"
                |> Result.mapErr \_ -> BadRequest (MissingField "DateCreated")
                |> Result.try Model.parseDate
                |> Result.map \_ -> Valid
                |> Result.mapErr \_ -> Invalid "must be date format yyyy-mm-dd"
                |> Task.fromResult!

            updateBigTaskOnlyIfValid! validation {dbPath, id, values}

            {
                updateUrl : "/bigTask/dateCreated/$(idStr)",
                inputs : [{
                    name : "DateCreated",
                    id : idStr,
                    # use the provided value here so we keep the user's input
                    value : Date (Dict.get values "DateCreated" |> Result.withDefault ""),
                    validation,
                }],
            }
            |> Bootstrap.newDataTableForm
            |> Bootstrap.renderDataTableForm
            |> respondHtml

        (Put, ["status", idStr]) ->

            values = decodeFormValues! req.body

            id = decodeBigTaskId! idStr

            validation =
                Dict.get values "Status"
                |> Result.mapErr \_ -> BadRequest (MissingField "Status")
                |> Result.try Model.parseStatus
                |> Result.map \_ -> Valid
                |> Result.mapErr \_ -> Invalid "must be 'Raised|Completed|Deferred|Approved|In-Progress'"
                |> Task.fromResult!

            updateBigTaskOnlyIfValid! validation {dbPath, id, values}

            selectedIndex =
                Dict.get values "Status"
                |> Result.try \selected -> Model.statusOptionIndex selected
                |> Task.fromResult!

            {
                updateUrl : "/bigTask/status/$(idStr)",
                inputs : [{
                    name : "Status",
                    id : idStr,
                    # use the provided value here so we keep the user's input
                    value : Choice {
                        selected: selectedIndex,
                        options: Model.statusOptions
                    },
                    validation,
                }],
            }
            |> Bootstrap.newDataTableForm
            |> Bootstrap.renderDataTableForm
            |> respondHtml

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
