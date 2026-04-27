# Task 8.2 — Implement Deployment Monitoring and File Conflict Resolution

## Summary

Implemented the full `deployment_monitor.py` module with all 5 required functions. During verification against live AWS, discovered that the deployment from Task 8.1 (`d-TOT9JG8UI`) had failed due to a file-exists conflict. Resolved the issue by updating `before_install.sh` and re-deploying.

## What Was Implemented

### `components/deployment_monitor.py`

Five functions implemented:

1. **`get_deployment_status(deployment_id)`** — Calls `codedeploy.get_deployment()` and returns a dict with deployment_id, status, deployment_config, create_time, complete_time, rollback_info, and error_info.

2. **`get_instance_targets(deployment_id)`** — Uses `list_deployment_targets` + `batch_get_deployment_targets` to get per-instance details including target_id, status, and lifecycle_events.

3. **`get_lifecycle_events(deployment_id, target_id)`** — Retrieves lifecycle event data for a specific target using `batch_get_deployment_targets` with a single target ID.

4. **`wait_for_deployment(deployment_id, poll_interval_seconds)`** — Polls every N seconds, prints timestamped status updates, and returns the final status string when a terminal state is reached (Succeeded, Failed, Stopped, Ready).

5. **`list_deployments(app_name, group_name)`** — Uses `list_deployments` + `batch_get_deployments` to retrieve full deployment history with details.

## Verification Against Live AWS

When the monitor was used to check deployment status:

- **`d-JTQ4047UI`** (Task 8.1 first attempt): Failed — `IAM_ROLE_PERMISSIONS` (the IAM issue fixed earlier)
- **`d-TOT9JG8UI`** (Task 8.1 second attempt): Failed — `HEALTH_CONSTRAINTS` error
- **ALB target group**: 2 original blue instances healthy (`i-0426bac3d62e7d40a`, `i-0e5debb354d390c70`)

## File Conflict Error

### Root Cause

Deployment `d-TOT9JG8UI` failed at the `Install` lifecycle event because `/var/www/html/index.html` already existed on the green instances. The launch template user data installs Apache and creates a default page, and CodeDeploy's `Install` step then tries to copy `index.html` to the same location — failing because the file is already there.

### Resolution Options Considered

1. **`BeforeInstall` hook cleanup** (recommended) — Add `rm -rf /var/www/html/*` to `before_install.sh` to clear the target directory before CodeDeploy copies files. This is explicit, self-documenting, and teaches the purpose of lifecycle hooks.

2. **`file_exists_behavior: OVERWRITE`** — Set on the deployment to silently overwrite existing files. Works but is a blunter instrument that can mask unexpected file conflicts.

### Resolution Applied

Updated `blue-green-deploy/app-source/scripts/before_install.sh` to add the cleanup step:

```bash
echo "BeforeInstall: cleaning /var/www/html/ to avoid file-exists conflicts..."
rm -rf /var/www/html/*
```

Then rebuilt and re-uploaded the revision bundle to S3, and triggered a new deployment.

### New Deployment

- Rebuilt revision bundle with updated `before_install.sh`
- Re-uploaded to `s3://blue-green-deploy-revisions-628326705801/revisions/v1.zip`
- Triggered deployment **`d-3SQG2Y7UI`** with `CodeDeployDefault.AllAtOnce`
- Status confirmed: `InProgress`

## Key Files

| File | Action |
|------|--------|
| `blue-green-deploy/components/deployment_monitor.py` | Created — full monitoring module |
| `blue-green-deploy/app-source/scripts/before_install.sh` | Updated — added `/var/www/html/*` cleanup |
| `blue-green-deploy/revision.zip` | Rebuilt with updated hook script |
| S3 `revisions/v1.zip` | Re-uploaded |

## Deployment History

| Deployment ID | Config | Status | Issue |
|---------------|--------|--------|-------|
| `d-JTQ4047UI` | AllAtOnce | Failed | IAM permissions (fixed in 8.1) |
| `d-TOT9JG8UI` | AllAtOnce | Failed | File-exists conflict at Install |
| `d-3SQG2Y7UI` | AllAtOnce | InProgress | Fixed revision with BeforeInstall cleanup |

## Monitoring Commands

```bash
# Poll until complete
python3 -c "
import sys; sys.path.insert(0, 'blue-green-deploy')
from components.deployment_monitor import wait_for_deployment
wait_for_deployment('d-3SQG2Y7UI', poll_interval_seconds=30)
"

# Quick status check
aws deploy get-deployment --deployment-id d-3SQG2Y7UI --query 'deploymentInfo.status'
```
