

# Implementation Plan: Deploy a Containerized Application on Amazon ECS with Fargate

## Overview

This implementation plan guides you through deploying a containerized web application (nginx) on Amazon ECS using AWS Fargate. The approach uses Python scripts with boto3 to programmatically provision all AWS resources, organized into five manager components: ClusterManager, TaskDefinitionManager, NetworkManager, ServiceManager, and MonitoringManager. Each component encapsulates a logical layer of the deployment stack, and the tasks follow the natural dependency order of building infrastructure from the bottom up.

The plan progresses through three phases. First, the foundation phase establishes the project structure, ECS cluster, IAM execution role, and task definition. Second, the networking and deployment phase configures VPC resources, security groups, the Application Load Balancer, and launches the ECS service with load balancer integration. Third, the operations phase adds auto-scaling policies and CloudWatch monitoring capabilities. Checkpoints after the foundation and deployment phases ensure incremental validation before proceeding.

Key dependencies dictate the ordering: the ECS cluster must exist before services can be created, the task execution role must exist before registering task definitions, networking and load balancer resources must be ready before service deployment, and the service must be running before configuring auto-scaling or querying metrics. The final task provides complete resource teardown to avoid ongoing AWS charges.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for ECS, EC2, ELB, IAM, CloudWatch, and Application Auto Scaling
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Verify boto3: `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 Project Structure and Region Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `mkdir -p components`
    - Create `components/__init__.py`
    - Verify the default VPC exists: `aws ec2 describe-vpcs --filters Name=isDefault,Values=true`
    - _Requirements: (all)_

- [ ] 2. Implement ClusterManager and Create ECS Cluster
  - [ ] 2.1 Create `components/cluster_manager.py`
    - Initialize boto3 ECS client: `self.ecs_client = boto3.client('ecs')`
    - Implement `create_cluster(cluster_name)` using `create_cluster()` API with `capacityProviders=["FARGATE", "FARGATE_SPOT"]`
    - Implement `describe_cluster(cluster_name)` using `describe_clusters()` API and return cluster status/details
    - Implement `delete_cluster(cluster_name)` using `delete_cluster()` API
    - Implement `list_clusters()` using `list_clusters()` API
    - Handle `ClientException` when cluster name already exists and raise appropriate error
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Create ECS cluster and verify
    - Write a script or main block to call `create_cluster("ecs-fargate-lab")`
    - Verify cluster is ACTIVE: call `describe_cluster("ecs-fargate-lab")` and check `status == "ACTIVE"`
    - Verify capacity providers include FARGATE and FARGATE_SPOT
    - Verify via CLI: `aws ecs describe-clusters --clusters ecs-fargate-lab`
    - _Requirements: 1.1, 1.2_

- [ ] 3. Implement TaskDefinitionManager and Register Task Definition
  - [ ] 3.1 Create `components/task_definition_manager.py` - IAM and Logging
    - Initialize boto3 clients: `ecs_client`, `iam_client`, `logs_client`
    - Implement `create_execution_role(role_name)` that creates an IAM role with ECS tasks trust policy (`ecs-tasks.amazonaws.com`) and attaches `AmazonECSTaskExecutionRolePolicy`
    - Implement `create_log_group(log_group_name)` using `create_log_group()` API; handle `ResourceAlreadyExistsException`
    - Implement `delete_execution_role(role_name)` that detaches policies and deletes the role
    - Implement `delete_log_group(log_group_name)` using `delete_log_group()` API
    - _Requirements: 2.4, 7.2_
  - [ ] 3.2 Implement task definition registration
    - Implement `register_task_definition(family, container_name, image, cpu, memory, container_port, execution_role_arn, log_group_name, region)` that calls `register_task_definition()` with:
      - `requiresCompatibilities=["FARGATE"]`, `networkMode="awsvpc"`
      - Container definition with `portMappings` for the container port (protocol "tcp")
      - `logConfiguration` using `awslogs` driver with `awslogs-group`, `awslogs-region`, `awslogs-stream-prefix` options
    - Implement `describe_task_definition(family)` and `deregister_task_definition(task_definition_arn)`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 7.2_
  - [ ] 3.3 Create execution role, log group, and register task definition
    - Call `create_execution_role("ecsTaskExecutionRole-lab")` and capture the returned ARN
    - Call `create_log_group("/ecs/fargate-lab")`
    - Call `register_task_definition(family="fargate-lab-task", container_name="nginx", image="nginx:latest", cpu="256", memory="512", container_port=80, execution_role_arn=<role_arn>, log_group_name="/ecs/fargate-lab", region="us-east-1")`
    - Verify: `aws ecs describe-task-definition --task-definition fargate-lab-task`
    - Confirm task definition shows Fargate compatibility, awsvpc network mode, and awslogs log driver
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 7.2_

- [ ] 4. Checkpoint - Validate Cluster and Task Definition
  - Verify ECS cluster is ACTIVE with Fargate capacity providers: `aws ecs describe-clusters --clusters ecs-fargate-lab`
  - Verify task definition is registered with correct image, CPU (256), memory (512), port mapping (80), and awslogs configuration
  - Verify IAM execution role exists: `aws iam get-role --role-name ecsTaskExecutionRole-lab`
  - Verify CloudWatch log group exists: `aws logs describe-log-groups --log-group-name-prefix /ecs/fargate-lab`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement NetworkManager - VPC, Security Groups, and ALB
  - [ ] 5.1 Create `components/network_manager.py` - VPC and Security Groups
    - Initialize boto3 clients: `ec2_client`, `elbv2_client`
    - Implement `get_default_vpc()` using `describe_vpcs(Filters=[{"Name": "isDefault", "Values": ["true"]}])`
    - Implement `get_public_subnets(vpc_id)` using `describe_subnets()` filtered by VPC and `MapPublicIpOnLaunch=true`, ensuring subnets span at least 2 Availability Zones
    - Implement `create_alb_security_group(vpc_id, group_name, listener_port)` that creates a security group allowing inbound TCP on `listener_port` from `0.0.0.0/0`
    - Implement `create_task_security_group(vpc_id, group_name, container_port, alb_security_group_id)` that creates a security group allowing inbound TCP on `container_port` only from the ALB security group ID
    - Implement `delete_security_group(security_group_id)`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ] 5.2 Implement ALB, Target Group, and Listener
    - Implement `create_load_balancer(name, subnets, security_group_id)` using `create_load_balancer()` with `Type="application"`, `Scheme="internet-facing"`; wait for ALB to be active
    - Implement `create_target_group(name, vpc_id, port, health_check_path)` with `TargetType="ip"`, `Protocol="HTTP"`, and health check on the specified path and port
    - Implement `create_listener(load_balancer_arn, target_group_arn, port)` with default forward action to the target group
    - Implement `get_load_balancer_dns(load_balancer_arn)` to retrieve the ALB DNS name
    - Implement `delete_load_balancer(load_balancer_arn)` and `delete_target_group(target_group_arn)`
    - _Requirements: 4.1, 4.2, 4.3_
  - [ ] 5.3 Provision networking resources
    - Call `get_default_vpc()` and `get_public_subnets(vpc_id)` to discover networking
    - Call `create_alb_security_group(vpc_id, "alb-sg-lab", 80)` and `create_task_security_group(vpc_id, "task-sg-lab", 80, alb_sg_id)`
    - Call `create_load_balancer("fargate-lab-alb", subnet_ids, alb_sg_id)`
    - Call `create_target_group("fargate-lab-tg", vpc_id, 80, "/")` with health check on path "/"
    - Call `create_listener(alb_arn, tg_arn, 80)`
    - Verify ALB is active: `aws elbv2 describe-load-balancers --names fargate-lab-alb`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2_

- [ ] 6. Implement ServiceManager and Deploy ECS Service
  - [ ] 6.1 Create `components/service_manager.py` - Service and Auto-Scaling
    - Initialize boto3 clients: `ecs_client`, `autoscaling_client = boto3.client('application-autoscaling')`
    - Implement `create_service(cluster_name, service_name, task_definition, desired_count, subnets, security_group_id, target_group_arn, container_name, container_port)` using `create_service()` with `launchType="FARGATE"`, `networkConfiguration` (awsvpc with subnets, security group, `assignPublicIp="ENABLED"`), and `loadBalancers` configuration
    - Implement `describe_service(cluster_name, service_name)` and `wait_service_stable(cluster_name, service_name)` using ECS waiter
    - Implement `update_service(cluster_name, service_name, desired_count)` and `delete_service(cluster_name, service_name)` (set desired count to 0, then delete)
    - Implement `configure_auto_scaling(cluster_name, service_name, min_count, max_count, target_cpu_percent)` that registers a scalable target with Application Auto Scaling and creates a `TargetTrackingScaling` policy on `ECSServiceAverageCPUUtilization`
    - Implement `delete_auto_scaling(cluster_name, service_name)` that removes the scaling policy and deregisters the scalable target
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3_
  - [ ] 6.2 Deploy ECS service and verify public access
    - Call `create_service(cluster_name="ecs-fargate-lab", service_name="fargate-lab-service", task_definition="fargate-lab-task", desired_count=2, subnets=<subnet_ids>, security_group_id=<task_sg_id>, target_group_arn=<tg_arn>, container_name="nginx", container_port=80)`
    - Call `wait_service_stable("ecs-fargate-lab", "fargate-lab-service")` to wait for tasks to reach RUNNING state
    - Retrieve ALB DNS name via `get_load_balancer_dns(alb_arn)`
    - Verify public access: `curl http://<alb-dns-name>` — should return the nginx welcome page
    - Verify tasks are registered in target group: `aws elbv2 describe-target-health --target-group-arn <tg_arn>`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 4.3_

