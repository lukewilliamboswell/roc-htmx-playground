module [
    list!,
    get!,
    update!,
    total!,
]

import pf.Sqlite
import Models.BigTask exposing [BigTask]

list! :
    {
        dbPath : Str,
        page : I64,
        items : I64,
        sortBy : Str,
        sortDirection : [ASCENDING, DESCENDING],
    }
    => Result (List BigTask) _
list! = \{ dbPath, page, items, sortBy, sortDirection } ->
    if page < 1 || items <= 0 then
        Err (InvalidPageOrItems page items "expected page >= 1 and items > 0")
    else
        sort_dir =
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
            ORDER BY $(parse_column_name sortBy |> Result.with_default "ID") $(sort_dir)
            LIMIT :limit
            OFFSET :offset;
            """

        raw_rows = try Sqlite.query_many! {
            path: dbPath,
            query,
            bindings: [
                { name: ":limit", value: String (Num.to_str items) },
                { name: ":offset", value: String (Num.to_str ((page - 1) * items)) },
            ],
            rows: { Sqlite.decode_record <-
                id: Sqlite.i64 "ID",
                referenceId: Sqlite.str "ReferenceID",
                customerReferenceId: Sqlite.str "CustomerReferenceID",
                dateCreatedRaw: Sqlite.str "DateCreated",
                dateModifiedRaw: Sqlite.str "DateModified",
                title: Sqlite.str "Title",
                description: Sqlite.str "Description",
                statusRaw: Sqlite.str "Status",
                priorityRaw: Sqlite.str "Priority",
                scheduledStartDateRaw: Sqlite.str "ScheduledStartDate",
                scheduledEndDateRaw: Sqlite.str "ScheduledEndDate",
                actualStartDateRaw: Sqlite.str "ActualStartDate",
                actualEndDateRaw: Sqlite.str "ActualEndDate",
                systemName: Sqlite.str "SystemName",
                location: Sqlite.str "Location",
                fileReference: Sqlite.str "FileReference",
                comments: Sqlite.str "Comments",
            },
        }

        tasks =
            raw_rows
            |> List.map \row -> {
                id: row.id,
                referenceId: row.referenceId,
                customerReferenceId: row.customerReferenceId,
                dateCreated: Models.BigTask.parseDate row.dateCreatedRaw |> Result.with_default NotSet,
                dateModified: Models.BigTask.parseDate row.dateModifiedRaw |> Result.with_default NotSet,
                title: row.title,
                description: row.description,
                status: Models.BigTask.parseStatus row.statusRaw |> Result.with_default Raised,
                priority: Models.BigTask.parsePriority row.priorityRaw,
                scheduledStartDate: Models.BigTask.parseDate row.scheduledStartDateRaw |> Result.with_default NotSet,
                scheduledEndDate: Models.BigTask.parseDate row.scheduledEndDateRaw |> Result.with_default NotSet,
                actualStartDate: Models.BigTask.parseDate row.actualStartDateRaw |> Result.with_default NotSet,
                actualEndDate: Models.BigTask.parseDate row.actualEndDateRaw |> Result.with_default NotSet,
                systemName: row.systemName,
                location: row.location,
                fileReference: row.fileReference,
                comments: row.comments,
            }

        Ok tasks

total! : { dbPath : Str } => Result I64 _
total! = \{ dbPath } ->
    Sqlite.query! {
        path: dbPath,
        query: "SELECT COUNT(*) as count FROM BigTask;",
        bindings: [],
        row: Sqlite.i64 "count",
    }

get! : { dbPath : Str, id : I64 } => Result BigTask _
get! = \{ dbPath, id } ->
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

    rows = try Sqlite.query_many! {
        path: dbPath,
        query,
        bindings: [{ name: ":id", value: String (Num.to_str id) }],
        rows: { Sqlite.decode_record <-
            id: Sqlite.i64 "ID",
            referenceId: Sqlite.str "ReferenceID",
            customerReferenceId: Sqlite.str "CustomerReferenceID",
            dateCreatedRaw: Sqlite.str "DateCreated",
            dateModifiedRaw: Sqlite.str "DateModified",
            title: Sqlite.str "Title",
            description: Sqlite.str "Description",
            statusRaw: Sqlite.str "Status",
            priorityRaw: Sqlite.str "Priority",
            scheduledStartDateRaw: Sqlite.str "ScheduledStartDate",
            scheduledEndDateRaw: Sqlite.str "ScheduledEndDate",
            actualStartDateRaw: Sqlite.str "ActualStartDate",
            actualEndDateRaw: Sqlite.str "ActualEndDate",
            systemName: Sqlite.str "SystemName",
            location: Sqlite.str "Location",
            fileReference: Sqlite.str "FileReference",
            comments: Sqlite.str "Comments",
        },
    }

    when rows is
        [row] ->
            Ok {
                id: row.id,
                referenceId: row.referenceId,
                customerReferenceId: row.customerReferenceId,
                dateCreated: Models.BigTask.parseDate row.dateCreatedRaw |> Result.with_default NotSet,
                dateModified: Models.BigTask.parseDate row.dateModifiedRaw |> Result.with_default NotSet,
                title: row.title,
                description: row.description,
                status: Models.BigTask.parseStatus row.statusRaw |> Result.with_default Raised,
                priority: Models.BigTask.parsePriority row.priorityRaw,
                scheduledStartDate: Models.BigTask.parseDate row.scheduledStartDateRaw |> Result.with_default NotSet,
                scheduledEndDate: Models.BigTask.parseDate row.scheduledEndDateRaw |> Result.with_default NotSet,
                actualStartDate: Models.BigTask.parseDate row.actualStartDateRaw |> Result.with_default NotSet,
                actualEndDate: Models.BigTask.parseDate row.actualEndDateRaw |> Result.with_default NotSet,
                systemName: row.systemName,
                location: row.location,
                fileReference: row.fileReference,
                comments: row.comments,
            }

        _ -> Err (ErrGettingBigTask id NotFound)

update! : { dbPath : Str, id : I64, values : Dict Str Str } => Result {} _
update! = \{ dbPath, id, values } ->
    { sql_str, bindings } =
        values_to_sql
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
                "Comments",
            ]

    query =
        """
        UPDATE BigTask
        SET
        $(sql_str)
        WHERE ID = :id;
        """

    try Sqlite.execute! {
        path: dbPath,
        query,
        bindings: List.append bindings { name: ":id", value: String (Num.to_str id) },
    }

    Ok {}

values_to_sql : Dict Str Str, List Str -> { sql_str : Str, bindings : List Sqlite.Binding }
values_to_sql = \values, columns ->
    sql_str =
        Dict.to_list values
        |> List.keep_if \(k, _) -> List.contains columns k
        |> List.map \(k, _) ->
            "    $(k) = :$(k)"
        |> Str.join_with ",\n"

    bindings =
        Dict.to_list values
        |> List.keep_if \(k, _) -> List.contains columns k
        |> List.map \(k, v) -> { name: ":$(k)", value: String v }

    { sql_str, bindings }

parse_column_name : Str -> Result Str [InvalidColumnName Str]
parse_column_name = \name ->
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
        _ -> Err (InvalidColumnName name)
