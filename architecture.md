# Application architecture

This document describes the architectural direction for this application. It is
both a guide for new contributors and a set of constraints for future changes.
The codebase may move toward this structure incrementally; an existing module
does not need to be reorganized merely to make the directory look tidy.

The central idea is:

> Model valid application concepts with types, organize code around features,
> keep pure decisions separate from effects, describe reusable behaviour with
> small caller-local constraints, and convert to strings only at system
> boundaries.

This is not a strict implementation of MVC, Clean Architecture, or any other
named pattern. It combines the parts of those approaches that fit a
server-rendered Roc and htmx application.

## Why not adopt one named architecture?

Architectural patterns are collections of tradeoffs, not rules that apply
equally to every application. We considered several common approaches.

### Traditional layered MVC

MVC separates models, views, and controllers into application-wide layers. It
is familiar and makes the path from a request to an HTML response easy to
describe.

It becomes less helpful when every feature requires edits to the same large
`Models`, `Controllers`, `Views`, and `Db` modules. Roc modules are designed to
expose one principal type or namespace and to hide their other details. Broad
technical layers do not take full advantage of that design. htmx also means a
handler may render a small fragment rather than one conventional full-page
view.

We retain MVC's useful separation between persistence, orchestration, and
rendering, but apply it within a feature instead of across the whole
application.

### Pure feature slices

A pure vertical-slice architecture puts everything for a feature in one
module. This gives excellent change locality and can be a good starting point.

As a feature grows, however, its domain rules, SQL, HTTP handling, and HTML
begin to change for different reasons. Keeping them permanently in one module
makes pure logic harder to reuse and external systems harder to upgrade.

We organize primarily by feature, but allow a feature to split along clear
domain, repository, view, route, and handler boundaries.

### Pure type-centred design

Organizing every module around a domain type closely matches Roc's type module
system and produces an expressive vocabulary.

It does not completely answer where workflows belong. Registering a user or
updating a field can involve requests, sessions, validation, persistence, and
rendering. Attaching all of those operations to one entity type would make that
type a technical grab bag.

We use type-centred modules for domain vocabulary and invariants, then use
feature handlers or use-case modules for workflows involving several types.

### Use-case or endpoint modules

An application can create one module for every operation, such as
`CreateTodo`, `DeleteTodo`, or `UpdateBigTaskField`. This makes complicated
business workflows explicit and independently testable.

Doing it for every small endpoint creates many thin files and can separate an
htmx fragment from its only caller. We introduce a dedicated use-case module
when an operation contains meaningful rules or is reused through more than one
delivery mechanism. Straightforward orchestration stays in the feature
handler.

### Full Clean or Hexagonal Architecture

Clean and Hexagonal architectures place application logic behind abstract
ports, with HTTP and SQLite implemented as replaceable adapters. This is useful
when an application has multiple databases, interfaces, or substantial
business logic that must outlive its infrastructure.

In languages with traits, interfaces, or objects, this often introduces shared
interface declarations and runtime indirection. Roc offers a smaller option:
a use case can state the exact associated methods it needs in a `where` clause.
This is useful before a second production implementation exists when it
separates an important workflow from infrastructure or enables a focused test.

We still avoid abstracting every function. A generic boundary should express a
real dependency of its caller, not merely rename a concrete call.

### Elm-style central update loop

All requests could be decoded into one application-wide `Msg` type and handled
by one central update function. This provides exhaustive dispatch and a clear
catalogue of everything the application can do.

A webserver does not have the same persistent client-side model/update loop as
an Elm application. A single `Msg` and update function would also become a
central dependency for every feature. We take the useful part—a typed and
exhaustive route/action vocabulary—without putting every workflow in one
update function.

### The resulting compromise

Our choice is deliberately a hybrid:

- feature slices provide change locality;
- domain type modules provide safety and hiding;
- repository, view, and handler boundaries separate different reasons to
  change;
- a functional core keeps decisions easy to test;
- concrete nominal adapters isolate current external systems;
- caller-local `where` constraints describe the behaviour reusable code needs;
  and
- typed routes give us exhaustive dispatch and safe link generation.

Each part addresses a problem already present in this kind of application. We
avoid additional abstraction until a feature or integration creates a concrete
need for it.

## What happens during a request?

A web request starts as untrusted bytes and strings. The URL, form fields,
cookies, and database rows can all be malformed or unexpected.

Our request flow is:

```text
HTTP request
    |
    v
parse once into typed route, identifiers, and input
    |
    v
feature handler
    |--------------------|
    v                    v
pure domain rules     persistence effects
    |                    |
    |--------------------|
             |
             v
typed page or fragment model
             |
             v
HTML view
             |
             v
HTTP response
```

Parsing happens near the outside of the application. Once a value has been
validated, inner code should receive the validated type rather than repeatedly
checking the original string.

For example, a handler should receive `Todo.Id`, not a URL segment that every
function must parse as an `I64`. It should receive `Todo.Status`, not an
arbitrary status string.

## The architectural choices

We use four complementary ideas.

### 1. Type-centred domain modules

Important domain concepts get their own Roc type modules:

```text
Todo.roc
BigTask.roc
Session.roc
User.roc
```

These modules contain the type, its related vocabulary, and pure operations
that protect its invariants. Related types should normally be associated with
their owner:

