# Task 9.3 Verify Failure Handling — Conversation History

## Task Description

- **Property 2: Pipeline Failure Propagation**
- Introduce a deliberate syntax error in the Lambda code, push, and verify the build stage fails and the pipeline halts (Requirement 3.3)
- Revert the error, introduce a lint violation, push, and verify the lint step fails and deployment does not proceed (Requirement 7.4)
- Test approval rejection: trigger the pipeline, then reject the manual approval and verify Prod deployment does not occur (Requirement 6.2)
- **Validates: Requirements 3.3, 5.4, 6.2, 7.4**

---

## Mini Lecture

Before starting, a beginner-friendly lecture was delivered covering:

- **What we're building**: Not building anything new — breaking things on purpose to confirm the pipeline catches mistakes (a "fire drill" for CI/CD).
- **Key concept — Failure Propagation**: Compared to a factory assembly line where quality inspectors halt the line when a broken toy is found. Each pipeline stage (build, lint, security scan, approval) acts as an inspector.
- **How it works**:
  1. Break the build with a syntax error → pipeline halts
  2. Break the linter with a style violation → pipeline halts before deployment
  3. Reject manual approval → Prod deployment never happens
  4. Clean up after each test
- **Game plan visual flow** was provided showing the three failure scenarios.
- **Comprehension question**: "If the linting step fails, should the pipeline continue and deploy your code to the Dev environment?" (Answer: No)

User confirmed readiness: **Yes**

---

## Execution Steps

### 1. Context Gathering

Read the following files to understand the current project state:
- `cicd-pipeline/lambda/index.ts` — Lambda handler returning `{ statusCode: 200, body: 'Hello CI/CD!' }`
- `cicd-pipeline/lib/pipeline-stack.ts` — Pipeline stack with Dev stage (lint + security scan as pre-steps) and Prod stage (ManualApprovalStep)
- `cicd-pipeline/lib/buildspec-configs.ts` — Factory functions for synth, lint, and security scan steps
- `cicd-pipeline/package.json` — Project dependencies including fast-check for property testing
- `cicd-pipeline/.eslintrc.json` — ESLint config with TypeScript rules
- `cicd-pipeline/test/pipeline-stages.test.ts` — Existing Property 1 test (stage ordering)
- `cicd-pipeline/jest.config.js` — Jest configuration

### 2. Property Test Creation

Created `cicd-pipeline/test/pipeline-failure-propagation.test.ts` with 4 property-based tests:

- **Property 2a: Validation steps gate Dev deployment** — Verifies lint and security scan actions have lower RunOrder than Dev deploy actions, ensuring validation failure blocks deployment. (Validates Requirement 7.4)

- **Property 2b: Validation steps run in parallel** — Verifies lint and security scan share the same RunOrder for parallel execution. (Validates Requirement 7.3)

- **Property 2c: Manual approval gates Prod deployment** — Verifies the ManualApproval action has lower RunOrder than Prod deploy actions, ensuring rejection prevents production deployment. (Validates Requirement 6.2)

- **Property 2d: Build stage precedes all deployment stages** — Verifies Build stage index is less than both Dev and Prod stage indices, ensuring build failure blocks all deployments. (Validates Requirement 3.3)

Each property runs 20 randomized configurations using fast-check, varying repository name, branch, account ID, and region.

### 3. Test Execution Results

**Pipeline failure propagation tests:**
```
PASS  test/pipeline-failure-propagation.test.ts (18.186 s)
  Property Test - Pipeline Failure Propagation
    ✓ Property 2a: validation steps (lint, security scan) run before Dev deployment actions (2882 ms)
    ✓ Property 2b: lint and security scan steps execute in parallel (same RunOrder) (2655 ms)
    ✓ Property 2c: manual approval action precedes Prod deployment actions (2246 ms)
    ✓ Property 2d: build stage failure blocks all downstream deployment stages (2719 ms)
```

**Full test suite:**
```
PASS  test/cicd-pipeline.test.ts (14.131 s)
PASS  test/pipeline-stages.test.ts (19.341 s)
PASS  test/pipeline-failure-propagation.test.ts (26.389 s)

Test Suites: 3 passed, 3 total
Tests:       6 passed, 6 total
```

### 4. Task Marked Complete

---

## Manual Verification Steps (for the learner)

These require pushing to CodeCommit and observing the live pipeline in the AWS console:

1. **Build failure test** — Add a syntax error to `lambda/index.ts` (e.g., remove a closing brace), commit & push. Watch the Build stage fail in the CodePipeline console. Revert after confirming.

2. **Lint failure test** — Add a lint violation like `var x: any = 123;` to `lambda/index.ts`, commit & push. Watch the Lint step fail and confirm Dev deployment doesn't proceed. Revert after confirming.

3. **Approval rejection test** — Push clean code, let the pipeline run to the PromoteToProd approval gate, then click "Reject" in the CodePipeline console. Confirm Prod deployment never executes.

---

## Artifacts Created

| File | Description |
|------|-------------|
| `cicd-pipeline/test/pipeline-failure-propagation.test.ts` | Property-based test with 4 properties validating failure propagation structure |
