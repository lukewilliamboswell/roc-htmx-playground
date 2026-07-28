-- Feature-specific CRM fixtures are added alongside their implementation.
--
-- The legacy playground rows currently remain in init.sql because the hidden
-- demo routes still exercise them. They will disappear with those routes.
PRAGMA user_version = 1;

INSERT INTO companies (
    company_id,
    workspace_id,
    name,
    normalized_name,
    owner_id,
    lifecycle_status,
    website,
    website_domain,
    phone,
    normalized_phone,
    source_id,
    context,
    created_by_id,
    updated_by_id,
    created_at,
    updated_at,
    archived_at,
    version
) VALUES (
    'company-acme',
    'workspace-example',
    'Acme Studio',
    'acme studio',
    'member-mara',
    'prospect',
    'https://acme.example',
    'acme.example',
    '+61 3 9000 0000',
    '+61390000000',
    'referral',
    'Referred by an existing design client.',
    'member-mara',
    'member-mara',
    '2026-07-20T09:00:00Z',
    '2026-07-27T06:30:00Z',
    '',
    1
);

INSERT INTO company_revisions (
    company_id,
    version,
    name,
    owner_id,
    lifecycle_status,
    website,
    phone,
    source_id,
    context,
    changed_by_id,
    changed_at
) SELECT
    company_id,
    version,
    name,
    owner_id,
    lifecycle_status,
    website,
    phone,
    source_id,
    context,
    created_by_id,
    created_at
FROM companies;
