

# Implementation Plan: Highly Available Architecture with Auto Scaling

## Overview

This implementation plan guides you through building a highly available architecture on AWS using an Application Load Balancer and EC2 Auto Scaling. The approach follows a bottom-up infrastructure provisioning strategy: first establishing the network foundation (VPC, subnets, gateways), then layering on security groups, load balancing, compute with Auto Scaling, monitoring, and finally validating resilience through failure simulation. All infrastructure is provisioned programmatically using Python 3.12 with boto3.

The plan is organized into key phases: environment setup, network infrastructure, security and load balancing, Auto Scaling with health checks and scaling policies, monitoring and observability, and resilience validation. Each phase builds on the previous one, ensuring that dependencies are satisfied before dependent components are created. Checkpoints are placed after the network/ALB setup and after the full architecture deployment to validate incremental progress.

A critical consideration is the ordering of resource creation and deletion. NAT gateways and Elastic IPs incur costs while running, so the cleanup task is essential. The Auto Scaling group must be deleted before the launch template, and the ALB must be deleted before its security groups. The plan accounts for these dependencies throughout.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for VPC, EC2, ELB, Auto Scaling, CloudWatch, and SSM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Confirm sufficient service quotas: VPCs (at least 1 available), Elastic IPs (at least 2), NAT Gateways (at least 2)
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Create project directory structure: `mkdir -p components` and create `components/__init__.py`
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Identify two Availability Zones to use (e.g., `us-east-1a`, `us-east-1b`)
    - Look up a current Amazon Linux 2023 AMI ID: `aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023*-x86_64" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text`
    - Record the AMI ID, region, and AZ names for use in subsequent tasks
    - _Requirements: 1.1, 3.1, 4.1_

