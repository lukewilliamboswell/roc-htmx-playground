#!/usr/bin/env python3
"""Validate the Enquiry CRM SysML model and its traceability contracts."""

from __future__ import annotations

import argparse
import copy
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "docs" / "model"
SPEC42_CACHE = ROOT / ".tools" / "spec42-0.40.0" / "cache"
ID_PATTERN = re.compile(r"^(CRM|AI|RSK|CTL|VER|DEC)-\d{3}$")
SATISFACTION_PATTERN = re.compile(r"^satisfies_(CRM|AI|CTL)_(\d{3})$")
MODIFICATION_PATTERN = re.compile(r"^modifies_(CTL)_(\d{3})_(RSK)_(\d{3})$")
TRACEABLE_PREFIXES = ("CRM-", "AI-", "CTL-")
REQUIRED_RISK_FIELDS = {
    "source",
    "event",
    "consequence",
    "affectedObjective",
    "classification",
}
class ModelCheckError(RuntimeError):
    pass


def spec42_base(spec42: Path) -> list[str]:
    stdlib = SPEC42_CACHE / "stdlib"
    domain_libraries = SPEC42_CACHE / "domain-libraries"
    stdlib.mkdir(parents=True, exist_ok=True)
    domain_libraries.mkdir(parents=True, exist_ok=True)
    return [
        str(spec42),
        "--stdlib-path",
        str(stdlib),
        "--domain-libraries-path",
        str(domain_libraries),
        "--no-stdlib",
    ]


def run_spec42_check(spec42: Path) -> None:
    subprocess.run(
        [
            *spec42_base(spec42),
            "check",
            str(MODEL_DIR),
            "--warnings-as-errors",
            "--format",
            "text",
        ],
        cwd=ROOT,
        check=True,
    )


