

# Implementation Plan: Build a CI/CD Pipeline with AWS CodePipeline and CDK

## Overview

This implementation plan guides learners through building a self-mutating CI/CD pipeline using AWS CDK Pipelines and AWS CodePipeline. The approach follows a bottom-up strategy: first establishing the development environment and CDK project foundation, then building the pipeline incrementally — starting with source and build stages, adding the application to deploy, configuring multi-environment deployment with approval gates, and finally adding validation steps. Each phase builds on the previous one, allowing learners to verify progress at natural checkpoints.

The key milestones are: (1) CDK project initialization and bootstrap, (2) pipeline stack with source and synth stages operational, (3) application stage and stack defined and deployable, (4) multi-environment deployment with manual approval gate, and (5) parallel validation steps for linting and security scanning. The pipeline's self-mutation capability is inherent to CDK Pipelines and will be validated as part of the pipeline verification phase.

Task ordering follows strict dependency chains — the pipeline stack must exist before deployment stages can be added, and the application stage must be defined before it can be referenced by deployment stages. The final end-to-end verification task ensures all eight requirements are satisfied by pushing a code change and observing it flow through every pipeline stage. All AWS resources are created via CDK, so cleanup is handled through `cdk destroy`.

## Tasks

- [x] 1. Prerequisites - Environment Setup
  - [x] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Record your AWS account ID and preferred region (e.g., `us-east-1`) for use in later steps
    - _Requirements: (all)_
  - [x] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Node.js 18+: verify with `node --version`
    - Install TypeScript globally: `npm install -g typescript` and verify with `tsc --version`
    - Install AWS CDK CLI: `npm install -g aws-cdk` and verify with `cdk --version`
    - Install Git: verify with `git --version`
    - Install cfn-nag for security scanning: `gem install cfn-nag` and verify with `cfn_nag --version`
    - _Requirements: (all)_
  - [x] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure IAM permissions for: CodePipeline, CodeBuild, CodeCommit, CloudFormation, Lambda, IAM, S3, and CDK bootstrap resources
    - Verify `git-remote-codecommit` is available or configure HTTPS Git credentials for CodeCommit
    - _Requirements: (all)_

- [x] 2. CDK Project Initialization and Bootstrap
  - [x] 2.1 Initialize CDK TypeScript Application
    - Create project directory: `mkdir cicd-pipeline && cd cicd-pipeline`
    - Initialize CDK app: `cdk init app --language typescript`
    - Verify project structure contains `bin/`, `lib/`, `cdk.json`, `package.json`, and `tsconfig.json`
    - Install pipeline dependencies: `npm install aws-cdk-lib constructs`
    - Rename the entry point file to `bin/pipeline-app.ts` and update `cdk.json` to point to it
    - _Requirements: 1.1_
  - [x] 2.2 Bootstrap AWS Environment
    - Run CDK bootstrap: `cdk bootstrap aws://ACCOUNT_ID/REGION` (replace with your account ID and region)
    - Verify bootstrap stack exists: `aws cloudformation describe-stacks --stack-name CDKToolkit`
    - Confirm S3 bucket for assets, Amazon ECR repository, and IAM roles were provisioned in the bootstrap stack outputs
    - _Requirements: 1.2_
  - [x] 2.3 Configure CDK App Entry Point (Component 1: CDK App Entry Point)
    - Edit `bin/pipeline-app.ts` to instantiate `cdk.App` and `PipelineStack` with environment props (`account` and `region`)
    - Define the `Environment` data model values using your AWS account ID and region
    - Set `repositoryName` to `"pipeline-app-repo"` and `mainBranch` to `"main"` per `PipelineStackProps`
    - Run `cdk synth` to verify the app produces a valid CloudFormation template without errors
    - _Requirements: 1.1, 1.3_

- [x] 3. Pipeline Stack with Source and Build Stages
  - [x] 3.1 Create PipelineStack with CodeCommit Repository (Component 2: PipelineStack - createRepository)
    - Create `lib/pipeline-stack.ts` defining `PipelineStack` extending `cdk.Stack`
    - Accept `PipelineStackProps` (with `env`, `repositoryName`, `mainBranch`) in the constructor
    - Implement `createRepository()` using `codecommit.Repository` to create the CodeCommit repo
    - Export the repository clone URL for later use
    - _Requirements: 2.1, 2.2_
  - [x] 3.2 Create Synth Step and Pipeline (Component 5: BuildSpecConfigs - createSynthStep, Component 2: PipelineStack - createPipeline)
    - Create `lib/buildspec-configs.ts` with `createSynthStep(source)` factory function
    - Configure the `CodeBuildStep` with install commands (`npm ci`), build commands (`npm run build`, `npx cdk synth`), and `primaryOutputDirectory: 'cdk.out'` per the `BuildConfig` data model
    - In `pipeline-stack.ts`, implement `createPipeline()` using `pipelines.CodePipeline` with `CodePipelineSource.codeCommit()` pointing to the repository and main branch
    - Pass the synth step from `createSynthStep()` as the pipeline's `synth` property
    - Run `cdk synth` to verify the pipeline stack synthesizes correctly
    - _Requirements: 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 4.2_