```roc
Todo := {
	id : Id,
	description : Description,
	status : Status,
}.{
	Id :: I64

	Description :: Str

	Status := [NotStarted, InProgress, Completed]

	complete : Todo -> Todo
}
```

This produces names that explain themselves:

```roc
Todo.Id
Todo.Status
BigTask.SortColumn
BigTask.Field
Session.Id
```

The exact definitions will evolve with the application. The important part is
that distinct concepts are not represented by interchangeable primitives when
confusing them would be a realistic bug.

### 2. Feature-oriented modules

Code is grouped by the feature it changes, rather than only by technical role.
A mature feature might have:

```text
Todo.roc
TodoStore.roc
TodoView.roc
TodoHandler.roc
```

Their responsibilities are:

- `Todo.roc`: domain data, finite states, validation, and pure transformations.
- `TodoStore.roc`: SQLite queries and conversion between rows and domain
  values.
- `TodoView.roc`: full pages and htmx fragments.
- `TodoHandler.roc`: orchestration of requests, adapters, rules, and views.

This application keeps the small cross-feature HTTP vocabulary in one
`Route.roc`. A larger application can split route types by feature and compose
them at the top when the central route module becomes difficult to navigate.

This resembles MVC within a feature, but we do not create global modules
containing every model, every view, or every controller. A Todo change should
not require searching through application-wide `Models`, `Pages`, and `Db`
modules.

Not every feature needs five files. A small feature can begin in one or two
modules and be split when separate responsibilities become difficult to
navigate or test.

In this repository, Roc application modules live together under `src/`.
Roc type modules imported directly by an app share that app's platform
dependencies, while reusable packages are not allowed to depend on a platform.
Co-locating `main.roc`, `test.roc`, stores, handlers, views, and their domain
types lets both application entry points use the exact same modules. The name
means "the platform-bound application layer"; it is not a locally implemented
Roc host platform. If a future subset becomes genuinely platform-independent
and reusable by another application, extract that subset into a package then,
rather than introducing a package boundary in anticipation.

### 3. Functional core, imperative shell

Functions that make decisions should be pure when possible. Functions that
perform I/O remain at the edge and use Roc's effectful `!` naming.

For example:

```roc
BigTask.Field.validate :
	BigTask.Field, Str
	-> Try(BigTask.Update, BigTask.ValidationError)
```

The validation function does not need HTTP or SQLite. A handler performs the
effects around it:

```text
read form!
    -> validate
    -> update adapter!
    -> render fragment
```

This division gives us fast, focused tests for rules while keeping the actual
request flow straightforward.

### 4. Explicit adapters and caller-local contracts

HTTP, SQLite, environment variables, time, and file contents are external
systems. Modules that talk to them convert between external representations and
our application types.

For example, `TodoStore` knows that a database stores a status as text.
Other modules work with `Todo.Status`.

When application logic should work with more than one implementation, Roc does
not require a trait, typeclass, inheritance hierarchy, or record of function
pointers. We use:

- a nominal adapter type that owns its state and associated methods; and
- a `where` clause on the caller that lists only the methods that caller needs.

For example, a SQLite adapter can carry its database connection:

```roc
TodoStore := { db : Sqlite.Db }.{
	insert! :
		TodoStore, Todo.New
		=> Try({}, TodoStore.Error)
}
```

A domain use case can validate and persist a Todo without importing
`TodoStore`:

```roc
Todo.create! :
	store, Str, Todo.Status
	=> Try({}, Todo.CreateError(err))
	where [
		store.insert! : store, Todo.New => Try({}, err),
	]
```

The `where` clause is a structural contract local to `Todo.create!`. It says
"the store type used here must have this method." There is no application-wide
`TodoStore` interface that every implementation must import or satisfy in full.
Another use case can ask for only `find!` or `list!`.

Production calls this function with `TodoStore`. The compiler selects the
concrete method from the adapter's type. Roc's static dispatch has no runtime
dispatch overhead; the compiled result is equivalent to a direct call.

A second nominal adapter can satisfy the same constraint, but that is not our
default unit-testing technique. Because `insert!` is effectful, a fake
`insert!` is effectful too and cannot be invoked by an ordinary pure `expect`.
Instead, keep validation and outcome interpretation pure:

```roc
Todo.complete_create :
	Try({}, err)
	-> Try({}, Todo.CreateError(err))
```

Inline expectations pass typed values such as `Ok({})` and
`Err(DatabaseUnavailable)` to this function. That simulates the possible
result of the effect without building another effectful application. One
platform test then invokes the real `TodoStore` against SQLite.

The nominal `Todo.CreateError(err)` wrapper is intentional. In the current Roc
compiler, closed error unions do not automatically widen across `?` or match
branches. The wrapper keeps validation failure distinct from
`StoreFailure(err)` without turning either into a string.

This technique is useful when:

- a reusable operation should not depend on its production infrastructure;
- an external system is likely to be replaced or supplemented;
- several adapters should support the same reusable operation; or
- keeping infrastructure imports out of application logic clarifies the
  dependency direction.

A concrete call is still simpler when there is no reusable operation or useful
substitution. We do not make every handler generic and do not create broad
"repository interfaces" containing operations a caller never uses.

#### Static dispatch is not runtime dispatch

