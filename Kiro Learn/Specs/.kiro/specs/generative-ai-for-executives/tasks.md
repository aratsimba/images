

# Implementation Plan: Generative AI for Executives

## Overview

This implementation plan guides executive learners through a hands-on exploration of generative AI using Amazon Bedrock. The approach progresses from foundational model exploration and prompt engineering, through responsible AI evaluation and knowledge-augmented prototyping, to strategic planning artifact creation. Each phase builds on the previous one, ensuring learners develop both practical intuition and strategic thinking about generative AI adoption.

The plan is organized into three major phases. Phase 1 (Tasks 2-4) covers core technical exploration: setting up the project structure and data models, building the ModelExplorer and PromptWorkshop components to interact with foundation models, and comparing outputs across models and parameter configurations. Phase 2 (Tasks 5-7) addresses responsible AI evaluation and knowledge-augmented generation: creating Bedrock guardrails, building the KnowledgeAssistant with S3-backed documents, and demonstrating RAG value. Phase 3 (Tasks 8-10) focuses on strategic outputs: use case prioritization, adoption roadmap generation, and producing final deliverables using the StrategyReporter component.

Key dependencies flow naturally through the plan. The ModelExplorer must be built first since PromptWorkshop and other components reuse its model invocation patterns. The ResponsibleAIEvaluator and KnowledgeAssistant can be developed in sequence after prompt engineering is understood. The StrategyReporter depends on insights gathered from all prior exercises. Checkpoints after each phase validate that learners have functioning components and meaningful outputs before proceeding.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with Amazon Bedrock access
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Create project directory structure: `mkdir -p components sample_documents outputs`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Bedrock Model Access
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Enable model access in the Amazon Bedrock console for Anthropic Claude and Amazon Titan models
    - Verify model access: `aws bedrock list-foundation-models --query "modelSummaries[?providerName=='Anthropic'].modelId"`
    - Create an S3 bucket for sample documents: `aws s3 mb s3://<your-bucket-name> --region us-east-1`
    - Ensure IAM permissions include `bedrock:*`, `s3:*`, and `iam:PassRole` for Bedrock Knowledge Base role creation
    - _Requirements: (all)_

- [ ] 2. Project Foundation - Data Models and Shared Utilities
  - [ ] 2.1 Define all data model types
    - Create `components/__init__.py` and `components/data_models.py`
    - Implement dataclasses for `InferenceParameters` (temperature, max_tokens, top_p), `ModelResponse` (model_id, prompt, response_text, input_tokens, output_tokens, parameters, latency_ms), and `BusinessScenario` (name, description, vague_prompt, refined_prompt, few_shot_examples)
    - Implement `ScenarioResult`, `GuardrailConfig`, `GuardrailComparison`, `KBResponse`, `KBComparison`
    - Implement `UseCase` (name, description, category, business_value, feasibility, data_readiness, risk_level), `ScoredUseCase`, `ReadinessInput`, and `RoadmapInput`
    - Verify by importing all types in a Python REPL: `from components.data_models import *`
    - _Requirements: 1.1, 1.3, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1_
  - [ ] 2.2 Prepare sample business documents
    - Create 3-5 sample Markdown/text documents in `sample_documents/` covering a fictional company's strategy, product catalog, and HR policies
    - These documents will serve as the knowledge base source for the KnowledgeAssistant (Requirement 5)
    - Upload documents to S3: `aws s3 sync sample_documents/ s3://<your-bucket-name>/documents/`
    - Verify upload: `aws s3 ls s3://<your-bucket-name>/documents/`
    - _Requirements: 5.1_

