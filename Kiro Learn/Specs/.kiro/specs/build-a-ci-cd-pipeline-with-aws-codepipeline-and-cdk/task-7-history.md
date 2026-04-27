# Task 7 — Validation Steps: Linting and Security Scanning

## Overview

Task 7 added automated linting and security scanning as parallel validation steps that run before the Dev deployment stage in the CI/CD pipeline.

---

## Task 7.1 — Create Lint and Security Scan Steps

### Mini Lecture

Before coding, a beginner-friendly lecture was presented using a publishing analogy: two editors (linter and security scanner) review an essay in parallel before it gets published. If either finds a problem, publication is blocked.

### Steps Performed

1. **Installed ESLint and TypeScript plugins**
   - Initially installed ESLint v10, but it required Node 20+. The project runs Node 18.
   - Downgraded to ESLint v8 with compatible TypeScript plugins:
     ```
     npm install --save-dev eslint@8 @typescript-eslint/parser@7 @typescript-eslint/eslint-plugin@7
     ```

2. **Added lint script to `package.json`**
   - Added `"lint": "npx eslint . --ext .ts"` to the scripts section.

3. **Created `.eslintrc.json`**
   - Configured ESLint with `@typescript-eslint/parser`, recommended rulesets, and ignore patterns for `.js`, `.d.ts`, `node_modules/`, and `cdk.out/`.

4. **Updated `lib/buildspec-configs.ts`**
   - Added `createLintStep(source)` — returns a `ShellStep` running `npm ci` then `npm run lint`.
   - Added `createSecurityScanStep(source)` — returns a `ShellStep` that installs dependencies, builds, runs `cdk synth`, installs `cfn-nag` via `gem install`, and runs `cfn_nag_scan --input-path cdk.out/`.

5. **Verification**
   - `npm run lint` passed locally.
   - No TypeScript diagnostics in `buildspec-configs.ts`.

---

## Task 7.2 — Add Validation Stage to Pipeline

### Mini Lecture

A restaurant kitchen analogy was used: before a dish goes to the dining room (deployment), two quality checkers work side by side — one checks presentation, the other checks temperature. Both must pass before the dish leaves the kitchen.

### Steps Performed

1. **Updated imports in `lib/pipeline-stack.ts`**
   - Added `createLintStep` and `createSecurityScanStep` to the import from `./buildspec-configs`.

2. **Refactored `PipelineStack`**
   - Added a private `source` field to store the `CodePipelineSource` reference.
   - Changed `createPipeline()` to return both the pipeline and source objects.
   - Updated the constructor to destructure and store both.

3. **Refactored `addDevStage()`**
   - Creates lint and security scan steps using the stored source reference.
   - Passes both as `pre` options: `this.pipeline.addStage(devStage, { pre: [lintStep, securityScanStep] })`.
   - This makes them run in parallel before any Dev deployment actions.

4. **Verification**
   - `cdk synth` succeeded — both `Lint` and `SecurityScan` actions confirmed in `PipelineStack.template.json`.
   - `npm test` passed (1 test suite, 1 test).
   - No TypeScript diagnostics in `pipeline-stack.ts`.

---

## Files Modified

| File | Change |
|------|--------|
| `cicd-pipeline/package.json` | Added `"lint"` script, added ESLint dev dependencies |
| `cicd-pipeline/.eslintrc.json` | Created — ESLint config with TypeScript support |
| `cicd-pipeline/lib/buildspec-configs.ts` | Added `createLintStep()` and `createSecurityScanStep()` |
| `cicd-pipeline/lib/pipeline-stack.ts` | Stored source ref, refactored `addDevStage()` with pre-validation steps |

## Final State

- Pipeline now includes: Source → Build → Self-Mutation → Lint + SecurityScan (parallel) → Dev Deploy → Manual Approval → Prod Deploy
- All tests pass, `cdk synth` succeeds, lint passes locally
