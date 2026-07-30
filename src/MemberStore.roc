import pf.Sqlite

import Member
import Session

MemberStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> MemberStore
	new = |db| MemberStore.{ db }

	register! : MemberStore, Member.Registration => Try({}, [MemberAlreadyExists, DbErr(Sqlite.QueryError)])
	register! = |store, registration| {
		existing : List(Str)
		existing = Sqlite.query_many!({
			db: store.db,
			query: "SELECT member_id AS id FROM members WHERE name = :name;",
			params: { name: registration.name.to_str() },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		if existing.is_empty() {
			Sqlite.execute!({
				db: store.db,
				query: (
					\\INSERT INTO members (member_id, workspace_id, name, email, active)
					\\SELECT
					\\    'member-' || lower(hex(randomblob(16))),
					\\    workspace_id,
					\\    :name,
					\\    :email,
					\\    1
					\\FROM workspaces
					\\LIMIT 1;
					,
				),
				params: {
					name: registration.name.to_str(),
					email: registration.email.to_str(),
				},
			}) ? DbErr
			Ok({})
		} else {
			Err(MemberAlreadyExists)
		}
	}

	login! : MemberStore, Session.Id, Member.Name => Try({}, [MemberNotFound, InactiveMember, DbErr(Sqlite.QueryError)])
	login! = |store, session_id, name| {
		rows : List({ active : I64, id : Str })
		rows = Sqlite.query_many!({
			db: store.db,
			query: "SELECT member_id AS id, active FROM members WHERE name = :name;",
			params: { name: name.to_str() },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		match rows {
			[] => Err(MemberNotFound)
			[{ active: 0, .. }, ..] => Err(InactiveMember)
			[{ id, .. }, ..] => {
				Sqlite.execute!({
					db: store.db,
					query: "UPDATE sessions SET member_id = :memberId WHERE session_id = :sessionId;",
					params: {
						memberId: id,
						sessionId: session_id.to_i64(),
					},
				}) ? DbErr
				Ok({})
			}
		}
	}

	find_active_by_email! : MemberStore, Str => Try(Member, [MemberNotFound, InactiveMember, DbErr(Sqlite.QueryError)])
	find_active_by_email! = |store, raw_email| {
		rows : List({ active : I64, email : Str, id : Str, name : Str })
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT member_id AS id, name, email, active
				\\FROM members
				\\WHERE email = :email COLLATE NOCASE
				\\LIMIT 1;
				,
			),
			params: { email: raw_email.trim().with_ascii_lowercased() },
			limits: Sqlite.default_query_limits,
		}) ? DbErr

		match rows {
			[] => Err(MemberNotFound)
			[{ active: 0, .. }, ..] => Err(InactiveMember)
			[{ active, email, id, name }, ..] =>
				Ok(Member.from_storage(id, name, email, active))
			}
	}

	list_active! : MemberStore => Try(List(Member), Sqlite.QueryError)
	list_active! = |store| {
		rows : List({ active : I64, email : Str, id : Str, name : Str })
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT member_id AS id, name, email, active
				\\FROM members
				\\WHERE active = 1
				\\ORDER BY name;
				,
			),
			params: {},
			limits: Sqlite.default_query_limits,
		})?

		Ok(
			rows.map(|row|
				Member.from_storage(row.id, row.name, row.email, row.active)),
		)
	}
}
