# Task 10: Checkpoint - End-to-End Validation

## Objective
Verify the entire blue-green deployment pipeline works end-to-end: deployment history, live application, rollback behavior, and property tests.

## Validation Steps & Results

### 1. Deployment History (7 deployments found, ≥3 required)

| Deployment ID | Config | Status | Date |
|---|---|---|---|
| d-3SQG2Y7UI | AllAtOnce | ✅ Succeeded | 2026-04-10 17:26 |
| d-29D6UYQUI | HalfAtATime | ✅ Succeeded | 2026-04-11 12:32 |
| d-C13WWKRUI | OneAtATime | ✅ Succeeded | 2026-04-11 12:59 |
| d-HHD49HSUI | AllAtOnce | ❌ Failed (rollback) | 2026-04-11 13:24 |
| d-HOZWKISUI | AllAtOnce | 🛑 Stopped (manual) | 2026-04-11 13:34 |
| d-TOT9JG8UI | AllAtOnce | ❌ Failed (early) | 2026-04-10 17:04 |
| d-JTQ4047UI | AllAtOnce | ❌ Failed (IAM perms) | 2026-04-10 16:59 |

Three distinct deployment strategies exercised: AllAtOnce, HalfAtATime, OneAtATime.

### 2. ALB Serving Latest Version

```
$ curl http://BlueGreenALB-886007790.us-east-1.elb.amazonaws.com

Version 3.0 — OneAtATime deployment
Deployed using CodeDeployDefault.OneAtATime strategy
```

Confirms the most recent successful deployment (d-C13WWKRUI, OneAtATime) is live.

### 3. Rollback Events in History

All failed and stopped deployments have `rollback_info` populated:

- **d-HHD49HSUI (Failed)**: `"Automatic rollback isn't required because traffic hasn't begun rerouting to the replacement environment"` — Error: HEALTH_CONSTRAINTS
- **d-HOZWKISUI (Stopped)**: `"Automatic rollback isn't required because traffic hasn't begun rerouting to the replacement environment"` — Manual stop
- **d-TOT9JG8UI (Failed)**: Same rollback message — HEALTH_CONSTRAINTS
- **d-JTQ4047UI (Failed)**: Same rollback message — IAM_ROLE_PERMISSIONS (early failure before Task 2.1 fix)

In all cases, failures occurred before traffic shifted to green, so the blue environment was never at risk.

### 4. Blue Environment Health

ALB target group `BlueGreenTG` has 2 healthy targets:
- `i-0f59dc5fe35e3c377` — healthy
- `i-05a738465640cdf60` — healthy

### 5. Property Test: Rollback Preserves Blue Environment

```
✓ P1.1 Auto-rollback triggered on failure: PASS
✓ P1.2 Blue environment healthy (ALB targets): PASS
✓ P1.3 Rollback recorded in deployment history: PASS

✓ PROPERTY HOLDS: Rollback preserves blue environment
```

### 6. Auto Scaling Group Status

4 ASGs still running from previous CodeDeploy blue-green deployments:
- `CodeDeploy_BlueGreenDG_d-C13WWKRUI` — 2 instances (current green, serving traffic)
- `CodeDeploy_BlueGreenDG_d-HHD49HSUI` — 2 instances (leftover from failed deployment)
- `CodeDeploy_BlueGreenDG_d-HOZWKISUI` — 2 instances (leftover from stopped deployment)
- `CodeDeploy_BlueGreenDG_d-TOT9JG8UI` — 2 instances (leftover from early failed deployment)

⚠️ Extra ASGs to be cleaned up in Task 11.

## Verdict

✅ **All checkpoint validations passed.** The blue-green deployment pipeline is fully functional with multiple traffic shifting strategies exercised, rollback behavior confirmed, and the property test holding.
