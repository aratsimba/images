

# Implementation Plan: Deploy and Scale a Web Application on Amazon EC2

## Overview

This implementation plan guides you through progressively building a scalable web application architecture on Amazon EC2 using Python and boto3. The approach starts with foundational setup — configuring security groups and launching a single EC2 instance running a web server — then expands to a multi-Availability Zone deployment behind an Application Load Balancer, and finally adds Auto Scaling with dynamic scaling policies to handle variable demand automatically.

The plan is organized into three phases. Phase one covers the core building blocks: security group configuration, launching an EC2 instance with a user data script, and verifying the web server is accessible. Phase two introduces high availability by creating a launch template, deploying instances across multiple AZs, and setting up an Application Load Balancer with a target group and health checks. Phase three adds Auto Scaling with a target tracking policy based on CPU utilization, followed by load simulation and scaling verification to validate the complete architecture.

Each phase builds on the previous one, so tasks must be completed in order. All AWS resources are created programmatically via boto3 within the default VPC. A final cleanup task ensures all resources are deleted to avoid ongoing charges. Key checkpoints are placed after the single-instance deployment and after the full Auto Scaling setup to validate correctness at each milestone.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account (free-tier eligible recommended)
    - Configure AWS CLI: `aws configure` (set access key, secret key, default region)
    - Verify access: `aws sts get-caller-identity`
    - Confirm IAM permissions for EC2, Elastic Load Balancing, Auto Scaling, and SSM
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Install AWS CLI v2: verify with `aws --version`
    - Create project directory structure: `mkdir -p components`
    - Create `components/__init__.py`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create an EC2 key pair in the target region (if not already created): `aws ec2 create-key-pair --key-name my-web-key --query 'KeyMaterial' --output text > my-web-key.pem && chmod 400 my-web-key.pem`
    - Look up the latest Amazon Linux 2023 AMI ID for your region: `aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text`
    - Note the default VPC ID: `aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text`
    - _Requirements: (all)_

- [ ] 2. Implement SecurityGroupManager and Configure Web Traffic Rules
  - [ ] 2.1 Create the SecurityGroupManager component
    - Create `components/security_group_manager.py`
    - Initialize with `boto3.client('ec2')`
    - Implement `create_security_group(group_name, description, vpc_id)` using `create_security_group` API, return the group ID
    - Implement `add_inbound_rule(group_id, protocol, port, cidr)` using `authorize_security_group_ingress`
    - Implement `remove_inbound_rule(group_id, protocol, port, cidr)` using `revoke_security_group_ingress`
    - Implement `describe_security_group(group_id)` using `describe_security_groups`, return rule details as a dictionary
    - Implement `delete_security_group(group_id)` using `delete_security_group`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - [ ] 2.2 Create a security group and configure inbound rules
    - Write a script (e.g., `scripts/setup_security_group.py`) that uses `SecurityGroupManager`
    - Create a security group named `web-server-sg` in the default VPC
    - Add inbound rule: HTTP port 80 from `0.0.0.0/0` (public web access)
    - Add inbound rule: SSH port 22 from your IP only (find your IP: `curl -s https://checkip.amazonaws.com`)
    - Call `describe_security_group` to verify both rules are present
    - Verify: `aws ec2 describe-security-groups --group-ids <sg-id> --query 'SecurityGroups[0].IpPermissions'`
    - _Requirements: 2.1, 2.2, 2.4_

