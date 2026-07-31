app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.21.0/4rAQg8kUYZ3Vksr4qMQHpaFYNiHSn9GgS7gVxghd1XYV.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Cmd
import pf.Env
import pf.Http
import pf.OsStr
import pf.Path
import pf.Stdout
import http.Request
import http.Response

TailwindTarget := {
	asset : Str,
	checksum : Str,
}

Spec42Target := {
	asset : Str,
	checksum : Str,
}

DevOptions := {
	memberEmail : Str,
	keepDb : Bool,
}

# TODO: Restore `speed` after re-verifying the optimized full application
# build with the pinned nightly and platform.
deploymentOptimization : Str
deploymentOptimization = "dev"

main! : List(OsStr) => Try({}, _)
main! = |args|
	match args.drop_first(1) {
		[] => usage!()
		[command_arg, .. as command_args] => {
			command = OsStr.display(command_arg)

			match command {
				"css" => buildCss!(Bool.False)
				"css-watch" => buildCss!(Bool.True)
				"build" => buildDistribution!(deploymentOptimization)
				"check" => check!()
				"check-all" => checkAll!()
				"model-check" => modelCheck!()
				"dev" => dev!(command_args.map(OsStr.display))
				"reset-db" => resetDevDatabase!()
				"release" => release!()
				"setup" => setup!(Bool.False)
				"setup-ci" => setup!(Bool.True)
				"tailwind-install" => {
					_ = ensureTailwind!()?
					Ok({})
				}
				"test-auth" => testAuth!()
				"test-browser" => testBrowser!()
				"test-e2e" => testE2e!()
				"help" => usage!()
				"--help" => usage!()
				"-h" => usage!()
				_ => {
					usage!()?
					Err(UnknownCommand(command))
				}
			}
		}
	}

usage! : () => Try({}, _)
usage! = || {
	Stdout.line!(
		\\Usage: roc scripts/tasks.roc <command>
		\\
		\\Commands:
		\\  css               Build minified CSS
		\\  css-watch         Rebuild CSS when the design system changes
		\\  build             Build a local runtime bundle in dist/
		\\  check             Build CSS, format-check, type-check, and test
		\\  check-all         Run check and all end-to-end tests
		\\  model-check       Validate the SysML model and traceability contracts
		\\  dev [--member-email EMAIL] [--keep-db]
		\\                    Serve as Mara by default; optionally preserve the DB
		\\  reset-db          Recreate the disposable development database
		\\  release           Build the identified x64 Linux release bundle
		\\  setup             Install Node packages and Chromium
		\\  setup-ci          Install test tooling and Linux system dependencies
		\\  tailwind-install  Install the pinned standalone Tailwind CLI
		\\  test-auth         Test production Tailscale authentication
		\\  test-browser      Run the Playwright browser journeys
		\\  test-e2e          Run the browser and authentication suites
		,
	)?

	Ok({})
}

dev! : List(Str) => Try({}, _)
dev! = |args| {
	options = parse_dev_options(
		args,
		DevOptions.{
			memberEmail: "mara@example.com",
			keepDb: Bool.False,
		},
	)?
	run!("roc", ["fmt", "scripts", "src"])?
	run!("roc", ["check", "src/main.roc"])?
	run!("roc", ["test", "src/main.roc"])?
	checkIntegration!("dev")?

	if options.keepDb {
		db_path = ensureDevDatabase!()?
		buildDistribution!("dev")?
		Stdout.line!("Preserving and migrating ${db_path}")?
	} else {
		resetDevDatabase!()?
		buildDistribution!("dev")?
		Stdout.line!("Reset dist/playground.db from development fixtures")?
	}

	Cmd.new_str("node")
		.args_str(["scripts/dev-server.js", "--member-email", options.memberEmail])
		.exec_cmd!()
}

parse_dev_options : List(Str), DevOptions -> Try(DevOptions, _)
parse_dev_options = |args, options|
	match args {
		[] => Ok(options)
		["--keep-db", .. as rest] =>
			parse_dev_options(
				rest,
				DevOptions.{
					memberEmail: options.memberEmail,
					keepDb: Bool.True,
				},
			)
		["--member-email", email, .. as rest] if !email.trim().is_empty() =>
			parse_dev_options(
				rest,
				DevOptions.{
					memberEmail: email.trim(),
					keepDb: options.keepDb,
				},
			)
		["--member-email", ..] => Err(MissingDevMemberEmail)
		[unknown, ..] => Err(UnknownDevOption(unknown))
	}

