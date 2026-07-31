import pf.Server
import http.Response

import Actor
import AiStore
import AppError
import Company
import CompanyStore
import DateTime
import Http
import Member
import Person
import PersonStore
import PersonView
import Route
import Web
import WorkTaskStore

PersonHandler := [].{
	page! : PersonStore, Actor, Person.Filter => Try(Response, AppError)
	page! = |store, actor, filter|
		match PersonStore.list!(store, filter.to_str()) {
			Ok(people) => Ok(Http.html(200, PersonView.page(actor, people, filter), []))
			Err(error) => Err(AppError.from(error))
		}

	detail! : PersonStore, WorkTaskStore, Actor, Person.Id => Try(Response, AppError)
	detail! = |store, tasks, actor, id|
		match PersonStore.find!(store, id) {
			Ok(person) => {
				today = WorkTaskStore.today!(tasks) ? AppError.from
				open_tasks = WorkTaskStore.for_person!(tasks, id.to_str(), today)
					? AppError.from
				history = PersonStore.history!(store, id) ? AppError.from
				Ok(Http.html(200, PersonView.detail(actor, person, open_tasks, history), []))
			}
			Err(Person.FindError.NotFound) => Err(AppError.NotFound("person ${id.to_str()}"))
			Err(Person.FindError.StoreFailure(error)) => Err(AppError.from(error))
		}

	new_page! : CompanyStore, Actor, [None, Some(Company.Id)] => Try(Response, AppError)
	new_page! = |companies, actor, company_id| {
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		origin = match company_id {
			Some(id) => Some(find_origin_company!(companies, id)?)
			None => None
		}
		form = empty_form(origin, actor.member.id.to_str())
		Ok(Http.html(200, PersonView.new_page(actor, company_list, origin, form, "", []), []))
	}

	new_page_with_scanner! : CompanyStore, Actor, [None, Some(Company.Id)], Str => Try(Response, AppError)
	new_page_with_scanner! = |companies, actor, company_id, grant_id| {
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		origin = match company_id {
			Some(id) => Some(find_origin_company!(companies, id)?)
			None => None
		}
		form = empty_form(origin, actor.member.id.to_str())
		scanner = PersonView.Scanner.Ready({
			grantId: grant_id,
			message: "",
			error: False,
			review: NoReview,
		})
		Ok(
			Http.html(
				200,
				PersonView.new_page_with_scanner(
					actor,
					company_list,
					origin,
					form,
					"",
					[],
					scanner,
				),
				[],
			),
		)
	}

	form_from_fields : Dict(Str, Str) -> PersonView.Form
	form_from_fields = |fields| form_values(fields)

	scanner_page! : CompanyStore, Actor, PersonView.Form, PersonView.Scanner, U16 => Try(Response, AppError)
	scanner_page! = |companies, actor, form, scanner, status| {
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		origin = form_origin!(companies, form.originCompany)?
		Ok(
			Http.html(
				status,
				PersonView.new_page_with_scanner(
					actor,
					company_list,
					origin,
					form,
					"",
					[],
					scanner,
				),
				[],
			),
		)
	}

	edit_page! : PersonStore, CompanyStore, Actor, Person.Id => Try(Response, AppError)
	edit_page! = |people, companies, actor, id| {
		person = match PersonStore.find!(people, id) {
			Ok(value) => value
			Err(Person.FindError.NotFound) =>
				return Err(AppError.NotFound("person ${id.to_str()}"))
			Err(Person.FindError.StoreFailure(error)) => return Err(AppError.from(error))
		}
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		Ok(
			Http.html(
				200,
				PersonView.edit_page(actor, company_list, person, form_from_person(person), ""),
				[],
			),
		)
	}

	preview! : Server.Request, PersonStore, CompanyStore, AiStore, Actor => Try(Response, AppError)
	preview! = |request, people, companies, ai_store, actor| {
		fields = Http.read_form!(request)?
		form = form_values(fields)
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		origin = form_origin!(companies, form.originCompany)?
		match person_input(form, actor) {
			Err(message) =>
				Ok(Http.html(422, PersonView.new_page(actor, company_list, origin, form, message, []), []))
			Ok(input) =>
				match PersonStore.matches!(people, actor.workspace.id, input) {
					Err(error) => Err(AppError.from(error))
					Ok(matches) if matches.is_empty() =>
						create_input!(people, ai_store, actor, company_list, origin, form, input, False)
					Ok(matches) =>
						Ok(Http.html(200, PersonView.new_page(actor, company_list, origin, form, "", matches), []))
					}
			}
	}

	create! : Server.Request, PersonStore, CompanyStore, AiStore, Actor => Try(Response, AppError)
	create! = |request, people, companies, ai_store, actor| {
		fields = Http.read_form!(request)?
		form = form_values(fields)
		confirmed = field(fields, Route.PersonInput.ConfirmDistinct) == "yes"
		if !confirmed {
			return Err(AppError.BadRequest("Duplicate confirmation was missing"))
		}
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		origin = form_origin!(companies, form.originCompany)?
		match person_input(form, actor) {
			Err(message) =>
				Ok(Http.html(422, PersonView.new_page(actor, company_list, origin, form, message, []), []))
			Ok(input) => create_input!(people, ai_store, actor, company_list, origin, form, input, True)
		}
	}

	update! : Server.Request, PersonStore, CompanyStore, Actor, Person.Id => Try(Response, AppError)
	update! = |request, people, companies, actor, id| {
		fields = Http.read_form!(request)?
		form = form_values(fields)
		version = Company.Version.from_str(field(fields, Route.PersonInput.Version))
			? |_| AppError.BadRequest("Expected a valid person version")
		company_list = CompanyStore.list!(companies, Company.Filter.empty)
			? AppError.from
		match person_input(form, actor) {
			Err(message) =>
				render_edit_error!(people, actor, company_list, id, form, message, 422)
			Ok(input) =>
				match PersonStore.update!(
					people,
					actor.workspace.id,
					actor.member.id,
					id,
					input,
					version,
					DateTime.now_utc!(),
				) {
					Ok(_) => Ok(Web.redirect(Route.Location.PersonDetail(id)))
					Err(Person.UpdateError.NotFound) =>
						Err(AppError.NotFound("person ${id.to_str()}"))
					Err(Person.UpdateError.Conflict(current)) =>
						Ok(
							Http.html(
								409,
								PersonView.edit_page(
									actor,
									company_list,
									current,
									form,
									"This person changed while you were editing. Review your values and submit again.",
								),
								[],
							),
						)
					Err(Person.UpdateError.StoreFailure(error)) => Err(AppError.from(error))
				}
			}
	}

	add_contact! : Server.Request, PersonStore, Person.Id, [Email, Phone] => Try(Response, AppError)
	add_contact! = |request, store, id, kind| {
		fields = Http.read_form!(request)?
		value = field(fields, Route.PersonInput.Value)
		if value.trim().is_empty() {
			return Err(AppError.BadRequest("Enter a contact value"))
		}
		PersonStore.add_contact!(
			store,
			id,
			kind,
			field(fields, Route.PersonInput.Label),
			value,
			field(fields, Route.PersonInput.Primary) == "yes",
		) ? AppError.from
		Ok(Web.redirect(Route.Location.PersonDetail(id)))
	}

	delete_contact! : PersonStore, Person.Id, [Email, Phone], Person.ContactId => Try(Response, AppError)
	delete_contact! = |store, id, kind, contact_id| {
		PersonStore.delete_contact!(store, id, kind, contact_id)
			? AppError.from
		Ok(Web.redirect(Route.Location.PersonDetail(id)))
	}

	make_primary! : PersonStore, Person.Id, [Email, Phone], Person.ContactId => Try(Response, AppError)
	make_primary! = |store, id, kind, contact_id| {
		PersonStore.make_primary!(store, id, kind, contact_id)
			? AppError.from
		Ok(Web.redirect(Route.Location.PersonDetail(id)))
	}
}

