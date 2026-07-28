Activity := {
	id : Str,
	occurredAt : Str,
	createdByName : Str,
	subject : Str,
	changeField : Str,
	changeFrom : Str,
	changeTo : Str,
}.{
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
			occurredAt: row.occurredAt,
			createdByName: row.createdByName,
			subject: row.subject,
			changeField: row.changeField,
			changeFrom: row.changeFrom,
			changeTo: row.changeTo,
		}

	summary : Activity -> Str
	summary = |activity|
		if activity.changeField.is_empty() {
			activity.subject
		} else {
			"${activity.changeField}: ${activity.changeFrom} → ${activity.changeTo}"
		}
}