- [ ] 3. ModelExplorer - Foundation Model Invocation and Comparison
  - [ ] 3.1 Implement ModelExplorer component
    - Create `components/model_explorer.py` with `boto3.client('bedrock-runtime')` and `boto3.client('bedrock')`
    - Implement `list_available_models()` to query available Bedrock foundation models and return model IDs with provider info
    - Implement `invoke_model(model_id, prompt, parameters)` that sends a prompt to a specified model using `invoke_model` API, parses the response, tracks input/output token counts and latency, and returns a `ModelResponse`
    - Implement `compare_models(model_ids, prompt, parameters)` that invokes the same prompt across at least two models (e.g., Claude and Titan) and returns a list of `ModelResponse` objects
    - Implement `compare_parameters(model_id, prompt, parameter_variants)` that invokes the same model with different `InferenceParameters` (e.g., temperature 0.1 vs 0.9, max_tokens 100 vs 500) and returns results for comparison
    - _Requirements: 1.1, 1.2, 1.3, 6.1_
  - [ ] 3.2 Run model exploration exercises
    - Create `scripts/explore_models.py` as a CLI entry point
    - List available models and print their IDs and provider names
    - Submit a business prompt (e.g., "Summarize the benefits of cloud computing for a Fortune 500 CEO") to two different models and print side-by-side outputs demonstrating style/length differences
    - Adjust temperature (0.1 vs 0.9) and max_tokens (100 vs 500) for the same prompt and model, observing output variation
    - Print token usage (input_tokens, output_tokens) for each invocation to build cost awareness
    - Compare token usage and note pricing differences between models
    - Verify: outputs show distinct responses from different models and parameter settings
    - _Requirements: 1.1, 1.2, 1.3, 6.1, 6.2, 6.3_

