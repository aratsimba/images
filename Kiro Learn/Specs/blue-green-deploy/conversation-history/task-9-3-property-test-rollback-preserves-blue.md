# Task 9.3 — Property Test: Rollback Preserves Blue Environment

## Overview

Task 9.3 is a property-based test that validates Requirements 8.1, 8.2, and 8.3 — ensuring that when a blue-green deployment fails, the original blue environment remains intact and continues serving traffic.

## What Was Built

Created `blue-green-deploy/test_property_rollback_preserves_blue.py` — a standalone property test script that queries live AWS deployment history and ALB health to verify three sub-properties:

- **P1.1 Auto-rollback triggered on failure** — Checks that the failed deployment's `rollback_info` is populated, confirming CodeDeploy acknowledged the failure and either rolled back or determined rollback wasn't needed.
- **P1.2 Blue environment healthy (ALB targets)** — Queries the ALB target group (`BlueGreenTG`) and verifies at least one target is in `healthy` state, confirming the blue environment is still serving traffic.
- **P1.3 Rollback recorded in deployment history** — Checks for either (a) a separate rollback deployment in history linked to the failed deployment, or (b) a rollback message indicating rollback wasn't required because traffic never shifted away from blue.

## Key Design Decisions

1. **Non-destructive test** — The script queries existing deployment history rather than triggering new deployments, making it safe to run repeatedly.
2. **Two rollback mechanisms handled** — CodeDeploy has two paths when a deployment fails:
   - If traffic had already begun shifting, a separate rollback deployment is created.
   - If the failure occurred before traffic shifting (e.g., during lifecycle hooks on green instances), CodeDeploy reports "Automatic rollback isn't required because traffic hasn't begun rerouting to the replacement environment." Both are valid evidence that the blue environment was preserved.
3. **Curly quote normalization** — AWS returns rollback messages with Unicode curly quotes (U+2019 `'`) instead of straight apostrophes. The P1.3 check normalizes these before string matching.

## Issues Encountered and Fixes

### P1.3 initially failed

**Problem**: The first version of `check_p1_3_history_records_rollback` only looked for a separate rollback deployment in history. In our environment, all failed deployments failed before traffic shifting began, so CodeDeploy never created rollback deployments — it just left traffic on blue.

**Fix**: Updated P1.3 to also accept the "rollback isn't required" message as valid evidence that the blue environment was preserved.

### Curly quotes in AWS messages

**Problem**: After the logic fix, P1.3 still failed because the string comparison used a straight apostrophe (`'`) but AWS returned curly quotes (`'` U+2019).

**Fix**: Added `rb_msg.replace("\u2019", "'")` normalization before the substring check.

## Test Execution Results

```
================================================================
  Property Test: Rollback Preserves Blue Environment
  (Requirements 8.1, 8.2, 8.3)
================================================================

[1/4] Fetching deployment history...
Found 7 deployment(s) for BlueGreenApp/BlueGreenDG

[2/4] Looking up ALB target group...
  Target group ARN: arn:aws:elasticloadbalancing:us-east-1:628326705801:targetgroup/BlueGreenTG/e2fc1e3372e26f07

[3/4] Checking properties...

  P1.1 Auto-rollback triggered on failure: ✓ PASS
  P1.2 Blue environment healthy (ALB targets): ✓ PASS
       healthy targets: ['i-0f59dc5fe35e3c377', 'i-05a738465640cdf60']
  P1.3 Rollback recorded in deployment history: ✓ PASS

[4/4] Verdict

================================================================
  ✓ PROPERTY HOLDS: Rollback preserves blue environment
================================================================
```

## Files Created/Modified

- **Created**: `blue-green-deploy/test_property_rollback_preserves_blue.py`
