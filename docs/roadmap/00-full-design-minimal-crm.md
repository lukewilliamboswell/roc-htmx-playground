# Minimal CRM — Product Requirements

> Target-state roadmap. This document describes intended product scope, not
> implemented behavior. The authoritative as-built baseline is the SysML model
> under [`../model/`](../model/).

Document class: Enduring product design

Status: Draft for validation  
Research date: 28 July 2026

## 1. Purpose

The product gives a small team one dependable place to remember who its prospects and customers are, understand the history of each relationship, track active sales opportunities, and know what to do next.

The CRM succeeds when it replaces scattered spreadsheets, personal notes, and memory without introducing enterprise-level process overhead.

## 2. Scope assumptions

These requirements assume:

- One small organisation with roughly 2–20 CRM users.
- A straightforward sales process shared by the team.
- Both business customers and individual customers are first-class use cases.
- Most records and interactions are entered manually.
- The initial product supports one sales pipeline and one organisation-wide currency.
- The team works to a single declared timezone.
- Sales and relationship management are in scope; marketing automation and customer support case management are not.
- The CRM runs where only the organisation's own members can reach it, and those members are identified by the surrounding environment rather than by the CRM. The CRM knows which member is acting, and controls what that member can do inside the workspace, but does not implement sign-in, credentials, network protection, or storage protection.
- Import and export move a complete workspace in a single file. They exist for migration, backup, and restoration, not for routine data entry.

If any of these assumptions are false, the requirements should be revisited before design begins.

## 3. Research findings and product implications

Research across established CRM products showed a stable minimum:

1. A shared contact record is the foundation. HubSpot describes contact management, communication history, deals, tasks, pipeline management, import, and reporting as core small-business CRM capabilities.
2. A deal pipeline needs to show both progress and attention required. Pipedrive treats a deal as an opportunity that moves through stages to a won or lost outcome, and prioritises deals using their next activity.
3. Activities are not merely a historical log. Calls, meetings, emails, and follow-ups are the controllable work that moves a deal forward, so every active opportunity should have a visible next action.
4. Separate lead conversion introduces decisions about creating or matching people, companies, and deals. Zoho's conversion workflow demonstrates the duplicate and history-preservation issues this creates. For a minimal CRM, a person remains the same record throughout the relationship; qualification creates a deal rather than converting the person into another record type.
5. Data quality and portability are part of the basic product, not advanced administration. Users need import, export, duplicate prevention, correction, and safe archiving.
6. Customer information requires care. For Australian organisations, the Australian Privacy Principles address collection, data quality, protection from misuse and unauthorised access, access, correction, and destruction or de-identification once the information is no longer needed. The APPs contain no general right to erasure equivalent to the European GDPR; the obligation that most shapes this product is APP 11.2, which concerns destroying or de-identifying personal information the organisation no longer needs. Exact legal obligations depend on the organisation and jurisdiction.
7. Twenty's standard model of People, Companies, Opportunities, Tasks, and Notes reinforces that a small set of related concepts can cover the core workflow. Its migration flow also highlights stable identifiers, relationship-aware import, validation, and preview.
8. Atomic CRM combines contacts, companies, tasks, reminders, notes, a configurable deal pipeline, and aggregated activity history. Its single-file JSON migration is a useful model for portable import and export.
9. Established CRMs normally provide default pipeline stages and then let a trusted workspace user rename, reorder, add, or retire them. Loss reasons are most useful as configurable choices with optional explanatory context.
10. Contact creation is generally permissive. HubSpot permits manual creation with a name and/or email and recommends email because it improves matching. Task handling typically combines due-today, overdue, and upcoming views with optional timed notifications.

## 4. Users and their needs

### Sales or relationship owner

Needs to:

- Capture a new relationship quickly.
- See the complete context before contacting someone.
- Know which follow-ups are due and which opportunities need attention.
- Record an interaction without excessive administration.
- Move an opportunity forward and hand it to a colleague without losing context.

### Sales manager

Needs to:

- Understand the current pipeline and likely outcomes.
- Identify opportunities with overdue or missing follow-ups.
- See workload and results by owner.
- Improve data quality and reassign work when necessary.

### Workspace member performing setup and stewardship

Needs to:

- Manage members, pipeline stages, and standard choices.
- Import existing business data and export it when needed.
- Resolve duplicates and support privacy-related access, correction, and deletion requests.

This is a responsibility, not a permission tier. All active workspace members are trusted and
have identical access; "owner" expresses responsibility for follow-up, not record visibility.
In a very small business, one person may perform all three roles. Wherever these
requirements once said "an authorised user", they now say "an active workspace member",
because no other level of authorisation exists.

## 5. Product principles

- The record should answer: "Who are they, what has happened, what is open, and what happens next?"
- Enter information once and reuse it wherever the relationship appears.
- Make incomplete follow-up more visible than administrative completeness.
- Preserve useful history when records are reassigned, closed, archived, or merged.
- Ask only for information needed to manage the relationship.
- Prefer clear, reversible actions. Where an action cannot be reversed, state plainly what it will do before the member commits to it.
- A member should never lose a colleague's work without being told.

## 6. Core concepts

- **Workspace:** The organisation's single CRM instance, its members, its configurable choices, its currency, and its timezone.
- **Person:** An individual the organisation communicates with, whether they are a new lead, prospect, customer, or inactive relationship.
- **Company:** An organisation associated with one or more people. A person does not need to belong to a company.
- **Customer party:** The person or company that would buy. A company deal may also identify one or more people as contacts. An individual deal does not require a company.
- **Deal:** A specific sales opportunity that a member has decided is worth tracking, with a person or company as its customer party. A person or company may have multiple deals over time.
- **Activity:** A past interaction, such as a note, call, email, or meeting, or a record of a material change such as a change of owner or stage.
- **Task:** A planned action with a due date and an assignee.
- **Next action:** A deal's next action is its earliest open task linked directly to that deal, whoever it is assigned to. A task linked only to the related person or company does not count as the deal's next action, and completed or cancelled tasks never count.
- **Owner:** The team member accountable for a person, company, deal, or task.
- **Pipeline stage:** The current step of an open deal. "Won" and "lost" are final outcomes rather than active stages.
- **Archived:** A record deliberately set aside as no longer active. Archiving is always reversible.
- **Deleted:** A record permanently removed. Deletion cannot be reversed from inside the CRM.

## 7. Core workflows

### Workflow A — Capture a new enquiry

1. The member searches for the person or company to avoid creating a duplicate.
2. If no record exists, the member records the minimum known contact information.
3. The member records the source and context of the enquiry.
4. The member assigns an owner and relationship status.
5. The member records or schedules the next action.

Outcome: the enquiry has an accountable owner, enough context for another team member to understand it, and a follow-up.

### Workflow B — Qualify an opportunity

1. The owner reviews the relationship history.
2. The owner decides whether there is a sufficiently real sales opportunity to track. The CRM offers guidance but does not enforce a universal qualification test.
3. If so, the owner creates a deal with the existing person or company as the customer party. For a company deal, the owner may also identify the relevant contact people.
4. The owner records the deal's current stage and any known value or expected close date.
5. The owner schedules the next action.

Outcome: qualification does not duplicate or replace the relationship record, and the opportunity appears in the active pipeline.

### Workflow C — Work daily follow-ups

1. The member opens a work list showing overdue, due-today, and upcoming actions.
2. The member opens a task and sees the related person, company, deal, and recent history.
3. The member completes the action and records its outcome.
4. Where more work is required, the member schedules the next action and updates the deal stage if appropriate.

Outcome: completed work becomes part of the shared history and no active opportunity is left without an obvious next step.

### Workflow D — Progress and close a deal

1. The owner moves the deal through stages that reflect completed sales milestones.
2. The owner can see how long the deal has been open, its recent activity, and its next action.
3. The owner marks the deal won or lost when a final outcome is known.
4. For a lost deal, the owner records a loss reason. For a won deal, the related relationship can be identified as a customer.
5. Closed deals leave the active pipeline but remain available in history and reporting.

Outcome: the active pipeline reflects reality and completed outcomes remain explainable.

### Workflow E — Reassign or hand over a relationship

1. A member changes the relevant owner, either on one record or on a selected set of records.
2. Open tasks are reviewed and reassigned or retained explicitly.
3. The new owner can see the full relationship history, active deals, and pending work.
4. Where the handover is caused by a member leaving, the departing member's open deals and open tasks are reassigned before their access ends.

