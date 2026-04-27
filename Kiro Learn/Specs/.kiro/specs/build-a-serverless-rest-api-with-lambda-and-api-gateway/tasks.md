

# Implementation Plan: Serverless REST API with Lambda and API Gateway

## Overview

This implementation plan guides you through building a serverless REST API using AWS Lambda, Amazon API Gateway, and Amazon DynamoDB. The approach follows a layered dependency order: first establishing the data persistence layer (DynamoDB), then configuring the security layer (IAM), building the compute layer (Lambda functions), wiring it together through the API layer (API Gateway), and finally deploying and validating the complete system end-to-end.

The plan is organized into three major phases. Phase 1 covers infrastructure foundations — creating the DynamoDB table and IAM execution role with least-privilege permissions. Phase 2 covers application logic — writing the Lambda function handlers for create, read, and delete operations, packaging them, and deploying them alongside the API Gateway REST API with resources, methods, Lambda proxy integration, and CORS. Phase 3 covers deployment, end-to-end testing, and cleanup. Checkpoints after the infrastructure phase and after API deployment ensure incremental validation before moving forward.

Key dependencies drive the task ordering: the DynamoDB table must exist before the IAM policy can reference its ARN, the IAM role must exist before Lambda functions can be created, Lambda functions must be deployed before API Gateway methods can integrate with them, and the API must be deployed to a stage before end-to-end testing can occur. All provisioning is done via Python scripts using the boto3 SDK, and testing uses the `requests` library against the live invoke URL.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with admin access
    - Configure AWS CLI: `aws configure` (set access key, secret key, region)
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Install requests library: `pip install requests`
    - _Requirements: (all)_
  - [ ] 1.3 Project Structure and Region Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `components/`, `lambda_functions/create_item/`, `lambda_functions/get_item/`, `lambda_functions/delete_item/`
    - Verify boto3 connectivity: `python3 -c "import boto3; print(boto3.client('sts').get_caller_identity())"`
    - _Requirements: (all)_

- [ ] 2. DynamoDB Table and IAM Role Setup
  - [ ] 2.1 Create DynamoDB table for API data persistence
    - Create `components/dynamodb_setup.py` implementing the `DynamoDBSetup` interface
    - Implement `create_table(table_name, partition_key)` using `boto3.resource('dynamodb')` with `id` as the partition key (type `S`), `BillingMode='PAY_PER_REQUEST'` (on-demand capacity)
    - Implement `wait_until_active(table_name)` using `table.meta.client.get_waiter('table_exists')`
    - Implement `get_table_arn(table_name)` to retrieve the table ARN for IAM policy scoping
    - Implement `delete_table(table_name)` for cleanup
    - Run the script and verify: `aws dynamodb describe-table --table-name Items --query 'Table.TableStatus'` returns `"ACTIVE"`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Create IAM execution role with least-privilege permissions
    - Create `components/iam_role_setup.py` implementing the `IAMRoleSetup` interface
    - Implement `create_lambda_execution_role(role_name)` with an assume-role trust policy for `lambda.amazonaws.com`
    - Implement `attach_cloudwatch_logs_policy(role_name)` — attach the `AWSLambdaBasicExecutionRole` managed policy for CloudWatch Logs
    - Implement `attach_dynamodb_policy(role_name, table_arn)` — create and attach an inline policy granting `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:DeleteItem`, `dynamodb:Scan` scoped to the specific table ARN only
    - Implement `get_role_arn(role_name)` and `delete_role(role_name)` (detach policies before deletion)
    - Add a 10-second wait after role creation for IAM propagation
    - Verify: `aws iam get-role --role-name lambda-api-role` and `aws iam list-attached-role-policies --role-name lambda-api-role`
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 3. Checkpoint - Validate Infrastructure Layer
  - Confirm DynamoDB table is in `ACTIVE` status: `aws dynamodb describe-table --table-name Items`
  - Confirm table uses on-demand billing: check `BillingModeSummary.BillingMode` equals `PAY_PER_REQUEST`
  - Confirm IAM role exists with correct trust policy for `lambda.amazonaws.com`
  - Confirm CloudWatch Logs policy is attached to the role
  - Confirm DynamoDB inline policy is scoped to the specific table ARN (not `*`)
  - Test that the role cannot access other tables by verifying the policy document
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Lambda Function Handlers
  - [ ] 4.1 Implement CreateItem handler
    - Create `lambda_functions/create_item/handler.py` implementing the `CreateItemHandler` interface
    - Parse `event['body']` (JSON string) to extract item fields (`id`, `name`, `description`, `price`)
    - Validate required fields (`id`, `name`, `price`) — return `400` with error message if missing
    - Generate `created_at` as ISO 8601 timestamp using `datetime.utcnow().isoformat()`
    - Write item to DynamoDB using `table.put_item(Item=item)`
    - Return `LambdaProxyResponse` with `statusCode: 201`, CORS headers (`Access-Control-Allow-Origin: *`), and JSON-serialized body containing the created item
    - Handle exceptions and return `500` with meaningful error message
    - _Requirements: 2.1, 6.4_
  - [ ] 4.2 Implement GetItem handler
    - Create `lambda_functions/get_item/handler.py` implementing the `GetItemHandler` interface
    - Extract `id` from `event['pathParameters']`
    - Call `table.get_item(Key={'id': item_id})` and check for `'Item'` in response
    - Return `200` with item data if found, or `404` with `{"message": "Item not found"}` if not found
    - Include CORS headers in all responses; handle `Decimal` serialization for `price` field
    - _Requirements: 2.2, 2.4_
  - [ ] 4.3 Implement DeleteItem handler
    - Create `lambda_functions/delete_item/handler.py` implementing the `DeleteItemHandler` interface
    - Extract `id` from `event['pathParameters']`
    - First check if item exists with `get_item`, return `404` if not found
    - Call `table.delete_item(Key={'id': item_id})` and return `200` with confirmation message
    - Include CORS headers in all responses
    - _Requirements: 2.3, 2.4_

