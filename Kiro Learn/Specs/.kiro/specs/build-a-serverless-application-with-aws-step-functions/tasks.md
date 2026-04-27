

# Implementation Plan: Build a Serverless Application with AWS Step Functions

## Overview

This implementation plan guides learners through building a serverless order-processing workflow orchestrated by AWS Step Functions. The approach follows a logical progression: first setting up the development environment and project structure, then implementing the Lambda functions that serve as workflow steps, defining the state machine in Amazon States Language (ASL) with sequential, branching, parallel, and error-handling patterns, wiring everything together via an AWS SAM template, and finally deploying, executing, and monitoring the application.

The project is organized into key phases: environment setup, Lambda function implementation, state machine definition, SAM template configuration with deployment, and workflow execution with monitoring. Each phase builds on the previous one, ensuring learners can validate their progress incrementally. The Lambda functions are developed first so that the state machine definition can reference them meaningfully, and the SAM template ties everything together with definition substitutions and IAM policies before deployment.

A critical dependency is that all Lambda functions and the ASL definition must be complete before the SAM template can be deployed successfully. The invocation script is developed after deployment so learners have a deployed state machine ARN to target. Checkpoints are placed after Lambda implementation and after full deployment to validate the application end-to-end before exploring monitoring and observability features.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions to create Lambda functions, Step Functions state machines, IAM roles, and CloudWatch Logs
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install AWS SAM CLI: verify with `sam --version`
    - Install boto3: `pip install boto3`
    - _Requirements: (all)_
  - [ ] 1.3 Initialize Project Structure
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create the project directory structure:
      ```
      step-functions-app/
      ├── functions/
      │   ├── validate_order/
      │   ├── process_payment/
      │   ├── reserve_inventory/
      │   ├── send_notification/
      │   └── handle_failure/
      ├── statemachine/
      ├── scripts/
      └── template.yaml
      ```
    - Verify structure is in place before proceeding
    - _Requirements: (all)_

- [ ] 2. Implement Lambda Functions for Workflow Steps
  - [ ] 2.1 Create ValidateOrder Lambda
    - Create `functions/validate_order/app.py` with `lambda_handler(event, context)`
    - Validate required fields: `order_id`, `customer_name`, `order_type`, `items`, `total_amount`
    - Raise a `ValidationError` (as a Python `Exception` with that name) if fields are missing or invalid
    - Return a `ValidatedOrder` dictionary with all input fields plus `validated_at` (ISO 8601 timestamp) and `is_valid: True`
    - Ensure `order_type` field (`"standard"` or `"express"`) is preserved in output for downstream choice state routing
    - Test locally: `python -c "from functions.validate_order.app import lambda_handler; print(lambda_handler({'order_id':'ORD-001','customer_name':'Alice','order_type':'standard','items':[{'item_id':'ITEM-1','name':'Widget','quantity':2,'price':10.0}],'total_amount':20.0}, None))"`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Create ProcessPayment and ReserveInventory Lambdas
    - Create `functions/process_payment/app.py` with `lambda_handler(event, context)`
    - Simulate payment processing: generate a `transaction_id` using `uuid.uuid4()`, return a `PaymentResult` with `order_id`, `transaction_id`, `status: "succeeded"`, and `charged_amount`
    - Add random transient failure: approximately 30% of invocations raise a custom `PaymentProcessingError` exception to demonstrate retry behavior
    - Create `functions/reserve_inventory/app.py` with `lambda_handler(event, context)`
    - Simulate inventory reservation: generate a `reservation_id`, return a `ReservationResult` with `order_id`, `reservation_id`, `status: "reserved"`, and `reserved_items` list of item IDs
    - Test each function locally to verify output structure
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.3 Create SendNotification and HandleFailure Lambdas
    - Create `functions/send_notification/app.py` with `lambda_handler(event, context)`
    - Receive combined parallel state output (an array of branch results), produce a `NotificationResult` with `order_id`, a summary `message`, and `notification_sent: True`
    - Log the order outcome using `print()` or the `logging` module
    - Create `functions/handle_failure/app.py` with `lambda_handler(event, context)`
    - Extract error details from the event (fields `Error` and `Cause` injected by Step Functions catch)
    - Return a `FailureReport` with `order_id`, `error_type`, `error_message`, and `handled_at` timestamp
    - Test each function locally to verify correct output
    - _Requirements: 1.1, 1.2, 1.3, 5.2_