Outcome: accountability is clear, no open work is left owned by someone who cannot act on it, and the customer does not need to repeat prior context.

### Workflow F — Maintain data quality

1. A member is warned when a likely matching person or company already exists at the moment of creation.
2. A member who suspects a duplicate later can search for and compare any two records of the same type.
3. The member either keeps them separate or merges them, after reviewing what the merge will do.
4. A merge preserves the chosen details, associations, activities, deals, and ownership history, and the member reviews the surviving deals in case the merge has left two deals describing one opportunity.

Outcome: the team works from one coherent version of each relationship without losing history.

### Workflow G — Keep an existing customer

1. When a deal is won, the customer party's lifecycle status can be set to customer and a follow-up scheduled.
2. A member can list customers ordered by the date of their most recent activity, so quiet relationships surface.
3. The member reviews the relationship history and records or schedules the next contact.
4. Where a renewal or new piece of work emerges, the member creates a new deal against the same person or company.

Outcome: a won deal leaving the active pipeline does not mean the customer disappears from view, and repeat or renewal business is visible without a separate system.

## 8. Must-have functional requirements

All requirements in this section are required for the minimal release.

### Contacts and companies

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-001 | A member can create, view, and update a person by supplying a name alone. Email, phone, and all other details are optional at first capture. The CRM itself supplies owner, lifecycle status, authorship, and timestamps, defaulting the owner to the member creating the record and the lifecycle status to lead. | A new relationship can be captured from a name alone, and the record that results is complete enough to export and re-import without further editing. |
| CRM-002 | A person can hold one or more email addresses and phone numbers, each with a label and at most one of each marked primary, together with role/title, relationship status, source, owner, and free-form context. | The record contains enough identity, qualification, and ownership context to support follow-up. |
| CRM-003 | A member can create, view, and update a company and associate multiple people with it. | Opening a company reveals its people, active deals, and recent activity. |
| CRM-004 | A person can exist without a company and can later be associated with one. Changing a person's company moves them to the new company; activities, deals, and tasks stay attached to the records they were logged against. | Individual customers and initially incomplete enquiries are supported, and a person changing employer does not silently rewrite the former company's history. |
| CRM-005 | A person or company has a lifecycle status of lead, prospect, customer, or inactive, which can change at any time without creating a replacement record. | Relationship progress can be represented without a lead-conversion workflow. |
| CRM-006 | A record presents contact details, owner, status, linked records, active deals, open tasks, and chronological activity in one coherent view. A company's view also shows activity logged against its people. | A colleague can understand the current relationship without consulting another system. |
| CRM-007 | Before a person or company is created, the member is shown likely existing matches, ranked by strength. A matching email address, phone number, or company website domain is a strong match and is shown prominently. A matching name alone is a weak match, shown as a possible existing record and never as a recommended merge. The member can open an existing record or confirm the new record is distinct. | Accidental duplicates are discouraged without blocking legitimate similar records, records that share an email address, or records with little initial data. |
| CRM-008 | A member can archive a person or company that is no longer active. Archiving lists any open deals and open tasks attached to the record and requires the member to close, reassign, or explicitly keep each one in the same action. Archiving is reversible and erases nothing. | Archived records leave normal working views without stranding open work that someone is still expecting to do. |

