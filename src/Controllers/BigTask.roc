module [respond!]

import pf.Http exposing [Request, Response]
import Sql.BigTask
import Views.BigTask
import Views.Bootstrap
import Models.Session exposing [Session]
import Models.BigTask
import Helpers exposing [respond_html, decode_form_values, parse_query_params]

respond! : { req : Request, url_segments : List Str, db_path : Str, session : Session } => Result Response _
respond! = \{ req, url_segments, db_path, session } ->
    # confirm the user is Authenticated, these routes are all protected
    try Models.Session.isAuthenticated session.user

    when (req.method, url_segments) is
        (GET, []) ->
            query_params =
                req.uri
                |> parse_query_params
                |> Result.with_default (Dict.empty {})

            # First check for the updateItemsPerPage form value,
            # if not present then check for the items URL parameter,
            # if not provided default to 25
            items =
                query_params
                |> Dict.get "updateItemsPerPage"
                |> Result.try Str.to_i64
                |> Result.on_err \_ ->
                    query_params
                    |> Dict.get "items"
                    |> Result.try Str.to_i64
                |> Result.with_default 25

            page =
                query_params
                |> Dict.get "page"
                |> Result.try Str.to_i64
                |> Result.with_default 1

            sort_by =
                query_params
                |> Dict.get "sortBy"
                |> Result.with_default "ID"

            sort_direction =
                when Dict.get query_params "sortDirection" is
                    Ok "asc" -> ASCENDING
                    Ok "ASC" -> ASCENDING
                    Ok "desc" -> DESCENDING
                    Ok "DESC" -> DESCENDING
                    _ -> ASCENDING

            tasks = try Sql.BigTask.list! {
                dbPath: db_path,
                page,
                items,
                sortBy: sort_by,
                sortDirection: sort_direction,
            }

            total = try Sql.BigTask.total! { dbPath: db_path }

            sort_direction_str =
                when sort_direction is
                    ASCENDING -> "asc"
                    DESCENDING -> "desc"

            update_url = "/bigTask?page=$(Num.to_str page)&items=$(Num.to_str items)&sortBy=$(sort_by)&sortDirection=$(sort_direction_str)"

            Views.BigTask.page {
                session,
                tasks,
                sortBy: sort_by,
                sortDirection: sort_direction,
                pagination: {
                    page,
                    items,
                    total,
                    baseHref: "/bigTask?",
                },
            }
            |> respond_html [{ name: "HX-Push-Url", value: update_url }]

        (PUT, ["customerId", id_str]) ->
            values = try decode_form_values req.body

            id = try decode_big_task_id id_str

            validation : [None, Valid, Invalid Str]
            validation =
                when Dict.get values "CustomerReferenceID" is
                    Err _ -> None
                    Ok cridstr ->
                        when Str.to_i64 cridstr is
                            Ok i64 if i64 > 0 && i64 < 100000 -> Valid
                            _ -> Invalid "must be a number between 0 and 100,000"

            try update_big_task_only_if_valid! validation { db_path, id, values }

            {
                updateUrl: "/bigTask/customerId/$(id_str)",
                inputs: [{
                    name: "CustomerReferenceID",
                    id: "customer-id-$(id_str)",
                    value: Text (Dict.get values "CustomerReferenceID" |> Result.with_default ""),
                    validation,
                }],
            }
            |> Views.Bootstrap.newDataTableForm
            |> Views.Bootstrap.renderDataTableForm
            |> respond_html []

        (PUT, ["dateCreated", id_str]) ->
            values = try decode_form_values req.body

            id = try decode_big_task_id id_str

            validation : [None, Valid, Invalid Str]
            validation =
                when Dict.get values "DateCreated" is
                    Err _ -> None
                    Ok date_str ->
                        when Models.BigTask.parseDate date_str is
                            Ok _ -> Valid
                            Err _ -> Invalid "must be date format yyyy-mm-dd"

            try update_big_task_only_if_valid! validation { db_path, id, values }

            {
                updateUrl: "/bigTask/dateCreated/$(id_str)",
                inputs: [{
                    name: "DateCreated",
                    id: "date-created-$(id_str)",
                    value: Date (Dict.get values "DateCreated" |> Result.with_default ""),
                    validation,
                }],
            }
            |> Views.Bootstrap.newDataTableForm
            |> Views.Bootstrap.renderDataTableForm
            |> respond_html []

        (PUT, ["status", id_str]) ->
            values = try decode_form_values req.body

            id = try decode_big_task_id id_str

            validation : [None, Valid, Invalid Str]
            validation =
                when Dict.get values "Status" is
                    Err _ -> None
                    Ok status_str ->
                        when Models.BigTask.parseStatus status_str is
                            Ok _ -> Valid
                            Err _ -> Invalid "must be 'Raised|Completed|Deferred|Approved|In-Progress'"

            try update_big_task_only_if_valid! validation { db_path, id, values }

            selected_index =
                try (
                    Dict.get values "Status"
                    |> Result.try \selected -> Models.BigTask.statusOptionIndex selected
                )

            {
                updateUrl: "/bigTask/status/$(id_str)",
                inputs: [{
                    name: "Status",
                    id: "status-$(id_str)",
                    value: Choice {
                        selected: selected_index,
                        options: Models.BigTask.statusOptions,
                    },
                    validation,
                }],
            }
            |> Views.Bootstrap.newDataTableForm
            |> Views.Bootstrap.renderDataTableForm
            |> respond_html []

        (GET, ["downloadCsv"]) ->
            data =
                """
                ID, CustomerReferenceID, DateCreated, Status
                1, 12345, 2021-01-01, Raised
                2, 67890, 2021-01-02, Completed
                3, 54321, 2021-01-03, Deferred
                """
                |> Str.to_utf8

            Ok {
                status: 200,
                headers: [
                    { name: "Content-Type", value: "text/plain" },
                    { name: "Content-Disposition", value: "attachment; filename=table.csv" },
                    { name: "Content-Length", value: "$(List.len data |> Num.to_str)" },
                ],
                body: data,
            }

        _ -> Err (URLNotFound req.uri)

decode_big_task_id : Str -> Result I64 _
decode_big_task_id = \id_str ->
    Str.to_i64 id_str
    |> Result.map_err \_ -> BadRequest (InvalidBigTaskID id_str "expected a valid 64-bit integer")

update_big_task_only_if_valid! : [None, Valid, Invalid Str], { db_path : Str, id : I64, values : Dict Str Str } => Result {} _
update_big_task_only_if_valid! = \validation, { db_path, id, values } ->
    when validation is
        Valid ->
            Sql.BigTask.update! { dbPath: db_path, id, values }
        _ ->
            Ok {}
