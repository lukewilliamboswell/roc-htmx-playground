module [
    find!,
    login!,
    register!,
    list!,
]

import pf.Sqlite
import Models.Session exposing [User]

find! : Str, Str => Result User _
find! = \path, name ->
    rows = try Sqlite.query_many! {
        path,
        query: "SELECT user_id, name, email FROM users WHERE name = :name;",
        bindings: [{ name: ":name", value: String name }],
        rows: { Sqlite.decode_record <-
            id: Sqlite.i64 "user_id",
            name: Sqlite.str "name",
            email: Sqlite.str "email",
        },
    }

    when rows is
        [] -> Err (UserNotFound name)
        [user, ..] -> Ok user

login! : Str, I64, Str => Result {} _
login! = \path, session_id, name ->
    user = try find! path name

    query =
        """
        UPDATE sessions
        SET user_id = :A
        WHERE session_id = :B;
        """

    bindings = [
        { name: ":A", value: String (Num.to_str user.id) },
        { name: ":B", value: String (Num.to_str session_id) },
    ]

    try Sqlite.execute! { path, query, bindings }
    Ok {}

find_user_by_name! : { path : Str, name : Str } => Result User _
find_user_by_name! = \{ path, name } ->
    rows = try Sqlite.query_many! {
        path,
        query: "SELECT user_id, name, email FROM users WHERE name = :name;",
        bindings: [{ name: ":name", value: String name }],
        rows: { Sqlite.decode_record <-
            id: Sqlite.i64 "user_id",
            name: Sqlite.str "name",
            email: Sqlite.str "email",
        },
    }

    when rows is
        [] -> Err UserNotFound
        [user, ..] -> Ok user

register! : { path : Str, name : Str, email : Str } => Result {} _
register! = \{ path, name, email } ->
    when find_user_by_name! { path, name } is
        Err UserNotFound ->
            query =
                """
                INSERT INTO users (name, email)
                VALUES (:name, :email);
                """

            bindings = [
                { name: ":name", value: String name },
                { name: ":email", value: String email },
            ]

            try Sqlite.execute! { path, query, bindings }
            Ok {}

        Ok _user -> Err UserAlreadyExists
        Err err -> Err err

list! : Str => Result (List User) _
list! = \path ->
    Sqlite.query_many! {
        path,
        query: "SELECT user_id, name, email FROM users;",
        bindings: [],
        rows: { Sqlite.decode_record <-
            id: Sqlite.i64 "user_id",
            name: Sqlite.str "name",
            email: Sqlite.str "email",
        },
    }
