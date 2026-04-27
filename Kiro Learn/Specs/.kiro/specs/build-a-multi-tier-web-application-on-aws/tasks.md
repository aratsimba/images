

# Implementation Plan: Build a Multi-Tier Web Application on AWS

## Overview

This implementation plan guides the learner through building a serverless multi-tier web application on AWS, following a bottom-up approach that starts with the network foundation and progressively adds each architectural tier. The project is organized into phases: network infrastructure (VPC, subnets, security), data tier (DynamoDB), logic tier (Lambda functions with IAM), API layer (API Gateway with Cognito authentication), and presentation tier (S3, CloudFront). Each phase builds on the previous one, ensuring dependencies are satisfied before moving forward.

The key milestones are: (1) a fully configured VPC with multi-AZ subnets and security boundaries, (2) a functional data tier accessible only via VPC endpoint, (3) Lambda functions executing in private subnets with CRUD operations against DynamoDB, (4) a REST API with authentication routing requests to Lambda, and (5) a static frontend served via CloudFront communicating with the API. Checkpoints after the network/security setup and after the logic tier validate that foundational layers work before building higher tiers on top of them.

The implementation uses Python 3.12 with boto3 scripts organized into component modules matching the design document. Each component (NetworkManager, SecurityManager, DataTierManager, LogicTierManager, ApiTierManager, PresentationTierManager) is implemented as a separate Python module under `components/`. Lambda function handler code is packaged separately under `lambda_handlers/`. The learner will create a main orchestration script that wires the components together and stores deployment configuration for cross-component references.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for VPC, EC2, Lambda, API Gateway, DynamoDB, S3, CloudFront, Cognito, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Check VPC limit: `aws ec2 describe-vpcs` (ensure you have room for a new VPC)
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`; verify: `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 Project Structure and Region Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `mkdir -p components lambda_handlers static_assets`
    - Create `config.py` with region, VPC CIDR (`10.0.0.0/16`), subnet CIDRs, table name, and naming conventions
    - Define the `DeploymentConfig`, `VpcConfig`, `SecurityConfig`, and `AppItem` data models in `config.py` for use across all components
    - _Requirements: (all)_

- [ ] 2. VPC and Multi-Tier Network Infrastructure
  - [ ] 2.1 Create VPC, Subnets, and Gateways
    - Implement `components/network_manager.py` with the `NetworkManager` class
    - Implement `create_vpc(cidr_block, name)` to create VPC with CIDR `10.0.0.0/16` and tag it
    - Implement `enable_vpc_dns(vpc_id)` to enable DNS resolution and DNS hostnames on the VPC
    - Implement `create_subnet(vpc_id, cidr, az, name, public)` and create 6 subnets: 2 public (e.g., `10.0.1.0/24`, `10.0.2.0/24`), 2 private/logic (e.g., `10.0.3.0/24`, `10.0.4.0/24`), 2 isolated/data (e.g., `10.0.5.0/24`, `10.0.6.0/24`) across two AZs (e.g., `us-east-1a`, `us-east-1b`)
    - Implement `create_internet_gateway(vpc_id)` and attach it to the VPC
    - Implement `create_nat_gateway(subnet_id, name)` — allocate an Elastic IP and create a NAT gateway in each public subnet (one per AZ)
    - Verify VPC: `aws ec2 describe-vpcs --vpc-ids <vpc-id>`; verify subnets: `aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpc-id>`
    - _Requirements: 1.1, 1.2, 8.1, 8.2_
  - [ ] 2.2 Configure Route Tables and VPC Endpoint
    - Implement `create_route_table(vpc_id, name)` and `add_route(route_table_id, destination_cidr, gateway_id)` and `associate_subnet_to_route_table(subnet_id, route_table_id)`
    - Create public route table with `0.0.0.0/0 → IGW`, associate to both public subnets
    - Create two private/logic route tables (one per AZ) with `0.0.0.0/0 → NAT Gateway` for the corresponding AZ, associate to logic subnets
    - Create isolated/data route table with NO internet route, associate to both data subnets
    - Implement `create_vpc_endpoint(vpc_id, service_name, route_table_ids)` to create a gateway endpoint for DynamoDB (`com.amazonaws.<region>.dynamodb`) associated with logic-tier and data-tier route tables
    - Implement `get_vpc_summary(vpc_id)` to return a `VpcConfig` dictionary with all created resource IDs
    - Verify route tables: `aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-id>`
    - Verify VPC endpoint: `aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=<vpc-id>`
    - _Requirements: 1.3, 1.4, 3.3, 8.2_

