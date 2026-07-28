import pf.Sqlite

import Activity
import Company
import Member
import Person
import Workspace

PersonStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> PersonStore
	new = |db| PersonStore.{ db }

	list! : PersonStore, Str => Try(List(Person), Sqlite.QueryError)
	list! = |store, filter| {
		rows : List(RawPerson)
		rows = Sqlite.query_many!({
			db: store.db,
			query: "${person_select} ${person_joins} WHERE p.archived_at = '' AND (:filter = '' OR p.normalized_name LIKE '%' || :filter || '%' OR EXISTS (SELECT 1 FROM person_emails e WHERE e.person_id = p.person_id AND e.normalized_email LIKE '%' || :filter || '%') OR EXISTS (SELECT 1 FROM person_phones ph WHERE ph.person_id = p.person_id AND ph.normalized_phone LIKE '%' || :filter || '%')) ORDER BY p.updated_at DESC, p.name;",
			params: { filter: filter.trim().with_ascii_lowercased() },
			limits: Sqlite.default_query_limits,
		})?
		hydrate_rows!(store.db, rows)
	}

	list_for_company! : PersonStore, Company.Id => Try(List(Person), Sqlite.QueryError)
	list_for_company! = |store, company_id| {
		rows : List(RawPerson)
		rows = Sqlite.query_many!({
			db: store.db,
			query: "${person_select} ${person_joins} WHERE p.archived_at = '' AND p.company_id = :companyId ORDER BY p.name;",
			params: { companyId: company_id.to_str() },
			limits: Sqlite.default_query_limits,
		})?
		hydrate_rows!(store.db, rows)
	}

	find! : PersonStore, Person.Id => Try(Person, Person.FindError(Sqlite.QueryError))
	find! = |store, id| {
		rows : List(RawPerson)
		rows = Sqlite.query_many!({
			db: store.db,
			query: "${person_select} ${person_joins} WHERE p.person_id = :id;",
			params: { id: id.to_str() },
			limits: Sqlite.default_query_limits,
		}) ? Person.FindError.StoreFailure
		match rows {
			[] => Err(Person.FindError.NotFound)
			[row, ..] =>
				hydrate!(store.db, row).map_err(|error| Person.FindError.StoreFailure(error))
			}
	}

	matches! : PersonStore, Workspace.Id, Person.New => Try(List(Person.Match), Sqlite.QueryError)
	matches! = |store, workspace_id, input| {
		rows : List(RawPersonMatch)
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT p.person_id AS id,
				\\    CASE
				\\      WHEN :email <> '' AND EXISTS (
				\\        SELECT 1 FROM person_emails e
				\\        WHERE e.person_id = p.person_id AND e.normalized_email = :email
				\\      ) AND (
				\\        SELECT COUNT(DISTINCT owner.person_id)
				\\        FROM person_emails owner
				\\        JOIN people owner_person ON owner_person.person_id = owner.person_id
				\\        WHERE owner.normalized_email = :email
				\\          AND owner_person.workspace_id = :workspaceId
				\\          AND owner_person.archived_at = ''
				\\      ) = 1 THEN 'strong'
				\\      WHEN :phone <> '' AND EXISTS (
				\\        SELECT 1 FROM person_phones ph
				\\        WHERE ph.person_id = p.person_id AND ph.normalized_phone = :phone
				\\      ) AND (
				\\        SELECT COUNT(DISTINCT owner.person_id)
				\\        FROM person_phones owner
				\\        JOIN people owner_person ON owner_person.person_id = owner.person_id
				\\        WHERE owner.normalized_phone = :phone
				\\          AND owner_person.workspace_id = :workspaceId
				\\          AND owner_person.archived_at = ''
				\\      ) = 1 THEN 'strong'
				\\      ELSE 'weak'
				\\    END AS strength,
				\\    CASE
				\\      WHEN :email <> '' AND EXISTS (
				\\        SELECT 1 FROM person_emails e
				\\        WHERE e.person_id = p.person_id AND e.normalized_email = :email
				\\      ) THEN 'Same email address'
				\\      WHEN :phone <> '' AND EXISTS (
				\\        SELECT 1 FROM person_phones ph
				\\        WHERE ph.person_id = p.person_id AND ph.normalized_phone = :phone
				\\      ) THEN 'Same phone number'
				\\      ELSE 'Same name'
				\\    END AS reason
				\\FROM people p
				\\WHERE p.workspace_id = :workspaceId AND p.archived_at = ''
				\\  AND (
				\\    p.normalized_name = :name
				\\    OR (:email <> '' AND EXISTS (
				\\      SELECT 1 FROM person_emails e
				\\      WHERE e.person_id = p.person_id AND e.normalized_email = :email
				\\    ))
				\\    OR (:phone <> '' AND EXISTS (
				\\      SELECT 1 FROM person_phones ph
				\\      WHERE ph.person_id = p.person_id AND ph.normalized_phone = :phone
				\\    ))
				\\  )
				\\ORDER BY CASE strength WHEN 'strong' THEN 0 ELSE 1 END;
				,
			),
			params: {
				workspaceId: workspace_id.to_str(),
				name: input.name.normalized(),
				email: Person.normalized_email(input.email),
				phone: Person.normalized_phone(input.phone),
			},
			limits: Sqlite.default_query_limits,
		})?
		load_matches!(store, rows, [])
	}

	create! : PersonStore, Workspace.Id, Member.Id, Person.New, Str, Bool => Try(Person.Id, Person.CreateError(Sqlite.QueryError))
	create! = |store, workspace_id, actor_id, input, now, confirm_distinct| {
		matches = matches!(store, workspace_id, input)
			? Person.CreateError.StoreFailure
		if !confirm_distinct and !matches.is_empty() {
			return Err(Person.CreateError.DuplicateMatches(matches))
		}

		transaction = Sqlite.begin!(store.db, Immediate)
			? Person.CreateError.StoreFailure
		match create_in_transaction!(transaction, workspace_id, actor_id, input, now) {
			Err(error) => {
				Sqlite.Transaction.rollback!(transaction) ?? {}
				Err(Person.CreateError.StoreFailure(error))
			}
			Ok(id) => {
				Sqlite.Transaction.commit!(transaction)
					? Person.CreateError.StoreFailure
				Ok(id)
			}
		}
	}

	update! : PersonStore, Workspace.Id, Member.Id, Person.Id, Person.New, Company.Version, Str => Try(Company.Version, Person.UpdateError(Sqlite.QueryError))
	update! = |store, workspace_id, actor_id, id, input, expected_version, now| {
		current = find!(store, id)
		current_person = match current {
			Err(Person.FindError.NotFound) => return Err(Person.UpdateError.NotFound)
			Err(Person.FindError.StoreFailure(error)) =>
				return Err(Person.UpdateError.StoreFailure(error))
			Ok(person) if person.version != expected_version =>
				return Err(Person.UpdateError.Conflict(person))
			Ok(person) => person
		}
		next_version = Company.Version.from_i64(expected_version.to_i64() + 1)
		changed = Sqlite.execute!({
			db: store.db,
			query: (
				\\UPDATE people SET
				\\ name = :name, normalized_name = :normalizedName,
				\\ company_id = :companyId, job_title = :jobTitle,
				\\ owner_id = :ownerId, lifecycle_status = :lifecycle,
				\\ source_id = :sourceId, context = :context,
				\\ updated_by_id = :actorId, updated_at = :now, version = :nextVersion
				\\WHERE person_id = :id AND workspace_id = :workspaceId
				\\  AND version = :expectedVersion;
				,
			),
			params: {
				id: id.to_str(),
				workspaceId: workspace_id.to_str(),
				name: input.name.to_str(),
				normalizedName: input.name.normalized(),
				companyId: input.companyId,
				jobTitle: input.jobTitle,
				ownerId: input.ownerId.to_str(),
				lifecycle: input.lifecycle.to_str(),
				sourceId: input.sourceId,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
				nextVersion: next_version.to_i64(),
				expectedVersion: expected_version.to_i64(),
			},
		}) ? Person.UpdateError.StoreFailure
		_ = changed
		Sqlite.execute!({
			db: store.db,
			query: (
				\\INSERT INTO person_revisions (
				\\ person_id, version, name, company_id, job_title, owner_id,
				\\ lifecycle_status, source_id, context, changed_by_id, changed_at
				\\) VALUES (
				\\ :id, :version, :name, :companyId, :jobTitle, :ownerId,
				\\ :lifecycle, :sourceId, :context, :actorId, :now
				\\);
				,
			),
			params: {
				id: id.to_str(),
				version: next_version.to_i64(),
				name: input.name.to_str(),
				companyId: input.companyId,
				jobTitle: input.jobTitle,
				ownerId: input.ownerId.to_str(),
				lifecycle: input.lifecycle.to_str(),
				sourceId: input.sourceId,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
			},
		}) ? Person.UpdateError.StoreFailure
		if current_person.ownerId != input.ownerId {
			log_person_change!(
				store.db,
				workspace_id,
				actor_id,
				id,
				"owner",
				current_person.ownerId.to_str(),
				input.ownerId.to_str(),
				now,
			) ? Person.UpdateError.StoreFailure
		}
		if current_person.lifecycle != input.lifecycle {
			log_person_change!(
				store.db,
				workspace_id,
				actor_id,
				id,
				"lifecycle",
				current_person.lifecycle.to_label(),
				input.lifecycle.to_label(),
				now,
			) ? Person.UpdateError.StoreFailure
		}
		Ok(next_version)
	}

	history! : PersonStore, Person.Id => Try(List(Activity), Sqlite.QueryError)
	history! = |store, id| {
		rows : List(RawActivity)
		rows = Sqlite.query_many!({
			db: store.db,
			query: (
				\\SELECT a.activity_id AS id, a.occurred_at AS occurredAt,
				\\ member.name AS createdByName, a.subject,
				\\ a.change_field AS changeField, a.change_from AS changeFrom,
				\\ a.change_to AS changeTo
				\\FROM activities a
				\\JOIN activity_people link ON link.activity_id = a.activity_id
				\\JOIN members member ON member.member_id = a.created_by_id
				\\WHERE link.person_id = :id
				\\ORDER BY a.occurred_at DESC, a.activity_id DESC;
				,
			),
			params: { id: id.to_str() },
			limits: Sqlite.default_query_limits,
		})?
		Ok(rows.map(Activity.from_storage))
	}

	add_contact! : PersonStore, Person.Id, [Email, Phone], Str, Str, Bool => Try({}, Sqlite.QueryError)
	add_contact! = |store, person_id, kind, label, value, primary| {
		if value.trim().is_empty() {
			return Ok({})
		}
		transaction = Sqlite.begin!(store.db, Immediate)?
		result = add_contact_in_transaction!(
			transaction,
			person_id,
			kind,
			label,
			value,
			primary,
		)
		finish_contact_transaction!(transaction, result)
	}

	make_primary! : PersonStore, Person.Id, [Email, Phone], Person.ContactId => Try({}, Sqlite.QueryError)
	make_primary! = |store, person_id, kind, contact_id| {
		transaction = Sqlite.begin!(store.db, Immediate)?
		result = make_primary_in_transaction!(transaction, person_id, kind, contact_id)
		finish_contact_transaction!(transaction, result)
	}

	delete_contact! : PersonStore, Person.Id, [Email, Phone], Person.ContactId => Try({}, Sqlite.QueryError)
	delete_contact! = |store, person_id, kind, contact_id| {
		transaction = Sqlite.begin!(store.db, Immediate)?
		result = delete_contact_in_transaction!(transaction, person_id, kind, contact_id)
		finish_contact_transaction!(transaction, result)
	}
}

