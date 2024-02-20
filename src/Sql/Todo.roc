interface Sql.Todo
    exposes [
        list,
        create,
        delete,
        update,
    ]
    imports [
        pf.Task.{ Task },
        pf.SQLite3,
        Model.{ Todo },
    ]

list : Str, Str -> Task (List Todo) [SqlError _]_
list = \path, filterQuery ->

    (query, bindings) =
        if Str.isEmpty filterQuery then
            (
                "SELECT id, task, status FROM tasks;",
                [],
            )
        else
            (
                "SELECT id, task, status FROM tasks WHERE task LIKE :task;",
                [{ name: ":task", value: "%$(filterQuery)%" }],
            )

    rows <-
        SQLite3.execute { path, query, bindings }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.await

    List.map rows \cols ->
        when cols is
            [Integer id, String task, String status] -> { id, task, status }
            _ -> crash "unexpected values returned for get, got $(Inspect.toStr cols)"
    |> Task.ok

create : Str, Todo -> Task {} [TodoWasEmpty, SqlError _]_
create = \path, newTodo ->
    if Str.isEmpty newTodo.task then
        Task.err TodoWasEmpty
    else
        SQLite3.execute {
            path,
            query: "INSERT INTO tasks (task, status) VALUES (:task, :status);",
            bindings: [
                { name: ":task", value: newTodo.task },
                { name: ":status", value: newTodo.status },
            ],
        }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.map \_ -> {}

update : Str, Str -> Task {} [TodoWasEmpty, SqlError _]_
update = \path, idStr ->
    if Str.isEmpty idStr then
        Task.err TodoIdWasEmpty
    else
        SQLite3.execute {
            path,
            query: "UPDATE tasks SET status = (:status) WHERE id=:id;",
            bindings: [
                { name: ":status", value: "Completed" },
                { name: ":id", value: idStr },

            ],
        }
        |> Task.onErr \err -> SqlError err |> Task.err
        |> Task.map \_ -> {}

delete : Str, Str -> Task {} [SqlError _]_
delete = \path, idStr ->
    SQLite3.execute {
        path,
        query: "DELETE FROM tasks WHERE id = :id;",
        bindings: [{ name: ":id", value: idStr }],
    }
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.map \_ -> {}