- [ ] 2. Multi-AZ VPC Network Infrastructure
  - [ ] 2.1 Implement NetworkManager component
    - Create `components/network_manager.py` with a `NetworkManager` class using `boto3.client('ec2')`
    - Implement `get_availability_zones(region)` to return available AZ names
    - Implement `create_vpc(cidr_block, name)` to create a VPC with DNS support enabled, returning `vpc_id`
    - Implement `create_internet_gateway(vpc_id)` to create and attach an IGW, returning `internet_gateway_id`
    - Implement `create_subnet(vpc_id, cidr_block, az, public, name)` to create a subnet (set `MapPublicIpOnLaunch` for public subnets), returning `subnet_id`
    - Implement `create_nat_gateway(subnet_id)` to allocate an Elastic IP and create a NAT gateway in the given public subnet, returning `nat_gateway_id`
    - Implement `configure_route_table(vpc_id, subnet_id, gateway_id, is_nat)` to create a route table, add a `0.0.0.0/0` route to the IGW or NAT gateway, and associate it with the subnet, returning `route_table_id`
    - Implement `delete_vpc_resources(vpc_id)` to tear down all VPC resources in correct dependency order
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [ ] 2.2 Provision the Multi-AZ VPC
    - Create a provisioning script `provision_network.py` that uses `NetworkManager` to build the full network
    - Create VPC with CIDR `10.0.0.0/16`
    - Create public subnets: `10.0.1.0/24` in AZ1, `10.0.2.0/24` in AZ2 (each /24 provides 251 usable IPs for scaling headroom)
    - Create private subnets: `10.0.3.0/24` in AZ1, `10.0.4.0/24` in AZ2
    - Create and attach an internet gateway; configure public subnet route tables to route `0.0.0.0/0` through the IGW
    - Create a NAT gateway in each public subnet; configure private subnet route tables to route `0.0.0.0/0` through the respective NAT gateway
    - Populate and store a `VpcConfig` data model (dict) with `vpc_id`, `internet_gateway_id`, `public_subnet_ids`, `private_subnet_ids`, `nat_gateway_ids`, `availability_zones`
    - Save configuration to `config/vpc_config.json` for use by subsequent tasks
    - Verify: `aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc_id>" --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]' --output table`
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 3. Security Groups and Application Load Balancer
  - [ ] 3.1 Implement SecurityGroupManager component
    - Create `components/security_group_manager.py` with a `SecurityGroupManager` class using `boto3.client('ec2')`
    - Implement `create_alb_security_group(vpc_id, name, ingress_port)` to create a security group allowing inbound TCP on `ingress_port` (80) from `0.0.0.0/0`, returning `sg_id`
    - Implement `create_instance_security_group(vpc_id, name, alb_sg_id, app_port)` to create a security group allowing inbound TCP on `app_port` only from the ALB security group, returning `sg_id`
    - Implement `delete_security_group(sg_id)` to delete the specified security group
    - Provision both security groups and record their IDs in `config/sg_config.json`
    - Verify: `aws ec2 describe-security-groups --group-ids <alb_sg_id> <instance_sg_id> --query 'SecurityGroups[*].[GroupId,GroupName,IpPermissions]' --output table`
    - _Requirements: 2.4, 3.2_
  - [ ] 3.2 Implement LoadBalancerManager component
    - Create `components/load_balancer_manager.py` with a `LoadBalancerManager` class using `boto3.client('elbv2')`
    - Implement `create_load_balancer(name, subnet_ids, sg_id)` to create an internet-facing ALB across public subnets, returning a dict with `alb_arn` and `alb_dns_name`
    - Implement `create_target_group(name, vpc_id, port, health_check_path)` to create an HTTP target group with health check on the given path (use `/`), returning `target_group_arn`
    - Implement `create_listener(alb_arn, target_group_arn, port)` to create a listener on port 80 forwarding to the target group, returning `listener_arn`
    - Note: Cross-zone load balancing is always enabled at the load balancer level for ALBs and cannot be turned off; no action is needed to enable it. Optionally implement `configure_cross_zone_load_balancing(target_group_arn, enabled)` via `modify_target_group_attributes` if per-target-group cross-zone behavior needs to be controlled
    - Implement `get_target_health(target_group_arn)` to return a list of `TargetHealthStatus` dicts with `instance_id`, `availability_zone`, `health_state`, and optional `reason`
    - Implement `delete_load_balancer(alb_arn)` and `delete_target_group(target_group_arn)` for cleanup
    - _Requirements: 2.1, 2.2, 2.3, 5.1_
  - [ ] 3.3 Provision ALB and Target Group
    - Create `provision_alb.py` that uses `LoadBalancerManager` and `SecurityGroupManager`
    - Create the ALB across both public subnets with the ALB security group
    - Create a target group in the VPC with health check path `/` on port 80
    - Create a listener on port 80 forwarding to the target group
    - Note: Cross-zone load balancing is always enabled at the load balancer level for Application Load Balancers and cannot be disabled; no explicit configuration step is required
    - Populate and store an `AlbConfig` data model (dict) with `alb_arn`, `alb_dns_name`, `target_group_arn`, `listener_arn`
    - Save to `config/alb_config.json`
    - Verify: `aws elbv2 describe-load-balancers --load-balancer-arns <alb_arn> --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code,AvailabilityZones[*].ZoneName]' --output table`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.1_

