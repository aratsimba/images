# Task 6.2 — Add Prod Deployment Stage with Manual Approval

## What was done
Added `addProdStageWithApproval()` method to `PipelineStack` that creates an `ApplicationStage` with `stageName: "Prod"` and adds it to the pipeline with a `ManualApprovalStep("PromoteToProd")` as a `pre` step. This ensures the pipeline pauses for human approval before deploying to production.

## Key files changed
- `cicd-pipeline/lib/pipeline-stack.ts` — added `addProdStageWithApproval()` method, called it from constructor after `addDevStage()`

## Issues
- Same `this.pipeline.stack.env` issue as 6.1, resolved the same way with `this.account`/`this.region`.
