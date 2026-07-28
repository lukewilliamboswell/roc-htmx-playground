-- USERS
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    email TEXT
);

INSERT INTO users (name, email) VALUES
    ('Mara Singh', 'mara@example.com'),
    ('Theo Nguyen', 'theo@example.com');

-- WORKSPACE MEMBERS
--
-- These are the CRM actors. The legacy users table remains temporarily for
-- the hidden Todo tree and user-list demos.
CREATE TABLE workspaces (
    workspace_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    currency TEXT NOT NULL CHECK(length(currency) = 3),
    timezone TEXT NOT NULL
);

INSERT INTO workspaces (workspace_id, name, currency, timezone) VALUES
    ('workspace-example', 'Example CRM', 'AUD', 'Australia/Melbourne');

CREATE TABLE sources (
    workspace_id TEXT NOT NULL,
    source_id TEXT NOT NULL,
    name TEXT NOT NULL,
    position INTEGER NOT NULL,
    active INTEGER NOT NULL CHECK(active IN (0, 1)),
    PRIMARY KEY (workspace_id, source_id),
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id)
);

INSERT INTO sources (workspace_id, source_id, name, position, active) VALUES
    ('workspace-example', 'referral', 'Referral', 1, 1),
    ('workspace-example', 'inbound', 'Inbound enquiry', 2, 1),
    ('workspace-example', 'outbound', 'Outbound prospecting', 3, 1),
    ('workspace-example', 'event', 'Event', 4, 1),
    ('workspace-example', 'partner', 'Partner', 5, 1),
    ('workspace-example', 'other', 'Other', 6, 1);

CREATE TABLE task_types (
    workspace_id TEXT NOT NULL,
    task_type_id TEXT NOT NULL,
    name TEXT NOT NULL,
    position INTEGER NOT NULL,
    active INTEGER NOT NULL CHECK(active IN (0, 1)),
    PRIMARY KEY (workspace_id, task_type_id),
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id)
);

INSERT INTO task_types (workspace_id, task_type_id, name, position, active) VALUES
    ('workspace-example', 'call', 'Call', 1, 1),
    ('workspace-example', 'email', 'Email', 2, 1),
    ('workspace-example', 'meeting', 'Meeting', 3, 1),
    ('workspace-example', 'follow-up', 'Follow up', 4, 1),
    ('workspace-example', 'other', 'Other', 5, 1);

CREATE TABLE members (
    member_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL,
    active INTEGER NOT NULL CHECK(active IN (0, 1)),
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id)
);

INSERT INTO members (member_id, workspace_id, name, email, active) VALUES
    ('member-mara', 'workspace-example', 'Mara Singh', 'mara@example.com', 1),
    ('member-theo', 'workspace-example', 'Theo Nguyen', 'theo@example.com', 1);

-- SESSIONS
CREATE TABLE sessions (
    session_id INTEGER PRIMARY KEY,
    user_id INTEGER NULL,
    member_id TEXT NULL,

    CONSTRAINT fk_column
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_session_member
        FOREIGN KEY (member_id)
        REFERENCES members (member_id)
        ON DELETE SET NULL
);

-- CRM COMPANIES
CREATE TABLE companies (
    company_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL CHECK(lifecycle_status IN ('lead', 'prospect', 'customer', 'inactive')),
    website TEXT NOT NULL DEFAULT '',
    website_domain TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    normalized_phone TEXT NOT NULL DEFAULT '',
    source_id TEXT NOT NULL DEFAULT '',
    context TEXT NOT NULL DEFAULT '',
    created_by_id TEXT NOT NULL,
    updated_by_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT NOT NULL DEFAULT '',
    version INTEGER NOT NULL DEFAULT 1 CHECK(version > 0),
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id),
    FOREIGN KEY (owner_id) REFERENCES members(member_id),
    FOREIGN KEY (created_by_id) REFERENCES members(member_id),
    FOREIGN KEY (updated_by_id) REFERENCES members(member_id)
);