### Deals and pipeline

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-009 | A member can create a deal with either a person or a company as its customer party and assign its owner and current stage. A company deal can identify one or more associated contact people. | Both individual and business sales are supported while every pipeline item has relationship context and accountability. |
| CRM-010 | A deal can record a title, value when known, expected close date when known, source, description, and relevant people. | Members can distinguish and assess opportunities without making speculative fields mandatory. |
| CRM-011 | The team can view all open deals grouped by their current stage. | The pipeline provides a shared picture of work in progress. |
| CRM-012 | A member can name, order, add, and retire the workspace's configurable choices: pipeline stages, loss reasons, sources, and task types. A stage cannot be retired while open deals occupy it; retiring it requires nominating the stage those deals move to, and that move is recorded on each deal. Retired choices remain readable wherever existing records still reference them. | The pipeline and standard choices can reflect the team's actual process without rewriting history or stranding deals in a stage that no longer exists. |
| CRM-013 | A member can move a deal to another active stage while the CRM retains when and by whom the change occurred, and which stage the deal actually moved from. | The current position and progression history remain understandable and form an unbroken chain. |
| CRM-014 | Each open deal displays its owner, value if known, expected close date if known, and next-action status. | Members can identify important and neglected deals from the pipeline. |
| CRM-015 | A member can mark a deal won or lost; a lost deal requires a configured reason plus optional context. "Other" remains available when no standard reason fits. | Closed outcomes are consistent enough to review later without forcing an inaccurate choice. |
| CRM-016 | A member can reopen a closed deal when the real-world opportunity resumes. Reopening is recorded as a dated event, clears the outcome and outcome date, clears any loss reason, and returns the deal to the stage it occupied when it closed, or to the first active stage if that stage has since been retired. | Mistakes and renewed negotiations do not require a duplicate deal, and a reopened deal is never left carrying a stale outcome. |
| CRM-017 | Closed deals are excluded from the default active pipeline but remain searchable and included in historical reporting. | Day-to-day work stays uncluttered without losing business history. |

### Activities, tasks, and follow-up

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-018 | A member can log a note, call, email, or meeting against a person, company, or deal, including when it occurred and an optional outcome. A single activity can relate to several records at once. | Important customer interactions form a shared chronological history that appears wherever it is relevant. |
| CRM-019 | A member can create a follow-up task with a subject, due date, assignee, completion state, optional type, and related person, company, or deal. | Every planned action has timing, accountability, and context. |
| CRM-020 | A member can complete a task and record its result without leaving the related relationship context. | Updating the CRM is a natural part of completing the work. |
| CRM-021 | When completing a follow-up, a member can immediately schedule the next action. | Multi-step follow-up does not end in an untracked gap. |
| CRM-022 | Each member has a work list that clearly separates overdue, due-today, and upcoming tasks, evaluated against the workspace timezone. | A member can decide what to do next without checking every record. |
| CRM-023 | Open deals with an overdue next action, or with no next action at all, are visibly distinguishable in the pipeline and relevant lists. | Neglected opportunities can be found before they go cold. |
| CRM-024 | Every open task appears in its assignee's due, overdue, and upcoming work views from the moment it is created, with no configuration required. | Follow-up is visible by default, and no task depends on a member having configured anything to be seen. |
| CRM-046 | The workspace has one declared timezone. Every due, overdue, upcoming, and day-grouped view is evaluated in that timezone, and reports state it. | Two members in different locations see the same task in the same bucket and the same overdue count. |

### Finding and organising work

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-025 | A member can search across people, companies, and deals using common identifying information, and across the free-text content of activities, tasks, and deal descriptions. Archived records and closed deals are excluded by default and included by an explicit choice that states how many additional results it added. | A known record can be found without knowing its type or owner, someone mentioned only inside a note can be found, and a member always knows whether they are looking at active records alone. |
| CRM-026 | People, companies, deals, and tasks can be filtered and sorted using a defined set of fields for each list: people and companies by owner, lifecycle status, source, archived state, and date of last activity; deals by owner, stage, status, source, expected close date, value, and date of last activity; tasks by assignee, status, and due date. | Members can isolate their work and answer routine operational questions, and the lists have a knowable, testable set of controls. |
| CRM-027 | A member's starting view summarises overdue and due-today tasks, deals without a next action, and recently updated records. | The CRM directs attention to action rather than acting only as a database. |
| CRM-028 | Empty results and "no work due" states explain what the member is seeing and, where relevant, how to add or broaden the view. | Members can distinguish a genuine empty state from a mistake or hidden filter. |