expect {
	options = parse_dev_options(
		["--member-email", "theo@example.com", "--keep-db"],
		DevOptions.{ memberEmail: "mara@example.com", keepDb: Bool.False },
	)
	match options {
		Ok(parsed) =>
			parsed.memberEmail == "theo@example.com" and parsed.keepDb
		_ => False
	}
}

ensureDevDatabase! : () => Try(Str, _)
ensureDevDatabase! = || {
	db_path = "dist/playground.db"
	database = Path.utf8(db_path)

	if !database.is_file!()? {
		Stdout.line!("Creating ${db_path} from migrations and db/test-fixtures.sql...")?
		run!("sqlite3", [db_path, ".read db/migrations/001_initial.sql"])?
		run!("sqlite3", [db_path, ".read db/migrations/002_remove_legacy_auth_and_demos.sql"])?
		run!("sqlite3", [db_path, ".read db/migrations/003_ai_foundation.sql"])?
		run!("sqlite3", [db_path, ".read db/test-fixtures.sql"])?
	}

	Ok(db_path)
}

resetDevDatabase! : () => Try({}, _)
resetDevDatabase! = || {
	db_path = "dist/playground.db"
	database = Path.utf8(db_path)

	if database.is_file!()? {
		Stdout.line!("Deleting disposable development database ${db_path}...")?
		database.delete!()?
	}

	_ = ensureDevDatabase!()?
	Ok({})
}

check! : () => Try({}, _)
check! = || {
	modelCheck!()?
	buildCss!(Bool.False)?
	run!("ci/check_source_contracts.sh", [])?
	run!("roc", ["fmt", "--check", "scripts", "src"])?
	run!("roc", ["check", "src/main.roc"])?
	run!("roc", ["check", "src/admin.roc"])?
	run!("roc", ["test", "src/main.roc"])?
	checkIntegration!("dev")?
	checkIntegration!("speed")?

	Ok({})
}

modelCheck! : () => Try({}, _)
modelCheck! = || {
	spec42 = ensureSpec42!()?
	run!("python3", ["ci/check_model_contracts.py", "check", spec42])
}

checkAll! : () => Try({}, _)
checkAll! = || {
	check!()?
	testE2e!()
}

setup! : Bool => Try({}, _)
setup! = |include_system_dependencies| {
	run!("npm", ["ci"])?
	playwright_arguments = if include_system_dependencies {
		["install", "--with-deps", "chromium"]
	} else {
		["install", "chromium"]
	}
	run!("node_modules/.bin/playwright", playwright_arguments)?
	installCiDependencies!(include_system_dependencies)?
	Ok({})
}

installCiDependencies! : Bool => Try({}, _)
installCiDependencies! = |should_install|
	if should_install {
		run!("sudo", ["apt-get", "install", "--yes", "sqlite3"])
	} else {
		Ok({})
	}

testE2e! : () => Try({}, _)
testE2e! = || {
	testBrowser!()?
	testAuth!()
}

testBrowser! : () => Try({}, _)
testBrowser! = || run!("node_modules/.bin/playwright", ["test"])

testAuth! : () => Try({}, _)
testAuth! = || {
	run!("node", ["tests/migration-smoke.js"])?
	run!("node", ["tests/business-card-smoke.js"])?
	run!("node", ["tests/dev-auth-smoke.js"])?
	run!("node", ["tests/tailscale-auth-smoke.js"])
}

checkIntegration! : Str => Try({}, _)
checkIntegration! = |optimization| {
	output = Path.display(
		Path.join(
			Env.temp_dir!(),
			"roc-htmx-playground-integration-${optimization}",
		),
	)
	build_arguments = if optimization == "dev" {
		[
			"build",
			"--output=${output}",
			"src/test.roc",
		]
	} else {
		[
			"build",
			"--opt=${optimization}",
			"--output=${output}",
			"src/test.roc",
		]
	}
	run!("roc", build_arguments)?
	runWithTimezone!(output, [])?
	Ok({})
}

buildDistribution! : Str => Try({}, _)
buildDistribution! = |optimization| {
	buildCss!(Bool.False)?
	db_path = ensureDevDatabase!()?
	run!(
		"roc",
		[
			"build",
			"--opt=${optimization}",
			"--output=dist/roc-htmx-playground",
			"src/main.roc",
		],
	)?
	run!(
		"roc",
		[
			"build",
			"--opt=${optimization}",
			"--output=dist/enquiry-crm-admin",
			"src/admin.roc",
		],
	)?
	config_path = ensureDevConfig!(db_path)?
	runWithServerConfig!("dist/enquiry-crm-admin", ["migrate"], config_path)?

	Ok({})
}

