

# Implementation Plan: Code Review Automation with Amazon Q Developer

## Overview

This project guides learners through setting up Amazon Q Developer's automated code review capabilities within a GitHub-based development workflow. The implementation follows a progressive approach: first establishing the prerequisite environment and GitHub integration, then building helper components that generate sample code and manage project rules, followed by iterative pull request review cycles that exercise Amazon Q Developer's automated and on-demand review features.

The key milestones are: (1) environment setup and Amazon Q Developer GitHub App installation, (2) building the sample code generator and PR workflow tooling, (3) experiencing automated pull request reviews with intentional code issues, (4) defining custom project rules and validating their effect on reviews, (5) exploring IDE-based code reviews and the `/q dev` agent for feature generation. Each phase builds on the previous, ensuring learners progressively deepen their understanding of AI-assisted code review workflows.

Dependencies flow linearly: the GitHub App must be installed before any reviews can occur, sample code must exist before pull requests can be created, and pull requests must be reviewed before slash commands and custom rules can be exercised. The project prioritizes hands-on interaction with Amazon Q Developer's review findings over complex application logic, so the helper components are intentionally lightweight—focused on generating review targets and automating Git operations.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with access to the Amazon Q Developer console
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install Git; verify: `git --version`
    - Install GitHub CLI (`gh`); verify: `gh --version`
    - Authenticate GitHub CLI: `gh auth login`
    - Install IDE with Amazon Q Developer extension (VS Code or JetBrains) and authenticate with AWS
    - _Requirements: (all)_
  - [ ] 1.3 GitHub Organization and Repository Setup
    - Ensure you have a GitHub organization (free tier is sufficient)
    - Create a new repository in the organization for this project (e.g., `code-review-automation-lab`)
    - Clone the repository locally: `git clone <repo-url> && cd code-review-automation-lab`
    - Verify you have Write, Maintain, or Admin role on the repository
    - Create the project directory structure: `mkdir -p components .amazonq/rules`
    - _Requirements: 1.3, 4.1_

- [ ] 2. Amazon Q Developer GitHub Installation and Configuration
  - [ ] 2.1 Install Amazon Q Developer GitHub App
    - Navigate to the GitHub Marketplace and search for "Amazon Q Developer"
    - Install the Amazon Q Developer app on your GitHub organization
    - Grant access to the target repository (or all repositories)
    - Verify the app appears under Organization Settings → Installed GitHub Apps
    - Implement `components/setup_manager.sh` with functions: `verify_github_app_installed`, `verify_repository_access`, `verify_user_role`, and `print_setup_instructions`
    - Run verification: `bash components/setup_manager.sh` to confirm installation status
    - _Requirements: 1.1, 1.3_
  - [ ] 2.2 Register GitHub Installation with AWS Account
    - Open the Amazon Q Developer console in your AWS account
    - Navigate to the GitHub integration settings and register your GitHub App installation
    - Enable the "Code reviews" feature in the Amazon Q Developer console
    - Implement `verify_console_registration` function in `setup_manager.sh` that checks registration status
    - Verify the integration is active and ready to perform reviews
    - _Requirements: 1.2, 1.4_

- [ ] 3. Build Sample Code Generator and PR Workflow Components
  - [ ] 3.1 Implement SampleCodeGenerator
    - Create `components/sample_code_generator.py` implementing the `SampleCodeGenerator` interface
    - Implement `generate_vulnerable_python(output_dir)`: create a Python file with hardcoded credentials, SQL injection, and insecure deserialization (returns file path)
    - Implement `generate_iac_misconfiguration(output_dir)`: create a CloudFormation template with open security groups, unencrypted S3 buckets, and overly permissive IAM policies (returns file path)
    - Implement `generate_code_quality_issues(output_dir)`: create a Python file with unused imports, overly complex functions, missing error handling (returns file path)
    - Implement `generate_clean_python(output_dir)`: create a well-written Python file following best practices (returns file path)
    - Implement `list_generated_files(output_dir)`: return list of all generated file paths
    - Define the `SampleFile` data model with fields: `file_path`, `file_type`, `issue_category`, `description`
    - Verify by running: `python3 -c "from components.sample_code_generator import SampleCodeGenerator; sg = SampleCodeGenerator(); print(sg.list_generated_files('samples'))"`
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 3.2 Implement PRWorkflowManager
    - Create `components/pr_workflow_manager.py` implementing the `PRWorkflowManager` interface
    - Implement `create_feature_branch(branch_name)`: run `git checkout -b <branch_name>` via subprocess
    - Implement `add_and_commit_files(file_paths, commit_message)`: stage and commit specified files
    - Implement `push_branch(branch_name)`: push branch to remote origin
    - Implement `create_review_cycle_branch(cycle_name, sample_files)`: orchestrate branch creation, file staging, commit, and push in one call; return branch name
    - Implement `list_branches()`: return list of local branches
    - Define the `ReviewCycle` data model with fields: `cycle_number`, `branch_name`, `sample_files`, `purpose`
    - Handle error case: branch already exists (raise descriptive error with resolution guidance)
    - _Requirements: 2.1, 5.2_

