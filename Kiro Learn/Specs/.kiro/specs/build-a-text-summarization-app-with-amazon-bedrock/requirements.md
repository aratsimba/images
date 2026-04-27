

# Requirements Document

## Introduction

This project guides learners through building a text summarization application using Amazon Bedrock and AWS App Studio. The application provides a simple user interface where users can input text—such as meeting notes, article content, or research findings—and receive concise AI-generated summaries powered by a foundation model. This exercise introduces core concepts of integrating generative AI capabilities into applications using AWS managed services.

Text summarization is a foundational generative AI use case with broad applicability across industries, from condensing legal documents to creating content previews. By building this application, learners will gain hands-on experience with Amazon Bedrock's model invocation capabilities, App Studio's low-code development environment, and the connectors and automation patterns that tie them together. Understanding how to configure AI model parameters such as temperature and token limits is essential for producing reliable, high-quality outputs.

The project follows a structured approach: establishing the necessary IAM permissions and service connectors, designing a user interface with input and output components, creating an automation workflow that sends text to a foundation model and returns a summary, and finally publishing and testing the application in a live environment.

## Glossary

- **amazon_bedrock**: A fully managed AWS service that provides access to foundation models from various AI providers through a unified interface, enabling generative AI capabilities without managing infrastructure.
- **app_studio**: An AWS low-code development environment for building enterprise applications using visual components, automations, and connectors with minimal coding.
- **foundation_model**: A large-scale AI model pre-trained on broad datasets that can be adapted for various tasks such as text summarization, generation, and analysis.
- **connector**: An App Studio resource that bridges the application to an external AWS service, configured with an IAM role to authorize access.
- **automation**: A defined sequence of actions, parameters, and outputs in App Studio that encapsulates application logic and behavior.
- **temperature**: A model inference parameter that controls the randomness of generated responses; lower values produce more deterministic and factual outputs.
- **max_tokens**: A model inference parameter that sets the upper limit on the number of tokens the model can generate in a single response.
- **system_prompt**: Instructions provided to a foundation model that define its behavior, role, and constraints for processing user input.

## Requirements

### Requirement 1: IAM Role and Bedrock Model Access

**User Story:** As a generative AI learner, I want to configure IAM permissions and enable a foundation model in Amazon Bedrock, so that my application can securely invoke AI capabilities for text summarization.

#### Acceptance Criteria

1. WHEN the learner enables the Claude 3 Sonnet model in Amazon Bedrock, THE model SHALL appear as available for invocation in the learner's account and region.
2. THE IAM role created for this project SHALL grant permissions scoped to Amazon Bedrock model invocation and SHALL follow the principle of least privilege.
3. IF the learner attempts to invoke a model that has not been enabled, THEN Amazon Bedrock SHALL deny the request and indicate that model access has not been granted.

### Requirement 2: App Studio Connector Configuration

**User Story:** As a generative AI learner, I want to create an App Studio connector linked to my IAM role, so that my application can communicate with Amazon Bedrock through a secure, managed integration point.

#### Acceptance Criteria

1. WHEN the learner creates a connector in App Studio using the IAM role with Bedrock permissions, THE connector SHALL be available for selection in automations within the application.
2. THE connector SHALL use the IAM role's credentials to authorize requests to Amazon Bedrock, ensuring the application does not require embedded access keys.
3. IF the connector is configured with an IAM role that lacks Amazon Bedrock permissions, THEN automation actions using that connector SHALL fail and indicate an authorization error.

### Requirement 3: Application and Page Structure

**User Story:** As a generative AI learner, I want to create an App Studio application with a clearly named page, so that I have an organized workspace for building the text summarization interface.

#### Acceptance Criteria

1. WHEN the learner creates a new application from scratch in App Studio, THE application SHALL be initialized with a default page ready for component placement.
2. THE learner SHALL be able to rename the default page to a descriptive name (e.g., "TextSummarizationTool") and THE updated name SHALL be reflected in the application's page navigation.
3. THE application structure SHALL support adding components, automations, and connector references within a single-page layout.

### Requirement 4: User Interface Design

**User Story:** As a generative AI learner, I want to design an interface with a text input field, a submission button, and a text area for results, so that users have a clear workflow for entering text and viewing AI-generated summaries.

#### Acceptance Criteria

1. WHEN the learner adds a text input component to the page, THE component SHALL accept free-form text entry from users and make the entered value accessible to automations.
2. WHEN the learner adds a text area component to the page, THE component SHALL be capable of displaying multi-paragraph summary text returned from the automation.
3. THE button component SHALL support attaching triggers that invoke automations and set component values, enabling a sequential workflow from user input to displayed output.
4. THE three components SHALL be arrangeable on the canvas in a logical top-to-bottom flow: input field, button, then results area.

### Requirement 5: Bedrock Summarization Automation

**User Story:** As a generative AI learner, I want to create an automation that sends user-provided text to Amazon Bedrock and returns a summary, so that I understand how to orchestrate AI model invocation within an application workflow.

#### Acceptance Criteria

1. WHEN the automation receives a text string parameter as input, THE GenAI Prompt action SHALL send that text to the configured Amazon Bedrock foundation model along with system instructions for summarization.
2. THE automation SHALL be configured with a temperature value of 0 and a max tokens limit of 4096, ensuring deterministic and sufficiently detailed summary output.
3. WHEN the foundation model returns a response, THE automation output SHALL contain the generated summary text and make it available to UI components.
4. IF the input text parameter is empty or missing, THEN THE automation SHALL not produce a valid summary result.

### Requirement 6: Button Triggers and Workflow Integration

**User Story:** As a generative AI learner, I want to configure the button to invoke the summarization automation and display the result in the text area, so that the end-to-end workflow functions with a single user action.

#### Acceptance Criteria

1. WHEN the user clicks the send button, THE button's first trigger SHALL invoke the Bedrock automation and pass the current value of the text input component as the input parameter.
2. WHEN the automation completes successfully, THE button's second trigger SHALL set the text area component's value to the automation's returned summary text.
3. THE triggers SHALL execute in sequence, ensuring the automation result is available before the text area value is set.

### Requirement 7: Application Publishing and Testing

**User Story:** As a generative AI learner, I want to publish my application to the Testing environment and verify end-to-end functionality, so that I can confirm the summarization workflow operates correctly with live Amazon Bedrock integration.

#### Acceptance Criteria

1. WHEN the learner publishes the application to the Testing environment, THE application SHALL become accessible for interactive testing with live connections to Amazon Bedrock.
2. WHEN a user enters text into the input field and clicks the send button in the published application, THE text area SHALL display a coherent summary generated by the foundation model.
3. WHEN the learner is satisfied with the testing results, THE application SHALL be promotable from the Testing environment to the Production environment through the publish workflow.
4. THE learner SHALL be able to clean up all resources created during the project, including the App Studio application and the Amazon Bedrock connector.
