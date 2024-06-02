module [
    list,
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
        FROM
            BigTask;
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
            parseListRows rest (List.append acc {
                id,
                referenceId,
                customerReferenceId,
                dateCreated : Model.parseDate dateCreatedRaw,
                dateModified : Model.parseDate dateModifiedRaw,
                title,
                description,
                status : Model.parseStatus statusRaw,
                priority : Model.parsePriority priorityRaw,
                scheduledStartDate : Model.parseDate rawScheduledStartDate,
                scheduledEndDate : Model.parseDate rawScheduledEndDate,
                actualStartDate : Model.parseDate rawActualStartDate,
                actualEndDate : Model.parseDate rawActualEndDate,
                systemName,
                location,
                fileReference,
                comments,
            })

        _ -> Inspect.toStr rows |> UnexpectedSQLValues |> Err
