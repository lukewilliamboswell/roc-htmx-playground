import pf.Sqlite

import Models

Db := [].{
	newSession! : Sqlite.Db => Try(I64, Sqlite.QueryError)
	newSession! = |db| {
		row : { id : I64 }
		row = Sqlite.query!({
			db,
			query: "INSERT INTO sessions (user_id) VALUES (NULL) RETURNING session_id AS id;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(row.id)
	}

	getSession! : Sqlite.Db, I64 => Try(Models.Session, [SessionNotFound, DbErr(Sqlite.QueryError)])
	getSession! = |db, id| {
		rows : List({ id : I64, username : Str })
		rows = Sqlite.query_many!({
			db,
			query: "SELECT s.session_id AS id, IFNULL(u.name, '') AS username FROM sessions AS s LEFT JOIN users AS u ON s.user_id = u.user_id WHERE s.session_id = :id;",
			params: { id: id },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		match rows {
			[] => Err(SessionNotFound)
			[row, ..] =>
				if Str.is_empty(row.username) {
					Ok({ id: row.id, user: Guest })
				} else {
					Ok({ id: row.id, user: LoggedIn(row.username) })
				}
			}
	}

	registerUser! : Sqlite.Db, Str, Str => Try({}, [UserAlreadyExists, DbErr(Sqlite.QueryError)])
	registerUser! = |db, name, email| {
		existing : List({ id : I64 })
		existing = Sqlite.query_many!({
			db,
			query: "SELECT user_id AS id FROM users WHERE name = :name;",
			params: { name: name },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		if existing.is_empty() {
			Sqlite.execute!({
				db,
				query: "INSERT INTO users (name, email) VALUES (:name, :email);",
				params: { name: name, email: email },
			}) ? DbErr
			Ok({})
		} else {
			Err(UserAlreadyExists)
		}
	}

	login! : Sqlite.Db, I64, Str => Try({}, [UserNotFound, DbErr(Sqlite.QueryError)])
	login! = |db, sessionId, name| {
		users : List({ id : I64 })
		users = Sqlite.query_many!({
			db,
			query: "SELECT user_id AS id FROM users WHERE name = :name;",
			params: { name: name },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		match users {
			[] => Err(UserNotFound)
			[user, ..] => {
				Sqlite.execute!({
					db,
					query: "UPDATE sessions SET user_id = :userId WHERE session_id = :sessionId;",
					params: { userId: user.id, sessionId: sessionId },
				}) ? DbErr
				Ok({})
			}
		}
	}

	listUsers! : Sqlite.Db => Try(List(Models.User), Sqlite.QueryError)
	listUsers! = |db|
		Sqlite.query_many!({
			db,
			query: "SELECT user_id AS id, name, email FROM users ORDER BY user_id;",
			params: {},
			limits: Sqlite.default_query_limits,
		})

	listTodos! : Sqlite.Db, Str => Try(List(Models.Todo), Sqlite.QueryError)
	listTodos! = |db, filter| {
		pattern = "%${filter}%"
		Sqlite.query_many!({
			db,
			query: "SELECT id, task, status FROM tasks WHERE task LIKE :pattern ORDER BY id;",
			params: { pattern: pattern },
			limits: Sqlite.default_query_limits,
		})
	}

	createTodo! : Sqlite.Db, Str, Str => Try({}, [TaskWasEmpty, DbErr(Sqlite.QueryError)])
	createTodo! = |db, task, status|
		if Str.is_empty(Str.trim(task)) {
			Err(TaskWasEmpty)
		} else {
			Sqlite.execute!({
				db,
				query: "INSERT INTO tasks (task, status) VALUES (:task, :status);",
				params: { task: task, status: status },
			}) ? DbErr
			Ok({})
		}

	updateTodo! : Sqlite.Db, I64, Str => Try({}, Sqlite.QueryError)
	updateTodo! = |db, id, status|
		Sqlite.execute!({
			db,
			query: "UPDATE tasks SET status = :status WHERE id = :id;",
			params: { id: id, status: status },
		})

	deleteTodo! : Sqlite.Db, I64 => Try({}, Sqlite.QueryError)
	deleteTodo! = |db, id|
		Sqlite.execute!({
			db,
			query: "DELETE FROM tasks WHERE id = :id;",
			params: { id: id },
		})

	todoTree! : Sqlite.Db, I64 => Try(Models.Tree(Models.Todo), Sqlite.QueryError)
	todoTree! = |db, userId| {
		rows : List({ id : I64, task : Str, status : Str, left : I64, right : I64 })
		rows = Sqlite.query_many!({
			db,
			query: "SELECT t.id, t.task, t.status, h.lft AS \"left\", h.rgt AS \"right\" FROM TaskHeirachy AS h JOIN tasks AS t ON h.task_id = t.id WHERE h.user_id = :userId ORDER BY h.lft;",
			params: { userId: userId },
			limits: Sqlite.default_query_limits,
		})?

		nested = rows.map(
			|row| {
				value: { id: row.id, task: row.task, status: row.status },
				left: row.left,
				right: row.right,
			},
		)
		Ok(Models.nestedSetToTree(nested))
	}

	listBigTasks! : Sqlite.Db, I64, I64, Str, Models.SortDirection => Try(List(Models.BigTask), Sqlite.QueryError)
	listBigTasks! = |db, page, items, sortBy, sortDirection| {
		column = allowedSortColumn(sortBy)
		direction = 
			match sortDirection {
				Ascending => "ASC"
				Descending => "DESC"
			}
		offset = (page - 1) * items
		query = 
			"SELECT ID AS id, ReferenceID AS referenceId, CustomerReferenceID AS customerReferenceId, IFNULL(DateCreated, '') AS dateCreated, IFNULL(DateModified, '') AS dateModified, IFNULL(Title, '') AS title, IFNULL(Description, '') AS description, IFNULL(Status, '') AS status, IFNULL(Priority, '') AS priority, IFNULL(ScheduledStartDate, '') AS scheduledStartDate, IFNULL(ScheduledEndDate, '') AS scheduledEndDate, IFNULL(ActualStartDate, '') AS actualStartDate, IFNULL(ActualEndDate, '') AS actualEndDate, IFNULL(SystemName, '') AS systemName, IFNULL(Location, '') AS location, IFNULL(FileReference, '') AS fileReference, IFNULL(Comments, '') AS comments FROM BigTask ORDER BY ${column} ${direction} LIMIT :items OFFSET :offset;"

		Sqlite.query_many!({
			db,
			query,
			params: { items: items, offset: offset },
			limits: Sqlite.default_query_limits,
		})
	}

	totalBigTasks! : Sqlite.Db => Try(I64, Sqlite.QueryError)
	totalBigTasks! = |db| {
		row : { total : I64 }
		row = Sqlite.query!({
			db,
			query: "SELECT COUNT(*) AS total FROM BigTask;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(row.total)
	}

	updateBigTask! : Sqlite.Db, I64, [CustomerReferenceId(Str), DateCreated(Str), Status(Str)] => Try({}, Sqlite.QueryError)
	updateBigTask! = |db, id, update|
		match update {
			CustomerReferenceId(value) =>
				Sqlite.execute!({
					db,
					query: "UPDATE BigTask SET CustomerReferenceID = :value WHERE ID = :id;",
					params: { id: id, value: value },
				})
			DateCreated(value) =>
				Sqlite.execute!({
					db,
					query: "UPDATE BigTask SET DateCreated = :value WHERE ID = :id;",
					params: { id: id, value: value },
				})
			Status(value) =>
				Sqlite.execute!({
					db,
					query: "UPDATE BigTask SET Status = :value WHERE ID = :id;",
					params: { id: id, value: value },
				})
			}
}

allowedSortColumn = |column|
	match column {
		"ID" => "ID"
		"ReferenceID" => "ReferenceID"
		"CustomerReferenceID" => "CustomerReferenceID"
		"DateCreated" => "DateCreated"
		"DateModified" => "DateModified"
		"Title" => "Title"
		"Description" => "Description"
		"Status" => "Status"
		"Priority" => "Priority"
		"ScheduledStartDate" => "ScheduledStartDate"
		"ScheduledEndDate" => "ScheduledEndDate"
		"ActualStartDate" => "ActualStartDate"
		"ActualEndDate" => "ActualEndDate"
		"SystemName" => "SystemName"
		"Location" => "Location"
		"FileReference" => "FileReference"
		"Comments" => "Comments"
		_ => "ID"
	}
