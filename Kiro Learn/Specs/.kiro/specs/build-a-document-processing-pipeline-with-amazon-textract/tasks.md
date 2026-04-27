

# Implementation Plan: Document Processing Pipeline with Amazon Textract

## Overview

This implementation plan guides you through building a serverless document processing pipeline using Amazon Textract, S3, Lambda, SNS, SQS, and DynamoDB. The pipeline follows an event-driven architecture where documents uploaded to S3 trigger automated text extraction and structured data analysis, with results stored in both S3 and DynamoDB for downstream querying. The plan is organized into phases: environment setup, infrastructure provisioning, core Lambda function development, integration wiring, monitoring, and cleanup.

The first phase establishes prerequisites and provisions all AWS infrastructure — the S3 bucket with folder structure, SNS topics, SQS queues with dead-letter queue configuration, the DynamoDB table, and IAM roles. The second phase implements the core processing logic: the TextractParser for transforming raw Textract output, the DataStore for persistence, the DocumentProcessor Lambda for handling S3 events and synchronous Textract calls, and the ResultsProcessor Lambda for handling asynchronous job completions. The third phase wires everything together with event notifications, adds CloudWatch monitoring, and validates the end-to-end flow.

Key dependencies dictate task ordering: infrastructure must exist before Lambda functions can be deployed; the TextractParser and DataStore modules must be built before the Lambda handlers that depend on them; and SNS/SQS must be configured before asynchronous processing can work. Checkpoints are placed after infrastructure provisioning and after core processing logic to ensure incremental validation before advancing.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for S3, Lambda, Textract, SNS, SQS, DynamoDB, CloudWatch, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Create project directory structure: `mkdir -p components/ tests/`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Verify Amazon Textract is available in chosen region
    - Note your account's Textract API quotas via the Service Quotas console
    - Prepare sample test documents: one single-page JPEG/PNG with text, one single-page document with a form/table, one multi-page PDF (2+ pages)
    - _Requirements: (all)_

- [ ] 2. Provision AWS Infrastructure
  - [ ] 2.1 Create S3 Bucket and Folder Structure
    - Create `components/infrastructure_setup.py` with `create_s3_bucket(bucket_name)` function
    - Create bucket: `aws s3api create-bucket --bucket doc-processing-pipeline-<account-id> --region us-east-1`
    - Create folder prefixes by uploading empty markers: `incoming/`, `results/text-detection/`, `results/document-analysis/`, `errors/`
    - Verify: `aws s3 ls s3://doc-processing-pipeline-<account-id>/`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Create SNS Topics, SQS Queues, and Dead-Letter Queue
    - Implement `create_sns_topic(topic_name)` for two topics: `AmazonTextract-job-notifications` and `doc-processing-error-alerts`
    - **Important**: The SNS topic used for Textract async job notifications **must have its name prepended with `AmazonTextract`** (e.g., `AmazonTextract-job-notifications`). This is required by AWS for the Textract IAM service role to be able to publish to the topic.
    - Implement `create_sqs_queue(queue_name, dead_letter_queue_arn, max_receive_count)` — first create the DLQ (`doc-processing-dlq`) with no redrive policy, then create main queue (`textract-results-queue`) with redrive policy pointing to DLQ (maxReceiveCount: 3)
    - Implement `subscribe_sqs_to_sns(topic_arn, queue_arn)` — subscribe the SQS queue to the Textract notifications SNS topic (`AmazonTextract-job-notifications`); set SQS queue policy allowing SNS to send messages
    - Implement `subscribe_email_to_sns(topic_arn, email)` — subscribe your email to the error alerts SNS topic; confirm the subscription via email
    - Configure SNS topic access policy on `AmazonTextract-job-notifications` to allow Textract service (`textract.amazonaws.com`) to publish
    - Verify: `aws sns list-topics`, `aws sqs list-queues`
    - _Requirements: 4.4, 6.1, 6.2, 6.3_
  - [ ] 2.3 Create DynamoDB Table and IAM Roles
    - Implement `create_dynamodb_table(table_name, partition_key, sort_key)` — create table `DocumentResults` with partition key `document_id` (String) and sort key `sort_key` (String), on-demand billing mode
    - Create IAM role `doc-processor-lambda-role` with policies for: S3 read/write, Textract full access, DynamoDB read/write, SQS send/receive/delete, SNS publish, CloudWatch Logs and PutMetricData
    - Create IAM role `textract-sns-role` that grants Textract permission to publish to the SNS topic (trust policy for `textract.amazonaws.com`)
    - Verify DynamoDB: `aws dynamodb describe-table --table-name DocumentResults`
    - Verify roles: `aws iam get-role --role-name doc-processor-lambda-role`
    - _Requirements: 5.2, 5.4_