- [ ] 3. Network Security Boundaries
  - [ ] 3.1 Create Security Groups for Each Tier
    - Implement `components/security_manager.py` with the `SecurityManager` class
    - Implement `create_security_group(vpc_id, name, description)` to create a security group and return its ID
    - Implement `add_ingress_rule(sg_id, protocol, port, source)` and `add_egress_rule(sg_id, protocol, port, destination)`
    - Create presentation-tier SG: allow inbound HTTPS (443) from `0.0.0.0/0`, allow outbound to logic-tier SG
    - Create logic-tier SG: allow inbound HTTPS (443) only from presentation-tier SG, allow outbound to data-tier SG and HTTPS outbound for NAT access
    - Create data-tier SG: allow inbound on DynamoDB port (443) only from logic-tier SG, deny all other inbound
    - Verify: `aws ec2 describe-security-groups --group-ids <sg-ids>`
    - _Requirements: 2.1, 2.2, 2.4_
  - [ ] 3.2 Configure Network ACLs for Subnet-Level Defense
    - Implement `create_network_acl(vpc_id, name)`, `add_nacl_rule(nacl_id, rule_number, protocol, port_range, cidr, egress, action)`, and `associate_nacl_to_subnet(nacl_id, subnet_id)`
    - Create public-tier NACL: allow inbound/outbound HTTPS and ephemeral ports
    - Create logic-tier NACL: allow inbound HTTPS from public subnet CIDRs, outbound HTTPS to data subnet CIDRs and NAT, ephemeral return ports
    - Create data-tier NACL: allow inbound HTTPS only from logic subnet CIDRs, deny traffic from public subnet CIDRs, allow outbound ephemeral return ports to logic subnets only
    - Implement `verify_tier_isolation(presentation_sg, logic_sg, data_sg)` to programmatically check that data-tier SG has no rules allowing presentation-tier SG or `0.0.0.0/0` inbound
    - Verify: `aws ec2 describe-network-acls --filters Name=vpc-id,Values=<vpc-id>`
    - _Requirements: 2.3, 2.4_

