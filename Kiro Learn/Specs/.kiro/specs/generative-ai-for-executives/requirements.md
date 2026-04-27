

# Requirements Document

## Introduction

This learning project guides executives and strategic leaders through a hands-on exploration of generative AI concepts, capabilities, and responsible adoption strategies using AWS services. Rather than building production AI systems, learners will engage with foundation models, evaluate use cases, and implement lightweight proof-of-concept workflows that demonstrate how generative AI can be strategically applied across an organization's workforce, processes, and products.

The project matters because executive leaders must move beyond theoretical understanding of generative AI to develop informed intuition about what these technologies can and cannot do. By directly interacting with foundation models through Amazon Bedrock, evaluating outputs for quality and responsibility, and prototyping a simple use case end-to-end, leaders gain the practical grounding needed to guide investment decisions, set responsible AI policies, and champion adoption across their organizations.

The high-level approach begins with exploring foundation models and their capabilities, progresses through responsible AI evaluation and use case prioritization, and culminates in building a simple generative AI prototype — such as a knowledge assistant or content generation tool — that demonstrates strategic value. Throughout the project, learners will assess outputs against business objectives, ethical guidelines, and quality standards that mirror real organizational decision-making.

## Glossary

- **foundation_model**: A large pre-trained AI model that can be adapted to a wide range of tasks, such as text generation, summarization, and question answering, without requiring training from scratch.
- **prompt_engineering**: The practice of crafting input text (prompts) to guide a foundation model toward producing desired outputs, including techniques like providing context, examples, and constraints.
- **retrieval_augmented_generation**: A technique (RAG) that enhances a foundation model's responses by retrieving relevant information from external data sources and including it as context in the prompt.
- **responsible_ai**: A set of principles, policies, and practices that ensure AI systems are developed and used in ways that are fair, transparent, safe, and aligned with ethical and regulatory standards.
- **model_playground**: An interactive environment, such as the Amazon Bedrock console playground, where users can experiment with foundation models by submitting prompts and observing responses without writing code.
- **use_case_prioritization**: The process of evaluating and ranking potential generative AI applications based on business value, feasibility, data readiness, and risk to determine where to invest effort.
- **knowledge_base**: A structured or unstructured collection of organizational data that can be connected to a foundation model to provide domain-specific context for more accurate and relevant responses.
- **model_inference_parameters**: Configurable settings — such as temperature, maximum token length, and top-p — that control the behavior and output characteristics of a foundation model during response generation.

## Requirements

### Requirement 1: Foundation Model Exploration and Comparison

**User Story:** As an executive learner, I want to explore and compare multiple foundation models available through Amazon Bedrock, so that I understand the range of model capabilities and can make informed decisions about which models suit different business scenarios.

#### Acceptance Criteria

1. WHEN the learner accesses the Amazon Bedrock model playground, THE learner SHALL be able to submit natural language prompts to at least two different foundation models and observe their respective outputs.
2. WHEN the learner submits the same prompt to different foundation models, THE responses SHALL vary in style, length, or content, demonstrating that model selection impacts output quality and characteristics.
3. THE learner SHALL adjust model inference parameters (such as temperature and maximum response length) and observe how changes affect the generated output for a given prompt.

### Requirement 2: Prompt Engineering for Business Scenarios

**User Story:** As an executive learner, I want to practice crafting and refining prompts for common business tasks — such as summarization, content drafting, and question answering — so that I understand how prompt design influences the quality and usefulness of AI-generated outputs.

#### Acceptance Criteria

1. WHEN the learner provides a vague or underspecified prompt, THE foundation model's response SHALL demonstrate the limitations of poorly constructed prompts (e.g., generic, off-topic, or incomplete output).
2. WHEN the learner refines the same prompt with added context, role instructions, or output format constraints, THE foundation model SHALL produce a noticeably more relevant and structured response.
3. THE learner SHALL craft prompts for at least three distinct business scenarios (such as drafting a customer communication, summarizing a strategic report, and generating product ideas), and each scenario SHALL produce output that is recognizably aligned with the intended business task.
4. IF the learner includes few-shot examples within a prompt, THEN THE foundation model SHALL generate output that more closely follows the pattern and style of the provided examples.

### Requirement 3: Responsible AI Evaluation