release! : () => Try({}, _)
release! = || {
	buildCss!(Bool.False)?
	release_id = OsStr.display(Env.var!("RELEASE_ID")?).trim()
	if release_id.is_empty() or release_id.contains("/") or release_id.contains("..") {
		return Err(InvalidReleaseId(release_id))
	}

	stage_root = "dist/release-stage"
	bundle_name = "enquiry-crm-${release_id}-x64-linux"
	bundle_root = "${stage_root}/${bundle_name}"
	release_dir : Path
	release_dir = "dist/release"

	run!("rm", ["-rf", stage_root])?
	Path.utf8("${bundle_root}/bin").create_all!()?
	Path.utf8("${bundle_root}/deploy").create_all!()?
	release_dir.create_all!()?

	run!(
		"roc",
		[
			"build",
			"--opt=${deploymentOptimization}",
			"--target=x64musl",
			"--output=${bundle_root}/bin/enquiry-crm",
			"src/main.roc",
		],
	)?
	run!(
		"roc",
		[
			"build",
			"--opt=${deploymentOptimization}",
			"--target=x64musl",
			"--output=${bundle_root}/bin/enquiry-crm-admin",
			"src/admin.roc",
		],
	)?

	run!("cp", ["-R", "dist/assets", "${bundle_root}/assets"])?
	run!("cp", ["deploy/enquiry-crm.service", "${bundle_root}/deploy/"])?
	run!("cp", ["deploy/enquiry-crm.json.example", "${bundle_root}/deploy/"])?
	run!("cp", ["LICENSE", "${bundle_root}/"])?
	run!("cp", ["vendor/LICENSE-htmx.txt", "${bundle_root}/"])?
	Path.utf8("${bundle_root}/RELEASE_ID").write_utf8!("${release_id}\n")?

	archive = "dist/release/${bundle_name}.tar.gz"
	run!("tar", ["-C", stage_root, "-czf", archive, bundle_name])?
	Stdout.line!(archive)?
	Ok({})
}

run! : Str, List(Str) => Try({}, _)
run! = |program, arguments|
	Cmd.new_str(program)
		.args_str(arguments)
		.exec_cmd!()

runWithServerConfig! : Str, List(Str), Str => Try({}, _)
runWithServerConfig! = |program, arguments, config_path|
	Cmd.new_str(program)
		.args_str(arguments)
		.env_str("SERVER_CONFIG_PATH", config_path)
		.exec_cmd!()

ensureDevConfig! : Str => Try(Str, _)
ensureDevConfig! = |db_path| {
	config_path = "dist/development.server.json"
	Path.utf8(config_path).write_utf8!((
		\\{
		\\  "version": 1,
		\\  "server": {
		\\    "database_path": ${Json.to_str(db_path)},
		\\    "assets_path": "dist/assets",
		\\    "public_origin": "http://127.0.0.1:8000",
		\\    "listen_port": 8001,
		\\    "timezone": "Australia/Melbourne"
		\\  },
		\\  "features": {
		\\    "business_card_scanner": {
		\\      "enabled": false,
		\\      "provider": null
		\\    }
		\\  }
		\\}
		,
	))?
	Ok(config_path)
}

runWithTimezone! : Str, List(Str) => Try({}, _)
runWithTimezone! = |program, arguments|
	Cmd.new_str(program)
		.args_str(arguments)
		.env_str("TZ", "Australia/Melbourne")
		.exec_cmd!()

buildCss! : Bool => Try({}, _)
buildCss! = |watch| {
	assets : Path
	assets = "dist/assets"
	run!("rm", ["-rf", "dist/assets"])?
	assets.create_all!()?
	run!("cp", ["-R", "assets/.", "dist/assets"])?
	run!("cp", ["vendor/htmx-4-0-0-beta6.min.js", "dist/assets/htmx.min.js"])?

	tailwind = ensureTailwind!()?
	arguments = if watch {
		["-i", "src/tailwind.css", "-o", "dist/assets/styles.css", "--watch"]
	} else {
		["-i", "src/tailwind.css", "-o", "dist/assets/styles.css", "--minify"]
	}

	run!(tailwind, arguments)?
	writeAssetVersions!()?

	Ok({})
}