Static dispatch can choose an implementation only from types known at compile
time. It does not replace ordinary data modelling or runtime decisions.

An incoming HTTP request is known only at runtime, so routing still uses a tag
union and exhaustive pattern matching. The same applies to user-selected
statuses, editable fields, and adapter choices read from runtime
configuration.

If a deployment can choose between databases at runtime, represent that choice
explicitly:

```roc
TodoStore := [
	Sqlite(SqliteTodoStore),
	InMemory(InMemoryTodoStore),
]
```

Code then matches on `TodoStore` and calls the selected adapter. If the adapter
is chosen when building the application and its type is known at compile time,
a generic function with a `where` constraint can use static dispatch instead.

#### Pure and effectful contracts remain distinct

Roc has no effect polymorphism: one function signature cannot mean "this method
may be pure or effectful." Pure functions use `->`; effectful functions use
`=>` and conventionally have names ending in `!`.

Persistence operations perform I/O, so their constraints should normally be
effectful:

```roc
store.find! : store, Todo.Id => Try(Todo, err)
```

Every adapter used through that contract must provide the effectful method the
caller requested. Keep validation and state transitions in separate pure
functions so tests can exercise most decisions without an effectful adapter.
Do not try to make one constraint abstract over both a pure `find` and an
effectful `find!`.

This leads to a useful rule: `where` constraints express reusable capabilities;
they are not a mocking framework. Test pure plans, validation, and typed effect
outcome mappings with `expect`. Test a concrete effect interpreter with the
smallest platform application that can actually run it.

## Typed routes, pages, and links

Routes are application data, not scattered strings. A route module should own:

- parsing an HTTP method and URL into a route;
- rendering typed locations and actions back into URLs;
- typed page identity and page metadata;
- static asset locations; and
- failures produced while parsing a request target.

A useful distinction is:

```roc
Route := [
	Visit(Location),
	Post(PostAction),
	Put(PutAction),
	Serve(Asset),
].{
	Page := [Home, Login, Register, Todos, Users, TodoTree, BigTasks]

	Location := [AtPage(Page), TodoList, BigTasks(BigTask.Query), BigTaskCsv]

	PostAction := [Login, Logout, CreateTodo, DeleteTodo(Todo.Id)]

	PutAction := [
		CompleteTodo(Todo.Id),
		UpdateBigTask(BigTask.Id, BigTask.Field),
	]

	Asset := [Styles, Htmx, Robots]
}
```

A `Location` can be visited with an ordinary link. An `Action` is submitted
using its declared HTTP method. Keeping these concepts distinct prevents an
endpoint that requires `POST` or `PUT` from accidentally being rendered as an
ordinary `GET` link.

HTML helpers should consume these types:

```roc
Web.link : location, List(Attribute.Attribute), List(Html.Node) -> Html.Node
	where [location.to_href : location -> Str]

Web.hx_post : action -> Attribute.Attribute
	where [action.to_post_url : action -> Str]

Web.hx_put : action -> Attribute.Attribute
	where [action.to_put_url : action -> Str]
```

This application's `Web` module stays reusable without importing the
application's `Route` type. Each helper states the one behaviour it needs:

```roc
Web.link :
	location,
	List(Attribute.Attribute),
	List(Html.Node)
	-> Html.Node
	where [
		location.to_href : location -> Str,
	]
```

`Route.Location` and any feature-specific location type can provide a
compatible `to_href` associated method. This keeps the helper typed without
making a shared web module depend on every application route. The same pattern
can work for redirects and form actions, provided each contract stays small.

The view then says what it means:

```roc
Web.link(Route.Page.Todos, [Design.navLink], [Html.text("Tasks")])
```

Only `Route` and the HTTP helper need to know that this is currently `/task`.
Changing the URL later does not require searching templates for matching string
literals.

Page identity should also be typed. A layout can accept a `Page` or
`Route.Location` and derive the title and navigation state from it, instead of
accepting unrelated title and URL strings.

Not every string should become a nominal type. User-entered descriptions,
display text, and error explanations are naturally strings. Types are most
valuable for identifiers, validated values, finite choices, and values that
would be dangerous to interchange.

## HTMX interaction architecture

HTMX enhances the application's HTML navigation and forms; it does not define
a second client-side application model. Each interaction must therefore start
with a semantic HTML control and a server-rendered representation of the
resulting application state.

Interaction policy belongs in typed helpers only after a feature establishes
the user intent it represents. Browser tests cover the relevant failure mode,
including concurrency, history, accessibility, or progressive enhancement as
applicable. This prevents convenient HTMX attributes from becoming implicit
application-wide behavior.

### Semantic controls remain the baseline

A navigable state uses an anchor with a typed `href`. HTMX may add a faster
request and bounded swap to that anchor, but disabling JavaScript, opening the
link in a new tab, or reloading its URL must still produce a useful full page.
Mutation controls use forms and buttons rather than pretending to be links.
Where HTML supports the method, the form also declares its native action and
method; methods such as `PUT` still require enhancement or a deliberate POST
fallback.

A full-page form presents one primary submit action and an adjacent secondary
Cancel link. Cancel is navigation, not a mutation: it uses a typed location and
returns to the record being edited or the collection that owns a new record.
This escape route must work without browser scripting and must not submit or
discard data through an action endpoint.

