#!/usr/bin/env python3
"""
Cleanup script — tears down ALL AWS resources created during the
blue-green deployment project.

Order of deletion:
  1. CodeDeploy resources (deployment group, application)
  2. Infrastructure (ASGs including copied ones, launch template, ALB)
  3. S3 revision bucket
  4. IAM roles and instance profiles
"""

import json
import boto3
from botocore.exceptions import ClientError

# Load project config
with open("config.json") as f:
    config = json.load(f)

# AWS clients
codedeploy = boto3.client("codedeploy")
autoscaling = boto3.client("autoscaling")
ec2 = boto3.client("ec2")
elbv2 = boto3.client("elbv2")
sts = boto3.client("sts")

# Import component cleanup helpers
from components.deployment_manager import delete_deployment_group, delete_application
from components.revision_manager import delete_revision_bucket
from components.iam_setup import delete_roles_and_profiles
iam = boto3.client("iam")

# ── Resource names (must match what was created) ──────────────────────────
APP_NAME = "BlueGreenApp"
DG_NAME = "BlueGreenDG"
ASG_NAME = "BlueGreenASG"
ALB_NAME = "BlueGreenALB"
TG_NAME = "BlueGreenTG"
LT_NAME = "BlueGreenLT"
CODEDEPLOY_ROLE = "CodeDeployServiceRole"
EC2_ROLE = "CodeDeployEC2Role"
INSTANCE_PROFILE = "CodeDeployInstanceProfile"

ACCOUNT_ID = sts.get_caller_identity()["Account"]
BUCKET_NAME = f"blue-green-deploy-revisions-{ACCOUNT_ID}"


def banner(msg: str) -> None:
    print(f"\n{'='*60}")
    print(f"  {msg}")
    print(f"{'='*60}\n")


# ── Phase 1: CodeDeploy ──────────────────────────────────────────────────
def cleanup_codedeploy():
    banner("Phase 1 — Deleting CodeDeploy resources")
    delete_deployment_group(APP_NAME, DG_NAME)
    delete_application(APP_NAME)


# ── Phase 2: Infrastructure ──────────────────────────────────────────────
def find_copied_asgs():
    """Find ASGs created by CodeDeploy's COPY_AUTO_SCALING_GROUP action."""
    copied = []
    paginator = autoscaling.get_paginator("describe_auto_scaling_groups")
    for page in paginator.paginate():
        for asg in page["AutoScalingGroups"]:
            name = asg["AutoScalingGroupName"]
            # CodeDeploy copies produce names like
            # BlueGreenASG-<deployment-id> or CodeDeploy_...
            if name != ASG_NAME and (
                name.startswith(ASG_NAME) or name.startswith("CodeDeploy_")
            ):
                copied.append(name)
    return copied


def delete_asg(name: str):
    try:
        autoscaling.delete_auto_scaling_group(
            AutoScalingGroupName=name, ForceDelete=True
        )
        print(f"  Deleted ASG: {name}")
    except ClientError as e:
        if "not found" in str(e).lower() or e.response["Error"]["Code"] == "ValidationError":
            print(f"  ASG {name} not found, skipping")
        else:
            raise


def cleanup_infrastructure():
    banner("Phase 2 — Deleting infrastructure resources")

    # 2a. Delete copied ASGs from blue-green deployments
    copied = find_copied_asgs()
    if copied:
        print(f"Found {len(copied)} copied ASG(s) from blue-green deployments:")
        for name in copied:
            delete_asg(name)
    else:
        print("No copied ASGs found.")

    # 2b. Delete the original ASG
    delete_asg(ASG_NAME)

    # 2c. Delete launch template
    try:
        ec2.delete_launch_template(LaunchTemplateName=LT_NAME)
        print(f"  Deleted launch template: {LT_NAME}")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("InvalidLaunchTemplateName.NotFoundException",
                     "InvalidLaunchTemplateId.NotFound"):
            print(f"  Launch template {LT_NAME} not found, skipping")
        else:
            raise

    # 2d. Delete ALB listeners, target group, and ALB
    alb_arn = None
    try:
        resp = elbv2.describe_load_balancers(Names=[ALB_NAME])
        alb_arn = resp["LoadBalancers"][0]["LoadBalancerArn"]
    except ClientError:
        print(f"  ALB {ALB_NAME} not found, skipping ALB cleanup")

    if alb_arn:
        # Delete listeners
        try:
            listeners = elbv2.describe_listeners(LoadBalancerArn=alb_arn)
            for listener in listeners["Listeners"]:
                elbv2.delete_listener(ListenerArn=listener["ListenerArn"])
                print(f"  Deleted listener: {listener['ListenerArn']}")
        except ClientError:
            print("  No listeners found, skipping")

        # Delete ALB first (target group can't be deleted while ALB references it)
        try:
            elbv2.delete_load_balancer(LoadBalancerArn=alb_arn)
            print(f"  Deleted ALB: {alb_arn}")
        except ClientError:
            print(f"  Could not delete ALB {alb_arn}")

    # Delete target group (may need a moment after ALB deletion)
    tg_arn = None
    try:
        resp = elbv2.describe_target_groups(Names=[TG_NAME])
        tg_arn = resp["TargetGroups"][0]["TargetGroupArn"]
    except ClientError:
        print(f"  Target group {TG_NAME} not found, skipping")

    if tg_arn:
        import time
        # ALB deletion is async; wait briefly for it to release the TG
        print("  Waiting a few seconds for ALB deletion to propagate...")
        time.sleep(5)
        try:
            elbv2.delete_target_group(TargetGroupArn=tg_arn)
            print(f"  Deleted target group: {tg_arn}")
        except ClientError as e:
            print(f"  Could not delete target group: {e}")
            print("  (You may need to retry after the ALB finishes deleting)")


# ── Phase 3: S3 ──────────────────────────────────────────────────────────
def cleanup_s3():
    banner("Phase 3 — Deleting S3 revision bucket")
    delete_revision_bucket(BUCKET_NAME)


# ── Phase 4: IAM ─────────────────────────────────────────────────────────
def cleanup_iam():
    banner("Phase 4 — Deleting IAM roles and instance profiles")
    # EC2 instance profile + role
    print("Removing EC2 instance profile and role...")
    delete_roles_and_profiles(EC2_ROLE, INSTANCE_PROFILE)

    # CodeDeploy service role (handles both managed and inline policies)
    print("Removing CodeDeploy service role...")
    try:
        # Detach managed policies
        attached = iam.list_attached_role_policies(RoleName=CODEDEPLOY_ROLE)
        for policy in attached.get("AttachedPolicies", []):
            iam.detach_role_policy(
                RoleName=CODEDEPLOY_ROLE, PolicyArn=policy["PolicyArn"]
            )
        # Delete inline policies
        inline = iam.list_role_policies(RoleName=CODEDEPLOY_ROLE)
        for policy_name in inline.get("PolicyNames", []):
            iam.delete_role_policy(
                RoleName=CODEDEPLOY_ROLE, PolicyName=policy_name
            )
        iam.delete_role(RoleName=CODEDEPLOY_ROLE)
        print(f"  Deleted role: {CODEDEPLOY_ROLE}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchEntity":
            print(f"  Role {CODEDEPLOY_ROLE} does not exist, skipping")
        else:
            raise


# ── Main ──────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Starting full resource teardown...")
    cleanup_codedeploy()
    cleanup_infrastructure()
    cleanup_s3()
    cleanup_iam()
    banner("Teardown complete! All project resources have been removed.")
