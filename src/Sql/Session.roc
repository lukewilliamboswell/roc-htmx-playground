module [
    new!,
    parse,
    get!,
]

import pf.Http exposing [Request]
import pf.Sqlite
import Models.Session exposing [Session]

new! : Str => Result I64 _
new! = \path ->
    query = "INSERT INTO sessions (session_id) VALUES (abs(random()));"

    try Sqlite.execute! {
        path,
        query,
        bindings: [],
    }

    id = try Sqlite.query! {
        path,
        query: "SELECT last_insert_rowid() as id;",
        bindings: [],
        row: Sqlite.i64 "id",
    }

    Ok id

parse : Request -> Result I64 [NoSessionCookie, InvalidSessionCookie]
parse = \req ->
    when req.headers |> List.keep_if \req_header -> req_header.name == "cookie" is
        [req_header] ->
            req_header.value
            |> Str.split_on "="
            |> List.get 1
            |> Result.try Str.to_i64
            |> Result.map_err \_ -> InvalidSessionCookie

        _ -> Err NoSessionCookie

get! : I64, Str => Result Session _
get! = \session_id, path ->
    not_found_str = "NOT_FOUND"

    query =
        """
        SELECT
            sessions.session_id AS 'session_id',
            COALESCE(users.name,'$(not_found_str)') AS 'username'
        FROM sessions
        LEFT OUTER JOIN users
        ON sessions.user_id = users.user_id
        WHERE sessions.session_id = :sessionId;
        """

    bindings = [{ name: ":sessionId", value: String (Num.to_str session_id) }]

    rows = try Sqlite.query_many! {
        path,
        query,
        bindings,
        rows: { Sqlite.decode_record <-
            id: Sqlite.i64 "session_id",
            username: Sqlite.str "username",
        },
    }

    when rows is
        [] -> Err SessionNotFound
        [{ id, username }, ..] ->
            if username == not_found_str then
                Ok { id, user: Guest }
            else
                Ok { id, user: LoggedIn username }
