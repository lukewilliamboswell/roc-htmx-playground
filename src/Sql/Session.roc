module [
    new,
    parse,
    get,
]

import pf.Task exposing [Task]
import pf.Http exposing [Request]
import pf.SQLite3
import Model exposing [Session]

new : Str -> Task I64 _
new = \path ->

    _ <-
        SQLite3.execute { path, query: "INSERT INTO sessions (session_id) VALUES (abs(random()));", bindings: [] }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    rows <-
        SQLite3.execute { path, query: "SELECT last_insert_rowid();", bindings: [] }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    when rows is
        [] -> Task.err NoRows
        [[Integer id], ..] -> Task.ok id
        _ -> Task.err (UnexpectedValues "unexpected values in new Session, got $(Inspect.toStr rows)")

parse : Request -> Result I64 {}
parse = \req ->
    req.headers
    |> List.keepIf \reqHeader -> reqHeader.name == "cookie"
    |> List.first
    |> Result.mapErr \_ -> {}
    |> Result.try \reqHeader ->
        reqHeader.value
        |> Str.fromUtf8
        |> Result.try \str -> str |> Str.split "=" |> List.get 1
        |> Result.try Str.toI64
        |> Result.mapErr \_ -> {}

get : Result I64 {}, Str -> Task Session _
get = \maybeSessionId, path ->

    notFoundStr = "NOT_FOUND"

    # we take a result and unwrap here to simplify the use of this function
    sessionId <-
        maybeSessionId
        |> Task.fromResult
        |> Task.mapErr \_ -> SessionNotFound
        |> Task.await

    query =
        """
        SELECT sessions.session_id AS \"notUsed\", COALESCE(users.name,'$(notFoundStr)') AS \"username\" 
        FROM sessions
        LEFT OUTER JOIN users
        ON sessions.user_id = users.user_id
        WHERE sessions.session_id = :sessionId;
        """

    bindings = [{ name: ":sessionId", value: Num.toStr sessionId }]

    rows <-
        SQLite3.execute { path, query, bindings }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    when rows is
        [] -> Task.err SessionNotFound
        [[Integer id, String username], ..] ->
            if username == notFoundStr then
                Task.ok { id, user: Guest }
            else
                Task.ok { id, user: LoggedIn username }

        _ -> Task.err (UnexpectedValues "unexpected values in get Session, got $(Inspect.toStr rows)")
