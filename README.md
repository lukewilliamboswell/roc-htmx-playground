# Enquiry CRM

A focused, server-rendered CRM for capturing company enquiries, the people
behind them, and accountable follow-up work. It is implemented in
[Roc](https://www.roc-lang.org) with SQLite and progressively enhanced HTML.

The current vertical slice supports:

- active workspace members acting through typed sessions;
- searchable company and person records;
- duplicate review before company or person creation;
- concurrency-safe edits with record revisions;
- optional company association and multiple labeled email/phone methods;
- company-scoped person capture; and
- company/person follow-up tasks grouped as overdue, due today, or upcoming in
  the workspace timezone.

The detailed product contract is in
[docs/product/company-enquiry-slice.md](docs/product/company-enquiry-slice.md).
The broader research and requirements remain in
[docs/product/minimal-crm-requirements.md](docs/product/minimal-crm-requirements.md).

## Quick start

Install `roc` and `sqlite3`, then run:

```sh
roc scripts/tasks.roc dev
```

Open <http://127.0.0.1:8000>. The development task validates the application,
recreates the disposable database from the checked-in schema and fixtures,
builds the assets, sets `TZ=Australia/Melbourne` to match the bootstrap
workspace, and starts the server. Any local development data is discarded each
time the task starts.

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
npm install
npx playwright install chromium
npm run test:e2e

# Build the executable and runtime assets under dist/
roc scripts/tasks.roc build

# Rebuild generated CSS once or continuously
roc scripts/tasks.roc css
roc scripts/tasks.roc css-watch
```

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

Legacy playground routes remain directly addressable while the refactor is
incremental, but they are no longer part of the product navigation. See
[architecture.md](architecture.md) for the design rationale and evidence.

For deployment, provide:

```sh
DB_PATH=/path/to/crm.sqlite
ASSET_PATH=/path/to/assets
AUTH_MODE=tailscale
PUBLIC_ORIGIN=https://machine-name.tailnet-name.ts.net
PORT=8000
TZ=Australia/Melbourne
```

`TZ` must exactly match the timezone stored in the workspace so due-date
grouping and local-to-UTC conversion cannot silently use the host timezone.
The server always binds to `127.0.0.1`. In `tailscale` authentication mode it
trusts Tailscale Serve's verified login header, maps that email to an active
pre-provisioned member, and disables the development login and registration
routes.

The supported production procedure, release workflow, member administration,
systemd hardening, and Tailscale access policy are documented in
[docs/deployment/digitalocean-tailscale.md](docs/deployment/digitalocean-tailscale.md).

Production releases are versioned x64 Linux bundles. The manually triggered
release workflow derives the version from `VERSION`, extracts and installs the
bundle into the production filesystem layout, runs the browser and
authentication suites against that exact release, and creates the Git tag only
after those checks pass.
