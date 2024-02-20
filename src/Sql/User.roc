interface Sql.User
    exposes [
        find,
        login,
        register,
        list,
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
            query: "SELECT user_id as userId, name, email FROM users WHERE name = :name;",
            bindings: [{ name: ":name", value: name }],
        }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    when rows is
        [] -> Task.err (UserNotFound name)
        [[Integer id, String _, String email], ..] -> Task.ok { id, name, email }
        _ -> Task.err (UnexpectedValues "got $(Inspect.toStr rows)")

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

findUserByName : { path : Str, name : Str } -> Task User _
findUserByName = \{ path, name } ->

    rows <-
        SQLite3.execute {
            path,
            query: "SELECT user_id as userId, name, email FROM users WHERE name = :name;",
            bindings: [{ name: ":name", value: name }],
        }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    when rows is
        [] -> Task.err UserNotFound
        [[Integer id, String _, String email], ..] -> Task.ok { id, name: name, email }
        _ -> Task.err (UnexpectedValues "got $(Inspect.toStr rows)")

register : { path : Str, name : Str, email : Str } -> Task {} _
register = \{ path, name, email } ->

    ## Check if name exists
    userExists <- findUserByName { path, name } |> Task.attempt

    when userExists is
        Err UserNotFound ->
            ## Insert new user
            query =
                """
                INSERT INTO users (name, email)
                VALUES (:name, :email);
                """

            bindings = [
                { name: ":name", value: name },
                { name: ":email", value: email },
            ]

            SQLite3.execute { path, query, bindings }
            |> Task.onErr \err -> SqlError err |> Task.err
            |> Task.map \_ -> {}

        Ok user -> UserAlreadyExists |> Task.err
        Err err -> Task.err err

list : Str -> Task (List User) _
list = \path ->

    rows <-
        SQLite3.execute {
            path,
            query: "SELECT user_id as userId, name, email FROM users;",
            bindings: [],
        }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    rows
    |> List.keepOks \row ->
        when row is
            [Integer id, String name, String email] -> Ok { id, name, email }
            _ -> Err {}
    |> Task.ok