CREATE INDEX companies_active_name
    ON companies(workspace_id, archived_at, normalized_name);
CREATE INDEX companies_phone
    ON companies(workspace_id, normalized_phone);
CREATE INDEX companies_domain
    ON companies(workspace_id, website_domain);

CREATE TABLE company_revisions (
    company_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    name TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL,
    website TEXT NOT NULL,
    phone TEXT NOT NULL,
    source_id TEXT NOT NULL,
    context TEXT NOT NULL,
    changed_by_id TEXT NOT NULL,
    changed_at TEXT NOT NULL,
    PRIMARY KEY (company_id, version),
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_id) REFERENCES members(member_id)
);

CREATE TABLE activities (
    activity_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    created_by_id TEXT NOT NULL,
    subject TEXT NOT NULL DEFAULT '',
    details TEXT NOT NULL DEFAULT '',
    outcome TEXT NOT NULL DEFAULT '',
    change_field TEXT NOT NULL DEFAULT '',
    change_from TEXT NOT NULL DEFAULT '',
    change_to TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id),
    FOREIGN KEY (created_by_id) REFERENCES members(member_id)
);

CREATE TABLE activity_companies (
    activity_id TEXT NOT NULL,
    company_id TEXT NOT NULL,
    PRIMARY KEY (activity_id, company_id),
    FOREIGN KEY (activity_id) REFERENCES activities(activity_id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE
);

-- CRM PEOPLE
CREATE TABLE people (
    person_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL,
    company_id TEXT NOT NULL DEFAULT '',
    job_title TEXT NOT NULL DEFAULT '',
    owner_id TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL CHECK(lifecycle_status IN ('lead', 'prospect', 'customer', 'inactive')),
    source_id TEXT NOT NULL DEFAULT '',
    context TEXT NOT NULL DEFAULT '',
    created_by_id TEXT NOT NULL,
    updated_by_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT NOT NULL DEFAULT '',
    version INTEGER NOT NULL DEFAULT 1 CHECK(version > 0),
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id),
    FOREIGN KEY (owner_id) REFERENCES members(member_id),
    FOREIGN KEY (created_by_id) REFERENCES members(member_id),
    FOREIGN KEY (updated_by_id) REFERENCES members(member_id)
);

CREATE INDEX people_active_name
    ON people(workspace_id, archived_at, normalized_name);
CREATE INDEX people_company
    ON people(workspace_id, company_id, archived_at);

CREATE TABLE person_emails (
    email_id TEXT PRIMARY KEY,
    person_id TEXT NOT NULL,
    label TEXT NOT NULL,
    email TEXT NOT NULL,
    normalized_email TEXT NOT NULL,
    is_primary INTEGER NOT NULL CHECK(is_primary IN (0, 1)),
    position INTEGER NOT NULL,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
);

CREATE INDEX person_email_match ON person_emails(normalized_email);

CREATE TABLE person_phones (
    phone_id TEXT PRIMARY KEY,
    person_id TEXT NOT NULL,
    label TEXT NOT NULL,
    phone TEXT NOT NULL,
    normalized_phone TEXT NOT NULL,
    is_primary INTEGER NOT NULL CHECK(is_primary IN (0, 1)),
    position INTEGER NOT NULL,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
);

CREATE INDEX person_phone_match ON person_phones(normalized_phone);

CREATE TABLE person_revisions (
    person_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    name TEXT NOT NULL,
    company_id TEXT NOT NULL,
    job_title TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL,
    source_id TEXT NOT NULL,
    context TEXT NOT NULL,
    changed_by_id TEXT NOT NULL,
    changed_at TEXT NOT NULL,
    PRIMARY KEY (person_id, version),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_id) REFERENCES members(member_id)
);

