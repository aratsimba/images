

# Implementation Plan: Deploy Infrastructure as Code with AWS CloudFormation

## Overview

This implementation plan guides you through the complete lifecycle of AWS CloudFormation, from authoring YAML templates to deploying, updating, inspecting, and deleting infrastructure stacks. The approach uses two layers: hand-authored YAML CloudFormation templates that define AWS resources declaratively (an S3 bucket and SNS topic), and Python scripts using boto3 that interact with the CloudFormation service programmatically to validate, deploy, update, detect drift, and clean up stacks.

The plan is organized into three phases. First, you will set up your environment and author CloudFormation templates with parameters, intrinsic functions, and outputs. Second, you will build the three Python components — TemplateManager, StackManager, and DriftDetector — that drive CloudFormation operations. Third, you will use these components to execute the full stack lifecycle: validate and deploy, update via change sets, detect drift after manual modifications, and finally delete the stack. Checkpoints after key milestones ensure you verify progress incrementally.

Dependencies flow naturally: templates must be authored before validation, validation before deployment, deployment before updates and drift detection, and all operations before cleanup. Each Python component is self-contained with a clear interface, so they can be built and tested in sequence. The two YAML templates (base and updated) are created early and referenced throughout the lifecycle operations.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for CloudFormation, S3, and SNS
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Confirm CloudFormation permissions: `aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`; verify: `python3 -c "import boto3; print(boto3.__version__)"`
    - Create project directory structure: `mkdir -p templates components`
    - Create `components/__init__.py` as an empty file
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure IAM permissions include: `cloudformation:*`, `s3:*`, `sns:*`
    - Note: all resources created will be in a single region and deleted at the end
    - _Requirements: (all)_

- [ ] 2. Author CloudFormation Templates
  - [ ] 2.1 Create the base template with parameters, resources, and outputs
    - Create `templates/base_template.yaml` with `AWSTemplateFormatVersion: "2010-09-09"` and a `Description` field
    - Define `Parameters` section with `EnvironmentName` (Type: String, Default: "dev", AllowedValues: ["dev", "staging", "prod"], Description provided) and `BucketRetentionDays` (Type: Number, Default: 7, Description provided)
    - Define `Resources` section with `AppBucket` (Type: `AWS::S3::Bucket`) using `!Sub` to compose the bucket name from `EnvironmentName`, and `NotificationTopic` (Type: `AWS::SNS::Topic`) using `!Join` to compose the topic display name referencing `EnvironmentName`
    - Use `!Ref` in the SNS topic to reference the S3 bucket, establishing an implicit dependency
    - Define `Outputs` section: `BucketName` using `!Ref AppBucket`, `BucketArn` using `!GetAtt AppBucket.Arn`, `TopicArn` using `!Ref NotificationTopic`, and `StackRegion` using `!Sub "Region: ${AWS::Region}"`
    - Verify the file is valid YAML: `python3 -c "import yaml; yaml.safe_load(open('templates/base_template.yaml'))"`
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 5.1, 5.2_
  - [ ] 2.2 Create the updated template for stack updates
    - Copy `templates/base_template.yaml` to `templates/updated_template.yaml`
    - Modify `updated_template.yaml`: add a `Tags` property to `AppBucket` with key `Updated` and value `true`, and update the `Description` to indicate it is a modified version
    - Ensure all parameters, intrinsic functions, and outputs remain intact
    - This template will be used later to demonstrate change sets and stack updates
    - _Requirements: 4.1, 4.2_

- [ ] 3. Implement TemplateManager and StackManager Components
  - [ ] 3.1 Build the TemplateManager component
    - Create `components/template_manager.py` with a `TemplateManager` class
    - Implement `__init__` to create a `boto3.client('cloudformation')` client
    - Implement `read_template(file_path: str) -> str` to read and return the YAML file contents from disk
    - Implement `validate_template(template_body: str) -> dict` to call `client.validate_template(TemplateBody=template_body)` and return the response; catch `ClientError` for validation failures and return the error details
    - Implement `get_template_parameters(template_body: str) -> list` to parse the validation response and return the list of parameter definitions
    - Test by running: `python3 -c "from components.template_manager import TemplateManager; tm = TemplateManager(); body = tm.read_template('templates/base_template.yaml'); print(tm.validate_template(body))"`
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2_
  - [ ] 3.2 Build the StackManager component
    - Create `components/stack_manager.py` with a `StackManager` class
    - Implement `__init__` to create a `boto3.client('cloudformation')` client
    - Implement `create_stack(stack_name, template_body, parameters)` to call `client.create_stack()` with the given parameters (as list of `{"ParameterKey": k, "ParameterValue": v}` dicts) and return the stack ID
    - Implement `wait_for_stack(stack_name, target_status)` using `client.get_waiter()` for statuses like `stack_create_complete`, `stack_update_complete`, `stack_delete_complete`; return final status
    - Implement `describe_stack(stack_name)` to call `client.describe_stacks()` and return the stack dictionary
    - Implement `get_stack_outputs(stack_name)` to extract and return the `Outputs` list from `describe_stack`
    - Implement `get_stack_events(stack_name)` to call `client.describe_stack_events()` and return the events list
    - Implement `create_change_set(stack_name, template_body, parameters, change_set_name)` to call `client.create_change_set()` and return the change set ID
    - Implement `describe_change_set(stack_name, change_set_name)` to call `client.describe_change_set()` and return the full response including `Changes` list
    - Implement `execute_change_set(stack_name, change_set_name)` to call `client.execute_change_set()`
    - Implement `delete_stack(stack_name)` to call `client.delete_stack()`
    - Implement `list_stack_resources(stack_name)` to call `client.list_stack_resources()` and return the resource summaries
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 7.1, 7.2, 7.3_

