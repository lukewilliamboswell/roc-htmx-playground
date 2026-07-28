import pf.Sqlite

import Session

## Concrete SQLite adapter for session persistence. The opaque nominal wrapper
## prevents database details from leaking through the rest of the application.
SessionStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> SessionStore
	new = |db| SessionStore.{ db }

	create! : SessionStore => Try(Session.Id, Sqlite.QueryError)
	create! = |store| {
		row : { id : I64 }
		row = Sqlite.query!({
			db: store.db,
			query: "INSERT INTO sessions (user_id) VALUES (NULL) RETURNING session_id AS id;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(Session.Id.from_i64(row.id))
	}

	find! : SessionStore, Session.Id => Try(Session, [SessionNotFound, DbErr(Sqlite.QueryError)])
	find! = |store, id| {
		rows : List({ id : I64, username : Str })
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT s.session_id AS id, IFNULL(u.name, '') AS username
				\\FROM sessions AS s
				\\LEFT JOIN users AS u ON s.user_id = u.user_id
				\\WHERE s.session_id = :id;
				,
			),
			params: { id: id.to_i64() },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		match rows {
			[] => Err(SessionNotFound)
			[row, ..] =>
				if row.username.is_empty() {
					Ok(Session.guest(Session.Id.from_i64(row.id)))
				} else {
					Ok(Session.logged_in(Session.Id.from_i64(row.id), row.username))
				}
			}
	}
}
