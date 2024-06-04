
module [
    list,
    get,
    update,
]

import pf.Task exposing [Task]
import pf.SQLite3
import Model exposing [BigTask]

list : {dbPath : Str } -> Task (List BigTask) _
list = \{dbPath} ->

    query =
        """
        SELECT
            ID,
            ReferenceID,
            CustomerReferenceID,
            DateCreated,
            DateModified,
            Title,
            Description,
            Status,
            Priority,
            ScheduledStartDate,
            ScheduledEndDate,
            ActualStartDate,
            ActualEndDate,
            SystemName,
            Location,
            FileReference,
            Comments
        FROM BigTask
        ORDER BY ID
        LIMIT 10 OFFSET 0;
        """

    SQLite3.execute {
        path: dbPath,
        query,
        bindings: [],
    }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.await \rows -> parseListRows rows [] |> Task.fromResult
    |> Task.mapErr ErrGettingBigTasks

get : {dbPath : Str, id : I64} -> Task BigTask _
get = \{dbPath, id} ->

    query =
        """
        SELECT
            ID,
            ReferenceID,
            CustomerReferenceID,
            DateCreated,
            DateModified,
            Title,
            Description,
            Status,
            Priority,
            ScheduledStartDate,
            ScheduledEndDate,
            ActualStartDate,
            ActualEndDate,
            SystemName,
            Location,
            FileReference,
            Comments
        FROM BigTask
        WHERE ID = :id;
        """

    SQLite3.execute {
        path: dbPath,
        query,
        bindings: [{name: ":id", value: Num.toStr id}],
    }
    |> Task.onErr \err -> Task.err (ErrGettingBigTask id (SqlError err))
    |> Task.await \rows ->
        when parseListRows rows [] is
            Ok [task] -> Task.ok task
            _ -> Task.err (ErrGettingBigTask id (UnexpectedSQLValues (Inspect.toStr rows)))

parseListRows : List (List SQLite3.Value), List BigTask -> Result (List BigTask) _
parseListRows = \rows, acc ->
    when rows is
        [] -> acc |> Ok
        [[
            Integer id,
            String referenceId,
            String customerReferenceId,
            String dateCreatedRaw,
            String dateModifiedRaw,
            String title,
            String description,
            String statusRaw,
            String priorityRaw,
            String rawScheduledStartDate,
            String rawScheduledEndDate,
            String rawActualStartDate,
            String rawActualEndDate,
            String systemName,
            String location,
            String fileReference,
            String comments
        ], .. as rest] ->

            # TODO we should do better than using Result.withDefault here

            parseListRows rest (List.append acc {
                id,
                referenceId,
                customerReferenceId,
                dateCreated : Model.parseDate dateCreatedRaw |> Result.withDefault NotSet,
                dateModified : Model.parseDate dateModifiedRaw |> Result.withDefault NotSet,
                title,
                description,
                status : Model.parseStatus statusRaw |> Result.withDefault Raised,
                priority : Model.parsePriority priorityRaw,
                scheduledStartDate : Model.parseDate rawScheduledStartDate |> Result.withDefault NotSet,
                scheduledEndDate : Model.parseDate rawScheduledEndDate |> Result.withDefault NotSet,
                actualStartDate : Model.parseDate rawActualStartDate |> Result.withDefault NotSet,
                actualEndDate : Model.parseDate rawActualEndDate |> Result.withDefault NotSet,
                systemName,
                location,
                fileReference,
                comments,
            })

        _ -> Inspect.toStr rows |> UnexpectedSQLValues |> Err

update : {dbPath : Str, id : I64, values: Dict Str Str} -> Task {} _
update = \{dbPath, id, values} ->

    {sqlStr, bindings} = valuesToSql values

    query =
        """
        UPDATE BigTask
        SET
        $(sqlStr)
        WHERE ID = :id;
        """

    SQLite3.execute {
        path: dbPath,
        query,
        bindings: List.append bindings {name: ":id", value: Num.toStr id},
    }
    |> Task.onErr \err -> Task.err (ErrUpdatingBigTask (SqlError err) query)
    |> Task.await \_ -> Task.ok {}

valuesToSql : Dict Str Str -> {sqlStr : Str, bindings : List SQLite3.Binding}
valuesToSql = \values ->
    sqlStr =
        Dict.toList values
        |> List.map \(k,_) ->
            "    $(k) = :$(k)"
        |> Str.joinWith ",\n"

    bindings =
        Dict.toList values
        |> List.map \(k,v) -> { name: ":$(k)", value : v}

    {sqlStr, bindings}

expect
    a = valuesToSql (Dict.fromList [("A", "foo"), ("B","bar"), ("C", "baz")])
    a
    ==
    {
        sqlStr :
            """
                A = :A,
                B = :B,
                C = :C
            """,
        bindings : [
            { name: ":A", value: "foo" },
            { name: ":B", value: "bar" },
            { name: ":C", value: "baz" }
        ]
    }
