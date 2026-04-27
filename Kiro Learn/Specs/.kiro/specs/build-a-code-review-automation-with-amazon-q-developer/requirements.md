

# Requirements Document

## Introduction

This project guides learners through setting up and using Amazon Q Developer's automated code review capabilities within a GitHub-based development workflow. Code review is a critical practice in professional software development, and understanding how AI-powered review tools augment human reviewers is an increasingly valuable skill. By integrating Amazon Q Developer with GitHub, learners will experience how automated code analysis can detect security vulnerabilities, code quality issues, and potential bugs before code reaches production.

The project focuses on configuring the Amazon Q Developer GitHub integration, experiencing automated pull request reviews, iterating on code based on AI-generated findings, and defining custom coding standards that shape review behavior. Learners will work through realistic development scenarios — creating pull requests with intentional issues, interpreting review findings, applying suggested fixes, and using interactive commands to deepen their understanding of flagged concerns.

By the end of this project, learners will understand how Amazon Q Developer fits into the software development lifecycle as an automated first-pass reviewer, how to customize its behavior with project-specific rules, and how to establish a workflow where AI-assisted review complements human code review for higher overall code quality.

## Glossary

- **code_review_summary**: The top-level comment Amazon Q Developer posts on a pull request after analysis, summarizing all findings and their severities.
- **threaded_finding**: An individual code issue identified by Amazon Q Developer, posted as a threaded comment on the specific lines of code in a pull request where the issue was detected.
- **suggested_fix**: A code change proposed by Amazon Q Developer alongside a finding that can be committed directly to the pull request branch.
- **slash_command**: A command prefixed with `/q` entered in a GitHub pull request comment to interact with Amazon Q Developer, such as initiating a review or asking follow-up questions.
- **project_rules**: Custom coding standards defined in Markdown files within the `.amazonq/rules` directory that Amazon Q Developer follows when performing code reviews.
- **amazon_q_detectors**: The combination of generative AI and rule-based automatic reasoning engines that power Amazon Q Developer's code analysis, informed by AWS and Amazon.com security best practices.
- **pull_request_diff**: The set of code changes between a pull request's source branch and its target branch that Amazon Q Developer analyzes during a review.
- **iac_misconfiguration**: An error or deviation from best practices in infrastructure as code templates (such as CloudFormation) that Amazon Q Developer can detect during reviews.

## Requirements

### Requirement 1: Amazon Q Developer GitHub Installation and Configuration

**User Story:** As a DevOps learner, I want to install and configure Amazon Q Developer for my GitHub organization, so that I can enable AI-powered automated code reviews on my repositories.

#### Acceptance Criteria

1. WHEN the learner installs the Amazon Q Developer app on their GitHub organization, THE app SHALL appear as an installed GitHub App with access to the selected repositories.
2. WHEN the learner registers the GitHub installation with their AWS account through the Amazon Q Developer console, THE integration SHALL be active and ready to perform automated reviews.
3. THE learner SHALL have the appropriate GitHub repository role (Write, Maintain, or Admin) to initiate code reviews on the target repository.
4. WHEN the learner enables the code reviews feature in the Amazon Q Developer console, THE setting SHALL control whether automated reviews run on new or reopened pull requests.

### Requirement 2: Automated Pull Request Code Review

**User Story:** As a developer learning CI/CD best practices, I want Amazon Q Developer to automatically review my pull requests when they are created or reopened, so that I receive immediate feedback on code quality and security issues without manual intervention.

#### Acceptance Criteria

1. WHEN the learner creates a new pull request or reopens a previously closed pull request, THE Amazon Q Developer service SHALL automatically perform a code review and post a code review summary on the pull request.
2. WHEN Amazon Q Developer identifies issues during an automated review, THE findings SHALL appear as threaded comments on the specific code lines where issues were detected, including detailed explanations.
3. WHERE Amazon Q Developer detects security vulnerabilities, code quality issues, or potential bugs, THE findings SHALL include suggested fixes that the learner can review and commit directly to the pull request.
4. IF subsequent commits are pushed to an existing open pull request, THEN THE service SHALL NOT automatically trigger a new code review for those commits.

