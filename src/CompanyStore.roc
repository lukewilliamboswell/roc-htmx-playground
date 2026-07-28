import pf.Sqlite

import Company

CompanyStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> CompanyStore
	new = |db| CompanyStore.{ db }

	list! : CompanyStore, Company.Filter => Try(List(Company), Sqlite.QueryError)
	list! = |store, filter| {
		rows : List(RawCompany)
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT
				\\    c.company_id AS id,
				\\    c.name,
				\\    c.owner_id AS ownerId,
				\\    owner.name AS ownerName,
				\\    c.lifecycle_status AS lifecycle,
				\\    c.website,
				\\    c.phone,
				\\    c.source_id AS sourceId,
				\\    IFNULL(source.name, '') AS sourceName,
				\\    c.context,
				\\    creator.name AS createdByName,
				\\    updater.name AS updatedByName,
				\\    c.created_at AS createdAt,
				\\    c.updated_at AS updatedAt,
				\\    c.version
				\\FROM companies AS c
				\\JOIN members AS owner ON owner.member_id = c.owner_id
				\\JOIN members AS creator ON creator.member_id = c.created_by_id
				\\JOIN members AS updater ON updater.member_id = c.updated_by_id
				\\LEFT JOIN sources AS source
				\\    ON source.workspace_id = c.workspace_id
				\\    AND source.source_id = c.source_id
				\\WHERE c.archived_at = ''
				\\  AND (
				\\      :filter = ''
				\\      OR c.normalized_name LIKE '%' || :filter || '%'
				\\      OR c.normalized_phone LIKE '%' || :filter || '%'
				\\      OR c.website_domain LIKE '%' || :filter || '%'
				\\  )
				\\ORDER BY c.updated_at DESC, c.name;
				,
			),
			params: { filter: filter.normalized() },
			limits: Sqlite.default_query_limits,
		})?

		Ok(rows.map(Company.from_storage))
	}

	find! : CompanyStore, Company.Id => Try(Company, Company.FindError(Sqlite.QueryError))
	find! = |store, id| {
		rows : List(RawCompany)
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT
				\\    c.company_id AS id,
				\\    c.name,
				\\    c.owner_id AS ownerId,
				\\    owner.name AS ownerName,
				\\    c.lifecycle_status AS lifecycle,
				\\    c.website,
				\\    c.phone,
				\\    c.source_id AS sourceId,
				\\    IFNULL(source.name, '') AS sourceName,
				\\    c.context,
				\\    creator.name AS createdByName,
				\\    updater.name AS updatedByName,
				\\    c.created_at AS createdAt,
				\\    c.updated_at AS updatedAt,
				\\    c.version
				\\FROM companies AS c
				\\JOIN members AS owner ON owner.member_id = c.owner_id
				\\JOIN members AS creator ON creator.member_id = c.created_by_id
				\\JOIN members AS updater ON updater.member_id = c.updated_by_id
				\\LEFT JOIN sources AS source
				\\    ON source.workspace_id = c.workspace_id
				\\    AND source.source_id = c.source_id
				\\WHERE c.company_id = :id;
				,
			),
			params: { id: id.to_str() },
			limits: Sqlite.default_query_limits,
		}) ? Company.FindError.StoreFailure

		match rows {
			[] => Err(Company.FindError.NotFound)
			[row, ..] => Ok(Company.from_storage(row))
		}
	}
}

RawCompany : {
	context : Str,
	createdAt : Str,
	createdByName : Str,
	id : Str,
	lifecycle : Str,
	name : Str,
	ownerId : Str,
	ownerName : Str,
	phone : Str,
	sourceId : Str,
	sourceName : Str,
	updatedAt : Str,
	updatedByName : Str,
	version : I64,
	website : Str,
}
