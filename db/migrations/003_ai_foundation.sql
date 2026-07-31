CREATE TABLE ai_action_grants (
    grant_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    feature_id TEXT NOT NULL,
    issued_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    consumed_at INTEGER NULL,
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

CREATE INDEX ai_action_grants_expiry
    ON ai_action_grants(expires_at);

CREATE TABLE ai_runs (
    run_id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    feature_id TEXT NOT NULL,
    prompt_id TEXT NOT NULL,
    release_id TEXT NOT NULL,
    provider TEXT NOT NULL,
    requested_model TEXT NOT NULL,
    returned_model TEXT NOT NULL DEFAULT '',
    provider_request_id TEXT NOT NULL DEFAULT '',
    submitted_at INTEGER NOT NULL,
    provider_started_at INTEGER NULL,
    finished_at INTEGER NULL,
    duration_millis INTEGER NULL,
    input_bytes INTEGER NOT NULL DEFAULT 0,
    state TEXT NOT NULL CHECK(state IN ('submitted', 'in_flight', 'succeeded', 'failed', 'rejected', 'abandoned')),
    outcome_code TEXT NOT NULL DEFAULT '',
    provider_status INTEGER NULL,
    prompt_tokens INTEGER NULL,
    completion_tokens INTEGER NULL,
    total_tokens INTEGER NULL,
    reasoning_tokens INTEGER NULL,
    cached_tokens INTEGER NULL,
    cost_credits_nanos INTEGER NULL,
    quality_score_permille INTEGER NULL,
    accepted_at INTEGER NULL,
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

CREATE INDEX ai_runs_feature_time
    ON ai_runs(feature_id, submitted_at);
CREATE INDEX ai_runs_member_time
    ON ai_runs(member_id, submitted_at);
CREATE INDEX ai_runs_state
    ON ai_runs(workspace_id, state, provider_started_at);

PRAGMA user_version = 3;