- [ ] 3. Implement InstanceManager and Launch a Web Server
  - [ ] 3.1 Create the InstanceManager component
    - Create `components/instance_manager.py`
    - Initialize with `boto3.resource('ec2')` and `boto3.client('ec2')`
    - Implement `launch_instance(ami_id, instance_type, key_name, security_group_id, subnet_id, user_data)` — launch a single instance with tags (e.g., `Name: WebServer`), return instance ID
    - Implement `wait_until_running(instance_id)` using the EC2 instance waiter `instance_running`
    - Implement `get_instance_info(instance_id)` — return an `InstanceInfo` dict with `instance_id`, `public_ip`, `public_dns`, `availability_zone`, `state`, `instance_type`
    - Implement `list_instances_by_tag(tag_key, tag_value)` using `describe_instances` with tag filters, returning a list of `InstanceInfo` dicts
    - Implement `terminate_instance(instance_id)` using `terminate_instances`
    - Implement `get_default_vpc_subnets()` — use `describe_subnets` filtered by the default VPC, return list of `SubnetInfo` dicts (`subnet_id`, `availability_zone`, `vpc_id`)
    - _Requirements: 1.1, 1.4, 3.1, 3.2_
  - [ ] 3.2 Launch an EC2 instance with a web server user data script
    - Define a user data script (bash) that installs and starts httpd (Apache) and creates an `index.html` with "Hello, World!" content including the instance ID
    - Use `InstanceManager.get_default_vpc_subnets()` to select a subnet
    - Launch an instance with `t2.micro` (free-tier eligible), the Amazon Linux 2023 AMI, your key pair, and the security group from Task 2
    - Call `wait_until_running` then `get_instance_info` to retrieve the public IP and DNS
    - Verify: open `http://<public-ip>` in a browser or `curl http://<public-ip>` to see the Hello World page
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 7.1_

- [ ] 4. Checkpoint - Validate Single Instance Web Server
  - Access `http://<public-ip>` in a browser and confirm the Hello World page loads
  - Test security group rule removal: use `SecurityGroupManager.remove_inbound_rule` to remove the HTTP rule, then verify `curl http://<public-ip>` times out
  - Restore the HTTP rule with `SecurityGroupManager.add_inbound_rule` and confirm access resumes without restarting the instance
  - Verify SSH access from your IP: `ssh -i my-web-key.pem ec2-user@<public-ip>`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement LoadBalancerManager and Deploy Multi-AZ Architecture
  - [ ] 5.1 Create the LoadBalancerManager component
    - Create `components/load_balancer_manager.py`
    - Initialize with `boto3.client('elbv2')`
    - Implement `create_target_group(name, vpc_id, port, health_check_path)` — create an HTTP target group with health check on the specified path (e.g., `/`), return target group ARN
    - Implement `create_load_balancer(name, subnet_ids, security_group_id)` — create an internet-facing ALB spanning subnets in at least 2 AZs, return `LoadBalancerInfo` dict (`arn`, `dns_name`, `hosted_zone_id`)
    - Implement `create_listener(load_balancer_arn, target_group_arn, port)` — create an HTTP listener on port 80 forwarding to the target group, return listener ARN
    - Implement `register_targets(target_group_arn, instance_ids)` and `deregister_targets(target_group_arn, instance_ids)`
    - Implement `get_target_health(target_group_arn)` — return list of `TargetHealthInfo` dicts (`instance_id`, `port`, `health_state`, `reason`)
    - Implement `wait_until_available(load_balancer_arn)` using the `load_balancer_available` waiter
    - Implement `delete_load_balancer(load_balancer_arn)` and `delete_target_group(target_group_arn)`
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 5.2 Launch multiple instances and set up the ALB
    - Use `InstanceManager.get_default_vpc_subnets()` to identify subnets in at least 2 AZs
    - Launch 2 EC2 instances (using `InstanceManager`) in different AZ subnets with the same user data script, AMI, instance type, security group, and key pair
    - Create a target group with health check path `/`
    - Create an internet-facing ALB spanning the 2+ AZ subnets with the web security group
    - Create an HTTP listener on port 80 forwarding to the target group
    - Register both instances in the target group
    - Wait for ALB to become available, then verify: `curl http://<alb-dns-name>` returns the Hello World page
    - Call `get_target_health` to confirm both instances show `healthy`
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4_
  - [ ]* 5.3 Verify load balancer health check behavior
    - **Property 1: Unhealthy Instance Traffic Removal**
    - Stop the web server on one instance via SSM or terminate it, then call `get_target_health` to observe it becoming `unhealthy`
    - Confirm `curl http://<alb-dns-name>` still works (served by the healthy instance)
    - Restart or replace the instance and confirm it returns to `healthy` status
    - **Validates: Requirements 3.3, 4.3**

