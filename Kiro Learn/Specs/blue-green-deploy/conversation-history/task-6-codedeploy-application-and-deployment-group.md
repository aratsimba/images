# Task 6: CodeDeploy Application and Blue-Green Deployment Group

## Overview

Task 6 involved two subtasks:
- **6.1** — Create the CodeDeploy Application
- **6.2** — Create the Blue-Green Deployment Group

Both the Python implementation (writing the code) and the actual AWS resource provisioning (running the code) were completed.

## What Was Implemented

### `components/deployment_manager.py`

Six functions were added:

| Function | Purpose |
|----------|---------|
| `create_application(app_name)` | Registers a CodeDeploy app with `computePlatform='Server'`; handles `ApplicationAlreadyExistsException` gracefully |
| `list_deployment_configs()` | Lists available deployment configurations (AllAtOnce, HalfAtATime, etc.) |
| `create_blue_green_deployment_group(...)` | Creates a BLUE_GREEN deployment group with COPY_AUTO_SCALING_GROUP provisioning, ALB target group linkage, blue instance termination config, and auto-rollback |
| `create_deployment(...)` | Triggers a deployment with a specified revision and deployment config |
| `delete_deployment_group(app_name, group_name)` | Cleanup — deletes a deployment group |
| `delete_application(app_name)` | Cleanup — deletes a CodeDeploy application |

## Resources Provisioned

### CodeDeploy Application
- **Name**: `BlueGreenApp`
- **ID**: `f1725c38-bdab-42d1-af4e-49617d730aeb`
- **Compute Platform**: Server (EC2/On-Premises)

### Blue-Green Deployment Group
- **Name**: `BlueGreenDG`
- **ID**: `69dee672-4756-42af-8913-ed8567ea4fbe`
- **Deployment Type**: BLUE_GREEN
- **Deployment Option**: WITH_TRAFFIC_CONTROL
- **Green Fleet Provisioning**: COPY_AUTO_SCALING_GROUP
- **Auto Scaling Group**: BlueGreenASG
- **Target Group**: BlueGreenTG
- **Service Role**: `arn:aws:iam::628326705801:role/CodeDeployServiceRole`
- **Auto Rollback**: Enabled (DEPLOYMENT_FAILURE, DEPLOYMENT_STOP_ON_ALARM)
- **Blue Termination Wait**: 5 minutes

## Also Provisioned (Task 5 resources, done in same session)

Task 5 resources were provisioned alongside Task 6 since they had only been coded but not executed:

- **S3 Bucket**: `blue-green-deploy-revisions-628326705801`
- **Revision Bundle**: `s3://blue-green-deploy-revisions-628326705801/revisions/v1.zip`
  - Contains: `appspec.yml`, `src/index.html`, lifecycle hook scripts (`before_install.sh`, `after_install.sh`, `validate_service.sh`)

## Verification Commands

```bash
# Verify CodeDeploy application
aws deploy get-application --application-name BlueGreenApp

# Verify deployment group
aws deploy get-deployment-group --application-name BlueGreenApp --deployment-group-name BlueGreenDG

# Verify S3 revision
aws s3 ls s3://blue-green-deploy-revisions-628326705801/revisions/

# List deployment configs
aws deploy list-deployment-configs
```

## Lecture Notes

Before coding, a mini-lecture covered:
- What a CodeDeploy Application is (a named container for your deployment project)
- What a Deployment Group is (the configuration linking ASG, ALB, and deployment strategy)
- The restaurant analogy: blue = current dining room, green = new dining room, customers redirected seamlessly
- Why graceful error handling matters (idempotent scripts that can be re-run safely)
