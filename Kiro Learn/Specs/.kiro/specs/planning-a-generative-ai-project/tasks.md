

# Implementation Plan: Planning a Generative AI Project

## Overview

This implementation plan guides learners through a structured end-to-end generative AI project planning exercise on AWS. The approach follows a logical progression: first establishing the environment and planning artifacts, then exploring and selecting foundation models, configuring responsible AI guardrails, building a knowledge base from planning documents, creating a conversational agent, evaluating output quality, and finally consolidating everything into an implementation roadmap. Each phase builds on the previous one, mirroring the real-world discipline of planning before building.

The work is organized into key milestones: environment setup and project scoping (Tasks 1-2), foundation model exploration and guardrail configuration (Tasks 3-4), knowledge base and agent creation (Tasks 5-6), evaluation and roadmap consolidation (Tasks 7-8), with checkpoints after the midpoint and at completion. The six Python components — PlanningArtifactManager, ModelExplorer, GuardrailManager, KnowledgeBaseManager, AgentManager, and EvaluationManager — are implemented incrementally so learners can validate each AWS integration before moving to the next.

Dependencies flow naturally: planning documents must be uploaded to S3 before the knowledge base can ingest them, the knowledge base must exist before the agent can be associated with it, and guardrails must be created before they can be applied to the agent and model invocations. The evaluation phase requires all prior components to be functional. IAM roles for Bedrock, S3, and OpenSearch Serverless must be created early, as multiple components depend on them.

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
    - Install boto3: `pip install boto3` and verify with `python3 -c "import boto3; print(boto3.__version__)"`
    - Create project directory structure: `mkdir -p components/` and create `__init__.py`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region, IAM Roles, and Model Access
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Enable foundation model access in Amazon Bedrock console (navigate to Model access, enable at least Anthropic Claude and Amazon Titan models)
    - Create IAM role for Bedrock with trust policy for `bedrock.amazonaws.com` and policies for S3 read/write, Bedrock full access, and OpenSearch Serverless access
    - Create IAM role for Bedrock Agent with trust policy for `bedrock.amazonaws.com` and attach `AmazonBedrockFullAccess` policy
    - Note the role ARNs for use in subsequent tasks
    - Verify model access: `aws bedrock list-foundation-models --query "modelSummaries[0].modelId"`
    - _Requirements: (all)_

- [ ] 2. Define Project Scope and Create Planning Artifacts
  - [ ] 2.1 Implement PlanningArtifactManager component
    - Create file `components/planning_artifact_manager.py`
    - Define data model classes: `ProjectScope`, `ReadinessAssessment`, `Risk`, `Milestone`, `EffortEstimation`, `ImplementationRoadmap` as Python dataclasses or dictionaries
    - Implement `create_s3_bucket(bucket_name)` using `boto3.client('s3').create_bucket()`
    - Implement `upload_artifact_to_s3(bucket_name, key, content)` using `s3.put_object()`
    - Implement `list_artifacts(bucket_name, prefix)` using `s3.list_objects_v2()`
    - Verify: create a test bucket and upload a test file, then list it
    - _Requirements: 1.1, 1.4, 7.1_
  - [ ] 2.2 Define project scope and readiness assessment
    - Implement `create_project_scope(customer_problem, target_audience, business_outcome, use_case_type, constraints, compliance_notes)` returning a `ProjectScope` structure
    - Ensure `use_case_type` is one of: `text_generation`, `summarization`, `question_answering`, `conversation`
    - Implement `create_readiness_assessment(data_availability, required_skills, estimated_effort, recommendation)` returning a `ReadinessAssessment` structure
    - Create a concrete project scope for a realistic scenario (e.g., an internal Q&A assistant for company policies) with at least one constraint and compliance note if applicable
    - Create a readiness assessment addressing data availability, skills, effort, and go/no-go recommendation
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [ ] 2.3 Upload planning documents to S3
    - Create an S3 bucket (e.g., `genai-planning-<account-id>`) using `create_s3_bucket()`
    - Serialize the project scope and readiness assessment as structured text/JSON documents
    - Upload documents to S3 using `upload_artifact_to_s3()` with keys like `planning-docs/project-scope.json` and `planning-docs/readiness-assessment.json`
    - Create and upload additional context documents (governance policy outline, use case description) for knowledge base ingestion
    - Verify uploads: `aws s3 ls s3://<bucket-name>/planning-docs/`
    - _Requirements: 1.1, 1.4, 4.1_

