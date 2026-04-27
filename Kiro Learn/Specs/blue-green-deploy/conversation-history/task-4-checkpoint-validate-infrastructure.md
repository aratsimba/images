# Task 4: Checkpoint — Validate Infrastructure

**Started:** 2026-04-10
**Completed:** 2026-04-10

## Overview

Ran the pre-flight checklist to confirm all infrastructure from Tasks 2 and 3 was healthy and ready for CodeDeploy deployments. Discovered that the Python scripts had been written but never executed, so we provisioned the resources first, then validated all four checkpoint criteria.

## Key Concepts Discussed

- **Infrastructure Checkpoint** — a verification gate ensuring all provisioned resources are operational before moving to the next phase; like a pilot's pre-flight checklist
- **ASG Lifecycle States** — instances transition through `Pending` → `InService`; only `InService` instances receive traffic and participate in deployments
- **CodeDeploy Agent** — a small daemon running on each EC2 instance that listens for deployment instructions from the CodeDeploy service; verified via AWS Systems Manager (SSM)
- **Target Group Health Checks** — the ALB periodically pings each instance on port 80 at path `/`; targets must show `healthy` before deployments can succeed
- **End-to-End Validation** — hitting the ALB DNS endpoint with `curl` to confirm the full chain works: internet → ALB → target group → EC2 instance → Apache response

### Analogies Used

- Checkpoint as a restaurant soft opening — checking ovens work, doors are unlocked, waitstaff can reach tables
- ASG InService as kitchen staff showing up for their shift
- CodeDeploy agent as the delivery system being plugged in
- Target group health as the front door connecting to the dining room
- ALB endpoint test as a test customer placing an order

## Provisioning Performed

Infrastructure had not been created by Tasks 2/3 (scripts were written but not run). Provisioned all resources before validation:

### IAM Resources (Task 2)
- Created `CodeDeployServiceRole` with `AWSCodeDeployRole` managed policy
- Created `CodeDeployEC2Role` with `AmazonS3ReadOnlyAccess` and `AmazonSSMManagedInstanceCore`
- Created `CodeDeployInstanceProfile` instance profile

### Infrastructure Resources (Task 3)
- Created ALB `BlueGreenALB` (DNS: `BlueGreenALB-886007790.us-east-1.elb.amazonaws.com`)
- Created target group `BlueGreenTG` with health checks on `/`
- Created HTTP listener on port 80
- Looked up Amazon Linux 2023 AMI (`ami-0ea87431b78a82070`) via SSM parameter
- Created launch template `BlueGreenLT` (`lt-03cc5fb00f36d8c51`) with user data installing Apache and CodeDeploy agent
- Created ASG `BlueGreenASG` with desired capacity of 2 across two subnets

## Validation Results

| Check | Command | Result |
|-------|---------|--------|
| ASG Instance State | `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names BlueGreenASG` | Both instances `InService` / `Healthy` |
| CodeDeploy Agent | `aws ssm send-command` with `systemctl status codedeploy-agent` | `active (running)` on both instances |
| Target Group Health | `aws elbv2 describe-target-health --target-group-arn <tg-arn>` | Both targets `healthy` on port 80 |
| ALB Endpoint | `curl http://BlueGreenALB-886007790.us-east-1.elb.amazonaws.com/` | HTTP 200, body: `<h1>Blue-Green Demo - Blue Environment</h1>` |

### Instance Details

| Instance ID | AZ | CodeDeploy Agent | Target Health |
|-------------|-----|-------------------|---------------|
| `i-0426bac3d62e7d40a` | us-east-1a | Running | Healthy |
| `i-0e5debb354d390c70` | us-east-1b | Running | Healthy |

## Issues Encountered

### 1. Infrastructure Not Provisioned
- **Problem:** Tasks 2 and 3 only described implementing the Python functions, not running them to create actual AWS resources
- **Resolution:** Ran the IAM setup and infrastructure manager functions before performing checkpoint validation
- **Follow-up:** Added explicit provisioning sub-tasks (2.3 and 3.3) to `tasks.md` so future learners know to run the scripts

### 2. Incorrect AWSCodeDeployRole Policy ARN
- **Problem:** `iam_setup.py` used `arn:aws:iam::aws:policy/AWSCodeDeployRole` which doesn't exist
- **Resolution:** Corrected to `arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole` (the policy lives under the `service-role/` path)
- **File Modified:** `blue-green-deploy/components/iam_setup.py`

## Tasks.md Updates

Added two new sub-tasks to prevent the provisioning gap for future learners:
- **2.3 Provision IAM Resources** — explicitly calls `create_codedeploy_service_role()` and `create_ec2_instance_profile()`
- **3.3 Provision Infrastructure Resources** — explicitly calls all infra functions (ALB, target group, listener, launch template, ASG) with a note to wait for instance boot