### Requirement 3: On-Demand Code Review with Slash Commands

**User Story:** As a developer learning iterative code improvement, I want to manually trigger additional code reviews and ask follow-up questions using slash commands, so that I can re-evaluate my code after making changes and deepen my understanding of specific findings.

#### Acceptance Criteria

1. WHEN the learner enters the `/q review` slash command in a new pull request comment, THE Amazon Q Developer service SHALL initiate a new code review of the pull request in its current state, including all comments and new commits.
2. WHEN the learner enters `/q` followed by a question in a pull request comment, THE Amazon Q Developer service SHALL respond with contextual information related to the code review findings.
3. IF the learner attempts to use the `/q review` slash command within an existing comment thread rather than as a new comment, THEN THE command SHALL NOT initiate a code review.
4. THE `/q review` slash command SHALL function regardless of whether the automated code review feature setting is enabled or disabled in the Amazon Q Developer console.

### Requirement 4: Custom Project Rules for Code Review Standards

**User Story:** As a developer learning to enforce team coding standards, I want to define custom review rules in my repository, so that Amazon Q Developer's code reviews align with my project's specific quality guidelines and conventions.

#### Acceptance Criteria

1. WHEN the learner creates Markdown files in the `.amazonq/rules` directory at the project root, THE Amazon Q Developer service SHALL incorporate those guidelines when performing code reviews on pull requests.
2. THE project rules SHALL be written as simple Markdown files describing coding standards in natural language, allowing the learner to express conventions without configuration syntax.
3. WHEN the learner modifies the project rules and triggers a new review, THE Amazon Q Developer service SHALL apply the updated guidelines to the subsequent code review.

### Requirement 5: Reviewing and Applying Suggested Fixes

**User Story:** As a developer learning secure coding practices, I want to evaluate Amazon Q Developer's suggested fixes for identified issues and selectively apply them, so that I understand each remediation and practice making informed decisions about code changes.

#### Acceptance Criteria

1. WHEN Amazon Q Developer provides a suggested fix for a finding, THE fix SHALL be presented as a reviewable code change that the learner can inspect before applying.
2. WHEN the learner chooses to commit a suggested fix, THE code change SHALL be applied directly to the pull request branch, updating the pull request with the fix.
3. WHEN the learner addresses Amazon Q Developer's findings and initiates a subsequent review using the `/q review` command, THE new review results SHALL reflect the resolved issues and identify any remaining or newly introduced concerns.

### Requirement 6: IDE-Based Code Review for Local Development

**User Story:** As a developer learning to shift security left, I want to run Amazon Q Developer code reviews directly in my IDE on local code, so that I can identify and fix issues before pushing changes to a pull request.

#### Acceptance Criteria

1. WHEN the learner requests a code review through the IDE chat panel, THE Amazon Q Developer service SHALL analyze the code and present findings within the IDE environment.
2. WHEN the learner requests a review of recent code changes in the active file, THE review SHALL scope its analysis to only the changed code rather than the entire file.
3. WHEN the learner requests a review of the entire repository or project, THE Amazon Q Developer service SHALL analyze all supported files, excluding unsupported languages, test code, and open source library code.
4. THE code review findings in the IDE SHALL include issue severity levels and explanations to help the learner prioritize which issues to address first.

### Requirement 7: Feature Development Automation with Amazon Q Developer Agent

**User Story:** As a developer learning AI-assisted development workflows, I want to use Amazon Q Developer's development agent to generate implementation code from GitHub issue descriptions, so that I can understand how AI can accelerate feature development and produce reviewable pull requests.

#### Acceptance Criteria

1. WHEN the learner creates a GitHub issue with a detailed feature description and applies the "Amazon Q development agent" label, THE Amazon Q Developer service SHALL analyze the requirements and generate a pull request with an implementation plan and code changes.
2. WHEN the learner uses the `/q dev` command in a GitHub issue comment, THE Amazon Q Developer service SHALL initiate the feature development workflow for that issue.
3. WHEN Amazon Q Developer generates a pull request from an issue, THE pull request SHALL be subject to the same automated code review process, allowing the learner to review both the generated implementation and any quality or security findings.