- [ ] 4. Checkpoint - Validate Network Infrastructure and Security
  - Verify VPC exists with DNS enabled: `aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsSupport`
  - Verify 6 subnets across 2 AZs: `aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpc-id> --query "Subnets[].{AZ:AvailabilityZone,CIDR:CidrBlock}"`
  - Verify NAT gateways in multiple AZs: `aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<vpc-id>`
  - Verify DynamoDB VPC endpoint exists: `aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=<vpc-id>`
  - Run `verify_tier_isolation()` and confirm data-tier SG blocks direct access from presentation tier
  - Confirm isolated/data route table has no `0.0.0.0/0` route
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Data Tier - DynamoDB Table
  - [ ] 5.1 Create DynamoDB Table and Verify Operations
    - Implement `components/data_tier_manager.py` with the `DataTierManager` class using `boto3.resource('dynamodb')`
    - Implement `create_table(table_name, partition_key, sort_key)` to create a table with partition key `user_id` (S) and sort key `item_id` (S), using on-demand billing mode (`PAY_PER_REQUEST`)
    - Implement `wait_until_active(table_name)` using the DynamoDB table waiter
    - Implement CRUD methods: `put_item`, `get_item`, `update_item`, `delete_item`, `query_items` matching the `AppItem` data model (user_id, item_id, title, description, status, created_at, updated_at)
    - Implement `delete_table(table_name)` for cleanup
    - Test locally: create table, put an item, get it back, query by partition key, update it, delete it
    - Verify: `aws dynamodb describe-table --table-name <table-name>` confirms `ACTIVE` status and `PAY_PER_REQUEST` billing
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 6. Logic Tier - Lambda Functions in VPC
  - [ ] 6.1 Create IAM Execution Role and Lambda Handler Code
    - Implement `components/logic_tier_manager.py` with the `LogicTierManager` class
    - Implement `create_execution_role(role_name, dynamodb_table_arn)`: create IAM role with Lambda trust policy, attach inline policy granting only `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:UpdateItem`, `dynamodb:DeleteItem`, `dynamodb:Query` on the specific table ARN, plus `ec2:CreateNetworkInterface`, `ec2:DescribeNetworkInterfaces`, `ec2:DescribeSubnets`, `ec2:DeleteNetworkInterface`, `ec2:AssignPrivateIpAddresses`, `ec2:UnassignPrivateIpAddresses` for VPC ENI management, and `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` for CloudWatch
    - Implement `wait_for_role_propagation(role_arn)` with a 10-second sleep to allow IAM propagation
    - Create Lambda handler files in `lambda_handlers/`: `create_item.py`, `get_item.py`, `update_item.py`, `delete_item.py`, `list_items.py` — each handler reads from event, performs the DynamoDB operation, returns a `LambdaResponse` with status_code, headers, and JSON body; invalid inputs return 400 with a generic error message (no internal details)
    - Implement `package_lambda_code(handler_file)` using `zipfile` to create in-memory zip bytes
    - Verify role: `aws iam get-role --role-name <role-name>`
    - _Requirements: 4.2, 4.3, 4.4_
  - [ ] 6.2 Deploy and Test Lambda Functions
    - Implement `create_function(function_name, role_arn, handler, zip_bytes, subnet_ids, security_group_id, environment_vars)`: deploy Lambda with Python 3.12 runtime, 256MB memory, 30s timeout, VPC config using logic-tier subnet IDs and logic-tier security group, environment variable `TABLE_NAME`
    - Deploy 5 Lambda functions (create, get, update, delete, list) into the logic-tier private subnets
    - Implement `invoke_function(function_name, payload)` and `delete_function(function_name)` and `delete_execution_role(role_name)`
    - Test each function via `invoke_function`: verify create returns 201, get returns 200 with item data, update returns 200, delete returns 200, list returns array; verify invalid input returns 400
    - Verify: `aws lambda get-function --function-name <name>` shows VPC configuration with correct subnet IDs and security group
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 8.3_

