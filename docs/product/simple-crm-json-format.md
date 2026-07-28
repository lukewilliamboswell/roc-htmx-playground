# Simple CRM JSON Interchange Format

Status: Draft version 1  
Purpose: Complete export, backup, restoration, and migration of the minimal CRM

## 1. Design goals

The format should be:

- Understandable by a person reading the file.
- Complete enough to move a workspace without losing relationships or history.
- Small enough to produce from a spreadsheet, script, or another CRM export.
- Safe to preview and validate before creating CRM records.
- Usable for both business customers and individual customers.
- Stable across small product changes through an explicit format version.

Atomic CRM demonstrates the useful core idea: one JSON file can carry users, contacts,
companies, tasks, notes, and deals together. This format keeps that approach while adding
explicit versioning, configuration, customer-party relationships, and activity links.

A file always describes **one complete workspace**. There is no partial file, and importing
never merges into records that already exist. This is what keeps the format simple: a file
is a whole workspace, and importing one means creating that workspace from scratch.

## 2. File shape

A file contains one JSON object with these top-level members:

| Member | Required | Purpose |
|---|---|---|
| `format` | Yes | Always `simple-crm`. |
| `version` | Yes | Integer format version. This document defines version `1`. |
| `exported_at` | Yes | When the file was produced. |
| `workspace` | Yes | Workspace identity, name, currency, timezone, and configurable choices. |
| `users` | Yes | Workspace members referenced as owners, assignees, and authors. |
| `companies` | Yes | Business customer and prospect records. May be an empty array. |
| `people` | Yes | Individual contacts and customers. May be an empty array. |
| `deals` | Yes | Open, won, and lost sales opportunities. May be an empty array. |
| `activities` | Yes | Historical notes, calls, emails, meetings, and recorded changes. May be an empty array. |
| `tasks` | Yes | Planned, completed, and cancelled follow-ups. May be an empty array. |

Empty collections are represented by `[]`, not omitted. Optional properties within a
record are omitted when unknown.

There is no `scope` member. Every valid file is a complete workspace.

## 3. Shared conventions

- IDs are non-empty, stable strings and unique within their collection.
- References use those IDs. Every reference must point to a record present in the same file.
- A production workspace should not derive identifiers from a person's or company's name, email address, or any other personal information, because identifiers appear in places that outlive the record. The example file uses readable identifiers for legibility only.
- Timestamps use RFC 3339 with a timezone, such as `2026-07-28T09:30:00+10:00`.
- Date-only values use `YYYY-MM-DD`.
- Money is a JSON number in the workspace currency. It is not a formatted string.
- Enumerated values use stable lowercase identifiers such as `inbound` or `poor-fit`.
- Display names may change without changing IDs.
- Unknown optional values are omitted rather than represented by an empty string.
- Archived records include `archived_at`; active records omit it.
- Record authorship uses `created_by_id` and `updated_by_id`.
- A complete export includes archived records and historical activities. Deleted records do not appear in any form: deletion in the CRM is permanent, so there is no recoverable or pending-deletion state for the format to represent.

## 4. Workspace configuration

`workspace` has this shape:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable source-workspace identifier, retained so a restored workspace can be traced to its origin. |
| `name` | Yes | Human-readable workspace name. |
| `currency` | Yes | Three-letter currency code, such as `AUD`. |
| `timezone` | Yes | IANA timezone name, such as `Australia/Melbourne`, in which due, overdue, and day-grouped views are evaluated. |
| `pipeline_stages` | Yes | Ordered open-deal stages. |
| `loss_reasons` | Yes | Choices presented when a deal is lost. |
| `sources` | Yes | Choices describing how a relationship began. |
| `task_types` | Yes | Choices describing the intended follow-up. |

Each configurable choice has:

- `id`: stable identifier used by records.
- `name`: current user-facing label.
- `position`: integer display order.
- `active`: whether members may select it for new changes.

Retired choices remain in the configuration with `active: false` while existing records
still reference them. A retired stage never has open deals referencing it, because the CRM
requires those deals to be moved before the stage can be retired.

## 5. Users

Each user contains:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable user identifier. |
| `name` | Yes | Display name. |
| `email` | Yes | User's email address. |
| `active` | Yes | Whether the user currently has workspace access. |

All active users have the same CRM privileges in version 1. A file carries each user's
`active` value unchanged, so a workspace restored from a backup has the same active members
it had when the file was produced. Inactive users are retained because records reference
them as owners and authors; an inactive user never owns an open deal or an open task.

## 6. Companies

