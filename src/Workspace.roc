Workspace := {
	id : Id,
	name : Str,
	currency : Currency,
	timezone : Timezone,
	sources : List(Source),
	taskTypes : List(TaskType),
}.{
	Id :: Str.{
		from_str : Str -> Try(Id, [InvalidWorkspaceId])
		from_str = |value|
			if value.trim().is_empty() {
				Err(InvalidWorkspaceId)
			} else {
				Ok(Id.(value.trim()))
			}

		to_str : Id -> Str
		to_str = |Id.(value)| value

		is_eq : _
	}

	Currency :: Str.{
		from_str : Str -> Try(Currency, [InvalidCurrency])
		from_str = |value|
			if value.to_utf8().len() == 3 {
				Ok(Currency.(value.with_ascii_uppercased()))
			} else {
				Err(InvalidCurrency)
			}

		to_str : Currency -> Str
		to_str = |Currency.(value)| value

		is_eq : _
	}

	Timezone :: Str.{
		from_str : Str -> Try(Timezone, [InvalidTimezone])
		from_str = |value| {
			trimmed = value.trim()
			if trimmed.is_empty() or !trimmed.contains("/") {
				Err(InvalidTimezone)
			} else {
				Ok(Timezone.(trimmed))
			}
		}

		to_str : Timezone -> Str
		to_str = |Timezone.(value)| value

		is_eq : _
	}

	SourceId :: Str.{
		from_str : Str -> Try(SourceId, [InvalidSourceId])
		from_str = |value|
			if value.trim().is_empty() {
				Err(InvalidSourceId)
			} else {
				Ok(SourceId.(value.trim()))
			}

		to_str : SourceId -> Str
		to_str = |SourceId.(value)| value

		is_eq : _
	}

	TaskTypeId :: Str.{
		from_str : Str -> Try(TaskTypeId, [InvalidTaskTypeId])
		from_str = |value|
			if value.trim().is_empty() {
				Err(InvalidTaskTypeId)
			} else {
				Ok(TaskTypeId.(value.trim()))
			}

		to_str : TaskTypeId -> Str
		to_str = |TaskTypeId.(value)| value

		is_eq : _
	}

	Source := {
		id : SourceId,
		name : Str,
		position : I64,
		active : Bool,
	}

	TaskType := {
		id : TaskTypeId,
		name : Str,
		position : I64,
		active : Bool,
	}

	LoadError(err) := [MissingWorkspace, MultipleWorkspaces, StoreFailure(err)]

	from_storage : Str, Str, Str, Str, List(Source), List(TaskType) -> Workspace
	from_storage = |id, name, currency, timezone, sources, task_types|
		Workspace.{
			id: Id.(id),
			name,
			currency: Currency.(currency),
			timezone: Timezone.(timezone),
			sources,
			taskTypes: task_types,
		}

	source_from_storage : Str, Str, I64, I64 -> Source
	source_from_storage = |id, name, position, active|
		Source.{
			id: SourceId.(id),
			name,
			position,
			active: active == 1,
		}

	task_type_from_storage : Str, Str, I64, I64 -> TaskType
	task_type_from_storage = |id, name, position, active|
		TaskType.{
			id: TaskTypeId.(id),
			name,
			position,
			active: active == 1,
		}

	timezone_matches : Workspace, Str -> Bool
	timezone_matches = |workspace, configured|
		!configured.trim().is_empty()
			and configured == workspace.timezone.to_str()
}

expect Workspace.Currency.from_str("aud") == Ok(Workspace.Currency.("AUD"))
expect Workspace.Timezone.from_str("Australia/Melbourne").is_ok()
expect Workspace.Timezone.from_str("UTC").is_err()