- [ ] 7. Checkpoint - Validate Data and Logic Tiers
  - Invoke create Lambda function with a test `AppItem` payload and verify 201 response
  - Invoke get Lambda function and verify it retrieves the created item from DynamoDB
  - Invoke list Lambda function with a partition key and verify it returns items
  - Invoke update Lambda function and verify the item is modified
  - Invoke delete Lambda function and verify the item is removed
  - Invoke a Lambda function with malformed input and verify it returns a 400 error without internal details
  - Verify Lambda functions are running in private subnets: `aws lambda get-function-configuration --function-name <name> --query "VpcConfig"`
  - Verify DynamoDB traffic uses VPC endpoint (Lambda in private subnet with no internet route can still reach DynamoDB)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. API Gateway with Cognito Authentication
  - [ ] 8.1 Create Cognito User Pool and App Client
    - Implement `components/presentation_tier_manager.py` with the `PresentationTierManager` class
    - Implement `create_cognito_user_pool(pool_name, password_policy)`: create user pool with email as username attribute, email verification required, password policy (minimum 8 chars, require uppercase, lowercase, numbers, special characters)
    - Implement `create_cognito_app_client(user_pool_id, client_name)`: create app client with `ALLOW_USER_PASSWORD_AUTH` and `ALLOW_REFRESH_TOKEN_AUTH` flows
    - Implement `get_user_pool_arn(user_pool_id)` to retrieve the ARN for API Gateway authorizer configuration
    - Verify: `aws cognito-idp describe-user-pool --user-pool-id <id>`
    - _Requirements: 7.1_
  - [ ] 8.2 Create REST API with Resources, Methods, and Authorizer
    - Implement `components/api_tier_manager.py` with the `ApiTierManager` class
    - Implement `create_rest_api(api_name)` and `get_root_resource_id(api_id)`
    - Implement `create_resource(api_id, parent_id, path_part)`: create `/items` and `/items/{item_id}` resources
    - Implement `create_request_model(api_id, model_name, schema)`: create a JSON schema model for item creation/update requests requiring `title` and `description` fields
    - Implement `create_cognito_authorizer(api_id, user_pool_arn)`: create a Cognito authorizer that validates JWT tokens from the Authorization header
    - Implement `create_method_with_lambda(api_id, resource_id, http_method, lambda_arn, model_name, authorizer_id)`: create methods (POST /items → create, GET /items → list, GET /items/{item_id} → get, PUT /items/{item_id} → update, DELETE /items/{item_id} → delete) with Lambda proxy integration, request validation using the model, and Cognito authorizer; grant API Gateway permission to invoke each Lambda function via `lambda:add-permission`
    - Implement `configure_cors(api_id, resource_id, allowed_origin)`: add OPTIONS method with CORS headers for each resource, restricting `Access-Control-Allow-Origin` to the CloudFront domain (use `*` initially, update after CloudFront creation)
    - Implement `deploy_api(api_id, stage_name)`: deploy to a `prod` stage and return the invoke URL
    - Implement `delete_rest_api(api_id)` for cleanup
    - Verify: `aws apigateway get-rest-api --rest-api-id <id>`; test invoke URL returns 401 without auth token
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 7.2, 7.3_

- [ ] 9. Presentation Tier - S3, CloudFront, and Static Frontend
  - [ ] 9.1 Create S3 Bucket and CloudFront Distribution
    - Implement `create_s3_bucket(bucket_name, region)` with a unique bucket name
    - Implement `block_public_access(bucket_name)` to enable all Block Public Access settings
    - Implement `create_origin_access_control(name)` for CloudFront S3 origin type
    - Implement `create_cloudfront_distribution(bucket_name, oac_id)`: create distribution with S3 origin using OAC, default root object `index.html`, viewer protocol policy `redirect-to-https` (uses default CloudFront certificate for HTTPS)
    - Implement `set_bucket_policy_for_cloudfront(bucket_name, distribution_arn)`: set S3 bucket policy allowing `s3:GetObject` only from the CloudFront distribution's service principal
    - Verify: `aws s3api get-public-access-block --bucket <name>` shows all blocks enabled; `aws cloudfront get-distribution --id <dist-id>` shows OAC configured
    - _Requirements: 6.1, 6.2, 6.4_
  - [ ] 9.2 Build and Deploy Static Frontend Assets
    - Create `static_assets/index.html`: single-page application with login form, item CRUD interface
    - Create `static_assets/app.js`: JavaScript that integrates with Cognito for sign-up/sign-in (using Cognito hosted UI or direct API calls), stores JWT token, sends authenticated requests to API Gateway endpoints with `Authorization` header, displays items
    - Create `static_assets/style.css`: basic styling for the application
    - Configure `app.js` with the API Gateway invoke URL, Cognito user pool ID, and app client ID
    - Implement `upload_static_assets(bucket_name, assets_directory)`: upload all files from `static_assets/` to S3 with correct content types (`text/html`, `application/javascript`, `text/css`)
    - Update CORS configuration on API Gateway to restrict `Access-Control-Allow-Origin` to the CloudFront distribution domain (`https://<dist-id>.cloudfront.net`)
    - Implement `delete_cognito_user_pool(user_pool_id)`, `delete_s3_bucket(bucket_name)` (empty and delete), `delete_cloudfront_distribution(distribution_id)` (disable then delete) for cleanup
    - Verify: access `https://<cloudfront-domain>/` in browser loads the application; verify S3 direct URL returns 403
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.2, 8.3_