When a parent record launches a creation form, carry that origin separately
from editable relationship fields. Back and Cancel return to the validated
origin through validation and confirmation responses even if the member
changes the new record's relationships. Never infer navigation context from a
mutable selection.

Do not introduce a shared `hx_nav` helper that silently chooses a global target
and swap strategy. `Web` owns typed protocol primitives; the feature view
composes target, selection, and swap attributes beside the region whose
ownership it understands. Ordinary links do not need HTMX enhancement when a
full navigation already serves the task well.

### A swap target owns one coherent state

Target the smallest stable region that completely owns the state changed by an
interaction. A live search owns its results fragment. Sorting and pagination
jointly own the results collection and its navigation controls. Page chrome,
client-only state, focus, and unrelated regions are outside that ownership.

The server may still return the canonical full page. `hx-select` can select the
owned region from that response, avoiding a second partial-rendering branch
until measured response size or rendering cost justifies one.
This trades some response bytes for one representation and reliable direct
navigation.

### Meaningful state participates in browser history

If users may reasonably refresh, bookmark, share, or traverse back to a state,
that state belongs in the URL. Discrete sorting and pagination navigation push
their typed query URL. The stable results region is the history element so
history traversal restores that region without replacing unrelated document
state. A direct request for every pushed URL must return a complete page.

Ephemeral UI state does not create history entries merely because HTMX can do
so. Rapidly changing but meaningful filters use the canonical typed GET query
URL and replace the current URL rather than pushing one entry per keystroke.
The server reconstructs both controls and results from every represented URL.

### Concurrent requests express user intent

Debouncing controls request frequency but does not determine which in-flight
response is authoritative. Derived, read-only UI such as live search uses
`Web.hx_sync_latest`, which maps the user-facing rule "newest input wins" to
HTMX's `this:replace` synchronization. This prevents an older response from
replacing newer input under uneven latency.

Synchronization is a browser response policy, not a write-serialization
guarantee. An aborted request may already have committed. Autosave therefore
submits the rendered record version, and the store compares and increments that
version in one immediate transaction. A stale write returns `409 Conflict`
with the submitted value intact and the current version, so the user can review
and retry without silently overwriting another committed edit.

Do not apply latest-wins where every request matters. Give each synchronization
policy a name that states its intent, and back mutations with a server-side
invariant. Browser synchronization cannot provide exactly-once execution.

### Form fragments own validation and focus

When a form or field editor replaces itself, its response must contain the
submitted value, validation state, and accessible relationship between the
control and its message. Controls use stable IDs so HTMX can restore focus
after replacement. `aria-invalid` reflects the rendered validation state and
`aria-describedby` points to a stable `aria-live="polite"` message region.

Inline validation and autosave are latest-wins interactions: an older
validation response must not overwrite a newer value.

HTMX 4 swaps error responses by default, unlike HTMX 2. A validation response
may therefore use `422` only when its HTML is shaped for the declared target.
Unexpected server errors must not replace a local editor with a full-page
error representation.

Full-page forms use the same recovery principle at page scale. An invalid
submission re-renders every submitted value, places a stable focusable alert
before the form, and moves focus to that alert. Field-level messages use stable
IDs and `aria-describedby` only when the server can identify the field that
failed; a general error must not be falsely associated with one control.
Native constraint validation may complement this response but does not replace
server validation.

Use native constraints only for stable invariants the browser can express
accurately. Required controls show a visible cue as well as their semantic
attribute. Values that improve a record without being essential remain
optional; explanatory copy may state why they are useful, but the form must not
turn that guidance into an extra gate.

### Contextual mutations defend the action at three layers

A mutation initiated inside a record context keeps the member in that context.
Its native POST redirects to the typed containing location, while HTMX replaces
only the stable section that owns the changed state. The native destination is
the contract.

The submitting control exposes local request status. A named first-wins policy
may drop repeated browser submissions while one page request is pending, but it
does not make retries safe. Prefer idempotent state transitions such as
`open -> completed` guarded by `WHERE status = 'open'`. A non-idempotent
operation instead needs a client operation key that the server stores with its
result and replays for duplicate submissions.

HTMX 4 error responses have an explicit destination. Full error pages expose a
stable `Web.ErrorTarget.RequestError` summary; enhanced mutation forms use
`Web.hx_errors_to` to place expected `400`, `403`, `404`, `409`, `422`, `429`,
and `5xx` summaries in a dedicated local `aria-live` region. The normal
interaction state remains in place for correction or retry. Do not use one
blanket `4xx` policy: authentication, validation, conflict, missing context,
and rate limiting require different user recovery even when some share a
render target.

An expired session during an enhanced request must navigate the whole window to
the typed login location, never swap a login document into a local fragment.
The server detects `HX-Request: true` and returns `200` with `HX-Redirect`;
ordinary unauthorized requests remain `401`. Ordinary successful form
redirects remain `303 See Other`. HTMX response headers are emitted on a
successful response because error-status header processing is not a navigation
contract.

### Browser code closes only browser-owned gaps

