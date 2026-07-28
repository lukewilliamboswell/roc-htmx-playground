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

Open <http://127.0.0.1:8000>. The development task builds assets, creates a
fresh disposable database when needed, sets `TZ=Australia/Melbourne` to match
the bootstrap workspace, validates the application, and starts the server.

To recreate the database after a schema change:

```sh
roc scripts/tasks.roc reset-db
```

There are deliberately no migrations or compatibility guarantees for old
database files during this refactor. `db/init.sql` is the canonical schema and
`db/test-fixtures.sql` contains representative development/test records.

## Development

```sh
# Generated CSS, formatting, type checking, pure tests, and fresh-SQL integration tests
roc scripts/tasks.roc check

# Build the executable and runtime assets under dist/
roc scripts/tasks.roc build

# Rebuild generated CSS once or continuously
roc scripts/tasks.roc css
roc scripts/tasks.roc css-watch
```

The task runner downloads and verifies the pinned standalone Tailwind CSS CLI
under `.tools/`. Tailwind class strings live only in `src/Design.roc`; views
consume semantic design attributes.

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
TZ=Australia/Melbourne
```

`TZ` must exactly match the timezone stored in the workspace so due-date
grouping and local-to-UTC conversion cannot silently use the host timezone.
Place the server behind the organisation’s private-network access boundary and
a reverse proxy that provides TLS.
