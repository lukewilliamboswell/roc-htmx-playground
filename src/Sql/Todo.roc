module [
    list,
    create,
    delete,
    update,
    tree,
]

import pf.SQLite3
import Models.Todo exposing [Todo]
import Models.NestedSet exposing [Tree, NestedSet]

list : { path : Str, filterQuery : Str } -> Task (List Todo) _
list = \{ path, filterQuery } ->

    (query, bindings) =
        if Str.isEmpty filterQuery then
            (
                "SELECT id, task, status FROM tasks;",
                [],
            )
        else
            (
                "SELECT id, task, status FROM tasks WHERE task LIKE :task;",
                [{ name: ":task", value: String "%$(filterQuery)%" }],
            )

    SQLite3.execute { path, query, bindings }
    |> Task.mapErr SqlError
    |> Task.await \rows -> parseListRows rows [] |> Task.fromResult

parseListRows : List (List SQLite3.Value), List Todo -> Result (List Todo) _
parseListRows = \rows, acc ->
    when rows is
        [] -> acc |> Ok
        [[Integer id, String task, String status], .. as rest] ->
            parseListRows rest (List.append acc { id, task, status })

        _ -> Inspect.toStr rows |> UnexpectedSQLValues |> Err

create : { path : Str, newTodo : Todo } -> Task {} [TodoWasEmpty, SqlError _]_
create = \{ path, newTodo } ->
    if Str.isEmpty newTodo.task then
        Task.err TodoWasEmpty
    else
        SQLite3.execute {
            path,
            query: "INSERT INTO tasks (task, status) VALUES (:task, :status);",
            bindings: [
                { name: ":task", value: String (newTodo.task) },
                { name: ":status", value: String (newTodo.status) },
            ],
        }
        |> Task.mapErr SqlError
        |> Task.map \_ -> {}

update : { path : Str, taskIdStr : Str, action : [Completed, InProgress] } -> Task {} _
update = \{ path, taskIdStr, action } ->

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
                { name: ":status", value: String statusStr },
                { name: ":task_id", value: String taskIdStr },
            ],
        }
        |> Task.mapErr SqlError
        |> Task.map \_ -> {}

delete : { path : Str, userId : Str } -> Task {} _
delete = \{ path, userId } ->
    SQLite3.execute {
        path,
        query: "DELETE FROM tasks WHERE id = :id;",
        bindings: [{ name: ":id", value: String userId }],
    }
    |> Task.mapErr SqlError
    |> Task.map \_ -> {}

tree : { path : Str, userId : U64 } -> Task (Tree Todo) _
tree = \{ path, userId } ->

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

    bindings = [{ name: ":user_id", value: String (Num.toStr userId) }]

    SQLite3.execute { path, query, bindings }
    |> Task.mapErr SqlError
    |> Task.await \rows -> parseTreeRows rows [] |> Task.fromResult

parseTreeRows : List (List SQLite3.Value), List (NestedSet Todo) -> Result (Tree Todo) _
parseTreeRows = \rows, acc ->
    when rows is
        [] -> Models.NestedSet.nestedSetToTree acc |> Ok
        [[Integer id, String task, String status, Integer left, Integer right], .. as rest] ->
            todo : Todo
            todo = { id, task, status }

            parseTreeRows rest (List.append acc { value: todo, left, right })

        _ -> Inspect.toStr rows |> UnexpectedSQLValues |> Err
