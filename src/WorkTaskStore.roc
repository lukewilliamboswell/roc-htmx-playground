import pf.Sqlite

import Member
import WorkTask
import Workspace

WorkTaskStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> WorkTaskStore
	new = |db| WorkTaskStore.{ db }

	today! : WorkTaskStore => Try(Str, Sqlite.QueryError)
	today! = |store| {
		row : { today : Str }
		row = Sqlite.query!({
			db: store.db,
			query: "SELECT date('now', 'localtime') AS today;",
			params: {},
			limits: Sqlite.default_query_limits,
		})?
		Ok(row.today)
	}

	for_assignee! : WorkTaskStore, Workspace.Id, Member.Id, Str => Try(List(WorkTask), Sqlite.QueryError)
	for_assignee! = |store, workspace_id, assignee_id, today| {
		rows : List(RawTask)
		rows = Sqlite.query_many!({
			db: store.db,
			query: "${task_select} WHERE t.workspace_id = :workspaceId AND t.assignee_id = :assigneeId AND t.status = 'open' ORDER BY t.due_local, t.created_at;",
			params: {
				workspaceId: workspace_id.to_str(),
				assigneeId: assignee_id.to_str(),
			},
			limits: Sqlite.default_query_limits,
		})?
		Ok(rows.map(|row| WorkTask.from_storage(row, today)))
	}

	for_company! : WorkTaskStore, Str, Str => Try(List(WorkTask), Sqlite.QueryError)
	for_company! = |store, company_id, today|
		list_related!(store, "company", company_id, today)

	for_person! : WorkTaskStore, Str, Str => Try(List(WorkTask), Sqlite.QueryError)
	for_person! = |store, person_id, today|
		list_related!(store, "person", person_id, today)

	create! : WorkTaskStore, Workspace.Id, Member.Id, WorkTask.New, Str => Try(WorkTask.Id, Sqlite.QueryError)
	create! = |store, workspace_id, actor_id, input, now| {
		company_id = match input.related {
			WorkTask.Related.Company(id) => id
			WorkTask.Related.Person(_) => ""
		}
		person_id = match input.related {
			WorkTask.Related.Company(_) => ""
			WorkTask.Related.Person(id) => id
		}
		created : { id : Str }
		created = Sqlite.query!({
			db: store.db,
			query: (
				\\INSERT INTO crm_tasks (
				\\ task_id, workspace_id, subject, due_local, due_at_utc,
				\\ assignee_id, task_type_id, status, company_id, person_id,
				\\ context, created_by_id, created_at, version
				\\) VALUES (
				\\ 'task-' || lower(hex(randomblob(16))), :workspaceId, :subject,
				\\ :dueLocal, CAST(strftime('%s', :dueLocal, 'utc') AS INTEGER),
				\\ :assigneeId, :taskTypeId, 'open', :companyId, :personId,
				\\ :context, :actorId, :now, 1
				\\) RETURNING task_id AS id;
				,
			),
			params: {
				workspaceId: workspace_id.to_str(),
				subject: input.subject.to_str(),
				dueLocal: input.dueLocal,
				assigneeId: input.assigneeId.to_str(),
				taskTypeId: input.taskTypeId,
				companyId: company_id,
				personId: person_id,
				context: input.context,
				actorId: actor_id.to_str(),
				now,
			},
			limits: Sqlite.default_query_limits,
		})?
		Ok(WorkTask.Id.from_storage(created.id))
	}

	complete! : WorkTaskStore, Workspace.Id, Member.Id, WorkTask.Id, Str => Try({}, Sqlite.QueryError)
	complete! = |store, workspace_id, actor_id, id, now| {
		Sqlite.execute!({
			db: store.db,
			query: (
				\\UPDATE crm_tasks SET
				\\ status = 'completed', completed_by_id = :actorId,
				\\ completed_at = :now, version = version + 1
				\\WHERE task_id = :id AND workspace_id = :workspaceId
				\\  AND status = 'open';
				,
			),
			params: {
				id: id.to_str(),
				workspaceId: workspace_id.to_str(),
				actorId: actor_id.to_str(),
				now,
			},
		})?
		Ok({})
	}
}

list_related! : WorkTaskStore, Str, Str, Str => Try(List(WorkTask), Sqlite.QueryError)
list_related! = |store, kind, related_id, today| {
	column = if kind == "company" {
		"t.company_id"
	} else {
		"t.person_id"
	}
	rows : List(RawTask)
	rows = Sqlite.query_many!({
		db: store.db,
		query: "${task_select} WHERE ${column} = :relatedId AND t.status = 'open' ORDER BY t.due_local, t.created_at;",
		params: { relatedId: related_id },
		limits: Sqlite.default_query_limits,
	})?
	Ok(rows.map(|row| WorkTask.from_storage(row, today)))
}

task_select = (
	\\SELECT t.task_id AS id, t.subject, t.due_local AS dueLocal,
	\\ t.assignee_id AS assigneeId, assignee.name AS assigneeName,
	\\ t.task_type_id AS taskTypeId, IFNULL(task_type.name, '') AS taskTypeName,
	\\ t.status, t.company_id AS companyId, IFNULL(company.name, '') AS companyName,
	\\ t.person_id AS personId, IFNULL(person.name, '') AS personName,
	\\ t.context, creator.name AS createdByName,
	\\ strftime('%Y-%m-%dT%H:%M', t.created_at, 'localtime') AS createdAt,
	\\ CASE WHEN t.completed_at = '' THEN ''
	\\      ELSE strftime('%Y-%m-%dT%H:%M', t.completed_at, 'localtime') END AS completedAt
	\\FROM crm_tasks t
	\\JOIN members assignee ON assignee.member_id = t.assignee_id
	\\JOIN members creator ON creator.member_id = t.created_by_id
	\\LEFT JOIN task_types task_type
	\\ ON task_type.workspace_id = t.workspace_id AND task_type.task_type_id = t.task_type_id
	\\LEFT JOIN companies company ON company.company_id = t.company_id
	\\LEFT JOIN people person ON person.person_id = t.person_id
	,
)

RawTask : {
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
}
