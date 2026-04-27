# Task 8.1 — Trigger All-at-Once Deployment

## Summary

Triggered the first blue-green deployment using `CodeDeployDefault.AllAtOnce` configuration. The `create_deployment` function was already implemented in `deployment_manager.py` from earlier tasks, so the work focused on creating a runner script and resolving IAM permission issues.

## What Was Done

### 1. Created `trigger_deployment.py`

A runner script at `blue-green-deploy/trigger_deployment.py` that:
- Imports `get_revision_location` from `revision_manager.py` and `create_deployment` from `deployment_manager.py`
- Builds the `RevisionLocation` dictionary pointing to `s3://blue-green-deploy-revisions-628326705801/revisions/v1.zip`
- Calls `create_deployment` with app name `BlueGreenApp`, deployment group `BlueGreenDG`, and `CodeDeployDefault.AllAtOnce` config
- Prints the deployment ID and helpful follow-up commands

### 2. IAM Permission Fix

The first deployment attempt (`d-JTQ4047UI`) failed because the `AWSCodeDeployRole` managed policy doesn't cover all permissions needed for blue-green deployments that copy Auto Scaling groups. An inline policy `BlueGreenDeploymentPermissions` was attached to `CodeDeployServiceRole` granting:
- `iam:PassRole`
- `ec2:RunInstances`
- `ec2:CreateTags`
- Related Auto Scaling and EC2 permissions

### 3. Successful Deployment Triggered

The second deployment (`d-TOT9JG8UI`) was confirmed `InProgress` with `CodeDeployDefault.AllAtOnce` configuration via `aws deploy get-deployment`.

## Key Files

| File | Action |
|------|--------|
| `blue-green-deploy/trigger_deployment.py` | Created — runner script to trigger deployments |
| `blue-green-deploy/components/deployment_manager.py` | Already had `create_deployment` — no changes needed |
| IAM role `CodeDeployServiceRole` | Updated — added inline policy for blue-green permissions |

## Deployment Details

- **App Name**: BlueGreenApp
- **Deployment Group**: BlueGreenDG
- **Deployment Config**: CodeDeployDefault.AllAtOnce
- **Revision**: s3://blue-green-deploy-revisions-628326705801/revisions/v1.zip
- **First attempt**: `d-JTQ4047UI` — failed (IAM permissions)
- **Second attempt**: `d-TOT9JG8UI` — in progress (after IAM fix)

## Verification

```bash
aws deploy get-deployment --deployment-id d-TOT9JG8UI
```
