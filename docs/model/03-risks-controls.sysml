package CRMRiskAndControls {
    doc /* Unified system-risk baseline using ISO/IEC 27005-aligned scenario terminology. */

    private import CRMArchitecture::*;

    item def RiskScenario {
        doc /* A source can cause an event with consequences for an objective or information asset. */
    }

    package Risks {
        item <'RSK-001'> IdentityHeaderSpoofing : RiskScenario {
            doc /* An untrusted caller may impersonate a workspace member.
Source: A client or proxy outside the trusted identity boundary.
Event: A forged or ambiguous Tailscale login header reaches request dispatch.
Consequence: Customer information is disclosed or changed under another member's identity.
Affected objective: Authenticated and attributable CRM access.
Classification: Information security: confidentiality, integrity, and accountability. */
            item source { doc /* A client or proxy outside the trusted identity boundary. */ }
            item event { doc /* A forged or ambiguous Tailscale login header reaches request dispatch. */ }
            item consequence { doc /* Customer information is disclosed or changed under another member's identity. */ }
            item affectedObjective { doc /* Authenticated and attributable CRM access. */ }
            item classification { doc /* Information security: confidentiality, integrity, and accountability. */ }
        }

        item <'RSK-002'> InactiveMemberAccess : RiskScenario {
            doc /* A formerly authorized or unknown identity may continue to use the CRM.
Source: Membership changes or stale authorization assumptions.
Event: A request is accepted without checking current active membership.
Consequence: Customer data remains available after access should have ended.
Affected objective: Immediate enforcement of workspace membership.
Classification: Information security: confidentiality and authorization. */
            item source { doc /* Membership changes or stale authorization assumptions. */ }
            item event { doc /* A request is accepted without checking current active membership. */ }
            item consequence { doc /* Customer data remains available after access should have ended. */ }
            item affectedObjective { doc /* Immediate enforcement of workspace membership. */ }
            item classification { doc /* Information security: confidentiality and authorization. */ }
        }

        item <'RSK-003'> CrossOriginOrWorkspaceMutation : RiskScenario {
            doc /* A mutation may be initiated from the wrong origin or applied outside the actor's workspace.
Source: A malicious site, malformed request, or missing persistence scope.
Event: State-changing input crosses the origin or workspace boundary.
Consequence: Records are exposed, associated, or changed outside their intended scope.
Affected objective: Workspace isolation and intentional member actions.
Classification: Information security: confidentiality and integrity. */
            item source { doc /* A malicious site, malformed request, or missing persistence scope. */ }
            item event { doc /* State-changing input crosses the origin or workspace boundary. */ }
            item consequence { doc /* Records are exposed, associated, or changed outside their intended scope. */ }
            item affectedObjective { doc /* Workspace isolation and intentional member actions. */ }
            item classification { doc /* Information security: confidentiality and integrity. */ }
        }

        item <'RSK-004'> UnintendedPublicExposure : RiskScenario {
            doc /* The application port may become reachable without the trusted tailnet proxy.
Source: Network, firewall, proxy, or deployment misconfiguration.
Event: The service listens publicly or Tailscale Funnel is enabled.
Consequence: Identity headers can no longer be treated as trusted.
Affected objective: Private tailnet-only availability.
Classification: Information security: confidentiality and authorization. */
            item source { doc /* Network, firewall, proxy, or deployment misconfiguration. */ }
            item event { doc /* The service listens publicly or Tailscale Funnel is enabled. */ }
            item consequence { doc /* Identity headers can no longer be treated as trusted. */ }
            item affectedObjective { doc /* Private tailnet-only availability. */ }
            item classification { doc /* Information security: confidentiality and authorization. */ }
        }

        item <'RSK-005'> SecretOrConfigurationFailure : RiskScenario {
            doc /* Provider credentials or invalid runtime assumptions may be exposed or accepted.
Source: Weak file permissions, logs, or malformed configuration.
Event: A secret is disclosed or invalid configuration reaches runtime.
Consequence: Provider abuse, inconsistent behavior, or unsafe startup.
Affected objective: Confidential configuration and fail-fast startup.
Classification: Information security and operational integrity. */
            item source { doc /* Weak file permissions, logs, or malformed configuration. */ }
            item event { doc /* A secret is disclosed or invalid configuration reaches runtime. */ }
            item consequence { doc /* Provider abuse, inconsistent behavior, or unsafe startup. */ }
            item affectedObjective { doc /* Confidential configuration and fail-fast startup. */ }
            item classification { doc /* Information security and operational integrity. */ }
        }

        item <'RSK-006'> InvalidOrPartialMutation : RiskScenario {
            doc /* A failed or malformed write may leave inconsistent related records.
Source: Invalid external values, storage failure, or multi-step mutation.
Event: Only part of a logical change is committed.
Consequence: Records, ownership, history, or tasks disagree.
Affected objective: Valid and atomic business state.
Classification: Data integrity and reliability. */
            item source { doc /* Invalid external values, storage failure, or multi-step mutation. */ }
            item event { doc /* Only part of a logical change is committed. */ }
            item consequence { doc /* Records, ownership, history, or tasks disagree. */ }
            item affectedObjective { doc /* Valid and atomic business state. */ }
            item classification { doc /* Data integrity and reliability. */ }
        }

        item <'RSK-007'> LostConcurrentUpdate : RiskScenario {
            doc /* One member's edit may silently overwrite a newer edit.
Source: Concurrent browser sessions editing the same record version.
Event: A stale write is committed without version comparison.
Consequence: Correct customer information is lost without notice.
Affected objective: Recoverable, visible concurrency conflicts.
Classification: Data integrity and user trust. */
            item source { doc /* Concurrent browser sessions editing the same record version. */ }
            item event { doc /* A stale write is committed without version comparison. */ }
            item consequence { doc /* Correct customer information is lost without notice. */ }
            item affectedObjective { doc /* Recoverable, visible concurrency conflicts. */ }
            item classification { doc /* Data integrity and user trust. */ }
        }

        item <'RSK-008'> DuplicateOrUntraceableHistory : RiskScenario {
            doc /* Ambiguous duplicates or missing attribution may make relationship history unreliable.
Source: Similar sparse records or mutations without append-only attribution.
Event: A duplicate is created unknowingly or a material change cannot be reconstructed.
Consequence: Follow-up fragments and users cannot explain current state.
Affected objective: Coherent customer history and accountability.
Classification: Data integrity and operational quality. */
            item source { doc /* Similar sparse records or mutations without append-only attribution. */ }
            item event { doc /* A duplicate is created unknowingly or a material change cannot be reconstructed. */ }
            item consequence { doc /* Follow-up fragments and users cannot explain current state. */ }
            item affectedObjective { doc /* Coherent customer history and accountability. */ }
            item classification { doc /* Data integrity and operational quality. */ }
        }

        item <'RSK-009'> TimezoneMisclassification : RiskScenario {
            doc /* Work may be placed in different due-date buckets for different environments or members.
Source: Host-local time or mismatched workspace and server timezone.
Event: A due time is converted or grouped against the wrong timezone.
Consequence: Overdue or due-today work is missed.
Affected objective: One shared and predictable work schedule.
Classification: Business correctness and reliability. */
            item source { doc /* Host-local time or mismatched workspace and server timezone. */ }
            item event { doc /* A due time is converted or grouped against the wrong timezone. */ }
            item consequence { doc /* Overdue or due-today work is missed. */ }
            item affectedObjective { doc /* One shared and predictable work schedule. */ }
            item classification { doc /* Business correctness and reliability. */ }
        }

        item <'RSK-010'> MigrationOrRecoveryFailure : RiskScenario {
            doc /* Upgrade or recovery may lose data or leave an incompatible schema.
Source: Migration defect, newer database, incomplete backup, or untested restore.
Event: Activation proceeds without a compatible schema or recoverable database.
Consequence: Service outage, corruption, or irreversible customer-data loss.
Affected objective: Data continuity and recoverable upgrades.
Classification: Availability, integrity, and operations. */
            item source { doc /* Migration defect, newer database, incomplete backup, or untested restore. */ }
            item event { doc /* Activation proceeds without a compatible schema or recoverable database. */ }
            item consequence { doc /* Service outage, corruption, or irreversible customer-data loss. */ }
            item affectedObjective { doc /* Data continuity and recoverable upgrades. */ }
            item classification { doc /* Availability, integrity, and operations. */ }
        }

        item <'RSK-011'> ReleaseArtifactRegression : RiskScenario {
            doc /* The deployed bundle may differ from the source and behavior that passed tests.
Source: Rebuild drift, packaging omission, activation error, or premature tag.
Event: An unverified artifact is released or activated.
Consequence: Production behavior regresses despite a green source build.
Affected objective: Reproducible, tested, and rollback-ready releases.
Classification: Reliability, integrity, and release operations. */
            item source { doc /* Rebuild drift, packaging omission, activation error, or premature tag. */ }
            item event { doc /* An unverified artifact is released or activated. */ }
            item consequence { doc /* Production behavior regresses despite a green source build. */ }
            item affectedObjective { doc /* Reproducible, tested, and rollback-ready releases. */ }
            item classification { doc /* Reliability, integrity, and release operations. */ }
        }

        item <'RSK-012'> UserExperienceRegression : RiskScenario {
            doc /* A change may remove an accessible, responsive, or non-JavaScript path.
Source: Rendering, htmx, design-system, or route changes.
Event: A key user journey becomes unavailable or misleading.
Consequence: Members cannot safely capture or complete work.
Affected objective: Progressive, accessible, behaviorally stable UI.
Classification: Product reliability and accessibility. */
            item source { doc /* Rendering, htmx, design-system, or route changes. */ }
            item event { doc /* A key user journey becomes unavailable or misleading. */ }
            item consequence { doc /* Members cannot safely capture or complete work. */ }
            item affectedObjective { doc /* Progressive, accessible, behaviorally stable UI. */ }
            item classification { doc /* Product reliability and accessibility. */ }
        }

        item <'RSK-013'> TestContamination : RiskScenario {
            doc /* Test outcomes may depend on order, developer data, or an unrelated running server.
Source: Shared databases, ports, fixtures, or persistent process state.
Event: A test observes state left by another test or environment.
Consequence: Regressions are hidden or failures become non-reproducible.
Affected objective: Deterministic and trustworthy verification.
Classification: Quality and regression prevention. */
            item source { doc /* Shared databases, ports, fixtures, or persistent process state. */ }
            item event { doc /* A test observes state left by another test or environment. */ }
            item consequence { doc /* Regressions are hidden or failures become non-reproducible. */ }
            item affectedObjective { doc /* Deterministic and trustworthy verification. */ }
            item classification { doc /* Quality and regression prevention. */ }
        }

        item <'RSK-014'> ToolOrDependencyTampering : RiskScenario {
            doc /* Mutable or substituted build inputs may change generated or executable output.
Source: Upstream releases, package registries, actions, or tool downloads.
Event: An unpinned or checksum-mismatched dependency is executed.
Consequence: CI, generated artifacts, or releases become untrusted.
Affected objective: Reviewable and reproducible supply-chain inputs.
Classification: Information security and supply-chain integrity. */
            item source { doc /* Upstream releases, package registries, actions, or tool downloads. */ }
            item event { doc /* An unpinned or checksum-mismatched dependency is executed. */ }
            item consequence { doc /* CI, generated artifacts, or releases become untrusted. */ }
            item affectedObjective { doc /* Reviewable and reproducible supply-chain inputs. */ }
            item classification { doc /* Information security and supply-chain integrity. */ }
        }

        item <'RSK-015'> UnsafeAIInput : RiskScenario {
            doc /* An unsupported, deceptive, or excessive input may reach image processing or the provider.
Source: Malicious upload, accidental original image, or malformed media.
Event: Input bypasses preparation, type, structure, or size validation.
Consequence: Resource abuse, processing failure, or unintended information disclosure.
Affected objective: Bounded and intentional AI input handling.
Classification: Information security, privacy, and availability. */
            item source { doc /* Malicious upload, accidental original image, or malformed media. */ }
            item event { doc /* Input bypasses preparation, type, structure, or size validation. */ }
            item consequence { doc /* Resource abuse, processing failure, or unintended information disclosure. */ }
            item affectedObjective { doc /* Bounded and intentional AI input handling. */ }
            item classification { doc /* Information security, privacy, and availability. */ }
        }

        item <'RSK-016'> AIInformationDisclosure : RiskScenario {
            doc /* Sensitive image content, contact data, raw output, or credentials may be retained or collected.
Source: Application persistence, logs, provider routing, or provider policy.
Event: Sensitive AI data survives the transient request or is collected by the provider.
Consequence: Personal or secret information leaves its intended lifecycle.
Affected objective: Data minimization and controlled provider processing.
Classification: Information security and privacy. */
            item source { doc /* Application persistence, logs, provider routing, or provider policy. */ }
            item event { doc /* Sensitive AI data survives the transient request or is collected by the provider. */ }
            item consequence { doc /* Personal or secret information leaves its intended lifecycle. */ }
            item affectedObjective { doc /* Data minimization and controlled provider processing. */ }
            item classification { doc /* Information security and privacy. */ }
        }

        item <'RSK-017'> AIGrantOrResourceAbuse : RiskScenario {
            doc /* A scan authorization may be replayed, crossed between scopes, or used to exhaust provider capacity.
Source: Captured grants or repeated concurrent requests.
Event: The system accepts replay, cross-member use, or unbounded work.
Consequence: Unauthorized disclosure, provider cost, or degraded availability.
Affected objective: Scoped, one-use, and bounded AI actions.
Classification: Information security and availability. */
            item source { doc /* Captured grants or repeated concurrent requests. */ }
            item event { doc /* The system accepts replay, cross-member use, or unbounded work. */ }
            item consequence { doc /* Unauthorized disclosure, provider cost, or degraded availability. */ }
            item affectedObjective { doc /* Scoped, one-use, and bounded AI actions. */ }
            item classification { doc /* Information security and availability. */ }
        }

        item <'RSK-018'> IncorrectAIMutation : RiskScenario {
            doc /* Incorrect extraction may be treated as authoritative customer data.
Source: Probabilistic or malformed provider output.
Event: Extracted values bypass strict decoding or member review.
Consequence: Incorrect contact data is persisted and acted upon.
Affected objective: Validated, human-approved CRM mutations.
Classification: Data integrity and product correctness. */
            item source { doc /* Probabilistic or malformed provider output. */ }
            item event { doc /* Extracted values bypass strict decoding or member review. */ }
            item consequence { doc /* Incorrect contact data is persisted and acted upon. */ }
            item affectedObjective { doc /* Validated, human-approved CRM mutations. */ }
            item classification { doc /* Data integrity and product correctness. */ }
        }

        item <'RSK-019'> AIProviderOrModelDrift : RiskScenario {
            doc /* Provider failure or changing prompts, models, and releases may make outcomes unavailable or unexplained.
Source: External service failure or untraceable AI configuration change.
Event: A scan fails or its behavior cannot be tied to reviewed inputs.
Consequence: Members lose the optional capability or cannot diagnose a regression.
Affected objective: Graceful degradation and traceable AI behavior.
Classification: Reliability, operations, and change control. */
            item source { doc /* External service failure or untraceable AI configuration change. */ }
            item event { doc /* A scan fails or its behavior cannot be tied to reviewed inputs. */ }
            item consequence { doc /* Members lose the optional capability or cannot diagnose a regression. */ }
            item affectedObjective { doc /* Graceful degradation and traceable AI behavior. */ }
            item classification { doc /* Reliability, operations, and change control. */ }
        }

        item <'RSK-020'> ServiceAvailabilityFailure : RiskScenario {
            doc /* A failed process, unhealthy activation, or unavailable database may interrupt relationship work.
Source: Runtime crash, service configuration, storage, or deployment failure.
Event: The application becomes unhealthy or cannot restart safely.
Consequence: Members cannot access customer context or follow-up work.
Affected objective: Observable, restartable, and recoverable service.
Classification: Availability and operations. */
            item source { doc /* Runtime crash, service configuration, storage, or deployment failure. */ }
            item event { doc /* The application becomes unhealthy or cannot restart safely. */ }
            item consequence { doc /* Members cannot access customer context or follow-up work. */ }
            item affectedObjective { doc /* Observable, restartable, and recoverable service. */ }
            item classification { doc /* Availability and operations. */ }
        }
    }

    package Controls {
        requirement def <'CTL-001'> TrustedLoopbackIdentityBoundary {
            subject system : EnquiryCRMSystem;
            doc /* Bind on loopback and accept identity only from Tailscale Serve or the stripping development proxy; never use Funnel. */
            require constraint { doc /* Exactly one normalized identity header reaches active-member resolution. */ }
        }

        requirement def <'CTL-002'> ActiveMembershipEveryRequest {
            subject system : EnquiryCRMSystem;
            doc /* Resolve every non-health request against the current active member table. */
            require constraint { doc /* The application has no authorization-bearing cookie session. */ }
        }

        requirement def <'CTL-003'> OriginAndWorkspaceScoping {
            subject system : EnquiryCRMSystem;
            doc /* Reject cross-origin mutations and bind persistence operations to the actor's workspace. */
            require constraint { doc /* Identifiers alone cannot cross the workspace boundary. */ }
        }

        requirement def <'CTL-004'> TypedExternalBoundaries {
            subject system : EnquiryCRMSystem;
            doc /* Parse routes and external strings before validated domain values reach business decisions. */
            require constraint { doc /* Views generate URLs from the closed route vocabulary. */ }
        }

        requirement def <'CTL-005'> PreparedScopedPersistence {
            subject system : EnquiryCRMSystem;
            doc /* Stores own prepared SQL, storage conversion, and explicit workspace constraints. */
            require constraint { doc /* Handlers and views do not construct SQL. */ }
        }

        requirement def <'CTL-006'> AtomicConstrainedMutations {
            subject system : EnquiryCRMSystem;
            doc /* Use SQLite constraints and immediate transactions for multi-record business mutations. */
            require constraint { doc /* Failure rolls back the complete logical change. */ }
        }

        requirement def <'CTL-007'> OptimisticVersionsAndHistory {
            subject system : EnquiryCRMSystem;
            doc /* Compare submitted record versions and retain attributable revisions or activity history. */
            require constraint { doc /* Stale writes return recoverable conflict information. */ }
        }

        requirement def <'CTL-008'> ExplicitDuplicateReview {
            subject system : EnquiryCRMSystem;
            doc /* Rank likely duplicates and require an explicit distinct-record decision. */
            require constraint { doc /* Similarity never triggers an automatic merge. */ }
        }

        requirement def <'CTL-009'> WorkspaceTimezoneAgreement {
            subject system : EnquiryCRMSystem;
            doc /* Require configured and stored workspace timezones to match before serving requests. */
            require constraint { doc /* Work buckets use that timezone rather than host-local defaults. */ }
        }

        requirement def <'CTL-010'> MigrationBackupAndRollback {
            subject system : EnquiryCRMSystem;
            doc /* Apply ordered immutable migrations, reject newer schemas, verify backups, and rehearse rollback. */
            require constraint { doc /* Activation proceeds only with a checked schema and recoverable prior database. */ }
        }

        requirement def <'CTL-011'> LayeredIsolatedVerification {
            subject system : EnquiryCRMSystem;
            doc /* Combine source contracts, types, pure tests, fresh-SQL integration, browser journeys, and boundary smoke tests. */
            require constraint { doc /* Browser and integration suites use disposable isolated databases and owned ports. */ }
        }

        requirement def <'CTL-012'> ExactArtifactReleaseVerification {
            subject system : EnquiryCRMSystem;
            doc /* Install and test the exact release bundle before checksum publication and Git tagging. */
            require constraint { doc /* Release identity is derived from immutable commit information. */ }
        }

        requirement def <'CTL-013'> PinnedVerifiedToolchain {
            subject system : EnquiryCRMSystem;
            doc /* Pin external actions and tools and verify downloaded standalone binaries by SHA-256. */
            require constraint { doc /* Checksum mismatch prevents execution. */ }
        }

        requirement def <'CTL-014'> ValidatedSecretConfiguration {
            subject system : EnquiryCRMSystem;
            doc /* Load one versioned configuration at startup, protect it as a service credential, and omit disabled features. */
            require constraint { doc /* Secrets are neither committed nor rendered. */ }
        }

        requirement def <'CTL-015'> AIInputPreparationAndValidation {
            subject scanner : BusinessCardScanner;
            doc /* Strip metadata and resize in-browser, then enforce same-origin JPEG structure and byte limits on the server. */
            require constraint { doc /* The provider call follows all input checks. */ }
        }

        requirement def <'CTL-016'> ScopedOneUseAIGrants {
            subject scanner : BusinessCardScanner;
            doc /* Issue short-lived, one-use member/workspace/feature grants and claim them transactionally. */
            require constraint { doc /* Rejected requests receive a fresh grant rather than reusing a consumed one. */ }
        }

        requirement def <'CTL-017'> AIRateAndConcurrencyLimits {
            subject scanner : BusinessCardScanner;
            doc /* Enforce per-member hourly limits and member/workspace concurrent-run limits. */
            require constraint { doc /* Limit decisions are stored with the run claim. */ }
        }

        requirement def <'CTL-018'> AIPrivacyAndMinimalPersistence {
            subject scanner : BusinessCardScanner;
            doc /* Require zero provider retention, deny data collection, and persist no image, extracted contact, raw response, or credential. */
            require constraint { doc /* Only bounded operational metadata and trace identifiers remain. */ }
        }

        requirement def <'CTL-019'> StrictAIOutputAndHumanReview {
            subject scanner : BusinessCardScanner;
            doc /* Decode a strict bounded schema and require normal form review and validation before creating a person. */
            require constraint { doc /* Provider output has no direct persistence path. */ }
        }

        requirement def <'CTL-020'> TraceableGracefulAIFailure {
            subject scanner : BusinessCardScanner;
            doc /* Embed prompts and schema in the release, record prompt/model/release IDs, and return safe recoverable errors. */
            require constraint { doc /* Provider failure does not prevent ordinary person entry. */ }
        }

        requirement def <'CTL-021'> HardenedObservableService {
            subject system : EnquiryCRMSystem;
            doc /* Run under systemd hardening, verify health after activation, and retain a tested restart and rollback path. */
            require constraint { doc /* Service failure is visible before a release is accepted. */ }
        }

        satisfy TrustedLoopbackIdentityBoundary by enquiryCrm.identity;
        satisfy ActiveMembershipEveryRequest by enquiryCrm.identity;
        satisfy OriginAndWorkspaceScoping by enquiryCrm.handler;
        satisfy TypedExternalBoundaries by enquiryCrm.route;
        satisfy PreparedScopedPersistence by enquiryCrm.store;
        satisfy AtomicConstrainedMutations by enquiryCrm.store;
        satisfy OptimisticVersionsAndHistory by enquiryCrm.store;
        satisfy ExplicitDuplicateReview by enquiryCrm.domain;
        satisfy WorkspaceTimezoneAgreement by enquiryCrm.configuration;
        satisfy MigrationBackupAndRollback by enquiryCrm.administration;
        satisfy LayeredIsolatedVerification by enquiryCrm;
        satisfy ExactArtifactReleaseVerification by production;
        satisfy PinnedVerifiedToolchain by enquiryCrm;
        satisfy ValidatedSecretConfiguration by enquiryCrm.configuration;
        satisfy AIInputPreparationAndValidation by enquiryCrm.businessCardScanner;
        satisfy ScopedOneUseAIGrants by enquiryCrm.businessCardScanner;
        satisfy AIRateAndConcurrencyLimits by enquiryCrm.businessCardScanner;
        satisfy AIPrivacyAndMinimalPersistence by enquiryCrm.businessCardScanner;
        satisfy StrictAIOutputAndHumanReview by enquiryCrm.businessCardScanner;
        satisfy TraceableGracefulAIFailure by enquiryCrm.businessCardScanner;
        satisfy HardenedObservableService by production;

        dependency satisfies_CTL_001 from TrustedIdentityAdapter to TrustedLoopbackIdentityBoundary;
        dependency satisfies_CTL_002 from TrustedIdentityAdapter to ActiveMembershipEveryRequest;
        dependency satisfies_CTL_003 from HandlerLayer to OriginAndWorkspaceScoping;
        dependency satisfies_CTL_004 from RouteLayer to TypedExternalBoundaries;
        dependency satisfies_CTL_005 from StoreLayer to PreparedScopedPersistence;
        dependency satisfies_CTL_006 from StoreLayer to AtomicConstrainedMutations;
        dependency satisfies_CTL_007 from StoreLayer to OptimisticVersionsAndHistory;
        dependency satisfies_CTL_008 from DomainLayer to ExplicitDuplicateReview;
        dependency satisfies_CTL_009 from ConfigurationLoader to WorkspaceTimezoneAgreement;
        dependency satisfies_CTL_010 from AdminExecutable to MigrationBackupAndRollback;
        dependency satisfies_CTL_011 from EnquiryCRMSystem to LayeredIsolatedVerification;
        dependency satisfies_CTL_012 from ProductionDeployment to ExactArtifactReleaseVerification;
        dependency satisfies_CTL_013 from EnquiryCRMSystem to PinnedVerifiedToolchain;
        dependency satisfies_CTL_014 from ConfigurationLoader to ValidatedSecretConfiguration;
        dependency satisfies_CTL_015 from BusinessCardScanner to AIInputPreparationAndValidation;
        dependency satisfies_CTL_016 from BusinessCardScanner to ScopedOneUseAIGrants;
        dependency satisfies_CTL_017 from BusinessCardScanner to AIRateAndConcurrencyLimits;
        dependency satisfies_CTL_018 from BusinessCardScanner to AIPrivacyAndMinimalPersistence;
        dependency satisfies_CTL_019 from BusinessCardScanner to StrictAIOutputAndHumanReview;
        dependency satisfies_CTL_020 from BusinessCardScanner to TraceableGracefulAIFailure;
        dependency satisfies_CTL_021 from ProductionDeployment to HardenedObservableService;
    }

    private import Risks::*;
    private import Controls::*;

    dependency modifies_CTL_001_RSK_001 from TrustedLoopbackIdentityBoundary to IdentityHeaderSpoofing;
    dependency modifies_CTL_002_RSK_001 from ActiveMembershipEveryRequest to IdentityHeaderSpoofing;
    dependency modifies_CTL_002_RSK_002 from ActiveMembershipEveryRequest to InactiveMemberAccess;
    dependency modifies_CTL_003_RSK_003 from OriginAndWorkspaceScoping to CrossOriginOrWorkspaceMutation;
    dependency modifies_CTL_005_RSK_003 from PreparedScopedPersistence to CrossOriginOrWorkspaceMutation;
    dependency modifies_CTL_001_RSK_004 from TrustedLoopbackIdentityBoundary to UnintendedPublicExposure;
    dependency modifies_CTL_014_RSK_005 from ValidatedSecretConfiguration to SecretOrConfigurationFailure;
    dependency modifies_CTL_004_RSK_006 from TypedExternalBoundaries to InvalidOrPartialMutation;
    dependency modifies_CTL_006_RSK_006 from AtomicConstrainedMutations to InvalidOrPartialMutation;
    dependency modifies_CTL_007_RSK_007 from OptimisticVersionsAndHistory to LostConcurrentUpdate;
    dependency modifies_CTL_008_RSK_008 from ExplicitDuplicateReview to DuplicateOrUntraceableHistory;
    dependency modifies_CTL_007_RSK_008 from OptimisticVersionsAndHistory to DuplicateOrUntraceableHistory;
    dependency modifies_CTL_009_RSK_009 from WorkspaceTimezoneAgreement to TimezoneMisclassification;
    dependency modifies_CTL_010_RSK_010 from MigrationBackupAndRollback to MigrationOrRecoveryFailure;
    dependency modifies_CTL_012_RSK_011 from ExactArtifactReleaseVerification to ReleaseArtifactRegression;
    dependency modifies_CTL_011_RSK_011 from LayeredIsolatedVerification to ReleaseArtifactRegression;
    dependency modifies_CTL_011_RSK_012 from LayeredIsolatedVerification to UserExperienceRegression;
    dependency modifies_CTL_011_RSK_013 from LayeredIsolatedVerification to TestContamination;
    dependency modifies_CTL_013_RSK_014 from PinnedVerifiedToolchain to ToolOrDependencyTampering;
    dependency modifies_CTL_015_RSK_015 from AIInputPreparationAndValidation to UnsafeAIInput;
    dependency modifies_CTL_018_RSK_016 from AIPrivacyAndMinimalPersistence to AIInformationDisclosure;
    dependency modifies_CTL_014_RSK_016 from ValidatedSecretConfiguration to AIInformationDisclosure;
    dependency modifies_CTL_016_RSK_017 from ScopedOneUseAIGrants to AIGrantOrResourceAbuse;
    dependency modifies_CTL_017_RSK_017 from AIRateAndConcurrencyLimits to AIGrantOrResourceAbuse;
    dependency modifies_CTL_019_RSK_018 from StrictAIOutputAndHumanReview to IncorrectAIMutation;
    dependency modifies_CTL_020_RSK_019 from TraceableGracefulAIFailure to AIProviderOrModelDrift;
    dependency modifies_CTL_021_RSK_020 from HardenedObservableService to ServiceAvailabilityFailure;
    dependency modifies_CTL_010_RSK_020 from MigrationBackupAndRollback to ServiceAvailabilityFailure;
}