- [ ] 3. Checkpoint - Validate Infrastructure
  - Confirm S3 bucket exists with all four prefixes (`incoming/`, `results/text-detection/`, `results/document-analysis/`, `errors/`)
  - Confirm both SNS topics exist and subscriptions are active
  - Confirm SQS queues exist with correct redrive policy (main queue → DLQ)
  - Confirm DynamoDB table is ACTIVE with correct key schema and on-demand mode
  - Confirm both IAM roles exist with required policies attached
  - Upload a test file to `s3://bucket/incoming/` and verify it lands: `aws s3 cp test.jpg s3://doc-processing-pipeline-<account-id>/incoming/`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Implement TextractParser and DataStore Modules
  - [ ] 4.1 Build TextractParser Module
    - Create `components/textract_parser.py` implementing all five interface functions
    - `extract_text_lines(blocks)`: filter blocks by `BlockType == "LINE"`, return list of `{text, confidence}` dicts
    - `extract_key_value_pairs(blocks)`: find `KEY_VALUE_SET` blocks, resolve `Relationships` to map keys to values, return list of `{key, value, confidence}` dicts
    - `extract_tables(blocks)`: find `TABLE` blocks, resolve `CELL` children using relationships, build 2D array of cell contents with `table_index`, `row_count`, `column_count`
    - `build_document_record(document_id, s3_location, analysis_type, extracted_data)`: construct a `DocumentRecord` dict with `processing_timestamp` (ISO 8601), `block_count`, and content fields
    - `count_blocks_by_type(blocks)`: return dict counting blocks by `BlockType` (PAGE, LINE, WORD, TABLE, CELL, KEY_VALUE_SET, etc.)
    - Test locally with a sample Textract JSON response to verify parsing logic
    - _Requirements: 2.1, 3.1, 3.2, 5.1_
  - [ ] 4.2 Build DataStore Module
    - Create `components/data_store.py` implementing all four interface functions
    - `save_results_to_s3(bucket, prefix, document_id, analysis_type, results)`: serialize results to JSON, write to `results/text-detection/` or `results/document-analysis/` based on `analysis_type`, return the S3 key
    - `store_document_record(table_name, record)`: write record to DynamoDB using `put_item`, handle `document_id` as partition key and `sort_key` as sort key
    - `get_document_record(table_name, document_id, sort_key)`: retrieve single record using `get_item`
    - `query_by_document(table_name, document_id)`: query all records for a given `document_id` using `query` with `KeyConditionExpression`
    - Test locally: write and read back a sample record from DynamoDB
    - Verify S3 output: `aws s3 ls s3://doc-processing-pipeline-<account-id>/results/`
    - _Requirements: 2.2, 3.3, 5.1, 5.2, 5.3_
  - [ ]* 4.3 Property Test for TextractParser
    - **Property 1: Block Parsing Completeness**
    - **Validates: Requirements 2.1, 3.1, 3.2**

- [ ] 5. Implement DocumentProcessor Lambda
  - [ ] 5.1 Build Document Validation and Routing Logic
    - Create `components/document_processor.py` with the `handler(event, context)` function
    - Implement `validate_document(bucket, key)`: extract file extension, check against `SUPPORTED_FORMATS` list, determine `is_multi_page` by checking if format is PDF/TIFF (use S3 head_object for content type confirmation), return `DocumentMetadata` dict
    - Implement `move_to_error_prefix(bucket, key, reason)`: copy object to `errors/` prefix with reason in metadata, delete original from `incoming/`
    - In `handler`: parse S3 event to get bucket/key, validate document, if unsupported format log and call `move_to_error_prefix`, otherwise route to sync or async processing
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [ ] 5.2 Implement Synchronous Textract Processing
    - Implement `detect_text_sync(bucket, key)`: call `textract.detect_document_text()` with S3Object, return raw response blocks
    - Implement `analyze_document_sync(bucket, key, feature_types)`: call `textract.analyze_document()` with S3Object and `FeatureTypes=['FORMS', 'TABLES']`, return raw response blocks
    - After sync calls: use TextractParser to extract text lines, key-value pairs, and tables; use DataStore to save JSON results to S3 and structured records to DynamoDB
    - Log number of detected blocks and source document reference using `print()` or `logging`
    - Implement `publish_metrics(metric_name, value)`: use CloudWatch `put_metric_data` to publish `DocumentsProcessed` and `DocumentsFailed` custom metrics under namespace `DocProcessingPipeline`
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 5.1, 5.3_
  - [ ] 5.3 Implement Asynchronous Job Submission
    - Implement `start_async_text_detection(bucket, key, sns_topic_arn, role_arn)`: call `textract.start_document_text_detection()` with S3Object, NotificationChannel (SNSTopicArn, RoleArn), return `JobId`
    - Implement `start_async_document_analysis(bucket, key, feature_types, sns_topic_arn, role_arn)`: call `textract.start_document_analysis()` with S3Object, FeatureTypes, NotificationChannel, return `JobId`
    - In `handler`: for multi-page documents, call async APIs, log the `JobId`, and store job metadata (as `TextractJobInfo`) to DynamoDB with sort_key `META`
    - _Requirements: 4.1, 4.4_

