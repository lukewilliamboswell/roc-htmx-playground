interface Sql.User
    exposes [
        find,
        login,
    ]
    imports [
        pf.Task.{ Task },
        pf.SQLite3,
        Model.{ User },
    ]

find : Str, Str -> Task User _
find = \path, name ->

    rows <-
        SQLite3.execute {
            path,
            query: "SELECT user_id as userId FROM users WHERE name = :name;",
            bindings: [{ name: ":name", value: name }],
        }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    rows
    |> List.map \cols ->
        when cols is
            [Integer id] -> { id, name }
            _ -> crash "unexpected values returned, got $(Inspect.toStr cols)"
    |> List.first
    |> Task.fromResult
    |> Task.mapErr \err ->
        when err is
            ListWasEmpty -> UserNotFound name
            _ -> MultipleUsersFound

login : Str, I64, Str -> Task {} _
login = \path, sessionId, name ->

    user <- find path name |> Task.await

    query =
        """
        UPDATE sessions
        SET user_id = :A
        WHERE session_id = :B;
        """

    bindings = [
        { name: ":A", value: Num.toStr user.id },
        { name: ":B", value: Num.toStr sessionId },
    ]

    SQLite3.execute { path, query, bindings }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.map \_ -> {}
