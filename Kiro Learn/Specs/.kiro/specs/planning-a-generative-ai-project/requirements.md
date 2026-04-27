

# Requirements Document

## Introduction

This project guides learners through the end-to-end process of planning a generative AI project on AWS. Rather than jumping directly into model building or prompt engineering, this exercise emphasizes the critical upfront work: defining project scope, identifying appropriate use cases, establishing governance, and creating an implementation plan that leverages AWS services for generative AI development. These planning disciplines are what separate successful AI initiatives from costly failures.

Planning a generative AI project requires balancing business objectives, technical feasibility, responsible AI considerations, and organizational readiness. Learners will work through a structured planning methodology — from scoping customer problems and evaluating organizational capability, through selecting appropriate AWS generative AI services, to establishing guardrails and evaluation criteria. The exercise culminates in a working project artifact deployed within the AWS generative AI ecosystem.

By completing this project, learners will gain practical experience with Amazon Bedrock's project and governance capabilities, understand how to align generative AI use cases with business outcomes, and develop the planning habits needed to responsibly deliver AI-powered solutions. The project uses a realistic scenario where the learner acts as both the AI project planner and the initial implementer of a proof-of-concept generative AI application.

## Glossary

- **project_scope**: The defined boundaries of a generative AI initiative, including target customers, problems to solve, desired outcomes, and constraints that limit what the project will and will not address.
- **use_case_prioritization**: The process of evaluating and ranking potential generative AI applications based on business value, technical feasibility, data availability, and organizational readiness.
- **governance_policy**: A set of rules and guidelines that govern how AI models are trained, deployed, monitored, and retired, including ethical use frameworks and compliance requirements.
- **knowledge_base**: A structured collection of organizational data sources that a generative AI application can query to provide contextually relevant and grounded responses, powered by Amazon Bedrock Knowledge Bases.
- **guardrail**: A configurable safety mechanism in Amazon Bedrock that filters and controls model inputs and outputs to enforce content policies, topic restrictions, and responsible AI standards.
- **model_evaluation**: The systematic process of assessing a generative AI model's outputs against defined quality criteria such as relevance, accuracy, coherence, and harmlessness, using Amazon Bedrock Evaluations.
- **foundation_model**: A large pre-trained AI model available through Amazon Bedrock that can be used directly or customized for specific generative AI tasks such as text generation, summarization, or conversation.
- **implementation_roadmap**: A detailed plan outlining milestones, resource requirements, effort estimates, and deliverables needed to move a generative AI project from concept to production.

## Requirements

### Requirement 1: Define Project Scope and Use Case

**User Story:** As a generative AI project planner, I want to define a clear project scope with a specific customer problem and measurable business outcome, so that my generative AI initiative is focused, relevant, and achievable.

#### Acceptance Criteria

1. WHEN the learner defines a project scope, THE scope document SHALL include a clearly stated customer problem, target audience, desired business outcome, and at least one constraint or boundary condition.
2. THE project scope SHALL identify whether the use case requires text generation, summarization, question answering, or conversational interaction so that the appropriate foundation model category can be selected.
3. IF the learner's defined use case involves sensitive data domains (such as healthcare, finance, or personal information), THEN THE scope document SHALL include a note identifying relevant compliance considerations.
4. WHEN the learner evaluates organizational readiness, THE assessment SHALL address data availability, required skills, estimated effort, and whether the organization should pursue the initiative.

### Requirement 2: Foundation Model Selection Using Amazon Bedrock

**User Story:** As a generative AI project planner, I want to explore and compare available foundation models in Amazon Bedrock, so that I can select a model that aligns with my project's requirements for capability, cost, and performance.

#### Acceptance Criteria

1. WHEN the learner accesses Amazon Bedrock, THE service SHALL present a catalog of available foundation models with their provider, capability category, and supported input/output modalities.
2. WHEN the learner enables model access for a selected foundation model, THE model SHALL become available for inference within the learner's account and region.
3. THE learner SHALL interact with at least two different foundation models using the same prompt in the Amazon Bedrock playground to compare output quality, style, and relevance to their defined use case.
4. IF a foundation model is not available in the learner's selected region, THEN THE service SHALL indicate the model's unavailability and the learner SHALL document this as a constraint in their planning artifact.

### Requirement 3: Establish Responsible AI Guardrails

**User Story:** As a generative AI project planner, I want to configure guardrails for my generative AI application, so that model interactions are governed by content policies and responsible AI standards aligned with my project's governance requirements.

