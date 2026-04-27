

# Implementation Plan: Build a Text Summarization App with Amazon Bedrock

## Overview

This implementation plan guides learners through building a text summarization application using AWS App Studio and Amazon Bedrock. The project follows a structured progression: setting up the development environment and prerequisites, configuring IAM permissions and enabling the foundation model, implementing Python components for IAM role management and direct Bedrock invocation, configuring the App Studio application with its connector, UI, and automation, and finally publishing and testing the end-to-end workflow.

The plan is organized into three key phases. The first phase covers environment setup, IAM role creation, and Bedrock model enablement — establishing the security and infrastructure foundation. The second phase implements the Python components (IAMRoleManager, BedrockSummarizer, and AppStudioConfigurator) that automate role provisioning, provide direct model invocation for testing, and generate configuration guidance for the App Studio console steps. The third phase walks through the App Studio console configuration — creating the connector, building the UI, wiring the automation, and publishing the application for live testing.

Dependencies flow linearly: IAM role creation must precede connector setup, the connector must exist before automation configuration, and the automation must be defined before button triggers can reference it. The Python BedrockSummarizer component serves as both a learning tool and a validation mechanism — learners can verify Bedrock access works via Python before troubleshooting App Studio integration. All data models (SummarizationConfig, SummarizationResult, ConnectorConfig, AutomationConfig, UILayoutConfig, TriggerConfig) are implemented within their respective component modules.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with App Studio Admin role access
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Create project directory structure: `mkdir -p components && touch components/__init__.py`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 1.3 Enable Amazon Bedrock Claude 3 Sonnet Model
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Navigate to Amazon Bedrock console → Model access → Request access for Claude 3 Sonnet
    - Wait for model status to show as "Available" / "Access granted"
    - Verify model access via CLI: `aws bedrock list-foundation-models --query "modelSummaries[?modelId=='anthropic.claude-3-sonnet-20240229-v1:0'].modelId"`
    - _Requirements: 1.1, 1.3_

- [ ] 2. Implement IAMRoleManager Component
  - [ ] 2.1 Create IAMRoleManager class with role creation and policy attachment
    - Create file `components/iam_role_manager.py`
    - Define the `SummarizationConfig` data model as a dataclass with fields: `model_id` (str), `temperature` (float), `max_tokens` (int), `system_prompt` (str)
    - Implement `create_bedrock_role(role_name: str, trust_policy: dict) -> dict` using `boto3.client('iam').create_role()`
    - Set the trust policy to allow App Studio to assume the role
    - Implement `attach_bedrock_policy(role_name: str, model_id: str) -> None` that creates and attaches an inline policy scoped to `bedrock:InvokeModel` for the specific model ARN only (least privilege)
    - Implement `get_role_arn(role_name: str) -> str` using `iam.get_role()`
    - Implement `delete_bedrock_role(role_name: str) -> None` that detaches policies and deletes the role
    - _Requirements: 1.2, 1.3_
  - [ ] 2.2 Run IAM role creation script
    - Create `scripts/setup_iam.py` that instantiates `IAMRoleManager` and creates a role named `AppStudioBedrockRole`
    - Execute: `python3 scripts/setup_iam.py`
    - Verify role exists: `aws iam get-role --role-name AppStudioBedrockRole`
    - Note the Role ARN for use in App Studio connector configuration
    - _Requirements: 1.2, 2.2_
  - [ ]* 2.3 Verify least privilege IAM policy
    - **Property 1: Least Privilege Policy Scope**
    - **Validates: Requirements 1.2, 2.3**

- [ ] 3. Implement BedrockSummarizer Component
  - [ ] 3.1 Create BedrockSummarizer class with model invocation
    - Create file `components/bedrock_summarizer.py`
    - Define the `SummarizationResult` data model as a dataclass with fields: `summary_text` (str), `input_token_count` (int), `output_token_count` (int), `model_id` (str)
    - Import and use `SummarizationConfig` from `iam_role_manager` module (or define in a shared `models.py`)
    - Implement `check_model_access(model_id: str) -> bool` using `boto3.client('bedrock').get_foundation_model()`
    - Implement `list_available_models() -> list[str]` using `boto3.client('bedrock').list_foundation_models()`
    - Implement `summarize_text(input_text: str, config: SummarizationConfig) -> SummarizationResult` using `boto3.client('bedrock-runtime').invoke_model()`
    - Configure the request body with `temperature: 0`, `max_tokens: 4096`, system prompt for summarization, and user message containing `input_text`
    - Parse the response to extract summary text and token counts into `SummarizationResult`
    - Handle empty/missing input text by raising a `ValueError`
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 3.2 Test direct Bedrock summarization via Python
    - Create `scripts/test_summarize.py` that instantiates `BedrockSummarizer` and calls `summarize_text()` with sample text
    - Use config: `model_id="anthropic.claude-3-sonnet-20240229-v1:0"`, `temperature=0`, `max_tokens=4096`, system_prompt="You are a text summarization assistant. Provide concise summaries of the provided text."
    - Execute: `python3 scripts/test_summarize.py`
    - Verify a coherent summary is returned and token counts are populated
    - Test with empty string input to verify error handling
    - _Requirements: 1.1, 5.1, 5.2, 5.3, 5.4_

