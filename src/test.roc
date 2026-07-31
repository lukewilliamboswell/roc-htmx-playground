app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.15.0/HcMFsVT26qeMvqWtG5rfNhVMWjceYbKh1An4uYpheBVW.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	gregorian: "https://cdn.jasperwoudenberg.com/roc-gregorian-v1.0.0-rc.2/Ce3xuHN92F5oGRuzjUTmm65jULAEj8pvvrTBmZJzE1M4.tar.zst",
}

import pf.Env
import pf.Path
import pf.Server
import pf.Sqlite
import pf.Stderr
import pf.Stdout
import http.Response
import "../db/migrations/001_initial.sql" as init_schema : Str
import "../db/migrations/002_remove_legacy_auth_and_demos.sql" as remove_legacy_schema : Str
import "../db/test-fixtures.sql" as test_fixtures : Str

import Activity
import Actor
import Company
import CompanyHandler
import CompanyStore
import Http
import Member
import Person
import PersonHandler
import PersonStore
import Session
import Workspace
import WorkspaceStore
import WorkTask
import WorkTaskStore
import WorkTaskView

Context := {}

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64), ..])
init! = || {
	test_db_path = Path.join(
		Env.temp_dir!(),
		"roc-htmx-playground-platform-test.sqlite",
	)
	if test_db_path.is_file!() ? |_| Exit(1) {
		test_db_path.delete!() ? |_| Exit(1)
	}
	default = Sqlite.default_config(test_db_path)
	opened = Sqlite.open!({
		..default,
		max_connections: 1,
		journal_mode: Delete,
	})
	db = match opened {
		Err(error) => {
			Stderr.line!("database open failed: ${Str.inspect(error)}") ? |_| Exit(1)
			return Err(Exit(1))
		}
		Ok(value) => value
	}
	match load_schema!(db, init_schema.split_on(";")) {
		Err(error) => {
			Stderr.line!("schema failed: ${Str.inspect(error)}") ? |_| Exit(2)
			return Err(Exit(2))
		}
		Ok({}) => {}
	}
	match load_schema!(db, remove_legacy_schema.split_on(";")) {
		Err(error) => {
			Stderr.line!("migration failed: ${Str.inspect(error)}") ? |_| Exit(2)
			return Err(Exit(2))
		}
		Ok({}) => {}
	}
	match load_schema!(db, test_fixtures.split_on(";")) {
		Err(error) => {
			Stderr.line!("fixtures failed: ${Str.inspect(error)}") ? |_| Exit(2)
			return Err(Exit(2))
		}
		Ok({}) => {}
	}
	Stdout.line!("schema: ok") ? |_| Exit(3)
	test_schema_version!(db)
	Stdout.line!("schema version: ok") ? |_| Exit(3)
	test_workspace!(db)
	Stdout.line!("workspace: ok") ? |_| Exit(3)
	test_companies!(db)
	Stdout.line!("companies: ok") ? |_| Exit(3)
	test_people!(db)
	Stdout.line!("people: ok") ? |_| Exit(3)
	test_work_tasks!(db)
	Stdout.line!("work tasks: ok") ? |_| Exit(3)
	Err(Exit(0))
}

