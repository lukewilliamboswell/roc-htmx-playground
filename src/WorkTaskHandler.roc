import pf.Server
import pf.Utc
import http.Response

import Actor
import AppError
import Company
import Http
import Person
import Route
import Web
import WorkTask
import WorkTaskStore
import WorkTaskView

WorkTaskHandler := [].{
	page! : WorkTaskStore, Actor => Try(Response, AppError)
	page! = |store, actor| {
		today = WorkTaskStore.today!(store) ? AppError.from
		tasks = WorkTaskStore.for_assignee!(
			store,
			actor.workspace.id,
			actor.member.id,
			today,
		) ? AppError.from
		Ok(Http.html(200, WorkTaskView.page(actor, tasks), []))
	}

	create! : Server.Request, WorkTaskStore, Actor, WorkTask.Related => Try(Response, AppError)
	create! = |request, store, actor, related| {
		fields = Http.read_form!(request)?
		input = WorkTask.new(
			field(fields, Route.TaskInput.Subject),
			field(fields, Route.TaskInput.DueLocal),
			actor.member.id,
			field(fields, Route.TaskInput.TaskType),
			related,
			field(fields, Route.TaskInput.Context),
		) ? |error|
			match error {
				WorkTask.NewError.SubjectWasEmpty => AppError.BadRequest("Enter a task subject")
				WorkTask.NewError.DueWasInvalid =>
					AppError.BadRequest("Choose a valid local due date and time")
				WorkTask.NewError.RelatedRecordMissing =>
					AppError.BadRequest("Choose a related CRM record")
				}
		_ = WorkTaskStore.create!(
			store,
			actor.workspace.id,
			actor.member.id,
			input,
			Utc.to_iso_8601(Utc.now!()),
		) ? AppError.from
		Ok(
			match related {
				WorkTask.Related.Company(id) =>
					Web.redirect(Route.Location.CompanyDetail(Company.Id.from_storage(id)))
				WorkTask.Related.Person(id) =>
					Web.redirect(Route.Location.PersonDetail(Person.Id.from_storage(id)))
				},
		)
	}

	complete! : WorkTaskStore, Actor, WorkTask.Id => Try(Response, AppError)
	complete! = |store, actor, id| {
		WorkTaskStore.complete!(
			store,
			actor.workspace.id,
			actor.member.id,
			id,
			Utc.to_iso_8601(Utc.now!()),
		) ? AppError.from
		Ok(Web.redirect(Route.Page.Work))
	}
}

field : Dict(Str, Str), Route.TaskInput -> Str
field = |fields, input| fields.get(input.to_name()) ?? ""