- [ ] 4. Checkpoint - Validate Infrastructure and Bedrock Access
  - Verify IAM role exists and has correct permissions: `aws iam get-role --role-name AppStudioBedrockRole`
  - Verify Bedrock model is accessible: `aws bedrock get-foundation-model --model-identifier anthropic.claude-3-sonnet-20240229-v1:0`
  - Run `python3 scripts/test_summarize.py` and confirm a summary is returned
  - Verify `check_model_access()` returns `True` for Claude 3 Sonnet
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement AppStudioConfigurator and Configure App Studio
  - [ ] 5.1 Create AppStudioConfigurator class
    - Create file `components/app_studio_configurator.py`
    - Define data models as dataclasses: `ConnectorConfig` (connector_name, iam_role_arn, service), `AutomationConfig` (automation_name, input_parameter_name, input_parameter_type, action_name, connector_name, model_id, user_prompt_template, system_prompt, temperature, max_tokens, output_expression), `UILayoutConfig` (page_name, input_component_name, button_component_name, button_label, output_component_name), `TriggerConfig` (button_name, trigger_1_name, trigger_1_type, trigger_1_automation, trigger_1_input, trigger_2_name, trigger_2_type, trigger_2_component, trigger_2_action, trigger_2_value)
    - Implement `generate_connector_config(role_arn: str, connector_name: str) -> ConnectorConfig` returning config with service="Bedrock Runtime"
    - Implement `generate_automation_config(connector_name: str, model_id: str, config: SummarizationConfig) -> AutomationConfig` with automation_name="InvokeBedrock", input_parameter_name="input", user_prompt_template="{{params.input}}", output_expression="{{results.PromptBedrock.text}}"
    - Implement `generate_ui_layout() -> UILayoutConfig` returning page_name="TextSummarizationTool", input="inputPrompt", button="sendButton" (label="Send"), output="textSummary"
    - Implement `generate_trigger_config(automation_name: str) -> TriggerConfig` with trigger_1 "invokeBedrockAutomation" (Invoke Automation, input="{{ui.inputPrompt.value}}") and trigger_2 "setTextSummary" (Run component action, Set value, "{{results.invokeBedrockAutomation}}")
    - Implement `generate_cleanup_checklist() -> list[str]` returning list of resources to clean up
    - _Requirements: 2.1, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 6.1, 6.2, 6.3_
  - [ ] 5.2 Create App Studio connector and application via console
    - Run `python3 -c "from components.app_studio_configurator import AppStudioConfigurator; c = AppStudioConfigurator(); print(c.generate_connector_config('<your-role-arn>', 'BedrockConnector'))"` to get connector config
    - In App Studio console: Create a new connector named "BedrockConnector" using the IAM role ARN from Task 2.2
    - Verify the connector appears in the connectors list
    - Create a new application: Choose "Start from scratch", name it "Text Summarizer"
    - Choose "Edit app" to enter the application studio
    - Rename the default page to "TextSummarizationTool" in the Properties panel
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

