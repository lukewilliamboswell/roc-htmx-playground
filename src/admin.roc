app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.21.0/4rAQg8kUYZ3Vksr4qMQHpaFYNiHSn9GgS7gVxghd1XYV.tar.zst",
}

import pf.Env
import pf.OsStr
import pf.Path
import pf.Sqlite
import pf.Stdout
import "../db/migrations/001_initial.sql" as initial_migration : Str
import "../db/migrations/002_remove_legacy_auth_and_demos.sql" as remove_legacy_migration : Str

import Authentication

latest_schema_version : I64
latest_schema_version = 2

main! : List(OsStr) => Try({}, _)
main! = |raw_args| {
	args = raw_args.drop_first(1).map(OsStr.display)
	match args {
		["bootstrap", ..] => bootstrap!(args)?
		["migrate", ..] => migrate!(database_path!(args)?)?
		["schema", "check", ..] => schema_check!(database_path!(args)?)?
		["members", "list", ..] => members_list!(database_path!(args)?)?
		["members", "add", ..] =>
			member_add!(
				database_path!(args)?,
				required_arg(args, "--name")?,
				required_arg(args, "--email")?,
			)?
		["members", "activate", ..] =>
			member_set_active!(
				database_path!(args)?,
				required_arg(args, "--email")?,
				Bool.True,
			)?
		["members", "deactivate", ..] =>
			member_set_active!(
				database_path!(args)?,
				required_arg(args, "--email")?,
				Bool.False,
			)?
		_ => usage!()?
	}
	Ok({})
}

usage! : () => Try({}, _)
usage! = || {
	Stdout.line!(
		\\Usage:
		\\  enquiry-crm-admin bootstrap --db PATH --workspace-name NAME --currency AUD --timezone AREA/CITY --member-name NAME --member-email EMAIL
		\\  enquiry-crm-admin migrate --db PATH
		\\  enquiry-crm-admin schema check --db PATH
		\\  enquiry-crm-admin members list --db PATH
		\\  enquiry-crm-admin members add --db PATH --name NAME --email EMAIL
		\\  enquiry-crm-admin members activate --db PATH --email EMAIL
		\\  enquiry-crm-admin members deactivate --db PATH --email EMAIL
		,
	)?
	Err(InvalidArguments)
}

database_path! : List(Str) => Try(Path, _)
database_path! = |args|
	match optional_arg(args, "--db") {
		Some(value) => Ok(Path.utf8(value))
		None =>
			match Env.var!("DB_PATH") {
				Ok(value) => Ok(Path.from_os_str(value))
				Err(_) => Err(MissingArgument("--db"))
			}
		}

required_arg = |args, name|
	match optional_arg(args, name) {
		Some(value) if !value.trim().is_empty() => Ok(value.trim())
		_ => Err(MissingArgument(name))
	}

optional_arg : List(Str), Str -> [Some(Str), None]
optional_arg = |args, expected|
	match args {
		[] => None
		[name, value, ..] if name == expected => Some(value)
		[_, .. as rest] => optional_arg(rest, expected)
	}

bootstrap! : List(Str) => Try({}, _)
bootstrap! = |args| {
	db_path = database_path!(args)?
	if db_path.is_file!()? {
		return Err(DatabaseAlreadyExists(Path.display(db_path)))
	}

	workspace_name = required_arg(args, "--workspace-name")?
	currency = required_arg(args, "--currency")?.with_ascii_uppercased()
	timezone = required_arg(args, "--timezone")?
	member_name = required_arg(args, "--member-name")?
	member_email = normalize_email(required_arg(args, "--member-email")?)

	if currency.to_utf8().len() != 3 {
		return Err(InvalidCurrency(currency))
	}
	if !timezone.contains("/") {
		return Err(InvalidTimezone(timezone))
	}
	if !Authentication.valid_login(member_email) {
		return Err(InvalidEmail(member_email))
	}

	result = bootstrap_database!(
		db_path,
		workspace_name,
		currency,
		timezone,
		member_name,
		member_email,
	)
	match result {
		Ok({}) => {
			Stdout.line!("Initialized ${Path.display(db_path)} at schema version ${latest_schema_version.to_str()}.")?
			Ok({})
		}
		Err(error) => {
			if db_path.is_file!() ?? Bool.False {
				db_path.delete!() ?? {}
			}
			Err(error)
		}
	}
}