- [ ] 4. PromptWorkshop - Prompt Engineering for Business Scenarios
  - [ ] 4.1 Implement PromptWorkshop component
    - Create `components/prompt_workshop.py` using `boto3.client('bedrock-runtime')`
    - Implement `run_scenario(model_id, scenario)` that submits both the vague and refined prompts from a `BusinessScenario`, returns a `ScenarioResult` with both responses
    - Implement `compare_prompt_versions(model_id, prompt_versions, scenario_name)` for iterative prompt refinement comparison
    - Implement `run_few_shot_exercise(model_id, examples, test_prompt)` that constructs a prompt with few-shot examples prepended and returns a `ModelResponse`
    - Implement `generate_workshop_summary(results)` that produces a Markdown summary of all scenario results highlighting prompt engineering lessons
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - [ ] 4.2 Run prompt engineering exercises across business scenarios
    - Create `scripts/run_prompt_workshop.py` as a CLI entry point
    - Define at least three `BusinessScenario` objects: (1) drafting a customer communication, (2) summarizing a strategic report, (3) generating product ideas
    - For each scenario, run with vague prompt first, then refined prompt with context, role instructions, and output format constraints
    - Run few-shot exercise for at least one scenario with 2-3 examples demonstrating desired output pattern
    - Generate and save workshop summary to `outputs/prompt_workshop_summary.md`
    - Verify: refined prompts produce noticeably more relevant and structured responses; few-shot outputs follow example patterns
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 5. Checkpoint - Validate Model Exploration and Prompt Engineering
  - Run `scripts/explore_models.py` and confirm outputs from at least two models with visible style/content differences
  - Confirm parameter variation produces measurably different outputs (e.g., temperature effects on creativity)
  - Run `scripts/run_prompt_workshop.py` and confirm three business scenarios produce task-aligned outputs
  - Verify `outputs/prompt_workshop_summary.md` exists and contains comparative analysis
  - Confirm token usage is tracked and printed for cost awareness
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. ResponsibleAIEvaluator - Guardrails and Safety Assessment
  - [ ] 6.1 Implement ResponsibleAIEvaluator component
    - Create `components/responsible_ai_evaluator.py` using `boto3.client('bedrock-runtime')` and `boto3.client('bedrock')`
    - Implement `create_guardrail(config)` that creates a Bedrock guardrail with content filters and denied topics from `GuardrailConfig`, returns guardrail_id
    - Implement `invoke_with_guardrail(model_id, prompt, guardrail_id, guardrail_version)` and `invoke_without_guardrail(model_id, prompt)` for side-by-side comparison
    - Implement `compare_guardrail_impact(model_id, prompts, guardrail_id, guardrail_version)` that runs a list of sensitive prompts with and without guardrails, returns `List[GuardrailComparison]` with `guardrail_triggered` flag
    - Implement `generate_responsible_ai_assessment(comparisons, use_case_name)` that produces a Markdown assessment document identifying at least three risk categories (hallucination, bias, data privacy)
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ] 6.2 Run responsible AI evaluation exercises
    - Create `scripts/run_responsible_ai.py` as a CLI entry point
    - Create a guardrail with content filtering policies (e.g., block harmful content, deny topics like financial advice or medical diagnosis)
    - Submit prompts designed to probe for biased, harmful, or inaccurate outputs — document model behaviors
    - Test the same sensitive prompts with and without guardrails, printing comparison results showing measurable safety differences
    - Generate and save responsible AI assessment to `outputs/responsible_ai_assessment.md` covering hallucination, bias, and data privacy risks
    - Verify: guardrail-enabled responses are blocked or modified when policies are triggered; assessment document contains three+ risk categories
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 7. KnowledgeAssistant - RAG Prototype with Bedrock Knowledge Bases
  - [ ] 7.1 Implement KnowledgeAssistant component
    - Create `components/knowledge_assistant.py` using `boto3.client('bedrock-agent')`, `boto3.client('bedrock-agent-runtime')`, and `boto3.client('s3')`
    - Implement `upload_documents(bucket_name, documents_path)` to upload local documents to S3 and return list of uploaded keys
    - Implement `create_knowledge_base(name, bucket_name, embedding_model_id)` that creates a Bedrock knowledge base with S3 data source, creates the necessary IAM role for Bedrock KB access to S3, and returns knowledge_base_id
    - Implement `start_ingestion(knowledge_base_id, data_source_id)` that triggers document ingestion and waits for completion
    - Implement `query_knowledge_base(knowledge_base_id, model_id, query)` using `retrieve_and_generate` API, returning `KBResponse` with citations
    - Implement `query_model_directly(model_id, query)` for baseline comparison without KB
    - Implement `compare_with_without_kb(knowledge_base_id, model_id, queries)` that runs queries both ways and returns `List[KBComparison]`
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 7.2 Build and test the knowledge-augmented assistant
    - Create `scripts/run_knowledge_assistant.py` as a CLI entry point
    - Upload sample documents to S3 (if not already done), create knowledge base, and start ingestion
    - Query the assistant with questions answerable from ingested documents — verify responses include source citations
    - Query with out-of-scope questions — verify the assistant indicates information is not available (configure guardrails if needed)
    - Run comparison queries with and without KB, printing side-by-side results showing RAG produces more accurate domain-specific answers
    - Save comparison results to `outputs/kb_comparison.md`
    - Verify: KB responses cite source documents; direct model responses lack domain-specific accuracy
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 8. Checkpoint - Validate Responsible AI and Knowledge Assistant
  - Run `scripts/run_responsible_ai.py` and confirm guardrails block or modify unsafe content
  - Verify `outputs/responsible_ai_assessment.md` covers hallucination, bias, and data privacy
  - Run `scripts/run_knowledge_assistant.py` and confirm KB queries return cited, domain-specific answers
  - Verify RAG comparison clearly demonstrates improvement over direct model queries
  - Confirm out-of-scope queries are handled appropriately
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. StrategyReporter - Use Case Prioritization and Adoption Roadmap
  - [ ] 9.1 Implement StrategyReporter component
    - Create `components/strategy_reporter.py` using `boto3.client('bedrock-runtime')`
    - Implement `score_use_cases(use_cases)` that calculates a weighted priority score from business_value, feasibility, data_readiness, and risk_level, returns ranked `List[ScoredUseCase]`
    - Implement `generate_business_case(use_case, model_id)` that uses a foundation model to draft a one-page business case mapping the use case to business objectives
    - Implement `generate_readiness_assessment(assessment_input, model_id)` that produces a Markdown assessment evaluating data readiness, skill gaps, change management, and ethical/regulatory dimensions
    - Implement `generate_adoption_roadmap(roadmap_input, model_id)` that produces a phased roadmap (experimentation, pilot, scaled adoption) with key activities, AWS services, success criteria, and a responsible AI governance section
    - Implement `save_report(content, filename)` to write generated content to `outputs/` directory
    - _Requirements: 4.1, 4.2, 4.3, 7.1, 7.2, 7.3, 7.4_
  - [ ] 9.2 Generate strategic planning artifacts
    - Create `scripts/run_strategy.py` as a CLI entry point
    - Define at least five candidate use cases across workforce, process, and product categories as `UseCase` objects
    - Score and rank all use cases, printing the prioritization matrix
    - Select the top-priority use case and generate a one-page business case, saving to `outputs/business_case.md`
    - Generate readiness assessment for a hypothetical organization across all four dimensions, saving to `outputs/readiness_assessment.md`
    - Generate phased adoption roadmap referencing the prioritized use case and KB prototype experience, including responsible AI governance section, saving to `outputs/adoption_roadmap.md`
    - Verify: all five use cases scored and ranked; business case maps to specific objectives; roadmap has three stages with responsible AI governance; roadmap references prototype findings
    - _Requirements: 4.1, 4.2, 4.3, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4_