- [ ] 4. Checkpoint - Validate Network and Load Balancer
  - Verify VPC exists with 4 subnets (2 public, 2 private) across 2 AZs: `aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc_id>"`
  - Verify internet gateway is attached to VPC: `aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<vpc_id>"`
  - Verify both NAT gateways are available: `aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<vpc_id>" --query 'NatGateways[*].[NatGatewayId,State,SubnetId]'`
  - Verify public route tables route to IGW and private route tables route to NAT gateways
  - Verify ALB is active and spans both AZs: `aws elbv2 describe-load-balancers --load-balancer-arns <alb_arn>`
  - Verify target group has health check configured: `aws elbv2 describe-target-groups --target-group-arns <tg_arn>`
  - Verify security groups have correct inbound rules
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Launch Template and Auto Scaling Group
  - [ ] 5.1 Implement AutoScalingManager component
    - Create `components/auto_scaling_manager.py` with an `AutoScalingManager` class using `boto3.client('autoscaling')` and `boto3.client('ec2')`
    - Implement `create_launch_template(name, ami_id, instance_type, sg_id, user_data)` where `user_data` is a base64-encoded bootstrap script that installs and starts a simple web server (e.g., `yum install -y httpd && systemctl start httpd && echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html`), returning `launch_template_id`
    - Implement `create_auto_scaling_group(name, launch_template_id, subnet_ids, min_size, max_size, desired_capacity, target_group_arn, health_check_grace_period)` to create an ASG across private subnets with ELB health check type and the specified grace period, attaching the target group
    - Implement `create_target_tracking_policy(asg_name, policy_name, target_cpu)` to create a target tracking scaling policy on `ASGAverageCPUUtilization`, returning the policy details
    - Implement `get_scaling_activities(asg_name)` to return a list of `ScalingActivity` dicts
    - Implement `get_group_details(asg_name)` to return ASG details including instance IDs, health status, and AZ distribution
    - Implement `delete_auto_scaling_group(asg_name, force)` to delete the ASG (with `ForceDelete` option) and `delete_launch_template(template_id)`
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.2, 5.3, 5.4, 6.1, 6.2_
  - [ ] 5.2 Provision Launch Template and Auto Scaling Group
    - Create `provision_asg.py` that uses `AutoScalingManager`
    - Create the launch template with Amazon Linux 2023 AMI, `t3.micro` instance type, instance security group, and user data bootstrap script
    - Create the ASG with `min_size=2`, `max_size=6`, `desired_capacity=2` across both private subnets, attached to the ALB target group, with health check type `ELB` and grace period of `300` seconds
    - Create a target tracking scaling policy targeting 50% average CPU utilization
    - Populate and store an `AsgConfig` data model (dict) with `asg_name`, `launch_template_id`, `min_size`, `max_size`, `desired_capacity`
    - Save to `config/asg_config.json`
    - Wait for instances to reach `InService` state: poll `get_group_details` until desired capacity is met
    - Verify instances registered with target group: `aws elbv2 describe-target-health --target-group-arn <tg_arn>`
    - Verify application is accessible via ALB DNS: `curl http://<alb_dns_name>`
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.2, 5.3, 5.4, 6.1, 6.2_

