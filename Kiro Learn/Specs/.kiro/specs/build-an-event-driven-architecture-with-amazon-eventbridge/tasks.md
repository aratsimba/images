

# Implementation Plan: Event-Driven Architecture with Amazon EventBridge

## Overview

This implementation plan guides you through building a multi-component event-driven architecture using Amazon EventBridge as the central event router. The system consists of five Python components: EventBusManager for event bus lifecycle, TargetSetup for provisioning downstream AWS resources, RuleManager for creating rules with event patterns and targets, EventPublisher for emitting custom events, and PipeManager for point-to-point integration via EventBridge Pipes. All components use boto3 to interact with AWS services.

The plan follows a logical progression: first setting up prerequisites and IAM roles, then provisioning the custom event bus and downstream targets (Lambda, SQS, SNS), followed by creating rules with event patterns, publishing custom events, and verifying multi-target routing. Later tasks introduce event transformation, AWS service event monitoring on the default event bus, dead-letter queue error handling, and EventBridge Pipes. Checkpoints after major milestones validate that events flow correctly through the system.

Key dependencies dictate the ordering: the event bus must exist before rules can be created, targets must be provisioned before they can be attached to rules, and rules must be active before events can be routed. The EventBridge Pipe task depends on both the SQS source queue and the custom event bus being available. All resources are created programmatically via boto3, with IAM roles set up via AWS CLI as a prerequisite.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`; verify: `python3 -c "import boto3; print(boto3.__version__)"`
    - Create project directory structure: `mkdir -p components lambda_code`
    - _Requirements: (all)_
  - [ ] 1.3 IAM Roles and Permissions
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Note: Lambda, SQS, and SNS targets use **resource-based policies**, not IAM roles — do NOT create an IAM role with RoleArn for these targets, as doing so can cause event delivery failures. Instead, grant EventBridge permission via resource-based policies on each target (Lambda: `aws lambda add-permission`, SQS: `aws sqs set-queue-attributes`, SNS: `aws sns set-topic-attributes`). An IAM role (trust policy for `events.amazonaws.com`) is only needed for targets that require identity-based access, such as Kinesis streams or Step Functions state machines.
    - Create an IAM role for Lambda execution with `AWSLambdaBasicExecutionRole`
    - Create an IAM role for EventBridge Pipes (trust policy for `pipes.amazonaws.com`) with permissions to read from SQS and put events to EventBridge
    - Note all role ARNs for use in subsequent tasks
    - Verify roles: `aws iam get-role --role-name <role-name>`
    - _Requirements: (all)_

- [ ] 2. EventBusManager and Custom Event Bus
  - [ ] 2.1 Implement EventBusManager component
    - Create `components/event_bus_manager.py` with class `EventBusManager`
    - Initialize `boto3.client('events')` in the constructor
    - Implement `create_event_bus(bus_name)` using `create_event_bus()` API; return response dict
    - Implement `describe_event_bus(bus_name)` using `describe_event_bus()` API
    - Implement `list_event_buses()` using `list_event_buses()` API; return list of dicts
    - Implement `delete_event_bus(bus_name)` using `delete_event_bus()` API
    - Add error handling for `ResourceAlreadyExistsException` and `ResourceNotFoundException`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Create and verify custom event bus
    - Write a script `scripts/create_bus.py` that creates a custom event bus named `learning-eda-bus`
    - Call `describe_event_bus('learning-eda-bus')` to verify it is active
    - Call `list_event_buses()` to confirm both custom and default bus appear
    - Test duplicate creation to verify `ResourceAlreadyExistsException` is returned
    - Verify: `aws events describe-event-bus --name learning-eda-bus`
    - _Requirements: 1.1, 1.2, 1.3_

- [ ] 3. TargetSetup - Provision Downstream Resources
  - [ ] 3.1 Implement TargetSetup component
    - Create `components/target_setup.py` with class `TargetSetup`
    - Initialize `boto3.client('lambda')`, `boto3.client('sqs')`, `boto3.client('sns')` in the constructor
    - Implement `create_lambda_function(function_name, role_arn, handler, zip_path)` using `create_function()` API with Python 3.12 runtime
    - Implement `delete_lambda_function(function_name)` using `delete_function()` API
    - Implement `create_sqs_queue(queue_name)` using `create_queue()` API; return dict with QueueUrl
    - Implement `get_queue_arn(queue_name)` using `get_queue_attributes()` to retrieve ARN
    - Implement `get_queue_url(queue_name)` using `get_queue_url()` API
    - Implement `receive_messages(queue_url, max_messages)` using `receive_message()` API
    - Implement `delete_sqs_queue(queue_url)` using `delete_queue()` API
    - Implement `create_sns_topic(topic_name)` using `create_topic()` API; return dict with TopicArn
    - Implement `subscribe_email(topic_arn, email)` using `subscribe()` with protocol `email`
    - Implement `delete_sns_topic(topic_arn)` using `delete_topic()` API
    - _Requirements: 4.1, 4.2, 4.3, 7.1, 7.3, 8.1_
  - [ ] 3.2 Provision all target resources
    - Create a Lambda handler in `lambda_code/event_processor.py` that logs the received event; zip it to `lambda_code/event_processor.zip`
    - Create Lambda function `eda-event-processor` using the Lambda execution role ARN
    - Add a resource-based policy to the Lambda function allowing `events.amazonaws.com` to invoke it
    - Create SQS queue `eda-event-queue` for event target; note its ARN and URL
    - Create SQS queue `eda-dlq` for dead-letter queue; note its ARN
    - Set SQS queue policies on both queues to allow EventBridge to send messages
    - Create SQS queue `eda-pipe-source` for the EventBridge Pipe source; note its ARN
    - Create SNS topic `eda-notifications`; note its ARN
    - Optionally subscribe an email address to the SNS topic for testing
    - Set SNS topic policy allowing EventBridge to publish
    - Verify all resources: `aws lambda get-function --function-name eda-event-processor`, `aws sqs get-queue-url --queue-name eda-event-queue`, `aws sns list-topics`
    - _Requirements: 4.1, 4.2, 4.3, 7.1, 8.1_

- [ ] 4. Checkpoint - Validate Infrastructure
  - Confirm custom event bus `learning-eda-bus` exists: `aws events describe-event-bus --name learning-eda-bus`
  - Confirm Lambda function is active: `aws lambda get-function --function-name eda-event-processor`
  - Confirm SQS queues exist: `aws sqs list-queues --queue-name-prefix eda-`
  - Confirm SNS topic exists: `aws sns list-topics`
  - Test Lambda invocation manually: `aws lambda invoke --function-name eda-event-processor --payload '{"test": true}' /dev/stdout`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. RuleManager - Rules, Targets, and Event Publishing
  - [ ] 5.1 Implement RuleManager component
    - Create `components/rule_manager.py` with class `RuleManager`
    - Initialize `boto3.client('events')` in the constructor
    - Implement `create_rule(rule_name, bus_name, event_pattern)` using `put_rule()` API with the event pattern as a JSON string
    - Implement `add_target(rule_name, bus_name, target_id, target_arn)` using `put_targets()` API; note: do NOT pass `RoleArn` for Lambda, SQS, or SNS targets — these use resource-based policies only
    - Implement `add_target_with_transform(rule_name, bus_name, target_id, target_arn, input_paths_map, input_template)` using `put_targets()` with `InputTransformer` parameter; do NOT pass `RoleArn` for Lambda, SQS, or SNS targets
    - Implement `add_target_with_dlq(rule_name, bus_name, target_id, target_arn, dlq_arn)` using `put_targets()` with `DeadLetterConfig`; do NOT pass `RoleArn` for Lambda, SQS, or SNS targets
    - Implement `list_rules(bus_name)` using `list_rules()` API
    - Implement `list_targets(rule_name, bus_name)` using `list_targets_by_rule()` API
    - Implement `remove_targets(rule_name, bus_name, target_ids)` using `remove_targets()` API
    - Implement `delete_rule(rule_name, bus_name)` using `delete_rule()` API (must remove targets first)
    - Add error handling for `InvalidEventPatternException`, `ResourceNotFoundException`, `ManagedRuleException`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.4, 5.1, 5.2, 5.3, 7.1, 7.2, 7.3_
  - [ ] 5.2 Implement EventPublisher component
    - Create `components/event_publisher.py` with class `EventPublisher`
    - Initialize `boto3.client('events')` in the constructor
    - Implement `publish_event(bus_name, source, detail_type, detail)` using `put_events()` API with a single entry; return response dict
    - Implement `publish_events_batch(bus_name, entries)` using `put_events()` with multiple entries; return dict with `FailedEntryCount` and `Entries`
    - Add error handling for `ResourceNotFoundException` when bus does not exist
    - _Requirements: 3.1, 3.2, 3.3_
  - [ ] 5.3 Create rules and route events to multiple targets
    - Create rule `order-created-rule` on `learning-eda-bus` with event pattern: `{"source": ["com.myapp.orders"], "detail-type": ["OrderCreated"]}`
    - Add Lambda target `eda-event-processor` to the rule using `add_target()`
    - Add SQS target `eda-event-queue` to the rule using `add_target()`
    - Add SNS target `eda-notifications` to the rule using `add_target()`
    - Create rule `order-shipped-rule` on `learning-eda-bus` with event pattern filtering on nested detail: `{"source": ["com.myapp.orders"], "detail-type": ["OrderUpdated"], "detail": {"status": ["shipped"]}}`
    - Add SQS target to `order-shipped-rule`
    - Publish a custom `OrderCreated` event with `OrderDetail` data model fields (order_id, customer_id, status, total_amount, items)
    - Publish a batch of events including `OrderCreated` and `OrderUpdated` events using `publish_events_batch()`
    - Verify Lambda was invoked: check CloudWatch Logs for the function
    - Verify SQS received messages: call `receive_messages()` on `eda-event-queue`
    - Verify events matched independently across rules by publishing an `OrderUpdated` event with `status: "shipped"` and confirming it routes to `order-shipped-rule` targets
    - Test that non-matching events (different source) are not delivered to any target
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4_
  - [ ]* 5.4 Verify event pattern matching and batch publishing
    - **Property 1: Event Pattern Selective Routing**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3**

- [ ] 6. Event Transformation and Error Handling
  - [ ] 6.1 Configure input transformer on a rule target
    - Create rule `order-transform-rule` on `learning-eda-bus` with event pattern matching `com.myapp.orders` / `OrderCreated`
    - Use `add_target_with_transform()` to add the SQS queue as target with input paths map: `{"orderId": "$.detail.order_id", "status": "$.detail.status", "customer": "$.detail.customer_id"}`
    - Set input template: `'{"id": <orderId>, "currentStatus": <status>, "customerId": <customer>}'`
    - Publish an `OrderCreated` event and verify the SQS message contains only the transformed payload (not the full event)
    - Publish an event where a mapped field (e.g., `customer_id`) is missing and verify the transformed output contains empty/null for that field
    - _Requirements: 5.1, 5.2, 5.3_
  - [ ] 6.2 Configure dead-letter queue for failed delivery
    - Create rule `order-dlq-rule` on `learning-eda-bus` with an event pattern matching `com.myapp.orders` / `OrderFailed`
    - Use `add_target_with_dlq()` to add a non-existent or intentionally failing Lambda ARN as target, with `eda-dlq` as the dead-letter queue
    - Publish an `OrderFailed` event and wait for retries to exhaust
    - Call `receive_messages()` on the `eda-dlq` queue URL to verify the failed event landed in the DLQ with original payload and failure metadata
    - Verify that without a DLQ configured, a failed delivery results in the event being dropped (create a separate rule with no DLQ and a bad target to demonstrate)
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 7. Checkpoint - Validate Core Event Routing
  - Publish an `OrderCreated` event and confirm it arrives at Lambda (CloudWatch Logs), SQS queue, and SNS topic simultaneously
  - Publish an `OrderUpdated` event with `status: "shipped"` and verify nested field filtering works
  - Verify transformed events in SQS contain only the restructured payload
  - Verify DLQ contains failed events with metadata
  - Test publishing to a non-existent bus name and confirm error is returned
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. AWS Service Events and EventBridge Pipes
  - [ ] 8.1 Monitor AWS service events on the default event bus
    - Create rule `ec2-state-change-rule` on the default event bus with event pattern: `{"source": ["aws.ec2"], "detail-type": ["EC2 Instance State-change Notification"], "detail": {"state": ["stopped"]}}`
    - Add SQS queue `eda-event-queue` as target for this rule
    - Trigger the event by stopping an EC2 instance (or describe how to test with a running instance)
    - Verify the rule only triggers for `stopped` state, not for other state changes like `running`
    - Confirm event appears in the SQS queue with AWS service event structure
    - Call `list_rules('default')` to see the rule listed
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ] 8.2 Implement PipeManager component
    - Create `components/pipe_manager.py` with class `PipeManager`
    - Initialize `boto3.client('pipes')` in the constructor
    - Implement `create_pipe(pipe_name, source_arn, target_arn, role_arn)` using `create_pipe()` API with SQS source parameters (batch size 1)
    - Implement `create_pipe_with_filter(pipe_name, source_arn, target_arn, role_arn, filter_pattern)` using `create_pipe()` with `FilterCriteria` parameter
    - Implement `describe_pipe(pipe_name)` using `describe_pipe()` API
    - Implement `delete_pipe(pipe_name)` using `delete_pipe()` API
    - Add error handling for `ResourceAlreadyExistsException` and `ResourceNotFoundException`
    - _Requirements: 8.1, 8.2, 8.3_
  - [ ] 8.3 Create and test EventBridge Pipe
    - Create pipe `eda-order-pipe` with source `eda-pipe-source` SQS queue ARN and target `learning-eda-bus` event bus ARN using the Pipes IAM role
    - Verify pipe is in RUNNING state: call `describe_pipe('eda-order-pipe')`
    - Send a test message to `eda-pipe-source` SQS queue with an order event JSON body
    - Verify the event flows through the pipe to the custom event bus and is routed by existing rules to targets
    - Create pipe `eda-filtered-pipe` with filter pattern matching only `{"body": {"status": ["critical"]}}` using `create_pipe_with_filter()`
    - Send messages with `status: "critical"` and `status: "normal"` to the pipe source queue
    - Verify only the `critical` message is delivered through the pipe to the event bus
    - _Requirements: 8.1, 8.2, 8.3_

- [ ] 9. Checkpoint - Validate Complete System
  - Verify AWS service events on the default bus are captured by the EC2 state change rule
  - Verify the EventBridge Pipe reads from SQS and delivers to the custom event bus
  - Verify pipe filtering correctly discards non-matching messages
  - Confirm end-to-end flow: SQS → Pipe → Event Bus → Rules → Lambda/SQS/SNS targets
  - Review all five components are implemented: EventBusManager, RuleManager, EventPublisher, TargetSetup, PipeManager
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete EventBridge Pipes
    - Delete pipe: `aws pipes delete-pipe --name eda-order-pipe`
    - Delete pipe: `aws pipes delete-pipe --name eda-filtered-pipe`
    - Verify: `aws pipes list-pipes` shows no project pipes
    - _Requirements: (all)_
  - [ ] 10.2 Delete EventBridge rules and targets
    - Remove all targets from each rule before deleting the rule
    - For each rule (`order-created-rule`, `order-shipped-rule`, `order-transform-rule`, `order-dlq-rule`): call `remove_targets()` then `delete_rule()` on `learning-eda-bus`
    - For `ec2-state-change-rule`: remove targets and delete rule on default event bus
    - Verify: `aws events list-rules --event-bus-name learning-eda-bus` returns empty
    - _Requirements: (all)_
  - [ ] 10.3 Delete custom event bus and downstream resources
    - Delete custom event bus: `aws events delete-event-bus --name learning-eda-bus`
    - Delete Lambda function: `aws lambda delete-function --function-name eda-event-processor`
    - Delete SQS queues: `aws sqs delete-queue --queue-url <eda-event-queue-url>`, `aws sqs delete-queue --queue-url <eda-dlq-url>`, `aws sqs delete-queue --queue-url <eda-pipe-source-url>`
    - Delete SNS topic: `aws sns delete-topic --topic-arn <eda-notifications-arn>`
    - Delete IAM roles: remove attached policies first, then `aws iam delete-role --role-name <role-name>` for each role created
    - Verify no resources remain: `aws events list-event-buses`, `aws sqs list-queues --queue-name-prefix eda-`, `aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'eda-')]"`
    - **Warning**: Ensure all resources are deleted to avoid ongoing charges, particularly SQS queues and Lambda functions
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation of the event-driven architecture
- IAM role creation via AWS CLI is a prerequisite; all other resources are provisioned via boto3 in Python components
- The EventBridge Pipe requires the pipe IAM role to have permissions for both the SQS source and EventBridge target
- Allow a few seconds of propagation time after creating rules before publishing events, as rule activation may not be instantaneous
- For Requirement 6 (AWS service events), testing requires either a running EC2 instance or can be validated by inspecting the rule configuration matches the expected event pattern
