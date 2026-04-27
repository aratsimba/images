#!/usr/bin/env python3
"""Trigger a deployment with a deliberately FAILING ValidateService hook.

This script tests automatic rollback: the deployment should fail during
the ValidateService lifecycle event, and CodeDeploy should automatically
roll back traffic to the blue (original) environment.

Usage:
    python3 trigger_failing_deployment.py
"""

import json
import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from components.revision_manager import (
    generate_appspec,
    create_revision_bundle,
    upload_revision,
    get_revision_location,
)
from components.deployment_manager import create_deployment
from components.deployment_monitor import (
    wait_for_deployment,
    get_instance_targets,
    list_deployments,
)

APP_NAME = "BlueGreenApp"
DEPLOYMENT_GROUP = "BlueGreenDG"
DEPLOYMENT_CONFIG = "CodeDeployDefault.AllAtOnce"
BUCKET_NAME = "blue-green-deploy-revisions-628326705801"
REVISION_KEY = "revisions/v4-fail.zip"
SOURCE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app-source")
BUNDLE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "v4-fail.zip")


def main():
    print("=" * 60)
    print("  Rollback Test — Failing ValidateService Hook")
    print("=" * 60)

    # 1. Generate appspec with the FAILING validate script
    print("\n→ Generating AppSpec with failing ValidateService hook...")
    file_mappings = [
        {"source": "/src", "destination": "/var/www/html"},
    ]
    hooks = [
        {
            "event_name": "BeforeInstall",
            "script_location": "scripts/before_install.sh",
            "timeout": 300,
            "runas": "root",
        },
        {
            "event_name": "AfterInstall",
            "script_location": "scripts/after_install.sh",
            "timeout": 300,
            "runas": "root",
        },
        {
            "event_name": "ValidateService",
            "script_location": "scripts/validate_service_fail.sh",
            "timeout": 60,
            "runas": "root",
        },
    ]
    appspec_content = generate_appspec(file_mappings, hooks)
    print(f"  AppSpec content:\n{appspec_content}")

    # 2. Bundle and upload
    print("→ Creating revision bundle...")
    bundle_path = create_revision_bundle(appspec_content, SOURCE_DIR, BUNDLE_PATH)

    print(f"\n→ Uploading to s3://{BUCKET_NAME}/{REVISION_KEY}...")
    upload_revision(BUCKET_NAME, bundle_path, REVISION_KEY)

    # 3. Trigger deployment
    print(f"\n→ Triggering AllAtOnce deployment (expected to FAIL)...")
    revision_location = get_revision_location(BUCKET_NAME, REVISION_KEY)
    deployment_id = create_deployment(
        app_name=APP_NAME,
        group_name=DEPLOYMENT_GROUP,
        revision_location=revision_location,
        deployment_config_name=DEPLOYMENT_CONFIG,
        description="Rollback test — failing ValidateService hook (v4-fail)",
    )

    # 4. Monitor — expect failure + automatic rollback
    print(f"\n→ Monitoring deployment {deployment_id} (expect failure & rollback)...")
    final_status = wait_for_deployment(deployment_id, poll_interval_seconds=15)

    # 5. Show instance target details
    print("\n→ Instance target details:")
    targets = get_instance_targets(deployment_id)
    for t in targets:
        print(f"  Target: {t['target_id']}  Status: {t['status']}")
        for le in t.get("lifecycle_events", []):
            diag = ""
            if le.get("diagnostics"):
                diag = f"  log: {le['diagnostics'].get('logTail', '')[:120]}"
            print(f"    {le['event_name']}: {le['status']}{diag}")

    # 6. Show deployment history (should include rollback)
    print("\n→ Deployment history (checking for rollback events):")
    history = list_deployments(APP_NAME, DEPLOYMENT_GROUP)
    for d in history:
        rb = d.get("rollback_info") or {}
        rb_msg = rb.get("rollbackMessage", "")
        err = d.get("error_info") or {}
        err_msg = err.get("message", "")
        print(f"  {d['deployment_id']}  status={d['status']}")
        if rb_msg:
            print(f"    rollback: {rb_msg}")
        if err_msg:
            print(f"    error: {err_msg}")

    # 7. Summary
    print()
    print("=" * 60)
    print(f"  Deployment {deployment_id} finished: {final_status}")
    if final_status in ("Failed", "Stopped"):
        print("  ✓ Automatic rollback expected — traffic should remain on blue env")
    else:
        print("  ✗ Unexpected success — the failing hook should have caused failure")
    print("=" * 60)

    return final_status


if __name__ == "__main__":
    status = main()
    # Exit 0 if the deployment failed (that's the expected outcome)
    sys.exit(0 if status in ("Failed", "Stopped") else 1)