- [ ] 10. Checkpoint - Final Validation of All Deliverables
  - Verify all output files exist in `outputs/`: `prompt_workshop_summary.md`, `responsible_ai_assessment.md`, `kb_comparison.md`, `business_case.md`, `readiness_assessment.md`, `adoption_roadmap.md`
  - Confirm the adoption roadmap references the prioritized use case and knowledge-augmented prototype as evidence
  - Confirm the roadmap includes a responsible AI governance section addressing model evaluation, content safety policies, and monitoring
  - Confirm readiness assessment covers all four dimensions: data readiness, skill gaps, change management, ethical/regulatory
  - Review cost awareness: verify token usage was documented and at least two cost management strategies identified in outputs
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Delete Bedrock Knowledge Base and associated resources
    - Delete the Bedrock data source: `aws bedrock-agent delete-data-source --knowledge-base-id <kb-id> --data-source-id <ds-id>`
    - Delete the Bedrock knowledge base: `aws bedrock-agent delete-knowledge-base --knowledge-base-id <kb-id>`
    - Delete the IAM role created for KB: `aws iam detach-role-policy --role-name <kb-role-name> --policy-arn <policy-arn>` then `aws iam delete-role --role-name <kb-role-name>`
    - _Requirements: (all)_
  - [ ] 11.2 Delete Bedrock Guardrails
    - List guardrails: `aws bedrock list-guardrails`
    - Delete created guardrail: `aws bedrock delete-guardrail --guardrail-identifier <guardrail-id>`
    - _Requirements: (all)_
  - [ ] 11.3 Delete S3 bucket and verify cleanup
    - Empty and delete S3 bucket: `aws s3 rb s3://<your-bucket-name> --force`
    - Verify no Bedrock resources remain: `aws bedrock-agent list-knowledge-bases` and `aws bedrock list-guardrails`
    - Verify S3 bucket deleted: `aws s3 ls s3://<your-bucket-name>` should return error
    - Check AWS Cost Explorer for any remaining Bedrock charges
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The Amazon Bedrock console playground can supplement scripted exercises in Tasks 3 and 4 for initial model exploration (Requirement 1.1)
- Cost awareness (Requirement 6) is integrated throughout Tasks 3 and 9 rather than isolated as a separate component, since the StrategyReporter and ModelExplorer together cover token tracking, model cost comparison, and cost strategy documentation
- All Bedrock model invocations may incur costs — monitor usage during exercises and clean up promptly after completing the project
