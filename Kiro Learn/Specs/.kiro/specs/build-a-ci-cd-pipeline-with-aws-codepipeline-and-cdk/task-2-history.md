# Task 2: CDK Project Initialization and Bootstrap — Conversation History

## Context
- AWS Account ID: 628326705801
- Region: us-east-1
- Spec: Build a CI/CD Pipeline with AWS CodePipeline and CDK

---

## Task 2.1: Initialize CDK TypeScript Application

### Starting State
- `cicd-pipeline/` directory already existed with a CDK project initialized
- `package.json` already had `aws-cdk-lib` (2.161.0) and `constructs` (^10.0.0) as dependencies
- `node_modules/` already existed (dependencies installed)
- `cdk.json` already pointed to `npx ts-node --prefer-ts-exts bin/pipeline-app.ts`
- `tsconfig.json` existed and was configured
- `bin/` directory existed but was **empty** — `bin/pipeline-app.ts` needed to be created
- `lib/` directory existed but was **empty**
- `test/cicd-pipeline.test.ts` existed with a placeholder test

### Mini Lecture
- Analogy: Initializing a CDK project is like preparing a kitchen before cooking — you need the right workspace, tools, and organization.
- Key files explained: project directory = plot of land, entry point = front door, `cdk.json` = blueprint index, `package.json` = toolbox inventory.

### What Was Done
1. Verified project structure (bin/, lib/, cdk.json, package.json, tsconfig.json all present)
2. Confirmed dependencies were already installed
3. Confirmed `cdk.json` already pointed to `bin/pipeline-app.ts`
4. Created `bin/pipeline-app.ts` as a minimal CDK app entry point that instantiates `cdk.App()`
5. Ran `cdk synth` — reported "no stacks" which was expected (PipelineStack added in task 2.3)

### Result
✅ Completed successfully.

---

## Task 2.2: Bootstrap AWS Environment

### Mini Lecture
- Analogy: Bootstrapping is like setting up a construction staging area — storage yard (S3 bucket), security badges (IAM roles), container registry (ECR repo).
- Only needs to happen once per account/region.

### User Input
- AWS Account ID: 628326705801
- Preferred Region: us-east-1

### What Was Done
1. Ran `cdk bootstrap aws://628326705801/us-east-1` from the `cicd-pipeline/` directory
2. CDKToolkit stack created successfully (`CREATE_COMPLETE` status)
3. Verified all required resources:
   - S3 asset bucket: `cdk-hnb659fds-assets-628326705801-us-east-1`
   - ECR repository: `cdk-hnb659fds-container-assets-628326705801-us-east-1`
   - 5 IAM roles: CloudFormationExecutionRole, DeploymentActionRole, FilePublishingRole, ImagePublishingRole, LookupRole

### Result
✅ Completed successfully.

---

## Task 2.3: Configure CDK App Entry Point (Component 1: CDK App Entry Point)

### Mini Lecture
- Analogy: The CDK App is like a company headquarters building; each Stack is a department; the entry point is the reception desk; Props are setup instructions.
- Explained why account ID and region are needed (like a delivery address).

### What Was Done
1. Created `lib/pipeline-stack.ts` with:
   - `PipelineStackProps` interface extending `cdk.StackProps` with `repositoryName: string` and `mainBranch: string`
   - `PipelineStack` class extending `cdk.Stack` with an empty constructor (resources added in later tasks)

2. Updated `bin/pipeline-app.ts` to:
   - Import `PipelineStack` from `'../lib/pipeline-stack'`
   - Instantiate `PipelineStack` with:
     - `env: { account: '628326705801', region: 'us-east-1' }`
     - `repositoryName: 'pipeline-app-repo'`
     - `mainBranch: 'main'`

3. Ran `cdk synth` — produced a valid CloudFormation template successfully

### Files Created/Modified
- **Created:** `lib/pipeline-stack.ts`
- **Modified:** `bin/pipeline-app.ts`

### Result
✅ Completed successfully.

---

## Summary

All three subtasks of Task 2 completed successfully. The CDK project foundation is in place:
- Entry point (`bin/pipeline-app.ts`) creates a `PipelineStack` with environment config
- Minimal `PipelineStack` class and `PipelineStackProps` interface defined in `lib/pipeline-stack.ts`
- AWS environment bootstrapped with CDKToolkit stack in `628326705801`/`us-east-1`
- `cdk synth` produces a valid CloudFormation template

Next: Task 3 — Pipeline Stack with Source and Build Stages (CodeCommit repository + CDK Pipeline).
