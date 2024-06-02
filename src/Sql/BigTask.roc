module [
    list,
]

import pf.Task exposing [Task]
import pf.SQLite3
import Model exposing [BigTask, Date]

#Date : [NotSet, Simple {year : I64,month : I64,day : I64}]

#BigTask : {
#    id : I64,
#    referenceId : Str,
#    customerReferenceId : Str,
#    dateCreated : Date,
#    dateModified : Date,
#    title : Str,
#    description : Str,
#    status : Str,
#    priority : Str,
#    scheduledStartDate : Date,
#    scheduledEndDate : Date,
#    actualStartDate : Date,
#    actualEndDate : Date,
#    systemName : Str,
#    location : Str,
#    fileReference : Str,
#    comments : Str,
#}

list : Str, Str -> Task User _
list = \path, name ->

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
        path,
        query,
        bindings: [],
    }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.await \rows ->
        when rows is
            [] -> Task.err (UserNotFound name)
            [[Integer id, String _, String email], ..] -> Task.ok { id, name, email }
            _ -> Task.err (UnexpectedValues "got $(Inspect.toStr rows)")

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
