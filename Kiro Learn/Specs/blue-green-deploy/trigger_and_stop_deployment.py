#!/usr/bin/env python3
"""Trigger a normal deployment and then manually stop it mid-flight.

This script tests the stop_deployment() function: it creates a valid
revision (v5), triggers a deployment, waits for it to reach InProgress,
then calls stop_deployment() to halt it. Traffic should stay with the
blue environment.

Usage:
    python3 trigger_and_stop_deployment.py
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
    get_deployment_status,
    wait_for_deployment,
    stop_deployment,
    get_instance_targets,
    list_deployments,
)

APP_NAME = "BlueGreenApp"
DEPLOYMENT_GROUP = "BlueGreenDG"
DEPLOYMENT_CONFIG = "CodeDeployDefault.AllAtOnce"
BUCKET_NAME = "blue-green-deploy-revisions-628326705801"
REVISION_KEY = "revisions/v5.zip"
SOURCE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app-source")
BUNDLE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "v5.zip")


def main():
    print("=" * 60)
    print("  Manual Stop Test — stop_deployment()")
    print("=" * 60)

    # 1. Generate a normal (valid) appspec
    print("\n→ Generating AppSpec with valid hooks...")
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
            "script_location": "scripts/validate_service.sh",
            "timeout": 300,
            "runas": "root",
        },
    ]
    appspec_content = generate_appspec(file_mappings, hooks)

    # 2. Bundle and upload
    print("→ Creating revision bundle (v5)...")
    bundle_path = create_revision_bundle(appspec_content, SOURCE_DIR, BUNDLE_PATH)

    print(f"\n→ Uploading to s3://{BUCKET_NAME}/{REVISION_KEY}...")
    upload_revision(BUCKET_NAME, bundle_path, REVISION_KEY)

    # 3. Trigger deployment
    print(f"\n→ Triggering AllAtOnce deployment...")
    revision_location = get_revision_location(BUCKET_NAME, REVISION_KEY)
    deployment_id = create_deployment(
        app_name=APP_NAME,
        group_name=DEPLOYMENT_GROUP,
        revision_location=revision_location,
        deployment_config_name=DEPLOYMENT_CONFIG,
        description="Manual stop test — v5 deployment",
    )

    # 4. Wait for deployment to get into an active state before stopping
    print(f"\n→ Waiting for deployment to reach an active state before stopping...")
    max_wait = 180  # seconds
    poll = 10
    elapsed = 0
    while elapsed < max_wait:
        status_data = get_deployment_status(deployment_id)
        status = status_data["status"]
        print(f"  [{time.strftime('%H:%M:%S')}] Status: {status}")
        if status in ("InProgress", "Ready", "Baking"):
            print(f"  Deployment is {status} — issuing stop now.")
            break
        if status in ("Succeeded", "Failed", "Stopped"):
            print(f"  Deployment already terminal ({status}) — cannot stop.")
            break
        time.sleep(poll)
        elapsed += poll

    # 5. Stop the deployment
    if status not in ("Succeeded", "Failed", "Stopped"):
        print(f"\n→ Calling stop_deployment({deployment_id}, auto_rollback=True)...")
        stop_deployment(deployment_id, auto_rollback=True)

        # 6. Monitor to terminal state
        print(f"\n→ Monitoring deployment after stop request...")
        final_status = wait_for_deployment(deployment_id, poll_interval_seconds=15)
    else:
        final_status = status

    # 7. Show instance target details
    print("\n→ Instance target details:")
    targets = get_instance_targets(deployment_id)
    for t in targets:
        print(f"  Target: {t['target_id']}  Status: {t['status']}")
        for le in t.get("lifecycle_events", []):
            print(f"    {le['event_name']}: {le['status']}")

    # 8. Show deployment history
    print("\n→ Deployment history (should show stopped deployment):")
    history = list_deployments(APP_NAME, DEPLOYMENT_GROUP)
    for d in history:
        rb = d.get("rollback_info") or {}
        rb_msg = rb.get("rollbackMessage", "")
        print(f"  {d['deployment_id']}  status={d['status']}  config={d['deployment_config']}")
        if rb_msg:
            print(f"    rollback: {rb_msg}")

    # 9. Summary
    print()
    print("=" * 60)
    print(f"  Deployment {deployment_id} finished: {final_status}")
    if final_status in ("Stopped", "Failed"):
        print("  ✓ Deployment was stopped — traffic should remain on blue env")
    else:
        print("  ✗ Deployment was not stopped as expected")
    print("=" * 60)

    return final_status


if __name__ == "__main__":
    status = main()
    sys.exit(0 if status in ("Stopped", "Failed") else 1)