create_input! : PersonStore, AiStore, Actor, List(Company), [None, Some(Company)], PersonView.Form, Person.New, Bool => Try(Response, AppError)
create_input! = |store, ai_store, actor, companies, origin, form, input, confirmed|
	match PersonStore.create!(
		store,
		actor.workspace.id,
		actor.member.id,
		input,
		DateTime.now_utc!(),
		confirmed,
	) {
		Ok(id) => {
			if !form.aiRunId.is_empty() {
				AiStore.mark_accepted!(
					ai_store,
					actor.workspace.id,
					actor.member.id,
					form.aiRunId,
				) ? AppError.from
			}
			Ok(Web.redirect(Route.Location.PersonDetail(id)))
		}
		Err(Person.CreateError.DuplicateMatches(matches)) =>
			Ok(Http.html(200, PersonView.new_page(actor, companies, origin, form, "", matches), []))
		Err(Person.CreateError.StoreFailure(error)) => Err(AppError.from(error))
	}

render_edit_error! : PersonStore, Actor, List(Company), Person.Id, PersonView.Form, Str, U16 => Try(Response, AppError)
render_edit_error! = |store, actor, companies, id, form, message, status|
	match PersonStore.find!(store, id) {
		Ok(person) =>
			Ok(Http.html(status, PersonView.edit_page(actor, companies, person, form, message), []))
		Err(Person.FindError.NotFound) => Err(AppError.NotFound("person ${id.to_str()}"))
		Err(Person.FindError.StoreFailure(error)) => Err(AppError.from(error))
	}

