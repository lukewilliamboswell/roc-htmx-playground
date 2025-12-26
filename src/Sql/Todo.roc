module [
    list!,
    create!,
    delete!,
    update!,
    tree!,
]

import pf.Sqlite
import Models.Todo exposing [Todo]
import Models.NestedSet exposing [Tree]

list! : { path : Str, filter_query : Str } => Result (List Todo) _
list! = \{ path, filter_query } ->
    if Str.is_empty filter_query then
        Sqlite.query_many! {
            path,
            query: "SELECT id, task, status FROM tasks;",
            bindings: [],
            rows: { Sqlite.decode_record <-
                id: Sqlite.i64 "id",
                task: Sqlite.str "task",
                status: Sqlite.str "status",
            },
        }
    else
        Sqlite.query_many! {
            path,
            query: "SELECT id, task, status FROM tasks WHERE task LIKE :task;",
            bindings: [{ name: ":task", value: String "%$(filter_query)%" }],
            rows: { Sqlite.decode_record <-
                id: Sqlite.i64 "id",
                task: Sqlite.str "task",
                status: Sqlite.str "status",
            },
        }

create! : { path : Str, new_todo : Todo } => Result {} _
create! = \{ path, new_todo } ->
    if Str.is_empty new_todo.task then
        Err TaskWasEmpty
    else
        try Sqlite.execute! {
            path,
            query: "INSERT INTO tasks (task, status) VALUES (:task, :status);",
            bindings: [
                { name: ":task", value: String new_todo.task },
                { name: ":status", value: String new_todo.status },
            ],
        }

        Ok {}

update! : { path : Str, task_id_str : Str, action : [Completed, InProgress] } => Result {} _
update! = \{ path, task_id_str, action } ->
    status_str =
        when action is
            Completed -> "Completed"
            InProgress -> "In-Progress"

    if Str.to_u64 task_id_str |> Result.is_err then
        Err (InvalidTodoID task_id_str)
    else
        try Sqlite.execute! {
            path,
            query: "UPDATE tasks SET status = (:status) WHERE id=:task_id;",
            bindings: [
                { name: ":status", value: String status_str },
                { name: ":task_id", value: String task_id_str },
            ],
        }

        Ok {}

delete! : { path : Str, user_id : Str } => Result {} _
delete! = \{ path, user_id } ->
    try Sqlite.execute! {
        path,
        query: "DELETE FROM tasks WHERE id = :id;",
        bindings: [{ name: ":id", value: String user_id }],
    }

    Ok {}

tree! : { path : Str, user_id : U64 } => Result (Tree Todo) _
tree! = \{ path, user_id } ->
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

    bindings = [{ name: ":user_id", value: String (Num.to_str user_id) }]

    rows = try Sqlite.query_many! {
        path,
        query,
        bindings,
        rows: { Sqlite.decode_record <-
            id: Sqlite.i64 "id",
            task: Sqlite.str "task",
            status: Sqlite.str "status",
            left: Sqlite.i64 "lft",
            right: Sqlite.i64 "rgt",
        },
    }

    nested_set =
        rows
        |> List.map \row -> {
            value: { id: row.id, task: row.task, status: row.status },
            left: row.left,
            right: row.right,
        }

    Ok (Models.NestedSet.nestedSetToTree nested_set)