- [ ] 6. Implement ResultsProcessor Lambda
  - [ ] 6.1 Build SQS Event Handler and Paginated Result Retrieval
    - Create `components/results_processor.py` with `handler(event, context)` function
    - Implement `parse_sqs_notification(record)`: extract SNS message from SQS record body, parse JSON to get `JobId`, `Status`, and `API` type
    - Implement `get_text_detection_results(job_id)`: call `textract.get_document_text_detection(JobId=job_id)`, return blocks
    - Implement `get_document_analysis_results(job_id)`: call `textract.get_document_analysis(JobId=job_id)`, return blocks
    - Implement `assemble_paginated_results(job_id, api_type)`: loop using `NextToken` to retrieve all pages of results, concatenate all Block lists into a single complete result set
    - Implement `publish_metrics(metric_name, value)` for async path metrics
    - _Requirements: 4.2, 4.3_
  - [ ] 6.2 Transform and Store Async Results
    - In `handler`: after assembling full results, use TextractParser to extract text lines, key-value pairs, and tables
    - Use DataStore to save JSON to appropriate S3 output prefix and store records in DynamoDB with correct sort keys (`TEXT#<line_num>`, `FORM#<field_name>`, `TABLE#<table_idx>#<row>#<col>`)
    - Log processing completion with block counts and source document reference
    - Handle `FAILED` job status: log error details and publish `DocumentsFailed` metric
    - _Requirements: 2.2, 3.3, 5.1, 5.2, 5.3_

- [ ] 7. Checkpoint - Validate Core Processing
  - Deploy both Lambda functions: package code with dependencies, create functions with `doc-processor-lambda-role`, set timeout to 60s and memory to 512MB
  - Configure S3 event notification on `incoming/` prefix to trigger DocumentProcessor Lambda (implement `configure_s3_event_notification`)
  - Configure SQS trigger on `textract-results-queue` to invoke ResultsProcessor Lambda
  - Test sync path: upload a single-page JPEG to `incoming/`, verify JSON output in `results/text-detection/`, verify DynamoDB records via `query_by_document`
  - Test document analysis: upload a single-page document with form fields, verify key-value pairs in `results/document-analysis/` and DynamoDB
  - Test async path: upload a multi-page PDF to `incoming/`, verify job ID is logged, wait for completion notification, verify assembled results in S3 and DynamoDB
  - Test error handling: upload a `.txt` file, verify it is moved to `errors/` prefix and no Textract call is made
  - Verify DLQ: temporarily cause a processing failure (e.g., invalid document), confirm message appears in `doc-processing-dlq` after retries
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement Monitoring, Alerting, and Error Notifications
  - [ ] 8.1 Configure CloudWatch Alarms and DLQ Alerting
    - Implement `create_dlq_alarm(alarm_name, queue_name, threshold, sns_topic_arn)`: create CloudWatch alarm on `ApproximateNumberOfMessagesVisible` metric for DLQ, threshold of 1, period 60s, trigger SNS error alert topic
    - Configure alarm: `aws cloudwatch put-metric-alarm --alarm-name DocProcessingDLQAlarm --namespace AWS/SQS --metric-name ApproximateNumberOfMessagesVisible --dimensions Name=QueueName,Value=doc-processing-dlq --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --evaluation-periods 1 --period 60 --statistic Sum --alarm-actions <error-alert-sns-arn>`
    - Verify alarm: `aws cloudwatch describe-alarms --alarm-names DocProcessingDLQAlarm`
    - _Requirements: 6.3, 7.3_
  - [ ] 8.2 Configure CloudWatch Dashboard and Structured Logging
    - Implement `create_cloudwatch_dashboard(dashboard_name, lambda_function_names, dlq_name)`: create dashboard showing Lambda invocations, errors, duration for both functions; DLQ message count; custom metrics (DocumentsProcessed, DocumentsFailed, BlockCount)
    - Ensure all Lambda functions use structured logging with consistent fields: `document_id`, `processing_stage`, `analysis_type`, `timestamp`, `block_count`
    - Verify custom metrics appear: `aws cloudwatch list-metrics --namespace DocProcessingPipeline`
    - Verify dashboard: open CloudWatch console and confirm `DocProcessingDashboard` displays all widgets
    - _Requirements: 7.1, 7.2, 7.4_

