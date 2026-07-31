import pf.Sqlite
import pf.UnixTime

import Member
import Workspace

AiStore :: { db : Sqlite.Db }.{
	new : Sqlite.Db -> AiStore
	new = |db| AiStore.{ db }

	Claim := {
		runId : Str,
	}

	ClaimError(err) := [
		InvalidGrant,
		StoreFailure(err),
	]

	BeginError(err) := [
		MemberRateLimited,
		MemberBusy,
		WorkspaceBusy,
		StoreFailure(err),
	]

	Usage := {
		promptTokens : I64,
		completionTokens : I64,
		totalTokens : I64,
		reasoningTokens : I64,
		cachedTokens : I64,
		costCreditsNanos : I64,
	}

	issue_grant! : AiStore, Workspace.Id, Member.Id, Str => Try(Str, Sqlite.QueryError)
	issue_grant! = |store, workspace_id, member_id, feature_id| {
		now = now_millis!()
		row : { id : Str }
		row = Sqlite.query!({
			db: store.db,
			query: (
				\\INSERT INTO ai_action_grants (
				\\ grant_id, workspace_id, member_id, feature_id,
				\\ issued_at, expires_at, consumed_at
				\\) VALUES (
				\\ 'grant-' || lower(hex(randomblob(24))), :workspaceId,
				\\ :memberId, :featureId, :now, :expiresAt, NULL
				\\) RETURNING grant_id AS id;
				,
			),
			params: {
				workspaceId: workspace_id.to_str(),
				memberId: member_id.to_str(),
				featureId: feature_id,
				now,
				expiresAt: now + 600_000,
			},
			limits: Sqlite.default_query_limits,
		})?
		Sqlite.execute!({
			db: store.db,
			query: "DELETE FROM ai_action_grants WHERE expires_at < :cutoff;",
			params: { cutoff: now - 86_400_000 },
		})?
		Ok(row.id)
	}

	claim! : AiStore, Workspace.Id, Member.Id, Str, Str, Str, Str, Str, I64 => Try(Claim, ClaimError(Sqlite.QueryError))
	claim! = |store, workspace_id, member_id, feature_id, prompt_id, release_id, model, grant_id, input_bytes| {
		now = now_millis!()
		transaction = Sqlite.begin!(store.db, Immediate)
			? ClaimError.StoreFailure
		claimed : List({ id : Str })
		claimed = Sqlite.Transaction.query_many!(
			transaction,
			{
				query: (
					\\UPDATE ai_action_grants
					\\SET consumed_at = :now
					\\WHERE grant_id = :grantId
					\\  AND workspace_id = :workspaceId
					\\  AND member_id = :memberId
					\\  AND feature_id = :featureId
					\\  AND consumed_at IS NULL
					\\  AND issued_at <= :now
					\\  AND expires_at >= :now
					\\RETURNING grant_id AS id;
					,
				),
				params: {
					grantId: grant_id,
					workspaceId: workspace_id.to_str(),
					memberId: member_id.to_str(),
					featureId: feature_id,
					now,
				},
				limits: Sqlite.default_query_limits,
			},
		) ? |error| {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			ClaimError.StoreFailure(error)
		}
		if claimed.is_empty() {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			return Err(ClaimError.InvalidGrant)
		}
		run : { id : Str }
		run = Sqlite.Transaction.query!(
			transaction,
			{
				query: (
					\\INSERT INTO ai_runs (
					\\ run_id, workspace_id, member_id, feature_id, prompt_id,
					\\ release_id, provider, requested_model, submitted_at,
					\\ input_bytes, state, outcome_code
					\\) VALUES (
					\\ 'ai-run-' || lower(hex(randomblob(16))), :workspaceId,
					\\ :memberId, :featureId, :promptId, :releaseId,
					\\ 'openrouter', :model, :now, :inputBytes,
					\\ 'submitted', ''
					\\) RETURNING run_id AS id;
					,
				),
				params: {
					workspaceId: workspace_id.to_str(),
					memberId: member_id.to_str(),
					featureId: feature_id,
					promptId: prompt_id,
					releaseId: release_id,
					model,
					now,
					inputBytes: input_bytes,
				},
				limits: Sqlite.default_query_limits,
			},
		) ? |error| {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			ClaimError.StoreFailure(error)
		}
		Sqlite.Transaction.commit!(transaction)
			? ClaimError.StoreFailure
		Ok(Claim.{ runId: run.id })
	}

	begin_provider! : AiStore, Workspace.Id, Member.Id, Str => Try({}, BeginError(Sqlite.QueryError))
	begin_provider! = |store, workspace_id, member_id, run_id| {
		now = now_millis!()
		transaction = Sqlite.begin!(store.db, Immediate)
			? BeginError.StoreFailure
		Sqlite.Transaction.execute!(
			transaction,
			{
				query: (
					\\UPDATE ai_runs SET
					\\ state = 'abandoned', outcome_code = 'process_abandoned',
					\\ finished_at = :now,
					\\ duration_millis = :now - provider_started_at
					\\WHERE workspace_id = :workspaceId
					\\  AND state = 'in_flight'
					\\  AND provider_started_at < :staleBefore;
					,
				),
				params: {
					now,
					workspaceId: workspace_id.to_str(),
					staleBefore: now - 90_000,
				},
			},
		) ? |error| {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			BeginError.StoreFailure(error)
		}
		member_hour : { countValue : I64 }
		member_hour = Sqlite.Transaction.query!(
			transaction,
			{
				query: "SELECT COUNT(*) AS countValue FROM ai_runs WHERE member_id = :memberId AND provider_started_at >= :since;",
				params: {
					memberId: member_id.to_str(),
					since: now - 3_600_000,
				},
				limits: Sqlite.default_query_limits,
			},
		) ? |error| {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			BeginError.StoreFailure(error)
		}
		member_active : { countValue : I64 }
		member_active = Sqlite.Transaction.query!(
			transaction,
			{
				query: "SELECT COUNT(*) AS countValue FROM ai_runs WHERE member_id = :memberId AND state = 'in_flight';",
				params: { memberId: member_id.to_str() },
				limits: Sqlite.default_query_limits,
			},
		) ? |error| {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			BeginError.StoreFailure(error)
		}
		workspace_active : { countValue : I64 }
		workspace_active = Sqlite.Transaction.query!(
			transaction,
			{
				query: "SELECT COUNT(*) AS countValue FROM ai_runs WHERE workspace_id = :workspaceId AND state = 'in_flight';",
				params: { workspaceId: workspace_id.to_str() },
				limits: Sqlite.default_query_limits,
			},
		) ? |error| {
			Sqlite.Transaction.rollback!(transaction) ?? {}
			BeginError.StoreFailure(error)
		}
		limit_error = if member_hour.countValue >= 30 {
			Some((BeginError.MemberRateLimited, "member_rate_limited"))
		} else if member_active.countValue >= 1 {
			Some((BeginError.MemberBusy, "member_busy"))
		} else if workspace_active.countValue >= 3 {
			Some((BeginError.WorkspaceBusy, "workspace_busy"))
		} else {
			None
		}
		match limit_error {
			Some((error, outcome)) => {
				Sqlite.Transaction.execute!(
					transaction,
					{
						query: "UPDATE ai_runs SET state = 'rejected', outcome_code = :outcome, finished_at = :now WHERE run_id = :runId AND state = 'submitted';",
						params: { outcome, now, runId: run_id },
					},
				) ? |store_error| {
					Sqlite.Transaction.rollback!(transaction) ?? {}
					BeginError.StoreFailure(store_error)
				}
				Sqlite.Transaction.commit!(transaction)
					? BeginError.StoreFailure
				Err(error)
			}
			None => {
				Sqlite.Transaction.execute!(
					transaction,
					{
						query: "UPDATE ai_runs SET state = 'in_flight', provider_started_at = :now WHERE run_id = :runId AND state = 'submitted';",
						params: { now, runId: run_id },
					},
				) ? |error| {
					Sqlite.Transaction.rollback!(transaction) ?? {}
					BeginError.StoreFailure(error)
				}
				Sqlite.Transaction.commit!(transaction)
					? BeginError.StoreFailure
				Ok({})
			}
		}
	}

	reject! : AiStore, Str, Str => Try({}, Sqlite.QueryError)
	reject! = |store, run_id, outcome| {
		now = now_millis!()
		Sqlite.execute!({
			db: store.db,
			query: "UPDATE ai_runs SET state = 'rejected', outcome_code = :outcome, finished_at = :now WHERE run_id = :runId AND state = 'submitted';",
			params: { outcome: bounded_outcome(outcome), now, runId: run_id },
		})
	}

	fail! : AiStore, Str, Str, I64 => Try({}, Sqlite.QueryError)
	fail! = |store, run_id, outcome, provider_status| {
		now = now_millis!()
		Sqlite.execute!({
			db: store.db,
			query: (
				\\UPDATE ai_runs SET state = 'failed', outcome_code = :outcome,
				\\ provider_status = NULLIF(:providerStatus, 0),
				\\ finished_at = :now,
				\\ duration_millis = :now - provider_started_at
				\\WHERE run_id = :runId AND state = 'in_flight';
				,
			),
			params: {
				outcome: bounded_outcome(outcome),
				providerStatus: provider_status,
				now,
				runId: run_id,
			},
		})
	}

	succeed! : AiStore, Str, Str, Str, Usage, I64 => Try({}, Sqlite.QueryError)
	succeed! = |store, run_id, returned_model, provider_request_id, usage, quality_score| {
		now = now_millis!()
		Sqlite.execute!({
			db: store.db,
			query: (
				\\UPDATE ai_runs SET state = 'succeeded', outcome_code = 'success',
				\\ returned_model = :returnedModel,
				\\ provider_request_id = :providerRequestId,
				\\ finished_at = :now,
				\\ duration_millis = :now - provider_started_at,
				\\ prompt_tokens = NULLIF(:promptTokens, -1),
				\\ completion_tokens = NULLIF(:completionTokens, -1),
				\\ total_tokens = NULLIF(:totalTokens, -1),
				\\ reasoning_tokens = NULLIF(:reasoningTokens, -1),
				\\ cached_tokens = NULLIF(:cachedTokens, -1),
				\\ cost_credits_nanos = NULLIF(:costCreditsNanos, -1),
				\\ quality_score_permille = :qualityScore
				\\WHERE run_id = :runId AND state = 'in_flight';
				,
			),
			params: {
				returnedModel: returned_model,
				providerRequestId: provider_request_id,
				now,
				promptTokens: usage.promptTokens,
				completionTokens: usage.completionTokens,
				totalTokens: usage.totalTokens,
				reasoningTokens: usage.reasoningTokens,
				cachedTokens: usage.cachedTokens,
				costCreditsNanos: usage.costCreditsNanos,
				qualityScore: quality_score,
				runId: run_id,
			},
		})
	}

	mark_accepted! : AiStore, Workspace.Id, Member.Id, Str => Try({}, Sqlite.QueryError)
	mark_accepted! = |store, workspace_id, member_id, run_id| {
		now = now_millis!()
		Sqlite.execute!({
			db: store.db,
			query: "UPDATE ai_runs SET accepted_at = :now WHERE run_id = :runId AND workspace_id = :workspaceId AND member_id = :memberId AND state = 'succeeded' AND accepted_at IS NULL;",
			params: {
				now,
				runId: run_id,
				workspaceId: workspace_id.to_str(),
				memberId: member_id.to_str(),
			},
		})
	}

	now_millis! : () => I64
	now_millis! = || {
		now = UnixTime.now!()
		now.seconds_since_epoch() * 1000
			+ (now.subsecond_nanoseconds() // 1_000_000).to_i64()
	}
}

bounded_outcome : Str -> Str
bounded_outcome = |value|
	Str.from_utf8_lossy(value.trim().to_utf8().take_first(80))
