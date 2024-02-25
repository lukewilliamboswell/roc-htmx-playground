interface Sql.Todo
    exposes [
        list,
        create,
        delete,
        update,
        tree,
    ]
    imports [
        pf.Task.{ Task },
        pf.SQLite3,
        Model.{ Todo, Tree, NestedSet },
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

update : {path: Str, taskIdStr: Str, action: [Completed, InProgress]} -> Task {} _
update = \{path, taskIdStr, action} ->

    statusStr = 
        when action is 
            Completed -> "Completed"
            InProgress -> "In-Progress"

    if Str.toU64 taskIdStr |> Result.isErr then
        Task.err (InvalidTodoID taskIdStr)
    else
        SQLite3.execute {
            path,
            query: "UPDATE tasks SET status = (:status) WHERE id=:task_id;",
            bindings: [
                { name: ":status", value: statusStr},
                { name: ":task_id", value: taskIdStr },
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

tree : Str, U64 -> Task (Tree Todo) [SqlError _]_
tree = \path, userId ->

    query =
        """
        SELECT 
            tasks.id,
            tasks.task,
            tasks.status,
            TaskHeirachy.lft,
            TaskHeirachy.rgt
        FROM
            users
            JOIN TaskHeirachy ON users.user_id = TaskHeirachy.user_id
            JOIN tasks ON TaskHeirachy.task_id = tasks.id
        WHERE
            users.user_id = :user_id
        ORDER BY
            TaskHeirachy.lft;
        """

    bindings = [{ name: ":user_id", value: Num.toStr userId }]

    SQLite3.execute {path,query,bindings}
    |> Task.onErr \err -> SqlError err |> Task.err
    |> Task.map \rows -> parseTreeRows rows []

parseTreeRows : List (List SQLite3.Value), List (NestedSet Todo) -> Tree Todo
parseTreeRows = \rows, acc ->
    when rows is 
        [] -> Model.nestedSetToTree acc
        [[Integer id, String task, String status, Integer left, Integer right], .. as rest] -> 
            
            todo : Todo
            todo = { id, task, status }

            parseTreeRows rest (List.append acc {value: todo, left, right})

        _ -> crash "unexpected values returned for getting Todos as a tree, got $(Inspect.toStr rows)"
