

# Implementation Plan: Getting Familiar with Kiro IDE

## Overview

This implementation plan guides learners through a hands-on exploration of the Kiro IDE's core AI-powered features. The approach is incremental: learners begin by setting up a workspace and orienting themselves within the VS Code-based environment, then progressively configure the steering system, exercise spec-driven development, interact with AI chat modes, set up agent hooks, and configure an MCP server. A small demo project (a task tracker) serves as the vehicle for exercising each feature.

The plan is organized into logical phases. First, prerequisites and workspace setup establish the foundation. Next, steering configuration and spec-driven development build persistent AI context and structured planning artifacts. Then, AI chat interaction and agent hooks demonstrate real-time AI collaboration and event-driven automation. Finally, MCP server configuration extends the AI agent's tool capabilities. Checkpoints are placed after the foundational setup phase and after the AI interaction features phase to validate progress.

Dependencies flow naturally: the workspace must exist before steering files can be created, steering context should be in place before spec-driven development is used, and spec artifacts provide material for chat interaction exercises. Agent hooks and MCP configuration are relatively independent but benefit from having a populated workspace with files to trigger hooks against.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 Kiro IDE Installation and Account
    - Ensure Kiro IDE is installed and updated to the latest version
    - Sign in with your Kiro account (or AWS Builder ID if applicable)
    - Verify Kiro launches successfully and displays the welcome screen
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [ ] 1.2 AWS Account and Credentials Setup
    - Ensure you have an AWS account (required if using AWS MCP Server or any AWS-integrated features)
    - Configure AWS credentials: run `aws configure` and verify with `aws sts get-caller-identity`
    - Set your default AWS region (e.g., `aws configure set region us-east-1`)
    - Confirm IAM permissions include any service-specific access required (e.g., read access to AWS services used via MCP tools)
    - _Requirements: 1.1_
  - [ ] 1.3 Required Tools
    - Install Node.js 20+: verify with `node --version`
    - Install TypeScript globally: `npm install -g typescript` and verify with `tsc --version`
    - Ensure a project folder exists for the demo workspace (e.g., `~/kiro-demo-task-tracker`)
    - _Requirements: 1.1, 1.2_