ContactColumns := {
	id : Str,
	idPrefix : Str,
	normalized : Str,
	table : Str,
	value : Str,
}

contact_columns : [Email, Phone] -> ContactColumns
contact_columns = |kind|
	match kind {
		Email => {
			id: "email_id",
			idPrefix: "email-",
			normalized: "normalized_email",
			table: "person_emails",
			value: "email",
		}
		Phone => {
			id: "phone_id",
			idPrefix: "phone-",
			normalized: "normalized_phone",
			table: "person_phones",
			value: "phone",
		}
	}

normalized_contact : [Email, Phone], Str -> Str
normalized_contact = |kind, value|
	match kind {
		Email => Person.normalized_email(value)
		Phone => Person.normalized_phone(value)
	}

add_contact_in_transaction! : Sqlite.Transaction, Person.Id, [Email, Phone], Str, Str, Bool => Try({}, Sqlite.QueryError)
add_contact_in_transaction! = |transaction, person_id, kind, label, value, primary| {
	columns = contact_columns(kind)
	if primary {
		Sqlite.Transaction.execute!(
			transaction,
			{
				query: "UPDATE ${columns.table} SET is_primary = 0 WHERE person_id = :personId;",
				params: { personId: person_id.to_str() },
			},
		)?
	}
	primary_value : I64
	primary_value = if primary {
		1
	} else {
		0
	}
	Sqlite.Transaction.execute!(
		transaction,
		{
			query: (
				\\INSERT INTO ${columns.table} (
				\\ ${columns.id}, person_id, label, ${columns.value},
				\\ ${columns.normalized}, is_primary, position
				\\) VALUES (
				\\ '${columns.idPrefix}' || lower(hex(randomblob(16))), :personId, :label,
				\\ :value, :normalized, :primary,
				\\ (SELECT COUNT(*) + 1 FROM ${columns.table} WHERE person_id = :personId)
				\\)
				\\ON CONFLICT(person_id, ${columns.normalized}) DO UPDATE SET
				\\ label = excluded.label,
				\\ ${columns.value} = excluded.${columns.value},
				\\ is_primary = CASE
				\\   WHEN excluded.is_primary = 1 THEN 1
				\\   ELSE ${columns.table}.is_primary
				\\ END;
				,
			),
			params: {
				personId: person_id.to_str(),
				label: contact_label(label),
				value: value.trim(),
				normalized: normalized_contact(kind, value),
				primary: primary_value,
			},
		},
	)?
	Ok({})
}

