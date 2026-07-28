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
			\\    IFNULL(Comments, '') AS comments
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
	total! = |store| {
		row : { total : I64 }
		row = Sqlite.query!({
			db: store.db,
			query: "SELECT COUNT(*) AS total FROM BigTask;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(row.total)
	}

	update! : BigTaskStore, BigTask.Id, BigTask.Update => Try({}, Sqlite.QueryError)
	update! = |store, id, update|
		match update {
			SetCustomerReference(value) =>
				Sqlite.execute!({
					db: store.db,
					query: "UPDATE BigTask SET CustomerReferenceID = :value WHERE ID = :id;",
					params: { id: id.to_i64(), value: value.to_str() },
				})
			SetDateCreated(value) =>
				Sqlite.execute!({
					db: store.db,
					query: "UPDATE BigTask SET DateCreated = :value WHERE ID = :id;",
					params: { id: id.to_i64(), value: value.to_str() },
				})
			SetStatus(value) =>
				Sqlite.execute!({
					db: store.db,
					query: "UPDATE BigTask SET Status = :value WHERE ID = :id;",
					params: { id: id.to_i64(), value: value.to_str() },
				})
			}
}

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
}

decode_rows : List(RawBigTask) -> Try(List(BigTask), [InvalidStoredStatus(Str), ..])
decode_rows = |rows|
	match rows {
		[] => Ok([])
		[row, .. as rest] =>
			match BigTask.from_storage(row) {
				Err(InvalidBigTaskStatus(status)) => Err(InvalidStoredStatus(status))
				Ok(task) =>
					match decode_rows(rest) {
						Err(err) => Err(err)
						Ok(tasks) => Ok(tasks.prepend(task))
					}
				}
		}
