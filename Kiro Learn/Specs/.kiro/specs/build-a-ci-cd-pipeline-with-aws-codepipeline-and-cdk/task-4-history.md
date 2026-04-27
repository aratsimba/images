# Task 4: Checkpoint - Validate Pipeline Foundation

## Summary
Validated the pipeline foundation by synthesizing, deploying, and verifying all core resources.

## Steps Performed

### 1. CDK Synth — Template Generation
- Ran `cdk synth` in the `cicd-pipeline/` directory
- Template generated successfully (no errors)
- Node 18 EOL warning noted but non-blocking

### 2. Template Review — Resource Verification
Confirmed the synthesized CloudFormation template contains:
- 1x `AWS::CodeCommit::Repository` — source repo (`pipeline-app-repo`)
- 1x `AWS::CodePipeline::Pipeline` — the pipeline (`AppPipeline`)
- 2x `AWS::CodeBuild::Project` — Synth build + SelfMutation build

Pipeline stages confirmed:
- **Source** → CodeCommit source action
- **Build** → Synth action (npm ci, npm run build, npx cdk synth)
- **UpdatePipeline** → SelfMutate action

### 3. Tests
- Ran `npm test` — all tests passed (1 test suite, 1 test)

### 4. Deployment
- Ran `cdk deploy PipelineStack --require-approval never`
- Deployment completed successfully in ~134 seconds
- Stack ARN: `arn:aws:cloudformation:us-east-1:628326705801:stack/PipelineStack/d6baf670-3449-11f1-9f73-12be47f86c4d`

**Outputs:**
- `RepositoryCloneUrlHttp`: `https://git-codecommit.us-east-1.amazonaws.com/v1/repos/pipeline-app-repo`
- `RepositoryCloneUrlGrc`: `codecommit::us-east-1://pipeline-app-repo`

### 5. AWS CLI Verification

**CodeCommit Repository:**
```
+----------+------------------------------------------------------------------------------+
|  CloneUrl|  https://git-codecommit.us-east-1.amazonaws.com/v1/repos/pipeline-app-repo   |
|  Id      |  722598be-60b3-4a44-b904-ae909d9f9654                                        |
|  Name    |  pipeline-app-repo                                                           |
+----------+------------------------------------------------------------------------------+
```

**Pipeline Stages:**
```
+------------------+
|  Source          |
|  Build           |
|  UpdatePipeline  |
+------------------+
```

### 6. Git Push to CodeCommit
- Added remote: `git remote add origin codecommit::us-east-1://pipeline-app-repo`
- Committed changes: `Add pipeline stack with CodeCommit source and CDK synth build stage` (7 files changed)
- Pushed to `origin/main` successfully

### 7. Pipeline Trigger Verification
- Pipeline execution triggered automatically via **CloudWatchEvent**
- Status at time of check: **InProgress**

```
+----------------+--------------+-------------------+
|    StartTime   |   Status     |      Trigger      |
+----------------+--------------+-------------------+
|  1775763058.718|  InProgress  |  CloudWatchEvent  |
+----------------+--------------+-------------------+
```

## Result
✅ All checkpoint criteria met:
- `cdk synth` produces valid template
- Template contains CodeCommit, CodePipeline, and CodeBuild resources
- Pipeline deployed successfully with Source, Build, and UpdatePipeline stages
- Code pushed to CodeCommit triggers pipeline automatically
- All tests pass

## Files Involved
- `cicd-pipeline/bin/pipeline-app.ts` — CDK app entry point
- `cicd-pipeline/lib/pipeline-stack.ts` — PipelineStack with CodeCommit repo and CDK Pipeline
- `cicd-pipeline/lib/buildspec-configs.ts` — Synth step factory function
- `cicd-pipeline/cdk.json` — CDK app configuration
- `cicd-pipeline/package.json` — Project dependencies
