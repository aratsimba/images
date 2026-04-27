# Task 8: Checkpoint - Full Pipeline Deployment and Self-Mutation — Conversation History

## Mini Lecture

Provided a beginner-friendly lecture covering:
- What a checkpoint is (analogy: building inspector checking a house before drywall)
- The four verification steps: synthesize, deploy, push & trigger, verify self-mutation
- Visual game plan flow from `cdk synth` through all pipeline stages

User confirmed ready to start.

## Step 1: Code Review and Initial Synthesis

- Reviewed all project files: `pipeline-stack.ts`, `application-stack.ts`, `application-stage.ts`, `buildspec-configs.ts`, `bin/pipeline-app.ts`, `cdk.json`, `package.json`, `lambda/index.ts`, and test file
- Ran `cdk synth` — succeeded, confirming all pipeline stages present:
  - Source → Build → UpdatePipeline → Assets → Dev (Lint + SecurityScan parallel at RunOrder 1) → Prod (ManualApproval + deploy)
- Ran `npm test` — passed

## Step 2: Provided Deployment & Verification Instructions

Gave the user step-by-step instructions for:
1. `cdk deploy PipelineStack`
2. Push code to CodeCommit
3. Verify stages in CodePipeline console
4. Test self-mutation (Req 4.1, 4.2)
5. Test no-op self-mutation (Req 4.3)
6. Verify parallel validation steps

## Issue 1: package-lock.json Out of Sync

**Problem:** Build stage failed in CodePipeline with `npm ci` error — `package-lock.json` had older versions of eslint (8.x) and typescript-eslint (7.x) while `package.json` specified newer versions (eslint 10.x, typescript-eslint 8.x).

**Root Cause:** The lock file was generated with older package versions and never regenerated after `package.json` was updated.

**Fix Attempted:** Ran `npm install` to regenerate lock file, but discovered eslint 10.x requires Node.js 20+ while the environment had Node.js 18.

## Issue 2: Node.js Version Too Old

**Problem:** eslint 10.x and its dependencies require Node.js ^20.19.0 || ^22.13.0 || >=24, but the active Node was v18.20.2.

**Discovery:** Node.js was managed by `mise` (not Homebrew). Homebrew had `node@20` installed but `mise` was overriding with v18.20.2.

**Fix:** 
- Installed Node.js 22 via mise: `mise install node@22`
- Set as active: `mise use node@22` → now v22.22.2
- Decided to stick with eslint@8 and @typescript-eslint@7 for stability (avoids eslint flat config migration)
- Reinstalled: `npm install --save-dev eslint@8 @typescript-eslint/parser@7 @typescript-eslint/eslint-plugin@7`
- Verified lint, synth, and tests all pass

## Issue 3: Lambda Runtime Not Compatible with CDK 2.161.0

**Problem:** Build stage failed with: `Property 'NODEJS_22_X' does not exist on type 'typeof Runtime'`

**Root Cause:** `NODEJS_22_X` was added in a CDK version newer than 2.161.0 (the version pinned in the project).

**Fix:** Changed `lambda.Runtime.NODEJS_22_X` to `lambda.Runtime.NODEJS_20_X` in `lib/application-stack.ts`. Build and synth passed.

## Issue 4: cfn_nag_scan Failing on Non-Template Files

**Problem:** SecurityScan step failed because `cfn_nag_scan --input-path cdk.out/` scanned all files recursively, including `manifest.json`, `tree.json`, and assembly directory manifests that aren't CloudFormation templates.

**Error:** `Illegal cfn - no Resources` for `manifest.json`, `tree.json`, and assembly manifests.

**Fix:** Updated `createSecurityScanStep()` in `lib/buildspec-configs.ts` to scan only `*.template.json` files:
```
'for template in $(find cdk.out -name "*.template.json"); do cfn_nag_scan --input-path "$template"; done'
```

Also updated `tasks.md` task 7.1 to reflect this change.

## Summary of Changes Made

| File | Change |
|------|--------|
| `cicd-pipeline/package.json` | eslint pinned to ^8.57.1, typescript-eslint to ^7.18.0 |
| `cicd-pipeline/package-lock.json` | Regenerated to sync with package.json |
| `cicd-pipeline/lib/application-stack.ts` | Runtime changed from `NODEJS_22_X` to `NODEJS_20_X` |
| `cicd-pipeline/lib/buildspec-configs.ts` | cfn_nag_scan now targets only `*.template.json` files |
| `.kiro/specs/.../tasks.md` | Task 7.1 updated to reflect cfn_nag_scan fix |
| Local environment | Node.js upgraded from v18.20.2 to v22.22.2 via mise |

## Task Status: ✅ Completed