Use a JavaScript event boundary only when neither semantic HTML nor an HTTP
response can represent the outcome. Connection loss and client-side timeout
meet that test. They create an uncertain outcome: lack of a response does not
prove the server failed to commit. An enhanced form opts in with
`Web.network_errors_to(target)`; `interactions.js` listens for HTMX 4's
`htmx:error` event and writes a persistent alert into that form's existing
local feedback region. Its copy tells the user to check current state before
retrying; the retry must be safe under the mutation's idempotency rule. A later
retry clears the transport alert before issuing the request. Server-rendered
success, validation, and operational error markup remain authoritative.

Do not generalize this boundary into a client state layer. In particular, we
reject global spinners and transient success/error toasts as the default:

- a global spinner cannot accurately communicate which of several concurrent
  requests is pending;
- fast local interactions should not make the whole application appear busy;
- disappearing toasts are poor primary feedback for consequential CRM actions;
  and
- server-rendered inline state survives long enough to inspect, associate with
  the initiating control, and test without JavaScript.

An optional toast may be reconsidered for a genuinely cross-page,
non-consequential notification, but it must not replace persistent inline
feedback.

### Removed controls need an explicit focus destination

When a successful local mutation removes the control that held keyboard focus,
the interaction restores orientation deliberately. The owning section exposes
a stable, programmatically focusable heading and the source opts into
`Web.focus_after_swap`.

This is not a global "focus every target" rule. Live-search input and inline
validation preserve focus through stable element IDs, while normal navigation
uses the browser's document behavior. Programmatic post-swap focus is reserved
for interactions that remove the active element and can name a nearby semantic
anchor. Error responses keep focus in place and announce their local alert
instead.

### Advanced techniques require product pressure

Availability in the library is not sufficient reason to adopt a technique.

| Technique | Default | Admission rule |
| --- | --- | --- |
| Semantic links and forms | Use | Every interaction starts with the native control and canonical typed URL that expresses its meaning. |
| Bounded swaps | Use | The target is the smallest stable region that owns the complete changed state. |
| Selecting from a canonical full page | Use until cost justifies a fragment | Prefer one representation and `hx-select` until measured response size or rendering cost justifies a dedicated fragment response. |
| History updates | Use selectively | Push discrete navigation; replace rapidly changing but meaningful filter state; do neither for ephemeral presentation state. |
| Request synchronization | Use named policies | Use latest-wins only for derived state and first-wins only for a guarded mutation. Every new strategy needs an adversarial concurrency test. |
| Local indicators and errors | Use | Feedback belongs beside the initiating interaction and must survive long enough to inspect. HTTP and transport failures have separate owners. |
| Focus management | Use selectively | Preserve stable focused controls; explicitly name a semantic destination only when a successful swap removes the active element. |
| Out-of-band swaps or multi-target partials | Defer | Admit only when one server transition changes two tightly coupled representations already visible on the same page. Prefer enlarging one coherent target first. |
| Polling, SSE, or WebSockets | Do not use by default | Use only for state that must change in an open page without member action, with a defined freshness target, stop condition, visibility behavior, and failure state. |
| Optimistic mutation | Do not use by default | Consequential CRM state remains server-authoritative. Use only for a reversible, high-frequency action with measured latency pain and a tested rollback experience. |
| Global request spinner | Rejected as a default | Concurrent local requests make one global busy state ambiguous. Use a local indicator where delay is perceptible. |
| Transient toasts | Rejected as primary feedback | Consequential outcomes and errors require persistent inline evidence. A toast may supplement a genuinely cross-page, non-consequential notice. |
| Client event bus or broad `HX-Trigger` use | Defer | Prefer response HTML. Admit an event only for browser-owned behavior or a truly decoupled consumer that cannot be represented by the response target. |
| Global boosting or a shared navigation macro | Do not use | Enhance individual typed controls only after their target, selection, history, and fallback behavior are explicit. |
| Infinite scrolling | Do not use for operational lists | CRM lists need knowable filters, counts, position, reload, and back behavior. Use typed, URL-addressable pagination unless observed usage proves otherwise. |
| Preserving arbitrary DOM islands | Defer | Choose a smaller target first. Use preservation only for a named rich widget whose state cannot be server-rendered, with lifecycle tests across swaps and history. |

Polling is especially inappropriate as a substitute for the work-list
requirements. Due and overdue work is visible when a member opens or refreshes
the CRM; timed external reminders are outside the minimal product. Likewise,
an eventual long-running import would need explicit progress and cancellation
requirements before any polling interval is chosen.

### Consequential actions use preview and confirmation states

Deletion, merge, import, export, bulk reassignment, stage retirement, and
archiving with open work are workflows, not button decorations. Each uses a
typed, navigable server-rendered preview that:

- states whether the action is reversible;
- names the records and exact dependent counts affected;
- presents any required choices before commitment;
- keeps the confirm action visually distinct from cancel; and
- remains usable without JavaScript.

Do not use `hx-confirm` or a native confirm dialog as the only barrier. A short
prompt cannot present the dependent records, reassignment decisions, merge
field choices, or privacy warning required by the CRM. HTMX may enhance the
preview form after the server-rendered flow exists, but cancelling, refreshing,
reloading, and submitting the canonical route must remain coherent.

### Empty states stay inside their owned representation

Every full page and selected region renders its own empty state. The state
keeps the section heading, explains the active scope or filter, and exposes the
nearest useful action or broadening control. It must not rely on a client hook
that runs only after a swap; direct requests, history restoration, and
JavaScript-disabled submissions need the same explanation.

### Interaction testing contract

