import DateTime
import Member

WorkTask := {
	id : Id,
	subject : Subject,
	dueLocal : DateTime.Display,
	assigneeId : Member.Id,
	assigneeName : Str,
	taskTypeId : Str,
	taskTypeName : Str,
	status : Status,
	companyId : Str,
	companyName : Str,
	personId : Str,
	personName : Str,
	context : Str,
	createdByName : Str,
	createdAt : DateTime.Display,
	completedAt : DateTime.Display,
	bucket : Bucket,
}.{
	Id :: Str.{
		from_storage : Str -> Id
		from_storage = |value| Id.(value)

		to_str : Id -> Str
		to_str = |Id.(value)| value

		is_eq : _
	}

	Subject :: Str.{
		from_str : Str -> Try(Subject, [TaskSubjectWasEmpty])
		from_str = |value|
			if value.trim().is_empty() {
				Err(TaskSubjectWasEmpty)
			} else {
				Ok(Subject.(value.trim()))
			}

		to_str : Subject -> Str
		to_str = |Subject.(value)| value

		is_eq : _
	}

	Status := [Open, Completed, Cancelled].{
		from_storage : Str -> Status
		from_storage = |value|
			match value {
				"open" => Open
				"completed" => Completed
				_ => Cancelled
			}

		to_str : Status -> Str
		to_str = |status|
			match status {
				Open => "open"
				Completed => "completed"
				Cancelled => "cancelled"
			}

		is_eq : _
	}

	Bucket := [Overdue, Today, Upcoming, Done].{
		to_label : Bucket -> Str
		to_label = |bucket|
			match bucket {
				Overdue => "Overdue"
				Today => "Due today"
				Upcoming => "Upcoming"
				Done => "Done"
			}

		is_eq : _
	}

	Related := [Company(Str), Person(Str)]

	New := {
		subject : Subject,
		dueLocal : Str,
		assigneeId : Member.Id,
		taskTypeId : Str,
		related : Related,
		context : Str,
	}

	NewError := [SubjectWasEmpty, DueWasInvalid, RelatedRecordMissing]

	new : Str, Str, Member.Id, Str, Related, Str -> Try(New, NewError)
	new = |subject, due_local, assignee_id, task_type_id, related, context|
		match Subject.from_str(subject) {
			Err(_) => Err(NewError.SubjectWasEmpty)
			Ok(valid_subject) =>
				if due_local.trim().to_utf8().len() < 16 or !due_local.contains("T") {
					Err(NewError.DueWasInvalid)
				} else {
					related_id = match related {
						Company(id) => id
						Person(id) => id
					}
					if related_id.trim().is_empty() {
						Err(NewError.RelatedRecordMissing)
					} else {
						Ok(
							New.{
								subject: valid_subject,
								dueLocal: due_local.trim(),
								assigneeId: assignee_id,
								taskTypeId: task_type_id,
								related,
								context: context.trim(),
							},
						)
					}
				}
			}

	bucket_for : Status, Str, Str -> Bucket
	bucket_for = |status, due_local, today|
		if status != Status.Open {
			Bucket.Done
		} else {
			due_date = due_local.split_on("T").first() ?? due_local
			due_number = date_number(due_date)
			today_number = date_number(today)
			if due_number < today_number {
				Bucket.Overdue
			} else if due_date == today {
				Bucket.Today
			} else {
				Bucket.Upcoming
			}
		}

	from_storage : {
		assigneeId : Str,
		assigneeName : Str,
		companyId : Str,
		companyName : Str,
		completedAt : Str,
		context : Str,
		createdAt : Str,
		createdByName : Str,
		dueLocal : Str,
		id : Str,
		personId : Str,
		personName : Str,
		status : Str,
		subject : Str,
		taskTypeId : Str,
		taskTypeName : Str,
	},
	Str -> WorkTask
	from_storage = |row, today| {
		status = Status.from_storage(row.status)
		WorkTask.{
			id: Id.(row.id),
			subject: Subject.(row.subject),
			dueLocal: DateTime.Display.from_local_storage(row.dueLocal),
			assigneeId: Member.Id.from_storage(row.assigneeId),
			assigneeName: row.assigneeName,
			taskTypeId: row.taskTypeId,
			taskTypeName: row.taskTypeName,
			status,
			companyId: row.companyId,
			companyName: row.companyName,
			personId: row.personId,
			personName: row.personName,
			context: row.context,
			createdByName: row.createdByName,
			createdAt: DateTime.Display.from_local_storage(row.createdAt),
			completedAt: DateTime.Display.from_local_storage(row.completedAt),
			bucket: bucket_for(status, row.dueLocal, today),
		}
	}
}

date_number : Str -> I64
date_number = |value|
	I64.from_str(Str.join_with(value.split_on("-"), "")) ?? 0

expect WorkTask.bucket_for(WorkTask.Status.Open, "2026-07-27T17:00", "2026-07-28") == WorkTask.Bucket.Overdue
expect WorkTask.bucket_for(WorkTask.Status.Open, "2026-07-28T09:00", "2026-07-28") == WorkTask.Bucket.Today
expect WorkTask.bucket_for(WorkTask.Status.Open, "2026-07-29T09:00", "2026-07-28") == WorkTask.Bucket.Upcoming
