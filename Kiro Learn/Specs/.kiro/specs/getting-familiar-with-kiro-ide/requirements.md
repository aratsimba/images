# Requirements Document

## Introduction

This project introduces learners to the Kiro IDE, an AI-powered integrated development environment built on the foundation of Visual Studio Code. Kiro enhances traditional coding workflows with AI-driven features such as spec-driven development, a steering system for persistent project knowledge, agent hooks for event-driven automation, and an intelligent chat interface for interacting with AI agents. Understanding how these features work together is essential for developers who want to incorporate AI assistance into their development process effectively.

The learning exercise guides developers through the core capabilities of Kiro by setting up a workspace, configuring the steering system, using spec-driven development to transform ideas into structured plans, and leveraging agent hooks and chat modes to accelerate coding tasks. By completing this project, learners will gain hands-on familiarity with Kiro's distinguishing features and understand how to integrate them into real-world development workflows.

The approach is exploratory and incremental. Learners will start with basic IDE orientation and terminal integration, progress through the steering system and spec-driven development workflow, and conclude with automation through agent hooks and effective use of Kiro's AI interaction modes. Each requirement represents a distinct learning milestone that builds on the previous one.

## Glossary

- **spec_driven_development**: Kiro's methodology for transforming high-level ideas into structured requirements, system designs, and discrete implementation tasks through AI-guided workflows.
- **steering_system**: A persistent knowledge base composed of markdown files stored in a dedicated project directory that defines project standards, coding conventions, and architectural decisions to guide AI interactions across sessions.
- **agent_hooks**: Lightweight automation utilities in Kiro that trigger predefined AI actions in response to specific IDE events such as file saves or file creations.
- **autopilot_mode**: A Kiro chat mode in which the AI agent autonomously makes code changes without requiring approval for each individual action.
- **supervised_mode**: A Kiro chat mode in which the AI agent proposes changes that require explicit human approval before being applied.
- **steering_files**: Markdown files within the steering system that capture product context, technology choices, and project structure conventions.
- **mcp_server**: Model Context Protocol server configuration that extends Kiro's AI capabilities by connecting to external tools and services.
- **chat_interface**: Kiro's built-in panel for interacting with AI agents to receive intelligent assistance during the development process.

## Requirements

### Requirement 1: Kiro Workspace Setup and IDE Orientation

**User Story:** As a developer new to Kiro, I want to set up a Kiro workspace and navigate the core IDE interface elements, so that I can orient myself within the environment before using its AI-powered features.

#### Acceptance Criteria

1. WHEN the learner opens Kiro and creates or opens a project workspace, THE IDE SHALL display the familiar VS Code-based editor layout including the file explorer, editor pane, and terminal panel.
2. THE workspace SHALL provide access to the integrated terminal, allowing the learner to execute commands, navigate the file system, and view command output within the IDE.
3. WHEN the learner opens the chat interface panel, THE IDE SHALL present the AI agent interaction area with the ability to toggle between autopilot mode and supervised mode.
4. THE learner SHALL be able to access Kiro settings and the command palette using standard keyboard shortcuts consistent with VS Code conventions.

### Requirement 2: Steering System Configuration

**User Story:** As a developer learning Kiro, I want to configure the steering system with project-specific conventions and standards, so that the AI agent has persistent context about my project across all sessions.

#### Acceptance Criteria

1. WHEN the learner creates steering files in the dedicated steering directory, THE steering system SHALL persist the project knowledge and make it available to the AI agent in subsequent interactions.
2. THE steering files SHALL support defining product context, technology choices, and project structure conventions as separate markdown documents.
3. WHEN the learner modifies a steering file and then initiates a new AI interaction, THE AI agent SHALL reflect the updated project standards and conventions in its responses and code generation.

### Requirement 3: Spec-Driven Development Workflow

**User Story:** As a developer learning Kiro, I want to use spec-driven development to transform a high-level idea into structured requirements, a system design, and implementation tasks, so that I understand how Kiro guides projects from concept to actionable plans.

#### Acceptance Criteria

1. WHEN the learner provides a high-level project idea through the spec-driven development workflow, THE system SHALL generate structured requirements that capture the functional objectives of the idea.
2. WHEN the requirements phase is complete, THE system SHALL produce a system design document that translates the requirements into technical architecture and component decisions.
3. WHEN the design phase is complete, THE system SHALL break the design down into discrete implementation tasks that can be individually executed or reviewed.
4. THE spec-driven development artifacts (requirements, design, and tasks) SHALL be stored as files within the project workspace so the learner can review, edit, and version them.

### Requirement 4: AI Chat Interaction and Mode Selection

**User Story:** As a developer learning Kiro, I want to interact with the AI agent through the chat interface in both supervised and autopilot modes, so that I understand the tradeoffs between human-in-the-loop control and autonomous AI code generation.

#### Acceptance Criteria

1. WHEN the learner sends a prompt through the chat interface in supervised mode, THE AI agent SHALL propose code changes and wait for explicit human approval before applying them to the workspace.
2. WHEN the learner switches to autopilot mode and sends a prompt, THE AI agent SHALL autonomously generate and apply code changes without requiring per-action approval.
3. WHEN the learner toggles between autopilot and supervised mode using the chat panel toggle, THE mode change SHALL take effect for subsequent interactions immediately.
4. THE chat interface SHALL allow the learner to provide iterative follow-up prompts to refine the AI agent's output, demonstrating the value of prompt engineering through progressive refinement.

### Requirement 5: Agent Hooks for Event-Driven Automation

**User Story:** As a developer learning Kiro, I want to configure agent hooks that trigger predefined AI actions in response to IDE events, so that I can automate repetitive development tasks like code quality checks or test generation.

#### Acceptance Criteria

1. WHEN the learner creates an agent hook that responds to a file save event, THE hook SHALL automatically invoke the specified AI action each time a matching file is saved in the workspace.
2. WHEN the learner creates an agent hook that responds to a file creation event, THE hook SHALL trigger the specified AI action when a new file matching the hook's criteria is created.
3. THE agent hook configuration SHALL allow the learner to define custom prompt instructions that guide the AI action performed when the hook is triggered.
4. IF an agent hook encounters an issue during execution, THEN THE IDE SHALL surface feedback to the learner so that the hook behavior can be diagnosed and corrected.

### Requirement 6: MCP Server Configuration and External Tool Integration

**User Story:** As a developer learning Kiro, I want to configure an MCP server within Kiro, so that I understand how to extend the AI agent's capabilities by connecting it to external tools and services.

#### Acceptance Criteria

1. WHEN the learner opens the MCP configuration through Kiro settings or the command palette, THE IDE SHALL present the option to edit workspace-level or user-level MCP configuration files.
2. WHEN the learner adds a valid MCP server entry to the configuration file and restarts or reloads the workspace, THE AI agent SHALL recognize and have access to the tools provided by the configured MCP server.
3. THE learner SHALL be able to verify available MCP tools through the chat interface by querying the AI agent about its accessible tool capabilities.