- [x] 4. Checkpoint - Validate Pipeline Foundation
  - Run `cdk synth` and confirm CloudFormation template is generated without errors
  - Review the synthesized template to verify CodeCommit repository, CodePipeline, and CodeBuild resources are present
  - Deploy the pipeline stack: `cdk deploy PipelineStack`
  - Verify the CodeCommit repository exists: `aws codecommit get-repository --repository-name pipeline-app-repo`
  - Verify the pipeline exists in the CodePipeline console with Source, Build, and UpdatePipeline stages
  - Push the project code to the CodeCommit repo and confirm the pipeline triggers automatically
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Application Stage and Stack
  - [x] 5.1 Create ApplicationStack (Component 4: ApplicationStack)
    - Create `lib/application-stack.ts` defining `ApplicationStack` extending `cdk.Stack`
    - Implement `createLambdaFunction(functionName)` that creates a Lambda function with `LambdaConfig` settings: runtime `nodejs18.x`, handler `index.handler`, code path `lambda/`
    - Create the `lambda/` directory with a simple `index.ts` handler that returns `{ statusCode: 200, body: "Hello from pipeline!" }`
    - Call `createLambdaFunction()` in the constructor, passing a function name derived from the stack ID
    - _Requirements: 5.3_
  - [x] 5.2 Create ApplicationStage (Component 3: ApplicationStage)
    - Create `lib/application-stage.ts` defining `ApplicationStage` extending `cdk.Stage`
    - Accept `StageProps` (with `env` and `stageName`) in the constructor
    - Instantiate `ApplicationStack` inside the stage constructor, passing `stageName` for resource naming
    - Verify synthesis: `cdk synth` should show application stack nested within the stage
    - _Requirements: 5.1, 5.2, 5.3_

- [x] 6. Multi-Environment Deployment and Approval Gate
  - [x] 6.1 Add Dev Deployment Stage (Component 2: PipelineStack - addDevStage)
    - In `pipeline-stack.ts`, implement `addDevStage()` that creates an `ApplicationStage` with `stageName: "Dev"` and adds it to the pipeline using `pipeline.addStage()`
    - Configure the Dev stage environment using the same account/region
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 6.2 Add Prod Deployment Stage with Manual Approval (Component 2: PipelineStack - addProdStageWithApproval)
    - Implement `addProdStageWithApproval()` that creates an `ApplicationStage` with `stageName: "Prod"`
    - Add the stage with `pipeline.addStage()` and include a `pre` option containing a `ManualApprovalStep("PromoteToProd")`
    - This ensures the pipeline pauses before Prod deployment and proceeds only on approval
    - _Requirements: 5.1, 5.2, 5.4, 6.1, 6.2, 6.3_
  - [ ]* 6.3 Property Test - Pipeline Stage Ordering
    - **Property 1: Sequential Stage Execution**
    - **Validates: Requirements 4.1, 4.2, 5.1, 5.2**

