import DateTime

Activity := {
	id : Str,
	occurredAt : DateTime.Display,
	createdByName : Str,
	subject : Str,
	change : Change,
}.{
	Change := [
		LifecycleChanged({ from : Str, to : Str }),
		OwnerChanged({ from : Str, to : Str }),
		Recorded({ field : Str, from : Str, to : Str }),
	].{
		is_eq : _
	}

	from_storage : {
		changeField : Str,
		changeFrom : Str,
		changeTo : Str,
		createdByName : Str,
		id : Str,
		occurredAt : Str,
		subject : Str,
	} -> Activity
	from_storage = |row|
		Activity.{
			id: row.id,
			occurredAt: DateTime.Display.from_local_storage(row.occurredAt),
			createdByName: row.createdByName,
			subject: row.subject,
			change: match row.changeField {
				"owner" => OwnerChanged({ from: row.changeFrom, to: row.changeTo })
				"lifecycle" => LifecycleChanged({ from: row.changeFrom, to: row.changeTo })
				field => Recorded({ field, from: row.changeFrom, to: row.changeTo })
			},
		}

	summary : Activity -> Str
	summary = |activity|
		match activity.change {
			OwnerChanged(change) => "Owner: ${change.from} → ${change.to}"
			LifecycleChanged(change) => "Lifecycle: ${change.from} → ${change.to}"
			Recorded(change) if change.field.is_empty() => activity.subject
			Recorded(change) => "${change.field}: ${change.from} → ${change.to}"
		}
}