Browser tests exercise the failure mode that each interaction policy exists to
prevent. Depending on the policy, this includes uneven latency, duplicate
activation, direct reload, history traversal, JavaScript-disabled submission,
HTTP or transport failure, validation association, and focus after replacement.
Tests assert the user-visible contract rather than merely checking for HTMX
attributes.

## Suggested module dependency direction

Roc intentionally disallows cyclic imports. We therefore design dependencies
as a directed graph:

```text
domain types
    |
    +----> feature routes ----> application Route
    |
    +----> concrete adapters
    |
    +----> use cases with caller-local contracts
    |
    +----> views <---- Layout / Design / Web
           \         |         /
            \        |        /
             v       v       v
                  handlers
                      |
                      v
                   main.roc
```

The practical rules are:

- Domain modules do not import handlers, views, repositories, or the global
  route.
- Concrete adapter modules may import their domain types.
- Generic use-case modules may import domain types and state the methods they
  require in `where` clauses, but do not import concrete adapters.
- Route modules may import domain types so routes can carry typed identifiers.
- Views may import domain types, route types, layout, and design modules.
- Handlers may import domain, use-case, concrete adapter, route, view, session,
  and web modules.
- `main.roc` is the composition root and may import all feature handlers.

An important example is that `Route` may carry a `Todo.Id`, but `Todo` must not
import `Route`. Reversing that dependency would create a cycle.

## Shared modules

Some concepts really are application-wide. They should have narrow,
well-defined responsibilities:

```text
main.roc       platform lifecycle and top-level dispatch
Route.roc      typed application routing
Web.roc        statically dispatched typed URL and HTML attributes
Http.roc       forms, cookies, response construction, and error responses
Layout.roc     shared document shell and navigation
Design.roc     typed visual variants and semantic styles
AppError.roc   application-level errors, if a shared closed type is useful
```

Avoid a general `Utils.roc`. A helper normally belongs to:

- the type whose values it operates on;
- the feature that uses it; or
- a specifically named shared concept such as `Pagination` or `Form`.

If a helper has only one caller, keeping it private in that caller's module is
usually clearest.

## Persistence adapter modules

A persistence adapter translates database representations into domain
representations. It owns:

- SQL;
- query parameters;
- row parser types;
- mapping database values into domain values; and
- persistence-specific errors.

It should not own:

- HTML;
- request cookies;
- URL parsing;
- page titles;
- redirects; or
- business rules that can be expressed without the database.

A concrete adapter should be a nominal type. It can carry the connection it
needs, and its associated methods should use domain types:

```roc
TodoStore := { db : Sqlite.Db }.{
	Error := [
		ConnectionFailed,
		InvalidRow(Str),
	]

	find! :
		TodoStore, Todo.Id
		=> Try(Todo, Error)

	insert! :
		TodoStore, Todo.New
		=> Try({}, Error)

	set_status! :
		TodoStore, Todo.Id, Todo.Status
		=> Try({}, Error)
}
```

Raw row records should normally remain private to the adapter. A handler can
call this concrete type directly, or pass it to a generic use case whose
`where` clause requests one or more of these methods.

Use Roc multiline strings for SQL that is logically multiline. Keeping clauses
and selected columns on separate source lines is easier to review and upgrade
than one long string:

```roc
query = (
	\\SELECT t.id, t.task, t.status
	\\FROM tasks AS t
	\\WHERE t.task LIKE :pattern
	\\ORDER BY t.id;
	,
)
```

Short one-clause statements can stay on one line. This is a readability rule,
not a requirement to make every SQL literal multiline.

Be explicit at serialization boundaries even when Roc accepts shorthand.
With the current SQLite package, `params: { pattern }` type-checks but is
encoded as a scalar at runtime. Write `params: { pattern: pattern }`.

> **TODO — nominal codec upgrade:** SQLite already uses compiler-derived
> `parser_for` for structural result records and `encoder_for` for structural
> parameter records. Revisit direct nominal row parsing and parameter encoding
> after compiler specialization is stable. With compiler
> `release-fast-f4b3c607`, exercising derived codecs on opaque nominal leaves
> caused monomorphization panics or segmentation faults; an explicit nominal
> encoder compiled but did not bind the expected runtime value. The intended
> end state is derived codecs for transparent scalar wrappers, custom
> string-backed codecs for statuses, and direct typed rows where doing so does
> not discard useful invalid-storage diagnostics.

## View modules

A view converts typed data into `Html.Node`. It does not query the database or
inspect raw requests.

Full-page and htmx-fragment renderers can live together when they belong to the
same feature:

```roc
TodoView.page : TodoView.PageModel -> Html.Node

TodoView.list_fragment : TodoView.ListModel -> Html.Node
```

Dedicated view models are useful when the screen needs data assembled from
several domain types or needs presentation state such as validation messages,
pagination, or selected controls.

Page hierarchy is stable across features. Each full page has exactly one `h1`.
A collection page puts its title and one page-level creation action before
search and comparable rows. A detail page presents the record's highest-value
summary before related collections and history. A form page states the action
in its `h1`, then presents guidance, validation, fields, and actions in that
order. Section-local actions remain visually and structurally scoped to their
`h2` section rather than competing with the page purpose.

