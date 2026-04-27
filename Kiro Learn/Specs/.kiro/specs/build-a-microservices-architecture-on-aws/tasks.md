

# Implementation Plan: Build a Microservices Architecture on AWS

## Overview

This implementation plan guides you through building a microservices architecture on AWS using AWS CDK (Python). The project deploys three independently deployable microservices — a user service (Lambda), a topic service (EC2), and a message service (ECS Fargate) — behind an Application Load Balancer with path-based routing. Each service owns a dedicated DynamoDB table, and asynchronous inter-service communication is implemented via SNS and SQS. Centralized logging and monitoring tie the distributed system together through CloudWatch.

The plan follows a layered dependency order: environment setup, then networking and load balancing infrastructure, followed by each microservice deployment, then the cross-cutting concerns of messaging and monitoring, and finally validation of independent deployment and resilience. AWS CDK stacks are structured to match the six design components (NetworkStack, LoadBalancerStack, UserServiceStack, TopicServiceStack, MessageServiceStack, MessagingAndMonitoringStack), enabling clean separation and independent deployability.

Key milestones include: (1) a working VPC with ALB routing to three target groups, (2) all three microservices deployed and responding to health checks, (3) async event flow from topic creation through SNS/SQS to the message service, and (4) centralized monitoring with a unified CloudWatch dashboard. Two checkpoints validate incremental progress. The final task ensures all provisioned resources are torn down to avoid ongoing costs.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for VPC, EC2, ECS, ECR, Lambda, DynamoDB, SNS, SQS, CloudWatch, IAM, and Elastic Load Balancing
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install Docker Desktop: verify with `docker --version`
    - Install AWS CDK v2: `npm install -g aws-cdk` and verify with `cdk --version`
    - Install Python dependencies: `pip install aws-cdk-lib constructs boto3`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and CDK Bootstrap
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Bootstrap CDK: `cdk bootstrap aws://ACCOUNT_ID/us-east-1`
    - Initialize CDK project: `cdk init app --language python` in a new project directory
    - Create directory structure: `stacks/`, `services/user_service/`, `services/topic_service/`, `services/message_service/`
    - Verify CDK synthesizes: `cdk synth`
    - _Requirements: (all)_

- [ ] 2. Networking and Security Infrastructure (NetworkStack)
  - [ ] 2.1 Create VPC with Public and Private Subnets
    - Create `stacks/network_stack.py` implementing the NetworkStack component
    - Call `create_vpc` with CIDR `10.0.0.0/16` and `az_count=2` using `aws_cdk.aws_ec2.Vpc`
    - Call `create_public_subnets` and `create_private_subnets` across two AZs (CDK Vpc construct handles this with `subnet_configuration`)
    - Call `create_nat_gateway` — configure NAT Gateway in a public subnet for private subnet outbound internet access
    - Verify private subnets route outbound traffic through the NAT Gateway
    - _Requirements: 7.1, 7.2_
  - [ ] 2.2 Create Security Groups for All Services
    - Call `create_alb_security_group` — allow inbound HTTP (port 80) from `0.0.0.0/0`
    - Call `create_service_security_group` for Lambda (no specific SG needed for Lambda, but create for ALB target integration)
    - Call `create_service_security_group` for EC2 — name `topic-service-sg`, allow inbound on port 8080 only from ALB security group
    - Call `create_service_security_group` for ECS — name `message-service-sg`, allow inbound on port 8080 only from ALB security group
    - Verify no security group allows direct internet inbound to compute resources
    - _Requirements: 7.3, 7.4, 4.4_

