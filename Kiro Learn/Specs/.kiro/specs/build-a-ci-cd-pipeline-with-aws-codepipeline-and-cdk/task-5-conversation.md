# Task 5 - Application Stage and Stack — Conversation History

## Context
Executing Task 5 from the CI/CD pipeline spec, which includes subtasks 5.1 (ApplicationStack) and 5.2 (ApplicationStage).

---

## Pre-Task Lecture (Task 5)

Provided a beginner-friendly lecture covering:
- **What we're building**: The application that the pipeline will deploy — a Lambda function wrapped in a Stage so the pipeline knows where to deliver it.
- **Key analogy**: Stack = the gift (actual app), Stage = the labeled shipping box (tells pipeline which environment).
- **Game plan**: Lambda handler → ApplicationStack → ApplicationStage → Ready for pipeline.

User confirmed ready to start.

---

## Subtask 5.1 — Create ApplicationStack

### Pre-Task Lecture
- Explained Lambda functions using a food truck analogy (only runs when called, unlike a restaurant that's always open).
- Covered why handler code lives in a separate `lambda/` folder (infrastructure vs. application code separation).

User confirmed ready.

### Implementation
1. Created `cicd-pipeline/lambda/index.ts`:
   - Simple async handler returning `{ statusCode: 200, body: "Hello from pipeline!" }`

2. Created `cicd-pipeline/lib/application-stack.ts`:
   - `ApplicationStack` extends `cdk.Stack`
   - `createLambdaFunction(functionName)` method creates a Lambda with:
     - Runtime: `NODEJS_18_X`
     - Handler: `index.handler`
     - Code: `lambda.Code.fromAsset(path.join(__dirname, '..', 'lambda'))`
   - Constructor derives function name from stack ID and calls `createLambdaFunction()`

### Verification
- `getDiagnostics` on both files: no issues found.

---

## Subtask 5.2 — Create ApplicationStage

### Pre-Task Lecture
- Used theater stage analogy: a named container that holds stacks and tells the pipeline where to deploy.
- Same "show" (ApplicationStack) can play on different "stages" (Dev, Prod).

User confirmed ready.

### Implementation
1. Created `cicd-pipeline/lib/application-stage.ts`:
   - `ApplicationStageProps` interface extends `cdk.StageProps` with `stageName: string`
   - `ApplicationStage` extends `cdk.Stage`
   - Constructor instantiates `ApplicationStack` using `${props.stageName}-ApplicationStack`

### Verification
- `getDiagnostics`: no issues found.
- `cdk synth`: completed successfully (exit code 0). Pipeline stack synthesized correctly with all existing resources intact. New files compile cleanly alongside existing code.

---

## Final Status
- **Task 5**: ✅ Completed
- **Subtask 5.1**: ✅ Completed
- **Subtask 5.2**: ✅ Completed

## Files Created
- `cicd-pipeline/lambda/index.ts`
- `cicd-pipeline/lib/application-stack.ts`
- `cicd-pipeline/lib/application-stage.ts`

## Issues Encountered
- None
