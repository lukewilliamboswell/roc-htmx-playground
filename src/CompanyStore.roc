import pf.Sqlite

import Company
import Member
import Workspace

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

	matches! : CompanyStore, Workspace.Id, Company.New => Try(List(Company.Match), Sqlite.QueryError)
	matches! = |store, workspace_id, input| {
		rows : List(RawMatch)
		rows = Sqlite.query_many!({
			db: store.db,
			query: duplicate_query,
			params: {
				workspaceId: workspace_id.to_str(),
				normalizedName: input.name.normalized(),
				normalizedPhone: Company.normalized_phone(input.phone),
				websiteDomain: Company.website_domain(input.website),
			},
			limits: Sqlite.default_query_limits,
		})?

		Ok(rows.map(match_from_storage))
	}

	create! : CompanyStore, Workspace.Id, Member.Id, Company.New, Str, Bool => Try(Company.Id, Company.CreateError(Sqlite.QueryError))
	create! = |store, workspace_id, actor_id, input, now, confirm_distinct| {
		transaction = Sqlite.begin!(store.db, Immediate)
			? Company.CreateError.StoreFailure

		match create_in_transaction!(transaction, workspace_id, actor_id, input, now, confirm_distinct) {
			Err(error) => {
				Sqlite.Transaction.rollback!(transaction) ?? {}
				Err(error)
			}
			Ok(id) => {
				Sqlite.Transaction.commit!(transaction)
					? Company.CreateError.StoreFailure
				Ok(id)
			}
		}
	}
}

create_in_transaction! : Sqlite.Transaction, Workspace.Id, Member.Id, Company.New, Str, Bool => Try(Company.Id, Company.CreateError(Sqlite.QueryError))
create_in_transaction! = |transaction, workspace_id, actor_id, input, now, confirm_distinct| {
	match_rows : List(RawMatch)
	match_rows = Sqlite.Transaction.query_many!(
		transaction,
		{
			query: duplicate_query,
			params: {
				workspaceId: workspace_id.to_str(),
				normalizedName: input.name.normalized(),
				normalizedPhone: Company.normalized_phone(input.phone),
				websiteDomain: Company.website_domain(input.website),
			},
			limits: Sqlite.default_query_limits,
		},
	) ? Company.CreateError.StoreFailure

	matches = match_rows.map(match_from_storage)
	if !confirm_distinct and !matches.is_empty() {
		return Err(Company.CreateError.DuplicateMatches(matches))
	}

	created : { id : Str }
	created = Sqlite.Transaction.query!(
		transaction,
		{
			query: (
				\\INSERT INTO companies (
				\\    company_id, workspace_id, name, normalized_name, owner_id,
				\\    lifecycle_status, website, website_domain, phone,
				\\    normalized_phone, source_id, context, created_by_id,
				\\    updated_by_id, created_at, updated_at, archived_at, version
				\\) VALUES (
				\\    'company-' || lower(hex(randomblob(16))),
				\\    :workspaceId, :name, :normalizedName, :ownerId,
				\\    :lifecycle, :website, :websiteDomain, :phone,
				\\    :normalizedPhone, :sourceId, :context, :actorId,
				\\    :actorId, :now, :now, '', 1
				\\)
				\\RETURNING company_id AS id;
				,
			),
			params: {
				workspaceId: workspace_id.to_str(),
				name: input.name.to_str(),
				normalizedName: input.name.normalized(),
				ownerId: input.ownerId.to_str(),
				lifecycle: input.lifecycle.to_str(),
				website: input.website,
				websiteDomain: Company.website_domain(input.website),
				phone: input.phone,
				normalizedPhone: Company.normalized_phone(input.phone),
				sourceId: input.sourceId,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
			},
			limits: Sqlite.default_query_limits,
		},
	) ? Company.CreateError.StoreFailure

	Sqlite.Transaction.execute!(
		transaction,
		{
			query: (
				\\INSERT INTO company_revisions (
				\\    company_id, version, name, owner_id, lifecycle_status,
				\\    website, phone, source_id, context, changed_by_id, changed_at
				\\) VALUES (
				\\    :id, 1, :name, :ownerId, :lifecycle,
				\\    :website, :phone, :sourceId, :context, :actorId, :now
				\\);
				,
			),
			params: {
				id: created.id,
				name: input.name.to_str(),
				ownerId: input.ownerId.to_str(),
				lifecycle: input.lifecycle.to_str(),
				website: input.website,
				phone: input.phone,
				sourceId: input.sourceId,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
			},
		},
	) ? Company.CreateError.StoreFailure

	Ok(Company.Id.from_storage(created.id))
}

