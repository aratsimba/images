#!/usr/bin/env python3
"""Trigger an All-at-Once blue-green deployment via CodeDeploy.

This script imports the existing component functions, builds the revision
location, and calls create_deployment with CodeDeployDefault.AllAtOnce.

Usage:
    python3 trigger_deployment.py
"""

import json
import sys
import os

# Ensure the project root is on the path so component imports work
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from components.revision_manager import get_revision_location
from components.deployment_manager import create_deployment

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
APP_NAME = "BlueGreenApp"
DEPLOYMENT_GROUP = "BlueGreenDG"
DEPLOYMENT_CONFIG = "CodeDeployDefault.AllAtOnce"
BUCKET_NAME = "blue-green-deploy-revisions-628326705801"
REVISION_KEY = "revisions/v1.zip"


def main():
    print("=" * 60)
    print("  Blue-Green Deployment — All-at-Once")
    print("=" * 60)

    # 1. Build the revision location dict
    print(f"\n→ Revision: s3://{BUCKET_NAME}/{REVISION_KEY}")
    revision_location = get_revision_location(BUCKET_NAME, REVISION_KEY)
    print(f"  RevisionLocation: {json.dumps(revision_location, indent=2)}")

    # 2. Trigger the deployment
    print(f"\n→ Triggering deployment...")
    print(f"  Application:       {APP_NAME}")
    print(f"  Deployment Group:  {DEPLOYMENT_GROUP}")
    print(f"  Config:            {DEPLOYMENT_CONFIG}")
    print()

    deployment_id = create_deployment(
        app_name=APP_NAME,
        group_name=DEPLOYMENT_GROUP,
        revision_location=revision_location,
        deployment_config_name=DEPLOYMENT_CONFIG,
        description="All-at-Once blue-green deployment of v1",
    )

    # 3. Print next steps
    print()
    print("=" * 60)
    print(f"  Deployment ID: {deployment_id}")
    print("=" * 60)
    print()
    print("Track this deployment with:")
    print(f"  aws deploy get-deployment --deployment-id {deployment_id}")
    print()
    print("Or monitor lifecycle events in the console:")
    print(f"  https://us-east-1.console.aws.amazon.com/codesuite/codedeploy/"
          f"deployments/{deployment_id}")


if __name__ == "__main__":
    main()