make_primary_in_transaction! : Sqlite.Transaction, Person.Id, [Email, Phone], Person.ContactId => Try({}, Sqlite.QueryError)
make_primary_in_transaction! = |transaction, person_id, kind, contact_id| {
	columns = contact_columns(kind)
	Sqlite.Transaction.execute!(
		transaction,
		{
			query: "UPDATE ${columns.table} SET is_primary = 0 WHERE person_id = :personId;",
			params: { personId: person_id.to_str() },
		},
	)?
	updated : { id : Str }
	updated = Sqlite.Transaction.query!(
		transaction,
		{
			query: "UPDATE ${columns.table} SET is_primary = 1 WHERE person_id = :personId AND ${columns.id} = :contactId RETURNING ${columns.id} AS id;",
			params: {
				personId: person_id.to_str(),
				contactId: contact_id.to_str(),
			},
			limits: Sqlite.default_query_limits,
		},
	)?
	_ = updated
	Ok({})
}

delete_contact_in_transaction! : Sqlite.Transaction, Person.Id, [Email, Phone], Person.ContactId => Try({}, Sqlite.QueryError)
delete_contact_in_transaction! = |transaction, person_id, kind, contact_id| {
	columns = contact_columns(kind)
	deleted : { primaryValue : I64 }
	deleted = Sqlite.Transaction.query!(
		transaction,
		{
			query: "DELETE FROM ${columns.table} WHERE person_id = :personId AND ${columns.id} = :contactId RETURNING is_primary AS primaryValue;",
			params: {
				personId: person_id.to_str(),
				contactId: contact_id.to_str(),
			},
			limits: Sqlite.default_query_limits,
		},
	)?
	if deleted.primaryValue == 1 {
		Sqlite.Transaction.execute!(
			transaction,
			{
				query: "UPDATE ${columns.table} SET is_primary = 1 WHERE ${columns.id} = (SELECT ${columns.id} FROM ${columns.table} WHERE person_id = :personId ORDER BY position, ${columns.id} LIMIT 1);",
				params: { personId: person_id.to_str() },
			},
		)?
	}
	Ok({})
}

