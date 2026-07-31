package CRMRequirements {
    doc /* Implemented as-built requirements only. Target-state requirements remain in docs/roadmap. */

    private import CRMArchitecture::*;

    package CRM {
        requirement def <'CRM-001'> PersonCapture {
            subject system : EnquiryCRMSystem;
            doc /* An active member can create, view, and update a person from a name, with optional contact details and system-supplied ownership, lifecycle, authorship, and timestamps. */
            require constraint { doc /* Person input crosses validated domain boundaries before persistence. */ }
        }

        requirement def <'CRM-002'> PersonContactMethods {
            subject system : EnquiryCRMSystem;
            doc /* A person can have labelled emails and phone numbers, with at most one primary value of each kind. */
            require constraint { doc /* Contact-method labels and primary selection remain consistent. */ }
        }

        requirement def <'CRM-003'> CompanyCapture {
            subject system : EnquiryCRMSystem;
            doc /* An active member can create, search, view, and update a company and associate people with it. */
            require constraint { doc /* Company names preserve display form while supporting normalized search. */ }
        }

        requirement def <'CRM-004'> OptionalCompanyAssociation {
            subject system : EnquiryCRMSystem;
            doc /* A person can exist independently and can later be associated with a company. */
            require constraint { doc /* Association changes do not rewrite prior task or activity history. */ }
        }

        requirement def <'CRM-005'> RelationshipLifecycle {
            subject system : EnquiryCRMSystem;
            doc /* People and companies expose the implemented lifecycle states without replacement records. */
            require constraint { doc /* Lifecycle changes are validated and attributable. */ }
        }

        requirement def <'CRM-006'> CoherentRecordDetail {
            subject system : EnquiryCRMSystem;
            doc /* Current record pages show contact details, owner, status, associated people, open tasks, and recorded owner or status history. */
            require constraint { doc /* Only currently implemented record relationships are claimed. */ }
        }

        requirement def <'CRM-007'> DuplicateReview {
            subject system : EnquiryCRMSystem;
            doc /* Likely existing people or companies are ranked before creation and the member explicitly confirms a distinct record. */
            require constraint { doc /* Similar names alone never force an automatic merge. */ }
        }

        requirement def <'CRM-019'> FollowUpTaskCreation {
            subject system : EnquiryCRMSystem;
            doc /* A member can create a related follow-up task with subject, due time, assignee, and company or person context. */
            require constraint { doc /* Newly created open work is immediately visible to its assignee. */ }
        }

        requirement def <'CRM-020'> InContextTaskCompletion {
            subject system : EnquiryCRMSystem;
            doc /* A member can complete related work from its record context or work list with or without JavaScript. */
            require constraint { doc /* Ambiguous network completion does not invite unsafe repeated mutation. */ }
        }

        requirement def <'CRM-022'> WorkspaceWorkBuckets {
            subject system : EnquiryCRMSystem;
            doc /* Each member sees assigned open work separated into overdue, due today, and upcoming buckets. */
            require constraint { doc /* Bucket boundaries use the workspace timezone. */ }
        }

        requirement def <'CRM-024'> ImmediateTaskVisibility {
            subject system : EnquiryCRMSystem;
            doc /* Every open task appears in its assignee's work views immediately without per-member configuration. */
            require constraint { doc /* Task creation and work-list reads share the same committed state. */ }
        }

        requirement def <'CRM-025'> ImplementedSearch {
            subject system : EnquiryCRMSystem;
            doc /* Members can search the implemented person and company records using common identifying information. */
            require constraint { doc /* This requirement does not claim future deal or free-text search. */ }
        }

        requirement def <'CRM-029'> IndividualOwnership {
            subject system : EnquiryCRMSystem;
            doc /* Every implemented person, company, and task has an explicit current owner or assignee. */
            require constraint { doc /* This requirement does not claim future bulk reassignment. */ }
        }

        requirement def <'CRM-030'> AttributionAndHistory {
            subject system : EnquiryCRMSystem;
            doc /* Members can see authorship, last change, and implemented owner or status history. */
            require constraint { doc /* History is append-only and attributable to an active member. */ }
        }

        requirement def <'CRM-031'> SharedActiveMemberAccess {
            subject system : EnquiryCRMSystem;
            doc /* Every active workspace member has the same implemented CRM access; ownership does not restrict visibility. */
            require constraint { doc /* No unimplemented permission tier is implied. */ }
        }

        requirement def <'CRM-044'> ImmediateMembershipEnforcement {
            subject system : EnquiryCRMSystem;
            doc /* Every non-health request resolves the trusted identity against current active membership. */
            require constraint { doc /* Ending membership prevents subsequent access without relying on an application session. */ }
        }

        requirement def <'CRM-046'> DeclaredWorkspaceTimezone {
            subject system : EnquiryCRMSystem;
            doc /* All due-date grouping uses the declared workspace timezone, which must equal server configuration. */
            require constraint { doc /* Startup fails instead of silently using a mismatched host timezone. */ }
        }

        requirement def <'CRM-047'> RecoverableConcurrentEdits {
            subject system : EnquiryCRMSystem;
            doc /* Stale person or company edits are detected and can be reapplied without silently replacing a newer change. */
            require constraint { doc /* Version checks and revision details make the conflict visible. */ }
        }

        satisfy PersonCapture by enquiryCrm;
        satisfy PersonContactMethods by enquiryCrm;
        satisfy CompanyCapture by enquiryCrm;
        satisfy OptionalCompanyAssociation by enquiryCrm;
        satisfy RelationshipLifecycle by enquiryCrm;
        satisfy CoherentRecordDetail by enquiryCrm;
        satisfy DuplicateReview by enquiryCrm;
        satisfy FollowUpTaskCreation by enquiryCrm;
        satisfy InContextTaskCompletion by enquiryCrm;
        satisfy WorkspaceWorkBuckets by enquiryCrm;
        satisfy ImmediateTaskVisibility by enquiryCrm;
        satisfy ImplementedSearch by enquiryCrm;
        satisfy IndividualOwnership by enquiryCrm;
        satisfy AttributionAndHistory by enquiryCrm;
        satisfy SharedActiveMemberAccess by enquiryCrm;
        satisfy ImmediateMembershipEnforcement by enquiryCrm.identity;
        satisfy DeclaredWorkspaceTimezone by enquiryCrm.configuration;
        satisfy RecoverableConcurrentEdits by enquiryCrm.store;

        dependency satisfies_CRM_001 from EnquiryCRMSystem to PersonCapture;
        dependency satisfies_CRM_002 from EnquiryCRMSystem to PersonContactMethods;
        dependency satisfies_CRM_003 from EnquiryCRMSystem to CompanyCapture;
        dependency satisfies_CRM_004 from EnquiryCRMSystem to OptionalCompanyAssociation;
        dependency satisfies_CRM_005 from EnquiryCRMSystem to RelationshipLifecycle;
        dependency satisfies_CRM_006 from EnquiryCRMSystem to CoherentRecordDetail;
        dependency satisfies_CRM_007 from EnquiryCRMSystem to DuplicateReview;
        dependency satisfies_CRM_019 from EnquiryCRMSystem to FollowUpTaskCreation;
        dependency satisfies_CRM_020 from EnquiryCRMSystem to InContextTaskCompletion;
        dependency satisfies_CRM_022 from EnquiryCRMSystem to WorkspaceWorkBuckets;
        dependency satisfies_CRM_024 from EnquiryCRMSystem to ImmediateTaskVisibility;
        dependency satisfies_CRM_025 from EnquiryCRMSystem to ImplementedSearch;
        dependency satisfies_CRM_029 from EnquiryCRMSystem to IndividualOwnership;
        dependency satisfies_CRM_030 from EnquiryCRMSystem to AttributionAndHistory;
        dependency satisfies_CRM_031 from EnquiryCRMSystem to SharedActiveMemberAccess;
        dependency satisfies_CRM_044 from TrustedIdentityAdapter to ImmediateMembershipEnforcement;
        dependency satisfies_CRM_046 from ConfigurationLoader to DeclaredWorkspaceTimezone;
        dependency satisfies_CRM_047 from StoreLayer to RecoverableConcurrentEdits;
    }

    package AI {
        doc /* Implemented AI capabilities. AI requirement IDs are globally unique and never reused. */

        package BusinessCardScanning {
            doc /* Current AI capability: extract suggested person-form values from a transient business-card image. */

            requirement def <'AI-001'> FeatureGating {
                subject scanner : BusinessCardScanner;
                doc /* The capability is absent from UI and routes when disabled and requires valid provider configuration when enabled. */
                require constraint { doc /* Disabled features require no provider credential. */ }
            }

            requirement def <'AI-002'> BrowserImagePreparation {
                subject scanner : BusinessCardScanner;
                doc /* The browser resizes the selected image, removes metadata, and submits a generated JPEG preview. */
                require constraint { doc /* Original image bytes are not sent directly. */ }
            }

            requirement def <'AI-003'> ServerInputValidation {
                subject scanner : BusinessCardScanner;
                doc /* The server accepts only a same-origin multipart request containing a bounded browser-generated JPEG. */
                require constraint { doc /* Media type, image structure, and byte limits are enforced before the provider call. */ }
            }

            requirement def <'AI-004'> ScopedOneUseGrant {
                subject scanner : BusinessCardScanner;
                doc /* Each scan requires a short-lived one-use grant scoped to member, workspace, and feature. */
                require constraint { doc /* Replayed, expired, or cross-scope grants are rejected. */ }
            }

            requirement def <'AI-005'> ResourceLimits {
                subject scanner : BusinessCardScanner;
                doc /* Per-member rate limits and member/workspace concurrency limits bound provider work. */
                require constraint { doc /* Limits are claimed transactionally before a provider request begins. */ }
            }

            requirement def <'AI-006'> ProviderPrivacy {
                subject scanner : BusinessCardScanner;
                doc /* Provider routing requires zero data retention and denied data collection. */
                require constraint { doc /* Failure to obtain those routing guarantees fails the scan. */ }
            }

            requirement def <'AI-007'> StructuredExtraction {
                subject scanner : BusinessCardScanner;
                doc /* Provider output is decoded through a strict structured contact schema with bounded fields. */
                require constraint { doc /* Raw provider text never bypasses application validation. */ }
            }

            requirement def <'AI-008'> ReviewBeforeCreate {
                subject scanner : BusinessCardScanner;
                doc /* Extracted values and warnings prefill the normal person form; only member review and submission creates a record. */
                require constraint { doc /* AI output cannot directly mutate CRM records. */ }
            }

            requirement def <'AI-009'> MinimalPersistence {
                subject scanner : BusinessCardScanner;
                doc /* Permanent AI-run data excludes images, extracted contact details, raw provider responses, and provider credentials. */
                require constraint { doc /* Only operational status, usage, timing, and trace identifiers are retained. */ }
            }

            requirement def <'AI-010'> TraceableAndRecoverableRuns {
                subject scanner : BusinessCardScanner;
                doc /* Runs record prompt, release, feature, and model identifiers and return safe member-facing failures. */
                require constraint { doc /* Prompt changes share the code release and rollback trail. */ }
            }

            satisfy FeatureGating by enquiryCrm.configuration;
            satisfy BrowserImagePreparation by enquiryCrm.businessCardScanner;
            satisfy ServerInputValidation by enquiryCrm.businessCardScanner;
            satisfy ScopedOneUseGrant by enquiryCrm.businessCardScanner;
            satisfy ResourceLimits by enquiryCrm.businessCardScanner;
            satisfy ProviderPrivacy by enquiryCrm.businessCardScanner;
            satisfy StructuredExtraction by enquiryCrm.businessCardScanner;
            satisfy ReviewBeforeCreate by enquiryCrm.businessCardScanner;
            satisfy MinimalPersistence by enquiryCrm.businessCardScanner;
            satisfy TraceableAndRecoverableRuns by enquiryCrm.businessCardScanner;

            dependency satisfies_AI_001 from ConfigurationLoader to FeatureGating;
            dependency satisfies_AI_002 from BusinessCardScanner to BrowserImagePreparation;
            dependency satisfies_AI_003 from BusinessCardScanner to ServerInputValidation;
            dependency satisfies_AI_004 from BusinessCardScanner to ScopedOneUseGrant;
            dependency satisfies_AI_005 from BusinessCardScanner to ResourceLimits;
            dependency satisfies_AI_006 from BusinessCardScanner to ProviderPrivacy;
            dependency satisfies_AI_007 from BusinessCardScanner to StructuredExtraction;
            dependency satisfies_AI_008 from BusinessCardScanner to ReviewBeforeCreate;
            dependency satisfies_AI_009 from BusinessCardScanner to MinimalPersistence;
            dependency satisfies_AI_010 from BusinessCardScanner to TraceableAndRecoverableRuns;
        }
    }
}
