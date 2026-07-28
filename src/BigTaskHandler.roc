import pf.Server
import http.Response

import AppError
import BigTask
import BigTaskStore
import BigTaskView
import Http
import Route
import Session
import Web

EditorModel : {
	id : BigTask.Id,
	field : BigTask.Field,
	label : Str,
	value : Str,
	original : Str,
	validation : Str,
	version : BigTask.Version,
}

## Application behavior for the BigTask feature.
##
## Route parsing has already converted URL strings into typed IDs, fields, and
## query values before any of these functions run.
BigTaskHandler := [].{
	page! : store, BigTask.Query, Session => Try(Response, AppError)
		where [
			store.list! : store, BigTask.Query => Try(List(BigTask), list_err),
			store.total! : store => Try(I64, total_err),
		]
	page! = |store, query, session| {
		Http.require_login(session)?
		Store : store
		tasks = Store.list!(store, query) ? AppError.from
		total = Store.total!(store) ? AppError.from
		location = Route.Location.BigTasks(query)
		Ok(
			Http.html(
				200,
				BigTaskView.page({ session, tasks, query, total }),
				[Web.hx_push_header(location)],
			),
		)
	}

	update! : Server.Request, store, Session, BigTask.Id, BigTask.Field => Try(Response, AppError)
		where [
			store.update! : store, BigTask.Id, BigTask.Version, Str, BigTask.Update => Try(BigTask.Version, BigTask.UpdateError(err)),
		]
	update! = |request, store, session, id, field| {
		Http.require_login(session)?
		form = Http.read_form!(request)?
		BigTaskHandler.update_form!(form, store, session, id, field)
	}

	update_form! : Dict(Str, Str), store, Session, BigTask.Id, BigTask.Field => Try(Response, AppError)
		where [
			store.update! : store, BigTask.Id, BigTask.Version, Str, BigTask.Update => Try(BigTask.Version, BigTask.UpdateError(err)),
		]
	update_form! = |form, store, session, id, field| {
		Http.require_login(session)?
		value = form.get(field.form_name()) ?? ""
		original = form.get("original") ?? ""
		version = BigTask.Version.from_str(form.get("version") ?? "")
			? |_| AppError.BadRequest("Expected a valid BigTask version")
		editor_model = {
			id,
			field,
			label: field_label(field),
			value,
			original,
			validation: "",
			version,
		}

		result = BigTask.update!(store, id, version, field, original, value)
		BigTaskHandler.editor_response(editor_model, result)
	}

	editor_response : EditorModel, Try(BigTask.Version, BigTask.UpdateError(err)) -> Try(Response, AppError)
	editor_response = |editor_model, result|
		match result {
			Ok(version) => {
				Ok(Http.html(200, BigTaskView.editor({ ..editor_model, version, original: editor_model.value }), []))
			}
			Err(BigTask.UpdateError.InvalidValue) =>
				Ok(
					Http.html(
						422,
						BigTaskView.editor({
							..editor_model,
							validation: validation_message(editor_model.field),
						}),
						[],
					),
				)
			Err(BigTask.UpdateError.Conflict(current)) =>
				Ok(
					Http.html(
						409,
						BigTaskView.editor({
							..editor_model,
							version: current.version,
							original: current.value,
							validation: "This field changed elsewhere. Review your value and edit again to retry.",
						}),
						[],
					),
				)
			Err(BigTask.UpdateError.NotFound) =>
				Err(AppError.NotFound("BigTask not found"))
			Err(BigTask.UpdateError.StoreFailure(error)) =>
				Err(AppError.from(error))
			}

	csv : () -> Response
	csv = || {
		body = (
			\\ID,CustomerReferenceID,DateCreated,Status
			\\1,12345,2021-01-01,Raised
			\\2,67890,2021-01-02,Completed
			\\3,54321,2021-01-03,Deferred
			,
		).to_utf8()
		Response.from_status(200)
			.with_headers([
				{ name: "Content-Type", value: "text/csv; charset=utf-8" },
				{ name: "Content-Disposition", value: "attachment; filename=table.csv" },
				{ name: "Content-Length", value: body.len().to_str() },
			])
			.with_body(body)
	}
}

field_label : BigTask.Field -> Str
field_label = |field|
	match field {
		BigTask.Field.CustomerReferenceField => "Customer reference"
		BigTask.Field.DateCreatedField => "Date created"
		BigTask.Field.StatusField => "Status"
	}

validation_message : BigTask.Field -> Str
validation_message = |field|
	match field {
		BigTask.Field.CustomerReferenceField => "Must be a number between 0 and 100,000."
		BigTask.Field.DateCreatedField => "Must use date format yyyy-mm-dd."
		BigTask.Field.StatusField => "Choose a valid status."
	}

expect {
	model = {
		id: BigTask.Id.from_i64(1),
		field: BigTask.Field.StatusField,
		label: "Status",
		value: "Unknown",
		original: "Raised",
		validation: "",
		version: BigTask.Version.initial,
	}
	result = BigTaskHandler.editor_response(model, Err(BigTask.UpdateError.InvalidValue))
	match result {
		Ok(response) =>
			Response.status(response) == 422
				and Str.from_utf8_lossy(Response.body(response))
					.contains("Choose a valid status.")
		Err(_) => False
	}
}

expect {
	model = {
		id: BigTask.Id.from_i64(1),
		field: BigTask.Field.StatusField,
		label: "Status",
		value: "Approved",
		original: "Raised",
		validation: "",
		version: BigTask.Version.initial,
	}
	result = BigTaskHandler.editor_response(model, Ok(BigTask.Version.from_i64(2)))
	match result {
		Ok(response) => Response.status(response) == 200
		Err(_) => False
	}
}

expect match BigTaskHandler.editor_response(
	{
		id: BigTask.Id.from_i64(1),
		field: BigTask.Field.StatusField,
		label: "Status",
		value: "Approved",
		original: "Raised",
		validation: "",
		version: BigTask.Version.initial,
	},
	Err(BigTask.UpdateError.StoreFailure(DatabaseUnavailable)),
) {
	Err(AppError.Internal(_)) => True
	_ => False
}
