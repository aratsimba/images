# IAM Setup - CodeDeploy service role and EC2 instance profile

import json
import time
import boto3
from botocore.exceptions import ClientError

iam = boto3.client("iam")

CODEDEPLOY_TRUST_POLICY = json.dumps({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"Service": "codedeploy.amazonaws.com"},
            "Action": "sts:AssumeRole",
        }
    ],
})

EC2_TRUST_POLICY = json.dumps({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Action": "sts:AssumeRole",
        }
    ],
})


# ---------------------------------------------------------------------------
# CodeDeploy Service Role
# ---------------------------------------------------------------------------

def create_codedeploy_service_role(role_name: str) -> str:
    """Create an IAM role that CodeDeploy can assume, with the AWSCodeDeployRole policy."""
    try:
        resp = iam.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=CODEDEPLOY_TRUST_POLICY,
            Description="Allows CodeDeploy to manage EC2, ASG, and ELB resources",
        )
        role_arn = resp["Role"]["Arn"]
        print(f"Created role: {role_arn}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityAlreadyExists":
            role_arn = get_role_arn(role_name)
            print(f"Role {role_name} already exists: {role_arn}")
        else:
            raise

    iam.attach_role_policy(
        RoleName=role_name,
        PolicyArn="arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole",
    )
    print("Attached AWSCodeDeployRole policy")

    print("Waiting 10 seconds for IAM propagation...")
    time.sleep(10)
    return role_arn


def get_role_arn(role_name: str) -> str:
    """Retrieve the ARN of an existing IAM role."""
    resp = iam.get_role(RoleName=role_name)
    return resp["Role"]["Arn"]


# ---------------------------------------------------------------------------
# EC2 Instance Profile
# ---------------------------------------------------------------------------

def create_ec2_instance_profile(profile_name: str, role_name: str) -> str:
    """Create an EC2 role + instance profile for CodeDeploy targets."""
    # --- Create the IAM role ---
    try:
        resp = iam.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=EC2_TRUST_POLICY,
            Description="EC2 role for CodeDeploy agent and S3 revision access",
        )
        print(f"Created EC2 role: {resp['Role']['Arn']}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityAlreadyExists":
            print(f"EC2 role {role_name} already exists")
        else:
            raise

    # Attach required policies
    for policy_arn in [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ]:
        iam.attach_role_policy(RoleName=role_name, PolicyArn=policy_arn)
    print("Attached S3ReadOnly and SSMManagedInstanceCore policies")

    # --- Create the instance profile ---
    try:
        iam.create_instance_profile(InstanceProfileName=profile_name)
        print(f"Created instance profile: {profile_name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityAlreadyExists":
            print(f"Instance profile {profile_name} already exists")
        else:
            raise

    # Add role to instance profile (ignore if already added)
    try:
        iam.add_role_to_instance_profile(
            InstanceProfileName=profile_name, RoleName=role_name
        )
        print(f"Added role {role_name} to instance profile {profile_name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "LimitExceeded":
            print(f"Role already in instance profile {profile_name}")
        else:
            raise

    print("Waiting 10 seconds for IAM propagation...")
    time.sleep(10)

    resp = iam.get_instance_profile(InstanceProfileName=profile_name)
    return resp["InstanceProfile"]["Arn"]


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

def delete_roles_and_profiles(role_name: str, profile_name: str) -> None:
    """Remove instance profile, detach policies, and delete both roles."""
    # Remove role from instance profile
    try:
        iam.remove_role_from_instance_profile(
            InstanceProfileName=profile_name, RoleName=role_name
        )
    except ClientError:
        pass

    # Delete instance profile
    try:
        iam.delete_instance_profile(InstanceProfileName=profile_name)
        print(f"Deleted instance profile: {profile_name}")
    except ClientError:
        pass

    # Detach all policies and delete the role
    _detach_and_delete_role(role_name)


def _detach_and_delete_role(role_name: str) -> None:
    """Detach all managed policies from a role and delete it."""
    try:
        attached = iam.list_attached_role_policies(RoleName=role_name)
        for policy in attached.get("AttachedPolicies", []):
            iam.detach_role_policy(
                RoleName=role_name, PolicyArn=policy["PolicyArn"]
            )
        iam.delete_role(RoleName=role_name)
        print(f"Deleted role: {role_name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchEntity":
            print(f"Role {role_name} does not exist, skipping")
        else:
            raise
