
module [
    new,
    parse,
    get,
]

import pf.Task exposing [Task]
import pf.Http exposing [Request]
import pf.SQLite3
import Models.Session exposing [Session]

new : Str -> Task I64 _
new = \path ->

    query =
        """
        INSERT INTO sessions (session_id) VALUES (abs(random()));
        """

    _ <-
        SQLite3.execute { path, query, bindings: [] }
        |> Task.mapErr \err -> SqlError err
        |> Task.await

    rows =
        SQLite3.execute { path, query: "SELECT last_insert_rowid();", bindings: [] }
        |> Task.onErr! \err -> SqlError err |> Task.err

    when rows is
        [] -> Task.err NoRows
        [[Integer id], ..] -> Task.ok id
        _ -> Task.err (UnexpectedValues "unexpected values in new Session, got $(Inspect.toStr rows)")

parse : Request -> Result I64 [NoSessionCookie, InvalidSessionCookie]
parse = \req ->
    when req.headers |> List.keepIf \reqHeader -> reqHeader.name == "cookie" is
        [reqHeader] ->
            reqHeader.value
            |> \str -> str |> Str.split "=" |> List.get 1
            |> Result.try Str.toI64
            |> Result.mapErr \_ -> InvalidSessionCookie
        _ -> Err NoSessionCookie

get : I64, Str -> Task Session _
get = \sessionId, path ->

    notFoundStr = "NOT_FOUND"

    query =
        """
        SELECT
            sessions.session_id AS 'notUsed',
            COALESCE(users.name,'$(notFoundStr)') AS 'username'
        FROM sessions
        LEFT OUTER JOIN users
        ON sessions.user_id = users.user_id
        WHERE sessions.session_id = :sessionId;
        """

    bindings = [{ name: ":sessionId", value: Integer sessionId }]

    rows = SQLite3.execute { path, query, bindings } |> Task.mapErr! SqlErrGettingSession

    when rows is
        [] -> Task.err SessionNotFound
        [[Integer id, String username], ..] ->
            if username == notFoundStr then
                Task.ok { id, user: Guest }
            else
                Task.ok { id, user: LoggedIn username }

        _ -> Task.err (UnexpectedValues "unexpected values in get Session, got $(Inspect.toStr rows)")
