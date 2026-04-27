# Task 3 — Pipeline Stack with Source and Build Stages: Conversation History

## Overview

Task 3 added the core pipeline infrastructure: a CodeCommit repository and a CDK Pipeline with source, build, and self-mutation stages.

---

## Mini Lecture — Task 3 (Parent)

### 🎯 What Are We Building?
The core of the CI/CD pipeline — a source code repository (CodeCommit) and a pipeline that watches it and automatically builds the project whenever new code is pushed.

### 💡 Key Concept: The Assembly Line
Like a car factory: raw materials (code) come in one end, and a finished product rolls out the other. Stations along the way handle specific jobs — the Source Stage grabs the latest code, and the Build/Synth Stage converts CDK code into CloudFormation templates (the blueprints AWS uses to create resources).

### 🔍 How It Works
1. Push code to CodeCommit → pipeline detects the change
2. Build Stage runs `npm ci` (install dependencies) and `cdk synth` (convert CDK to CloudFormation templates)
3. Output stored as artifacts for later stages
4. CDK Pipelines auto-creates a self-mutation stage

### Game Plan
```
PipelineStack
    ├──→ createRepository()  →  CodeCommit Repo
    ├──→ createSynthStep()   →  Build instructions
    └──→ createPipeline()    →  CodePipeline (Source → Build → Self-Mutation)
```

**User confirmed ready:** Yes

---

## Subtask 3.1 — Create PipelineStack with CodeCommit Repository

### Mini Lecture
- **Analogy:** CodeCommit is like a shared locker where the team stores project files. `createRepository()` tells AWS "build me a locker with this name."
- **Key steps:** Define PipelineStack class → accept props (repositoryName, mainBranch) → createRepository() creates a codecommit.Repository → store reference and export clone URLs

**User confirmed ready:** Yes

### Implementation
Updated `cicd-pipeline/lib/pipeline-stack.ts`:
- Imported `aws-cdk-lib/aws-codecommit`
- Added public `repository` property on PipelineStack
- Implemented `createRepository(repositoryName)` using `codecommit.Repository`
- Called `createRepository()` from the constructor
- Exported HTTPS and GRC clone URLs as CloudFormation outputs

**Verification:** `cdk synth` succeeded — template includes `AWS::CodeCommit::Repository` resource and clone URL outputs. Existing tests pass.

---

## Subtask 3.2 — Create Synth Step and Pipeline

### Mini Lecture
- **Analogy:** The synth step is a recipe card telling CodeBuild (the kitchen) what to do: install ingredients (`npm ci`), mix them (`npm run build`), plate the dish (`npx cdk synth`). The pipeline is the kitchen manager orchestrating everything.
- **Key steps:** Create buildspec-configs.ts with createSynthStep() → create CodePipelineSource.codeCommit() → wire synth step into pipelines.CodePipeline → self-mutation stage auto-created

**User confirmed ready:** Yes

### Implementation

**Created** `cicd-pipeline/lib/buildspec-configs.ts`:
- `createSynthStep(source)` returns a `CodeBuildStep` configured with:
  - Install commands: `npm ci`
  - Build commands: `npm run build`, `npx cdk synth`
  - Primary output directory: `cdk.out`

**Updated** `cicd-pipeline/lib/pipeline-stack.ts`:
- Imported `aws-cdk-lib/pipelines` and `createSynthStep` from `./buildspec-configs`
- Added public `pipeline` property
- Implemented `createPipeline(repository, mainBranch)`:
  - Creates `CodePipelineSource.codeCommit()` from the repository and mainBranch prop
  - Passes synth step from `createSynthStep(source)`
  - Returns a `pipelines.CodePipeline` named `AppPipeline`
- Called `createPipeline()` from constructor after `createRepository()`

**Verification:** `cdk synth` runs cleanly — template includes CodeCommit, CodePipeline (Source → Build → UpdatePipeline stages), and CodeBuild resources.

---

## Final State of Files After Task 3

### `cicd-pipeline/lib/pipeline-stack.ts`
- PipelineStackProps: `env`, `repositoryName`, `mainBranch`
- PipelineStack with public `repository` and `pipeline` properties
- `createRepository()` → codecommit.Repository
- `createPipeline()` → pipelines.CodePipeline with CodeCommit source and synth step
- CfnOutputs for clone URLs

### `cicd-pipeline/lib/buildspec-configs.ts`
- `createSynthStep(source)` → CodeBuildStep with install/build/synth commands

### `cicd-pipeline/bin/pipeline-app.ts` (unchanged)
- Instantiates PipelineStack with account, region, repositoryName, mainBranch
