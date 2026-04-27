# Task 2: IAM Roles and Instance Profiles

**Started:** 2026-04-10
**Completed:** 2026-04-10

## Overview

Created the IAM foundation for the blue-green deployment pipeline — the service role for CodeDeploy and the instance profile for EC2 instances.

## Key Concepts Discussed

- **IAM Roles** — permission badges that AWS services assume to perform actions on your behalf
- **Trust Policies** — rules that control *who* can assume a role (e.g., only `codedeploy.amazonaws.com` or `ec2.amazonaws.com`)
- **Managed Policies** — pre-built permission sets maintained by AWS (e.g., `AWSCodeDeployRole`, `AmazonS3ReadOnlyAccess`)
- **Instance Profiles** — wrappers that attach IAM roles to EC2 instances (the "lanyard" analogy)
- **IAM Propagation** — the ~10 second delay for IAM changes to replicate across AWS infrastructure

## Code Written

**File:** `blue-green-deploy/components/iam_setup.py`

### Functions Implemented

| Function | Purpose |
|----------|---------|
| `create_codedeploy_service_role(role_name)` | Creates IAM role with CodeDeploy trust policy, attaches `AWSCodeDeployRole` managed policy |
| `get_role_arn(role_name)` | Retrieves the ARN of an existing IAM role |
| `create_ec2_instance_profile(profile_name, role_name)` | Creates EC2 role with S3 and SSM policies, wraps in instance profile |
| `delete_roles_and_profiles(role_name, profile_name)` | Full cleanup — removes profile, detaches policies, deletes roles |

### Policies Attached

- **CodeDeploy role:** `AWSCodeDeployRole` (EC2, ASG, ELB permissions)
- **EC2 role:** `AmazonS3ReadOnlyAccess` (revision retrieval) + `AmazonSSMManagedInstanceCore` (agent communication)

## Verification Steps

- `aws iam get-role --role-name CodeDeployServiceRole`
- `aws iam get-instance-profile --instance-profile-name CodeDeployInstanceProfile`

## Issues Encountered

None — implementation was straightforward. All functions handle `EntityAlreadyExists` and `LimitExceeded` errors gracefully for idempotent re-runs.
