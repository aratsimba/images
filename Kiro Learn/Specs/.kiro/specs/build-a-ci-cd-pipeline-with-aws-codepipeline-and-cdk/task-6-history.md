# Task 6 — Multi-Environment Deployment and Approval Gate

## What was done
Implemented multi-environment deployment by adding Dev and Prod stages to the CDK Pipeline. The Dev stage deploys first, followed by a manual approval gate (`PromoteToProd`), then the Prod stage. Both stages use `ApplicationStage` with the pipeline stack's account/region.

## Key files changed
- `cicd-pipeline/lib/pipeline-stack.ts` — added `ApplicationStage` import, `addDevStage()` and `addProdStageWithApproval()` methods, wired both into the constructor

## Issues
- TypeScript compilation error: `CodePipeline` doesn't expose a `.stack` property. Resolved by using `this.account` and `this.region` inherited from `cdk.Stack`.
