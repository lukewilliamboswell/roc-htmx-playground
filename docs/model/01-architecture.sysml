package CRMArchitecture {
    doc /* As-built context, logical architecture, deployment, and key behavior for Enquiry CRM. */

    item def Person;
    item def Organisation;
    item def InformationAsset;

    item member : Person {
        doc /* An active workspace member using the CRM through a browser. */
    }

    item operator : Person {
        doc /* A trusted operator who releases, deploys, backs up, and restores the service. */
    }

    item tailnet : Organisation {
        doc /* The organisation-controlled private network and identity boundary. */
    }

    item openRouter : Organisation {
        doc /* The external AI routing provider used only when an AI feature is enabled. */
    }

    item customerRecords : InformationAsset {
        doc /* Company, person, contact, task, activity, ownership, and revision information. */
    }

    item businessCardImage : InformationAsset {
        doc /* A transient image supplied for business-card extraction and never persisted by the CRM. */
    }

    item providerCredential : InformationAsset {
        doc /* The AI provider API key held in the protected server configuration. */
    }

    part def RouteLayer {
        doc /* Owns the closed HTTP route vocabulary and URL generation. */
    }

    part def HandlerLayer {
        doc /* Parses external input, coordinates domain decisions, and chooses responses. */
    }

    part def DomainLayer {
        doc /* Owns validated values, normalization, and pure business decisions. */
    }

    part def StoreLayer {
        doc /* Owns prepared SQL, storage conversion, transactions, and workspace scoping. */
    }

    part def ViewLayer {
        doc /* Renders accessible server-side HTML with optional htmx enhancement. */
    }

    part def SQLiteDatabase {
        doc /* The single-workspace persistent store governed by ordered immutable migrations. */
    }

    part def TrustedIdentityAdapter {
        doc /* Accepts one trusted Tailscale login header and resolves an active member. */
    }

    part def ConfigurationLoader {
        doc /* Loads and validates the required versioned JSON configuration at startup. */
    }

    part def BusinessCardScanner {
        doc /* Coordinates transient image validation, scoped authorization, provider extraction, and review. */
    }

    part def AdminExecutable {
        doc /* Applies migrations, checks schema compatibility, and administers members. */
    }

    part def EnquiryCRMSystem {
        doc /* Server-rendered Roc application composed as typed vertical feature slices. */

        part route : RouteLayer;
        part handler : HandlerLayer;
        part domain : DomainLayer;
        part store : StoreLayer;
        part view : ViewLayer;
        part database : SQLiteDatabase;
        part identity : TrustedIdentityAdapter;
        part configuration : ConfigurationLoader;
        part businessCardScanner : BusinessCardScanner;
        part administration : AdminExecutable;
    }

    part enquiryCrm : EnquiryCRMSystem;

    dependency routeDispatch from RouteLayer to HandlerLayer;
    dependency handlerDomain from HandlerLayer to DomainLayer;
    dependency handlerPersistence from HandlerLayer to StoreLayer;
    dependency handlerRendering from HandlerLayer to ViewLayer;
    dependency storeDatabase from StoreLayer to SQLiteDatabase;
    dependency requestIdentity from HandlerLayer to TrustedIdentityAdapter;
    dependency startupConfiguration from EnquiryCRMSystem to ConfigurationLoader;
    dependency aiProviderCall from BusinessCardScanner to openRouter;

    part def TailscaleServe {
        doc /* Terminates HTTPS, supplies verified identity headers, and proxies to loopback. */
    }

    part def SystemdService {
        doc /* Runs the application with filesystem and process hardening. */
    }

    part def ProductionDeployment {
        doc /* Supported DigitalOcean deployment reachable only through the organisation tailnet. */

        part trustedProxy : TailscaleServe;
        part service : SystemdService;
        part application : EnquiryCRMSystem;
        part database : SQLiteDatabase;
    }

    part production : ProductionDeployment;
    dependency privateAccess from tailnet to TailscaleServe;
    dependency loopbackProxy from TailscaleServe to EnquiryCRMSystem;
    dependency persistentStorage from EnquiryCRMSystem to SQLiteDatabase;

    action def BusinessCardScanning {
        doc /* The current implemented AI capability; it produces reviewed form values, not a person record. */

        action prepareImage {
            doc /* Resize in the browser, remove metadata, and encode as JPEG. */
        }
        action validateRequest {
            doc /* Enforce same-origin multipart, media, size, grant, rate, and concurrency controls. */
        }
        action extractStructuredContact {
            doc /* Request strict structured extraction with provider privacy routing. */
        }
        action reviewExtractedContact {
            doc /* Present extracted values and warnings in the normal person form. */
        }
        action createPerson {
            doc /* Persist only after an active member reviews and submits the normal form. */
        }
    }

    action businessCardScanning : BusinessCardScanning;

    item <'DEC-001'> TypedVerticalSlices {
        doc /* Accepted architecture decision.
Rationale: Keep HTTP, domain, persistence, and HTML responsibilities explicit and independently testable.
Trade-off: More small modules and wiring are accepted in exchange for typed boundaries and local reasoning.
Affected: Route, main dispatch, handlers, domain modules, stores, and views. */
        item rationale {
            doc /* Keep HTTP, domain, persistence, and HTML responsibilities explicit and independently testable. */
        }
        item tradeoff {
            doc /* More small modules and wiring are accepted in exchange for typed boundaries and local reasoning. */
        }
        item affected {
            doc /* Route, main dispatch, handlers, domain modules, stores, and views. */
        }
    }

    item <'DEC-002'> ExternalIdentityBoundary {
        doc /* Accepted architecture decision.
Rationale: Reuse the organisation tailnet identity and keep credentials out of the application.
Trade-off: Production correctness depends on a private trusted proxy boundary and explicit active membership.
Affected: Tailscale Serve, the development proxy, request authentication, and member administration. */
        item rationale {
            doc /* Reuse the organisation tailnet identity and keep credentials out of the application. */
        }
        item tradeoff {
            doc /* Production correctness depends on a private trusted proxy boundary and explicit active membership. */
        }
        item affected {
            doc /* Tailscale Serve, the development proxy, request authentication, and member administration. */
        }
    }

    item <'DEC-003'> LoopbackOnlyDeployment {
        doc /* Accepted architecture decision.
Rationale: Make the application unreachable except through the trusted Tailscale proxy.
Trade-off: Direct public access and Tailscale Funnel are intentionally unsupported.
Affected: Server binding, host firewall, cloud firewall, systemd, and deployment procedure. */
        item rationale {
            doc /* Make the application unreachable except through the trusted Tailscale proxy. */
        }
        item tradeoff {
            doc /* Direct public access and Tailscale Funnel are intentionally unsupported. */
        }
        item affected {
            doc /* Server binding, host firewall, cloud firewall, systemd, and deployment procedure. */
        }
    }

    item <'DEC-004'> SQLiteTransactionsAndVersions {
        doc /* Accepted architecture decision.
Rationale: Preserve atomic mutations and detect concurrent edits in a small single-workspace deployment.
Trade-off: The design favors operational simplicity over horizontal write scaling.
Affected: Stores, migrations, revisions, activities, backups, and conflict responses. */
        item rationale {
            doc /* Preserve atomic mutations and detect concurrent edits in a small single-workspace deployment. */
        }
        item tradeoff {
            doc /* The design favors operational simplicity over horizontal write scaling. */
        }
        item affected {
            doc /* Stores, migrations, revisions, activities, backups, and conflict responses. */
        }
    }

    item <'DEC-005'> ModelAsDocumentationAuthority {
        doc /* Accepted architecture decision.
Rationale: Keep architecture, requirements, risk, controls, and verification in one machine-checkable graph.
Trade-off: Contributors must update the model with behavior-affecting changes.
Affected: Documentation, project checks, CI, review practice, and release verification. */
        item rationale {
            doc /* Keep architecture, requirements, risk, controls, and verification in one machine-checkable graph. */
        }
        item tradeoff {
            doc /* Contributors must update the model with behavior-affecting changes. */
        }
        item affected {
            doc /* Documentation, project checks, CI, review practice, and release verification. */
        }
    }

    item <'DEC-006'> HumanReviewBeforeAIMutation {
        doc /* Accepted architecture decision.
Rationale: Treat AI extraction as untrusted form assistance and keep the normal domain validation boundary.
Trade-off: Scanning cannot create a person automatically and therefore requires one explicit member action.
Affected: Business-card scanning, person creation, provider integration, and UI feedback. */
        item rationale {
            doc /* Treat AI extraction as untrusted form assistance and keep the normal domain validation boundary. */
        }
        item tradeoff {
            doc /* Scanning cannot create a person automatically and therefore requires one explicit member action. */
        }
        item affected {
            doc /* Business-card scanning, person creation, provider integration, and UI feedback. */
        }
    }
}