### Team accountability and access

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-029 | Every person, company, deal, and task has one current owner and can be reassigned by any active member, individually or as a selected set. | Responsibility is unambiguous during normal work and handover, and reassigning a departing member's work does not require opening every record. |
| CRM-030 | Members can see who created each record, who last changed it and when, who logged each activity, and the recorded history of owner, stage, and status changes. | Team members can reconstruct how a record reached its current owner, stage, and status, and can tell who to ask about anything else. |
| CRM-031 | Every active workspace member can view and update all customer and sales records and can use shared settings, import, export, merge, archive, and deletion workflows. Ownership does not restrict visibility, and no other level of authorisation exists. | The access model remains understandable for a small, fully trusted team, and no requirement depends on a permission tier the product does not have. |
| CRM-032 | Ending a member's workspace access does not remove the customer records, activities, deals, or tasks they owned or authored, and does not rewrite their authorship of past activity. | Staff changes do not erase organisational memory. |
| CRM-047 | When two members change the same record at the same time, the second change is not silently discarded: the member is told what changed, by whom, and can reapply their edit. | A colleague's work is never lost without anyone noticing. |
| CRM-048 | A member's workspace access cannot be ended while they still own open deals or open tasks. Ending their access requires reassigning that open work to active members in the same action, and takes effect immediately. | No open task or open deal is left owned by someone who can no longer act on it, and no work quietly disappears from every work list. |
| CRM-049 | The workspace keeps a record, visible to all members, of every export, permanent deletion, merge, import, and bulk reassignment: who performed it, when, and what it affected. | In a team where everyone can do everything, every consequential action is attributable to a named member and visible to their colleagues. |

### Reporting

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-033 | A manager can see the count and total known value of open deals by stage and owner. | The current pipeline can be reviewed without manual calculation. |
| CRM-034 | A manager can review deals won and lost over a selected period, including known value, owner, and loss reason. A deal reopened after the period it closed in remains counted in that period's outcome and is shown as subsequently reopened. | The team can assess outcomes and recurring reasons for loss, and a past period's report does not silently change when someone reopens an old deal. |
| CRM-035 | A manager can see overdue tasks and open deals with no next action, grouped by owner. | Follow-up risk and workload issues are visible. |
| CRM-036 | Reports clearly distinguish unknown values from zero values and state the period, timezone, and filters applied. | Totals are not misleading when information is incomplete. |

### Data administration and privacy

| ID | Requirement | Verification outcome |
|---|---|---|
| CRM-037 | A member can import one JSON file containing a complete workspace — settings, members, people, companies, deals, activities, and tasks — into an empty workspace; review what will be created and what has been rejected; and confirm before any change is committed. Importing into a workspace that already contains records is refused. | Existing data can be adopted, and a backup restored, without any possibility of silently overwriting or half-merging records that are already there. |
| CRM-038 | A member can export the complete workspace — settings, members, people, companies, deals, tasks, and activity history, including archived records — as one JSON file in the same documented format accepted for import. Before the file is produced, the CRM states how many records it will contain and that it holds personal information which leaves the CRM's control once downloaded. | The organisation can make a complete, intelligible backup and round-trip its business data, and nobody produces a copy of the entire customer base without realising what they have made. |
| CRM-039 | A member can find and compare two people or two companies at any time, and merge them after reviewing the result. Every field that can hold only one value — name, owner, lifecycle status, company, job title, source — is presented for an explicit choice. Email addresses and phone numbers are combined with one of each retained as primary. Merging cannot be reversed, so the review states plainly what will happen before it is committed. | Duplicate resolution does not arbitrarily discard correct information, and a member cannot merge two records without first seeing what they are about to combine. |
| CRM-040 | A merge retains activities, tasks, deals, company relationships, and ownership history from both source records, and records which records were combined and which values were kept. Afterwards the member reviews the surviving deals so that two deals describing one opportunity can be resolved. | Resolving a duplicate does not break the customer history, and does not leave one real opportunity counted twice in the pipeline. |
| CRM-041 | A member can locate everywhere the workspace holds information about a named individual — their own record, the companies, deals, activities, and tasks they are linked to, and free-text fields elsewhere that mention their name, email address, or phone number — and can read, correct, or delete what is found. Archived records are included. | An access, correction, or deletion request is answered against the whole workspace rather than one record, and nothing is missed because it was written in prose. |
| CRM-042 | Archiving is the reversible way to remove a record from everyday view. Deletion is permanent and irreversible: before it proceeds, the CRM states exactly what will be removed, including the counts of dependent activities, tasks, and deals, and requires explicit confirmation. | A member always knows which of the two actions they are taking, and cannot destroy material history by mistaking one for the other. |
| CRM-043 | Every field the CRM collects about a person or company serves one of the workflows in section 7, and the CRM makes the purpose and source of the information it holds understandable to members. | The claim to collect only what is needed can be checked against the record structure rather than taken on trust. |
| CRM-044 | Ending a member's workspace access removes their ability to view or change any customer information immediately, including in any session they already have open. | A former member cannot continue working in the CRM after their access has been ended, even from a device that is still on the organisation's network. |
| CRM-045 | When information about an individual is deleted to fulfil a privacy request, the CRM identifies the remaining free-text references to that individual — in activities, tasks, deal titles and descriptions, and other records' context notes — so the member can correct or remove them as part of the same request. | Deleting a person's record does not leave their name, contact details, and personal circumstances behind in notes that no search for their record would ever surface. |

