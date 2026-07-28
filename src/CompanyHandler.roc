import http.Response
import pf.Server
import pf.Utc

import Actor
import AppError
import Company
import CompanyStore
import CompanyView
import Http
import Route
import Web

CompanyHandler := [].{
	page! : CompanyStore, Actor, Company.Filter => Try(Response, AppError)
	page! = |store, actor, filter|
		match CompanyStore.list!(store, filter) {
			Ok(companies) =>
				Ok(
					Http.html(
						200,
						CompanyView.page({ actor, companies, filter }),
						[],
					),
				)
			Err(error) => Err(AppError.from(error))
		}

	detail! : CompanyStore, Actor, Company.Id => Try(Response, AppError)
	detail! = |store, actor, id|
		match CompanyStore.find!(store, id) {
			Ok(company) => Ok(Http.html(200, CompanyView.detail(actor, company), []))
			Err(Company.FindError.NotFound) =>
				Err(AppError.NotFound("company ${id.to_str()}"))
			Err(Company.FindError.StoreFailure(error)) => Err(AppError.from(error))
		}

	new_page : Actor -> Response
	new_page = |actor|
		Http.html(200, CompanyView.new_page(actor, empty_form(), ""), [])

	edit_page! : CompanyStore, Actor, Company.Id => Try(Response, AppError)
	edit_page! = |store, actor, id|
		match CompanyStore.find!(store, id) {
			Ok(company) =>
				Ok(
					Http.html(
						200,
						CompanyView.edit_page(actor, company, form_from_company(company), ""),
						[],
					),
				)
			Err(Company.FindError.NotFound) => Err(AppError.NotFound("company ${id.to_str()}"))
			Err(Company.FindError.StoreFailure(error)) => Err(AppError.from(error))
		}

	preview! : Server.Request, CompanyStore, Actor => Try(Response, AppError)
	preview! = |request, store, actor| {
		form = Http.read_form!(request)?
		preview_form!(form, store, actor)
	}

	preview_form! : Dict(Str, Str), CompanyStore, Actor => Try(Response, AppError)
	preview_form! = |fields, store, actor| {
		form = form_values(fields)
		match company_input(form, actor) {
			Err(message) =>
				Ok(Http.html(422, CompanyView.new_page(actor, form, message), []))
			Ok(input) =>
				match CompanyStore.matches!(store, actor.workspace.id, input) {
					Err(error) => Err(AppError.from(error))
					Ok(matches) if matches.is_empty() =>
						create_input!(store, actor, form, input, False)
					Ok(matches) =>
						Ok(Http.html(200, CompanyView.duplicate_page(actor, form, matches), []))
					}
			}
	}

	create! : Server.Request, CompanyStore, Actor => Try(Response, AppError)
	create! = |request, store, actor| {
		fields = Http.read_form!(request)?
		form = form_values(fields)
		confirmed = fields.get(Route.CompanyInput.to_name(Route.CompanyInput.ConfirmDistinct))
			== Ok("yes")
		if !confirmed {
			return Err(AppError.BadRequest("Duplicate confirmation was missing"))
		}
		match company_input(form, actor) {
			Err(message) =>
				Ok(Http.html(422, CompanyView.new_page(actor, form, message), []))
			Ok(input) => create_input!(store, actor, form, input, True)
		}
	}

	update! : Server.Request, CompanyStore, Actor, Company.Id => Try(Response, AppError)
	update! = |request, store, actor, id| {
		fields = Http.read_form!(request)?
		form = form_values(fields)
		expected_version = Company.Version.from_str(
			field(fields, Route.CompanyInput.Version),
		) ? |_| AppError.BadRequest("Expected a valid company version")

		match company_input(form, actor) {
			Err(message) =>
				match CompanyStore.find!(store, id) {
					Ok(company) =>
						Ok(Http.html(422, CompanyView.edit_page(actor, company, form, message), []))
					Err(Company.FindError.NotFound) => Err(AppError.NotFound("company ${id.to_str()}"))
					Err(Company.FindError.StoreFailure(error)) => Err(AppError.from(error))
				}
			Ok(input) =>
				match CompanyStore.update!(
					store,
					actor.workspace.id,
					actor.member.id,
					id,
					input,
					expected_version,
					Utc.to_iso_8601(Utc.now!()),
				) {
					Ok(_) => Ok(Web.redirect(Route.Location.CompanyDetail(id)))
					Err(Company.UpdateError.NotFound) =>
						Err(AppError.NotFound("company ${id.to_str()}"))
					Err(Company.UpdateError.Conflict(current)) =>
						Ok(Http.html(409, CompanyView.conflict_page(actor, current, form), []))
					Err(Company.UpdateError.StoreFailure(error)) => Err(AppError.from(error))
				}
			}
	}
}

create_input! : CompanyStore, Actor, CompanyView.Form, Company.New, Bool => Try(Response, AppError)
create_input! = |store, actor, form, input, confirm_distinct|
	match CompanyStore.create!(
		store,
		actor.workspace.id,
		actor.member.id,
		input,
		Utc.to_iso_8601(Utc.now!()),
		confirm_distinct,
	) {
		Ok(id) => Ok(Web.redirect(Route.Location.CompanyDetail(id)))
		Err(Company.CreateError.DuplicateMatches(matches)) =>
			Ok(Http.html(200, CompanyView.duplicate_page(actor, form, matches), []))
		Err(Company.CreateError.StoreFailure(error)) => Err(AppError.from(error))
	}

company_input : CompanyView.Form, Actor -> Try(Company.New, Str)
company_input = |form, actor|
	match Company.new(
		form.name,
		actor.member.id,
		form.lifecycle,
		form.website,
		form.phone,
		form.source,
		form.context,
	) {
		Ok(input) => Ok(input)
		Err(Company.NewError.NameWasEmpty) => Err("Enter a company name.")
		Err(Company.NewError.InvalidLifecycle(_)) => Err("Choose a valid lifecycle.")
	}

form_values : Dict(Str, Str) -> CompanyView.Form
form_values = |fields|
	CompanyView.Form.{
		name: field(fields, Route.CompanyInput.Name),
		lifecycle: field(fields, Route.CompanyInput.Lifecycle),
		website: field(fields, Route.CompanyInput.Website),
		phone: field(fields, Route.CompanyInput.Phone),
		source: field(fields, Route.CompanyInput.Source),
		context: field(fields, Route.CompanyInput.Context),
	}

field : Dict(Str, Str), Route.CompanyInput -> Str
field = |fields, input| fields.get(input.to_name()) ?? ""

empty_form : () -> CompanyView.Form
empty_form = ||
	CompanyView.Form.{
		name: "",
		lifecycle: "lead",
		website: "",
		phone: "",
		source: "",
		context: "",
	}

form_from_company : Company -> CompanyView.Form
form_from_company = |company|
	CompanyView.Form.{
		name: company.name.to_str(),
		lifecycle: company.lifecycle.to_str(),
		website: company.website,
		phone: company.phone,
		source: company.sourceId,
		context: company.context,
	}