Use tables for repeated records whose fields are compared across rows, with
the record identifier rendered as a real link. Use cards and description lists
for one record's summary. Do not make a whole table row imitate a link when an
ordinary identifier anchor provides clearer keyboard and browser behavior.

View models should remain typed:

```roc
TodoView.PageModel := {
	session : Session,
	todos : List(Todo),
	filter : Todo.Filter,
}
```

Views generate URLs through typed routing helpers. They should not contain raw
application paths or database representations.

Promote repeated semantic controls to shared view primitives only after at
least two feature views need the same contract. Such a primitive owns stable
label association, required-state semantics, and baseline styling. The feature
view still owns field-specific help, validation messages, request behavior, and
swap boundaries so reuse does not erase interaction intent.

Control IDs are stable and unique within the rendered document. A wire name is
not automatically a safe DOM identity: when the same input vocabulary appears
in repeated forms, the caller supplies a contextual ID while the primitive
preserves the server-facing name. Labels, focus restoration, and fragment
targets refer to that contextual identity.

Layouts are mobile-first. The document itself does not scroll horizontally at
the supported small viewport; actions wrap, controls fit their container, and
cards collapse into one column. Intrinsically wide data such as a table owns
its horizontal scrolling inside a labelled or otherwise understandable region
instead of widening the whole page.

## Handler modules

A handler coordinates a use case. It can:

- read already-routed request input;
- load the current session;
- check authorization;
- decode and validate a form;
- call repositories;
- apply domain operations;
- choose a full page or htmx fragment; and
- return a typed application error.

A handler should not contain large HTML trees or SQL strings. It should read
like a short description of the request:

```text
authorize
    -> validate input
    -> persist change
    -> reload display data
    -> render response
```

If this orchestration develops substantial branching independent of HTTP,
extract it into a use-case module such as `CreateTodo` or
`UpdateBigTaskField`. The use case can declare the smallest adapter behaviour it
needs with a caller-local `where` clause. The handler remains responsible for
choosing the concrete adapter and connecting the result to HTTP.

## Errors

Errors should retain useful types until the HTTP boundary.

Examples include:

```roc
Todo.ValidationError
TodoStore.Error
Route.ParseError
Session.AuthError
```

The outer web layer decides how these become status codes, redirects, logs, or
HTML validation messages. Inner modules should not turn every error into an
unstructured string merely to make their signatures uniform.

It is acceptable to have an application-level error union when one central
place handles all failures. Feature-specific errors can be converted into that
type by handlers.

Expected user errors and unexpected operational failures should remain
distinguishable. Invalid form input is not the same kind of problem as a
database connection failure.

## Application context

Long-lived resources are opened during application initialization and stored in
the application context:

```roc
Context := {
	sessionStore : SessionStore,
	userStore : UserStore,
	todoStore : TodoStore,
	bigTaskStore : BigTaskStore,
}
```

Add a context field when it represents an application-lifetime dependency, not
as a shortcut for passing arbitrary request state globally. A request-specific
session, parsed route, or form input should be passed explicitly.

## How to add a feature

Start with the smallest useful implementation:

1. Define its domain type and finite vocabulary.
2. Define typed locations and actions.
3. Add those routes to top-level parsing and dispatch.
4. Add persistence adapter operations using domain types.
5. Add typed page or fragment models.
6. Render links and actions through the route helpers.
7. Write a short handler that connects those pieces.
8. Extract a generic use case with a small `where` contract when infrastructure
   independence or focused substitution provides a concrete benefit.
9. Add pure tests for parsing, validation, and transformations.
10. Add integration coverage for important database and HTTP paths.

Do not create every possible abstraction up front. Split a module when doing so
creates a clearer API, hides implementation details, breaks up unrelated
reasons to change, or enables useful independent testing.

## How this makes upgrades easier

This structure localizes different kinds of change.

### Change a URL

Update its route parser and renderer. Typed links continue to compile without
template-wide string replacement.

### Add a status or editable field

Update the owning tag union. Exhaustive pattern matches identify every parser,
database conversion, view, and rule that must be considered.

### Change the database schema

Update the affected adapter and migration. Domain and view modules are
insulated from column names and row representations.

### Add a JSON API

Reuse domain and use-case modules. Add a JSON adapter alongside the HTML
handler rather than moving rules out of templates after the fact.

### Replace or supplement SQLite

Implement another nominal adapter with the associated methods required by the
existing use cases. Caller-local `where` clauses are already the contracts, so
there is no need to create one large shared repository interface.

If the application chooses the adapter at compile time, static dispatch selects
its methods directly. If it chooses at runtime, add an explicit adapter tag
union and match on it.

### Upgrade htmx or the webserver platform

Keep platform-specific request and response details concentrated in
`main.roc`, `Web.roc`, and small rendering helpers. Feature rules and
repository APIs should not need broad changes.

### Change the visual design

Update `Design` and shared layout components. Feature views should use semantic
styles and typed visual variants instead of assembling utility-class strings.

## Testing strategy

Tests should follow the same boundaries:

- Domain modules use inline `expect` statements for validation, state
  transitions, sorting, parsing, and typed simulations of effect outcomes.
- Route tests verify that parsing and rendering agree.
- View tests cover meaningful full-page and htmx-fragment output.
- Handler decision functions accept typed success or failure values, allowing
  inline tests to cover authorization, status codes, redirects, cookies, and
  validation responses without performing I/O.