- [ ] 9. Checkpoint - End-to-End Validation
  - Upload a single-page image with text → verify text detection results in S3 and DynamoDB, verify CloudWatch logs show structured entries for each processing stage
  - Upload a single-page document with forms and tables → verify separate document analysis results, verify key-value pairs and table data in DynamoDB
  - Upload a multi-page PDF → verify async job submission, SNS/SQS notification flow, paginated result assembly, final storage in S3 and DynamoDB
  - Upload an unsupported file (.docx) → verify it moves to `errors/` prefix with logged reason
  - Force a processing failure → verify message reaches DLQ, CloudWatch alarm triggers, SNS error alert email is received
  - Check CloudWatch dashboard shows processing volume, error rate, and Lambda duration metrics
  - Verify custom metrics: `DocumentsProcessed`, `DocumentsFailed`, and block count metrics are published
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete Lambda Functions and Event Configurations
    - Remove S3 event notification: `aws s3api put-bucket-notification-configuration --bucket doc-processing-pipeline-<account-id> --notification-configuration '{}'`
    - Remove SQS trigger from Lambda: `aws lambda delete-event-source-mapping --uuid <mapping-uuid>`
    - Delete Lambda functions: `aws lambda delete-function --function-name DocumentProcessor` and `aws lambda delete-function --function-name ResultsProcessor`
    - _Requirements: (all)_
  - [ ] 10.2 Delete Messaging, Storage, and Monitoring Resources
    - Delete SQS queues: `aws sqs delete-queue --queue-url <results-queue-url>` and `aws sqs delete-queue --queue-url <dlq-url>`
    - Delete SNS subscriptions: `aws sns unsubscribe --subscription-arn <sub-arn>` for each subscription
    - Delete SNS topics: `aws sns delete-topic --topic-arn <textract-notifications-arn>` and `aws sns delete-topic --topic-arn <error-alerts-arn>`
    - Delete DynamoDB table: `aws dynamodb delete-table --table-name DocumentResults`
    - Empty and delete S3 bucket: `aws s3 rm s3://doc-processing-pipeline-<account-id> --recursive` then `aws s3api delete-bucket --bucket doc-processing-pipeline-<account-id>`
    - Delete CloudWatch alarm: `aws cloudwatch delete-alarms --alarm-names DocProcessingDLQAlarm`
    - Delete CloudWatch dashboard: `aws cloudwatch delete-dashboards --dashboard-names DocProcessingDashboard`
    - Delete IAM roles (detach policies first): `aws iam detach-role-policy` for each policy, then `aws iam delete-role --role-name doc-processor-lambda-role` and `aws iam delete-role --role-name textract-sns-role`
    - _Requirements: (all)_
  - [ ] 10.3 Verify Cleanup
    - Verify no Lambda functions remain: `aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'Document') || starts_with(FunctionName, 'Results')]"`
    - Verify S3 bucket deleted: `aws s3api head-bucket --bucket doc-processing-pipeline-<account-id>` (should return error)
    - Verify DynamoDB table deleted: `aws dynamodb describe-table --table-name DocumentResults` (should return error)
    - Check AWS Cost Explorer for any remaining charges from Textract API calls or other resources
    - **Warning**: SNS topics and SQS queues incur no cost when idle, but Lambda functions with reserved concurrency and CloudWatch alarms may incur charges if not deleted
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The DocumentProcessor Lambda handles both sync processing (single-page) and async job submission (multi-page), while the ResultsProcessor Lambda handles async result retrieval — both paths share the TextractParser and DataStore modules
- IAM roles must be created before Lambda deployment; ensure the Textract SNS role trust policy allows `textract.amazonaws.com` as a principal
- For testing, use documents with at least 150 DPI for best Textract results; sample forms and tables can be created using any word processor and exported as PDF or image
