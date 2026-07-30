import pf.Sqlite

import Member
import Session

## Concrete SQLite adapter for session persistence. The opaque nominal wrapper
## prevents database details from leaking through the rest of the application.
SessionStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> SessionStore
	new = |db| SessionStore.{ db }

	## TODO(codec-upgrade): Return and bind `Session.Id` directly once nominal
	## `parser_for`/`encoder_for` works reliably with SQLite's generic codecs.
	create! : SessionStore => Try(Session.Id, Sqlite.QueryError)
	create! = |store| {
		id : I64
		id = Sqlite.query!({
			db: store.db,
			query: "INSERT INTO sessions (user_id, member_id) VALUES (NULL, NULL) RETURNING session_id AS id;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(Session.Id.from_i64(id))
	}

	find! : SessionStore, Session.Id => Try(Session, Session.FindError(Sqlite.QueryError))
	find! = |store, id| {
		rows : List({ active : I64, email : Str, id : I64, memberId : Str, memberName : Str, requestedMemberId : Str })
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT
				\\    s.session_id AS id,
				\\    IFNULL(s.member_id, '') AS requestedMemberId,
				\\    IFNULL(m.member_id, '') AS memberId,
				\\    IFNULL(m.name, '') AS memberName,
				\\    IFNULL(m.email, '') AS email,
				\\    IFNULL(m.active, 0) AS active
				\\FROM sessions AS s
				\\LEFT JOIN members AS m ON s.member_id = m.member_id
				\\WHERE s.session_id = :id;
				,
			),
			params: { id: id.to_i64() },
			limits: Sqlite.default_query_limits,
		}) ? Session.FindError.StoreFailure

		match rows {
			[] => Err(Session.FindError.NotFound)
			[row, ..] =>
				if row.requestedMemberId.is_empty() {
					Ok(Session.guest(Session.Id.from_i64(row.id)))
				} else if row.memberId.is_empty() or row.active == 0 {
					Err(Session.FindError.Inactive)
				} else {
					member = Member.from_storage(row.memberId, row.memberName, row.email, row.active)
					Ok(Session.logged_in(Session.Id.from_i64(row.id), member))
				}
			}
	}
}