- [ ] 6. Checkpoint - Validate Multi-AZ Load-Balanced Deployment
  - Access `http://<alb-dns-name>` multiple times and observe traffic distribution (different instance IDs in the page if displayed)
  - Verify `get_target_health` shows all instances as healthy
  - Terminate one instance and confirm the web application remains accessible via the ALB
  - Confirm instances are in different Availability Zones via `get_instance_info`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Implement AutoScalingManager with Launch Template and Scaling Policy
  - [ ] 7.1 Create the AutoScalingManager component
    - Create `components/auto_scaling_manager.py`
    - Initialize with `boto3.client('autoscaling')` and `boto3.client('ec2')`
    - Implement `create_launch_template(name, ami_id, instance_type, key_name, security_group_id, user_data)` — create an EC2 launch template with all specified settings, return template ID
    - Implement `create_auto_scaling_group(name, launch_template_id, min_size, max_size, desired_capacity, subnet_ids, target_group_arn)` — create an ASG across specified subnets, attached to the target group
    - Implement `set_target_tracking_policy(asg_name, policy_name, target_cpu_percent)` — configure a target tracking scaling policy on `ASGAverageCPUUtilization`
    - Implement `describe_auto_scaling_group(asg_name)` — return `AutoScalingGroupInfo` dict
    - Implement `get_scaling_activities(asg_name)` — return list of `ScalingActivity` dicts
    - Implement `update_capacity(asg_name, min_size, max_size, desired)` — update ASG capacity settings
    - Implement `delete_auto_scaling_group(asg_name, force_delete)` and `delete_launch_template(template_id)`
    - _Requirements: 3.2, 5.1, 5.2, 5.3, 5.4_
  - [ ] 7.2 Create launch template, ASG, and scaling policy
    - Terminate previously manually-launched instances (from Tasks 3 and 5) to avoid duplicates
    - Create a launch template with the same AMI, `t2.micro`, key pair, security group, and user data as before
    - Create a new target group (or reuse the existing one after deregistering old targets)
    - Create an Auto Scaling group: `min_size=2`, `max_size=4`, `desired_capacity=2`, spanning 2+ AZ subnets, attached to the target group
    - Set a target tracking policy: `target_cpu_percent=50` (scale when average CPU exceeds 50%)
    - Wait for ASG instances to launch; call `describe_auto_scaling_group` to confirm 2 running instances across different AZs
    - Update the ALB listener to forward to the ASG's target group (if a new target group was created)
    - Verify: `curl http://<alb-dns-name>` returns the web page served by ASG-managed instances
    - _Requirements: 3.1, 3.2, 5.1, 5.2, 5.3, 5.4, 7.1, 7.2_

- [ ] 8. Implement ScalingVerifier and Validate Scaling Behavior
  - [ ] 8.1 Create the ScalingVerifier component
    - Create `components/scaling_verifier.py`
    - Initialize with `boto3.client('ssm')` and `boto3.client('autoscaling')`
    - Implement `simulate_cpu_load(instance_ids, duration_seconds)` — use SSM `send_command` to run a CPU stress command (e.g., `stress-ng --cpu 4 --timeout <duration>s` or a `dd` loop) on target instances, return command IDs
    - Implement `poll_instance_count(asg_name, interval_seconds, max_polls)` — periodically call `describe_auto_scaling_group` and return list of `CapacitySnapshot` dicts (`timestamp`, `instance_count`, `desired_capacity`)
    - Implement `get_recent_scaling_activities(asg_name, max_results)` — call `describe_scaling_activities` and return list of `ScalingActivity` dicts
    - Implement `wait_for_capacity_change(asg_name, expected_count, timeout_seconds)` — poll until instance count matches expected or timeout, return boolean
    - Note: Ensure instances have the SSM Agent running (Amazon Linux 2023 includes it by default) and an IAM instance profile with `AmazonSSMManagedInstanceCore` policy attached — add this to the launch template if not already configured
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - [ ] 8.2 Simulate load and verify scale-out and scale-in
    - Use `simulate_cpu_load` to stress the 2 running instances for 300 seconds
    - Use `poll_instance_count` to observe the ASG launching additional instances (up to max 4)
    - Use `wait_for_capacity_change` to confirm instance count increases beyond 2
    - Call `get_recent_scaling_activities` to view launch events and their causes
    - Verify the ALB continues serving traffic during scale-out: `curl http://<alb-dns-name>`
    - After the stress test ends, use `poll_instance_count` to observe scale-in back toward 2 instances
    - _Requirements: 6.1, 6.3, 6.4, 5.2, 5.3_
  - [ ] 8.3 Verify instance replacement on termination
    - Manually terminate one ASG instance: use `InstanceManager.terminate_instance` on one of the running instances
    - Use `wait_for_capacity_change` to confirm the ASG launches a replacement to maintain desired capacity of 2
    - Call `get_recent_scaling_activities` to confirm the replacement event is recorded
    - Verify the ALB serves traffic without interruption during the replacement
    - _Requirements: 6.2, 6.3, 6.4_

