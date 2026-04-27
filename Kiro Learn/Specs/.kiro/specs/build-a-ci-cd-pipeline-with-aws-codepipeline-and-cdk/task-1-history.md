# Task 1: Prerequisites - Environment Setup — Conversation History

## Overview

Task 1 covered verifying and installing all prerequisite tools and configurations needed before building the CI/CD pipeline.

---

## Task 1.1: AWS Account and Credentials

**Goal**: Verify AWS account access and record account details.

**Steps performed**:

1. Ran `aws sts get-caller-identity` to verify credentials.
   - Result: 
     - Account: `628326705801`
     - User: `alain-is`
     - ARN: `arn:aws:iam::628326705801:user/alain-is`
2. Ran `aws configure get region` to check default region.
   - Result: `us-east-1`

**Outcome**: ✅ Completed — AWS credentials verified, account ID and region recorded.

---

## Task 1.2: Required Tools and SDKs

**Goal**: Ensure all required tools are installed and working.

**Initial tool check results**:

| Tool | Status | Version |
|------|--------|---------|
| AWS CLI | ✅ | v1.38.38 |
| Node.js | ✅ | v18.20.2 |
| TypeScript | ❌ | Not installed globally |
| AWS CDK CLI | ✅ | v2.161.0 |
| Git | ✅ | v2.50.1 |
| cfn-nag | ❌ | Not installed |

**Actions taken**:

1. Installed TypeScript globally: `npm install -g typescript`
   - Result: TypeScript v6.0.2 installed successfully.

2. Attempted `gem install cfn-nag` — failed due to system Ruby directory permissions.

3. Attempted `gem install --user-install cfn-nag` — failed because system Ruby (2.6.10) is too old (cfn-nag requires Ruby >= 2.7).

4. Discovered Homebrew Ruby 3.3.5 at `/opt/homebrew/Cellar/ruby/3.3.5/`.

5. Installed cfn-nag using Homebrew Ruby:
   ```
   /opt/homebrew/Cellar/ruby/3.3.5/bin/gem install cfn-nag
   ```
   - Result: cfn-nag v0.8.10 installed successfully.
   - Binary location: `/opt/homebrew/lib/ruby/gems/3.3.0/bin/cfn_nag_scan`

**Final tool check results**:

| Tool | Status | Version |
|------|--------|---------|
| AWS CLI | ✅ | v1.38.38 |
| Node.js | ✅ | v18.20.2 |
| TypeScript | ✅ | v6.0.2 |
| AWS CDK CLI | ✅ | v2.161.0 |
| Git | ✅ | v2.50.1 |
| cfn-nag | ✅ | v0.8.10 |

**Note**: cfn-nag is installed under Homebrew Ruby's gem path. The full path `/opt/homebrew/lib/ruby/gems/3.3.0/bin/cfn_nag_scan` may need to be used or added to PATH in later tasks.

**Outcome**: ✅ Completed — all six tools installed and verified.

---

## Task 1.3: AWS Region and Resource Configuration

**Goal**: Set default region, verify IAM permissions, and configure CodeCommit access.

**Steps performed**:

1. Checked `AWS_DEFAULT_REGION` environment variable — not set in session, but AWS CLI config already defaults to `us-east-1`.

2. Installed `git-remote-codecommit`:
   ```
   pip3 install git-remote-codecommit
   ```
   - Result: v1.17 installed successfully.

3. Verified CodeCommit access:
   ```
   aws codecommit list-repositories --region us-east-1
   ```
   - Result: Successful (empty repository list, as expected).

4. Verified `git-remote-codecommit` is functional (responds to invocation).

5. Checked IAM permissions:
   ```
   aws iam list-attached-user-policies --user-name alain-is
   ```
   - Result: `AdministratorAccess` policy attached — covers all required services (CodePipeline, CodeBuild, CodeCommit, CloudFormation, Lambda, IAM, S3, CDK bootstrap).

**Outcome**: ✅ Completed — region configured, full permissions confirmed, CodeCommit access verified.

---

## Summary

All three subtasks completed successfully. The environment is ready for Task 2 (CDK Project Initialization and Bootstrap).

**Key details for later tasks**:
- AWS Account ID: `628326705801`
- Region: `us-east-1`
- User: `alain-is`
- cfn-nag path: `/opt/homebrew/lib/ruby/gems/3.3.0/bin/cfn_nag_scan`
- CDK version: `2.161.0`
- Node.js version: `18.20.2`