finish_contact_transaction! : Sqlite.Transaction, Try({}, Sqlite.QueryError) => Try({}, Sqlite.QueryError)
finish_contact_transaction! = |transaction, result|
	match result {
		Ok({}) => Sqlite.Transaction.commit!(transaction)
		Err(error) => {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			Err(error)
		}
	}

log_person_change! : Sqlite.Db, Workspace.Id, Member.Id, Person.Id, Str, Str, Str, Str => Try({}, Sqlite.QueryError)
log_person_change! = |db, workspace_id, actor_id, person_id, field, from, to, now| {
	activity : { id : Str }
	activity = Sqlite.query!({
		db,
		query: (
			\\INSERT INTO activities (
			\\ activity_id, workspace_id, activity_type, occurred_at,
			\\ created_by_id, subject, details, outcome, change_field,
			\\ change_from, change_to, created_at
			\\) VALUES (
			\\ 'activity-' || lower(hex(randomblob(16))), :workspaceId,
			\\ 'record_change', :now, :actorId, 'Person updated',
			\\ '', '', :field, :fromValue, :toValue, :now
			\\) RETURNING activity_id AS id;
			,
		),
		params: {
			workspaceId: workspace_id.to_str(),
			actorId: actor_id.to_str(),
			field,
			fromValue: from,
			toValue: to,
			now,
		},
		limits: Sqlite.default_query_limits,
	})?
	Sqlite.execute!({
		db,
		query: "INSERT INTO activity_people (activity_id, person_id) VALUES (:activityId, :personId);",
		params: { activityId: activity.id, personId: person_id.to_str() },
	})?
	Ok({})
}