- [ ] 3. Load Balancer with Path-Based Routing (LoadBalancerStack)
  - [ ] 3.1 Create Application Load Balancer and Listener
    - Create `stacks/load_balancer_stack.py` implementing the LoadBalancerStack component
    - Call `create_alb` — deploy ALB in public subnets across two AZs, attach ALB security group
    - Call `create_listener` — create HTTP listener on port 80 with default fixed-response action returning 404 and body `{"error": "Path not found"}`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 3.2 Create Target Groups with Health Checks
    - Call `create_lambda_target_group` — create target group for `/users/*` path pattern with Lambda target type
    - Call `create_instance_target_group` — create target group for `/topics/*` path pattern, port 8080, health check path `/topics/health`
    - Call `create_ecs_target_group` — create target group for `/messages/*` path pattern, port 8080, health check path `/messages/health`
    - Configure health check intervals and healthy/unhealthy thresholds for each target group
    - Export target group ARNs and ALB DNS name as stack outputs for use by service stacks
    - _Requirements: 1.1, 1.4_

- [ ] 4. User Service - Serverless Lambda Microservice (UserServiceStack)
  - [ ] 4.1 Create DynamoDB Table and Lambda Function
    - Create `stacks/user_service_stack.py` implementing the UserServiceStack component
    - Call `create_users_table` — create DynamoDB table `ForumUsers` with partition key `user_id` (String), matching the `User` data model (user_id, username, email, created_at)
    - Create Lambda handler at `services/user_service/handler.py` implementing CRUD operations for users (GET, POST) and a health check endpoint
    - Parse ALB event format: extract `path` and `httpMethod`, route to appropriate handler
    - Call `create_lambda_role` — create IAM execution role with policies for DynamoDB read/write on the Users table ARN only, and CloudWatch Logs write
    - Call `create_lambda_function` — runtime Python 3.12, handler `handler.handler`, 256MB memory, 30s timeout, environment variables for `TABLE_NAME` (note: `AWS_REGION` is a reserved Lambda environment variable automatically provided by the runtime and cannot be set as a custom variable)
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 4.2 Register Lambda with ALB Target Group
    - Call `register_with_target_group` — add Lambda function as target in the `/users/*` target group
    - Grant ALB permission to invoke the Lambda function (CDK handles this with `LambdaTarget`)
    - Verify Lambda is invocable through ALB: `curl http://<ALB_DNS>/users/health`
    - _Requirements: 2.1, 2.4_

- [ ] 5. Topic Service - EC2 Microservice (TopicServiceStack)
  - [ ] 5.1 Create DynamoDB Table, Instance Role, and EC2 Instance
    - Create `stacks/topic_service_stack.py` implementing the TopicServiceStack component
    - Call `create_topics_table` — create DynamoDB table `ForumTopics` with partition key `topic_id` (String), matching the `Topic` data model (topic_id, title, author_user_id, created_at)
    - Call `create_instance_role` — create IAM role with policies for DynamoDB read/write on Topics table, SNS publish on the event topic ARN, CloudWatch agent permissions, and SSM for Session Manager access
    - Call `create_user_data_script` — generate user data script that installs Python/pip, installs Flask/boto3, deploys the topic service app, installs and configures CloudWatch agent, and starts the application on port 8080
    - Create topic service application at `services/topic_service/app.py` — Flask app with CRUD endpoints for `/topics/*`, health check at `/topics/health`, and SNS publish on topic creation (publishing `TopicCreatedEvent` data model)
    - Call `create_ec2_instance` — Amazon Linux 2023 AMI, `t3.micro`, placed in a private subnet, attach topic-service security group and instance role
    - _Requirements: 4.1, 4.2, 4.3, 5.2, 6.4_
  - [ ] 5.2 Register EC2 with ALB Target Group
    - Call `register_with_target_group` — add EC2 instance to the `/topics/*` target group
    - Verify instance passes health checks: check target group health in AWS Console or CLI
    - Verify the instance is NOT directly accessible from the internet (private subnet, SG restricts to ALB only)
    - _Requirements: 4.1, 4.4, 7.4_