CREATE TABLE activity_people (
    activity_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    PRIMARY KEY (activity_id, person_id),
    FOREIGN KEY (activity_id) REFERENCES activities(activity_id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
);

-- CRM FOLLOW-UP TASKS
CREATE TABLE crm_tasks (
    task_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    due_local TEXT NOT NULL,
    due_at_utc INTEGER NOT NULL,
    assignee_id TEXT NOT NULL,
    task_type_id TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL CHECK(status IN ('open', 'completed', 'cancelled')),
    company_id TEXT NOT NULL DEFAULT '',
    person_id TEXT NOT NULL DEFAULT '',
    context TEXT NOT NULL DEFAULT '',
    created_by_id TEXT NOT NULL,
    completed_by_id TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    completed_at TEXT NOT NULL DEFAULT '',
    version INTEGER NOT NULL DEFAULT 1 CHECK(version > 0),
    CHECK(company_id <> '' OR person_id <> ''),
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id),
    FOREIGN KEY (assignee_id) REFERENCES members(member_id),
    FOREIGN KEY (created_by_id) REFERENCES members(member_id)
);

CREATE INDEX crm_tasks_assignee_due
    ON crm_tasks(workspace_id, assignee_id, status, due_local);
CREATE INDEX crm_tasks_company
    ON crm_tasks(company_id, status, due_local);
CREATE INDEX crm_tasks_person
    ON crm_tasks(person_id, status, due_local);

-- TASKS
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    task VARCHAR(255),
    status VARCHAR(255)
);

INSERT INTO tasks (id, task, status) VALUES
    (0, 'Launch the neighbourhood garden', 'In-Progress'),
    (1, 'Confirm the council permit', 'Completed'),
    (2, 'Prepare the opening weekend', 'In-Progress'),
    (3, 'Book local musicians', 'Not Started');

-- TASK HIERARCHY
CREATE TABLE TaskHeirachy (
    user_id INTEGER,
    task_id INTEGER,
    lft INTEGER,
    rgt INTEGER,

    CONSTRAINT fk_user_id
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_task_id
        FOREIGN KEY (task_id)
        REFERENCES tasks (id)
        ON DELETE CASCADE
);

INSERT INTO TaskHeirachy (user_id, task_id, lft, rgt) VALUES
    (1, 0, 1, 8),
    (1, 1, 2, 3),
    (1, 2, 4, 7),
    (1, 3, 5, 6);

-- A fictional operations backlog with enough rows to exercise sorting,
-- pagination, editing, empty dates, and every status and priority.
CREATE TABLE BigTask (
    ID INTEGER PRIMARY KEY,
    ReferenceID TEXT NOT NULL,
    CustomerReferenceID TEXT NOT NULL,
    DateCreated TEXT NOT NULL,
    DateModified TEXT,
    Title TEXT NOT NULL,
    Description TEXT,
    Status TEXT CHECK(Status IN ('Raised', 'Completed', 'Deferred', 'Approved', 'In-Progress')),
    Priority TEXT CHECK(Priority IN ('High', 'Medium', 'Low')),
    ScheduledStartDate TEXT,
    ScheduledEndDate TEXT,
    ActualStartDate TEXT,
    ActualEndDate TEXT,
    SystemName TEXT,
    Location TEXT,
    FileReference TEXT,
    Comments TEXT
);

