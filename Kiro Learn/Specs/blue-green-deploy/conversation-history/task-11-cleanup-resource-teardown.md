# Task 11 — Cleanup: Resource Teardown

## Objective

Delete all AWS resources created during the blue-green deployment project to avoid ongoing costs.

## What Was Done

### Confirmation

User confirmed they wanted to proceed with full teardown of all BlueGreen deployment resources.

### Cleanup Script Created

Created `blue-green-deploy/cleanup_all.py` — a reusable Python script that tears down all resources in the correct dependency order across four phases:

1. **Phase 1 — CodeDeploy**: Delete deployment group, then application
2. **Phase 2 — Infrastructure**: Delete copied ASGs, original ASG, launch template, ALB listeners, ALB, target group
3. **Phase 3 — S3**: Empty and delete the revision bucket
4. **Phase 4 — IAM**: Remove instance profile and EC2 role, then detach policies (managed + inline) and delete CodeDeploy service role

### Execution Results

**Phase 1 — CodeDeploy** ✅
- Deleted deployment group `BlueGreenDG` from `BlueGreenApp`
- Deleted CodeDeploy application `BlueGreenApp`

**Phase 2 — Infrastructure** ✅
- Found and deleted 4 copied ASGs from blue-green deployments:
  - `CodeDeploy_BlueGreenDG_d-C13WWKRUI`
  - `CodeDeploy_BlueGreenDG_d-HHD49HSUI`
  - `CodeDeploy_BlueGreenDG_d-HOZWKISUI`
  - `CodeDeploy_BlueGreenDG_d-TOT9JG8UI`
- Original ASG `BlueGreenASG` was already gone (previously deleted by CodeDeploy during deployments)
- Deleted launch template `BlueGreenLT`
- Deleted ALB listener, ALB `BlueGreenALB`, and target group `BlueGreenTG`

**Phase 3 — S3** ✅
- Emptied and deleted bucket `blue-green-deploy-revisions-628326705801`

**Phase 4 — IAM** ✅
- Deleted instance profile `CodeDeployInstanceProfile`
- Deleted EC2 role `CodeDeployEC2Role`
- Deleted CodeDeploy service role `CodeDeployServiceRole`

### Issue Encountered and Fixed

The initial script run failed on the CodeDeploy service role deletion because the role had an **inline policy** (`BlueGreenDeploymentPermissions`) in addition to managed policies. The `_detach_and_delete_role` helper only handled managed policies.

**Fix**: 
- Manually deleted the inline policy and role via CLI
- Updated `cleanup_all.py` to handle both managed and inline policies when deleting the CodeDeploy service role

### Verification

Ran verification commands confirming all resources return "not found":
- `aws deploy get-application --application-name BlueGreenApp` → ApplicationDoesNotExistException
- `aws autoscaling describe-auto-scaling-groups` → no BlueGreen or CodeDeploy_ ASGs
- `aws elbv2 describe-load-balancers --names BlueGreenALB` → LoadBalancerNotFound
- `aws elbv2 describe-target-groups --names BlueGreenTG` → TargetGroupNotFound
- `aws ec2 describe-launch-templates --launch-template-names BlueGreenLT` → not found
- `aws s3 ls s3://blue-green-deploy-revisions-*` → NoSuchBucket
- `aws iam get-role --role-name CodeDeployServiceRole` → NoSuchEntity
- `aws iam get-role --role-name CodeDeployEC2Role` → NoSuchEntity
- `aws iam get-instance-profile --instance-profile-name CodeDeployInstanceProfile` → NoSuchEntity

## Files Created/Modified

- **Created**: `blue-green-deploy/cleanup_all.py` — comprehensive teardown script

## Key Takeaway

When deleting IAM roles, you must remove **both** managed (attached) policies and inline policies before the role can be deleted. The `DeleteConflict` error from IAM means there are still policies attached to the entity.