writeAssetVersions! : () => Try({}, _)
writeAssetVersions! = || {
	app_icon = checksum!("dist/assets/icons/app.svg")?
	hero_480 = checksum!("dist/assets/planning-desk-480.webp")?
	hero_640 = checksum!("dist/assets/planning-desk-640.webp")?
	hero_720 = checksum!("dist/assets/planning-desk-720.webp")?
	hero_960 = checksum!("dist/assets/planning-desk-960.webp")?
	htmx = checksum!("dist/assets/htmx.min.js")?
	interactions = checksum!("dist/assets/interactions.js")?
	stylesheet = checksum!("dist/assets/styles.css")?

	Path.utf8("src/AssetVersions.roc").write_utf8!((
		\\## Generated by `roc scripts/tasks.roc css`. Do not edit by hand.
		\\
		\\AssetVersions := [].{
		\\	appIcon : Str
		\\	appIcon = "${app_icon}"
		\\
		\\	hero480 : Str
		\\	hero480 = "${hero_480}"
		\\
		\\	hero640 : Str
		\\	hero640 = "${hero_640}"
		\\
		\\	hero720 : Str
		\\	hero720 = "${hero_720}"
		\\
		\\	hero960 : Str
		\\	hero960 = "${hero_960}"
		\\
		\\	htmx : Str
		\\	htmx = "${htmx}"
		\\
		\\	interactions : Str
		\\	interactions = "${interactions}"
		\\
		\\	stylesheet : Str
		\\	stylesheet = "${stylesheet}"
		\\}
		\\
		,
	))?

	Ok({})
}

ensureTailwind! : () => Try(Str, _)
ensureTailwind! = || {
	target = tailwindTarget!()?
	binary_path : Str
	binary_path = ".tools/tailwindcss"
	binary : Path
	binary = Path.utf8(binary_path)

	is_current = if binary.is_file!()? {
		checksum!(binary_path)? == target.checksum
	} else {
		Bool.False
	}

	if is_current {
		Ok(binary_path)
	} else {
		tools : Path
		tools = ".tools"
		tools.create_all!()?

		download_path : Str
		download_path = ".tools/tailwindcss.download"
		download : Path
		download = Path.utf8(download_path)
		url = "https://github.com/tailwindlabs/tailwindcss/releases/download/v4.3.0/${target.asset}"

		Stdout.line!("Downloading Tailwind CSS v4.3.0 standalone CLI...")?
		bytes = downloadBytes!(url, 5)?
		download.write_bytes!(bytes)?

		actual_checksum = checksum!(download_path)?
		if actual_checksum != target.checksum {
			return Err(
				ChecksumMismatch({
					actual: actual_checksum,
					expected: target.checksum,
				}),
			)
		}

		run!("chmod", ["755", download_path])?
		download.rename!(binary)?
		Stdout.line!("Installed ${binary_path}")?

		Ok(binary_path)
	}
}

tailwindTarget! : () => Try(TailwindTarget, _)
tailwindTarget! = || {
	host_platform = Env.platform!()

	match (host_platform.os, host_platform.arch) {
		(MACOS, AARCH64) =>
			Ok(
				TailwindTarget.{
					asset: "tailwindcss-macos-arm64",
					checksum: "56b4bbc62dbdc4614a78930d9c6986423a2ec63e4e640144a59a5d95c914322e",
				},
			)
		(MACOS, X64) =>
			Ok(
				TailwindTarget.{
					asset: "tailwindcss-macos-x64",
					checksum: "2ba252f770817091e6d0d12a84e0dd531bcc29aad1bfd9d976a3aff1a071b67a",
				},
			)
		(LINUX, AARCH64) =>
			Ok(
				TailwindTarget.{
					asset: "tailwindcss-linux-arm64",
					checksum: "8f48dcb72be3b351c10563c5329b4638ba8516820dc3b3a1609625a166e87cbd",
				},
			)
		(LINUX, X64) =>
			Ok(
				TailwindTarget.{
					asset: "tailwindcss-linux-x64",
					checksum: "73f0e5459054e5cfaa8ab6f3b940f3fbe0f13cc7fd83bc24e7c655033c203400",
				},
			)
		_ => Err(UnsupportedPlatform(Str.inspect(host_platform)))
	}
}