test_companies! : Sqlite.Db => {}
test_companies! = |db| {
	store = CompanyStore.new(db)
	workspace = WorkspaceStore.load!(WorkspaceStore.new(db))
		?? Workspace.from_storage(
			"workspace-example",
			"Example CRM",
			"AUD",
			"Australia/Melbourne",
			[],
			[],
			[],
		)
	member = Member.from_storage("member-mara", "Mara Singh", "mara@example.com", 1)
	theo_id = Member.Id.from_storage("member-theo")
	listed = CompanyStore.list!(store, Company.Filter.empty)
	expect match listed {
		Ok([company]) =>
			company.id.to_str() == "company-acme"
				and company.name.to_str() == "Acme Studio"
					and company.ownerName == "Mara Singh"
						and company.lifecycle == Company.Lifecycle.Prospect
							and company.sourceName == "Referral"
		_ => False
	}

	filtered = CompanyStore.list!(store, Company.Filter.from_str("acme.example"))
	expect match filtered {
		Ok([company]) => company.id.to_str() == "company-acme"
		_ => False
	}

	missing_id = Company.Id.from_storage("company-missing")
	missing = CompanyStore.find!(store, missing_id)
	expect match missing {
		Err(Company.FindError.NotFound) => True
		_ => False
	}

	duplicate_input = valid_company_input(
		"Acme Studio Australia",
		member.id,
		"lead",
		"https://www.acme.example/contact",
		"",
	)
	matches = CompanyStore.matches!(store, workspace.id, duplicate_input)
	expect match matches {
		Ok([{ strength: Company.MatchStrength.Strong, reason: Company.MatchReason.SameWebsite, .. }]) => True
		_ => False
	}

	name_variant = valid_company_input(
		"Acme Studios Pty Ltd",
		member.id,
		"lead",
		"",
		"",
	)
	name_matches = CompanyStore.matches!(store, workspace.id, name_variant)
	expect match name_matches {
		Ok([{ strength: Company.MatchStrength.Weak, reason: Company.MatchReason.SimilarName, .. }]) => True
		_ => False
	}

	blocked = CompanyStore.create!(
		store,
		workspace.id,
		member.id,
		duplicate_input,
		"2026-07-28T10:00:00Z",
		False,
	)
	expect match blocked {
		Err(Company.CreateError.DuplicateMatches([_])) => True
		_ => False
	}

	new_input = valid_company_input(
		"Northwind Workshop",
		member.id,
		"lead",
		"https://northwind.example",
		"+61 3 8111 2222",
	)
	previewed = CompanyStore.matches!(store, workspace.id, new_input)
	expect match previewed {
		Ok([]) => True
		_ => False
	}
	created = CompanyStore.create!(
		store,
		workspace.id,
		member.id,
		new_input,
		"2026-07-28T10:05:00Z",
		False,
	)
	found = match created {
		Ok(id) => CompanyStore.find!(store, id)
		Err(_) => Err(Company.FindError.NotFound)
	}
	expect match found {
		Ok(company) =>
			company.name.to_str() == "Northwind Workshop"
				and company.version.to_i64() == 1
		Err(_) => False
	}

	created_id = match created {
		Ok(id) => id
		Err(_) => Company.Id.from_storage("company-missing")
	}
	updated_input = valid_company_input(
		"Northwind Workshop",
		theo_id,
		"customer",
		"https://northwind.example",
		"+61 3 8111 2222",
	)
	updated = CompanyStore.update!(
		store,
		workspace.id,
		member.id,
		created_id,
		updated_input,
		Company.Version.initial,
		"2026-07-28T10:10:00Z",
	)
	expect match updated {
		Ok(version) => version.to_i64() == 2
		Err(_) => False
	}

	stale = CompanyStore.update!(
		store,
		workspace.id,
		member.id,
		created_id,
		new_input,
		Company.Version.initial,
		"2026-07-28T10:15:00Z",
	)
	expect match stale {
		Err(Company.UpdateError.Conflict(current)) =>
			current.version.to_i64() == 2
				and current.lifecycle == Company.Lifecycle.Customer
		_ => False
	}

	activity_count : { count : I64 }
	activity_count = Sqlite.query!({
		db,
		query: "SELECT COUNT(*) AS count FROM activities WHERE change_field = 'lifecycle';",
		params: {},
		limits: Sqlite.default_query_limits,
	}) ?? { count: 0 }
	expect activity_count.count == 1

	history = CompanyStore.history!(store, created_id)
	expect match history {
		Ok([first, second]) =>
			match (first.change, second.change) {
				(
					Activity.Change.LifecycleChanged({ from: "Lead", to: "Customer" }),
					Activity.Change.OwnerChanged({ from: "Mara Singh", to: "Theo Nguyen" }),
				) => True
				_ => False
			}
		_ => False
	}

	actor = match Actor.from_session(
		Session.trusted(member, Session.IdentitySource.Development),
		workspace,
	) {
		Ok(value) => value
		Err(_) => {
			crash "Company handler test requires a logged-in actor."
		}
	}
	preview_fields = Http.parse_form(
		"name=Mixed+CASE+Company&owner=member-mara&lifecycle=lead&website=&phone=&source=&context=".to_utf8(),
	) ?? Dict.empty()
	preview_response = CompanyHandler.preview_form!(preview_fields, store, actor)
	expect preview_response.is_ok()
	preview_created = CompanyStore.list!(
		store,
		Company.Filter.from_str("Mixed CASE Company"),
	)
	expect match preview_created {
		Ok([company]) => company.name.to_str() == "Mixed CASE Company"
		_ => False
	}

	# CRM-025: search has an explicit submit affordance in rendered HTML.
	page_response = CompanyHandler.page!(store, actor, Company.Filter.empty)
	expect match page_response {
		Ok(response) => {
			body = response_body(response)
			body.contains("id=\"company-search\"")
				and body.contains(">Search</button>")
		}
		Err(_) => False
	}
}