- [ ] 4. Implement DriftDetector Component
  - [ ] 4.1 Build the DriftDetector component
    - Create `components/drift_detector.py` with a `DriftDetector` class
    - Implement `__init__` to create a `boto3.client('cloudformation')` client
    - Implement `initiate_drift_detection(stack_name)` to call `client.detect_stack_drift(StackName=stack_name)` and return the `StackDriftDetectionId`
    - Implement `wait_for_drift_detection(detection_id)` to poll `client.describe_stack_drift_detection_status(StackDriftDetectionId=detection_id)` until `DetectionStatus` is `DETECTION_COMPLETE` (use a sleep loop with timeout)
    - Implement `get_stack_drift_status(stack_name)` to call `client.describe_stacks()` and return the `DriftInformation` from the stack
    - Implement `get_resource_drift_details(stack_name)` to call `client.describe_stack_resource_drifts(StackName=stack_name)` and return the list of drifted resources with expected/actual property values and property differences
    - Test the class instantiates: `python3 -c "from components.drift_detector import DriftDetector; dd = DriftDetector(); print('DriftDetector ready')"`
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 5. Checkpoint - Validate Templates and Components
  - Validate the base template: run `python3 -c "from components.template_manager import TemplateManager; tm = TemplateManager(); body = tm.read_template('templates/base_template.yaml'); result = tm.validate_template(body); print('Valid:', 'Parameters' in result)"` and confirm it succeeds
  - Validate the updated template similarly and confirm it succeeds
  - Test validation rejection: create a temporary invalid YAML template and confirm `validate_template` raises or returns an error
  - Verify `get_template_parameters` returns the two defined parameters (EnvironmentName, BucketRetentionDays) with their types and defaults
  - Confirm all three component files exist: `ls components/template_manager.py components/stack_manager.py components/drift_detector.py`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Deploy Stack and Validate Outputs
  - [ ] 6.1 Deploy the base template as a stack
    - Use StackManager to create a stack: call `create_stack("iac-learning-stack", template_body, [{"ParameterKey": "EnvironmentName", "ParameterValue": "dev"}])` (omit BucketRetentionDays to test default value usage)
    - Call `wait_for_stack("iac-learning-stack", "stack_create_complete")` and confirm the stack reaches `CREATE_COMPLETE`
    - Call `describe_stack("iac-learning-stack")` and verify the stack status, parameters (confirm BucketRetentionDays used default value of 7), and creation time
    - Call `get_stack_outputs("iac-learning-stack")` and verify all four outputs are present: BucketName, BucketArn, TopicArn, StackRegion
    - Call `list_stack_resources("iac-learning-stack")` and verify both AppBucket and NotificationTopic resources are listed
    - Verify resources exist in AWS: `aws s3 ls | grep <bucket-name>` and `aws sns list-topics | grep <topic-arn>`
    - _Requirements: 2.3, 3.1, 3.2, 5.1_
  - [ ]* 6.2 Test parameter constraint rejection
    - **Property 1: Parameter Constraint Enforcement**
    - Attempt to create a stack with `EnvironmentName` set to `"invalid"` (not in AllowedValues) and confirm CloudFormation rejects it with a validation error
    - **Validates: Requirements 2.2, 2.4**
  - [ ]* 6.4 Test circular dependency rejection
    - **Property 4: Circular Dependency Detection**
    - Create a temporary template where two resources each reference the other (e.g., Resource A uses `!Ref` to Resource B and Resource B uses `!Ref` to Resource A), creating a circular dependency
    - Call `validate_template` on this template using TemplateManager and confirm CloudFormation rejects it with a validation error describing the dependency cycle
    - **Validates: Requirements 5.3**
  - [ ]* 6.3 Test rollback on resource creation failure
    - **Property 2: Automatic Rollback on Failure**
    - Create a template with an intentionally invalid resource configuration and deploy it; confirm the stack reaches `ROLLBACK_COMPLETE` status
    - Use `get_stack_events` to inspect the failure reason
    - **Validates: Requirements 1.3, 3.3**

