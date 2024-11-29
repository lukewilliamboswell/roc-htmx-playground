module [
    find,
    login,
    register,
    list,
]

import pf.SQLite3
import Models.Session exposing [User]

find : Str, Str -> Task User _
find = \path, name ->
    SQLite3.execute {
        path,
        query: "SELECT user_id as userId, name, email FROM users WHERE name = :name;",
        bindings: [{ name: ":name", value: String name }],
    }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.await \rows ->
        when rows is
            [] -> Task.err (UserNotFound name)
            [[Integer id, String _, String email], ..] -> Task.ok { id, name, email }
            _ -> Task.err (UnexpectedValues "got $(Inspect.toStr rows)")

login : Str, I64, Str -> Task {} _
login = \path, sessionId, name ->

    user = find! path name

    query =
        """
        UPDATE sessions
        SET user_id = :A
        WHERE session_id = :B;
        """

    bindings = [
        { name: ":A", value: String (Num.toStr user.id) },
        { name: ":B", value: String (Num.toStr sessionId) },
    ]

    SQLite3.execute { path, query, bindings }
    |> Task.mapErr SqlError
    |> Task.map \_ -> {}

findUserByName : { path : Str, name : Str } -> Task User _
findUserByName = \{ path, name } ->
    SQLite3.execute {
        path,
        query: "SELECT user_id as userId, name, email FROM users WHERE name = :name;",
        bindings: [{ name: ":name", value: String name }],
    }
    |> Task.mapErr SqlError
    |> Task.await \rows ->
        when rows is
            [] -> Task.err UserNotFound
            [[Integer id, String _, String email], ..] -> Task.ok { id, name: name, email }
            _ -> Task.err (UnexpectedValues "got $(Inspect.toStr rows)")

register : { path : Str, name : Str, email : Str } -> Task {} _
register = \{ path, name, email } ->

    ## Check if name exists
    findUserByName { path, name }
    |> Task.attempt \userExists ->
        when userExists is
            Err UserNotFound ->
                ## Insert new user
                query =
                    """
                    INSERT INTO users (name, email)
                    VALUES (:name, :email);
                    """

                bindings = [
                    { name: ":name", value: String name },
                    { name: ":email", value: String email },
                ]

                SQLite3.execute { path, query, bindings }
                |> Task.mapErr SqlError
                |> Task.map \_ -> {}

            Ok _user -> UserAlreadyExists |> Task.err
            Err err -> Task.err err

list : Str -> Task (List User) _
list = \path ->
    SQLite3.execute {
        path,
        query: "SELECT user_id as userId, name, email FROM users;",
        bindings: [],
    }
    |> Task.mapErr SqlError
    |> Task.await \rows -> parseListRows rows [] |> Task.fromResult

parseListRows : List (List SQLite3.Value), List User -> Result (List User) _
parseListRows = \rows, acc ->
    when rows is
        [] -> acc |> Ok
        [[Integer id, String name, String email], .. as rest] ->
            parseListRows rest (List.append acc { id, name, email })

        _ -> Inspect.toStr rows |> UnexpectedSQLValues |> Err