- [ ] 4. Checkpoint - Validate Setup and Components
  - Verify Amazon Q Developer GitHub App is installed: check Organization Settings → Installed GitHub Apps
  - Verify console registration: confirm integration is active in Amazon Q Developer console
  - Run `python3 components/sample_code_generator.py` and confirm sample files are generated in the `samples/` directory
  - Run a quick test of PRWorkflowManager by creating and deleting a test branch
  - Confirm `gh` CLI can interact with your repository: `gh repo view`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Automated Pull Request Code Review
  - [ ] 5.1 Create First Pull Request with Vulnerable Code
    - Use `SampleCodeGenerator` to generate vulnerable Python and IaC misconfiguration files into a `samples/` directory
    - Use `PRWorkflowManager.create_review_cycle_branch("cycle-1-security", sample_files)` to create and push a branch
    - Create a pull request via GitHub UI or `gh pr create --title "Cycle 1: Security review" --body "Testing automated code review"`
    - Observe Amazon Q Developer automatically performing a code review within a few minutes
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 5.2 Interpret Review Findings and Guide
    - Create `components/review_guide_printer.py` implementing the `ReviewGuidePrinter` interface
    - Implement `print_interpreting_findings_guide()`: print guidance on reading code_review_summary and threaded_findings
    - Implement `print_applying_fixes_guide()`: print steps for reviewing and committing suggested_fixes
    - Implement `print_review_cycle_checklist(cycle_number)`: print a checklist for a given review cycle
    - Run the guide: `python3 -c "from components.review_guide_printer import ReviewGuidePrinter; rg = ReviewGuidePrinter(); rg.print_interpreting_findings_guide()"`
    - In the GitHub PR, review the code_review_summary and examine each threaded_finding with its severity and explanation
    - Verify that suggested_fixes are presented as reviewable code changes on specific lines
    - Verify that pushing additional commits to the PR does NOT automatically trigger a new review
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.1_

- [ ] 6. On-Demand Reviews, Slash Commands, and Applying Fixes
  - [ ] 6.1 Apply Suggested Fixes and Trigger On-Demand Review
    - In the open pull request from Task 5, commit one or more suggested_fixes directly via the GitHub UI
    - Verify the committed fix updates the pull request branch
    - Navigate to "Add a comment" (top-level, NOT in an existing thread) and enter `/q review`
    - Observe Amazon Q Developer initiating a new review of the PR in its current state
    - Verify the new review reflects resolved issues and identifies any remaining concerns
    - _Requirements: 3.1, 3.4, 5.1, 5.2, 5.3_
  - [ ] 6.2 Ask Follow-Up Questions and Test Command Constraints
    - In a new top-level PR comment, enter `/q explain the importance of the most critical finding`
    - Verify Amazon Q Developer responds with contextual information related to the findings
    - Implement `print_slash_commands_guide()` in `ReviewGuidePrinter` to document all available slash commands
    - Test constraint: enter `/q review` inside an existing comment thread and verify it does NOT initiate a review
    - _Requirements: 3.2, 3.3_

- [ ] 7. Custom Project Rules for Code Review Standards
  - [ ] 7.1 Implement ProjectRulesManager and Create Rules
    - Create `components/project_rules_manager.py` implementing the `ProjectRulesManager` interface
    - Implement `create_rules_directory(project_root)`: create `.amazonq/rules/` directory, return path
    - Implement `add_rule(project_root, rule_name, rule_content)`: write a Markdown file to `.amazonq/rules/{rule_name}.md`, return file path
    - Implement `list_rules(project_root)`, `update_rule(project_root, rule_name, rule_content)`, and `delete_rule(project_root, rule_name)`
    - Define the `ProjectRule` data model with fields: `rule_name`, `file_path`, `content`
    - Create example rules: naming conventions (e.g., snake_case for Python functions), error handling requirements (e.g., all functions must handle exceptions), and documentation standards (e.g., all public functions must have docstrings)
    - Verify rules exist: `ls .amazonq/rules/` should show `.md` files
    - _Requirements: 4.1, 4.2_
  - [ ] 7.2 Validate Custom Rules in a New Review Cycle
    - Use `SampleCodeGenerator.generate_code_quality_issues("samples/")` to create code that violates the custom rules
    - Use `PRWorkflowManager.create_review_cycle_branch("cycle-2-rules", sample_files)` and create a new PR
    - Wait for the automated review or trigger with `/q review`
    - Verify Amazon Q Developer's findings reference or align with the custom project rules
    - Update a rule using `update_rule()`, then trigger another review with `/q review` to verify the updated guidelines are applied
    - _Requirements: 4.1, 4.2, 4.3_