valid_company_input : Str, Member.Id, Str, Str, Str -> Company.New
valid_company_input = |name, owner_id, lifecycle, website, phone|
	match Company.new(name, owner_id, lifecycle, website, phone, "event", "Test context") {
		Ok(input) => input
		Err(_) => {
			crash "Company test input should be valid."
		}
	}

test_people! : Sqlite.Db => {}
test_people! = |db| {
	store = PersonStore.new(db)
	workspace = WorkspaceStore.load!(WorkspaceStore.new(db))
		?? Workspace.from_storage(
			"workspace-example",
			"Example CRM",
			"AUD",
			"Australia/Melbourne",
			[],
			[],
			[],
		)
	member = Member.from_storage("member-mara", "Mara Singh", "mara@example.com", 1)
	theo_id = Member.Id.from_storage("member-theo")
	input = valid_person_input(
		"Ada Lovelace",
		member.id,
		"company-acme",
		"ada@example.com",
		"+61 3 9000 1234",
	)
	created = PersonStore.create!(
		store,
		workspace.id,
		member.id,
		input,
		"2026-07-28T11:00:00Z",
		False,
	)
	person_id = match created {
		Ok(id) => id
		Err(_) => Person.Id.from_storage("person-missing")
	}
	found = PersonStore.find!(store, person_id)
	expect match found {
		Ok(person) =>
			person.name.to_str() == "Ada Lovelace"
				and person.companyName == "Acme Studio"
					and Person.primary_value(person.emails) == "ada@example.com"
						and Person.primary_value(person.phones) == "+61 3 9000 1234"
		Err(_) => False
	}

	duplicate = valid_person_input(
		"Ada L.",
		member.id,
		"",
		"ADA@example.com",
		"",
	)
	matches = PersonStore.matches!(store, workspace.id, duplicate)
	expect match matches {
		Ok([{ strength: Person.MatchStrength.Strong, reason: Person.MatchReason.SameEmail, .. }]) => True
		_ => False
	}
	blocked = PersonStore.create!(
		store,
		workspace.id,
		member.id,
		duplicate,
		"2026-07-28T11:05:00Z",
		False,
	)
	expect match blocked {
		Err(Person.CreateError.DuplicateMatches([_])) => True
		_ => False
	}

	email_added = PersonStore.add_contact!(store, person_id, Email, "Personal", "ada@home.example", False)
	expect email_added.is_ok()
	phone_added = PersonStore.add_contact!(store, person_id, Phone, "Mobile", "0400 000 000", True)
	expect phone_added.is_ok()
	with_contacts = PersonStore.find!(store, person_id)
	expect match with_contacts {
		Ok(person) =>
			person.emails.len() == 2
				and person.phones.len() == 2
					and Person.primary_value(person.phones) == "0400 000 000"
		Err(_) => False
	}
	personal_email_id = match with_contacts {
		Ok(person) =>
			match person.emails.find_first(|method| method.value == "ada@home.example") {
				Ok(method) => method.id
				Err(_) => Person.ContactId.from_storage("email-missing")
			}
		Err(_) => Person.ContactId.from_storage("email-missing")
	}
	promoted = PersonStore.make_primary!(store, person_id, Email, personal_email_id)
	expect promoted.is_ok()
	duplicate_email = PersonStore.add_contact!(
		store,
		person_id,
		Email,
		"Home",
		"ADA@HOME.EXAMPLE",
		False,
	)
	expect duplicate_email.is_ok()
	after_promotion = PersonStore.find!(store, person_id)
	expect match after_promotion {
		Ok(person) =>
			person.emails.len() == 2
				and Person.primary_value(person.emails) == "ADA@HOME.EXAMPLE"
		Err(_) => False
	}
	primary_removed = PersonStore.delete_contact!(store, person_id, Email, personal_email_id)
	expect primary_removed.is_ok()
	after_primary_removal = PersonStore.find!(store, person_id)
	expect match after_primary_removal {
		Ok(person) =>
			person.emails.len() == 1
				and Person.primary_value(person.emails) == "ada@example.com"
		Err(_) => False
	}

	company_people = PersonStore.list_for_company!(store, Company.Id.from_storage("company-acme"))
	expect match company_people {
		Ok([person]) => person.id == person_id
		_ => False
	}

	moved = valid_person_input("Ada Lovelace", theo_id, "", "", "")
	updated = PersonStore.update!(
		store,
		workspace.id,
		member.id,
		person_id,
		moved,
		Company.Version.initial,
		"2026-07-28T11:10:00Z",
	)
	expect match updated {
		Ok(version) => version.to_i64() == 2
		Err(_) => False
	}
	stale = PersonStore.update!(
		store,
		workspace.id,
		member.id,
		person_id,
		input,
		Company.Version.initial,
		"2026-07-28T11:15:00Z",
	)
	expect match stale {
		Err(Person.UpdateError.Conflict(current)) =>
			current.version.to_i64() == 2 and current.companyId.is_empty()
		_ => False
	}

	history = PersonStore.history!(store, person_id)
	expect match history {
		Ok([activity]) =>
			activity.change
				== Activity.Change.OwnerChanged({ from: "Mara Singh", to: "Theo Nguyen" })
		_ => False
	}

	actor = logged_in_actor(workspace, member)
	page_response = PersonHandler.page!(store, actor, Person.Filter.empty)
	expect match page_response {
		Ok(response) => {
			body = response_body(response)
			body.contains("id=\"people-search\"")
				and body.contains(">Search</button>")
		}
		Err(_) => False
	}

	# CRM-002 and CRM-030: contacts remain maintainable and history is readable.
	detail_response = PersonHandler.detail!(
		store,
		WorkTaskStore.new(db),
		actor,
		person_id,
	)
	expect match detail_response {
		Ok(response) => {
			body = response_body(response)
			body.contains("Make primary")
				and body.contains("Owner: Mara Singh → Theo Nguyen")
					and !body.contains("Owner: member-theo")
						and !body.contains("2026-07-28T")
		}
		Err(_) => False
	}
}