- [ ] 3. Foundation Model Selection Using Amazon Bedrock
  - [ ] 3.1 Implement ModelExplorer component
    - Create file `components/model_explorer.py`
    - Define data models: `ModelSummary`, `ModelDetails`, `ModelResponse`
    - Implement `list_foundation_models(provider, output_modality)` using `boto3.client('bedrock').list_foundation_models()` with optional `byProvider` and `byOutputModality` filters
    - Implement `get_model_details(model_id)` using `bedrock.get_foundation_model(modelIdentifier=model_id)` to retrieve capabilities (input/output modalities, customization support, inference types, and model lifecycle status); note that regional availability is not returned by this API and must be checked separately via the AWS documentation or console
    - Verify: list all available models and print their IDs, providers, and modalities
    - _Requirements: 2.1, 2.4_
  - [ ] 3.2 Invoke and compare foundation models
    - Implement `invoke_model(model_id, prompt, max_tokens)` using `boto3.client('bedrock-runtime').invoke_model()` with appropriate request body formatting per model provider; measure and return latency
    - Implement `compare_models(model_ids, prompt, max_tokens)` that calls `invoke_model` for each model and returns a list of `ModelResponse` objects
    - Select at least two foundation models (e.g., `anthropic.claude-3-haiku-20240307-v1:0` and `amazon.titan-text-express-v1`)
    - Invoke both models with the same prompt related to your project scope use case
    - Compare outputs for quality, style, and relevance; document the comparison as a model selection rationale
    - If a model is unavailable in the region, document it as a constraint
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Establish Responsible AI Guardrails
  - [ ] 4.1 Implement GuardrailManager component
    - Create file `components/guardrail_manager.py`
    - Define data models: `ContentFilter`, `DeniedTopic`, `GuardrailResponse`, `GuardrailDetails`, `GuardedModelResponse`
    - Implement `create_guardrail(name, description, content_filters, denied_topics, blocked_message)` using `boto3.client('bedrock').create_guardrail()` with `contentPolicyConfig` for content filters and `topicPolicyConfig` for denied topics
    - Implement `get_guardrail(guardrail_id)` using `bedrock.get_guardrail()`
    - Implement `delete_guardrail(guardrail_id)` using `bedrock.delete_guardrail()`
    - _Requirements: 3.1, 3.2_
  - [ ] 4.2 Configure and test guardrails with model invocations
    - Create a guardrail with at least one content filter (e.g., `HATE` with `input_strength: HIGH`, `output_strength: HIGH`) and at least one denied topic relevant to your project scope
    - Set a custom `blocked_message` for when guardrails intervene
    - Implement `invoke_model_with_guardrail(model_id, guardrail_id, guardrail_version, prompt)` using `bedrock-runtime.invoke_model()` with `guardrailIdentifier` and `guardrailVersion` parameters, or using the Converse API with guardrail config
    - Test with a prompt that should pass the guardrail and verify normal response
    - Test with a prompt that should trigger a denied topic or content filter; verify the blocked message is returned and `guardrail_action` is `INTERVENED`
    - Inspect trace information to confirm which guardrail rule was activated
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 5. Checkpoint - Validate Scope, Model Selection, and Guardrails
  - Verify the S3 bucket contains all planning documents: `aws s3 ls s3://<bucket-name>/planning-docs/`
  - Verify at least two models were compared and a selection rationale is documented
  - Verify the guardrail exists: `aws bedrock get-guardrail --guardrail-identifier <guardrail-id>`
  - Test a guardrail-filtered invocation and confirm the trace shows intervention on a violating prompt
  - Confirm the project scope includes customer problem, target audience, business outcome, use case type, constraints, and compliance notes (if applicable)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Build Knowledge Base and Conversational Agent
  - [ ] 6.1 Implement KnowledgeBaseManager component
    - Create file `components/knowledge_base_manager.py`
    - Define data models: `KnowledgeBaseResponse`, `DataSourceResponse`, `KnowledgeBaseQueryResult`, `Citation`
    - Implement `create_knowledge_base(name, description, embedding_model_arn, role_arn, storage_config)` using `boto3.client('bedrock-agent').create_knowledge_base()` with an OpenSearch Serverless vector store configuration (Bedrock manages the collection creation)
    - Implement `add_s3_data_source(knowledge_base_id, bucket_arn, data_source_name)` using `bedrock_agent.create_data_source()` with S3 configuration pointing to the planning documents prefix
    - Implement `sync_data_source(knowledge_base_id, data_source_id)` using `bedrock_agent.start_ingestion_job()` and poll for completion
    - Implement `query_knowledge_base(knowledge_base_id, query_text, model_arn)` using `boto3.client('bedrock-agent-runtime').retrieve_and_generate()` to get grounded responses with source citations
    - Implement `delete_knowledge_base(knowledge_base_id)` using `bedrock_agent.delete_knowledge_base()`
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 6.2 Create knowledge base and test grounded responses
    - Create the knowledge base using an embedding model (e.g., `amazon.titan-embed-text-v2:0`)
    - Add the S3 data source pointing to the planning documents bucket/prefix
    - Sync the data source and wait for ingestion to complete
    - Query the knowledge base with a question about the project scope (e.g., "What is the target audience for this project?") and verify the response includes source citations
    - Query with an unrelated topic and verify the response indicates insufficient information rather than fabricating an answer
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 6.3 Implement AgentManager component and create agent
    - Create file `components/agent_manager.py`
    - Define data models: `AgentResponse`, `AgentAliasResponse`, `AgentInvokeResponse`
    - Implement `create_agent(name, foundation_model_id, instruction, role_arn, guardrail_id, guardrail_version)` using `boto3.client('bedrock-agent').create_agent()` with a planning-assistant persona instruction
    - Implement `associate_knowledge_base(agent_id, knowledge_base_id, description)` using `bedrock_agent.associate_agent_knowledge_base()`
    - Implement `prepare_agent(agent_id)` using `bedrock_agent.prepare_agent()` and wait for status `PREPARED`
    - Implement `create_agent_alias(agent_id, alias_name)` using `bedrock_agent.create_agent_alias()`
    - Implement `invoke_agent(agent_id, agent_alias_id, session_id, input_text)` using `boto3.client('bedrock-agent-runtime').invoke_agent()` to stream and collect the response
    - Implement `delete_agent(agent_id)` using `bedrock_agent.delete_agent()`
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 6.4 Configure and test conversational agent
    - Create an agent with the selected foundation model, a planning-assistant instruction (e.g., "You are a generative AI project planning assistant. Answer questions about the project scope, governance, and implementation plan using the associated knowledge base."), the guardrail ID, and the agent IAM role ARN
    - Associate the knowledge base with the agent
    - Prepare the agent and create an alias for testing
    - Test the agent with a question about the project scope and verify it retrieves relevant information from the knowledge base
    - Test conversational context by asking a follow-up question referencing the prior exchange (e.g., first ask about the project scope, then ask "What are the constraints?" without restating context)
    - Verify the agent is available in the test console or via `invoke_agent` for validation
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 7. Evaluate Model Output Quality
  - [ ] 7.1 Implement EvaluationManager component
    - Create file `components/evaluation_manager.py`
    - Define data models: `TestCase`, `EvaluationJobResponse`, `EvaluationResults`, `QualityReport`
    - Implement `upload_test_dataset(bucket_name, key, test_cases)` that formats test cases as JSON Lines and uploads to S3
    - Implement `create_evaluation_job(job_name, model_id, dataset_s3_uri, output_s3_uri, evaluation_metrics, role_arn)` using `boto3.client('bedrock').create_model_evaluation_job()` with automatic evaluation task type and metrics (e.g., `Builtin.Accuracy`, `Builtin.Robustness`, `Builtin.Toxicity`); note that `Builtin.Relevance` and `Builtin.Coherence` are only available for LLM-as-judge evaluation jobs, not standard automatic evaluation jobs
    - Implement `get_evaluation_status(job_name)` using `bedrock.get_model_evaluation_job()`
    - Implement `get_evaluation_results(output_s3_uri)` that downloads and parses results from S3
    - Implement `generate_quality_report(results, quality_thresholds)` that compares scores against thresholds, identifies gaps, and recommends mitigations
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - [ ] 7.2 Run evaluation and document quality findings
    - Create a test dataset of at least 5 representative prompts with expected reference responses aligned to the project scope use case
    - Upload the test dataset to S3 in JSON Lines format
    - Create an evaluation job assessing at least two quality dimensions (e.g., accuracy and toxicity); for standard automatic evaluation jobs, valid built-in metrics are `Builtin.Accuracy`, `Builtin.Robustness`, and `Builtin.Toxicity` — relevance and coherence metrics require an LLM-as-judge configuration
    - Poll for job completion using `get_evaluation_status()`
    - Retrieve results and generate a quality report with overall scores, identified gaps, and recommended mitigations (prompt refinement, guardrail adjustments, or knowledge base expansion)
    - Document findings for inclusion in the implementation roadmap
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 8. Checkpoint - Validate End-to-End Integration
  - Query the knowledge base and verify grounded responses with citations
  - Invoke the agent and verify it retrieves knowledge base content through natural conversation
  - Verify the agent maintains session context across follow-up questions
  - Confirm the evaluation job completed and quality scores are available
  - Verify all six components are functional: PlanningArtifactManager, ModelExplorer, GuardrailManager, KnowledgeBaseManager, AgentManager, EvaluationManager
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Produce Implementation Roadmap and Project Artifact
  - [ ] 9.1 Consolidate planning decisions into the roadmap
    - Use `PlanningArtifactManager.create_implementation_roadmap()` to compile: project scope, model selection rationale, guardrail configuration decisions, knowledge base design, agent architecture, and evaluation results into a single structured document
    - Define at least three milestones with deliverables: (1) Proof-of-Concept — scope definition, model selection, initial guardrails; (2) Pilot — knowledge base with real data, agent integration, stakeholder testing; (3) Production Readiness — full evaluation, refined guardrails, operational runbook
    - Document all risks identified during planning (model availability, data quality gaps, compliance concerns, regional constraints) with likelihood, impact, and mitigation strategies
    - Include an effort estimation section addressing resource requirements, skill gaps requiring enablement, and AWS service budget considerations (Bedrock model invocation costs, S3 storage, OpenSearch Serverless)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ] 9.2 Upload and verify final roadmap artifact
    - Serialize the implementation roadmap as a structured JSON and human-readable Markdown document
    - Upload both formats to S3 using `upload_artifact_to_s3()`
    - Verify the complete set of artifacts in S3: `aws s3 ls s3://<bucket-name>/planning-docs/ --recursive`
    - Optionally re-sync the knowledge base to include the roadmap document, then query the agent about the implementation plan to validate end-to-end integration
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete Bedrock Agent resources
    - Delete agent alias: `aws bedrock-agent delete-agent-alias --agent-id <agent-id> --agent-alias-id <alias-id>`
    - Delete agent: `aws bedrock-agent delete-agent --agent-id <agent-id>`
    - Verify deletion: `aws bedrock-agent list-agents`
    - _Requirements: (all)_
  - [ ] 10.2 Delete Knowledge Base and data sources
    - Delete data source: `aws bedrock-agent delete-data-source --knowledge-base-id <kb-id> --data-source-id <ds-id>`
    - Delete knowledge base: `aws bedrock-agent delete-knowledge-base --knowledge-base-id <kb-id>`
    - Note: The OpenSearch Serverless collection managed by Bedrock may be deleted automatically; verify in the OpenSearch Serverless console and delete manually if needed
    - _Requirements: (all)_
  - [ ] 10.3 Delete Guardrails and S3 resources
    - Delete guardrail: `aws bedrock delete-guardrail --guardrail-identifier <guardrail-id>`
    - Empty and delete S3 bucket: `aws s3 rm s3://<bucket-name> --recursive` then `aws s3 rb s3://<bucket-name>`
    - _Requirements: (all)_
  - [ ] 10.4 Delete IAM roles and verify cleanup
    - Detach policies and delete the Bedrock IAM role: `aws iam detach-role-policy --role-name <role-name> --policy-arn <policy-arn>` then `aws iam delete-role --role-name <role-name>`
    - Repeat for the Bedrock Agent IAM role
    - Verify no lingering resources: check Bedrock console for agents, knowledge bases, and guardrails; check S3 console for buckets; check IAM for roles
    - Warning: OpenSearch Serverless collections incur costs if not deleted — verify removal in the OpenSearch Serverless console
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability (format: `_Requirements: X.Y_` where X is the requirement number and Y is the acceptance criteria number)
- Checkpoints (Tasks 5 and 8) ensure incremental validation at key milestones
- Foundation model access must be enabled in the Bedrock console before programmatic invocation (Task 1.3)
- Some Bedrock features (Evaluations, certain models) may have regional availability constraints — document any limitations as project constraints
- The OpenSearch Serverless collection created by Bedrock Knowledge Bases may take several minutes to provision; plan accordingly during Task 6
- Evaluation jobs (Task 7) may take 10-30 minutes to complete depending on dataset size and model selection