- [ ] 3. Checkpoint - Validate Lambda Functions
  - Invoke each Lambda handler locally with sample `OrderInput` data and verify structured output
  - Confirm `ValidateOrder` returns `ValidatedOrder` with `is_valid` and `validated_at`
  - Confirm `ProcessPayment` sometimes raises `PaymentProcessingError` and otherwise returns `PaymentResult`
  - Confirm `ReserveInventory` returns `ReservationResult` with `reservation_id`
  - Confirm `SendNotification` handles an array input (simulating parallel output) and returns `NotificationResult`
  - Confirm `HandleFailure` returns a `FailureReport` when given error-shaped input
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Define the State Machine (ASL)
  - [ ] 4.1 Create Sequential Workflow with Task and Choice States
    - Create `statemachine/order_processing.asl.json`
    - Define the `"Validate Order"` Task state invoking `${ValidateOrderArn}` as the first state
    - Define the `"Check Order Type"` Choice state that branches on `$.order_type`: route `"standard"` to `"Process Standard"` and `"express"` to `"Process Express"`, with a `Default` branch pointing to `"Process Standard"`
    - Define `"Process Standard"` and `"Process Express"` as Pass or Task states that both transition to the `"Parallel Process"` state (these serve as path placeholders demonstrating the branch was taken)
    - Verify the ASL JSON is valid by reviewing its structure or using the AWS Toolkit for VS Code
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3_
  - [ ] 4.2 Add Parallel State, Error Handling, and Terminal States
    - Define `"Parallel Process"` as a Parallel state with two branches:
      - Branch 1: `"ProcessPayment"` Task state invoking `${ProcessPaymentArn}`
      - Branch 2: `"ReserveInventory"` Task state invoking `${ReserveInventoryArn}`
    - Add a `Retry` configuration on the `"ProcessPayment"` Task state: match `PaymentProcessingError`, `IntervalSeconds: 2`, `MaxAttempts: 2`, `BackoffRate: 2.0`
    - Add a `Catch` configuration on the `"Parallel Process"` state: match `States.ALL`, set `ResultPath: "$.error_info"`, transition to `"Handle Failure"`
    - Define `"Send Notification"` Task state invoking `${SendNotificationArn}` as the state after `"Parallel Process"`
    - Define `"Handle Failure"` Task state invoking `${HandleFailureArn}`, transitioning to `"Order Failed"` (a Fail state or Succeed state representing graceful termination)
    - Define `"Order Complete"` as a Succeed state after `"Send Notification"`
    - Ensure all `Resource` fields use substitution variables: `${ValidateOrderArn}`, `${ProcessPaymentArn}`, `${ReserveInventoryArn}`, `${SendNotificationArn}`, `${HandleFailureArn}`
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [ ] 5. Create the SAM Template and Deploy
  - [ ] 5.1 Define SAM Template Resources
    - Create `template.yaml` with `Transform: AWS::Serverless-2016-10-31`
    - Define five `AWS::Serverless::Function` resources (one per Lambda), each with:
      - `Runtime: python3.12`
      - `Handler: app.lambda_handler`
      - `CodeUri` pointing to the respective `functions/<name>/` directory
    - Define one `AWS::Serverless::StateMachine` resource with:
      - `DefinitionUri: statemachine/order_processing.asl.json`
      - `DefinitionSubstitutions` mapping `ValidateOrderArn`, `ProcessPaymentArn`, `ReserveInventoryArn`, `SendNotificationArn`, `HandleFailureArn` to `!GetAtt` references of each function's ARN
      - `Policies` using SAM policy templates: `LambdaInvokePolicy` for each Lambda function
    - Enable logging on the state machine: add a `Logging` configuration with `Level: ALL` and a `CloudWatchLogsLogGroup` destination (define an `AWS::Logs::LogGroup` resource)
    - Add `Outputs` section exporting the state machine ARN and name for use by the invocation script
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.3_
  - [ ] 5.2 Build and Deploy with SAM CLI
    - Validate the template: `sam validate`
    - Build the application: `sam build`
    - Deploy the application: `sam deploy --guided` (set stack name, region, confirm IAM role creation)
    - Note the state machine ARN from the stack outputs
    - Verify deployment: `aws stepfunctions describe-state-machine --state-machine-arn <ARN>`
    - Verify all Lambda functions were created: `aws lambda list-functions --query "Functions[?starts_with(FunctionName, '<stack-name>')]"`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 6. Checkpoint - Validate Deployment
  - Confirm the CloudFormation stack is in `CREATE_COMPLETE` status: `aws cloudformation describe-stacks --stack-name <stack-name>`
  - View the state machine visual workflow in the Step Functions console and verify all states and transitions are displayed
  - Confirm the CloudWatch Logs log group exists for the state machine
  - Verify each Lambda function is independently invocable: `aws lambda invoke --function-name <function-name> --payload '{"order_id":"test"}' output.json`
  - Ensure all tests pass, ask the user if questions arise.
  - _Requirements: 2.4, 6.3_