valid_person_input : Str, Member.Id, Str, Str, Str -> Person.New
valid_person_input = |name, owner_id, company_id, email, phone|
	match Person.new(
		name,
		company_id,
		"",
		owner_id,
		"lead",
		"referral",
		"Test context",
		email,
		phone,
	) {
		Ok(input) => input
		Err(_) => {
			crash "Person test input should be valid."
		}
	}

test_work_tasks! : Sqlite.Db => {}
test_work_tasks! = |db| {
	store = WorkTaskStore.new(db)
	workspace = WorkspaceStore.load!(WorkspaceStore.new(db))
		?? Workspace.from_storage(
			"workspace-example",
			"Example CRM",
			"AUD",
			"Australia/Melbourne",
			[],
			[],
			[],
		)
	member = Member.from_storage("member-mara", "Mara Singh", "mara@example.com", 1)
	theo_id = Member.Id.from_storage("member-theo")
	overdue_input = valid_work_task(
		"Call Acme",
		"2026-07-27T16:00",
		member.id,
		WorkTask.Related.Company("company-acme"),
	)
	overdue = WorkTaskStore.create!(
		store,
		workspace.id,
		member.id,
		overdue_input,
		"2026-07-26T06:00:00Z",
	)
	today_input = valid_work_task(
		"Send proposal",
		"2026-07-28T09:00",
		member.id,
		WorkTask.Related.Company("company-acme"),
	)
	today_task = WorkTaskStore.create!(
		store,
		workspace.id,
		member.id,
		today_input,
		"2026-07-27T23:00:00Z",
	)
	upcoming_input = valid_work_task(
		"Book review",
		"2026-08-02T11:30",
		member.id,
		WorkTask.Related.Person("person-missing"),
	)
	upcoming = WorkTaskStore.create!(
		store,
		workspace.id,
		member.id,
		upcoming_input,
		"2026-07-28T00:00:00Z",
	)
	delegated_input = valid_work_task(
		"Confirm installation",
		"2026-07-29T10:00",
		theo_id,
		WorkTask.Related.Company("company-acme"),
	)
	delegated = WorkTaskStore.create!(
		store,
		workspace.id,
		member.id,
		delegated_input,
		"2026-07-28T00:05:00Z",
	)
	expect overdue.is_ok() and today_task.is_ok() and upcoming.is_ok() and delegated.is_ok()

	work = WorkTaskStore.for_assignee!(
		store,
		workspace.id,
		member.id,
		"2026-07-28",
	)
	expect match work {
		Ok([first, second, third]) =>
			first.bucket == WorkTask.Bucket.Overdue
				and second.bucket == WorkTask.Bucket.Today
					and third.bucket == WorkTask.Bucket.Upcoming
		_ => False
	}

	# CRM-019: a rendered task says who owns it, what kind it is, and why it exists.
	actor = logged_in_actor(workspace, member)
	work_page = match work {
		Ok(tasks) => response_body(Http.html(200, WorkTaskView.page(actor, tasks), []))
		Err(_) => ""
	}
	expect work_page.contains("Due: 27 Jul 2026, 16:00")
	expect work_page.contains("Assignee: Mara Singh")
	expect work_page.contains("Type: Follow up")
	expect work_page.contains("Context: Test context")
	expect !work_page.contains("2026-07-27T16:00")

	theo_work = WorkTaskStore.for_assignee!(
		store,
		workspace.id,
		theo_id,
		"2026-07-28",
	)
	expect match theo_work {
		Ok([task]) => task.subject.to_str() == "Confirm installation"
		_ => False
	}

	conversion : { utcValue : Str }
	conversion = Sqlite.query!({
		db,
		query: "SELECT datetime(due_at_utc, 'unixepoch') AS utcValue FROM crm_tasks WHERE subject = 'Send proposal';",
		params: {},
		limits: Sqlite.default_query_limits,
	}) ?? { utcValue: "" }
	expect conversion.utcValue == "2026-07-27 23:00:00"

	today_id = match today_task {
		Ok(id) => id
		Err(_) => WorkTask.Id.from_storage("task-missing")
	}
	completed = WorkTaskStore.complete!(
		store,
		workspace.id,
		member.id,
		today_id,
		"2026-07-28T01:00:00Z",
	)
	expect completed.is_ok()
	after_completion = WorkTaskStore.for_assignee!(
		store,
		workspace.id,
		member.id,
		"2026-07-28",
	)
	expect match after_completion {
		Ok(tasks) => tasks.len() == 2
		Err(_) => False
	}
}