- [ ] 5. Lambda Function Deployment
  - [ ] 5.1 Implement Lambda deployer component
    - Create `components/lambda_deployer.py` implementing the `LambdaDeployer` interface
    - Implement `package_function_code(source_dir)` to create an in-memory zip archive of the handler directory using `zipfile` module
    - Implement `create_function(function_name, role_arn, handler, zip_bytes, env_vars)` using `boto3.client('lambda').create_function()` with `Runtime='python3.12'`, `Timeout=30`, `MemorySize=128`
    - Pass `TABLE_NAME` as an environment variable so handlers reference the correct DynamoDB table
    - Implement `get_function_arn(function_name)` and `delete_function(function_name)`
    - Implement `add_api_gateway_permission(function_name, source_arn)` using `add_permission()` with `Principal='apigateway.amazonaws.com'`
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 5.2 Deploy all three Lambda functions
    - Deploy `CreateItemFunction` with handler `handler.handler` from `lambda_functions/create_item/`
    - Deploy `GetItemFunction` with handler `handler.handler` from `lambda_functions/get_item/`
    - Deploy `DeleteItemFunction` with handler `handler.handler` from `lambda_functions/delete_item/`
    - Verify each function: `aws lambda get-function --function-name CreateItemFunction`
    - Test each function locally with `aws lambda invoke` using a sample proxy integration event JSON
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 6. API Gateway REST API Configuration
  - [ ] 6.1 Create REST API with resource structure
    - Create `components/api_gateway_setup.py` implementing the `APIGatewaySetup` interface
    - Implement `create_rest_api(api_name)` to create the REST API and return the `api_id`
    - Implement `get_root_resource_id(api_id)` to retrieve the root `/` resource
    - Implement `create_resource(api_id, parent_id, path_part)` — create `/items` resource under root, then `/items/{id}` child resource with `{id}` path parameter
    - Verify: `aws apigateway get-resources --rest-api-id <api-id>` shows `/items` and `/items/{id}`
    - _Requirements: 4.1, 4.2_
  - [ ] 6.2 Configure methods with Lambda proxy integration and CORS
    - Implement `create_method_with_lambda_integration(api_id, resource_id, http_method, lambda_arn)` using `put_method()` with `AuthorizationType='NONE'` and `put_integration()` with `Type='AWS_PROXY'`, `integrationHttpMethod='POST'`, and Lambda function URI
    - Configure methods: `POST` on `/items` → `CreateItemFunction`, `GET` on `/items/{id}` → `GetItemFunction`, `DELETE` on `/items/{id}` → `DeleteItemFunction`
    - Add API Gateway invoke permissions to each Lambda function using `add_api_gateway_permission()`
    - Implement `enable_cors(api_id, resource_id, methods)` — add `OPTIONS` method with mock integration, configure `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers` response headers on both `/items` and `/items/{id}` resources
    - Verify method configuration: `aws apigateway get-method --rest-api-id <api-id> --resource-id <id> --http-method POST`
    - _Requirements: 4.3, 4.4_
  - [ ] 6.3 Deploy API to stage and obtain invoke URL
    - Implement `deploy_api(api_id, stage_name)` using `create_deployment()` with stage name `dev`
    - Implement `get_invoke_url(api_id, stage_name)` returning `https://{api_id}.execute-api.{region}.amazonaws.com/{stage_name}`
    - Implement `delete_rest_api(api_id)` for cleanup
    - Verify deployment: `aws apigateway get-stage --rest-api-id <api-id> --stage-name dev`
    - Record the invoke URL for testing (e.g., `https://abc123.execute-api.us-east-1.amazonaws.com/dev`)
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 7. Checkpoint - Validate API Deployment
  - Confirm all three Lambda functions are deployed and invocable: `aws lambda invoke --function-name GetItemFunction output.json`
  - Confirm REST API has correct resources: `aws apigateway get-resources --rest-api-id <api-id>`
  - Confirm API is deployed to `dev` stage with a valid invoke URL
  - Test a simple GET request to the invoke URL: `curl https://<api-id>.execute-api.<region>.amazonaws.com/dev/items/test-id`
  - Verify CORS headers appear in OPTIONS response
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. End-to-End API Testing
  - [ ] 8.1 Implement API test suite
    - Create `components/api_tester.py` implementing the `APITester` interface
    - Implement `test_create_item(base_url, item)` — send `POST` to `{base_url}/items` with JSON body containing `id`, `name`, `price`, `description`; assert `201` status and item in response
    - Implement `test_get_item(base_url, item_id)` — send `GET` to `{base_url}/items/{item_id}`; assert `200` status and correct item attributes
    - Implement `test_get_nonexistent_item(base_url, item_id)` — send `GET` with a non-existent ID; assert `404` status
    - Implement `test_delete_item(base_url, item_id)` — send `DELETE` to `{base_url}/items/{item_id}`; assert `200` status; then `GET` same ID and assert `404`
    - Implement `test_malformed_request(base_url, payload)` — send `POST` with invalid/incomplete JSON; assert `400` status with meaningful error message
    - Implement `run_all_tests(base_url)` to execute all tests in sequence and return `List[TestResult]`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - [ ] 8.2 Run full test suite and validate results
    - Execute `run_all_tests()` against the deployed invoke URL
    - Verify created item exists in DynamoDB: `aws dynamodb get-item --table-name Items --key '{"id": {"S": "test-123"}}'`
    - Verify deleted item no longer exists in DynamoDB after delete test
    - Confirm all test cases pass and print a summary of results
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - [ ]* 8.3 Property test for API idempotency and error handling
    - **Property 1: Non-existent item returns 404 consistently**
    - **Validates: Requirements 2.4, 6.4**

