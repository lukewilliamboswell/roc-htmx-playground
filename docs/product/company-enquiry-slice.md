# Company-enquiry slice

This document fixes the acceptance boundary for the first CRM implementation
slice. The full product contract remains in
[`minimal-crm-requirements.md`](minimal-crm-requirements.md), and the portable
data contract remains in
[`simple-crm-json-format.md`](simple-crm-json-format.md).

## Outcome

An active workspace member can:

1. search for a company and review likely duplicate records;
2. create a distinct company from its name alone;
3. maintain its owner, lifecycle status, source, website, phone, and context;
4. create a full person record, either independently or associated with the
   company;
5. maintain multiple labelled emails and phone numbers, with at most one
   primary value of each kind;
6. schedule a company- or person-related task for an active member at a date
   and time in the workspace timezone; and
7. find that task under overdue, due today, or upcoming work.

Company and person edits use optimistic versions. A stale edit presents the
submitted and current values and can be reapplied; it never silently replaces
the newer change.

## Requirement coverage

| Requirement | Coverage in this slice |
|---|---|
| CRM-001–005 | Person and company capture, association, ownership, lifecycle, and contact details |
| CRM-006 | Record details, associated people, open tasks, and recorded owner/status history; deals and manual interactions remain later |
| CRM-007 | Ranked duplicate preview for company and person creation |
| CRM-019 | Creation and immediate visibility of related, assigned follow-up tasks |
| CRM-022, CRM-024, CRM-046 | Workspace-timezone work buckets for every open assigned task |
| CRM-029, CRM-030 | Individual ownership, authorship, last-change attribution, and owner/status history; bulk reassignment remains later |
| CRM-031 | Every active member has the same CRM access |
| CRM-044 | Active membership is checked on every CRM request |
| CRM-047 | Optimistic conflict detection and recoverable reapplication |

## Verification layers

The acceptance contract is enforced at several seams:

| Layer | What it catches |
|---|---|
| Domain tests in `src/*.roc` | Normalization, validated values, status decisions, and other pure rules |
| Fresh-SQL integration tests in `src/test.roc` | Store transactions, constraints, handlers, and rendered HTML, in both development and optimized compiler modes |
| `ci/check_source_contracts.sh` | Architectural rules that are otherwise stringly, including keeping Tailwind classes inside `src/Design.roc` |
| `tests/crm.spec.js` | Browser journeys for display-name preservation and search (CRM-003, CRM-025), duplicate review (CRM-007), primary contact maintenance (CRM-002), and visible task responsibility (CRM-019) |

The browser suite uses roles, labels, and visible text rather than screenshots.
That makes it sensitive to missing affordances and misleading copy while
avoiding image-baseline churn for this server-rendered UI.

## Temporary compatibility boundaries

- The existing application-managed login remains the request identity adapter
  for this slice. It is not the final surrounding-environment identity model.
- Existing database files and demo rows are disposable. The checked-in SQL
  initialization file is the only schema authority during this refactor.
- Todo, Tree, and BigTask remain temporarily reachable by their existing URLs
  after the CRM becomes the default navigation. They are not CRM concepts and
  will be removed by later slices.
- Deals, task completion, configurable settings, import/export, archiving,
  deletion, merging, privacy workflows, and reporting are outside this slice.

## Green change rule

Each implementation commit must pass:

```sh
roc scripts/tasks.roc check
roc scripts/tasks.roc test-e2e
```

Schema-changing commits also recreate the disposable development database
before manual verification. No commit may depend on an uncommitted schema or
fixture change.
