
module [
    list,
    get,
    update,
    total,
]

import pf.SQLite3
import Models.BigTask exposing [BigTask]

list : {
    dbPath : Str,
    page : I64,
    items : I64,
    sortBy : Str,
    sortDirection : [ASCENDING, DESCENDING],
} -> Task (List BigTask) _
list = \{dbPath, page, items, sortBy, sortDirection} ->

    check =
        if page >= 1 && items > 0 then
            Task.ok {}
        else
            Task.err (InvalidPageOrItems page items "expected page >= 1 and items > 0")

    check!

    sortDir =
        when sortDirection is
            ASCENDING -> "ASC"
            DESCENDING -> "DESC"

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
        ORDER BY $(parseColumnName sortBy |> Result.withDefault "ID") $(sortDir)
        LIMIT :limit
        OFFSET :offset;
        """

    SQLite3.execute {
        path: dbPath,
        query,
        bindings: [
            {name: ":limit", value: String "$(Num.toStr items)"},
            {name: ":offset", value: String "$(Num.toStr ((page - 1) * items))"},
        ],
    }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.await \rows -> parseListRows rows [] |> Task.fromResult
    |> Task.mapErr ErrGettingBigTasks

total : {dbPath : Str } -> Task I64 _
total = \{dbPath} ->
    SQLite3.execute {
        path: dbPath,
        query: "SELECT COUNT(*) FROM BigTask;",
        bindings: [],
    }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.await \rows ->
        when rows is
            [[Integer count]] -> Task.ok count
            _ -> UnexpectedSQLValues (Inspect.toStr rows) |> Task.err

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
        bindings: [{name: ":id", value: String (Num.toStr id)}],
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
                dateCreated : Models.BigTask.parseDate dateCreatedRaw |> Result.withDefault NotSet,
                dateModified : Models.BigTask.parseDate dateModifiedRaw |> Result.withDefault NotSet,
                title,
                description,
                status : Models.BigTask.parseStatus statusRaw |> Result.withDefault Raised,
                priority : Models.BigTask.parsePriority priorityRaw,
                scheduledStartDate : Models.BigTask.parseDate rawScheduledStartDate |> Result.withDefault NotSet,
                scheduledEndDate : Models.BigTask.parseDate rawScheduledEndDate |> Result.withDefault NotSet,
                actualStartDate : Models.BigTask.parseDate rawActualStartDate |> Result.withDefault NotSet,
                actualEndDate : Models.BigTask.parseDate rawActualEndDate |> Result.withDefault NotSet,
                systemName,
                location,
                fileReference,
                comments,
            })

        _ -> Inspect.toStr rows |> UnexpectedSQLValues |> Err

update : {dbPath : Str, id : I64, values: Dict Str Str} -> Task {} _
update = \{dbPath, id, values} ->

    {sqlStr, bindings} =
        valuesToSql
            values
            [
                "ReferenceID",
                "CustomerReferenceID",
                "DateCreated",
                "DateModified",
                "Title",
                "Description",
                "Status",
                "Priority",
                "ScheduledStartDate",
                "ScheduledEndDate",
                "ActualStartDate",
                "ActualEndDate",
                "SystemName",
                "Location",
                "FileReference",
                "Comments"
            ]

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
        bindings: List.append bindings {name: ":id", value: String (Num.toStr id)},
    }
    |> Task.onErr \err -> Task.err (ErrUpdatingBigTask (SqlError err) query)
    |> Task.await \_ -> Task.ok {}

valuesToSql : Dict Str Str, List Str -> {sqlStr : Str, bindings : List SQLite3.Binding}
valuesToSql = \values, columns ->
    sqlStr =
        Dict.toList values
        |> List.keepIf \(k,_) -> List.contains columns k
        |> List.map \(k,_) ->
            "    $(k) = :$(k)"
        |> Str.joinWith ",\n"

    bindings =
        Dict.toList values
        |> List.keepIf \(k,_) -> List.contains columns k
        |> List.map \(k,v) -> { name: ":$(k)", value : String v}

    {sqlStr, bindings}

#expect
#    a = valuesToSql (Dict.fromList [("A", "foo"), ("B","bar"), ("C", "baz")]) ["A", "B", "C"]
#    a
#    ==
#    {
#        sqlStr :
#            """
#                A = :A,
#                B = :B,
#                C = :C
#            """,
#        bindings : [
#            { name: ":A", value: "foo" },
#            { name: ":B", value: "bar" },
#            { name: ":C", value: "baz" }
#        ]
#    }

## test valuesToSql only includes values for the columns list provided
#expect
#    a = valuesToSql (Dict.fromList [("A", "foo"), ("B","bar"), ("C", "baz")]) ["A"]
#    a
#    ==
#    {
#        sqlStr :
#            """
#                A = :A
#            """,
#        bindings : [
#            { name: ":A", value: Str "foo" }
#        ]
#    }

parseColumnName : Str -> Result _ [InvalidColumnName Str]
parseColumnName = \name ->
    when name is
        "ID" -> Ok "ID"
        "ReferenceID" -> Ok "ReferenceID"
        "CustomerReferenceID" -> Ok "CustomerReferenceID"
        "DateCreated" -> Ok "DateCreated"
        "DateModified" -> Ok "DateModified"
        "Title" -> Ok "Title"
        "Description" -> Ok "Description"
        "Status" -> Ok "Status"
        "Priority" -> Ok "Priority"
        "ScheduledStartDate" -> Ok "ScheduledStartDate"
        "ScheduledEndDate" -> Ok "ScheduledEndDate"
        "ActualStartDate" -> Ok "ActualStartDate"
        "ActualEndDate" -> Ok "ActualEndDate"
        "SystemName" -> Ok "SystemName"
        "Location" -> Ok "Location"
        "FileReference" -> Ok "FileReference"
        "Comments" -> Ok "Comments"
        _ -> InvalidColumnName name |> Err
