import pf.Server
import pf.Url

import Company
import Person
import WorkTask

## The complete HTTP vocabulary owned by the application.
##
## Runtime request dispatch is a closed tag union because the request method
## and URL are runtime data. URL generation is exposed on the narrower nested
## types so views cannot use a mutation action as a normal link.
Route := [
	Visit(Location),
	Post(PostAction),
	Serve(Asset),
].{
	Page := [
		Home,
		Companies,
		CompanyNew,
		People,
		PersonNew,
		Work,
	].{
		is_eq : _

		title : Page -> Str
		title = |page|
			match page {
				Home => "Home"
				Companies => "Companies"
				CompanyNew => "New company"
				People => "People"
				PersonNew => "New person"
				Work => "My Work"
			}

		to_href : Page -> Str
		to_href = |page|
			match page {
				Home => "/"
				Companies => "/companies"
				CompanyNew => "/companies/new"
				People => "/people"
				PersonNew => "/people/new"
				Work => "/work"
			}
	}

	## GET locations which are not fully described by a page identity.
	##
	Location := [
		AtPage(Page),
		CompanySearch(Company.Filter),
		CompanyDetail(Company.Id),
		CompanyEdit(Company.Id),
		PersonSearch(Person.Filter),
		PersonDetail(Person.Id),
		PersonEdit(Person.Id),
		PersonNewForCompany(Company.Id),
	].{
		to_href : Location -> Str
		to_href = |location|
			match location {
				AtPage(page) => Page.to_href(page)
				CompanySearch(filter) =>
					"/companies?q=${form_encode(filter.to_str())}"
				CompanyDetail(id) => "/companies/${id.to_str()}"
				CompanyEdit(id) => "/companies/${id.to_str()}/edit"
				PersonSearch(filter) => "/people?q=${form_encode(filter.to_str())}"
				PersonDetail(id) => "/people/${id.to_str()}"
				PersonEdit(id) => "/people/${id.to_str()}/edit"
				PersonNewForCompany(id) => "/people/new?company=${form_encode(id.to_str())}"
			}
	}

	TaskContext := [
		WorkList,
		CompanyRecord(Company.Id),
		PersonRecord(Person.Id),
	].{
		is_eq : _

		to_location : TaskContext -> Location
		to_location = |context|
			match context {
				WorkList => AtPage(Page.Work)
				CompanyRecord(id) => CompanyDetail(id)
				PersonRecord(id) => PersonDetail(id)
			}
	}

	PostAction := [
		PreviewCompany,
		CreateCompany,
		UpdateCompany(Company.Id),
		PreviewPerson,
		ScanBusinessCard,
		CreatePerson,
		UpdatePerson(Person.Id),
		AddPersonEmail(Person.Id),
		AddPersonPhone(Person.Id),
		PromotePersonEmail(Person.Id, Person.ContactId),
		PromotePersonPhone(Person.Id, Person.ContactId),
		DeletePersonEmail(Person.Id, Person.ContactId),
		DeletePersonPhone(Person.Id, Person.ContactId),
		CreateCompanyTask(Company.Id),
		CreatePersonTask(Person.Id),
		CompleteTask(WorkTask.Id, TaskContext),
	].{
		to_post_url : PostAction -> Str
		to_post_url = |action|
			match action {
				PreviewCompany => "/companies/preview"
				CreateCompany => "/companies"
				UpdateCompany(id) => "/companies/${id.to_str()}"
				PreviewPerson => "/people/preview"
				ScanBusinessCard => "/people/business-card/scan"
				CreatePerson => "/people"
				UpdatePerson(id) => "/people/${id.to_str()}"
				AddPersonEmail(id) => "/people/${id.to_str()}/emails"
				AddPersonPhone(id) => "/people/${id.to_str()}/phones"
				PromotePersonEmail(id, contact_id) =>
					"/people/${id.to_str()}/emails/${contact_id.to_str()}/primary"
				PromotePersonPhone(id, contact_id) =>
					"/people/${id.to_str()}/phones/${contact_id.to_str()}/primary"
				DeletePersonEmail(id, contact_id) =>
					"/people/${id.to_str()}/emails/${contact_id.to_str()}/delete"
				DeletePersonPhone(id, contact_id) =>
					"/people/${id.to_str()}/phones/${contact_id.to_str()}/delete"
				CreateCompanyTask(id) => "/companies/${id.to_str()}/tasks"
				CreatePersonTask(id) => "/people/${id.to_str()}/tasks"
				CompleteTask(id, context) =>
					match context {
						TaskContext.WorkList => "/tasks/${id.to_str()}/complete"
						TaskContext.CompanyRecord(company_id) =>
							"/companies/${company_id.to_str()}/tasks/${id.to_str()}/complete"
						TaskContext.PersonRecord(person_id) =>
							"/people/${person_id.to_str()}/tasks/${id.to_str()}/complete"
						}
				}
	}

	## Names used by application-owned forms. These remain strings on the wire,
	## but views and handlers share a closed vocabulary instead of duplicating
	## string literals.
	CompanyInput := [Name, Owner, Lifecycle, Website, Phone, Source, Context, ConfirmDistinct, Version].{
		to_name : CompanyInput -> Str
		to_name = |input|
			match input {
				Name => "name"
				Owner => "owner"
				Lifecycle => "lifecycle"
				Website => "website"
				Phone => "phone"
				Source => "source"
				Context => "context"
				ConfirmDistinct => "confirmDistinct"
				Version => "version"
			}
	}

	PersonInput := [Name, Company, JobTitle, Owner, Lifecycle, Source, Context, Email, Phone, OriginCompany, ConfirmDistinct, Version, Label, Value, Primary].{
		to_name : PersonInput -> Str
		to_name = |input|
			match input {
				Name => "name"
				Company => "company"
				JobTitle => "jobTitle"
				Owner => "owner"
				Lifecycle => "lifecycle"
				Source => "source"
				Context => "context"
				Email => "email"
				Phone => "phone"
				OriginCompany => "originCompany"
				ConfirmDistinct => "confirmDistinct"
				Version => "version"
				Label => "label"
				Value => "value"
				Primary => "primary"
			}
	}

	TaskInput := [Subject, DueLocal, Assignee, TaskType, Context].{
		to_name : TaskInput -> Str
		to_name = |input|
			match input {
				Subject => "subject"
				DueLocal => "dueLocal"
				Assignee => "assignee"
				TaskType => "taskType"
				Context => "context"
			}
	}

	## Encoded widths of the home page photograph.
	##
	## The width is part of the vocabulary rather than derived from the file
	## name, because a `srcset` candidate is only correct when its declared
	## width matches the encoded image.
	HeroPhoto := [Width480, Width640, Width720, Width960].{

		## Ordered narrowest first, as a `srcset` candidate list.
		responsive_set : List(HeroPhoto)
		responsive_set = [Width480, Width640, Width720, Width960]

		to_src : HeroPhoto -> Str
		to_src = |photo|
			match photo {
				Width480 => "/assets/planning-desk-480.webp"
				Width640 => "/assets/planning-desk-640.webp"
				Width720 => "/assets/planning-desk-720.webp"
				Width960 => "/assets/planning-desk-960.webp"
			}

		to_width : HeroPhoto -> Str
		to_width = |photo|
			match photo {
				Width480 => "480"
				Width640 => "640"
				Width720 => "720"
				Width960 => "960"
			}
	}

	Asset := [
		Robots,
		Stylesheet,
		Htmx,
		Interactions,
		AppIcon,
		Hero(HeroPhoto),
	].{
		to_src : Asset -> Str
		to_src = |asset|
			match asset {
				Robots => "/robots.txt"
				Stylesheet => "/assets/styles.css?v=20260728"
				Htmx => "/assets/htmx.min.js?v=4.0.0-beta6"
				Interactions => "/assets/interactions.js?v=20260728"
				AppIcon => "/assets/icons/app.svg"
				Hero(photo) => HeroPhoto.to_src(photo)
			}
	}

	ParseError := [NotFound(Str)]

	Method := [Get, Post, Put, Other].{
		is_eq : _
	}

	parse : Server.Request, Str, Url -> Try(Route, ParseError)
	parse = |request, target, url|
		parse_parts(method_from_request(request), target, url)

	## Pure routing core. `parse` is the normal application entry point;
	## the target is passed separately because the platform keeps the request
	## representation opaque. `parse_parts` allows route behavior to be tested
	## without constructing a `Server.Request`.
	parse_parts : Method, Str, Url -> Try(Route, ParseError)
	parse_parts = |method, target, url| {
		segments = Url.path(url).split_on("/")

		match (method, segments) {
			(Get, ["", ""]) => Ok(Visit(AtPage(Home)))

			(Get, ["", "companies"]) => {
				filter = Route.company_filter(Url.query_pairs(url))
				if filter.to_str().is_empty() {
					Ok(Visit(AtPage(Companies)))
				} else {
					Ok(Visit(CompanySearch(filter)))
				}
			}
			(Get, ["", "companies", "new"]) => Ok(Visit(AtPage(CompanyNew)))
			(Post, ["", "companies", "preview"]) => Ok(Post(PreviewCompany))
			(Post, ["", "companies"]) => Ok(Post(CreateCompany))
			(Get, ["", "companies", id, "edit"]) =>
				Ok(Visit(CompanyEdit(Company.Id.from_storage(id))))
			(Post, ["", "companies", id]) =>
				Ok(Post(UpdateCompany(Company.Id.from_storage(id))))
			(Post, ["", "companies", id, "tasks"]) =>
				Ok(Post(CreateCompanyTask(Company.Id.from_storage(id))))
			(Post, ["", "companies", id, "tasks", task_id, "complete"]) =>
				Ok(
					Post(
						CompleteTask(
							WorkTask.Id.from_storage(task_id),
							TaskContext.CompanyRecord(Company.Id.from_storage(id)),
						),
					),
				)
			(Get, ["", "companies", id]) =>
				Ok(Visit(CompanyDetail(Company.Id.from_storage(id))))

			(Get, ["", "people"]) => {
				filter = Person.Filter.from_str(query_value(Url.query_pairs(url), "q"))
				if filter.to_str().is_empty() {
					Ok(Visit(AtPage(People)))
				} else {
					Ok(Visit(PersonSearch(filter)))
				}
			}
			(Get, ["", "people", "new"]) => {
				company_id = query_value(Url.query_pairs(url), "company")
				if company_id.is_empty() {
					Ok(Visit(AtPage(PersonNew)))
				} else {
					Ok(Visit(PersonNewForCompany(Company.Id.from_storage(company_id))))
				}
			}
			(Post, ["", "people", "preview"]) => Ok(Post(PreviewPerson))
			(Post, ["", "people", "business-card", "scan"]) => Ok(Post(ScanBusinessCard))
			(Post, ["", "people"]) => Ok(Post(CreatePerson))
			(Get, ["", "people", id, "edit"]) =>
				Ok(Visit(PersonEdit(Person.Id.from_storage(id))))
			(Post, ["", "people", id]) =>
				Ok(Post(UpdatePerson(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "tasks"]) =>
				Ok(Post(CreatePersonTask(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "tasks", task_id, "complete"]) =>
				Ok(
					Post(
						CompleteTask(
							WorkTask.Id.from_storage(task_id),
							TaskContext.PersonRecord(Person.Id.from_storage(id)),
						),
					),
				)
			(Get, ["", "people", id]) =>
				Ok(Visit(PersonDetail(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "emails"]) =>
				Ok(Post(AddPersonEmail(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "phones"]) =>
				Ok(Post(AddPersonPhone(Person.Id.from_storage(id))))
			(Post, ["", "people", id, "emails", contact_id, "primary"]) =>
				Ok(
					Post(
						PromotePersonEmail(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)
			(Post, ["", "people", id, "phones", contact_id, "primary"]) =>
				Ok(
					Post(
						PromotePersonPhone(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)
			(Post, ["", "people", id, "emails", contact_id, "delete"]) =>
				Ok(
					Post(
						DeletePersonEmail(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)

			(Get, ["", "work"]) => Ok(Visit(AtPage(Work)))
			(Post, ["", "tasks", id, "complete"]) =>
				Ok(Post(CompleteTask(WorkTask.Id.from_storage(id), TaskContext.WorkList)))
			(Post, ["", "people", id, "phones", contact_id, "delete"]) =>
				Ok(
					Post(
						DeletePersonPhone(
							Person.Id.from_storage(id),
							Person.ContactId.from_storage(contact_id),
						),
					),
				)

			(Get, ["", "robots.txt"]) => Ok(Serve(Robots))

			_ => Err(NotFound(target))
		}
	}

	company_filter : List((Str, Str)) -> Company.Filter
	company_filter = |pairs|
		Company.Filter.from_str(query_value(pairs, "q"))
}

query_value : List((Str, Str)), Str -> Str
query_value = |pairs, expected|
	match pairs.find_first(|(name, _)| name == expected) {
		Ok((_, value)) => value
		Err(_) => ""
	}

method_from_request : Server.Request -> Route.Method
method_from_request = |request|
	match request.method() {
		GET => Route.Method.Get
		POST => Route.Method.Post
		PUT => Route.Method.Put
		_ => Route.Method.Other
	}

form_encode : Str -> Str
form_encode = |input|
	Str.from_utf8_lossy(
		List.fold(
			Str.to_utf8(input),
			[],
			|out, byte|
				if byte == 32 {
					out.append(43)
				} else if is_form_unescaped(byte) {
					out.append(byte)
				} else {
					out
						.append(37)
						.append(hex_digit_byte(byte // 16))
						.append(hex_digit_byte(byte % 16))
				},
		),
	)

is_form_unescaped : U8 -> Bool
is_form_unescaped = |byte|
	(byte >= 48 and byte <= 57)
		or (byte >= 65 and byte <= 90)
			or (byte >= 97 and byte <= 122)
				or byte == 42
					or byte == 45
						or byte == 46
							or byte == 95

hex_digit_byte : U8 -> U8
hex_digit_byte = |value|
	if value < 10 {
		value + 48
	} else {
		value + 55
	}

expect Route.Location.to_href(
	Route.Location.CompanySearch(Company.Filter.from_str("Acme Studio")),
) == "/companies?q=Acme+Studio"

expect {
	result = Route.parse_parts(
		Route.Method.Get,
		"/companies/company-acme",
		"http://localhost/companies/company-acme",
	)
	match result {
		Ok(Route.Visit(Route.Location.CompanyDetail(id))) =>
			id.to_str() == "company-acme"
		_ => False
	}
}

expect Route.Page.to_href(Route.Page.Work) == "/work"

expect {
	result = Route.parse_parts(
		Route.Method.Get,
		"/people/new?company=company-acme",
		"http://localhost/people/new?company=company-acme",
	)
	match result {
		Ok(Route.Visit(Route.Location.PersonNewForCompany(id))) =>
			id.to_str() == "company-acme"
		_ => False
	}
}

expect {
	result = Route.parse_parts(
		Route.Method.Post,
		"/tasks/task-follow-up/complete",
		"http://localhost/tasks/task-follow-up/complete",
	)
	match result {
		Ok(Route.Post(Route.PostAction.CompleteTask(id, context))) =>
			id.to_str() == "task-follow-up" and context == Route.TaskContext.WorkList
		_ => False
	}
}

expect {
	person_id = Person.Id.from_storage("person-ada")
	task_id = WorkTask.Id.from_storage("task-follow-up")
	action = Route.PostAction.CompleteTask(
		task_id,
		Route.TaskContext.PersonRecord(person_id),
	)
	parsed = Route.parse_parts(
		Route.Method.Post,
		action.to_post_url(),
		"http://localhost/people/person-ada/tasks/task-follow-up/complete",
	)
	match parsed {
		Ok(Route.Post(Route.PostAction.CompleteTask(actual_task, context))) =>
			actual_task == task_id
				and context == Route.TaskContext.PersonRecord(person_id)
		_ => False
	}
}