- [ ] 6. Monitoring and Observability
  - [ ] 6.1 Implement MonitoringManager component
    - Create `components/monitoring_manager.py` with a `MonitoringManager` class using `boto3.client('cloudwatch')`
    - Implement `get_alb_metrics(alb_arn, metric_name, period)` to query ALB metrics (HealthyHostCount, UnHealthyHostCount, RequestCount) from the `AWS/ApplicationELB` namespace, returning datapoints
    - Implement `get_asg_metrics(asg_name, metric_name, period)` to query ASG metrics (GroupInServiceInstances, GroupTotalInstances) from the `AWS/AutoScaling` namespace
    - Implement `create_unhealthy_host_alarm(alarm_name, target_group_arn, alb_arn, threshold)` to create a CloudWatch alarm that triggers when UnHealthyHostCount exceeds the threshold
    - Implement `get_alarm_state(alarm_name)` to return the alarm's current state and reason
    - Implement `delete_alarm(alarm_name)` for cleanup
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ] 6.2 Configure Monitoring and Verify Metrics
    - Create `provision_monitoring.py` that uses `MonitoringManager`
    - Create a CloudWatch alarm for unhealthy host count exceeding 0 on the target group
    - Query and display ALB HealthyHostCount metric to confirm 2 healthy hosts
    - Query and display ASG GroupInServiceInstances metric to confirm 2 in-service instances
    - View Auto Scaling activity history using `get_scaling_activities` to see initial launch events with cause and status
    - Verify alarm is in `OK` state: `aws cloudwatch describe-alarms --alarm-names <alarm_name> --query 'MetricAlarms[*].[AlarmName,StateValue]'`
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 7. Checkpoint - Validate Full Architecture
  - Access the application via ALB DNS name in a browser or `curl` — confirm responses come from different instances (hostname varies)
  - Verify ASG has 2 instances in `InService` state across 2 AZs: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg_name>`
  - Verify target group shows 2 healthy targets in different AZs: `aws elbv2 describe-target-health --target-group-arn <tg_arn>`
  - Verify scaling policy exists: `aws autoscaling describe-policies --auto-scaling-group-names <asg_name>`
  - Verify CloudWatch alarm is in OK state
  - Verify ASG activity history shows initial launch events with details
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Resilience Validation Through Failure Simulation
  - [ ] 8.1 Implement ResilienceTester component
    - Create `components/resilience_tester.py` with a `ResilienceTester` class using `boto3.client('ec2')` and `boto3.client('ssm')`
    - Implement `get_asg_instance_ids(asg_name)` to list current instance IDs in the ASG
    - Implement `terminate_instance(instance_id)` to terminate a specific EC2 instance
    - Implement `stop_application_on_instance(instance_id, process_name)` to stop the web server process (e.g., `httpd`) on an instance via SSM `send_command` with the `AWS-RunShellScript` document
    - Implement `generate_cpu_load(instance_ids, duration_seconds)` to run a CPU stress command on instances via SSM to trigger scaling
    - Implement `wait_for_healthy_host_count(target_group_arn, expected_count, timeout)` to poll target health until the expected number of healthy hosts is reached or timeout occurs, returning `True`/`False`
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  - [ ] 8.2 Test Instance Termination and Self-Healing
    - Create `test_resilience.py` that uses `ResilienceTester`, `LoadBalancerManager`, and `AutoScalingManager`
    - Get current instance IDs and record the healthy host count (should be 2)
    - Terminate one instance using `terminate_instance`
    - Monitor ALB target health — confirm the terminated instance is deregistered and remaining instance continues serving traffic (verify with `curl` to ALB DNS)
    - Wait for ASG to launch a replacement and for healthy host count to return to 2 using `wait_for_healthy_host_count(tg_arn, 2, 600)`
    - View ASG scaling activities to confirm the termination detection and replacement launch with cause details
    - _Requirements: 8.1, 8.3, 8.4_
  - [ ] 8.3 Test Application Failure and Health Check Recovery
    - Stop the application process on one instance using `stop_application_on_instance(instance_id, "httpd")`
    - Observe the ALB health check detect the failure and mark the instance unhealthy (poll `get_target_health`)
    - Confirm traffic continues flowing to the remaining healthy instance via `curl`
    - Wait for the ASG (with ELB health check type) to terminate the unhealthy instance and launch a replacement
    - Confirm healthy host count returns to expected value using `wait_for_healthy_host_count`
    - Observe the CloudWatch unhealthy host alarm transition to ALARM state during the failure window using `get_alarm_state`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 8.2, 8.3, 8.4_
  - [ ]* 8.4 Test Dynamic Scaling Under Load
    - **Property 1: Auto Scaling responds to demand by adjusting capacity within boundaries**
    - **Validates: Requirements 6.1, 6.2, 6.3**
    - Use `generate_cpu_load(instance_ids, 300)` to stress CPU on all running instances
    - Monitor ASG scaling activities — confirm new instances are launched (up to `max_size=6`)
    - Verify new instances register with the target group and become healthy
    - After load subsides, confirm scale-in occurs and instances are terminated back toward `desired_capacity`
    - Verify the ASG never exceeds `max_size` or drops below `min_size`
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ]* 8.5 Test Availability Zone Impairment and Cross-Zone Recovery
    - **Property 2: Auto Scaling maintains desired capacity when an Availability Zone becomes impaired**
    - **Validates: Requirement 4.4**
    - Get current instance IDs and record which AZ each instance is running in using `get_group_details`
    - Simulate AZ impairment by terminating all instances in one AZ simultaneously using `terminate_instance` for each
    - Monitor ASG scaling activities — confirm the ASG detects the lost instances and launches replacements
    - Verify replacement instances are launched in the remaining healthy AZ(s) to restore desired capacity
    - Wait for healthy host count to return to expected value using `wait_for_healthy_host_count(tg_arn, 2, 600)`
    - Confirm traffic continues flowing through the load balancer during the replacement period via `curl` to ALB DNS
    - View ASG scaling activities to confirm the cause references the terminated instances and restored capacity
    - _Requirements: 4.4, 8.3_

- [ ] 9. Checkpoint - Validate Resilience and Recovery
  - Confirm ASG activity history shows at least one termination-replacement cycle with cause and capacity details
  - Confirm ALB healthy host count is back to expected value (2)
  - Confirm CloudWatch alarm returned to OK state after recovery
  - Verify all monitoring metrics are visible in CloudWatch: ALB request count per AZ, healthy/unhealthy host counts, ASG group size
  - Review the complete architecture behavior: traffic distribution, health checks, self-healing, and scaling
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete Auto Scaling and Compute Resources
    - Delete scaling policies: `aws autoscaling delete-policy --auto-scaling-group-name <asg_name> --policy-name <policy_name>`
    - Delete Auto Scaling group (force): `aws autoscaling delete-auto-scaling-group --auto-scaling-group-name <asg_name> --force-delete`
    - Wait for ASG deletion to complete and all instances to terminate
    - Delete launch template: `aws ec2 delete-launch-template --launch-template-id <lt_id>`
    - _Requirements: (all)_
  - [ ] 10.2 Delete Load Balancer and Monitoring Resources
    - Delete CloudWatch alarms: `aws cloudwatch delete-alarms --alarm-names <alarm_name>`
    - Delete ALB listener: `aws elbv2 delete-listener --listener-arn <listener_arn>`
    - Delete ALB: `aws elbv2 delete-load-balancer --load-balancer-arn <alb_arn>`
    - Wait for ALB to be fully deleted before proceeding
    - Delete target group: `aws elbv2 delete-target-group --target-group-arn <tg_arn>`
    - _Requirements: (all)_
  - [ ] 10.3 Delete Network and Security Resources
    - Delete security groups (ALB and instance): `aws ec2 delete-security-group --group-id <sg_id>`
    - Delete NAT gateways: `aws ec2 delete-nat-gateway --nat-gateway-id <nat_id>` (wait for deletion)
    - Release Elastic IPs: `aws ec2 release-address --allocation-id <eip_alloc_id>`
    - Delete subnets: `aws ec2 delete-subnet --subnet-id <subnet_id>` (all 4)
    - Delete route tables (non-main): `aws ec2 delete-route-table --route-table-id <rt_id>`
    - Detach and delete internet gateway: `aws ec2 detach-internet-gateway --internet-gateway-id <igw_id> --vpc-id <vpc_id>` then `aws ec2 delete-internet-gateway --internet-gateway-id <igw_id>`
    - Delete VPC: `aws ec2 delete-vpc --vpc-id <vpc_id>`
    - Or use `NetworkManager.delete_vpc_resources(vpc_id)` to handle the full teardown programmatically
    - **Warning**: NAT gateways and Elastic IPs incur ongoing costs — verify deletion immediately
    - _Requirements: (all)_
  - [ ] 10.4 Verify Cleanup
    - Verify VPC deleted: `aws ec2 describe-vpcs --vpc-ids <vpc_id>` (should return error)
    - Verify no NAT gateways remain: `aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<vpc_id>" --query 'NatGateways[?State!=`deleted`]'`
    - Verify no Elastic IPs remain: `aws ec2 describe-addresses --query 'Addresses[?AssociationId==null]'`
    - Verify no load balancers remain: `aws elbv2 describe-load-balancers --query 'LoadBalancers[?LoadBalancerName==`ha-web-alb`]'`
    - Verify no ASGs remain: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg_name>`
    - Delete `config/` directory with saved configuration files
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- NAT gateways and Elastic IPs are the most cost-sensitive resources — always verify their deletion during cleanup
- The health check grace period of 300 seconds allows instances to fully bootstrap before health evaluation begins
- SSM agent must be available on the AMI for `ResilienceTester.stop_application_on_instance` and `generate_cpu_load` to work — Amazon Linux 2023 includes SSM agent by default, but instances in private subnets need a VPC endpoint for SSM or NAT gateway access
- All configuration files are stored in `config/` directory as JSON for cross-script resource ID sharing