## 9. Experience requirements

These requirements describe user outcomes, not a particular interface:

- A new member, after a short introduction, can create a person and schedule a follow-up without specialist CRM training.
- A regular member can locate an existing relationship and understand its latest context in under 30 seconds during a usability test.
- Moving a deal to its next stage or completing a task requires only the information relevant to that action.
- Required information is kept to the minimum needed to make a record usable; unknown commercial information can remain unknown.
- The same concept and status uses consistent language wherever it appears.
- Destructive, bulk, or privacy-sensitive actions state their effect, including how many records they touch, before the member commits them. These are: deletion, merging, archiving a record with open work, retiring a pipeline stage, bulk reassignment, import, and export.
- All core workflows are usable by people who navigate with a keyboard or assistive technology, and status is not communicated by colour alone.
- If an action cannot be completed, the member is told what needs attention without losing information already entered.

## 10. Business rules

1. A relationship begins as a person, a company, or both; "lead" is a lifecycle status, not a disposable record type.
2. A deal is created only when there is a specific opportunity worth tracking.
3. A deal has exactly one current owner and one current pipeline stage while open.
4. A deal can finish only as won or lost. Closing it records the outcome date. Reopening clears the outcome and its date and is itself recorded.
5. A lost deal requires a standard loss reason; explanatory notes remain optional.
6. Every open deal should have a next action: its earliest open task linked directly to the deal, whoever it is assigned to. The CRM highlights exceptions but does not prevent urgent updates.
7. Completing a task does not automatically imply that a deal has changed stage.
8. Archiving removes a record from ordinary work views and is always reversible. Deletion is permanent and is never reached by accident from an archive action.
9. Merging duplicates produces one surviving relationship and preserves the combined history and associations. A merge cannot be undone, so it is confirmed against a preview of its effect.
10. Reassignment changes current accountability but does not rewrite historical authorship.
11. An email address or phone number may be held by more than one person. Where it is, it stops being treated as a strong duplicate signal.
12. Open work is always owned by someone who can act on it: a member's access cannot end while they own an open deal or open task.
13. Overdue, due today, and upcoming are evaluated in the workspace's declared timezone.
14. An activity or task belongs to every record it relates to. It is removed only when every record it relates to has been deleted; while any remains, it continues under that record's history.
15. A deal is dependent on its customer party. Deleting a person or company deletes its deals, and the deletion confirmation says so.
16. A stage cannot be retired while open deals occupy it.
17. A closed deal's stage, value, and outcome are settled. Logging activities and tasks against it remains possible; changing a settled field requires reopening the deal first.
18. Import and export always move a complete workspace. There is no partial import and no partial export, and import is only ever into an empty workspace.
19. Every consequential action — export, deletion, merge, import, bulk reassignment — is attributable to the member who performed it and visible to the rest of the team.

## 11. Explicitly out of scope for the minimal release

- Marketing campaigns, bulk email, audience journeys, and lead scoring.
- Automatic email, calendar, phone, social-media, or website-form synchronisation. Lightweight email capture is the highest-priority post-MVP candidate because manual communication logging creates recurring work.
- Customer support tickets, service-level management, and knowledge bases.
- Quotes, contracts, invoices, payments, products, and inventory.
- Workflow automation, automatic assignment, and approval processes.
- AI-generated summaries, predictions, enrichment, or suggested actions.
- Multiple pipelines, territories, business units, currencies, timezones, or languages.
- Highly custom record types, calculated fields, and user-designed reports.
- Customer self-service portals.
- Native mobile applications or offline operation.
- Sign-in, credentials, network protection, and storage protection. The CRM is reached only over the organisation's own private network and members are identified by the surrounding environment. The CRM still decides what an identified member can do, and still ends a member's access immediately when it is withdrawn.
- Timed reminders delivered outside the CRM, digests, and calendar synchronisation. Tasks are visible in the CRM's work views without configuration.
- Partial import and partial export, and importing into a workspace that already holds records.
- Undoing a merge, and recovering a deleted record. Archiving covers the reversible case; export covers the disaster case.
- Field-by-field change history beyond owner, stage, and status.
- Permission tiers, per-record visibility, and any distinction between members beyond active and inactive.

