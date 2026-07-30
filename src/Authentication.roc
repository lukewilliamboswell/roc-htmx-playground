import pf.Url

Authentication := [].{
	Mode := [
		Development({ publicOrigin : Str }),
		Tailscale({ publicOrigin : Str }),
	].{
		is_eq : _

		from_public_origin : Str -> Try(Mode, [InvalidPublicOrigin(Str)])
		from_public_origin = |raw_origin| {
			origin = raw_origin.trim().with_ascii_lowercased()
			match Url.parse(origin) {
				Ok(url) if valid_public_origin(origin) =>
					match Url.scheme(url) {
						Http if Url.host(url) == "127.0.0.1" =>
							Ok(Development({ publicOrigin: origin }))
						Http => Err(InvalidPublicOrigin(origin))
						Https => Ok(Tailscale({ publicOrigin: origin }))
					}
				_ => Err(InvalidPublicOrigin(origin))
			}
		}

		public_origin : Mode -> Str
		public_origin = |mode|
			match mode {
				Development(config) => config.publicOrigin
				Tailscale(config) => config.publicOrigin
			}

		is_development : Mode -> Bool
		is_development = |mode|
			match mode {
				Development(_) => Bool.True
				Tailscale(_) => Bool.False
			}
	}

	Identity := {
		login : Str,
	}.{
		is_eq : _
	}

	tailscale_identity : List({ name : Str, value : Str }) -> Try(Identity, [MissingTrustedIdentity, AmbiguousTrustedIdentity, InvalidTrustedIdentity])
	tailscale_identity = |headers| {
		values = headers
			.keep_if(|header| header.name.with_ascii_lowercased() == "tailscale-user-login")
			.map(|header| header.value.trim().with_ascii_lowercased())
		match values {
			[] => Err(MissingTrustedIdentity)
			[login] if valid_login(login) => Ok(Identity.{ login })
			[_] => Err(InvalidTrustedIdentity)
			_ => Err(AmbiguousTrustedIdentity)
		}
	}

	valid_login : Str -> Bool
	valid_login = |raw_login| {
		login = raw_login.trim().with_ascii_lowercased()
		match login.split_on("@") {
			[local, domain] =>
				!local.is_empty()
					and valid_domain(domain)
						and !login.to_utf8().any(is_ascii_whitespace)
			_ => Bool.False
		}
	}
}

valid_public_origin : Str -> Bool
valid_public_origin = |origin| {
	match Url.parse(origin) {
		Ok(url) =>
			Url.path(url) == "/"
				and Url.query(url) == None
					and Url.fragment(url) == None
						and Url.to_str(url) == "${origin}/"
		_ => Bool.False
	}
}

valid_domain : Str -> Bool
valid_domain = |domain|
	!domain.is_empty()
		and domain.contains(".")
			and !domain.starts_with(".")
				and !domain.ends_with(".")

is_ascii_whitespace : U8 -> Bool
is_ascii_whitespace = |byte| byte == 32 or byte == 9 or byte == 10 or byte == 13

expect Authentication.Mode.from_public_origin("http://127.0.0.1:8000")
	== Ok(
		Authentication.Mode.Development({
			publicOrigin: "http://127.0.0.1:8000",
		}),
	)
expect Authentication.Mode.from_public_origin("https://crm.example.ts.net")
	== Ok(
		Authentication.Mode.Tailscale({
			publicOrigin: "https://crm.example.ts.net",
		}),
	)
expect Authentication.Mode.from_public_origin("http://crm.example.ts.net").is_err()
expect Authentication.Mode.from_public_origin("http://localhost:8000").is_err()
expect Authentication.Mode.from_public_origin("https://").is_err()
expect Authentication.Mode.from_public_origin("https://crm.example/").is_err()
expect Authentication.Mode.from_public_origin("https://crm.example/path").is_err()
expect Authentication.Mode.from_public_origin("https://crm.example?query=yes").is_err()
expect Authentication.Mode.from_public_origin("https://crm.example#fragment").is_err()
expect Authentication.Mode.from_public_origin("https://user@crm.example").is_err()
expect Authentication.Mode.from_public_origin("https://crm.example:443").is_err()
expect Authentication.Mode.from_public_origin("https://crm.example:70000").is_err()
expect Authentication.Mode.from_public_origin("https://-crm.example").is_err()
expect Authentication.Mode.from_public_origin("https://crm..example").is_err()
expect Authentication.tailscale_identity([
	{ name: "Tailscale-User-Login", value: " Luke@Example.COM " },
]) == Ok(Authentication.Identity.{ login: "luke@example.com" })
expect Authentication.tailscale_identity([]).is_err()
expect Authentication.tailscale_identity([
	{ name: "Tailscale-User-Login", value: "one@example.com" },
	{ name: "tailscale-user-login", value: "two@example.com" },
]).is_err()
expect Authentication.valid_login("owner@example.com")
expect !Authentication.valid_login("owner@")
expect !Authentication.valid_login("@example.com")
expect !Authentication.valid_login("owner@@example.com")
