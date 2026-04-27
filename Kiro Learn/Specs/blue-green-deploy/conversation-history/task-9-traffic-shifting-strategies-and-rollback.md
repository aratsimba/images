# Task 9 — Traffic Shifting Strategies and Rollback

## Overview

Task 9 covered two subtasks: experimenting with different EC2 deployment configurations (HalfAtATime, OneAtATime) and testing deployment rollback (automatic and manual).

---

## Task 9.1 — Experiment with Canary and Linear Strategies

### What Was Done

1. **Updated index.html to Version 2.0** with styled content indicating the HalfAtATime strategy.
2. **Bundled and uploaded `revisions/v2.zip`** to S3 bucket `blue-green-deploy-revisions-628326705801`.
3. **Created `trigger_half_at_a_time.py`** — triggers a deployment using `CodeDeployDefault.HalfAtATime`, monitors with `wait_for_deployment()`, and prints instance target details.
4. **Ran the HalfAtATime deployment** (`d-29D6UYQUI`) — succeeded. Instances were deployed in two batches.
5. **Updated index.html to Version 3.0** with OneAtATime strategy labeling.
6. **Bundled and uploaded `revisions/v3.zip`** to S3.
7. **Created `trigger_one_at_a_time.py`** — triggers a deployment using `CodeDeployDefault.OneAtATime`.
8. **Ran the OneAtATime deployment** (`d-C13WWKRUI`) — succeeded. Instances were deployed one at a time.

### Key Note — EC2 vs Lambda/ECS

On EC2/On-Premises, true canary/linear percentage-based traffic shifting is NOT available. EC2 uses instance-count-based configs:
- `CodeDeployDefault.AllAtOnce` — all instances at once
- `CodeDeployDefault.HalfAtATime` — half, then the other half
- `CodeDeployDefault.OneAtATime` — one instance at a time

Canary (10% then 90%) and linear (equal increments) are only for Lambda and ECS compute platforms.

### Files Created
- `blue-green-deploy/trigger_half_at_a_time.py`
- `blue-green-deploy/trigger_one_at_a_time.py`
- `blue-green-deploy/app-source/src/index.html` (updated to v3.0)
- S3: `revisions/v2.zip`, `revisions/v3.zip`

---

## Task 9.2 — Test Deployment Rollback

### Part A — Automatic Rollback Test

1. **Created `validate_service_fail.sh`** — a hook script that always exits with code 1.
2. **Created `trigger_failing_deployment.py`** — generates an appspec using the failing ValidateService hook, bundles as `v4-fail.zip`, deploys, and monitors.
3. **Ran the failing deployment** (`d-HHD49HSUI`) — failed at ValidateService as expected. Traffic never shifted to green; blue environment continued serving.

### Part B — Implement stop_deployment()

4. **Added `stop_deployment(deployment_id, auto_rollback)` to `deployment_monitor.py`**:
   - Calls `codedeploy.stop_deployment()`
   - Handles `DeploymentAlreadyCompletedException` gracefully
   - Prints status messages

### Part C — Manual Stop Test

5. **Created `trigger_and_stop_deployment.py`** — deploys v5.zip (valid revision), waits for InProgress state, then calls `stop_deployment()`.
6. **Ran the manual stop test** (`d-HOZWKISUI`) — deployment was successfully stopped mid-flight. Traffic remained on the blue environment.

### Part D — Deployment History

7. **Verified deployment history** via `list_deployments()` — showed all 7 deployments including Failed (rollback) and Stopped events.

### Files Created/Modified
- `blue-green-deploy/app-source/scripts/validate_service_fail.sh` (new)
- `blue-green-deploy/trigger_failing_deployment.py` (new)
- `blue-green-deploy/trigger_and_stop_deployment.py` (new)
- `blue-green-deploy/components/deployment_monitor.py` (added `stop_deployment()`)
- S3: `revisions/v4-fail.zip`, `revisions/v5.zip`

---

## Post-Task Discussion

### Traffic Verification Gap

After completing the task, a review identified that traffic verification was lighter than ideal:

**What was done:** Relied on CodeDeploy's reported deployment status, instance target lifecycle events, and deployment history.

**What was NOT done:**
- No `curl` against the ALB DNS to confirm served content changed
- No `describe-target-health` call to verify which instance IDs were registered/deregistered
- No before/after comparison of target group membership

The `get_target_group_health()` function exists in `infra_manager.py` but wasn't used. For production scenarios, independently verifying at the load balancer level is recommended.

---

## Deployment History Summary

| Deployment ID | Config | Version | Status | Notes |
|---|---|---|---|---|
| (earlier) | AllAtOnce | v1 | Succeeded | Task 8 |
| d-29D6UYQUI | HalfAtATime | v2 | Succeeded | Task 9.1 |
| d-C13WWKRUI | OneAtATime | v3 | Succeeded | Task 9.1 |
| d-HHD49HSUI | AllAtOnce | v4-fail | Failed | Task 9.2 — auto rollback |
| d-HOZWKISUI | AllAtOnce | v5 | Stopped | Task 9.2 — manual stop |
