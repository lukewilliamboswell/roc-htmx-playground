package CRMVerification {
    doc /* Verification cases connect implemented requirements and controls to executable or inspectable evidence. */

    private import CRMRequirements::CRM::*;
    private import CRMRequirements::AI::BusinessCardScanning::*;
    private import CRMRiskAndControls::Controls::*;
    private import CRMArchitecture::*;

    verification def <'VER-001'> SourceTypeAndUnitVerification {
        doc /* Method: automated test
Command: roc scripts/tasks.roc check
Evidence: ci/check_source_contracts.sh
Evidence: src/main.roc
Evidence: src/Route.roc
Evidence: src/Http.roc
Evidence: src/Design.roc
Selector: expect
The Roc compiler, pure expectations, formatting, and source contracts protect typed architectural boundaries. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRequirements::CRM::PersonCapture;
            verify CRMRequirements::CRM::PersonContactMethods;
            verify CRMRequirements::CRM::CompanyCapture;
            verify CRMRequirements::CRM::OptionalCompanyAssociation;
            verify CRMRequirements::CRM::RelationshipLifecycle;
            verify CRMRiskAndControls::Controls::TypedExternalBoundaries;
            verify CRMRiskAndControls::Controls::PinnedVerifiedToolchain;
        }
    }

    verification def <'VER-002'> FreshSQLIntegrationVerification {
        doc /* Method: automated test
Command: roc scripts/tasks.roc check
Evidence: src/test.roc
Selector: migration failed
The integration suite creates a database from every migration and exercises stores, handlers, and rendered HTML in development and optimized compiler modes. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRequirements::CRM::CoherentRecordDetail;
            verify CRMRequirements::CRM::DuplicateReview;
            verify CRMRequirements::CRM::FollowUpTaskCreation;
            verify CRMRequirements::CRM::InContextTaskCompletion;
            verify CRMRequirements::CRM::WorkspaceWorkBuckets;
            verify CRMRequirements::CRM::ImmediateTaskVisibility;
            verify CRMRequirements::CRM::ImplementedSearch;
            verify CRMRequirements::CRM::IndividualOwnership;
            verify CRMRequirements::CRM::AttributionAndHistory;
            verify CRMRequirements::CRM::DeclaredWorkspaceTimezone;
            verify CRMRequirements::CRM::RecoverableConcurrentEdits;
            verify CRMRiskAndControls::Controls::PreparedScopedPersistence;
            verify CRMRiskAndControls::Controls::AtomicConstrainedMutations;
            verify CRMRiskAndControls::Controls::OptimisticVersionsAndHistory;
            verify CRMRiskAndControls::Controls::ExplicitDuplicateReview;
            verify CRMRiskAndControls::Controls::WorkspaceTimezoneAgreement;
            verify CRMRiskAndControls::Controls::MigrationBackupAndRollback;
        }
    }

    verification def <'VER-003'> BrowserJourneyVerification {
        doc /* Method: automated test
Command: roc scripts/tasks.roc test-browser
Evidence: tests/crm.spec.js
Evidence: src/AssetVersions.roc
Selector: test(
Playwright exercises visible CRM outcomes, accessible names, responsive navigation, htmx enhancement, and non-JavaScript completion against an isolated database and port. It also recomputes the SHA-256 version of every long-lived browser asset referenced by application pages. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRequirements::CRM::PersonCapture;
            verify CRMRequirements::CRM::PersonContactMethods;
            verify CRMRequirements::CRM::CompanyCapture;
            verify CRMRequirements::CRM::OptionalCompanyAssociation;
            verify CRMRequirements::CRM::RelationshipLifecycle;
            verify CRMRequirements::CRM::CoherentRecordDetail;
            verify CRMRequirements::CRM::DuplicateReview;
            verify CRMRequirements::CRM::FollowUpTaskCreation;
            verify CRMRequirements::CRM::InContextTaskCompletion;
            verify CRMRequirements::CRM::WorkspaceWorkBuckets;
            verify CRMRequirements::CRM::ImmediateTaskVisibility;
            verify CRMRequirements::CRM::ImplementedSearch;
            verify CRMRequirements::CRM::IndividualOwnership;
            verify CRMRequirements::CRM::AttributionAndHistory;
            verify CRMRequirements::CRM::SharedActiveMemberAccess;
            verify CRMRequirements::CRM::RecoverableConcurrentEdits;
            verify CRMRiskAndControls::Controls::ExplicitDuplicateReview;
            verify CRMRiskAndControls::Controls::LayeredIsolatedVerification;
        }
    }

    verification def <'VER-004'> AuthenticationBoundaryVerification {
        doc /* Method: automated test
Command: roc scripts/tasks.roc test-auth
Evidence: tests/dev-auth-smoke.js
Evidence: tests/tailscale-auth-smoke.js
Selector: spoof
Development and production smoke suites verify selectable identities, header stripping, active membership, POST forwarding, and production-origin behavior. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRequirements::CRM::SharedActiveMemberAccess;
            verify CRMRequirements::CRM::ImmediateMembershipEnforcement;
            verify CRMRiskAndControls::Controls::TrustedLoopbackIdentityBoundary;
            verify CRMRiskAndControls::Controls::ActiveMembershipEveryRequest;
            verify CRMRiskAndControls::Controls::OriginAndWorkspaceScoping;
            verify CRMRiskAndControls::Controls::ValidatedSecretConfiguration;
        }
    }

    verification def <'VER-005'> MigrationVerification {
        doc /* Method: automated test
Command: roc scripts/tasks.roc test-e2e
Evidence: tests/migration-smoke.js
Evidence: db/migrations/001_initial.sql
Evidence: db/migrations/002_remove_legacy_auth_and_demos.sql
Evidence: db/migrations/003_ai_foundation.sql
Selector: ai_action_grants
The smoke test upgrades representative data through every immutable migration and checks the resulting schema and preserved records. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRiskAndControls::Controls::MigrationBackupAndRollback;
            verify CRMRiskAndControls::Controls::LayeredIsolatedVerification;
        }
    }

    verification def <'VER-006'> ReleaseAndServiceVerification {
        doc /* Method: automated test and operational demonstration
Command: GitHub Actions Release workflow
Evidence: .github/workflows/release.yml
Evidence: ci/release_id.sh
Evidence: docs/deployment/digitalocean-tailscale.md
Selector: Generate and verify release checksum
The release workflow installs and tests the exact bundle, rehearses backup and activation, checks systemd health, verifies the archive checksum, and tags only after success. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRiskAndControls::Controls::ExactArtifactReleaseVerification;
            verify CRMRiskAndControls::Controls::ValidatedSecretConfiguration;
            verify CRMRiskAndControls::Controls::HardenedObservableService;
            verify CRMRiskAndControls::Controls::MigrationBackupAndRollback;
        }
    }

    verification def <'VER-007'> BusinessCardAIVerification {
        doc /* Method: automated test
Command: roc scripts/tasks.roc test-e2e
Evidence: tests/business-card-smoke.js
Evidence: src/test.roc
Evidence: src/BusinessCardHandler.roc
Evidence: src/AiStore.roc
Selector: business-card scanner security
The AI smoke and integration tests cover feature gating, grants, replay, media validation, rate state, structured responses, safe persistence, and review rendering. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRequirements::AI::BusinessCardScanning::FeatureGating;
            verify CRMRequirements::AI::BusinessCardScanning::BrowserImagePreparation;
            verify CRMRequirements::AI::BusinessCardScanning::ServerInputValidation;
            verify CRMRequirements::AI::BusinessCardScanning::ScopedOneUseGrant;
            verify CRMRequirements::AI::BusinessCardScanning::ResourceLimits;
            verify CRMRequirements::AI::BusinessCardScanning::ProviderPrivacy;
            verify CRMRequirements::AI::BusinessCardScanning::StructuredExtraction;
            verify CRMRequirements::AI::BusinessCardScanning::ReviewBeforeCreate;
            verify CRMRequirements::AI::BusinessCardScanning::MinimalPersistence;
            verify CRMRequirements::AI::BusinessCardScanning::TraceableAndRecoverableRuns;
            verify CRMRiskAndControls::Controls::AIInputPreparationAndValidation;
            verify CRMRiskAndControls::Controls::ScopedOneUseAIGrants;
            verify CRMRiskAndControls::Controls::AIRateAndConcurrencyLimits;
            verify CRMRiskAndControls::Controls::AIPrivacyAndMinimalPersistence;
            verify CRMRiskAndControls::Controls::StrictAIOutputAndHumanReview;
            verify CRMRiskAndControls::Controls::TraceableGracefulAIFailure;
            verify CRMRiskAndControls::Controls::PinnedVerifiedToolchain;
        }
    }

    verification def <'VER-008'> DeploymentControlInspection {
        doc /* Method: inspection and operational demonstration
Command: follow the supported deployment and upgrade procedure
Evidence: docs/deployment/digitalocean-tailscale.md
Selector: Do not use Tailscale Funnel
Operators inspect tailnet policy, firewall exposure, configuration permissions, service hardening, backups, restore readiness, and post-activation health. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRiskAndControls::Controls::TrustedLoopbackIdentityBoundary;
            verify CRMRiskAndControls::Controls::ValidatedSecretConfiguration;
            verify CRMRiskAndControls::Controls::MigrationBackupAndRollback;
            verify CRMRiskAndControls::Controls::HardenedObservableService;
        }
    }

    verification def <'VER-009'> ModelContractVerification {
        doc /* Method: automated analysis
Command: roc scripts/tasks.roc model-check
Evidence: ci/check_model_contracts.py
Evidence: docs/model
Selector: check_contracts
The model gate validates SysML, traceability completeness, evidence references, stable identifiers, and AI capability scope. */
        subject systemUnderTest : EnquiryCRMSystem;
        objective {
            verify CRMRiskAndControls::Controls::LayeredIsolatedVerification;
            verify CRMRiskAndControls::Controls::PinnedVerifiedToolchain;
        }
    }
}