#### Acceptance Criteria

1. WHEN the learner creates a guardrail in Amazon Bedrock Guardrails, THE guardrail SHALL include at least one content filter configuration that defines thresholds for harmful content categories.
2. WHEN the learner configures a denied topic in the guardrail, THE guardrail SHALL block model responses that address the specified topic and return a configured blocked message instead.
3. THE learner SHALL associate the configured guardrail with their selected foundation model so that all subsequent interactions are filtered through the guardrail policies.
4. IF a user prompt or model response triggers a guardrail violation, THEN THE system SHALL intervene according to the configured policy and THE learner SHALL be able to review the trace information showing which guardrail rule was activated.

### Requirement 4: Build a Knowledge Base for Grounded Responses

**User Story:** As a generative AI project planner, I want to create a knowledge base backed by organizational documents, so that my generative AI application can provide responses grounded in authoritative data rather than relying solely on the foundation model's training data.

#### Acceptance Criteria

1. WHEN the learner creates an Amazon Bedrock Knowledge Base with a specified data source (such as an Amazon S3 bucket containing project-relevant documents), THE service SHALL ingest and index the documents for retrieval.
2. WHEN the learner syncs the knowledge base data source, THE knowledge base SHALL process the documents into vector embeddings and store them in the configured vector store.
3. WHEN the learner queries the knowledge base, THE response SHALL include generated text grounded in the ingested documents along with source attribution citations indicating which documents informed the answer.
4. IF the knowledge base does not contain information relevant to a query, THEN THE response SHALL indicate that insufficient information is available rather than fabricating an answer.

### Requirement 5: Create a Conversational Agent with Planning Context

**User Story:** As a generative AI project planner, I want to build a conversational agent in Amazon Bedrock that can answer questions about my generative AI project plan, so that stakeholders can interact with the planning documentation through natural language.

#### Acceptance Criteria

1. WHEN the learner creates an Amazon Bedrock Agent, THE agent SHALL be associated with a foundation model, a set of instructions defining its planning-assistant persona, and the previously created knowledge base.
2. WHEN a user asks the agent a question about the project scope, use cases, or governance policies, THE agent SHALL retrieve relevant information from the knowledge base and generate a contextually appropriate response.
3. THE agent SHALL maintain conversational context within a session so that follow-up questions can reference prior exchanges without requiring the user to restate context.
4. WHEN the learner prepares the agent for testing, THE agent SHALL be available in a test console where the learner can validate its behavior against expected responses for their project planning scenarios.

### Requirement 6: Evaluate Model Output Quality

**User Story:** As a generative AI project planner, I want to evaluate the quality of my generative AI application's outputs against defined criteria, so that I can measure whether the solution meets the business objectives established in my project scope.

#### Acceptance Criteria

1. WHEN the learner creates an evaluation job in Amazon Bedrock Evaluations, THE evaluation SHALL assess model outputs against at least two quality dimensions (such as relevance, coherence, accuracy, or harmlessness).
2. THE learner SHALL define a test dataset of representative prompts and expected reference responses that align with the use case identified in their project scope.
3. WHEN the evaluation job completes, THE results SHALL provide quantitative scores for each quality dimension so the learner can identify specific areas where the model underperforms.
4. IF the evaluation results reveal quality gaps, THEN THE learner SHALL document recommended mitigations (such as prompt refinement, guardrail adjustments, or knowledge base expansion) as part of their implementation roadmap.

### Requirement 7: Produce an Implementation Roadmap and Project Artifact

**User Story:** As a generative AI project planner, I want to compile my planning decisions, configurations, and evaluation results into a structured implementation roadmap, so that I have a comprehensive artifact demonstrating end-to-end generative AI project planning on AWS.

#### Acceptance Criteria

1. THE implementation roadmap SHALL consolidate the project scope, model selection rationale, guardrail configuration decisions, knowledge base design, agent architecture, and evaluation results into a single structured document.
2. THE roadmap SHALL define at least three milestones with associated deliverables that trace from proof-of-concept through to a production-readiness checkpoint.
3. WHEN the learner identifies risks during any planning step (such as model availability, data quality gaps, or compliance concerns), THE roadmap SHALL include those risks with proposed mitigation strategies.
4. THE roadmap SHALL include an effort estimation section that addresses resource requirements, skill gaps requiring enablement activities, and budget considerations for the AWS services used in the project.
