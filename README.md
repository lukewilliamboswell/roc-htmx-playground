# Roc + htmx playground

A small server-rendered application for exploring how
[Roc](https://www.roc-lang.org), [htmx](https://htmx.org), and SQLite fit
together. It goes beyond a minimal example with typed routing, forms, sessions,
database adapters, static assets, and focused htmx interactions.

![The Roc and htmx playground homepage](assets/app-home.png)

The playground includes:

- task creation, filtering, status updates, and deletion;
- registration, login, and shared session-aware navigation;
- a server-rendered task hierarchy;
- a sortable, paginated, editable data table with CSV export; and
- native static-file serving for responsive images and SVG icons.

The application uses modern Roc syntax,
[basic-webserver 0.14.0](https://github.com/roc-lang/basic-webserver/releases/tag/0.14.0),
and the vendored
[HTMX 4.0.0-beta6](https://github.com/bigskysoftware/htmx/releases/tag/v4.0.0-beta6)
browser build.

## Quick start

Install `roc` and `sqlite3`, then run:

```sh
roc scripts/tasks.roc build
DB_PATH=dist/playground.db ./dist/roc-htmx-playground
```

Open <http://127.0.0.1:8000>.

The build command assembles the executable, sample database, generated CSS,
vendored htmx runtime, images, and icons under `dist/`. For a validated
edit-and-run cycle, use:

```sh
roc scripts/tasks.roc dev
```

Delete `dist/playground.db` before building if you want a fresh copy of the
sample data. Set `ASSET_PATH` to override the default `dist/assets` static root
when embedding the server in another deployment layout.

## Development

The repository includes a Roc task runner, so no npm or Make installation is
needed:

```sh
# Format, validate, build, and serve a development build
roc scripts/tasks.roc dev

# Assemble a development binary and all runtime files without serving
roc scripts/tasks.roc build

# Run the same generated-CSS, formatting, type, unit, and integration checks as CI
roc scripts/tasks.roc check

# Rebuild CSS once, or continuously while editing the design system
roc scripts/tasks.roc css
roc scripts/tasks.roc css-watch
```

The task runner downloads and verifies the pinned standalone Tailwind CSS CLI
under `.tools/`. Tailwind utilities are centralized as semantic attributes in
`src/Design.roc`; views consume those attributes instead of assembling class
strings throughout the application.

## Architecture

The code is organized into typed feature slices:

- domain modules define validated values and use cases;
- handlers translate HTTP input into domain values and responses;
- stores isolate SQLite queries and storage conversion;
- views render typed models into HTML; and
- `src/main.roc` composes dependencies and dispatches typed routes.

See [architecture.md](architecture.md) for the design, alternatives considered,
and evidence gathered during the refactor.

The server opens one SQLite connection pool during initialization and shares it
with request handlers through immutable application context. It mounts the
assembled `dist/assets/` directory through basic-webserver's native static-file
support, including MIME handling, file transfer, and public cache headers.
Checked-in asset sources and licenses are documented in
[assets/README.md](assets/README.md).

For production deployment, put the application behind a reverse proxy such as
Caddy or nginx to add TLS and Brotli or gzip compression.

## Contributing

Pull requests and experiments are welcome. CI runs
`roc scripts/tasks.roc check` to verify generated CSS, formatting,
type-checking, unit tests, and SQLite integration tests.