valid_work_task : Str, Str, Member.Id, WorkTask.Related -> WorkTask.New
valid_work_task = |subject, due_local, assignee_id, related|
	match WorkTask.new(subject, due_local, assignee_id, "follow-up", related, "Test context") {
		Ok(input) => input
		Err(_) => {
			crash "Work task test input should be valid."
		}
	}

logged_in_actor : Workspace, Member -> Actor
logged_in_actor = |workspace, member|
	match Actor.from_session(
		Session.trusted(member, Session.IdentitySource.Development),
		workspace,
	) {
		Ok(actor) => actor
		Err(_) => {
			crash "View integration test requires a logged-in actor."
		}
	}

response_body : Response -> Str
response_body = |response| Str.from_utf8_lossy(Response.body(response))

test_workspace! : Sqlite.Db => {}
test_workspace! = |db| {
	loaded = WorkspaceStore.load!(WorkspaceStore.new(db))
	expect match loaded {
		Ok(workspace) =>
			workspace.name == "Example CRM"
				and workspace.currency.to_str() == "AUD"
					and workspace.timezone.to_str() == "Australia/Melbourne"
						and workspace.sources.len() == 6
							and workspace.taskTypes.len() == 5
								and workspace.members.len() == 2
		Err(_) => False
	}
}

test_schema_version! : Sqlite.Db => {}
test_schema_version! = |db| {
	version : I64
	version = Sqlite.query!({
		db,
		query: "PRAGMA user_version;",
		params: {},
		limits: Sqlite.default_query_limits,
	}) ?? 0
	expect version == 2
}

respond! = |_request, _context| Ok(Server.respond(Response.from_status(204)))

shutdown! = |_reason, _context| Ok({})

load_schema! : Sqlite.Db, List(Str) => Try({}, Sqlite.QueryError)
load_schema! = |db, statements|
	match statements {
		[] => Ok({})
		[statement, .. as rest] => {
			sql = statement.trim()
			if sql.is_empty() {
				load_schema!(db, rest)
			} else {
				Sqlite.execute!({ db, query: sql, params: {} })?
				load_schema!(db, rest)
			}
		}
	}