- [ ] 8. Checkpoint - Validate Review Workflow
  - Confirm at least two review cycles have been completed with findings and fixes
  - Verify `/q review` successfully triggers on-demand reviews from top-level comments
  - Verify `/q` follow-up questions receive contextual responses
  - Verify custom project rules in `.amazonq/rules/` influence review findings
  - Verify suggested fixes can be committed directly to the PR branch
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. IDE-Based Code Review and Feature Development Agent
  - [ ] 9.1 IDE-Based Code Review
    - Open the project repository in your IDE (VS Code or JetBrains) with Amazon Q Developer extension authenticated
    - Implement `print_ide_review_guide()` in `ReviewGuidePrinter` to document IDE review prompts and workflows
    - Open a sample file with changes and enter "Review my code" in the Amazon Q chat panel to review recent changes in the active file
    - Open a sample file without changes and enter "Review my entire code file" to review the full file
    - Enter "Review my repository" to trigger a full project review (excludes unsupported languages, test code, and open source library code)
    - Verify findings include issue severity levels and explanations
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - [ ] 9.2 Feature Development with /q dev Agent
    - Create `components/issue_workflow_manager.py` implementing the `IssueWorkflowManager` interface
    - Implement `create_feature_issue(title, description, acceptance_criteria)`: use `gh issue create` to create an issue, return issue number
    - Implement `apply_agent_label(issue_number)`: apply "Amazon Q development agent" label using `gh issue edit`; first create the label in GitHub if it doesn't exist: `gh label create "Amazon Q development agent"`
    - Implement `add_dev_command_comment(issue_number)`: add `/q dev` comment to the issue using `gh issue comment`
    - Implement `get_issue_status(issue_number)`: return issue metadata as a dictionary
    - Define the `FeatureIssue` data model with fields: `title`, `description`, `acceptance_criteria`, `issue_number`, `agent_label`
    - Create a feature issue with detailed description and acceptance criteria, then apply the agent label
    - Observe Amazon Q Developer generating a PR with an implementation plan and code changes
    - Verify the generated PR undergoes the same automated code review process
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 10. Checkpoint - Final Validation
  - Verify IDE-based code review returns findings with severity levels for active file, changed code, and full repository scans
  - Verify the `/q dev` agent generated a pull request from a GitHub issue
  - Verify the agent-generated PR received an automated code review
  - Confirm all six components are implemented: SetupManager, SampleCodeGenerator, ProjectRulesManager, PRWorkflowManager, IssueWorkflowManager, ReviewGuidePrinter
  - Confirm all four data models are defined: SampleFile, ProjectRule, ReviewCycle, FeatureIssue
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Close Pull Requests and Issues
    - Close all open pull requests: `gh pr list --state open | awk '{print $1}' | xargs -I {} gh pr close {}`
    - Close all open issues: `gh issue list --state open | awk '{print $1}' | xargs -I {} gh issue close {}`
    - Delete feature branches: `git branch -r | grep 'origin/cycle-' | sed 's/origin\///' | xargs -I {} git push origin --delete {}`
    - _Requirements: (all)_
  - [ ] 11.2 Remove Amazon Q Developer Integration
    - In the Amazon Q Developer console, remove the GitHub installation registration if no longer needed
    - In GitHub Organization Settings → Installed GitHub Apps, uninstall Amazon Q Developer if desired
    - Optionally delete the test repository: `gh repo delete <org>/<repo> --yes`
    - _Requirements: (all)_
  - [ ] 11.3 Verify Cleanup
    - Verify no open PRs remain: `gh pr list --state open`
    - Verify no open issues remain: `gh issue list --state open`
    - Verify Amazon Q Developer integration is removed from AWS console (if applicable)
    - Check AWS billing dashboard for any unexpected charges
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The Amazon Q Developer GitHub App is in preview; UI and behavior may change — refer to the latest AWS documentation if steps differ
- The `/q dev` agent requires the "Amazon Q development agent" label to exist in the repository before it can be applied to issues
- IDE-based auto-reviews require an Amazon Q Developer Pro subscription and are out of scope; manual IDE reviews via the chat panel are covered
- Some Amazon Q Developer operations (automated reviews, `/q dev` generation) may take several minutes to complete — be patient and refresh the PR page
