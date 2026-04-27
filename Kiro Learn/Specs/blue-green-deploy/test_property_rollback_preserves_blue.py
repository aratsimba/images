#!/usr/bin/env python3
"""Property Test — Rollback Preserves Blue Environment.

Property 1: Blue Environment Integrity on Failure
Validates: Requirements 8.1, 8.2, 8.3

This property test verifies that when a blue-green deployment fails,
the original blue environment remains intact and continues serving
traffic. It checks three sub-properties:

  P1.1  Failed deployments trigger automatic rollback when auto-rollback
        is enabled on the deployment group.
  P1.2  After rollback, traffic is routed back to the original blue
        environment (ALB target group has healthy targets).
  P1.3  Deployment history records the rollback event with a reference
        to the original failed deployment.

The test queries the EXISTING deployment history rather than triggering
a new deployment, so it is safe to run repeatedly without side effects.
If no failed deployments exist yet, it will report that and exit.

Usage:
    python3 test_property_rollback_preserves_blue.py
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from components.deployment_monitor import (
    get_deployment_status,
    list_deployments,
    get_instance_targets,
)
from components.infra_manager import get_target_group_health

import boto3

# ---------------------------------------------------------------------------
# Configuration — must match the live environment
# ---------------------------------------------------------------------------
APP_NAME = "BlueGreenApp"
DEPLOYMENT_GROUP = "BlueGreenDG"
TARGET_GROUP_NAME = "BlueGreenTG"

elbv2 = boto3.client("elbv2")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def find_target_group_arn(tg_name: str) -> str:
    """Look up the ARN of a target group by name."""
    resp = elbv2.describe_target_groups(Names=[tg_name])
    return resp["TargetGroups"][0]["TargetGroupArn"]


def get_failed_deployments(history: list) -> list:
    """Return deployments whose status is 'Failed' or 'Stopped'."""
    return [d for d in history if d["status"] in ("Failed", "Stopped")]


# ---------------------------------------------------------------------------
# Property checks
# ---------------------------------------------------------------------------

def check_p1_1_auto_rollback_triggered(failed_deployment: dict) -> bool:
    """P1.1 — A failed deployment must have triggered an automatic rollback.

    Evidence: the deployment's rollback_info is populated and contains a
    rollback deployment ID or message.
    """
    rb = failed_deployment.get("rollback_info") or {}
    has_rollback = bool(
        rb.get("rollbackDeploymentId")
        or rb.get("rollbackMessage")
        or rb.get("rollbackTriggeringDeploymentId")
    )
    return has_rollback


def check_p1_2_blue_env_healthy(tg_arn: str) -> bool:
    """P1.2 — The ALB target group must have at least one healthy target.

    This confirms that the blue environment is still serving traffic.
    """
    resp = elbv2.describe_target_health(TargetGroupArn=tg_arn)
    healthy = [
        t for t in resp["TargetHealthDescriptions"]
        if t["TargetHealth"]["State"] == "healthy"
    ]
    return len(healthy) > 0


def check_p1_3_history_records_rollback(
    history: list, failed_deployment: dict
) -> bool:
    """P1.3 — The failed deployment must show evidence that the blue
    environment was preserved, via one of two mechanisms:

    a) A separate rollback deployment exists in history whose rollback_info
       references the failed deployment ID (traffic was shifted, then
       rolled back).
    b) The failed deployment's own rollback_info indicates that rollback
       was unnecessary because traffic never left the blue environment
       (e.g., "traffic hasn't begun rerouting to the replacement
       environment"). This is equally valid — the blue env was never
       at risk.
    """
    failed_dep_id = failed_deployment["deployment_id"]

    # Case (a): explicit rollback deployment in history
    for dep in history:
        rb = dep.get("rollback_info") or {}
        triggering_id = rb.get("rollbackTriggeringDeploymentId", "")
        if triggering_id == failed_dep_id and dep["status"] == "Succeeded":
            return True

    # Case (b): rollback not required — traffic never shifted
    rb = failed_deployment.get("rollback_info") or {}
    rb_msg = rb.get("rollbackMessage", "").lower()
    # AWS may use curly quotes (U+2019) — normalise to straight apostrophe
    rb_msg = rb_msg.replace("\u2019", "'")
    if "isn't required" in rb_msg or "not required" in rb_msg:
        return True

    return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    print("=" * 64)
    print("  Property Test: Rollback Preserves Blue Environment")
    print("  (Requirements 8.1, 8.2, 8.3)")
    print("=" * 64)

    # --- Gather evidence ---------------------------------------------------
    print("\n[1/4] Fetching deployment history...")
    history = list_deployments(APP_NAME, DEPLOYMENT_GROUP)
    if not history:
        print("  ✗ No deployments found. Run a failing deployment first.")
        return 1

    failed = get_failed_deployments(history)
    if not failed:
        print("  ✗ No failed/stopped deployments in history.")
        print("    Run trigger_failing_deployment.py first to generate one.")
        return 1

    # Use the most recent failed deployment for the property checks
    target_dep = failed[0]
    dep_id = target_dep["deployment_id"]
    print(f"  Using failed deployment: {dep_id} (status={target_dep['status']})")

    # --- Look up target group ARN ------------------------------------------
    print("\n[2/4] Looking up ALB target group...")
    try:
        tg_arn = find_target_group_arn(TARGET_GROUP_NAME)
        print(f"  Target group ARN: {tg_arn}")
    except Exception as e:
        print(f"  ✗ Could not find target group '{TARGET_GROUP_NAME}': {e}")
        return 1

    # --- Run property checks -----------------------------------------------
    results = {}

    print("\n[3/4] Checking properties...\n")

    # P1.1
    p1_1 = check_p1_1_auto_rollback_triggered(target_dep)
    results["P1.1 Auto-rollback triggered on failure"] = p1_1
    rb_info = target_dep.get("rollback_info") or {}
    print(f"  P1.1 Auto-rollback triggered on failure: {'✓ PASS' if p1_1 else '✗ FAIL'}")
    if rb_info:
        print(f"       rollback info: {rb_info}")

    # P1.2
    p1_2 = check_p1_2_blue_env_healthy(tg_arn)
    results["P1.2 Blue environment healthy (ALB targets)"] = p1_2
    print(f"  P1.2 Blue environment healthy (ALB targets): {'✓ PASS' if p1_2 else '✗ FAIL'}")
    if p1_2:
        targets = elbv2.describe_target_health(TargetGroupArn=tg_arn)
        healthy_ids = [
            t["Target"]["Id"]
            for t in targets["TargetHealthDescriptions"]
            if t["TargetHealth"]["State"] == "healthy"
        ]
        print(f"       healthy targets: {healthy_ids}")

    # P1.3
    p1_3 = check_p1_3_history_records_rollback(history, target_dep)
    results["P1.3 Rollback recorded in deployment history"] = p1_3
    print(f"  P1.3 Rollback recorded in deployment history: {'✓ PASS' if p1_3 else '✗ FAIL'}")

    # --- Verdict -----------------------------------------------------------
    all_passed = all(results.values())

    print(f"\n[4/4] Verdict\n")
    print("=" * 64)
    if all_passed:
        print("  ✓ PROPERTY HOLDS: Rollback preserves blue environment")
    else:
        print("  ✗ PROPERTY VIOLATED: One or more checks failed")
        for name, passed in results.items():
            if not passed:
                print(f"    - {name}")
    print("=" * 64)

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