- [ ] 2. Workspace Setup and IDE Orientation
  - [ ] 2.1 Create project workspace and verify IDE layout
    - Open Kiro and select File > Open Folder to open the demo project directory
    - Initialize the project: run `npm init -y` in the integrated terminal (Ctrl+` to open terminal)
    - Update `package.json` with project name `kiro-demo-task-tracker` and description
    - Verify the file explorer shows the project files, the editor pane opens `package.json`, and the terminal panel is visible
    - Create a `src/` directory and a placeholder file `src/index.ts` to confirm file creation and navigation
    - _Requirements: 1.1, 1.2_
  - [ ] 2.2 Verify chat interface, command palette, and settings access
    - Open the chat interface panel and confirm the AI agent interaction area is visible
    - Locate and verify the autopilot/supervised mode toggle in the chat panel
    - Open the command palette using Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows/Linux)
    - Open Kiro settings using standard VS Code keyboard shortcuts (Cmd+, or Ctrl+,)
    - _Requirements: 1.3, 1.4_

- [ ] 3. Steering System Configuration
  - [ ] 3.1 Create steering directory and product context file
    - Create the `.kiro/steering/` directory in the project root
    - Create `.kiro/steering/product.md` with product context: project name ("Task Tracker Demo"), description, and goals (e.g., "Learn Kiro features", "Practice AI-assisted development")
    - _Requirements: 2.1, 2.2_
  - [ ] 3.2 Create technology and structure steering files
    - Create `.kiro/steering/tech.md` defining technology choices: TypeScript, Node.js, and coding conventions (e.g., "Use camelCase for variables", "Prefer async/await over callbacks")
    - Create `.kiro/steering/structure.md` defining project structure conventions: `src/` for source code, `tests/` for test files, naming conventions for files and modules
    - _Requirements: 2.2_
  - [ ] 3.3 Verify AI agent reflects steering context
    - Open the chat interface and send a test prompt such as "What technology stack does this project use?"
    - Confirm the AI agent's response references TypeScript, Node.js, and the conventions defined in steering files
    - Modify `.kiro/steering/tech.md` to add a new convention (e.g., "Use ESLint for linting"), then send a follow-up prompt and verify the AI reflects the updated content
    - _Requirements: 2.1, 2.3_

- [ ] 4. Checkpoint - Validate Workspace and Steering Configuration
  - Confirm the project workspace has `package.json`, `src/index.ts`, and the `.kiro/steering/` directory with three markdown files (`product.md`, `tech.md`, `structure.md`)
  - Verify the integrated terminal executes commands and shows output
  - Verify the chat panel opens with mode toggle visible
  - Verify the AI agent references steering file content in its responses
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Spec-Driven Development Workflow
  - [ ] 5.1 Initiate spec-driven development and generate requirements
    - Use Kiro's spec-driven development feature (via command palette or menu) to start a new spec
    - Provide the high-level idea: "Build a simple task tracker that lets users add, list, and complete tasks"
    - Allow Kiro to generate structured requirements capturing the functional objectives
    - Review the generated requirements document stored in `.kiro/specs/` directory
    - _Requirements: 3.1, 3.4_
  - [ ] 5.2 Generate system design and implementation tasks
    - Progress through the spec workflow to generate a system design document from the requirements
    - Review the design document for technical architecture and component decisions
    - Continue to the task generation phase and review the discrete implementation tasks produced
    - Verify all three artifacts (requirements, design, tasks) are stored as files in the workspace
    - Practice editing a spec artifact (e.g., modify a requirement) to confirm files are editable and versionable
    - _Requirements: 3.2, 3.3, 3.4_

- [ ] 6. AI Chat Interaction and Mode Selection
  - [ ] 6.1 Use supervised mode for controlled code generation
    - Ensure the chat panel is set to supervised mode using the mode toggle
    - Send a prompt: "Create a TypeScript interface for a Task with id, title, description, and completed fields in src/models/task.ts"
    - Observe the AI agent proposing code changes and waiting for approval
    - Approve the proposed changes and verify the file is created in the workspace
    - Send a follow-up prompt to refine the output (e.g., "Add a createdAt date field to the Task interface") to demonstrate iterative refinement
    - _Requirements: 4.1, 4.3, 4.4_
  - [ ] 6.2 Use autopilot mode for autonomous code generation
    - Toggle to autopilot mode using the chat panel toggle
    - Confirm the mode change has taken effect
    - Send a prompt: "Create a TaskService class in src/services/taskService.ts with methods to add, list, and complete tasks"
    - Observe the AI agent autonomously generating and applying code changes without per-action approval
    - Send a follow-up refinement prompt (e.g., "Add input validation to the addTask method") to further demonstrate iterative prompt engineering
    - _Requirements: 4.2, 4.3, 4.4_

- [ ] 7. Agent Hooks for Event-Driven Automation
  - [ ] 7.1 Create an on-save agent hook
    - Create the `.kiro/hooks/` directory if it does not exist
    - Create an agent hook configuration that responds to file save events on `*.ts` files
    - Define a custom prompt instruction for the hook, e.g., "Check the saved TypeScript file for any missing type annotations and suggest fixes"
    - Save a `.ts` file in the workspace and verify the hook triggers the specified AI action automatically
    - _Requirements: 5.1, 5.3_
  - [ ] 7.2 Create an on-create agent hook and verify feedback
    - Create an agent hook that responds to file creation events for `*.test.ts` files
    - Define the prompt instruction: "When a new test file is created, generate a basic test skeleton with describe and it blocks based on the corresponding source file"
    - Create a new file `tests/taskService.test.ts` and verify the hook fires and generates test scaffolding
    - If the hook encounters an issue, review the IDE feedback to diagnose and correct the hook configuration
    - _Requirements: 5.2, 5.3, 5.4_

- [ ] 8. Checkpoint - Validate AI Features and Automation
  - Confirm spec-driven development artifacts exist in `.kiro/specs/` (requirements, design, tasks files)
  - Verify supervised mode produces proposals requiring approval before applying changes
  - Verify autopilot mode applies changes autonomously
  - Confirm at least one agent hook triggers successfully on a file save or file creation event
  - Review IDE feedback for any hook execution issues
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. MCP Server Configuration and External Tool Integration
  - [ ] 9.1 Open and edit MCP configuration
    - Open the MCP configuration through Kiro settings or command palette (Cmd+Shift+P / Ctrl+Shift+P, search "MCP Config")
    - Choose to edit the workspace-level MCP configuration file (click "Open Workspace MCP Config")
    - _Requirements: 6.1_
  - [ ] 9.2 Add MCP server entry and verify integration
    - Add a valid MCP server entry to the configuration file in JSON format, specifying `server_name`, `command`, and `args` fields (e.g., configure the AWS MCP Server or another available MCP server)
    - Reload or restart the Kiro workspace for the configuration to take effect
    - Open the chat interface and query the AI agent about its accessible tools (e.g., "What MCP tools do you have access to?")
    - Verify the AI agent recognizes and lists tools provided by the configured MCP server
    - If the server is not recognized, check the JSON syntax, verify the command path, and ensure the workspace was fully reloaded
    - _Requirements: 6.2, 6.3_

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Remove demo project artifacts
    - Delete agent hook configurations: remove files from `.kiro/hooks/` directory
    - Delete steering files: remove files from `.kiro/steering/` directory
    - Remove MCP configuration entries added during the exercise (revert workspace MCP config to its original state)
    - Optionally delete the entire demo project directory: `rm -rf ~/kiro-demo-task-tracker`
    - _Requirements: (all)_
  - [ ] 10.2 Verify cleanup
    - Confirm the `.kiro/` directory has been cleaned or the project folder has been removed
    - Verify no lingering MCP server configurations remain in user-level settings (if modified)
    - No AWS resources were provisioned during this exercise, so no cloud cleanup is required
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- This project is entirely local — no AWS resources are created or billed, so cleanup focuses on local file removal
- The demo project (task tracker) is a vehicle for learning Kiro features, not a production application
- Learners should experiment freely with prompts and steering file content to deepen their understanding of how AI context works in Kiro