These may become later requirements only after real usage shows that they solve a frequent, important problem.

## 12. Release acceptance outcomes

The minimal CRM is ready for a pilot when a representative small team can:

1. Establish its active people and companies, by manual entry or by importing a complete workspace file into an empty workspace, without uncontrolled duplication.
2. Capture a new enquiry, assign it, record its context, and schedule a follow-up.
3. Turn a qualified enquiry into a deal without duplicating the person.
4. Run a complete working day from the task list and pipeline.
5. Move deals through the pipeline and close them won or lost.
6. Hand a relationship to another member with its context intact, including when that member is leaving.
7. Answer "What is open, what needs attention, and what have we won or lost?" from the available views and reports.
8. Keep a won customer visible and schedule the next contact with them.
9. Archive a record that is no longer active and bring it back.
10. Find and merge a duplicate person or company without losing history.
11. Export the complete workspace and restore it into an empty workspace unchanged.
12. Locate everything held about one named individual, correct it, and delete it.

## 13. Suggested pilot success measures

Validate these after 2–4 weeks of real use:

- The median time since the last completed activity, across open deals, is under 14 days. This replaces counting deals that merely have a future task attached, which can be satisfied by rescheduling a placeholder.
- No open deal has had its next action rescheduled three or more times without an activity being logged in between.
- Fewer than 5% of active person records are duplicates, measured by sampling rather than by the CRM's own matching.
- No pilot member is still maintaining a personal spreadsheet or note file of customer information, confirmed by asking to see it.
- A member can capture a new enquiry and its follow-up in under two minutes in a usability test.
- A manager can identify overdue follow-ups and explain the current pipeline without manual data reconciliation.
- Daily use continues into week four rather than tapering after the first fortnight.

The measures are product hypotheses for the pilot, not permanent targets; revise them after observing the team's actual sales cycle.

## 14. Validated product decisions

The initial open questions have been resolved as follows:

1. **Customer type:** Support both businesses and individuals. A deal's customer party is either a company or a person; a company deal can additionally link its contact people.
2. **Qualification:** The member decides when an enquiry is worth tracking as a deal. Suggested guidance is evidence of interest or need plus a meaningful next step, but this is not an enforced gate.
3. **Pipeline:** Start with four editable open stages: New opportunity, Discovery, Proposal, and Negotiation. Won and lost are outcomes. Members can rename, reorder, add, and retire open stages, and a stage holding open deals cannot be retired without moving them.
4. **Loss reasons:** Start with No budget, No decision, Competitor, Poor fit, Timing, No response, and Other. Members can configure the list; Other permits explanatory context.
5. **Access:** All active workspace members are equally privileged and can see and do everything. Ownership communicates accountability only. Because there is no permission tier to restrain consequential actions, the workspace instead records them and shows them to everyone.
6. **Minimum contact capture:** A person's name is the only field a member must supply; a company name is the only field a member must supply for a company. Owner, lifecycle status, authorship, and timestamps are supplied by the CRM. Everything else is optional, although the CRM should clearly prompt for an email or phone because it makes follow-up and duplicate detection more reliable.
7. **Source:** Source is optional. Start with Referral, Inbound enquiry, Outbound prospecting, Event, Partner, and Other, and allow the list to be configured.
8. **Task types:** Optional on a task. Start with Call, Email, Meeting, Follow up, and Other, and allow the list to be configured alongside the other choices.
9. **Reminders:** Due and overdue tasks are always visible in the CRM's work views, with no configuration. Timed external notifications, digests, and calendar synchronisation are out of scope.
10. **Timezone:** The workspace declares one timezone, and every date-grouped view and report is evaluated and labelled in it.
11. **Retention:** Closing a relationship never deletes it. Inactive records are archived and retained until the organisation decides they are no longer needed. Deletion is permanent, confirmed against a statement of what it removes, and is the mechanism used to fulfil an approved privacy request. The product does not attempt to decide the organisation's legal or business retention period.
12. **Import and export:** Use the companion [Simple CRM JSON interchange format](./01-full-design-json-interchange.md). A file always carries a complete workspace. Export produces one; import accepts one into an empty workspace, previewed before commitment. There is no partial file and no merging import.
13. **Deployment and access control:** The CRM is reached only over the organisation's private network, and members are identified by the surrounding environment. The CRM does not implement sign-in or protect the network or the stored data; it does control what an identified member can do and ends a member's access immediately when withdrawn.
14. **Weekly management questions:** The default reporting must answer: What is currently in the pipeline and where? What needs attention now? What did we win or lose, and why? These map to CRM-033 through CRM-036.
15. **Most burdensome excluded capability:** Communication capture is the strongest candidate for the first post-MVP enhancement. Atomic CRM's lightweight BCC/forward-to-CRM model is a useful intermediate step before full email and calendar synchronisation.

