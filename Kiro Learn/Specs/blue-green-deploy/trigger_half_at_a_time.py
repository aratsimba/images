#!/usr/bin/env python3
"""Trigger a HalfAtATime blue-green deployment via CodeDeploy.

This script deploys v2.zip using CodeDeployDefault.HalfAtATime, which
installs the revision on half the instances first, then the remaining half.
On EC2, this is instance-count-based (not percentage-based traffic shifting).

Usage:
    python3 trigger_half_at_a_time.py
"""

import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from components.revision_manager import get_revision_location
from components.deployment_manager import create_deployment
from components.deployment_monitor import wait_for_deployment, get_instance_targets

APP_NAME = "BlueGreenApp"
DEPLOYMENT_GROUP = "BlueGreenDG"
DEPLOYMENT_CONFIG = "CodeDeployDefault.HalfAtATime"
BUCKET_NAME = "blue-green-deploy-revisions-628326705801"
REVISION_KEY = "revisions/v2.zip"


def main():
    print("=" * 60)
    print("  Blue-Green Deployment — HalfAtATime")
    print("=" * 60)

    # 1. Build revision location
    print(f"\n→ Revision: s3://{BUCKET_NAME}/{REVISION_KEY}")
    revision_location = get_revision_location(BUCKET_NAME, REVISION_KEY)
    print(f"  RevisionLocation: {json.dumps(revision_location, indent=2)}")

    # 2. Trigger deployment
    print(f"\n→ Triggering HalfAtATime deployment...")
    print(f"  Application:       {APP_NAME}")
    print(f"  Deployment Group:  {DEPLOYMENT_GROUP}")
    print(f"  Config:            {DEPLOYMENT_CONFIG}")
    print()
    print("  HalfAtATime deploys to half the instances first,")
    print("  then the remaining half — allowing incremental validation.")
    print()

    deployment_id = create_deployment(
        app_name=APP_NAME,
        group_name=DEPLOYMENT_GROUP,
        revision_location=revision_location,
        deployment_config_name=DEPLOYMENT_CONFIG,
        description="HalfAtATime blue-green deployment of v2",
    )

    # 3. Monitor deployment to completion
    print(f"\n→ Monitoring deployment {deployment_id}...")
    final_status = wait_for_deployment(deployment_id, poll_interval_seconds=15)

    # 4. Show instance target details
    print("\n→ Instance target details:")
    targets = get_instance_targets(deployment_id)
    for t in targets:
        print(f"  Target: {t['target_id']}  Status: {t['status']}")
        for le in t.get("lifecycle_events", []):
            print(f"    {le['event_name']}: {le['status']}")

    # 5. Summary
    print()
    print("=" * 60)
    print(f"  Deployment {deployment_id} finished: {final_status}")
    print(f"  Strategy: HalfAtATime — instances deployed in two batches")
    print("=" * 60)

    return final_status


if __name__ == "__main__":
    status = main()
    sys.exit(0 if status == "Succeeded" else 1)