bootstrap_database! : Path, Str, Str, Str, Str, Str => Try({}, _)
bootstrap_database! = |db_path, workspace_name, currency, timezone, member_name, member_email| {
	apply_migrations!(db_path)?
	clear_development_rows!(db_path)?
	execute!(
		db_path,
		(
			\\INSERT INTO workspaces (workspace_id, name, currency, timezone)
			\\VALUES ('workspace-main', :name, :currency, :timezone);
			,
		),
		[
			string_binding(":name", workspace_name),
			string_binding(":currency", currency),
			string_binding(":timezone", timezone),
		],
	)?
	insert_defaults!(db_path)?
	member_add!(db_path, member_name, member_email)
}

migrate! : Path => Try({}, _)
migrate! = |db_path| {
	if !db_path.is_file!()? {
		return Err(DatabaseDoesNotExist(Path.display(db_path)))
	}
	apply_migrations!(db_path)
}

apply_migrations! : Path => Try({}, _)
apply_migrations! = |db_path| {
	version = schema_version!(db_path)?
	if version > latest_schema_version {
		return Err(DatabaseSchemaTooNew({ actual: version, expected: latest_schema_version }))
	}
	if version == 0 {
		execute_statements!(db_path, initial_migration.split_on(";"))?
	}
	if version <= 1 {
		execute_statements!(db_path, remove_legacy_migration.split_on(";"))?
	}
	schema_check!(db_path)
}

schema_check! : Path => Try({}, _)
schema_check! = |db_path| {
	if !db_path.is_file!()? {
		return Err(DatabaseDoesNotExist(Path.display(db_path)))
	}
	version = schema_version!(db_path)?
	if version == latest_schema_version {
		Ok({})
	} else if version > latest_schema_version {
		Err(DatabaseSchemaTooNew({ actual: version, expected: latest_schema_version }))
	} else {
		Err(DatabaseMigrationRequired({ actual: version, expected: latest_schema_version }))
	}
}

schema_version! : Path => Try(I64, _)
schema_version! = |db_path|
	Sqlite.query!({
		path: db_path,
		query: "PRAGMA user_version;",
		bindings: [],
		row: Sqlite.i64("user_version"),
	})

execute_statements! : Path, List(Str) => Try({}, _)
execute_statements! = |db_path, statements|
	match statements {
		[] => Ok({})
		[statement, .. as rest] => {
			sql = statement.trim()
			if sql.is_empty() {
				execute_statements!(db_path, rest)
			} else {
				execute!(db_path, sql, [])?
				execute_statements!(db_path, rest)
			}
		}
	}

clear_development_rows! : Path => Try({}, _)
clear_development_rows! = |db_path|
	execute_statements!(
		db_path,
		[
			"DELETE FROM activity_companies",
			"DELETE FROM activity_people",
			"DELETE FROM activities",
			"DELETE FROM crm_tasks",
			"DELETE FROM person_emails",
			"DELETE FROM person_phones",
			"DELETE FROM person_revisions",
			"DELETE FROM people",
			"DELETE FROM company_revisions",
			"DELETE FROM companies",
			"DELETE FROM members",
			"DELETE FROM sources",
			"DELETE FROM task_types",
			"DELETE FROM workspaces",
		],
	)