- [x] 7. Validation Steps - Linting and Security Scanning
  - [x] 7.1 Create Lint and Security Scan Steps (Component 5: BuildSpecConfigs - createLintStep, createSecurityScanStep)
    - In `lib/buildspec-configs.ts`, implement `createLintStep(source)` returning a `ShellStep` that runs `npm ci && npm run lint`
    - Add a lint script to `package.json`: `"lint": "npx eslint . --ext .ts"` and install eslint: `npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin`
    - Implement `createSecurityScanStep(source)` returning a `ShellStep` that installs cfn-nag and runs `cfn_nag_scan --input-path cdk.out/`
    - _Requirements: 7.1, 7.2_
  - [x] 7.2 Add Validation Stage to Pipeline (Component 2: PipelineStack - addValidationStage)
    - In `pipeline-stack.ts`, implement `addValidationStage()` that adds lint and security scan steps as `pre` steps on the Dev deployment stage (this makes them run in parallel before Dev deploy)
    - Use `pipeline.addStage(devStage, { pre: [lintStep, securityScanStep] })` to configure parallel execution
    - Refactor `addDevStage()` to incorporate the validation steps from `addValidationStage()`
    - Verify with `cdk synth` that the pipeline template includes parallel validation actions
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 8. Checkpoint - Full Pipeline Deployment and Self-Mutation
  - Run `cdk synth` to verify the complete pipeline definition synthesizes without errors
  - Deploy the updated pipeline: `cdk deploy PipelineStack`
  - Push the CDK code to CodeCommit and verify the pipeline triggers
  - Confirm the pipeline includes stages: Source → Build → UpdatePipeline → Validation/Dev → Approval → Prod
  - Verify self-mutation: make a minor change to the pipeline stack (e.g., add a comment), push, and observe the UpdatePipeline stage updating the pipeline before proceeding — validates Requirements 4.1, 4.2
  - Verify no-op self-mutation: push a change with no pipeline definition changes and confirm the UpdatePipeline stage completes successfully without modifying the pipeline — validates Requirement 4.3
  - Verify validation steps run in parallel in the CodePipeline console
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. End-to-End Pipeline Verification
  - [ ] 9.1 Trigger Full Pipeline Execution
    - Modify the Lambda handler code in `lambda/index.ts` (e.g., change the response body to `"Hello CI/CD!"`)
    - Commit and push the change to the CodeCommit repository main branch
    - Open the CodePipeline console and observe the pipeline execution through all stages
    - Verify Source stage retrieves the latest commit
    - Verify Build/Synth stage completes and produces artifacts
    - Verify self-mutation stage completes (no pipeline changes expected)
    - Verify linting and security scanning steps pass in parallel
    - Verify Dev deployment completes and Lambda is updated
    - _Requirements: 8.1, 8.2, 8.3_
  - [ ] 9.2 Approve and Verify Production Deployment
    - When the pipeline pauses at the Manual Approval step, approve it via the CodePipeline console
    - Verify Prod deployment completes successfully
    - Invoke the Dev Lambda: `aws lambda invoke --function-name Dev-AppFunction --payload '{}' response.json && cat response.json`
    - Invoke the Prod Lambda: `aws lambda invoke --function-name Prod-AppFunction --payload '{}' response.json && cat response.json`
    - Confirm both functions return the updated response body
    - _Requirements: 6.1, 6.3, 8.1, 8.2, 8.3_
  - [ ]* 9.3 Verify Failure Handling
    - **Property 2: Pipeline Failure Propagation**
    - Introduce a deliberate syntax error in the Lambda code, push, and verify the build stage fails and the pipeline halts (Requirement 3.3)
    - Revert the error, introduce a lint violation, push, and verify the lint step fails and deployment does not proceed (Requirement 7.4)
    - Test approval rejection: trigger the pipeline, then reject the manual approval and verify Prod deployment does not occur (Requirement 6.2)
    - **Validates: Requirements 3.3, 5.4, 6.2, 7.4**

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete Pipeline and Application Stacks
    - Empty any S3 buckets created by the pipeline (artifact buckets): `aws s3 ls | grep pipeline` then `aws s3 rm s3://BUCKET_NAME --recursive` for each
    - Destroy all CDK stacks: `cdk destroy --all --force`
    - If `cdk destroy` fails for application stacks (deployed by pipeline), manually delete them: `aws cloudformation delete-stack --stack-name Dev-ApplicationStack` and `aws cloudformation delete-stack --stack-name Prod-ApplicationStack`
    - _Requirements: (all)_
  - [ ] 10.2 Delete CodeCommit Repository and Bootstrap Resources
    - Delete the CodeCommit repository: `aws codecommit delete-repository --repository-name pipeline-app-repo`
    - Optionally remove the CDK bootstrap stack if no longer needed: `aws cloudformation delete-stack --stack-name CDKToolkit` (note: this affects all CDK apps in the account/region)
    - _Requirements: (all)_
  - [ ] 10.3 Verify Cleanup
    - Verify no pipeline exists: `aws codepipeline list-pipelines`
    - Verify no application stacks remain: `aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE`
    - Verify CodeCommit repo is deleted: `aws codecommit get-repository --repository-name pipeline-app-repo` (should return error)
    - Check AWS Cost Explorer for any remaining charges from CodeBuild, S3, or Lambda
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests that validate failure handling and stage ordering — useful for deeper understanding but not required for the core learning objective
- Each task references specific requirements for traceability (format: `_Requirements: X.Y_` where X is the requirement number and Y is the acceptance criteria number)
- Checkpoints (Tasks 4 and 8) ensure incremental validation at key milestones — deploy and verify before adding complexity
- The pipeline's self-mutation capability (Requirement 4) is automatically provided by CDK Pipelines and is verified during Checkpoint Task 8 rather than requiring separate implementation
- CDK Pipelines automatically creates the UpdatePipeline (self-mutation) stage — no manual configuration is needed for this feature
- The validation steps (linting and security scanning) are added as `pre` steps on the Dev deployment stage, which causes CodePipeline to run them in parallel before the Dev deployment actions
- All resources are provisioned via CDK, making `cdk destroy` the primary cleanup mechanism, supplemented by manual deletion for pipeline-deployed stacks