## 15. Remaining pilot questions

These questions require observation of a real team rather than a generic product decision:

1. Do the default stages, loss reasons, and task types match the language members naturally use?
2. Does name-only contact capture create too many ambiguous records in practice?
3. Is the in-CRM work view sufficient on its own, or do members miss follow-ups because they did not open the CRM that day?
4. Does manual communication logging cause enough missed context to justify bringing lightweight email capture into the first release?
5. What retention policy does the adopting organisation approve for its particular records and obligations, and does the absence of any recovery path for deletion prove uncomfortable in practice?
6. Does the team need to record that an individual has asked not to be called or emailed? The Spam Act 2003 and the Do Not Call Register Act 2006 have no small-business exemption, and the workspace ships an Outbound prospecting source, but a minimal CRM with no bulk contact capability may reasonably leave this to the member's judgement.
7. Does losing a person's association with their former employer, when they change companies, cost the team useful history?
8. Is one workspace timezone sufficient, or does the team in practice span more than one?

## Sources consulted

- [HubSpot — Free CRM for startups and small businesses](https://www.hubspot.com/products/crm)
- [HubSpot — Create contacts](https://knowledge.hubspot.com/records/create-contacts)
- [HubSpot — Task views and filters](https://knowledge.hubspot.com/tasks/filter-tasks-and-manage-task-views)
- [HubSpot — Task reminders and daily digests](https://knowledge.hubspot.com/tasks/task-reminders-and-daily-digest)
- [Salesforce — What is a CRM system?](https://www.salesforce.com/crm/what-is-crm/crm-systems/)
- [Pipedrive — Pipeline view: manage the deal lifecycle](https://support.pipedrive.com/en/article/pipeline-view)
- [Pipedrive — Activities and goals](https://www.pipedrive.com/en/features/activities-goals)
- [Pipedrive — How pipeline prioritisation works](https://support.pipedrive.com/en/article/how-are-deals-ordered-in-the-pipeline-view)
- [HubSpot — Set up and customise pipelines](https://knowledge.hubspot.com/object-settings/set-up-and-customize-pipelines)
- [Zoho — Converting leads](https://help.zoho.com/portal/en/kb/crm/sales-force-automation/leads/articles/convert-leads)
- [Zoho — Creating and managing deals](https://help.zoho.com/portal/en/kb/crm/sales-force-automation/deal-management/articles/create-deals)
- [HubSpot — Review and manage duplicate records](https://knowledge.hubspot.com/records/manage-duplicate-records)
- [HubSpot — Export CRM records](https://knowledge.hubspot.com/import-and-export/export-records)
- [OAIC — Australian Privacy Principles](https://www.oaic.gov.au/privacy/australian-privacy-principles)
- [Twenty — Standard CRM objects](https://docs.twenty.com/user-guide/data-model/capabilities/objects)
- [Twenty — Data migration](https://docs.twenty.com/user-guide/data-migration/overview)
- [Twenty — Dashboards](https://docs.twenty.com/getting-started/core-concepts/dashboards)
- [Atomic CRM — Product features](https://marmelab.com/atomic-crm/)
- [Atomic CRM — Application settings](https://marmelab.com/atomic-crm/doc/users/settings/)
- [Atomic CRM — JSON migration](https://marmelab.com/atomic-crm/doc/users/import-data/)
