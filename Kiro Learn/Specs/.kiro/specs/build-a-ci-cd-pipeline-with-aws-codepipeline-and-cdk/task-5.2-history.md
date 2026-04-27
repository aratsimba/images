# Task 5.2 - Create ApplicationStage

## What was done
- Created `lib/application-stage.ts` with `ApplicationStage` class extending `cdk.Stage`
- Defined `ApplicationStageProps` interface extending `StageProps` with `stageName` field
- Constructor instantiates `ApplicationStack` inside the stage, using `stageName` for resource naming
- Verified `cdk synth` completes successfully with no errors

## Files created
- `cicd-pipeline/lib/application-stage.ts`

## Issues
- None
