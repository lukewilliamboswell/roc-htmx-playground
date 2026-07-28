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

ReleaseTarget := {
	filename : Str,
	target : Str,
}

main! : List(OsStr) => Try({}, _)
main! = |args|
	match args.drop_first(1) {
		[] => usage!()
		[command_arg, ..] => {
			command = OsStr.display(command_arg)

			match command {
				"css" => buildCss!(Bool.False)
				"css-watch" => buildCss!(Bool.True)
				"build" => buildDistribution!("speed")
				"check" => check!()
				"dev" => dev!()
				"reset-db" => resetDevDatabase!()
				"release" => release!()
				"tailwind-install" => {
					_ = ensureTailwind!()?
					Ok({})
				}
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
		\\  dev               Format, validate, build dist/, and serve it
		\\  reset-db          Recreate the disposable development database
		\\  release           Build release binaries for Linux and macOS
		\\  tailwind-install  Install the pinned standalone Tailwind CLI
		,
	)?

	Ok({})
}

dev! : () => Try({}, _)
dev! = || {
	run!("roc", ["fmt", "scripts", "src"])?
	run!("roc", ["check", "src/main.roc"])?
	run!("roc", ["test", "src/main.roc"])?
	runWithTimezone!("roc", ["src/test.roc"])?

	buildDistribution!("dev")?

	Stdout.line!("Serving dist/roc-htmx-playground with dist/playground.db")?
	Cmd.new_str("dist/roc-htmx-playground")
		.env_str("DB_PATH", "dist/playground.db")
		.env_str("ASSET_PATH", "dist/assets")
		.env_str("TZ", "Australia/Melbourne")
		.exec_cmd!()
}

ensureDevDatabase! : () => Try(Str, _)
ensureDevDatabase! = || {
	db_path = "dist/playground.db"
	database = Path.utf8(db_path)

	if !database.is_file!()? {
		Stdout.line!("Creating ${db_path} from db/init.sql and db/test-fixtures.sql...")?
		run!("sqlite3", [db_path, ".read db/init.sql"])?
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
	buildCss!(Bool.False)?
	run!("roc", ["fmt", "--check", "scripts", "src"])?
	run!("roc", ["check", "src/main.roc"])?
	run!("roc", ["test", "src/main.roc"])?
	runWithTimezone!("roc", ["src/test.roc"])?

	Ok({})
}

release! : () => Try({}, _)
release! = || {
	buildCss!(Bool.False)?
	_ = ensureDevDatabase!()?
	dist : Path
	dist = "dist"
	dist.create_all!()?

	checksum_lines = buildReleaseTargets!(releaseTargets, [])?
	checksums : Path
	checksums = "dist/SHA256SUMS"
	checksums.write_utf8!("${Str.join_with(checksum_lines, "\n")}\n")?

	Ok({})
}

buildDistribution! : Str => Try({}, _)
buildDistribution! = |optimization| {
	buildCss!(Bool.False)?
	_ = ensureDevDatabase!()?
	run!(
		"roc",
		[
			"build",
			"--opt=${optimization}",
			"--output=dist/roc-htmx-playground",
			"src/main.roc",
		],
	)?

	Ok({})
}

buildReleaseTargets! : List(ReleaseTarget), List(Str) => Try(List(Str), _)
buildReleaseTargets! = |remaining, checksum_lines|
	match remaining {
		[] => Ok(checksum_lines)
		[target, .. as rest] => {
			output = "dist/${target.filename}"
			run!(
				"roc",
				[
					"build",
					"--opt=speed",
					"--target=${target.target}",
					"--output=${output}",
					"src/main.roc",
				],
			)?
			checksum = checksum!(output)?
			buildReleaseTargets!(rest, checksum_lines.append("${checksum}  ${target.filename}"))
		}
	}

releaseTargets : List(ReleaseTarget)
releaseTargets = [
	ReleaseTarget.{ filename: "roc-htmx-playground-x64-linux", target: "x64musl" },
	ReleaseTarget.{ filename: "roc-htmx-playground-arm64-linux", target: "arm64musl" },
	ReleaseTarget.{ filename: "roc-htmx-playground-x64-macos", target: "x64mac" },
	ReleaseTarget.{ filename: "roc-htmx-playground-arm64-macos", target: "arm64mac" },
]

run! : Str, List(Str) => Try({}, _)
run! = |program, arguments|
	Cmd.new_str(program)
		.args_str(arguments)
		.exec_cmd!()

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
