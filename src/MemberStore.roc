import pf.Sqlite

import Member

MemberStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> MemberStore
	new = |db| MemberStore.{ db }

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