- [ ] 9. Checkpoint - Validate Complete Scalable Architecture
  - Confirm `describe_auto_scaling_group` shows the ASG with min=2, max=4, and 2 healthy instances across 2+ AZs
  - Confirm `get_target_health` shows all ASG instances as healthy in the target group
  - Review scaling activity history to verify both scale-out and scale-in events occurred with proper causes
  - Access `http://<alb-dns-name>` and confirm the web application is served reliably
  - Verify the architecture handles instance termination by replacing instances automatically
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete Auto Scaling resources
    - Set ASG desired/min/max to 0 first, or use force delete: `AutoScalingManager.delete_auto_scaling_group(asg_name, force_delete=True)`
    - Wait for all ASG instances to terminate: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name>` until empty
    - Delete the launch template: `AutoScalingManager.delete_launch_template(template_id)`
    - Verify: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name>` returns empty
    - _Requirements: 7.3_
  - [ ] 10.2 Delete Load Balancer resources
    - Delete the ALB listener (deleted automatically with ALB)
    - Delete the ALB: `LoadBalancerManager.delete_load_balancer(load_balancer_arn)`
    - Wait for ALB deletion to complete: `aws elbv2 describe-load-balancers --names <alb-name>` should return not found
    - Delete the target group: `LoadBalancerManager.delete_target_group(target_group_arn)`
    - Verify: `aws elbv2 describe-target-groups --names <tg-name>` returns not found
    - _Requirements: 7.3_
  - [ ] 10.3 Delete remaining EC2 resources
    - Terminate any remaining EC2 instances (from earlier tasks if not already terminated): `InstanceManager.terminate_instance(instance_id)` for each
    - Delete the security group (after all instances using it are terminated): `SecurityGroupManager.delete_security_group(group_id)`
    - Verify no instances remain: `aws ec2 describe-instances --filters "Name=tag:Name,Values=WebServer" "Name=instance-state-name,Values=running"` returns empty
    - Verify security group deleted: `aws ec2 describe-security-groups --group-ids <sg-id>` returns not found
    - Optionally delete the key pair if no longer needed: `aws ec2 delete-key-pair --key-name my-web-key`
    - **Warning**: Ensure all resources are deleted to stop incurring charges. Check the EC2 console for any running instances, load balancers, or target groups.
    - _Requirements: 7.3_

## Notes

- Tasks marked with `*` are optional property tests that provide deeper validation but can be skipped for a faster learning path
- Each task references specific requirements (e.g., `_Requirements: 1.1, 2.3_`) for traceability back to the requirements document
- Checkpoints ensure incremental validation — do not proceed past a checkpoint until all validations pass
- The user data script must include `#!/bin/bash` and install `stress-ng` or equivalent for the scaling verification in Task 8 to work
- Amazon Linux 2023 includes the SSM Agent by default, but instances need an IAM instance profile with `AmazonSSMManagedInstanceCore` to use SSM Run Command — configure this in the launch template
- All resources are created in the default VPC to simplify networking; no custom VPC setup is needed
- Use `t2.micro` instances throughout to stay within free-tier eligibility and minimize costs (Requirement 7.1)