create_in_transaction! : Sqlite.Transaction, Workspace.Id, Member.Id, Person.New, Str => Try(Person.Id, Sqlite.QueryError)
create_in_transaction! = |transaction, workspace_id, actor_id, input, now| {
	created : { id : Str }
	created = Sqlite.Transaction.query!(
		transaction,
		{
			query: (
				\\INSERT INTO people (
				\\ person_id, workspace_id, name, normalized_name, company_id,
				\\ job_title, owner_id, lifecycle_status, source_id, context,
				\\ created_by_id, updated_by_id, created_at, updated_at, archived_at, version
				\\) VALUES (
				\\ 'person-' || lower(hex(randomblob(16))), :workspaceId, :name,
				\\ :normalizedName, :companyId, :jobTitle, :ownerId, :lifecycle,
				\\ :sourceId, :context, :actorId, :actorId, :now, :now, '', 1
				\\) RETURNING person_id AS id;
				,
			),
			params: {
				workspaceId: workspace_id.to_str(),
				name: input.name.to_str(),
				normalizedName: input.name.normalized(),
				companyId: input.companyId,
				jobTitle: input.jobTitle,
				ownerId: input.ownerId.to_str(),
				lifecycle: input.lifecycle.to_str(),
				sourceId: input.sourceId,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
			},
			limits: Sqlite.default_query_limits,
		},
	)?
	Sqlite.Transaction.execute!(
		transaction,
		{
			query: (
				\\INSERT INTO person_revisions (
				\\ person_id, version, name, company_id, job_title, owner_id,
				\\ lifecycle_status, source_id, context, changed_by_id, changed_at
				\\) VALUES (
				\\ :id, 1, :name, :companyId, :jobTitle, :ownerId,
				\\ :lifecycle, :sourceId, :context, :actorId, :now
				\\);
				,
			),
			params: {
				id: created.id,
				name: input.name.to_str(),
				companyId: input.companyId,
				jobTitle: input.jobTitle,
				ownerId: input.ownerId.to_str(),
				lifecycle: input.lifecycle.to_str(),
				sourceId: input.sourceId,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
			},
		},
	)?
	if !input.email.is_empty() {
		Sqlite.Transaction.execute!(
			transaction,
			{
				query: (
					\\INSERT INTO person_emails (
					\\ email_id, person_id, label, email, normalized_email, is_primary, position
					\\) VALUES (
					\\ 'email-' || lower(hex(randomblob(16))), :id, 'Work',
					\\ :value, :normalized, 1, 1
					\\);
					,
				),
				params: {
					id: created.id,
					value: input.email,
					normalized: Person.normalized_email(input.email),
				},
			},
		)?
	}
	if !input.phone.is_empty() {
		Sqlite.Transaction.execute!(
			transaction,
			{
				query: (
					\\INSERT INTO person_phones (
					\\ phone_id, person_id, label, phone, normalized_phone, is_primary, position
					\\) VALUES (
					\\ 'phone-' || lower(hex(randomblob(16))), :id, 'Work',
					\\ :value, :normalized, 1, 1
					\\);
					,
				),
				params: {
					id: created.id,
					value: input.phone,
					normalized: Person.normalized_phone(input.phone),
				},
			},
		)?
	}
	Ok(Person.Id.from_storage(created.id))
}