- [ ] 7. Update Stack with Change Sets
  - [ ] 7.1 Create and inspect a change set
    - Read `templates/updated_template.yaml` using TemplateManager
    - Call `create_change_set("iac-learning-stack", updated_body, [{"ParameterKey": "EnvironmentName", "ParameterValue": "dev"}], "add-bucket-tags")` 
    - Wait for change set creation: poll `describe_change_set` until status is `CREATE_COMPLETE`
    - Inspect the change set: verify `Changes` lists the `AppBucket` resource as `Modify` action with `replacement` as `"False"` (in-place update; note the `Replacement` field in the API response is a string, not a boolean)
    - Print each change showing action, logical resource ID, resource type, and replacement status
    - _Requirements: 4.1_
  - [ ] 7.2 Execute the change set and verify the update
    - Call `execute_change_set("iac-learning-stack", "add-bucket-tags")`
    - Call `wait_for_stack("iac-learning-stack", "stack_update_complete")` and confirm the stack reaches `UPDATE_COMPLETE`
    - Call `describe_stack` to verify the updated stack status
    - Verify the S3 bucket now has the `Updated: true` tag: `aws s3api get-bucket-tagging --bucket <bucket-name>`
    - _Requirements: 4.2_
  - [ ]* 7.3 Test change set with no changes
    - **Property 3: No-Change Detection**
    - Create a change set using the same updated template again; confirm the change set status is `FAILED` with status reason indicating no changes detected
    - **Validates: Requirements 4.3**

- [ ] 8. Drift Detection and Infrastructure Integrity
  - [ ] 8.1 Verify IN_SYNC drift status
    - Call `initiate_drift_detection("iac-learning-stack")` and capture the detection ID
    - Call `wait_for_drift_detection(detection_id)` until detection completes
    - Call `get_stack_drift_status("iac-learning-stack")` and verify the drift status is `IN_SYNC`
    - _Requirements: 6.1_
  - [ ] 8.2 Introduce manual drift and detect it
    - Manually modify the S3 bucket outside of CloudFormation: `aws s3api put-bucket-tagging --bucket <bucket-name> --tagging 'TagSet=[{Key=ManualChange,Value=true}]'`
    - Call `initiate_drift_detection("iac-learning-stack")` again
    - Call `wait_for_drift_detection(detection_id)`
    - Call `get_stack_drift_status("iac-learning-stack")` and verify the drift status is `DRIFTED`
    - Call `get_resource_drift_details("iac-learning-stack")` and verify it identifies the AppBucket as `MODIFIED`, showing expected vs. actual property values and the property differences (the tag change)
    - Print the expected properties, actual properties, and property differences for each drifted resource
    - _Requirements: 6.2, 6.3_

- [ ] 9. Checkpoint - Full Lifecycle Validation
  - Confirm the stack is in `UPDATE_COMPLETE` status with all outputs accessible
  - Confirm drift detection correctly identified the manual tag change with expected vs. actual values
  - Review stack events using `get_stack_events` to trace the full history from creation through update
  - Confirm all three components (TemplateManager, StackManager, DriftDetector) were used successfully
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete the CloudFormation stack
    - Call `delete_stack("iac-learning-stack")` using StackManager
    - Call `wait_for_stack("iac-learning-stack", "stack_delete_complete")` and confirm the stack reaches `DELETE_COMPLETE`
    - If the stack enters `DELETE_FAILED` status, use `get_stack_events` to identify the failing resource, resolve the issue, and retry deletion
    - _Requirements: 7.1, 7.3_
  - [ ] 10.2 Verify all resources are removed
    - Verify the S3 bucket no longer exists: `aws s3 ls | grep <bucket-name>` should return nothing
    - Verify the SNS topic no longer exists: `aws sns list-topics` should not include the topic ARN
    - Verify the stack is gone: `aws cloudformation describe-stacks --stack-name iac-learning-stack` should return an error
    - Clean up any leftover test stacks from property tests (parameter rejection, rollback tests): `aws cloudformation delete-stack --stack-name <test-stack-name>` if applicable
    - _Requirements: 7.1, 7.2_
  - [ ] 10.3 Clean up local project files (optional)
    - Optionally remove the project directory if no longer needed
    - Confirm no AWS resources remain that could incur charges
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests that validate specific acceptance criteria through edge-case scenarios
- Each task references specific requirements for traceability (format: `_Requirements: X.Y_` where X is the requirement number and Y is the acceptance criterion)
- Checkpoints (Tasks 5 and 9) ensure incremental validation of progress before moving to the next phase
- The S3 bucket created by the stack must be empty before stack deletion; if objects were added manually, empty the bucket first with `aws s3 rm s3://<bucket-name> --recursive`
- All AWS resources are created within a single CloudFormation stack, so deleting the stack handles all resource cleanup
- If drift detection takes longer than expected, increase the polling interval and timeout in the `wait_for_drift_detection` implementation