- `src/test.roc` is the single effectful test application. It embeds the
  canonical `db/init.sql` and `db/test-fixtures.sql`, creates an isolated
  temporary SQLite database, invokes
  the real stores, and exits. It uses `basic-webserver`, not `basic-cli`,
  because the two platforms currently expose different SQLite APIs and the
  production stores use `basic-webserver`'s pooled `Sqlite.Db`.

Prefer testing typed behaviour over incidental implementation details. For
example, test that every `Todo.Status` round-trips through its database
representation rather than testing a private helper function.

Do not create a separate Roc application for every unit-test group. A separate
app is justified only when the code must execute hosted effects. Run the two
layers with:

```text
roc test src/main.roc
roc src/test.roc
```

## Patterns to avoid

### Application-wide grab bags

Modules named `Models`, `Pages`, `Db`, or `Utils` tend to accumulate unrelated
features. Prefer domain and feature names.

### Raw application paths in views

Strings such as `"/task"` and `"/bigTask"` belong in routing code. Views use
typed link and action helpers.

### Primitive obsession

Do not pass arbitrary `Str` or `I64` values when a distinct validated concept
would prevent realistic mistakes.

At the same time, do not wrap every piece of display text merely to maximize
the type count. Types should encode meaning or invariants.

### Parsing the same value repeatedly

Decode an identifier, status, route, query parameter, or form field at the
boundary. Pass the typed result inward.

### Import cycles

If two modules want to import each other, reconsider which one owns the shared
type or operation. A lower-level domain module should not know about its HTTP
handler or HTML view.

### Premature generic abstractions

Two pieces of code that look similar may change for different reasons. Keep
them feature-local until a stable shared concept becomes clear.

A small `where` constraint is appropriate when a caller genuinely needs a
behaviour independent of its implementation. A broad interface-like contract,
generic handler, or adapter wrapper with no independent caller is still
premature.

### Thin forwarding modules

A module that merely renames another function without hiding details, enforcing
a type boundary, or creating a useful seam adds navigation cost without adding
architecture.

## CRM vertical slices

Product-facing slices follow the same request path:

| Slice | Domain | Persistence | HTTP and presentation |
| --- | --- | --- | --- |
| Actor/workspace | `Member`, `Session`, `Actor`, `Workspace` | `MemberStore`, `SessionStore`, `WorkspaceStore` | authentication handlers and the composition root |
| Companies | `Company` | `CompanyStore` | `CompanyHandler`, `CompanyView` |
| People | `Person` | `PersonStore` | `PersonHandler`, `PersonView` |
| Follow-up work | `WorkTask` | `WorkTaskStore` | `WorkTaskHandler`, `WorkTaskView` |

`db/init.sql` is the canonical development and test schema. The platform
integration runner loads it into a fresh database, then adds
`db/test-fixtures.sql`. Schema evolution needs an explicit migration policy
before persistent production databases are supported.

The actor boundary resolves a session to one active workspace member. Stores
receive the workspace and actor identifiers required for each mutation rather
than consulting global request state. Company and person creation perform
duplicate review before commitment. Company edits compare the submitted record
version inside an immediate transaction and return the current record on a
conflict. Person edits expose the same conflict outcome at the HTTP boundary.

Follow-up due values are captured as workspace-local date-times and stored with
their UTC instant. The runtime `TZ` must equal the workspace timezone; the
development and integration commands pin that value explicitly. Work buckets
are therefore evaluated against the workspace-local date rather than an
implicit server locale.

Tailwind class strings are centralized in `Design.roc`. CRM views use semantic
design attributes only, keeping visual policy out of feature rendering.

## Toolchain constraints

The architecture accommodates these toolchain constraints:

- contributors must learn type modules, nested opaque values, typed routing,
  static dispatch, and the domain/store/view/handler request path;
- the clearer ownership comes with more modules and annotations;
- scalar nominal construction uses `Id.(value)`, which may be unfamiliar;
- closed error unions do not widen automatically through `?` or match
  branches, so generic effectful use cases may need a nominal error wrapper;
- an effectful fake adapter must mirror the production method's purity because
  Roc has no effect polymorphism, so pure typed-outcome simulation is usually
  simpler;
- `basic-cli` and `basic-webserver` currently expose different SQLite APIs, so
  the store integration runner must use the production platform;
- SQLite record shorthand for parameters type-checks but fails at runtime, so
  adapter smoke tests remain necessary.

## Decision summary

The application is organized primarily by feature, supported by type-centred
domain modules. MVC remains a useful description of repository, handler, and
view responsibilities within a feature, but it is not the top-level directory
structure.

The enduring rules are:

- represent closed choices and validated values with types;
- parse external strings once at the boundary;
- use typed routes for navigation and actions;
- keep domain decisions pure where practical;
- isolate HTTP, SQLite, and other effects in nominal adapters;
- express reusable behaviour with small caller-local `where` constraints;
- use static dispatch only when the concrete type is known at compile time;
- use tag unions and pattern matching for runtime choices;
- keep pure and effectful contracts distinct;
- make dependencies point toward domain types;
- keep `main.roc` focused on lifecycle and dispatch; and
- introduce abstractions in response to real pressure.

Following these rules matters more than achieving a particular file layout.
