# Task 9 - End-to-End Pipeline Verification

## What Was Done
- Changed Lambda response from "Hello from pipeline!" to "Hello CI/CD!"
- Pushed to CodeCommit; pipeline auto-triggered
- All 6 pipeline stages succeeded: Source → Build → UpdatePipeline → Assets → Dev → Prod
- Lint and SecurityScan ran in parallel within Dev stage, both passed
- Invoked both Dev and Prod Lambdas — both returned updated "Hello CI/CD!" response

## Pipeline Execution
- Execution ID: `1f9bffb0-c8e5-4b67-ae84-42a55796eb1b`
- Trigger: CloudWatchEvent (automatic on push)
- Status: Succeeded

## Issues
- Pipeline name was `AppPipeline` (not `PipelineStack-Pipeline` as initially guessed)
- Manual approval was already granted during the run, so no manual step was needed
