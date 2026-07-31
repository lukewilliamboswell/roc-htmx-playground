# Opportunity-qualification slice

> Proposed delivery slice. This is target-state planning, not evidence of
> implemented behavior. The authoritative as-built baseline is the SysML model
> under [`../model/`](../model/).

Document class: Delivery slice

Sequence: 2

This document proposes a future CRM implementation slice. Its starting
assumptions are defined by the implemented `CRM-###` requirements in the
[as-built model](../model/02-requirements.sysml): a person or company already
exists, its likely duplicates have been reviewed, and accountable follow-up
work can already be scheduled.

The full product contract remains in
[`00-full-design-minimal-crm.md`](00-full-design-minimal-crm.md), and the
portable data contract remains in
[`01-full-design-json-interchange.md`](01-full-design-json-interchange.md).

## Why this slice is next

The first slice answers "who is this, and what should we do next?" The next
smallest useful product outcome is to decide that an enquiry represents a
specific sales opportunity and make that opportunity visible to the team.

This slice therefore completes Workflow B, **Qualify an opportunity**, and the
open-deal part of Workflow D, **Progress and close a deal**. It deliberately
stops before closing a deal. Closing introduces loss reasons, settled-field
rules, reopening, closed-deal discovery, and historical reporting as one
separate set of decisions.

## Outcome

An active workspace member can:

1. open an existing person or company and create a distinct open deal for that
   customer party without replacing or duplicating the relationship record;
2. create the deal from a title alone, with the CRM defaulting its owner to the
   acting member and its stage to the first active pipeline stage;
3. maintain its owner, active stage, optional value, optional expected close
   date, optional source, description, and relevant contact people;
4. review a deal together with its customer party, relevant people, open tasks,
   current next action, and recorded owner and stage history;
5. schedule a task linked directly to the deal and find it immediately in the
   assignee's overdue, due-today, or upcoming work;
6. see every open deal in a shared pipeline grouped by the workspace's ordered
   active stages; and
7. distinguish in that pipeline between a deal whose next action is overdue,
   due today, upcoming, or missing.

A deal edit or stage move uses an optimistic version. A stale change presents
the submitted and current values and can be reapplied; it never silently
replaces a colleague's newer change.

## Product boundary

### Deal creation starts from a relationship

A member creates a deal from a person or company detail page. There is no
standalone customer-party picker in this slice. This keeps qualification tied
to a relationship the member has already reviewed and preserves the first
slice's duplicate-checking workflow.

The customer party is fixed after creation. Correcting an incorrectly selected
party and merging duplicate parties remain later data-quality work.

For a company deal, the member may select zero or more people currently
associated with that company as relevant contacts. Those links remain on the
deal if a person later changes company, because changing a person's current
company must not rewrite existing deal context. An individual deal does not
need to repeat its customer person as a relevant contact.

### Open deals only

Every deal created in this slice has status `open` and exactly one active
pipeline stage. The workspace is seeded with the validated default stages:

1. New opportunity
2. Discovery
3. Proposal
4. Negotiation

The application reads stage order and names from workspace data; they are not
hard-coded into deal or view logic. Members cannot add, rename, reorder, or
retire stages yet.

A stage move records the acting member, time, previous stage, and new stage in
the same transaction as the deal update. Moving a deal does not complete a
task, create a task, or imply that customer contact occurred.

### Commercial details remain optional

Only the title and customer party are required from the member. Owner and stage
have visible defaults and can be changed before creation.

Unknown value is distinct from a value of zero. A supplied value must be a
non-negative amount in the workspace currency. A supplied expected close date
must be a valid calendar date; it does not acquire a time of day.

### A next action is a direct deal task

The next action is the earliest open task linked directly to the deal,
regardless of its assignee. A task linked only to the customer person or
company is relationship work, but is not the deal's next action.

The next-action state is evaluated in the workspace timezone using the same
overdue, due-today, and upcoming rules as the existing work list. When no open
task is linked directly to the deal, the state is `No next action`.

Completing a deal task removes it from next-action consideration and exposes
the next earliest open deal task, or `No next action` when none remains.
Recording a completion outcome and creating the next task as one workflow
remain outside this slice.

### The pipeline is an operational view

The default pipeline contains every open, unarchived deal exactly once, grouped
under its active stage in stage order. Each deal entry shows:

- title and customer party;
- owner;
- known value in the workspace currency, or `Value unknown`;
- expected close date when known; and
- next-action state, expressed in text rather than colour alone.

Each group has an explicit empty state. A member can open a deal and move it to
another active stage without requiring pointer-based drag and drop. Pipeline
totals, filters, sorting controls, and management reporting remain later work.