- [ ] 10. Checkpoint - End-to-End Application Validation
  - Access the CloudFront URL in a browser and verify the static site loads over HTTPS
  - Attempt to access S3 bucket URL directly and verify it returns 403 (Access Denied)
  - Register a new user through the Cognito-integrated sign-up flow and verify email verification
  - Sign in and verify a JWT token is obtained
  - Create an item through the frontend and verify it appears in DynamoDB: `aws dynamodb scan --table-name <table-name>`
  - Attempt an API call without an auth token and verify the API Gateway returns 401 Unauthorized
  - Verify CORS: open browser developer tools, confirm no CORS errors on API calls from the CloudFront domain
  - Verify multi-AZ deployment: confirm subnets span 2 AZs, NAT gateways exist in 2 AZs, serverless services are inherently multi-AZ
  - Verify tier isolation: confirm presentation tier communicates only via API Gateway, not directly to DynamoDB
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Delete Presentation and API Tier Resources
    - Disable and delete CloudFront distribution: `aws cloudfront get-distribution-config --id <dist-id>`, update with `Enabled: false`, wait for deployment, then `aws cloudfront delete-distribution --id <dist-id> --if-match <etag>`
    - Empty and delete S3 bucket: `aws s3 rm s3://<bucket-name> --recursive` then `aws s3api delete-bucket --bucket <bucket-name>`
    - Delete Cognito user pool: `aws cognito-idp delete-user-pool --user-pool-id <id>`
    - Delete REST API: `aws apigateway delete-rest-api --rest-api-id <api-id>`
    - _Requirements: (all)_
  - [ ] 11.2 Delete Logic and Data Tier Resources
    - Delete all Lambda functions: `aws lambda delete-function --function-name <name>` for each function (create, get, update, delete, list)
    - Delete IAM execution role: detach/delete inline policies first, then `aws iam delete-role --role-name <role-name>`
    - Delete DynamoDB table: `aws dynamodb delete-table --table-name <table-name>`
    - _Requirements: (all)_
  - [ ] 11.3 Delete Network Infrastructure Resources
    - Delete VPC endpoint: `aws ec2 delete-vpc-endpoints --vpc-endpoint-ids <endpoint-id>`
    - Delete NAT gateways (⚠️ these incur hourly charges): `aws ec2 delete-nat-gateway --nat-gateway-id <id>` for each; wait for deletion
    - Release Elastic IPs: `aws ec2 release-address --allocation-id <alloc-id>` for each
    - Delete security groups (logic, data, presentation): `aws ec2 delete-security-group --group-id <sg-id>`
    - Delete custom network ACLs: `aws ec2 delete-network-acl --network-acl-id <nacl-id>` for each
    - Disassociate and delete route tables: `aws ec2 disassociate-route-table --association-id <id>` then `aws ec2 delete-route-table --route-table-id <id>`
    - Delete subnets: `aws ec2 delete-subnet --subnet-id <id>` for all 6 subnets
    - Detach and delete internet gateway: `aws ec2 detach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>` then `aws ec2 delete-internet-gateway --internet-gateway-id <igw-id>`
    - Delete VPC: `aws ec2 delete-vpc --vpc-id <vpc-id>`
    - Verify: `aws ec2 describe-vpcs --vpc-ids <vpc-id>` should return not found; `aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<vpc-id>` should show only deleted status
    - ⚠️ **Warning**: NAT gateways and Elastic IPs incur charges if not deleted. Verify all are removed.
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability (format: `_Requirements: X.Y_` where X is the requirement number and Y is the acceptance criteria number)
- Checkpoints (Tasks 4, 7, 10) ensure incremental validation at key milestones: after network setup, after data/logic tiers, and after full end-to-end integration
- NAT gateways incur hourly charges (~$0.045/hr each) — complete the project promptly and run cleanup to avoid unnecessary costs
- The Cognito user pool and CloudFront distribution are both implemented in `PresentationTierManager` as specified in the design document
- Lambda functions may take several minutes to become active after initial deployment due to VPC ENI creation; allow time before testing
- CloudFront distributions can take 10-15 minutes to deploy; wait for status `Deployed` before testing the frontend