person_input : PersonView.Form, Actor -> Try(Person.New, Str)
person_input = |form, actor| {
	owner = Member.Id.from_str(form.owner)
		? |_| "Choose a valid active owner."
	if !actor.workspace.has_active_member(owner) {
		return Err("Choose a valid active owner.")
	}
	match Person.new_with_contacts(
		form.name,
		form.company,
		form.jobTitle,
		owner,
		form.lifecycle,
		form.source,
		form.context,
		form.emails.map(|email| { label: "Work", value: email }),
		form.phones.map(|phone| { label: phone.label, value: phone.value }),
	) {
		Ok(input) => Ok(input)
		Err(Person.NewError.NameWasEmpty) => Err("Enter a person's name.")
		Err(Person.NewError.InvalidLifecycle(_)) => Err("Choose a valid lifecycle.")
	}
}

form_values : Dict(Str, Str) -> PersonView.Form
form_values = |fields|
	PersonView.Form.{
		name: field(fields, Route.PersonInput.Name),
		company: field(fields, Route.PersonInput.Company),
		jobTitle: field(fields, Route.PersonInput.JobTitle),
		owner: field(fields, Route.PersonInput.Owner),
		lifecycle: field(fields, Route.PersonInput.Lifecycle),
		source: field(fields, Route.PersonInput.Source),
		context: field(fields, Route.PersonInput.Context),
		emails: [
			field(fields, Route.PersonInput.Email),
			string_field(fields, "email2"),
			string_field(fields, "email3"),
			string_field(fields, "email4"),
			string_field(fields, "email5"),
		],
		phones: [
			{ label: string_field_or(fields, "phoneType", "Work"), value: field(fields, Route.PersonInput.Phone) },
			{ label: string_field_or(fields, "phoneType2", "Work"), value: string_field(fields, "phone2") },
			{ label: string_field_or(fields, "phoneType3", "Work"), value: string_field(fields, "phone3") },
			{ label: string_field_or(fields, "phoneType4", "Work"), value: string_field(fields, "phone4") },
			{ label: string_field_or(fields, "phoneType5", "Work"), value: string_field(fields, "phone5") },
		],
		originCompany: field(fields, Route.PersonInput.OriginCompany),
		aiRunId: string_field(fields, "aiRunId"),
	}

field : Dict(Str, Str), Route.PersonInput -> Str
field = |fields, input| fields.get(input.to_name()) ?? ""

string_field : Dict(Str, Str), Str -> Str
string_field = |fields, name| fields.get(name) ?? ""

string_field_or : Dict(Str, Str), Str, Str -> Str
string_field_or = |fields, name, fallback| {
	value = string_field(fields, name)
	if value.is_empty() {
		fallback
	} else {
		value
	}
}

empty_form : [None, Some(Company)], Str -> PersonView.Form
empty_form = |origin, owner|
	PersonView.Form.{
		name: "",
		company: match origin {
			Some(company) => company.id.to_str()
			None => ""
		},
		jobTitle: "",
		owner,
		lifecycle: "lead",
		source: "",
		context: "",
		emails: ["", "", "", "", ""],
		phones: [
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
		],
		originCompany: match origin {
			Some(company) => company.id.to_str()
			None => ""
		},
		aiRunId: "",
	}

form_from_person : Person -> PersonView.Form
form_from_person = |person|
	PersonView.Form.{
		name: person.name.to_str(),
		company: person.companyId,
		jobTitle: person.jobTitle,
		owner: person.ownerId.to_str(),
		lifecycle: person.lifecycle.to_str(),
		source: person.sourceId,
		context: person.context,
		emails: ["", "", "", "", ""],
		phones: [
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
			{ label: "Work", value: "" },
		],
		originCompany: "",
		aiRunId: "",
	}

form_origin! : CompanyStore, Str => Try([None, Some(Company)], AppError)
form_origin! = |store, value|
	if value.is_empty() {
		Ok(None)
	} else {
		id = Company.Id.from_str(value)
			? |_| AppError.BadRequest("Expected a valid originating company")
		Ok(Some(find_origin_company!(store, id)?))
	}

find_origin_company! : CompanyStore, Company.Id => Try(Company, AppError)
find_origin_company! = |store, id|
	match CompanyStore.find!(store, id) {
		Ok(company) => Ok(company)
		Err(Company.FindError.NotFound) =>
			Err(AppError.BadRequest("Originating company was not found"))
		Err(Company.FindError.StoreFailure(error)) => Err(AppError.from(error))
	}