insert_defaults! : Path => Try({}, _)
insert_defaults! = |db_path| {
	execute!(
		db_path,
		(
			\\INSERT INTO sources (workspace_id, source_id, name, position, active) VALUES
			\\ ('workspace-main', 'referral', 'Referral', 1, 1),
			\\ ('workspace-main', 'inbound', 'Inbound enquiry', 2, 1),
			\\ ('workspace-main', 'outbound', 'Outbound prospecting', 3, 1),
			\\ ('workspace-main', 'event', 'Event', 4, 1),
			\\ ('workspace-main', 'partner', 'Partner', 5, 1),
			\\ ('workspace-main', 'other', 'Other', 6, 1);
			,
		),
		[],
	)?
	execute!(
		db_path,
		(
			\\INSERT INTO task_types (workspace_id, task_type_id, name, position, active) VALUES
			\\ ('workspace-main', 'call', 'Call', 1, 1),
			\\ ('workspace-main', 'email', 'Email', 2, 1),
			\\ ('workspace-main', 'meeting', 'Meeting', 3, 1),
			\\ ('workspace-main', 'follow-up', 'Follow up', 4, 1),
			\\ ('workspace-main', 'other', 'Other', 5, 1);
			,
		),
		[],
	)
}

members_list! : Path => Try({}, _)
members_list! = |db_path| {
	schema_check!(db_path)?
	members = Sqlite.query_many!({
		path: db_path,
		query: "SELECT name, email, active FROM members ORDER BY name;",
		bindings: [],
		rows: decode_member,
	})?
	for member in members {
		status = if member.active == 1 {
			"active"
		} else {
			"inactive"
		}
		Stdout.line!("${member.email}\t${status}\t${member.name}")?
	}
	Ok({})
}

member_add! : Path, Str, Str => Try({}, _)
member_add! = |db_path, raw_name, raw_email| {
	schema_check!(db_path)?
	name = raw_name.trim()
	email = normalize_email(raw_email)
	if name.is_empty() {
		return Err(MissingArgument("--name"))
	}
	if !Authentication.valid_login(email) {
		return Err(InvalidEmail(email))
	}
	execute!(
		db_path,
		(
			\\INSERT INTO members (member_id, workspace_id, name, email, active)
			\\SELECT 'member-' || lower(hex(randomblob(16))), workspace_id, :name, :email, 1
			\\FROM workspaces
			\\LIMIT 1;
			,
		),
		[string_binding(":name", name), string_binding(":email", email)],
	)
}

member_set_active! : Path, Str, Bool => Try({}, _)
member_set_active! = |db_path, raw_email, active| {
	schema_check!(db_path)?
	email = normalize_email(raw_email)
	target_count = Sqlite.query!({
		path: db_path,
		query: "SELECT COUNT(*) AS count FROM members WHERE email = :email;",
		bindings: [string_binding(":email", email)],
		row: Sqlite.i64("count"),
	})?
	if target_count == 0 {
		return Err(MemberNotFound(email))
	}
	if !active {
		active_count = Sqlite.query!({
			path: db_path,
			query: "SELECT COUNT(*) AS count FROM members WHERE active = 1;",
			bindings: [],
			row: Sqlite.i64("count"),
		})?
		target_active = Sqlite.query!({
			path: db_path,
			query: "SELECT COUNT(*) AS count FROM members WHERE email = :email AND active = 1;",
			bindings: [string_binding(":email", email)],
			row: Sqlite.i64("count"),
		})?
		if active_count <= 1 and target_active == 1 {
			return Err(CannotDeactivateLastActiveMember)
		}
	}
	execute!(
		db_path,
		"UPDATE members SET active = :active WHERE email = :email;",
		[
			{
				name: ":active",
				value: Integer(
					if active {
						1
					} else {
						0
					},
				),
			},
			string_binding(":email", email),
		],
	)
}

execute! : Path, Str, List(Sqlite.Binding) => Try({}, _)
execute! = |path, query, bindings| Sqlite.execute!({ path, query, bindings })

string_binding : Str, Str -> Sqlite.Binding
string_binding = |name, value| { name, value: String(value) }

normalize_email : Str -> Str
normalize_email = |value| value.trim().with_ascii_lowercased()

decode_member = |cols|
	|stmt| {
		name = Sqlite.str("name")(cols)(stmt)?
		email = Sqlite.str("email")(cols)(stmt)?
		active = Sqlite.i64("active")(cols)(stmt)?
		Ok({ active, email, name })
	}