**User Story:** As an executive learner, I want to evaluate foundation model outputs against responsible AI criteria — including fairness, accuracy, and safety — so that I can establish practical judgment about when AI-generated content is appropriate for business use.

#### Acceptance Criteria

1. WHEN the learner submits prompts designed to probe for biased, harmful, or inaccurate outputs, THE learner SHALL document observed model behaviors and categorize them against a responsible AI evaluation checklist.
2. THE learner SHALL use Amazon Bedrock guardrails to define content filtering policies, and WHEN a prompt triggers a configured guardrail, THE system SHALL block or modify the response according to the policy.
3. IF the learner tests the same sensitive prompt with and without guardrails enabled, THEN THE responses SHALL demonstrate a measurable difference in content safety, confirming that guardrails are functioning as configured.
4. THE learner SHALL produce a brief responsible AI assessment document that identifies at least three risk categories (such as hallucination, bias, and data privacy) relevant to their chosen use case.

### Requirement 4: Use Case Identification and Prioritization

**User Story:** As an executive learner, I want to systematically identify and prioritize generative AI use cases across workforce, process, and product dimensions, so that I can practice the strategic evaluation skills needed to guide organizational AI investment.

#### Acceptance Criteria

1. THE learner SHALL define at least five candidate generative AI use cases and categorize each as targeting workforce productivity, process automation, or product/service innovation.
2. WHEN the learner evaluates each use case, THE evaluation SHALL include scoring criteria for business value, technical feasibility, data readiness, and risk level, resulting in a ranked prioritization.
3. THE learner SHALL select one top-priority use case and document a one-page business case that maps the use case to specific business objectives (such as improving customer engagement or automating content creation).

### Requirement 5: Knowledge-Augmented Prototype with Amazon Bedrock

**User Story:** As an executive learner, I want to build a simple knowledge-augmented assistant using Amazon Bedrock knowledge bases, so that I experience how connecting organizational data to a foundation model improves response relevance and accuracy.

#### Acceptance Criteria

1. WHEN the learner creates an Amazon Bedrock knowledge base and connects it to a data source containing sample business documents, THE knowledge base SHALL successfully ingest and index the provided documents.
2. WHEN the learner queries the knowledge assistant with a question answerable from the ingested documents, THE response SHALL include information derived from those documents and SHALL cite or reference the source material.
3. IF the learner asks a question outside the scope of the ingested documents, THEN THE assistant SHALL indicate that the information is not available in its knowledge base rather than generating an unsupported answer (when configured with appropriate guardrails).
4. THE learner SHALL compare responses from the same foundation model with and without the knowledge base attached, demonstrating that retrieval augmented generation produces more accurate, domain-specific answers.

### Requirement 6: Cost and Performance Awareness

**User Story:** As an executive learner, I want to monitor and understand the cost and usage patterns of foundation model interactions, so that I can make informed budgeting and scaling decisions when sponsoring generative AI initiatives.

#### Acceptance Criteria

1. WHEN the learner invokes foundation models through Amazon Bedrock, THE learner SHALL review usage metrics (such as input and output token counts) to understand the consumption model for generative AI services.
2. THE learner SHALL compare the token usage and relative pricing characteristics of at least two different foundation models for the same task, documenting how model choice impacts cost.
3. THE learner SHALL identify and document at least two strategies for managing generative AI costs at scale (such as prompt optimization to reduce token usage, or selecting smaller models for simpler tasks).

### Requirement 7: Strategic Readiness Assessment and Adoption Roadmap

**User Story:** As an executive learner, I want to produce a generative AI readiness assessment and a phased adoption roadmap for a hypothetical organization, so that I can practice translating technical experimentation into strategic planning artifacts.

#### Acceptance Criteria

1. THE learner SHALL complete a readiness assessment that evaluates a hypothetical organization across at least four dimensions: data readiness, technical skill gaps, cultural and change management readiness, and ethical/regulatory considerations.
2. THE learner SHALL produce a phased adoption roadmap with at least three stages (such as experimentation, pilot deployment, and scaled adoption), with each stage identifying key activities, AWS services involved, and success criteria.
3. WHEN the learner defines the roadmap, THE document SHALL include a responsible AI governance section that addresses model evaluation practices, content safety policies, and ongoing monitoring requirements.
4. THE roadmap SHALL reference the learner's prioritized use case from Requirement 4 and knowledge-augmented prototype from Requirement 5 as evidence informing the strategic plan.
