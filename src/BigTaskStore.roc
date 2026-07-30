import pf.Sqlite

import BigTask

## Concrete SQLite adapter for the BigTask feature.
BigTaskStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> BigTaskStore
	new = |db| BigTaskStore.{ db }

	list! : BigTaskStore, BigTask.Query => Try(List(BigTask), [InvalidStoredStatus(Str), DbErr(Sqlite.QueryError)])
	list! = |store, page_query| {
		column = page_query.sortBy.to_str()
		direction = page_query.sortDirection.to_str()
		query = (
			\\SELECT
			\\    ID AS id,
			\\    ReferenceID AS referenceId,
			\\    CustomerReferenceID AS customerReferenceId,
			\\    IFNULL(DateCreated, '') AS dateCreated,
			\\    IFNULL(DateModified, '') AS dateModified,
			\\    IFNULL(Title, '') AS title,
			\\    IFNULL(Description, '') AS description,
			\\    IFNULL(Status, '') AS status,
			\\    IFNULL(Priority, '') AS priority,
			\\    IFNULL(ScheduledStartDate, '') AS scheduledStartDate,
			\\    IFNULL(ScheduledEndDate, '') AS scheduledEndDate,
			\\    IFNULL(ActualStartDate, '') AS actualStartDate,
			\\    IFNULL(ActualEndDate, '') AS actualEndDate,
			\\    IFNULL(SystemName, '') AS systemName,
			\\    IFNULL(Location, '') AS location,
			\\    IFNULL(FileReference, '') AS fileReference,
			\\    IFNULL(Comments, '') AS comments,
			\\    Version AS version
			\\FROM BigTask
			\\ORDER BY ${column} ${direction}
			\\LIMIT :items OFFSET :offset;
			,
		)

		result = Sqlite.query_many!({
			db: store.db,
			query: query,
			params: {
				items: page_query.items.to_i64(),
				offset: page_query.offset(),
			},
			limits: Sqlite.default_query_limits,
		})
		match result {
			Err(err) => Err(DbErr(err))
			Ok(rows) => decode_rows(rows)
		}
	}

	total! : BigTaskStore => Try(I64, Sqlite.QueryError)
	total! = |store|
		Sqlite.query!({
			db: store.db,
			query: "SELECT COUNT(*) AS total FROM BigTask;",
			params: {},
			limits: Sqlite.default_query_limits,
		})

	update! : BigTaskStore, BigTask.Id, BigTask.Version, Str, BigTask.Update => Try(BigTask.Version, BigTask.UpdateError(Sqlite.QueryError))
	update! = |store, id, expected_version, original, update| {
		transaction = Sqlite.begin!(store.db, Immediate)
			? BigTask.UpdateError.StoreFailure

		result = update_in_transaction!(transaction, id, expected_version, original, update)
		match result {
			Err(error) => {
				Sqlite.Transaction.rollback!(transaction) ?? {}
				Err(error)
			}
			Ok(version) => {
				Sqlite.Transaction.commit!(transaction)
					? BigTask.UpdateError.StoreFailure
				Ok(version)
			}
		}
	}
}

## TODO(codec-upgrade): Give the scalar BigTask wrappers stable SQLite codecs,
## add a custom string codec for `BigTask.Status`, and query `BigTask` directly.
## The raw status remains intentional for now because it preserves the invalid
## stored value in `InvalidStoredStatus`.
RawBigTask : {
	id : I64,
	referenceId : Str,
	customerReferenceId : Str,
	dateCreated : Str,
	dateModified : Str,
	title : Str,
	description : Str,
	status : Str,
	priority : Str,
	scheduledStartDate : Str,
	scheduledEndDate : Str,
	actualStartDate : Str,
	actualEndDate : Str,
	systemName : Str,
	location : Str,
	fileReference : Str,
	comments : Str,
	version : I64,
}

decode_rows : List(RawBigTask) -> Try(List(BigTask), [InvalidStoredStatus(Str), ..])
decode_rows = |rows|
	rows.map_try(
		|row|
			match BigTask.from_storage(row) {
				Err(InvalidBigTaskStatus(status)) => Err(InvalidStoredStatus(status))
				Ok(task) => Ok(task)
			},
	)

WriteState : {
	customerReferenceId : Str,
	dateCreated : Str,
	status : Str,
	version : I64,
}

update_in_transaction! : Sqlite.Transaction, BigTask.Id, BigTask.Version, Str, BigTask.Update => Try(BigTask.Version, BigTask.UpdateError(Sqlite.QueryError))
update_in_transaction! = |transaction, id, expected_version, original, update| {
	rows : List(WriteState)
	rows = Sqlite.Transaction.query_many!(
		transaction,
		{
			query: "SELECT CustomerReferenceID AS customerReferenceId, DateCreated AS dateCreated, Status AS status, Version AS version FROM BigTask WHERE ID = :id;",
			params: { id: id.to_i64() },
			limits: Sqlite.default_query_limits,
		},
	) ? BigTask.UpdateError.StoreFailure

	current = match rows {
		[] => return Err(BigTask.UpdateError.NotFound)
		[row, ..] => row
	}
	current_version = BigTask.Version.from_i64(current.version)
	current_value = value_for_update(current, update)
	new_value = new_value_for_update(update)

	if current_value == new_value {
		return Ok(current_version)
	}
	if current_version != expected_version and current_value != original {
		return Err(BigTask.UpdateError.Conflict({ version: current_version, value: current_value }))
	}
	if current_value != original {
		return Err(BigTask.UpdateError.Conflict({ version: current_version, value: current_value }))
	}

	next_version = BigTask.Version.from_i64(current_version.to_i64() + 1)
	match update {
		SetCustomerReference(value) =>
			Sqlite.Transaction.execute!(
				transaction,
				{
					query: "UPDATE BigTask SET CustomerReferenceID = :value, Version = :nextVersion WHERE ID = :id AND Version = :expectedVersion;",
					params: {
						id: id.to_i64(),
						value: value.to_str(),
						expectedVersion: current_version.to_i64(),
						nextVersion: next_version.to_i64(),
					},
				},
			) ? BigTask.UpdateError.StoreFailure
		SetDateCreated(value) =>
			Sqlite.Transaction.execute!(
				transaction,
				{
					query: "UPDATE BigTask SET DateCreated = :value, Version = :nextVersion WHERE ID = :id AND Version = :expectedVersion;",
					params: {
						id: id.to_i64(),
						value: value.to_str(),
						expectedVersion: current_version.to_i64(),
						nextVersion: next_version.to_i64(),
					},
				},
			) ? BigTask.UpdateError.StoreFailure
		SetStatus(value) =>
			Sqlite.Transaction.execute!(
				transaction,
				{
					query: "UPDATE BigTask SET Status = :value, Version = :nextVersion WHERE ID = :id AND Version = :expectedVersion;",
					params: {
						id: id.to_i64(),
						value: value.to_str(),
						expectedVersion: current_version.to_i64(),
						nextVersion: next_version.to_i64(),
					},
				},
			) ? BigTask.UpdateError.StoreFailure
		}
	Ok(next_version)
}

value_for_update : WriteState, BigTask.Update -> Str
value_for_update = |current, update|
	match update {
		SetCustomerReference(_) => current.customerReferenceId
		SetDateCreated(_) => current.dateCreated
		SetStatus(_) => current.status
	}

new_value_for_update : BigTask.Update -> Str
new_value_for_update = |update|
	match update {
		SetCustomerReference(value) => value.to_str()
		SetDateCreated(value) => value.to_str()
		SetStatus(value) => value.to_str()
	}