hydrate_rows! : Sqlite.Db, List(RawPerson) => Try(List(Person), Sqlite.QueryError)
hydrate_rows! = |db, rows|
	match rows {
		[] => Ok([])
		[row, .. as rest] => {
			person = hydrate!(db, row)?
			remaining = hydrate_rows!(db, rest)?
			Ok([person].concat(remaining))
		}
	}

hydrate! : Sqlite.Db, RawPerson => Try(Person, Sqlite.QueryError)
hydrate! = |db, row| {
	emails : List(RawContact)
	emails = Sqlite.query_many!({
		db,
		query: "SELECT email_id AS id, label, email AS value, is_primary AS primaryValue FROM person_emails WHERE person_id = :id ORDER BY is_primary DESC, position;",
		params: { id: row.id },
		limits: Sqlite.default_query_limits,
	})?
	phones : List(RawContact)
	phones = Sqlite.query_many!({
		db,
		query: "SELECT phone_id AS id, label, phone AS value, is_primary AS primaryValue FROM person_phones WHERE person_id = :id ORDER BY is_primary DESC, position;",
		params: { id: row.id },
		limits: Sqlite.default_query_limits,
	})?
	Ok(
		Person.from_storage(
			row,
			emails.map(|item| Person.contact_from_storage(item.id, item.label, item.value, item.primaryValue)),
			phones.map(|item| Person.contact_from_storage(item.id, item.label, item.value, item.primaryValue)),
		),
	)
}

load_matches! : PersonStore, List(RawPersonMatch), List(Person.Match) => Try(List(Person.Match), Sqlite.QueryError)
load_matches! = |store, rows, loaded|
	match rows {
		[] => Ok(loaded)
		[row, .. as rest] =>
			match PersonStore.find!(store, Person.Id.from_storage(row.id)) {
				Err(Person.FindError.NotFound) => load_matches!(store, rest, loaded)
				Err(Person.FindError.StoreFailure(error)) => Err(error)
				Ok(person) =>
					load_matches!(
						store,
						rest,
						loaded.append(
							Person.Match.{
								person,
								strength: if row.strength == "strong" {
									Person.MatchStrength.Strong
								} else {
									Person.MatchStrength.Weak
								},
								reason: row.reason,
							},
						),
					)
				}
		}

contact_label : Str -> Str
contact_label = |label|
	if label.trim().is_empty() {
		"Other"
	} else {
		label.trim()
	}

person_select = (
	\\SELECT p.person_id AS id, p.name, p.company_id AS companyId,
	\\ IFNULL(company.name, '') AS companyName, p.job_title AS jobTitle,
	\\ p.owner_id AS ownerId, owner.name AS ownerName,
	\\ p.lifecycle_status AS lifecycle, p.source_id AS sourceId,
	\\ IFNULL(source.name, '') AS sourceName, p.context,
	\\ creator.name AS createdByName, updater.name AS updatedByName,
	\\ p.created_at AS createdAt, p.updated_at AS updatedAt, p.version
	\\FROM people p
	,
)

person_joins = (
	\\JOIN members owner ON owner.member_id = p.owner_id
	\\JOIN members creator ON creator.member_id = p.created_by_id
	\\JOIN members updater ON updater.member_id = p.updated_by_id
	\\LEFT JOIN companies company ON company.company_id = p.company_id
	\\LEFT JOIN sources source
	\\ ON source.workspace_id = p.workspace_id AND source.source_id = p.source_id
	,
)

RawPerson : {
	companyId : Str,
	companyName : Str,
	context : Str,
	createdAt : Str,
	createdByName : Str,
	id : Str,
	jobTitle : Str,
	lifecycle : Str,
	name : Str,
	ownerId : Str,
	ownerName : Str,
	sourceId : Str,
	sourceName : Str,
	updatedAt : Str,
	updatedByName : Str,
	version : I64,
}

RawContact : { id : Str, label : Str, primaryValue : I64, value : Str }

RawPersonMatch : { id : Str, reason : Str, strength : Str }

RawActivity : {
	changeField : Str,
	changeFrom : Str,
	changeTo : Str,
	createdByName : Str,
	id : Str,
	occurredAt : Str,
	subject : Str,
}