- [ ] 6. Build App Studio UI, Automation, and Triggers
  - [ ] 6.1 Create the automation in App Studio
    - Navigate to the Automations tab and create a new automation named "InvokeBedrock"
    - Add an input parameter: name="input", type="String"
    - Add a GenAI Prompt action, rename to "PromptBedrock"
    - Configure action: select "BedrockConnector" connector, select Claude 3 Sonnet model
    - Set user prompt to `{{params.input}}`
    - Set system prompt: "You are a text summarization assistant. Provide concise summaries of the provided text."
    - Set temperature to `0` and max tokens to `4096`
    - Set automation output to `{{results.PromptBedrock.text}}`
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 6.2 Add UI components to the page
    - Run the AppStudioConfigurator to review UI layout: `python3 -c "from components.app_studio_configurator import AppStudioConfigurator; print(AppStudioConfigurator().generate_ui_layout())"`
    - Add a Text input component from the Components panel, rename to "inputPrompt"
    - Add a Button component below the text input, rename to "sendButton", set label to "Send"
    - Add a Text area component below the button, rename to "textSummary"
    - Verify components are arranged top-to-bottom: inputPrompt → sendButton → textSummary
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 6.3 Configure button triggers for end-to-end workflow
    - Run the AppStudioConfigurator to review trigger config: `python3 -c "from components.app_studio_configurator import AppStudioConfigurator; print(AppStudioConfigurator().generate_trigger_config('InvokeBedrock'))"`
    - Select the sendButton component and open Properties panel
    - Add Trigger 1: name="invokeBedrockAutomation", type="Invoke Automation", automation="InvokeBedrock", input parameter value=`{{ui.inputPrompt.value}}`
    - Add Trigger 2: name="setTextSummary", type="Run component action", component="textSummary", action="Set value", value=`{{results.invokeBedrockAutomation}}`
    - Verify triggers are ordered sequentially (trigger 1 executes before trigger 2)
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 7. Checkpoint - Validate App Studio Configuration
  - Verify connector "BedrockConnector" is listed in App Studio connectors
  - Verify page is named "TextSummarizationTool" with three components visible
  - Verify automation "InvokeBedrock" has correct input parameter, action, and output
  - Verify sendButton has two triggers configured in correct order
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Publish and Test the Application
  - [ ] 8.1 Publish application to Testing environment
    - In the top-right corner of the app builder, choose "Publish"
    - Add a version description for the Testing environment
    - Review and accept the SLA checkbox
    - Choose "Start" — publishing may take up to 15 minutes
    - Wait for the application to become accessible in the Testing environment
    - _Requirements: 7.1_
  - [ ] 8.2 Test end-to-end summarization workflow
    - Open the published application in the Testing environment
    - Enter sample text into the inputPrompt field (e.g., a paragraph of meeting notes or article content)
    - Click the "Send" button
    - Verify the textSummary area displays a coherent, concise summary generated by Claude 3 Sonnet
    - Test with different input types: meeting notes, article content, research findings
    - Test with empty input to verify behavior (no valid summary produced)
    - _Requirements: 7.1, 7.2_
  - [ ] 8.3 Promote to Production (optional) and verify
    - After successful testing, choose "Publish" again to promote the application to the Production environment
    - Note: apps in Production are not available to end users until shared
    - Verify the application is accessible in the Production environment
    - _Requirements: 7.3_

- [ ] 9. Cleanup - Resource Teardown
  - [ ] 9.1 Delete App Studio resources
    - Delete or unpublish the "Text Summarizer" application from App Studio
    - Delete the "BedrockConnector" connector from App Studio (Admin role required)
    - Run AppStudioConfigurator cleanup checklist: `python3 -c "from components.app_studio_configurator import AppStudioConfigurator; print(AppStudioConfigurator().generate_cleanup_checklist())"`
    - _Requirements: 7.4_
  - [ ] 9.2 Delete IAM role and verify cleanup
    - Run the IAMRoleManager deletion: `python3 -c "from components.iam_role_manager import IAMRoleManager; m = IAMRoleManager(); m.delete_bedrock_role('AppStudioBedrockRole')"`
    - Or manually: `aws iam delete-role-policy --role-name AppStudioBedrockRole --policy-name BedrockInvokePolicy && aws iam delete-role --role-name AppStudioBedrockRole`
    - Verify IAM role is deleted: `aws iam get-role --role-name AppStudioBedrockRole` (should return NoSuchEntity error)
    - Optionally disable Claude 3 Sonnet model access in Bedrock console if no longer needed
    - Check AWS Cost Explorer for any remaining charges related to Bedrock invocations
    - _Requirements: 7.4_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- App Studio configuration (Tasks 5.2, 6.1–6.3) is performed through the AWS console; the AppStudioConfigurator Python component generates configuration data to guide these console steps
- The BedrockSummarizer Python component allows learners to test Bedrock invocation directly before configuring App Studio, providing a debugging baseline
- Preview mode in App Studio does not connect to external services — publishing to the Testing environment is required for live Bedrock integration testing
