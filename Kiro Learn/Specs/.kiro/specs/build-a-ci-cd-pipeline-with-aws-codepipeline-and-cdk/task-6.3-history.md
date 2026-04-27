# Task 6.3 - Property Test: Pipeline Stage Ordering

## Task Details
- **Property 1: Sequential Stage Execution**
- **Validates: Requirements 4.1, 4.2, 5.1, 5.2**

## Conversation History

### 1. Pre-Task Lecture

A mini lecture was delivered covering:

- **What we're building:** A property test that checks whether pipeline stages always appear in the correct order — Dev before Prod, with a manual approval gate between them.
- **Key concept (analogy):** Property testing is like a building inspector checking structural rules (foundation below first floor, roof above second floor). Our "structural rule" is that pipeline stages must flow: Source → Build → Self-Update → Validation/Dev → Approval → Prod.
- **How it works:**
  1. Create the pipeline stack in a test environment (no real AWS account needed — CDK synthesizes locally).
  2. Use CDK's `assertions` library to inspect the generated CloudFormation template.
  3. Find all pipeline stages and check their order.
  4. Verify ManualApproval appears before Prod deployment.
- **Game plan flow:** Instantiate PipelineStack → Synthesize to CloudFormation → Extract stage definitions → Assert Dev before Prod → Assert ManualApproval before Prod deploy.
- **Comprehension check:** Why test stage ordering? Because someone could accidentally swap `addDevStage()` and `addProdStageWithApproval()`, deploying straight to production without Dev.

**User confirmed readiness:** Yes

### 2. Context Gathering

Read the following files to understand the codebase:
- `cicd-pipeline/lib/pipeline-stack.ts` — PipelineStack with `addDevStage()` and `addProdStageWithApproval()`
- `cicd-pipeline/lib/application-stage.ts` — ApplicationStage wrapping ApplicationStack
- `cicd-pipeline/lib/buildspec-configs.ts` — Factory functions for synth, lint, and security scan steps
- `cicd-pipeline/bin/pipeline-app.ts` — CDK app entry point
- `cicd-pipeline/test/cicd-pipeline.test.ts` — Existing placeholder test
- `cicd-pipeline/package.json` — Jest + ts-jest, aws-cdk-lib 2.161.0
- `cicd-pipeline/jest.config.js` — Test config (roots: test/, match: *.test.ts)

### 3. Implementation

Created `cicd-pipeline/test/pipeline-stages.test.ts` with:

- **Library:** fast-check for property-based testing
- **Approach:** Synthesizes PipelineStack with randomized configurations (repo names, branches, accounts, regions) across 20 runs
- **Helper functions:**
  - `synthesizePipelineStages()` — Creates a PipelineStack, calls `pipeline.buildPipeline()` to materialize stages, extracts stages from the CloudFormation template
  - `findStageIndex()` — Finds a stage by name pattern in the stages array
- **Assertions verified per run:**
  1. All key stages exist (Source, Build, UpdatePipeline, Dev, Prod)
  2. Sequential ordering: Source < Build < UpdatePipeline < Dev < Prod
  3. Prod stage contains a ManualApproval action

### 4. Test Execution

All 20 property-based test runs passed, confirming the pipeline stage ordering property holds across varied configurations.

## Outcome

Task completed successfully. The property test validates Requirements 4.1, 4.2, 5.1, and 5.2 by ensuring pipeline stages are always sequentially ordered and the Prod deployment is gated by manual approval.