- [ ] 7. Create Invocation Script and Execute Workflows
  - [ ] 7.1 Build the Invocation Script
    - Create `scripts/start_execution.py` using `boto3.client('stepfunctions')`
    - Implement `start_execution(state_machine_arn, input_payload)` that calls `start_execution()` and returns the execution ARN
    - Implement `describe_execution(execution_arn)` that calls `describe_execution()` and returns status, input, and output
    - Implement `list_executions(state_machine_arn, status_filter)` that calls `list_executions()` and returns a list of execution summaries
    - Add CLI argument parsing to accept `--arn`, `--input` (JSON string or file), and `--action` (start/describe/list) parameters
    - _Requirements: 2.3, 7.1_
  - [ ] 7.2 Execute and Verify Workflow Paths
    - Start an execution with a `"standard"` order: `python scripts/start_execution.py --arn <ARN> --input '{"order_id":"ORD-001","customer_name":"Alice","order_type":"standard","items":[{"item_id":"ITEM-1","name":"Widget","quantity":2,"price":10.0}],"total_amount":20.0}'`
    - Start an execution with an `"express"` order to verify the choice state routes differently
    - Start an execution with invalid input (e.g., missing `order_id`) to trigger the validation error path
    - Run multiple executions to observe retry behavior on `ProcessPayment` transient failures
    - Verify successful executions reach `"Order Complete"` and failed ones route through `"Handle Failure"`
    - _Requirements: 2.1, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [ ] 8. Monitor Executions and Observe Workflow Behavior
  - [ ] 8.1 Inspect Execution History and Logs
    - In the Step Functions console, open a completed execution and review the execution event history showing each state entered with its input and output data
    - Observe a running execution's current state highlighted on the visual workflow diagram
    - Open a failed execution and identify which state failed, the error type, and error message
    - Verify retry attempts are visible in the execution history for `ProcessPayment` state (look for repeated `TaskScheduled` and `TaskFailed` event sequences within the same state entry)
    - Review CloudWatch Logs for the state machine: `aws logs filter-log-events --log-group-name <log-group-name> --limit 20`
    - Confirm execution events are captured in CloudWatch Logs for review outside the console
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ]* 8.2 Validate Error Handling and Parallel Execution Properties
    - **Property 1: Retry Policy Enforcement** — Start multiple executions and confirm that when `ProcessPayment` raises `PaymentProcessingError`, the state machine retries up to 2 times with exponential backoff before catching
    - **Property 2: Parallel Branch Output Combination** — Verify that when both parallel branches succeed, their outputs are combined into an array passed to `SendNotification`
    - **Property 3: Choice State Routing** — Confirm that `"standard"` and `"express"` inputs follow distinct paths, and an unrecognized `order_type` follows the default branch
    - **Validates: Requirements 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3**

- [ ] 9. Checkpoint - End-to-End Validation
  - Verify a standard order execution completes successfully through: Validate Order → Check Order Type → Process Standard → Parallel Process → Send Notification → Order Complete
  - Verify an express order execution follows the express branch through Check Order Type
  - Verify a failed execution routes through Handle Failure and produces a FailureReport
  - Verify retry behavior is observable in execution history for transient payment errors
  - Verify CloudWatch Logs contain execution events for all test runs
  - Confirm the visual workflow diagram accurately shows all states and transitions
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete the SAM Stack
    - Delete the CloudFormation stack and all its resources: `sam delete --stack-name <stack-name>`
    - Confirm stack deletion: `aws cloudformation describe-stacks --stack-name <stack-name>` should return an error or show `DELETE_COMPLETE`
    - _Requirements: (all)_
  - [ ] 10.2 Verify Resource Cleanup
    - Verify state machine is deleted: `aws stepfunctions list-state-machines` should not include the project's state machine
    - Verify Lambda functions are deleted: `aws lambda list-functions` should not include the project's functions
    - Verify CloudWatch Logs log group is deleted (or delete manually if retained): `aws logs delete-log-group --log-group-name <log-group-name>`
    - Check for any remaining S3 buckets created by SAM for deployment artifacts: `aws s3 ls | grep aws-sam` — delete if no longer needed: `aws s3 rb s3://<bucket-name> --force`
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The `ProcessPayment` Lambda intentionally includes random failures — run multiple executions to observe both success and retry/catch paths
- When deploying with `sam deploy --guided`, save the `samconfig.toml` so subsequent deploys can use `sam deploy` without re-entering parameters
- The invocation script can also be replaced by starting executions directly from the Step Functions console if preferred