Each company contains:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable company identifier. |
| `name` | Yes | Company name. |
| `owner_id` | Yes | User accountable for the relationship. |
| `lifecycle_status` | Yes | `lead`, `prospect`, `customer`, or `inactive`. |
| `website` | No | Company website. |
| `phone` | No | Main company phone number. |
| `source_id` | No | Reference to a workspace source choice. |
| `context` | No | Free-form relationship background. |
| `created_by_id` | Yes | User who created the record. |
| `updated_by_id` | Yes | User who most recently changed the record. |
| `created_at` | Yes | Creation timestamp. |
| `updated_at` | Yes | Most recent update timestamp. |
| `archived_at` | No | Archive timestamp. |

`owner_id`, `lifecycle_status`, authorship, and timestamps are always present because the
CRM supplies them when the record is created. A member creating a company supplies only its
name; the CRM defaults the owner to that member and the lifecycle status to `lead`.

## 7. People

Each person contains:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable person identifier. |
| `name` | Yes | The best currently known display name. |
| `owner_id` | Yes | User accountable for the relationship. |
| `lifecycle_status` | Yes | `lead`, `prospect`, `customer`, or `inactive`. |
| `emails` | No | Email addresses with labels and an optional primary marker. |
| `phones` | No | Phone numbers with labels and an optional primary marker. |
| `job_title` | No | Role or title. |
| `company_id` | No | The person's current associated company. |
| `source_id` | No | Reference to a workspace source choice. |
| `context` | No | Free-form relationship background. |
| `created_by_id` | Yes | User who created the record. |
| `updated_by_id` | Yes | User who most recently changed the record. |
| `created_at` | Yes | Creation timestamp. |
| `updated_at` | Yes | Most recent update timestamp. |
| `archived_at` | No | Archive timestamp. |

An email entry contains `value`, an optional `label`, and an optional boolean `primary`.
A phone entry uses the same shape. At most one email and one phone should be marked
primary. The same email address or phone number may appear on more than one person; the
format does not treat either as a unique key.

As with companies, the required properties beyond `name` are supplied by the CRM, so a
person captured from a name alone still produces a complete record.

`company_id` records the person's current association only. The format carries no history
of previous employers; activities, tasks, and deals stay attached to whichever records they
were logged against.

## 8. Deals

Each deal contains:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable deal identifier. |
| `title` | Yes | Human-readable opportunity title. |
| `customer` | Yes | The person or company that would buy. |
| `contact_person_ids` | Yes | People involved in the sale. May be an empty array on any deal. |
| `owner_id` | Yes | User accountable for the deal. |
| `status` | Yes | `open`, `won`, or `lost`. |
| `stage_id` | Yes | Current stage for an open deal; the stage it occupied at close for a closed deal. |
| `value` | No | Known deal value in the workspace currency. |
| `expected_close_on` | No | Expected close date. |
| `source_id` | No | Reference to a workspace source choice. |
| `description` | No | Opportunity context. |
| `closed_at` | Required when `status` is `won` or `lost`; must be absent when `open` | When the outcome was recorded. |
| `loss_reason_id` | Required when `status` is `lost`; must be absent otherwise | Configured reason for loss. |
| `loss_context` | No | Additional explanation, especially when reason is `other`. |
| `created_by_id` | Yes | User who created the record. |
| `updated_by_id` | Yes | User who most recently changed the record. |
| `created_at` | Yes | Creation timestamp. |
| `updated_at` | Yes | Most recent update timestamp. |
| `archived_at` | No | Archive timestamp. |

`customer` contains exactly two properties:

```json
{ "type": "person", "id": "person-jordan" }
```

or:

```json
{ "type": "company", "id": "company-acme" }
```

For a business deal, `contact_person_ids` identifies the people involved. For an
individual deal, the customer person need not be repeated in `contact_person_ids`.

A reopened deal is simply an open deal again: `status` returns to `open`, and `closed_at`
and `loss_reason_id` are absent. The record of its earlier outcome survives as a
`status-change` activity, which is what allows a past period's won and lost report to
remain accurate.

## 9. Activities

Each activity contains:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable activity identifier. |
| `type` | Yes | A customer interaction or material record-change type. |
| `occurred_at` | Yes | When the interaction happened. |
| `created_by_id` | Yes | User who recorded the activity. |
| `related_to` | Yes | One or more linked people, companies, or deals. |
| `subject` | No | Short summary. |
| `details` | No | Free-form content. |
| `outcome` | No | Result of the interaction. |
| `change` | Required for a change event | Structured record of what changed. |
| `merge` | Required for a merge event | Structured record of what was combined. |
| `created_at` | Yes | When the activity was recorded. |

Each `related_to` entry contains `type` (`person`, `company`, or `deal`) and the
corresponding record `id`. An activity belongs to every record it names, so a call can
appear in a person's, a company's, and a deal's history at once.

Customer-interaction types are `note`, `call`, `email`, and `meeting`. Material
record-change types are `owner-change`, `stage-change`, `status-change`, and `merge`.

A conforming export **must** include a change activity for every owner change, stage
change, and status change, including closing and reopening a deal. These activities are the
only record of how a deal reached its current position, so omitting them loses history the
CRM is required to show.

