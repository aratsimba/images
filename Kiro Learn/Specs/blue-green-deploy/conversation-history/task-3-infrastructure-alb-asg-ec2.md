# Task 3: Infrastructure — ALB, Auto Scaling Group, and EC2 Instances

**Started:** 2026-04-10
**Completed:** 2026-04-10

## Overview

Built the networking and compute infrastructure layer for the blue-green deployment pipeline — the Application Load Balancer, target group, listener, launch template, and Auto Scaling group.

## Key Concepts Discussed

- **Application Load Balancer (ALB)** — the "traffic cop" that directs user requests to healthy servers; lives across multiple availability zones for reliability
- **Target Group** — a registry of healthy servers the ALB can route to; includes health check settings (interval 30s, healthy threshold 2)
- **Listener** — the rule connecting the ALB's front door (port 80) to a target group; without it, the ALB has no instructions on where to send traffic
- **Launch Template** — a "recipe" for building identical EC2 instances (AMI, instance type, user data, security group, IAM profile)
- **Auto Scaling Group (ASG)** — ensures the right number of instances are always running (desired capacity of 2); attaches instances to the target group automatically
- **Health Checks** — the ALB pings each server's `/` path every 30 seconds; if a server doesn't respond, it stops receiving traffic

### Analogies Used

- ALB as a traffic cop at an intersection directing cars (requests) to open neighborhoods (servers)
- Target group as the cop's list of houses open for business
- Health checks as the host peeking into restaurant kitchens to see if they're still serving
- Launch template as a recipe, ASG as the kitchen manager ensuring the right number of cooks

## Code Written

**File:** `blue-green-deploy/components/infra_manager.py`

### Functions Implemented

| Function | Purpose |
|----------|---------|
| `create_application_load_balancer(alb_name, subnet_ids, security_group_id)` | Creates internet-facing ALB across subnets, returns ARN |
| `create_target_group(tg_name, vpc_id, health_check_path)` | Creates HTTP target group with health checks (30s interval, threshold 2) |
| `create_listener(alb_arn, target_group_arn, port)` | Creates HTTP listener forwarding traffic to target group |
| `get_target_group_health(target_group_arn)` | Queries and prints registered target health status |
| `create_launch_template(template_name, ami_id, instance_type, instance_profile_name, security_group_id, user_data_script)` | Creates EC2 launch template with base64-encoded user data |
| `create_auto_scaling_group(asg_name, launch_template_id, target_group_arn, subnet_ids, desired_capacity)` | Creates ASG with `Name=BlueGreenDemo` tag, target group attachment |
| `delete_infrastructure(alb_arn, target_group_arn, asg_name, launch_template_id)` | Tears down all infra in correct dependency order |

### boto3 Clients Used

- `boto3.client('elbv2')` — ALB, target groups, listeners
- `boto3.client('ec2')` — launch templates
- `boto3.client('autoscaling')` — Auto Scaling groups
- `boto3.client('ssm')` — AMI lookup (for later use)

### Design Patterns

- Module-level boto3 clients (matching `iam_setup.py` style)
- Idempotent error handling: `DuplicateLoadBalancerName`, `DuplicateTargetGroupName`, `DuplicateListener`, `InvalidLaunchTemplateName.AlreadyExistsException`, `AlreadyExists` (ASG)
- Print statements for progress tracking
- `delete_infrastructure()` follows correct teardown order: ASG (force-delete) → launch template → listeners → target group → ALB

## Verification Steps

- `aws elbv2 describe-load-balancers --names BlueGreenALB`
- `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names BlueGreenASG`

## Issues Encountered

None — implementation was clean with no diagnostics errors.
