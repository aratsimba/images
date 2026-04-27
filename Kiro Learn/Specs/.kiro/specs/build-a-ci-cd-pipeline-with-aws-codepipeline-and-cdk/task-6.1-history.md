# Task 6.1 — Add Dev Deployment Stage

## What was done
Added `addDevStage()` method to `PipelineStack` that creates an `ApplicationStage` with `stageName: "Dev"` using the same account/region as the pipeline stack, then adds it to the pipeline via `pipeline.addStage()`.

## Key files changed
- `cicd-pipeline/lib/pipeline-stack.ts` — added import for `ApplicationStage`, added `addDevStage()` method, called it from constructor

## Issues
- Initial implementation used `this.pipeline.stack.env` which doesn't exist on `CodePipeline`. Fixed by using `this.account` and `this.region` from the Stack base class.