A change event uses:

```json
{
  "field": "stage_id",
  "from": "discovery",
  "to": "proposal"
}
```

`from` may be omitted when no earlier value existed. A stage change records the stage the
deal was actually in at that moment, so a deal's stage history forms an unbroken chain.

A merge event uses a structured `merge` payload rather than free text, so that a merged
record can be explained afterwards:

```json
{
  "surviving_id": "person-sam",
  "merged_ids": ["person-samuel"],
  "retained_from": {
    "name": "person-sam",
    "owner_id": "person-samuel",
    "lifecycle_status": "person-sam"
  }
}
```

`retained_from` names, for each single-valued field that differed, the source record whose
value was kept.

## 10. Tasks

Each task contains:

| Property | Required | Meaning |
|---|---|---|
| `id` | Yes | Stable task identifier. |
| `subject` | Yes | What needs to be done. |
| `type_id` | No | Reference to a workspace task type. |
| `status` | Yes | `open`, `completed`, or `cancelled`. |
| `due_at` | Yes | Due timestamp, bucketed into overdue, due today, or upcoming using the workspace timezone. |
| `assigned_to_id` | Yes | User responsible for the task. |
| `related_to` | Yes | One or more linked people, companies, or deals. |
| `details` | No | Additional instructions or context. |
| `outcome` | No | Result recorded when the task was completed. |
| `completed_at` | Required when `status` is `completed` | Completion timestamp. |
| `created_by_id` | Yes | User who created the task. |
| `updated_by_id` | Yes | User who most recently changed the task. |
| `created_at` | Yes | Creation timestamp. |
| `updated_at` | Yes | Most recent update timestamp. |

There is no reminder property. Tasks appear in their assignee's work views without any
per-task configuration, and notifications delivered outside the CRM are out of scope.

A task's `related_to` links determine which records it appears under. A task counts as a
deal's next action only when it links to that deal directly.

## 11. Import behaviour

Importing means creating a workspace from a file. The user-facing import workflow must:

1. Accept the file only when the destination workspace contains no companies, people, deals, activities, or tasks. Importing into a workspace that already holds records is refused, with an explanation.
2. Validate the entire file before creating anything.
3. Reject an unsupported `format` or `version`.
4. Report invalid values, duplicate IDs, references that point to records not present in the file, and inconsistent states such as a lost deal without a loss reason, an open deal carrying `closed_at`, an open deal or task owned by an inactive user, or an open deal referencing a retired stage.
5. Preview the counts of records that will be created, and list everything rejected with the reason.
6. Adopt the file's identifiers, configuration, currency, and timezone as the new workspace's own. Because the destination is empty, no matching, deduplication, or conflict resolution is required or performed.
7. Create users with the `active` value the file carries.
8. Commit the accepted import as one operation, so a failure cannot leave a half-created workspace.
9. Produce a results summary the member can review afterwards, and record the import in the workspace's record of consequential actions.

Nothing in this workflow updates, merges, or deletes an existing record, because there are
never any existing records to act on. A file that describes a workspace the organisation
already has is imported by creating a new empty workspace for it.

## 12. Export behaviour

An export must:

1. Include all workspace configuration, active and inactive users, active and archived records, activities, and tasks.
2. Preserve stable IDs and relationships.
3. Be accepted by the import workflow, into an empty workspace, without manual restructuring.
4. Clearly state the export time.
5. State, before the file is produced, how many records it will contain and that it holds personal information which is outside the CRM's control once downloaded.
6. Be recorded in the workspace's record of consequential actions, with who produced it and when.

There is no selected-record export. Every export is the complete workspace, which is what
makes a restored file trustworthy: it cannot be missing a reference, and it cannot
accidentally include one individual's information inside another's.

## 13. Round trip

Exporting a workspace and importing that file into an empty workspace must reproduce the
original workspace: the same configuration, currency, timezone, members and their active
state, records, archived state, relationships, activity history including recorded changes,
and tasks.

The following are deliberately not carried, and are lost by a round trip:

- Which member is currently viewing or editing anything.
- The workspace's record of consequential actions under CRM-049, which describes the source workspace's history rather than its data.

Everything else the CRM shows a member is represented here.

## 14. Complete example

See [simple-crm-example.json](./simple-crm-example.json) for a valid, compact example
containing:

- A business customer with a company contact and company deal.
- An individual customer with no company and an individual deal.
- A historical call and a recorded stage change.
- An open follow-up task.

## Research references

- [Atomic CRM — single-file JSON migration](https://marmelab.com/atomic-crm/doc/users/import-data/)
- [Twenty — data migration, identifiers, relations, and preview](https://docs.twenty.com/user-guide/data-migration/overview)
- [HubSpot — contact creation and email-based duplicate handling](https://knowledge.hubspot.com/records/create-contacts)
