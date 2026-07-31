# Enquiry CRM

A focused, server-rendered CRM for capturing company enquiries, the people
behind them, and accountable follow-up work. It is implemented in
[Roc](https://www.roc-lang.org) with SQLite and progressively enhanced HTML.

The current vertical slice supports:

- active workspace members resolved from a trusted network identity;
- searchable company and person records;
- duplicate review before company or person creation;
- concurrency-safe edits with record revisions;
- optional company association and multiple labeled email/phone methods;
- company-scoped person capture;
- an optional, server-side business-card scanner that prefills the person
  review form; and
- company/person follow-up tasks grouped as overdue, due today, or upcoming in
  the workspace timezone.

The current implemented delivery boundary is in
[docs/product/10-slice-company-enquiry.md](docs/product/10-slice-company-enquiry.md).
The complete product design remains in
[docs/product/00-full-design-minimal-crm.md](docs/product/00-full-design-minimal-crm.md).
The next proposed delivery boundary is
[docs/product/11-slice-opportunity-qualification.md](docs/product/11-slice-opportunity-qualification.md).

## Quick start

Install `roc` and `sqlite3`, then run:

```sh
roc scripts/tasks.roc dev
```

Open <http://127.0.0.1:8000>. The development task validates the application,
recreates the disposable database from the checked-in schema and fixtures,
builds the assets, and starts a loopback development proxy. The proxy injects
Mara's trusted identity by default, and the navbar labels it as development
mode. Any local development data is discarded each time the task starts.

Use Theo's identity, or preserve the current database while switching users:

```sh
roc scripts/tasks.roc dev --member-email theo@example.com
roc scripts/tasks.roc dev --member-email theo@example.com --keep-db
```

`--keep-db` applies forward migrations without replacing `dist/playground.db`.
The selected email must belong to an active member in that database.

To recreate the database without starting the server:

```sh
roc scripts/tasks.roc reset-db
```

`db/migrations/` contains the versioned schema and `db/test-fixtures.sql`
contains representative development/test records. Production databases are
created and maintained with the bundled `enquiry-crm-admin` executable.

## Development

```sh
# Generated CSS, formatting, type checking, pure tests, and fresh-SQL integration tests
roc scripts/tasks.roc check

# Chromium journeys against an isolated database and server on port 8010
roc scripts/tasks.roc setup
roc scripts/tasks.roc test-e2e

# Everything above in one verification command (after setup)
roc scripts/tasks.roc check-all

# Build the executable and runtime assets under dist/
roc scripts/tasks.roc build

# Rebuild generated CSS once or continuously
roc scripts/tasks.roc css
roc scripts/tasks.roc css-watch
```

`roc scripts/tasks.roc help` lists every project task. npm remains the locked
dependency installer for Playwright, but `package.json` does not define a
second task interface.

The task runner downloads and verifies the pinned standalone Tailwind CSS CLI
under `.tools/`. Tailwind class strings live only in `src/Design.roc`; views
consume semantic design attributes.

The Playwright suite lives under `tests/`. It resets only
`test-results/playwright.db`, builds the current source, and owns port 8010, so
it does not disturb the development database or a server on port 8000. The
suite asserts behavior and accessible UI text; it does not use screenshot
baselines. Failure traces are retained under `test-results/`.

## Architecture

Each CRM feature follows a typed vertical slice:

```text
Route -> main dispatch -> Handler -> Domain
                              |-> Store -> SQLite
                              `-> View  -> HTML
```

External strings are parsed in handlers or routing, domain modules own
validated values and pure decisions, stores own SQL/storage conversion, and
`src/main.roc` is the composition root. The application opens one shared SQLite
pool and loads the single configured workspace at startup.

See [architecture.md](architecture.md) for the design rationale and evidence.

The server and administration command both require one versioned JSON
configuration file:

```json
{
  "version": 1,
  "server": {
    "database_path": "/path/to/crm.sqlite",
    "assets_path": "/path/to/assets",
    "public_origin": "https://machine-name.tailnet-name.ts.net",
    "listen_port": 8000,
    "timezone": "Australia/Melbourne"
  },
  "features": {
    "business_card_scanner": {
      "enabled": false,
      "provider": null
    }
  }
}
```

Point both executables at it:

```sh
SERVER_CONFIG_PATH=/path/to/enquiry-crm.json enquiry-crm
```

`server.timezone` must exactly match the timezone stored in the workspace so
due-date grouping and local-to-UTC conversion cannot silently use the host
timezone. The business-card feature remains absent from the UI while disabled.
To enable it, configure an OpenRouter provider with an API key and model (the
initial model is `openai/gpt-5.6-luna`) as shown in the production deployment
guide. Keep this file readable only by the service account because it contains
secrets.

AI prompts and their strict output schema are checked-in flat files under
`prompts/` and embedded into the Roc binary at build time. Prompt changes
therefore follow the same review, release, and rollback trail as code changes.

The server always binds to `127.0.0.1`. Both environments use the same trusted
identity header and active-member lookup. In development, the bundled loopback
proxy strips any client-supplied identity before injecting the selected member.
In production, Tailscale Serve supplies the verified identity. The application
does not provide local login, registration, logout, or cookie sessions. Other
HTTP origins are rejected.

The supported production procedure, release workflow, member administration,
systemd hardening, and Tailscale access policy are documented in
[docs/deployment/digitalocean-tailscale.md](docs/deployment/digitalocean-tailscale.md).

Production releases are x64 Linux bundles identified by the commit's UTC
timestamp and 12-character Git SHA. The manually triggered release workflow
derives that immutable release ID, extracts and installs the bundle into the
production filesystem layout, runs the browser and authentication suites
against that exact release, and creates the Git tag only after those checks
pass.
