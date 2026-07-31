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
only when `PUBLIC_ORIGIN` selects development mode.

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

## Verification

- Roc unit tests cover domain and rendering behavior.
- `src/test.roc` creates a database from every current migration and exercises
  stores, handlers, and rendered HTML.
- Playwright covers accessible CRM journeys through the development proxy.
- Authentication and migration smoke tests cover data-preserving upgrades,
  proxy spoof resistance, selectable Mara/Theo identities, POST forwarding,
  and production Tailscale behavior.
- `ci/check_source_contracts.sh` enforces cross-module source boundaries that
  are not represented directly in Roc's type system.