def load_summary(spec42: Path) -> dict[str, Any]:
    completed = subprocess.run(
        [
            *spec42_base(spec42),
            "model-summary",
            str(MODEL_DIR),
            "--max-nodes",
            "10000",
            "--format",
            "json",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(completed.stdout)


def declared_id(node: dict[str, Any]) -> str | None:
    attributes = node.get("attributes", {})
    facts = node.get("facts", {})
    return attributes.get("shortName") or facts.get("declared_short_name")


def documentation(node: dict[str, Any]) -> str:
    return str(
        node.get("attributes", {}).get("doc")
        or node.get("facts", {}).get("documentation")
        or ""
    )


def normalized_trace_id(prefix: str, number: str) -> str:
    return f"{prefix}-{number}"


def parse_evidence(doc: str) -> tuple[list[str], list[str], list[str], list[str]]:
    methods: list[str] = []
    commands: list[str] = []
    evidence: list[str] = []
    selectors: list[str] = []
    for line in doc.splitlines():
        key, separator, value = line.partition(":")
        if not separator:
            continue
        value = value.strip()
        if key == "Method":
            methods.append(value)
        elif key == "Command":
            commands.append(value)
        elif key == "Evidence":
            evidence.append(value)
        elif key == "Selector":
            selectors.append(value)
    return methods, commands, evidence, selectors


def labeled_documentation(doc: str) -> set[str]:
    labels: set[str] = set()
    for line in doc.splitlines():
        key, separator, value = line.partition(":")
        if separator and value.strip():
            labels.add(key.strip().lower())
    return labels


def selector_exists(selector: str, evidence_paths: list[Path]) -> bool:
    for evidence_path in evidence_paths:
        candidates = (
            [evidence_path]
            if evidence_path.is_file()
            else sorted(path for path in evidence_path.rglob("*") if path.is_file())
        )
        for candidate in candidates:
            try:
                if selector in candidate.read_text(encoding="utf-8"):
                    return True
            except (UnicodeDecodeError, OSError):
                continue
    return False


def check_contracts(summary: dict[str, Any], root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    nodes = summary.get("nodes", [])
    by_qname = {
        node.get("qualified_name"): node
        for node in nodes
        if node.get("qualified_name")
    }

    identified: dict[str, dict[str, Any]] = {}
    for node in nodes:
        stable_id = declared_id(node)
        if not stable_id:
            continue
        if not ID_PATTERN.fullmatch(stable_id):
            errors.append(f"malformed stable ID {stable_id!r}")
            continue
        if stable_id in identified:
            errors.append(f"duplicate stable ID {stable_id}")
        else:
            identified[stable_id] = node

    for prefix, expected_kind in (
        ("CRM-", "requirement def"),
        ("AI-", "requirement def"),
        ("CTL-", "requirement def"),
        ("RSK-", "item def"),
        ("VER-", "verification def"),
        ("DEC-", "item def"),
    ):
        for stable_id, node in identified.items():
            if stable_id.startswith(prefix) and node.get("element_kind") != expected_kind:
                errors.append(
                    f"{stable_id} must be a {expected_kind}, got {node.get('element_kind')}"
                )

    ai_requirements = {
        stable_id: node
        for stable_id, node in identified.items()
        if stable_id.startswith("AI-")
    }
    for stable_id, node in ai_requirements.items():
        qualified_name = str(node.get("qualified_name", ""))
        segments = qualified_name.split("::")
        if (
            len(segments) < 4
            or segments[:2] != ["CRMRequirements", "AI"]
            or not segments[2]
        ):
            errors.append(
                f"{stable_id} must belong to a named CRMRequirements::AI capability package"
            )

    risk_ids = {
        stable_id for stable_id in identified if stable_id.startswith("RSK-")
    }
    control_ids = {
        stable_id for stable_id in identified if stable_id.startswith("CTL-")
    }
    traceable_ids = {
        stable_id
        for stable_id in identified
        if stable_id.startswith(TRACEABLE_PREFIXES)
    }

    for risk_id in sorted(risk_ids):
        risk = identified[risk_id]
        fields = labeled_documentation(documentation(risk))
        normalized_fields = {
            field.replace(" ", "") for field in fields
        }
        missing = {
            field
            for field in REQUIRED_RISK_FIELDS
            if field.lower() not in normalized_fields
        }
        if missing:
            errors.append(
                f"{risk_id} is missing risk fields: {', '.join(sorted(missing))}"
            )

    dependency_names = {
        str(node.get("name"))
        for node in nodes
        if node.get("element_kind") == "dependency"
    }

    satisfied_ids: set[str] = set()
    for name in dependency_names:
        match = SATISFACTION_PATTERN.fullmatch(name)
        if match:
            stable_id = normalized_trace_id(match.group(1), match.group(2))
            satisfied_ids.add(stable_id)
            if stable_id not in traceable_ids:
                errors.append(f"{name} references unknown requirement or control {stable_id}")
    for stable_id in sorted(traceable_ids - satisfied_ids):
        errors.append(f"{stable_id} has no named implementation satisfaction")

    modified_risks: set[str] = set()
    modifying_controls: set[str] = set()
    for name in dependency_names:
        match = MODIFICATION_PATTERN.fullmatch(name)
        if not match:
            continue
        control_id = normalized_trace_id(match.group(1), match.group(2))
        risk_id = normalized_trace_id(match.group(3), match.group(4))
        modifying_controls.add(control_id)
        modified_risks.add(risk_id)
        if control_id not in control_ids:
            errors.append(f"{name} references unknown control {control_id}")
        if risk_id not in risk_ids:
            errors.append(f"{name} references unknown risk {risk_id}")
    for risk_id in sorted(risk_ids - modified_risks):
        errors.append(f"{risk_id} has no risk-modifying control")
    for control_id in sorted(control_ids - modifying_controls):
        errors.append(f"{control_id} does not modify a modeled risk")

    verified_ids: set[str] = set()
    verification_targets: dict[str, set[str]] = {}
    for node in nodes:
        if node.get("element_kind") != "verified requirement":
            continue
        target_qname = node.get("attributes", {}).get("verifiedRequirement")
        target = by_qname.get(target_qname)
        target_id = declared_id(target) if target else None
        if not target_id:
            errors.append(f"unresolved verification target {target_qname}")
            continue
        verified_ids.add(target_id)
        verification_targets.setdefault(str(node.get("parent")), set()).add(target_id)
    for stable_id in sorted(traceable_ids - verified_ids):
        errors.append(f"{stable_id} has no verification case")

    verification_ids = {
        stable_id: node
        for stable_id, node in identified.items()
        if stable_id.startswith("VER-")
    }
    for stable_id, node in verification_ids.items():
        doc = documentation(node)
        methods, commands, evidence, selectors = parse_evidence(doc)
        if len(methods) != 1 or not methods[0]:
            errors.append(f"{stable_id} must declare exactly one Method")
        if len(commands) != 1 or not commands[0]:
            errors.append(f"{stable_id} must declare exactly one Command")
        if not evidence:
            errors.append(f"{stable_id} must declare at least one Evidence path")
        evidence_paths = [root / path for path in evidence]
        for path, evidence_path in zip(evidence, evidence_paths):
            if Path(path).is_absolute() or ".." in Path(path).parts:
                errors.append(f"{stable_id} evidence must be repository-relative: {path}")
            elif not evidence_path.exists():
                errors.append(f"{stable_id} evidence does not exist: {path}")
        for selector in selectors:
            if evidence_paths and not selector_exists(selector, evidence_paths):
                errors.append(
                    f"{stable_id} selector {selector!r} was not found in its evidence"
                )
        if not verification_targets.get(str(node.get("qualified_name"))):
            errors.append(f"{stable_id} verifies no requirement or control")

    decision_ids = {
        stable_id: node
        for stable_id, node in identified.items()
        if stable_id.startswith("DEC-")
    }
    for stable_id, node in decision_ids.items():
        fields = {
            field.replace("-", "")
            for field in labeled_documentation(documentation(node))
        }
        missing = {"rationale", "tradeoff", "affected"} - fields
        if missing:
            errors.append(
                f"{stable_id} is missing decision fields: {', '.join(sorted(missing))}"
            )

    return errors


def run_contract_self_tests(summary: dict[str, Any]) -> None:
    baseline = check_contracts(summary)
    if baseline:
        raise ModelCheckError(
            "cannot run model-contract self-tests against an invalid baseline:\n"
            + "\n".join(baseline)
        )

    def expect_failure(
        label: str,
        mutate: Any,
        expected_fragment: str,
    ) -> None:
        candidate = copy.deepcopy(summary)
        mutate(candidate)
        errors = check_contracts(candidate)
        if not any(expected_fragment in error for error in errors):
            raise ModelCheckError(
                f"model-contract self-test {label!r} did not report "
                f"{expected_fragment!r}; errors were {errors}"
            )

    def remove_nodes(candidate: dict[str, Any], predicate: Any) -> None:
        candidate["nodes"] = [
            node for node in candidate["nodes"] if not predicate(node)
        ]

    expect_failure(
        "duplicate identifier",
        lambda candidate: candidate["nodes"].append(
            copy.deepcopy(
                next(
                    node
                    for node in candidate["nodes"]
                    if declared_id(node) == "CRM-001"
                )
            )
        ),
        "duplicate stable ID CRM-001",
    )
    expect_failure(
        "uncovered risk",
        lambda candidate: remove_nodes(
            candidate,
            lambda node: node.get("element_kind") == "dependency"
            and str(node.get("name", "")).endswith("_RSK_001"),
        ),
        "RSK-001 has no risk-modifying control",
    )
    expect_failure(
        "unsatisfied control",
        lambda candidate: remove_nodes(
            candidate,
            lambda node: node.get("name") == "satisfies_CTL_001",
        ),
        "CTL-001 has no named implementation satisfaction",
    )
    expect_failure(
        "unverified requirement",
        lambda candidate: remove_nodes(
            candidate,
            lambda node: node.get("element_kind") == "verified requirement"
            and node.get("attributes", {}).get("verifiedRequirement")
            == "CRMRequirements::CRM::PersonCapture",
        ),
        "CRM-001 has no verification case",
    )

    def break_evidence(candidate: dict[str, Any]) -> None:
        node = next(
            node
            for node in candidate["nodes"]
            if declared_id(node) == "VER-001"
        )
        node.setdefault("attributes", {})["doc"] = documentation(node).replace(
            "Evidence: ci/check_source_contracts.sh",
            "Evidence: missing/evidence.file",
        )

    expect_failure(
        "broken evidence",
        break_evidence,
        "VER-001 evidence does not exist",
    )

    def break_ai_scope(candidate: dict[str, Any]) -> None:
        node = next(
            node
            for node in candidate["nodes"]
            if declared_id(node) == "AI-001"
        )
        node["qualified_name"] = "CRMRequirements::AI::FeatureGating"

    expect_failure(
        "unscoped AI requirement",
        break_ai_scope,
        "AI-001 must belong to a named",
    )
    expect_failure(
        "incomplete risk scenario",
        lambda candidate: next(
            node
            for node in candidate["nodes"]
            if declared_id(node) == "RSK-001"
        ).setdefault("attributes", {}).__setitem__(
            "doc",
            documentation(
                next(
                    node
                    for node in candidate["nodes"]
                    if declared_id(node) == "RSK-001"
                )
            ).replace("Source:", "Origin:"),
        ),
        "RSK-001 is missing risk fields",
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("check",))
    parser.add_argument("spec42", type=Path)
    arguments = parser.parse_args()
    spec42 = arguments.spec42
    if not spec42.is_absolute():
        spec42 = ROOT / spec42
    if not spec42.is_file():
        raise ModelCheckError(f"Spec42 executable does not exist: {spec42}")

    run_spec42_check(spec42)
    summary = load_summary(spec42)
    errors = check_contracts(summary)
    if errors:
        raise ModelCheckError("\n".join(errors))
    run_contract_self_tests(summary)
    print("model contracts: ok")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ModelCheckError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"model check failed: {error}", file=sys.stderr)
        raise SystemExit(1)
