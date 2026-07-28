import pf.Sqlite

import Todo
import User

## Concrete SQLite adapter satisfying Todo's caller-local `insert!` constraint
## as well as the feature's read and mutation operations.
TodoStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> TodoStore
	new = |db| TodoStore.{ db }

	list! : TodoStore, Str => Try(List(Todo), [InvalidStoredStatus(Str), DbErr(Sqlite.QueryError)])
	list! = |store, filter| {
		pattern = "%${filter}%"
		result = Sqlite.query_many!({
			db: store.db,
			query: "SELECT id, task, status FROM tasks WHERE task LIKE :pattern ORDER BY id;",
			params: {
				pattern: pattern,
			},
			limits: Sqlite.default_query_limits,
		})
		match result {
			Err(err) => Err(DbErr(err))
			Ok(rows) => decode_rows(rows)
		}
	}

	insert! : TodoStore, Todo.New => Try({}, [DbErr(Sqlite.QueryError)])
	insert! = |store, new_todo| {
		Sqlite.execute!({
			db: store.db,
			query: "INSERT INTO tasks (task, status) VALUES (:task, :status);",
			params: {
				task: new_todo.task.to_str(),
				status: new_todo.status.to_str(),
			},
		}) ? DbErr
		Ok({})
	}

	update_status! : TodoStore, Todo.Id, Todo.Status => Try({}, Sqlite.QueryError)
	update_status! = |store, id, status|
		Sqlite.execute!({
			db: store.db,
			query: "UPDATE tasks SET status = :status WHERE id = :id;",
			params: { id: id.to_i64(), status: status.to_str() },
		})

	delete! : TodoStore, Todo.Id => Try({}, Sqlite.QueryError)
	delete! = |store, id|
		Sqlite.execute!({
			db: store.db,
			query: "DELETE FROM tasks WHERE id = :id;",
			params: { id: id.to_i64() },
		})

	tree! : TodoStore, User.Id => Try(Todo.Tree(Todo), [InvalidStoredStatus(Str), DbErr(Sqlite.QueryError)])
	tree! = |store, user_id| {
		result = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT t.id, t.task, t.status, h.lft AS "left", h.rgt AS "right"
				\\FROM TaskHeirachy AS h
				\\JOIN tasks AS t ON h.task_id = t.id
				\\WHERE h.user_id = :userId
				\\ORDER BY h.lft;
				,
			),
			params: { userId: user_id.to_i64() },
			limits: Sqlite.default_query_limits,
		})
		match result {
			Err(err) => Err(DbErr(err))
			Ok(rows) =>
				match decode_nested_rows(rows) {
					Err(err) => Err(err)
					Ok(nested) => Ok(Todo.nested_set_to_tree(nested))
				}
			}
	}

}

decode_rows : List({ id : I64, task : Str, status : Str }) -> Try(List(Todo), [InvalidStoredStatus(Str), ..])
decode_rows = |rows|
	match rows {
		[] => Ok([])
		[row, .. as rest] =>
			match Todo.from_storage(row.id, row.task, row.status) {
				Err(InvalidTodoStatus(status)) => Err(InvalidStoredStatus(status))
				Ok(todo) =>
					match decode_rows(rest) {
						Err(err) => Err(err)
						Ok(todos) => Ok(todos.prepend(todo))
					}
				}
		}

decode_nested_rows : List({ id : I64, task : Str, status : Str, left : I64, right : I64 }) -> Try(List(Todo.NestedSetItem(Todo)), [InvalidStoredStatus(Str), ..])
decode_nested_rows = |rows|
	match rows {
		[] => Ok([])
		[row, .. as rest] =>
			match Todo.from_storage(row.id, row.task, row.status) {
				Err(InvalidTodoStatus(status)) => Err(InvalidStoredStatus(status))
				Ok(todo) =>
					match decode_nested_rows(rest) {
						Err(err) => Err(err)
						Ok(items) =>
							Ok(
								items.prepend(
									Todo.NestedSetItem.{
										value: todo,
										left: row.left,
										right: row.right,
									},
								),
							)
						}
				}
		}