- [ ] 9. Checkpoint - Full System Validation
  - Verify the complete CRUD lifecycle: create → read → delete → confirm deletion
  - Confirm CORS headers present in all API responses
  - Verify CloudWatch Logs contain Lambda execution logs: `aws logs describe-log-groups --log-group-name-prefix /aws/lambda/`
  - Confirm that modifying API configuration without redeploying does not change the live stage behavior
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete API Gateway and Lambda resources
    - Delete REST API: `aws apigateway delete-rest-api --rest-api-id <api-id>`
    - Delete Lambda functions: `aws lambda delete-function --function-name CreateItemFunction`, `aws lambda delete-function --function-name GetItemFunction`, `aws lambda delete-function --function-name DeleteItemFunction`
    - Verify Lambda functions are deleted: `aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `CreateItem`) || starts_with(FunctionName, `GetItem`) || starts_with(FunctionName, `DeleteItem`)]'`
    - _Requirements: (all)_
  - [ ] 10.2 Delete DynamoDB table and IAM role
    - Delete DynamoDB table: `aws dynamodb delete-table --table-name Items`
    - Wait for table deletion: `aws dynamodb wait table-not-exists --table-name Items`
    - Detach policies from IAM role: `aws iam detach-role-policy --role-name lambda-api-role --policy-arn <policy-arn>` and delete inline policies: `aws iam delete-role-policy --role-name lambda-api-role --policy-name <policy-name>`
    - Delete IAM role: `aws iam delete-role --role-name lambda-api-role`
    - _Requirements: (all)_
  - [ ] 10.3 Verify cleanup
    - Verify no Lambda functions remain: `aws lambda list-functions` (confirm none with project prefixes)
    - Verify DynamoDB table is deleted: `aws dynamodb list-tables`
    - Verify IAM role is removed: `aws iam get-role --role-name lambda-api-role` (should return NoSuchEntity)
    - Verify API Gateway is removed: `aws apigateway get-rest-apis` (confirm project API is gone)
    - Check CloudWatch Log groups — optionally delete: `aws logs delete-log-group --log-group-name /aws/lambda/CreateItemFunction`
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at the infrastructure layer (Task 3), after API deployment (Task 7), and after full system testing (Task 9)
- IAM role propagation may take 10-15 seconds after creation — the deployment script should include a delay before creating Lambda functions
- DynamoDB `Decimal` types require custom JSON serialization in Lambda handlers — use `decimal.Decimal` to `float` conversion in responses
- The `requests` library is used for end-to-end testing against the live invoke URL rather than AWS SDK calls, simulating real client behavior
- All resource names (table name, role name, function names, API name) should be configurable via a shared configuration file or constants module to avoid hardcoding
