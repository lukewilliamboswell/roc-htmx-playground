import pf.Env
import pf.OsStr
import pf.Path

AppConfig := {
	server : ServerSettings,
	features : Features,
}.{
	ServerSettings := {
		databasePath : Str,
		assetsPath : Str,
		publicOrigin : Str,
		listenPort : U16,
		timezone : Str,
	}

	OpenRouter := {
		apiKey : Str,
		model : Str,
	}

	BusinessCardScanner := [Disabled, Enabled(OpenRouter)].{
		is_enabled : BusinessCardScanner -> Bool
		is_enabled = |feature|
			match feature {
				Disabled => False
				Enabled(_) => True
			}
	}

	Features := {
		businessCardScanner : BusinessCardScanner,
	}

	Error := [
		MissingPath,
		Unreadable,
		TooLarge,
		InvalidJson,
		UnsupportedVersion(I64),
		InvalidField(Str),
	].{
		to_message : Error -> Str
		to_message = |error|
			match error {
				MissingPath => "SERVER_CONFIG_PATH is required."
				Unreadable => "The server configuration file could not be read."
				TooLarge => "The server configuration file exceeds 64 KiB."
				InvalidJson => "The server configuration file is not valid version 1 JSON."
				UnsupportedVersion(version) =>
					"Unsupported server configuration version ${version.to_str()}."
				InvalidField(field) => "Invalid server configuration field: ${field}."
			}
	}

	load! : () => Try(AppConfig, Error)
	load! = ||
		match Env.var!("SERVER_CONFIG_PATH") {
			Err(_) => Err(MissingPath)
			Ok(raw_path) => load_path!(Path.from_os_str(raw_path))
		}

	load_path! : Path => Try(AppConfig, Error)
	load_path! = |path| {
		size = path.size_in_bytes!() ? |_| Unreadable
		if size > 64 * 1024 {
			return Err(TooLarge)
		}
		content = path.read_utf8!() ? |_| Unreadable
		parse(content)
	}

	parse : Str -> Try(AppConfig, Error)
	parse = |content| {
		raw : RawConfig
		raw = Json.parse(content) ? |_| InvalidJson
		if raw.version != 1 {
			return Err(UnsupportedVersion(raw.version))
		}
		validate_non_empty("server.database_path", raw.server.database_path)?
		validate_non_empty("server.assets_path", raw.server.assets_path)?
		validate_non_empty("server.public_origin", raw.server.public_origin)?
		validate_non_empty("server.timezone", raw.server.timezone)?
		if raw.server.listen_port == 0 {
			return Err(InvalidField("server.listen_port"))
		}
		scanner = if raw.features.business_card_scanner.enabled {
			provider = raw.features.business_card_scanner.provider
				? |_| InvalidField("features.business_card_scanner.provider")
			if provider.type != "openrouter" {
				return Err(InvalidField("features.business_card_scanner.provider.type"))
			}
			validate_secret("features.business_card_scanner.provider.api_key", provider.api_key)?
			validate_bounded("features.business_card_scanner.provider.model", provider.model, 200)?
			AppConfig.BusinessCardScanner.Enabled(
				AppConfig.OpenRouter.{
					apiKey: provider.api_key.trim(),
					model: provider.model.trim(),
				},
			)
		} else {
			AppConfig.BusinessCardScanner.Disabled
		}
		Ok(
			AppConfig.{
				server: AppConfig.ServerSettings.{
					databasePath: raw.server.database_path.trim(),
					assetsPath: raw.server.assets_path.trim(),
					publicOrigin: raw.server.public_origin.trim(),
					listenPort: raw.server.listen_port,
					timezone: raw.server.timezone.trim(),
				},
				features: AppConfig.Features.{
					businessCardScanner: scanner,
				},
			},
		)
	}
}

RawProvider : {
	type : Str,
	api_key : Str,
	model : Str,
}

RawFeature : {
	enabled : Bool,
	provider : Try(RawProvider, [Null]),
}

RawConfig : {
	version : I64,
	server : {
		database_path : Str,
		assets_path : Str,
		public_origin : Str,
		listen_port : U16,
		timezone : Str,
	},
	features : {
		business_card_scanner : RawFeature,
	},
}

validate_non_empty : Str, Str -> Try({}, AppConfig.Error)
validate_non_empty = |field, value|
	validate_bounded(field, value, 4096)

validate_secret : Str, Str -> Try({}, AppConfig.Error)
validate_secret = |field, value|
	validate_bounded(field, value, 512)

validate_bounded : Str, Str, U64 -> Try({}, AppConfig.Error)
validate_bounded = |field, value, maximum|
	if value.trim().is_empty() or value.to_utf8().len() > maximum {
		Err(AppConfig.Error.InvalidField(field))
	} else {
		Ok({})
	}

expect {
	parsed = AppConfig.parse((
		\\{
		\\  "version": 1,
		\\  "server": {
		\\    "database_path": "/tmp/crm.sqlite",
		\\    "assets_path": "/tmp/assets",
		\\    "public_origin": "http://localhost:8000",
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
	))
	match parsed {
		Ok(config) =>
			config.server.listenPort == 8001
				and !config.features.businessCardScanner.is_enabled()
		Err(_) => False
	}
}

expect {
	parsed = AppConfig.parse((
		\\{
		\\  "version": 1,
		\\  "server": {
		\\    "database_path": "/tmp/crm.sqlite",
		\\    "assets_path": "/tmp/assets",
		\\    "public_origin": "https://crm.example",
		\\    "listen_port": 8000,
		\\    "timezone": "Australia/Melbourne"
		\\  },
		\\  "features": {
		\\    "business_card_scanner": {
		\\      "enabled": true,
		\\      "provider": {
		\\        "type": "openrouter",
		\\        "api_key": "secret-value",
		\\        "model": "openai/gpt-5.6-luna"
		\\      }
		\\    }
		\\  }
		\\}
		,
	))
	match parsed {
		Ok(config) =>
			match config.features.businessCardScanner {
				AppConfig.BusinessCardScanner.Enabled(provider) =>
					provider.model == "openai/gpt-5.6-luna"
				AppConfig.BusinessCardScanner.Disabled => False
			}
		Err(_) => False
	}
}
