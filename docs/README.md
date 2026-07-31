# Enquiry CRM documentation

The authoritative description of the running system is the
[SysML v2 as-built model](model/enquiry-crm.sysml). It covers architecture,
implemented requirements, accepted decisions, risks, controls, and verification
evidence.

Supporting documents have deliberately narrow authority:

- [Development](development.md) covers local setup, project checks, builds, and
  code structure.
- [Deployment](deployment/digitalocean-tailscale.md) owns exact operational
  procedures and commands.
- [Roadmap](roadmap/) describes proposed or target-state behavior and is not
  evidence that a feature exists.
- [Media](media/) contains non-model images used by the project documentation.

## Reading the model

Start with `model/enquiry-crm.sysml`, which imports these packages:

| Package | Purpose |
|---|---|
| `CRMArchitecture` | Context, parts, deployment, behavior, and accepted decisions |
| `CRMRequirements` | Implemented CRM requirements and capability-scoped `AI-###` requirements |
| `CRMRiskAndControls` | ISO/IEC 27005-aligned risk scenarios and risk-modifying controls |
| `CRMVerification` | Verification methods, commands, and evidence |

Stable IDs are never reused:

- existing `CRM-###` IDs identify implemented CRM requirements;
- globally unique `AI-###` IDs identify implemented AI requirements, with the
  package path defining the capability scope;
- `RSK-###`, `CTL-###`, `VER-###`, and `DEC-###` identify risks, controls,
  verification cases, and accepted decisions.

The current AI requirements live under
`CRMRequirements::AI::BusinessCardScanning`. A future AI feature gets its own
capability package and the next unused global `AI-###` IDs.

## Risk and verification method

Each risk records a source, event, consequence, affected objective, and
classification. This vocabulary is informed by
[ISO/IEC 27005:2022](https://www.iso.org/standard/80585.html), but the model is
not a certification claim or a quantitative risk assessment.

Every risk must have a risk-modifying control. Every control and implemented
requirement must be satisfied by an implementation element and verified by
evidence. Evidence can be an automated test, analysis, inspection, or
operational demonstration; procedural controls are not presented as automated
tests.

## Editing and checking

The model targets [OMG SysML v2.0](https://www.omg.org/spec/SysML/2.0) core
notation. [Spec42](https://github.com/elan8/spec42) supplies the pinned
command-line parser, semantic summary, and editor language server.
The official
[SysML v2 pilot implementation](https://github.com/Systems-Modeling/SysML-v2-Pilot-Implementation)
is an optional interoperability reference, not a second CI gate.

```sh
# Validate syntax, traceability, evidence, and IDs
roc scripts/tasks.roc model-check

# Run the complete non-browser project check, including model-check
roc scripts/tasks.roc check
```

The task runner downloads the pinned Spec42 binary into ignored `.tools/`,
verifies its SHA-256 before execution, and runs without external SysML domain
libraries.

## Definition of done

A behavior-affecting change updates, in the same change:

1. the relevant requirement, architecture element, decision, risk, or control;
2. its implementation satisfaction and verification evidence;
3. roadmap or runbook material only when their distinct future or operational
   scope changes.

The checker can enforce structural traceability and evidence references. Review
still determines whether the model accurately describes the semantic effect of
the code change.