## Requirement coverage

| Requirement | Coverage in this slice |
|---|---|
| CRM-003, CRM-004, CRM-006 | Person and company views reveal their active deals; deal links survive later changes to a person's current company |
| CRM-009, CRM-010 | Open deal capture for person and company customer parties, including optional commercial context and company contacts |
| CRM-011 | Shared open pipeline grouped by ordered active stage |
| CRM-013 | Transactional stage changes with an attributable, unbroken history |
| CRM-014, CRM-023 | Owner, optional value and close date, and overdue/today/upcoming/missing next-action state on each pipeline entry |
| CRM-019, CRM-022, CRM-024, CRM-046 | Direct deal tasks appear immediately in the existing workspace-timezone work buckets |
| CRM-029, CRM-030 | Individual deal ownership, authorship, last-change attribution, and owner/stage history; bulk reassignment remains later |
| CRM-031, CRM-044 | Every CRM request requires an active member and gives every active member the same deal access |
| CRM-047 | Optimistic conflict detection and recoverable reapplication for deal edits and stage moves |

This table describes only the portion of each requirement accepted by this
slice. It does not claim completion of requirement clauses explicitly left
below.

## Acceptance journeys

### Qualify a company enquiry

1. Open an existing company with two associated people.
2. Choose **Create deal**.
3. Enter a title, select one relevant person, and leave value and expected
   close date unknown.
4. Create the deal.
5. See it on the company, on the selected person's linked context, on its own
   detail page, and in **New opportunity** in the pipeline.
6. See `No next action` until a task is scheduled directly against the deal.

### Qualify an individual enquiry

1. Open an existing person who has no company.
2. Create a deal with a known value and expected close date.
3. See the person as the customer party without an invented company or a
   duplicate person record.
4. See the known value and expected close date on both the deal and pipeline.

### Put the opportunity into accountable work

1. Schedule a direct deal task for another active member.
2. See it immediately on the deal and in that member's appropriate work-list
   bucket.
3. See the same due state on the pipeline entry.
4. Complete the task.
5. See the pipeline expose the next direct open task, or `No next action`.

### Progress without losing history

1. Open the same deal in two sessions at the same version.
2. Move it from **New opportunity** to **Discovery** in one session.
3. Attempt a conflicting edit or stage move in the other session.
4. See both the submitted and current values, who made the newer change, and an
   option to reapply deliberately.
5. After resolution, see each successful owner or stage change once, in order,
   with its actor and time.

## Verification layers

| Layer | What it catches |
|---|---|
| Domain tests in `src/*.roc` | Deal validation, optional money/date semantics, permitted open-state transitions, and next-action selection |
| Fresh-SQL integration tests in `src/test.roc` | Deal, contact, activity, and task transactions; stage ordering; workspace scoping; optimistic conflicts; and rendered pipeline/detail HTML |
| `ci/check_source_contracts.sh` | Existing architectural rules, including keeping Tailwind classes inside `src/Design.roc` |
| `tests/crm.spec.js` | The four acceptance journeys above using roles, labels, links, and visible status text |

Tests must include two workspaces or explicit wrong-workspace identifiers at
the store seam so a deal, contact, stage, or task cannot be attached across a
workspace boundary. They must also distinguish unknown value from zero and a
relationship-only task from a direct deal task.

## Outside this slice

- Winning, losing, and reopening deals.
- Loss-reason data and configuration.
- Adding, renaming, reordering, or retiring pipeline stages.
- Manual notes, calls, emails, meetings, completion outcomes, and combined
  complete-and-schedule-next workflows.
- Closed-deal search, archived records, global cross-record search, pipeline
  filters, and list sorting.
- Pipeline totals, forecasts, owner summaries, outcome reports, and other
  reporting.
- Bulk reassignment and ending a member's access while they own open work.
- Import, export, merge, deletion, and privacy workflows.
- Drag-and-drop as a required interaction.
- Automatic lifecycle changes when a deal is created or moved. Lifecycle and
  pipeline stage remain separate concepts.

## Temporary compatibility boundaries

- Development and production share the trusted identity/member lookup; the
  development proxy selects which fixture member it injects.
- Existing database files are disposable unless development is started with
  `--keep-db`; versioned migrations are the schema authority.
- Existing person and company task URLs remain valid. Adding deal tasks must
  extend the task model without changing the meaning of those links.
- Legacy playground authentication and demo routes have been removed.

## Green change rule

Each implementation commit must pass:

```sh
roc scripts/tasks.roc check
roc scripts/tasks.roc test-e2e
```

Schema-changing commits also recreate the disposable development database
before manual verification. No commit may depend on an uncommitted schema or
fixture change.