- [ ] 7. Checkpoint - Validate Service Deployment and Public Access
  - Verify ECS service is ACTIVE with 2 running tasks: `aws ecs describe-services --cluster ecs-fargate-lab --services fargate-lab-service`
  - Verify target group has 2 healthy targets: `aws elbv2 describe-target-health --target-group-arn <tg_arn>`
  - Access ALB DNS name in browser or via curl and confirm nginx welcome page is returned
  - Verify tasks have public IPs assigned (awsvpc with ENABLED): `aws ecs describe-tasks --cluster ecs-fargate-lab --tasks <task_ids>`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Configure Auto-Scaling for the ECS Service
  - [ ] 8.1 Apply target tracking scaling policy
    - Call `configure_auto_scaling(cluster_name="ecs-fargate-lab", service_name="fargate-lab-service", min_count=2, max_count=4, target_cpu_percent=50.0)`
    - Verify scalable target registered: `aws application-autoscaling describe-scalable-targets --service-namespace ecs`
    - Verify scaling policy created: `aws application-autoscaling describe-scaling-policies --service-namespace ecs`
    - Confirm min capacity is 2, max capacity is 4, and target value is 50.0
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ]* 8.2 Validate auto-scaling boundaries
    - **Property 1: Scaling Boundary Enforcement**
    - Attempt to set desired count below minimum via `update_service` — confirm the auto-scaler adjusts it back to minimum
    - Verify service will not exceed maximum task count boundary
    - **Validates: Requirements 6.2, 6.3**

