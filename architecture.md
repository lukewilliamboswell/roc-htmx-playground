# Enquiry CRM architecture

Enquiry CRM is a server-rendered Roc application with SQLite persistence and
small htmx enhancements. The architecture keeps HTTP, domain, persistence, and
HTML concerns explicit:

```text
Route -> main dispatch -> Handler -> Domain
                              |-> Store -> SQLite
                              `-> View  -> HTML
```

`src/main.roc` is the composition root. It opens the database, verifies that it
matches the application schema, loads the single workspace, creates concrete
stores, resolves one request actor, and dispatches the parsed route. Handlers
receive only the stores needed by their feature.

## Identity boundary

The application does not own passwords, registration, login forms, logout, or
cookie sessions. Every non-health request requires one
`Tailscale-User-Login` header and resolves its normalized email against an
active row in `members`.

In production, Tailscale Serve is the trusted proxy and the application listens
only on loopback. In development, `scripts/dev-server.js` starts the application
on a private loopback port and exposes a second loopback proxy. That proxy
removes any client-supplied identity header and injects the member selected by
`roc scripts/tasks.roc dev --member-email EMAIL`. The navbar adds a `Dev mode` badge
only when the configured public origin selects development mode.

This makes the application-side authorization path identical in development
and production while keeping the source of trust environment-specific.

## HTTP and routing

`src/Route.roc` owns the closed vocabulary of pages, mutations, assets, and URL
generation. Views use typed route values instead of string URLs. `src/Http.roc`
owns response headers, form decoding, same-origin mutation checks, and error
representation.

The public product routes cover home, companies, people, and follow-up work.
The former playground login, User, Todo/Tree, and BigTask routes and modules
have been removed.

## Domain and persistence

Company, person, activity, and work-task modules own validated values and pure
decisions. Their stores own SQL and storage conversion. Mutations use SQLite
transactions and record versions where concurrent edits could otherwise
overwrite one another.

Database migrations are immutable and ordered. The admin executable applies
them sequentially, verifies the resulting schema, preserves product data during
upgrades, and rejects databases newer than the application. Retired product
experiments do not remain in the runtime schema.

Development resets the fixture database by default. `--keep-db` preserves it,
applies forward migrations, and makes it possible to stop the server and restart
as another member without losing state.

## Configuration and AI boundary

The server and administration executable load the same required, versioned JSON
configuration through `SERVER_CONFIG_PATH`. Server-wide settings and
feature-specific provider credentials are validated once at startup. A disabled
feature requires no provider configuration and is not rendered or routed.

Business-card images are resized and stripped of metadata in the browser, then
sent to the application in a same-origin multipart request. The application
enforces a short-lived, one-use member/workspace grant, JPEG and size checks,
per-member rate limits, and member/workspace concurrency limits before making
the provider request. Provider routing requires zero data retention and denies
data collection; failure to satisfy those requirements fails the scan.

Prompts and the structured-output schema are flat files under `prompts/` and
are embedded into the executable with Roc imports. Each run stores permanent
operational metadata and prompt/release identifiers, but never stores the card
image, extracted contact details, API key, or raw provider response. The person
record is written only after the member reviews and submits the normal create
form.

## Verification

- Roc unit tests cover domain and rendering behavior.
- `src/test.roc` creates a database from every current migration and exercises
  stores, handlers, and rendered HTML.
- Playwright covers accessible CRM journeys through the development proxy.
- Playwright recomputes the SHA-256 version of every long-lived browser asset
  referenced by the home and application pages.
- Authentication and migration smoke tests cover data-preserving upgrades,
  proxy spoof resistance, selectable Mara/Theo identities, POST forwarding,
  and production Tailscale behavior.
- `ci/check_source_contracts.sh` enforces cross-module source boundaries that
  are not represented directly in Roc's type system.