WITH RECURSIVE task_number(id) AS (
    SELECT 0
    UNION ALL
    SELECT id + 1 FROM task_number WHERE id < 99
)
INSERT INTO BigTask (
    ID,
    ReferenceID,
    CustomerReferenceID,
    DateCreated,
    DateModified,
    Title,
    Description,
    Status,
    Priority,
    ScheduledStartDate,
    ScheduledEndDate,
    ActualStartDate,
    ActualEndDate,
    SystemName,
    Location,
    FileReference,
    Comments
)
SELECT
    id,
    printf('OPS-%04d', 2100 + id),
    CAST(41000 + ((id * 137) % 9000) AS TEXT),
    date('2025-08-04', printf('+%d days', id * 2)),
    CASE
        WHEN id % 6 = 0 THEN NULL
        ELSE date('2025-08-04', printf('+%d days', (id * 2) + (id % 9) + 1))
    END,
    CASE id % 12
        WHEN 0 THEN 'Calibrate river-level sensors'
        WHEN 1 THEN 'Rehearse the gallery night changeover'
        WHEN 2 THEN 'Replace library self-check kiosks'
        WHEN 3 THEN 'Map accessible paths through the wetlands'
        WHEN 4 THEN 'Migrate volunteer shift reminders'
        WHEN 5 THEN 'Inspect the rooftop greenhouse irrigation'
        WHEN 6 THEN 'Publish the summer ferry timetable'
        WHEN 7 THEN 'Archive oral-history recordings'
        WHEN 8 THEN 'Trial reusable packaging with market vendors'
        WHEN 9 THEN 'Restore the observatory weather station'
        WHEN 10 THEN 'Coordinate the laneway lighting upgrade'
        ELSE 'Prepare the mobile clinic for regional visits'
    END || ' · phase ' || ((id / 12) + 1),
    CASE id % 10
        WHEN 0 THEN 'Field team needs an offline checklist before the next maintenance window.'
        WHEN 1 THEN 'Coordinate the handover without interrupting the public programme.'
        WHEN 2 THEN 'Pilot the change at two sites and collect staff feedback.'
        WHEN 3 THEN 'Confirm the route against the latest accessibility audit.'
        WHEN 4 THEN 'Move reminders to the shared service and preserve opt-out preferences.'
        WHEN 5 THEN 'Investigate pressure loss reported during the morning watering cycle.'
        WHEN 6 THEN 'Validate holiday services with crews and update passenger displays.'
        WHEN 7 THEN 'Create preservation copies and attach searchable interview notes.'
        WHEN 8 THEN 'Measure return rates before expanding beyond the Saturday market.'
        ELSE 'Replace the failed telemetry unit and backfill last week''s readings.'
    END,
    CASE id % 5
        WHEN 0 THEN 'Raised'
        WHEN 1 THEN 'In-Progress'
        WHEN 2 THEN 'Approved'
        WHEN 3 THEN 'Deferred'
        ELSE 'Completed'
    END,
    CASE id % 3
        WHEN 0 THEN 'High'
        WHEN 1 THEN 'Medium'
        ELSE 'Low'
    END,
    date('2025-08-11', printf('+%d days', id * 3)),
    date('2025-08-11', printf('+%d days', (id * 3) + 5 + (id % 8))),
    CASE
        WHEN id % 5 IN (1, 4) THEN date('2025-08-11', printf('+%d days', (id * 3) + 1))
        ELSE NULL
    END,
    CASE
        WHEN id % 5 = 4 THEN date('2025-08-11', printf('+%d days', (id * 3) + 6))
        ELSE NULL
    END,
    CASE id % 6
        WHEN 0 THEN 'Civic Works'
        WHEN 1 THEN 'Culture Hub'
        WHEN 2 THEN 'Library Network'
        WHEN 3 THEN 'Parks GIS'
        WHEN 4 THEN 'Community CRM'
        ELSE 'Field Operations'
    END,
    CASE id % 8
        WHEN 0 THEN 'Birrarung control room'
        WHEN 1 THEN 'Northside gallery'
        WHEN 2 THEN 'Carlton branch'
        WHEN 3 THEN 'Trin Warren wetlands'
        WHEN 4 THEN 'Docklands community hub'
        WHEN 5 THEN 'Fitzroy rooftop'
        WHEN 6 THEN 'Inner Harbour terminal'
        ELSE 'Regional depot'
    END,
    printf('OPS/2025/%04d', 2100 + id),
    CASE id % 7
        WHEN 0 THEN 'Waiting on the morning field report.'
        WHEN 1 THEN 'Owner confirmed the revised scope.'
        WHEN 2 THEN 'Include in Thursday''s operations review.'
        WHEN 3 THEN 'A short public notice will be required.'
        WHEN 4 THEN 'Parts are reserved at the regional depot.'
        WHEN 5 THEN 'Budget check complete.'
        ELSE 'No blockers reported.'
    END
FROM task_number;
