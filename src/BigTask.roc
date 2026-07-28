BigTask := {
	id : Id,
	referenceId : Str,
	customerReferenceId : CustomerReference,
	dateCreated : Date,
	dateModified : Str,
	title : Str,
	description : Str,
	status : Status,
	priority : Str,
	scheduledStartDate : Str,
	scheduledEndDate : Str,
	actualStartDate : Str,
	actualEndDate : Str,
	systemName : Str,
	location : Str,
	fileReference : Str,
	comments : Str,
	version : Version,
}.{
	Id :: I64.{
		from_i64 : I64 -> Id
		from_i64 = |value| Id.(value)

		from_str : Str -> Try(Id, [InvalidBigTaskId(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) => Ok(Id.(number))
				Err(_) => Err(InvalidBigTaskId(value))
			}

		to_i64 : Id -> I64
		to_i64 = |Id.(value)| value

		to_str : Id -> Str
		to_str = |id| id.to_i64().to_str()

		is_eq : _
	}

	CustomerReference :: Str.{
		from_str : Str -> Try(CustomerReference, [InvalidCustomerReference(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) if number > 0 and number < 100_000 => Ok(CustomerReference.(value))
				_ => Err(InvalidCustomerReference(value))
			}

		to_str : CustomerReference -> Str
		to_str = |CustomerReference.(value)| value

		is_eq : _
	}

	Version :: I64.{
		initial : Version
		initial = Version.(1)

		from_i64 : I64 -> Version
		from_i64 = |value| Version.(value)

		from_str : Str -> Try(Version, [InvalidBigTaskVersion])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) if number > 0 => Ok(Version.(number))
				_ => Err(InvalidBigTaskVersion)
			}

		to_i64 : Version -> I64
		to_i64 = |Version.(value)| value

		to_str : Version -> Str
		to_str = |version| version.to_i64().to_str()

		is_eq : _
	}

	Date :: Str.{

		## TODO(literal-conversion): Add `from_quote` if validated Date literals
		## become common in fixtures or configuration. Dynamic HTTP and database
		## values must still follow their runtime parsing paths.
		from_str : Str -> Try(Date, [InvalidDate(Str)])
		from_str = |value|
			if valid_date(value) {
				Ok(Date.(value))
			} else {
				Err(InvalidDate(value))
			}

		to_str : Date -> Str
		to_str = |Date.(value)| value

		is_eq : _
	}

	Status := [Raised, Completed, Deferred, Approved, InProgress].{

		## TODO(codec-upgrade): Implement custom string-backed `parser_for` and
		## `encoder_for` using `from_str`/`to_str`; derived tag encoding would not
		## match the persisted labels.
		from_str : Str -> Try(Status, [InvalidBigTaskStatus(Str)])
		from_str = |value|
			match value {
				"Raised" => Ok(Raised)
				"Completed" => Ok(Completed)
				"Deferred" => Ok(Deferred)
				"Approved" => Ok(Approved)
				"In-Progress" => Ok(InProgress)
				_ => Err(InvalidBigTaskStatus(value))
			}

		to_str : Status -> Str
		to_str = |status|
			match status {
				Raised => "Raised"
				Completed => "Completed"
				Deferred => "Deferred"
				Approved => "Approved"
				InProgress => "In-Progress"
			}

		is_eq : _
	}

	Page :: I64.{
		from_i64 : I64 -> Page
		from_i64 = |value| Page.(
			if value > 0 {
				value
			} else {
				1
			},
		)

		from_str : Str -> Try(Page, [InvalidPage(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) if number > 0 => Ok(Page.(number))
				_ => Err(InvalidPage(value))
			}

		default : Page
		default = Page.(1)

		to_i64 : Page -> I64
		to_i64 = |Page.(value)| value

		to_str : Page -> Str
		to_str = |page| page.to_i64().to_str()

		is_eq : _
	}

	ItemsPerPage :: I64.{
		from_i64 : I64 -> ItemsPerPage
		from_i64 = |value| ItemsPerPage.(
			if value > 0 {
				value
			} else {
				25
			},
		)

		from_str : Str -> Try(ItemsPerPage, [InvalidItemsPerPage(Str)])
		from_str = |value|
			match I64.from_str(value) {
				Ok(number) if number > 0 => Ok(ItemsPerPage.(number))
				_ => Err(InvalidItemsPerPage(value))
			}

		default : ItemsPerPage
		default = ItemsPerPage.(25)

		to_i64 : ItemsPerPage -> I64
		to_i64 = |ItemsPerPage.(value)| value

		to_str : ItemsPerPage -> Str
		to_str = |items| items.to_i64().to_str()

		is_eq : _
	}

	SortDirection := [Ascending, Descending].{
		from_str : Str -> SortDirection
		from_str = |value|
			match value.with_ascii_lowercased() {
				"desc" => Descending
				_ => Ascending
			}

		to_str : SortDirection -> Str
		to_str = |direction|
			match direction {
				Ascending => "asc"
				Descending => "desc"
			}

		is_eq : _
	}

	SortColumn := [
		ById,
		ByReferenceId,
		ByCustomerReferenceId,
		ByDateCreated,
		ByDateModified,
		ByTitle,
		ByDescription,
		ByStatus,
		ByPriority,
		ByScheduledStartDate,
		ByScheduledEndDate,
		ByActualStartDate,
		ByActualEndDate,
		BySystemName,
		ByLocation,
		ByFileReference,
		ByComments,
	].{
		from_str : Str -> SortColumn
		from_str = |value|
			match value {
				"ReferenceID" => ByReferenceId
				"CustomerReferenceID" => ByCustomerReferenceId
				"DateCreated" => ByDateCreated
				"DateModified" => ByDateModified
				"Title" => ByTitle
				"Description" => ByDescription
				"Status" => ByStatus
				"Priority" => ByPriority
				"ScheduledStartDate" => ByScheduledStartDate
				"ScheduledEndDate" => ByScheduledEndDate
				"ActualStartDate" => ByActualStartDate
				"ActualEndDate" => ByActualEndDate
				"SystemName" => BySystemName
				"Location" => ByLocation
				"FileReference" => ByFileReference
				"Comments" => ByComments
				_ => ById
			}

		to_str : SortColumn -> Str
		to_str = |column|
			match column {
				ById => "ID"
				ByReferenceId => "ReferenceID"
				ByCustomerReferenceId => "CustomerReferenceID"
				ByDateCreated => "DateCreated"
				ByDateModified => "DateModified"
				ByTitle => "Title"
				ByDescription => "Description"
				ByStatus => "Status"
				ByPriority => "Priority"
				ByScheduledStartDate => "ScheduledStartDate"
				ByScheduledEndDate => "ScheduledEndDate"
				ByActualStartDate => "ActualStartDate"
				ByActualEndDate => "ActualEndDate"
				BySystemName => "SystemName"
				ByLocation => "Location"
				ByFileReference => "FileReference"
				ByComments => "Comments"
			}

		is_eq : _
	}

	Query := {
		page : Page,
		items : ItemsPerPage,
		sortBy : SortColumn,
		sortDirection : SortDirection,
	}.{
		default : Query
		default = Query.{
			page: Page.default,
			items: ItemsPerPage.default,
			sortBy: ById,
			sortDirection: Ascending,
		}

		from_pairs : List((Str, Str)) -> Query
		from_pairs = |pairs| {
			page = match find_pair(pairs, "page") {
				Ok(value) => Page.from_str(value) ?? Page.default
				Err(_) => Page.default
			}
			current_items = match find_pair(pairs, "items") {
				Ok(value) => ItemsPerPage.from_str(value) ?? ItemsPerPage.default
				Err(_) => ItemsPerPage.default
			}
			items = match find_pair(pairs, "updateItemsPerPage") {
				Ok(value) => ItemsPerPage.from_str(value) ?? current_items
				Err(_) => current_items
			}
			sort_by = SortColumn.from_str(find_pair(pairs, "sortBy") ?? "ID")
			direction = SortDirection.from_str(find_pair(pairs, "sortDirection") ?? "asc")
			Query.{ page, items, sortBy: sort_by, sortDirection: direction }
		}

		offset : Query -> I64
		offset = |query| (query.page.to_i64() - 1) * query.items.to_i64()

		to_query : Query -> Str
		to_query = |query|
			"page=${query.page.to_str()}&items=${query.items.to_str()}&sortBy=${query.sortBy.to_str()}&sortDirection=${query.sortDirection.to_str()}"
	}

	Field := [CustomerReferenceField, DateCreatedField, StatusField].{
		from_url_segment : Str -> Try(Field, [InvalidBigTaskField(Str)])
		from_url_segment = |segment|
			match segment {
				"customerId" => Ok(CustomerReferenceField)
				"dateCreated" => Ok(DateCreatedField)
				"status" => Ok(StatusField)
				_ => Err(InvalidBigTaskField(segment))
			}

		to_url_segment : Field -> Str
		to_url_segment = |field|
			match field {
				CustomerReferenceField => "customerId"
				DateCreatedField => "dateCreated"
				StatusField => "status"
			}

		form_name : Field -> Str
		form_name = |field|
			match field {
				CustomerReferenceField => "CustomerReferenceID"
				DateCreatedField => "DateCreated"
				StatusField => "Status"
			}

		is_eq : _
	}

	Update := [
		SetCustomerReference(CustomerReference),
		SetDateCreated(Date),
		SetStatus(Status),
	]

	UpdateError(err) := [InvalidValue, Conflict(Version), NotFound, StoreFailure(err)]

	complete_update : Try(Version, err) -> Try(Version, UpdateError(err))
	complete_update = |stored|
		match stored {
			Ok(version) => Ok(version)
			Err(error) => Err(UpdateError.StoreFailure(error))
		}

	update : Field, Str -> Try(Update, [InvalidCustomerReferenceValue(Str), InvalidDateValue(Str), InvalidStatusValue(Str)])
	update = |field, value|
		match field {
			CustomerReferenceField =>
				match CustomerReference.from_str(value) {
					Ok(parsed) => Ok(SetCustomerReference(parsed))
					Err(_) => Err(InvalidCustomerReferenceValue(value))
				}
			DateCreatedField =>
				match Date.from_str(value) {
					Ok(parsed) => Ok(SetDateCreated(parsed))
					Err(_) => Err(InvalidDateValue(value))
				}
			StatusField =>
				match Status.from_str(value) {
					Ok(parsed) => Ok(SetStatus(parsed))
					Err(_) => Err(InvalidStatusValue(value))
				}
			}

	update! : store, Id, Version, Field, Str => Try(Version, UpdateError(err))
		where [
			store.update! : store, Id, Version, Update => Try(Version, UpdateError(err)),
		]
	update! = |store, id, version, field, value| {
		Store : store
		match BigTask.update(field, value) {
			Err(_) => Err(UpdateError.InvalidValue)
			Ok(update_value) => Store.update!(store, id, version, update_value)
		}
	}

	from_storage : {
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
	} -> Try(BigTask, [InvalidBigTaskStatus(Str)])
	from_storage = |row| {
		parsed_status = Status.from_str(row.status)?
		Ok(
			BigTask.{
				id: Id.from_i64(row.id),
				referenceId: row.referenceId,
				customerReferenceId: CustomerReference.(row.customerReferenceId),
				dateCreated: Date.(row.dateCreated),
				dateModified: row.dateModified,
				title: row.title,
				description: row.description,
				status: parsed_status,
				priority: row.priority,
				scheduledStartDate: row.scheduledStartDate,
				scheduledEndDate: row.scheduledEndDate,
				actualStartDate: row.actualStartDate,
				actualEndDate: row.actualEndDate,
				systemName: row.systemName,
				location: row.location,
				fileReference: row.fileReference,
				comments: row.comments,
				version: Version.from_i64(row.version),
			},
		)
	}
}

find_pair : List((Str, Str)), Str -> Try(Str, [MissingQueryParameter])
find_pair = |pairs, name|
	match pairs {
		[] => Err(MissingQueryParameter)
		[(key, value), .. as rest] =>
			if key == name {
				Ok(value)
			} else {
				find_pair(rest, name)
			}
		}

valid_date : Str -> Bool
valid_date = |value|
	match value.split_on("-") {
		[year, month, day] =>
			year.to_utf8().len() == 4
				and month.to_utf8().len() == 2
					and day.to_utf8().len() == 2
						and I64.from_str(year).is_ok()
							and I64.from_str(month).is_ok()
								and I64.from_str(day).is_ok()
		_ => False
	}

expect match BigTask.Id.from_str("7") {
	Ok(id) => id.to_i64() == 7
	Err(_) => False
}
expect BigTask.Query.from_pairs([("page", "2"), ("sortDirection", "desc")]).offset() == 25
expect BigTask.Field.from_url_segment("status") == Ok(StatusField)
expect BigTask.update(BigTask.Field.CustomerReferenceField, "0").is_err()
expect BigTask.update(BigTask.Field.DateCreatedField, "28/07/2026").is_err()
expect match BigTask.complete_update(Err(DatabaseUnavailable)) {
	Err(BigTask.UpdateError.StoreFailure(DatabaseUnavailable)) => True
	_ => False
}