ensureSpec42! : () => Try(Str, _)
ensureSpec42! = || {
	target = spec42Target!()?
	binary_path : Str
	binary_path = ".tools/spec42-0.40.0/spec42"
	binary : Path
	binary = Path.utf8(binary_path)

	if binary.is_file!()? {
		Ok(binary_path)
	} else {
		tools : Path
		tools = ".tools"
		tools.create_all!()?

		archive_path : Str
		archive_path = ".tools/${target.asset}"
		archive : Path
		archive = Path.utf8(archive_path)
		url = "https://github.com/elan8/spec42/releases/download/v0.40.0/${target.asset}"

		Stdout.line!("Downloading Spec42 v0.40.0...")?
		bytes = downloadBytes!(url, 5)?
		archive.write_bytes!(bytes)?

		actual_checksum = checksum!(archive_path)?
		if actual_checksum != target.checksum {
			return Err(
				ChecksumMismatch({
					actual: actual_checksum,
					expected: target.checksum,
				}),
			)
		}

		stage_path : Str
		stage_path = ".tools/spec42-0.40.0-stage"
		run!("rm", ["-rf", ".tools/spec42-0.40.0", stage_path])?
		stage : Path
		stage = Path.utf8(stage_path)
		stage.create_all!()?
		run!("tar", ["-xzf", archive_path, "-C", stage_path])?
		run!("chmod", ["755", "${stage_path}/spec42"])?
		stage.rename!(Path.utf8(".tools/spec42-0.40.0"))?
		archive.delete!()?
		Stdout.line!("Installed ${binary_path}")?

		Ok(binary_path)
	}
}

spec42Target! : () => Try(Spec42Target, _)
spec42Target! = || {
	host_platform = Env.platform!()

	match (host_platform.os, host_platform.arch) {
		(MACOS, AARCH64) =>
			Ok(
				Spec42Target.{
					asset: "spec42-0.40.0-darwin-arm64.tar.gz",
					checksum: "002f15bf380a796cf5ffee2538ac67d8f699de397b827a71c6705540acdb0e65",
				},
			)
		(MACOS, X64) =>
			Ok(
				Spec42Target.{
					asset: "spec42-0.40.0-darwin-x64.tar.gz",
					checksum: "17dc001049f7a3fbd9a511b596879989ed30b0a533032ac91794b10267349483",
				},
			)
		(LINUX, X64) =>
			Ok(
				Spec42Target.{
					asset: "spec42-0.40.0-linux-x64.tar.gz",
					checksum: "21b1c236fbb5974c2bf2d3fef22a606f9fd3353fbdcd123a1df7d56ef168d939",
				},
			)
		_ => Err(UnsupportedPlatform(Str.inspect(host_platform)))
	}
}

checksum! : Str => Try(Str, _)
checksum! = |path| {
	host_platform = Env.platform!()
	command = match host_platform.os {
		MACOS => Cmd.new_str("shasum").args_str(["-a", "256", path])
		LINUX => Cmd.new_str("sha256sum").arg_str(path)
		_ => return Err(UnsupportedChecksumPlatform(Str.inspect(host_platform.os)))
	}
	output : { stdout_utf8 : Str, stderr_utf8_lossy : Str }
	output = command.exec_output!()?

	match output.stdout_utf8.trim().split_on(" ") {
		[checksum, ..] if !checksum.is_empty() => Ok(checksum)
		_ => Err(InvalidChecksumOutput(output.stdout_utf8))
	}
}

downloadBytes! : Str, U8 => Try(List(U8), _)
downloadBytes! = |url, redirects_remaining| {
	request = Request.from_method(GET)
		.with_uri(url)
		.with_timeout(TimeoutMilliseconds(120_000))
	response = Http.send!(request)?
	status = Response.status(response)

	if status == 200 {
		Ok(Response.body(response))
	} else if status >= 300 and status < 400 {
		if redirects_remaining == 0 {
			Err(TooManyRedirects)
		} else {
			match redirectLocation(Response.headers(response)) {
				Found(location) => downloadBytes!(location, redirects_remaining - 1)
				Missing => Err(MissingRedirectLocation)
			}
		}
	} else {
		Err(DownloadFailed({ status, url }))
	}
}

redirectLocation : List({ name : Str, value : Str }) -> [Found(Str), Missing]
redirectLocation = |headers|
	match headers {
		[] => Missing
		[{ name, value }, ..] if name == "location" or name == "Location" => Found(value)
		[_, .. as rest] => redirectLocation(rest)
	}
