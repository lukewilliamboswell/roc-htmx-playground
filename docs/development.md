# Development guide

This guide covers local development and project verification. The root
[README](../README.md) describes the product; the [documentation
overview](README.md) explains the authoritative system model.

## Prerequisites

Install:

- [Roc](https://www.roc-lang.org);
- SQLite; and
- Python 3.

Browser tests additionally require Node.js and Chromium. The project setup task
installs their checked-in dependencies:

```sh
roc scripts/tasks.roc setup
```

## Run locally

Start the application with representative fixtures and the default development
identity:

```sh
roc scripts/tasks.roc dev
```

Open <http://127.0.0.1:8000>.

The development task validates the application, recreates the disposable
database from the checked-in schema and fixtures, builds the assets, and starts
a loopback development proxy. The proxy strips client-supplied identity
headers before injecting the selected test member.

Select another active fixture member or retain the current database:

```sh
roc scripts/tasks.roc dev --member-email theo@example.com
roc scripts/tasks.roc dev --member-email theo@example.com --keep-db
```

Without `--keep-db`, local data is recreated each time the development task
starts. With it, forward migrations are applied to `dist/playground.db`.

Recreate the disposable database without starting the server:

```sh
roc scripts/tasks.roc reset-db
```

The versioned schema is under `db/migrations/`; representative development and
test records are in `db/test-fixtures.sql`.

## Check changes

```sh
# Model, generated CSS, formatting, types, unit tests, and SQL integration
roc scripts/tasks.roc check

# Browser journeys and production authentication checks
roc scripts/tasks.roc test-e2e

# Both suites
roc scripts/tasks.roc check-all
```

Run `roc scripts/tasks.roc model-check` when working directly on the SysML
model. The normal `check` task already includes this gate.

The browser suite owns an isolated database and server on port 8010, so it does
not disturb the development database or a server on port 8000. Failure traces
are retained under `test-results/`.

## Build

Build the executable and runtime assets under `dist/`:

```sh
roc scripts/tasks.roc build
```

Rebuild generated CSS once or continuously:

```sh
roc scripts/tasks.roc css
roc scripts/tasks.roc css-watch
```

The task runner downloads checksum-verified Tailwind CSS and Spec42 binaries
into the ignored `.tools/` directory.

## Code structure

Each CRM capability follows a typed vertical slice:

```text
Route -> main dispatch -> Handler -> Domain
                              |-> Store -> SQLite
                              `-> View  -> HTML
```

Handlers and routing parse external input, domain modules own validated values
and pure decisions, stores own persistence conversion, and `src/main.roc` is
the composition root.

The [architecture model](model/01-architecture.sysml) records the detailed
structure, decisions, and trade-offs. AI prompts and their strict output schema
are checked-in under `prompts/` and embedded in the Roc binary so prompt
changes follow the same review and release trail as code.

For production configuration, releases, authentication, database
administration, and service operation, use the supported [deployment
runbook](deployment/digitalocean-tailscale.md).