- [ ] 9. Implement MonitoringManager - CloudWatch Metrics and Logs
  - [ ] 9.1 Create `components/monitoring_manager.py`
    - Initialize boto3 clients: `cloudwatch_client`, `logs_client`, `ecs_client`
    - Implement `get_service_metrics(cluster_name, service_name, metric_name, period_minutes)` using `get_metric_statistics()` with namespace `AWS/ECS`, dimensions for ClusterName and ServiceName, statistics `["Average"]`
    - Implement `get_log_streams(log_group_name)` using `describe_log_streams()` ordered by `LastEventTime`
    - Implement `get_log_events(log_group_name, log_stream_name, limit)` using `get_log_events()` to retrieve recent log entries
    - Implement `describe_stopped_tasks(cluster_name)` using `list_tasks(desiredStatus="STOPPED")` then `describe_tasks()` to get stop reasons
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ] 9.2 Verify monitoring and logging
    - Call `get_service_metrics("ecs-fargate-lab", "fargate-lab-service", "CPUUtilization", 30)` and confirm data points are returned
    - Call `get_service_metrics("ecs-fargate-lab", "fargate-lab-service", "MemoryUtilization", 30)` and confirm data points
    - Call `get_log_streams("/ecs/fargate-lab")` and confirm log streams exist with task ID prefixes
    - Call `get_log_events("/ecs/fargate-lab", <stream_name>, 10)` and confirm nginx access/error logs are visible
    - Call `describe_stopped_tasks("ecs-fargate-lab")` to verify stopped task inspection works (may return empty if no failures)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 10. Checkpoint - Validate Complete Deployment
  - Verify all five components are implemented: ClusterManager, TaskDefinitionManager, NetworkManager, ServiceManager, MonitoringManager
  - Confirm ECS cluster is ACTIVE with Fargate capacity providers
  - Confirm task definition is registered with correct container, networking, and logging configuration
  - Confirm ALB is routing traffic to healthy ECS tasks and application is publicly accessible
  - Confirm auto-scaling policy is active with correct min/max/target settings
  - Confirm CloudWatch metrics (CPU, memory) and container logs are accessible
  - Generate some traffic: `for i in $(seq 1 20); do curl -s http://<alb-dns>/; done` and verify logs update
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Remove auto-scaling and ECS service
    - Call `delete_auto_scaling("ecs-fargate-lab", "fargate-lab-service")` to remove scaling policy and scalable target
    - Call `delete_service("ecs-fargate-lab", "fargate-lab-service")` — sets desired count to 0 and deletes the service
    - Wait for tasks to drain: `aws ecs wait services-inactive --cluster ecs-fargate-lab --services fargate-lab-service`
    - _Requirements: (all)_
  - [ ] 11.2 Remove load balancer and networking resources
    - Delete ALB listener (automatically removed with ALB)
    - Call `delete_load_balancer(alb_arn)`: `aws elbv2 delete-load-balancer --load-balancer-arn <alb_arn>`
    - Wait for ALB deletion to complete, then call `delete_target_group(tg_arn)`: `aws elbv2 delete-target-group --target-group-arn <tg_arn>`
    - Call `delete_security_group(task_sg_id)` and `delete_security_group(alb_sg_id)`
    - Verify: `aws elbv2 describe-load-balancers --names fargate-lab-alb` returns not found
    - _Requirements: (all)_
  - [ ] 11.3 Remove task definition, IAM role, log group, and cluster
    - Call `deregister_task_definition(task_definition_arn)`: `aws ecs deregister-task-definition --task-definition fargate-lab-task:1`
    - Delete task definition: `aws ecs delete-task-definitions --task-definitions fargate-lab-task:1`
    - Call `delete_execution_role("ecsTaskExecutionRole-lab")` — detach `AmazonECSTaskExecutionRolePolicy` first, then delete role
    - Call `delete_log_group("/ecs/fargate-lab")`: `aws logs delete-log-group --log-group-name /ecs/fargate-lab`
    - Call `delete_cluster("ecs-fargate-lab")`: `aws ecs delete-cluster --cluster ecs-fargate-lab`
    - Verify cluster deleted: `aws ecs describe-clusters --clusters ecs-fargate-lab` shows INACTIVE
    - **Warning**: ALB and Fargate tasks incur charges while running — ensure all resources are removed
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- The project uses the default VPC to simplify networking — no custom VPC creation is needed
- Resource names include a "lab" suffix to avoid conflicts with existing resources
- Save resource ARNs and IDs (ALB ARN, target group ARN, security group IDs, role ARN) as you create them — they are needed for subsequent tasks and cleanup
- All components use boto3 directly; no infrastructure-as-code frameworks (CDK, CloudFormation) are used, giving hands-on API experience