duplicate_query = (
	\\WITH candidates AS (
	\\    SELECT
	\\        c.company_id AS id,
	\\        c.name,
	\\        c.owner_id AS ownerId,
	\\        owner.name AS ownerName,
	\\        c.lifecycle_status AS lifecycle,
	\\        c.website,
	\\        c.phone,
	\\        c.source_id AS sourceId,
	\\        IFNULL(source.name, '') AS sourceName,
	\\        c.context,
	\\        creator.name AS createdByName,
	\\        updater.name AS updatedByName,
	\\        c.created_at AS createdAt,
	\\        c.updated_at AS updatedAt,
	\\        c.version,
	\\        CASE
	\\            WHEN :normalizedPhone <> ''
	\\             AND c.normalized_phone = :normalizedPhone
	\\             AND (SELECT COUNT(*) FROM companies p
	\\                  WHERE p.workspace_id = :workspaceId
	\\                    AND p.archived_at = ''
	\\                    AND p.normalized_phone = :normalizedPhone) = 1
	\\                THEN 'strong'
	\\            WHEN :websiteDomain <> ''
	\\             AND c.website_domain = :websiteDomain
	\\             AND (SELECT COUNT(*) FROM companies d
	\\                  WHERE d.workspace_id = :workspaceId
	\\                    AND d.archived_at = ''
	\\                    AND d.website_domain = :websiteDomain) = 1
	\\                THEN 'strong'
	\\            ELSE 'weak'
	\\        END AS strength,
	\\        CASE
	\\            WHEN :normalizedPhone <> '' AND c.normalized_phone = :normalizedPhone
	\\                THEN 'Same phone number'
	\\            WHEN :websiteDomain <> '' AND c.website_domain = :websiteDomain
	\\                THEN 'Same website domain'
	\\            ELSE 'Similar company name'
	\\        END AS reason
	\\    FROM companies c
	\\    JOIN members owner ON owner.member_id = c.owner_id
	\\    JOIN members creator ON creator.member_id = c.created_by_id
	\\    JOIN members updater ON updater.member_id = c.updated_by_id
	\\    LEFT JOIN sources source
	\\      ON source.workspace_id = c.workspace_id AND source.source_id = c.source_id
	\\    WHERE c.workspace_id = :workspaceId
	\\      AND c.archived_at = ''
	\\      AND (
	\\          (:normalizedPhone <> '' AND c.normalized_phone = :normalizedPhone)
	\\          OR (:websiteDomain <> '' AND c.website_domain = :websiteDomain)
	\\          OR c.normalized_name = :normalizedName
	\\      )
	\\)
	\\SELECT * FROM candidates
	\\ORDER BY CASE strength WHEN 'strong' THEN 0 ELSE 1 END, name;
	,
)

match_from_storage : RawMatch -> Company.Match
match_from_storage = |row|
	Company.Match.{
		company: Company.from_storage({
			context: row.context,
			createdAt: row.createdAt,
			createdByName: row.createdByName,
			id: row.id,
			lifecycle: row.lifecycle,
			name: row.name,
			ownerId: row.ownerId,
			ownerName: row.ownerName,
			phone: row.phone,
			sourceId: row.sourceId,
			sourceName: row.sourceName,
			updatedAt: row.updatedAt,
			updatedByName: row.updatedByName,
			version: row.version,
			website: row.website,
		}),
		strength: if row.strength == "strong" {
			Company.MatchStrength.Strong
		} else {
			Company.MatchStrength.Weak
		},
		reason: row.reason,
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

RawMatch : {
	context : Str,
	createdAt : Str,
	createdByName : Str,
	id : Str,
	lifecycle : Str,
	name : Str,
	ownerId : Str,
	ownerName : Str,
	phone : Str,
	reason : Str,
	sourceId : Str,
	sourceName : Str,
	strength : Str,
	updatedAt : Str,
	updatedByName : Str,
	version : I64,
	website : Str,
}