- [ ] 6. Checkpoint - Validate Networking, ALB Routing, and First Two Services
  - Deploy stacks so far: `cdk deploy NetworkStack LoadBalancerStack UserServiceStack TopicServiceStack`
  - Test path-based routing: `curl http://<ALB_DNS>/users/health` returns healthy response
  - Test topic service: `curl http://<ALB_DNS>/topics/health` returns healthy response
  - Test default route: `curl http://<ALB_DNS>/nonexistent` returns 404 fixed response
  - Verify DynamoDB tables exist: `aws dynamodb list-tables`
  - Test CRUD: POST a user to `/users` and GET it back; POST a topic to `/topics` and GET it back
  - Verify EC2 instance is in private subnet and unreachable directly from internet
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Message Service - ECS Fargate Microservice (MessageServiceStack)
  - [ ] 7.1 Build and Push Container Image to ECR
    - Create `stacks/message_service_stack.py` implementing the MessageServiceStack component
    - Call `create_ecr_repository` — create private ECR repository `forum-message-service`
    - Create `services/message_service/app.py` — Flask/FastAPI app with CRUD endpoints for `/messages/*`, health check at `/messages/health`, and SQS polling logic for async events, matching the `Message` data model (message_id, topic_id, author_user_id, body, created_at) with a GSI on `topic_id`
    - Create `services/message_service/Dockerfile` — Python 3.12 slim base image, install dependencies, expose port 8080
    - Build and push image: `docker build -t forum-message-service .` then tag and push to ECR (or use CDK `DockerImageAsset`)
    - _Requirements: 3.1_
  - [ ] 7.2 Create ECS Cluster, Task Definition, and Fargate Service
    - Call `create_messages_table` — create DynamoDB table `ForumMessages` with partition key `message_id` (String) and GSI on `topic_id`
    - Call `create_ecs_cluster` — create ECS cluster `forum-cluster` in the VPC
    - Call `create_task_definition` — family `message-service`, 256 CPU, 512 memory, environment variables for `TABLE_NAME`, `QUEUE_URL`, configure `awslogs` log driver pointing to the message service CloudWatch log group
    - Create task execution role with ECR pull and CloudWatch Logs permissions; create task role with DynamoDB read/write on Messages table and SQS receive/delete on event queue
    - Call `create_fargate_service` — desired count 2, distribute across private subnets in two AZs, attach message-service security group
    - Call `register_with_target_group` — register service with the `/messages/*` target group on container port 8080, configure deregistration delay for rolling updates
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 8. Messaging and Monitoring (MessagingAndMonitoringStack)
  - [ ] 8.1 Create SNS Topic, SQS Queue, and Dead-Letter Queue
    - Create `stacks/messaging_monitoring_stack.py` implementing the MessagingAndMonitoringStack component
    - Call `create_dead_letter_queue` — create DLQ `forum-events-dlq`
    - Call `create_event_sqs_queue` — create SQS queue `forum-events-queue` subscribed to the SNS topic, with `max_receive_count=3` before moving to DLQ
    - Call `create_event_sns_topic` — create SNS topic `forum-topic-events` for inter-service communication
    - Subscribe the SQS queue to the SNS topic with an access policy that permits only the SNS topic ARN to send messages
    - Verify topic service can publish `TopicCreatedEvent` and message service receives it from the queue
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 8.2 Configure Centralized Logging and CloudWatch Dashboard
    - Call `create_log_group` three times — create `/forum/user-service`, `/forum/topic-service`, `/forum/message-service` log groups with 14-day retention
    - Verify Lambda sends logs to its log group (automatic with proper role), ECS uses `awslogs` driver, EC2 uses CloudWatch agent
    - Call `create_dashboard` — create CloudWatch dashboard `ForumMicroservices` with widgets for: Lambda invocations/errors/duration, ECS running task count/CPU/memory, EC2 CPUUtilization/StatusCheckFailed
    - Call `create_alert_sns_topic` — create alerting SNS topic with an email subscription for notifications
    - Call `create_alarm` — create CloudWatch alarm for elevated Lambda errors (threshold: 5 errors in 5 minutes), linked to the alerting SNS topic
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 9. Checkpoint - Validate Full Architecture and Cross-Cutting Concerns
  - Deploy all stacks: `cdk deploy --all`
  - Test end-to-end path routing: `curl` all three service health endpoints through the ALB
  - Test CRUD on all three services: create a user, create a topic (triggers SNS event), create a message
  - Verify async flow: after creating a topic, check SQS queue metrics or message service logs for the received `TopicCreatedEvent`
  - Verify dead-letter queue is empty (no processing failures): `aws sqs get-queue-attributes --queue-url <DLQ_URL> --attribute-names ApproximateNumberOfMessages`
  - Verify CloudWatch dashboard displays metrics from all three services
  - Verify CloudWatch log groups contain logs from each service
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Independent Deployment and Service Resilience Validation
  - [ ] 10.1 Verify Independent Deployability
    - Update the message service container (e.g., change the health check response message), build and push a new image
    - Update the ECS service to deploy the new task definition: observe rolling update via `aws ecs describe-services`
    - During the rolling update, verify user service and topic service continue responding: `curl http://<ALB_DNS>/users/health` and `curl http://<ALB_DNS>/topics/health`
    - Verify ALB drains connections from old tasks and routes to new tasks only after health checks pass
    - _Requirements: 8.1, 8.2, 8.4_
  - [ ]* 10.2 Test Service Isolation and Fault Tolerance
    - **Property 1: Service Independence Under Failure**
    - Simulate a Lambda error (e.g., temporarily remove DynamoDB permissions) and verify `/topics/*` and `/messages/*` continue functioning
    - Verify ALB returns error only for `/users/*` while other paths respond normally
    - Restore Lambda permissions and verify recovery
    - Confirm no security group allows direct internet access to EC2 or ECS tasks: attempt direct connection and verify it is denied
    - **Validates: Requirements 8.3, 7.4**
  - [ ] 10.3 Verify ALB Default Error Response for Unavailable Service
    - Simulate a service becoming unavailable (e.g., stop the EC2 instance running the topic service)
    - Verify that requests to `/topics/*` receive the default error response from the ALB while `/users/*` and `/messages/*` continue to respond normally
    - Verify the other services' health check status remains unchanged during the simulated outage
    - Restore the stopped service and verify it recovers
    - _Requirements: 8.3_

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Destroy All CDK Stacks
    - Delete all ECR images first (ECR repositories with images cannot be deleted by CDK): `aws ecr batch-delete-image --repository-name forum-message-service --image-ids "$(aws ecr list-images --repository-name forum-message-service --query 'imageIds[*]' --output json)"`
    - Destroy all stacks: `cdk destroy --all`
    - Confirm destruction when prompted for each stack
    - _Requirements: (all)_
  - [ ] 11.2 Verify Resource Cleanup
    - Verify VPC deleted: `aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*Forum*"`
    - Verify DynamoDB tables deleted: `aws dynamodb list-tables`
    - Verify no Lambda functions remain: `aws lambda list-functions --query "Functions[?contains(FunctionName, 'forum')]"`
    - Verify no ECS clusters remain: `aws ecs list-clusters`
    - Verify no load balancers remain: `aws elbv2 describe-load-balancers`
    - Verify SNS topics and SQS queues are deleted
    - **Warning**: NAT Gateway and Elastic IP incur costs — confirm they are deleted: `aws ec2 describe-nat-gateways --filter "Name=state,Values=available"`
    - Check AWS Cost Explorer after 24 hours to confirm no ongoing charges
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The MessagingAndMonitoringStack (Task 8) must be deployed before or alongside the service stacks that reference its SNS topic and SQS queue — CDK cross-stack references handle this automatically when stacks declare dependencies
- The EC2 user data script may take 3-5 minutes to complete after instance launch — monitor `/var/log/cloud-init-output.log` via Session Manager if the health check does not pass immediately
- DynamoDB tables use on-demand capacity mode to avoid provisioning concerns during learning
- The ECS Fargate service runs 2 tasks across 2 AZs for high availability; during development, you may reduce to 1 task to save costs and increase to 2 for final validation
