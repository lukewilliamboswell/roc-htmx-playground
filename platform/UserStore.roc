import pf.Sqlite

import Session
import User

## Concrete SQLite adapter for user persistence.
UserStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> UserStore
	new = |db| UserStore.{ db }

	register! : UserStore, User.Registration => Try({}, [UserAlreadyExists, DbErr(Sqlite.QueryError)])
	register! = |store, registration| {
		name = registration.name.to_str()
		email = registration.email.to_str()
		existing : List({ id : I64 })
		existing = Sqlite.query_many!({
			db: store.db,
			query: "SELECT user_id AS id FROM users WHERE name = :name;",
			params: {
				name: name,
			},
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		if existing.is_empty() {
			Sqlite.execute!({
				db: store.db,
				query: "INSERT INTO users (name, email) VALUES (:name, :email);",
				params: { name: name, email: email },
			}) ? DbErr
			Ok({})
		} else {
			Err(UserAlreadyExists)
		}
	}

	login! : UserStore, Session.Id, User.Name => Try({}, [UserNotFound, DbErr(Sqlite.QueryError)])
	login! = |store, session_id, username| {
		name = username.to_str()
		users : List({ id : I64 })
		users = Sqlite.query_many!({
			db: store.db,
			query: "SELECT user_id AS id FROM users WHERE name = :name;",
			params: {
				name: name,
			},
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		match users {
			[] => Err(UserNotFound)
			[user, ..] => {
				Sqlite.execute!({
					db: store.db,
					query: "UPDATE sessions SET user_id = :userId WHERE session_id = :sessionId;",
					params: { userId: user.id, sessionId: session_id.to_i64() },
				}) ? DbErr
				Ok({})
			}
		}
	}

	list! : UserStore => Try(List(User), Sqlite.QueryError)
	list! = |store| {
		rows : List({ id : I64, name : Str, email : Str })
		rows = Sqlite.query_many!({
			db: store.db,
			query: "SELECT user_id AS id, name, email FROM users ORDER BY user_id;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(rows.map(|row| User.from_storage(row.id, row.name, row.email)))
	}
}
