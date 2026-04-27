# Task 7: Checkpoint - Validate CodeDeploy Configuration

## Objective

Validate that all CodeDeploy resources are properly configured before executing deployments. This is a pre-flight checklist covering the application, deployment group, S3 revision, and available deployment configurations.

## Validation Steps and Results

### 1. CodeDeploy Application Exists

**Command:** `aws deploy get-application --application-name BlueGreenApp`

**Result:** ✅ Pass

```json
{
    "application": {
        "applicationId": "f1725c38-bdab-42d1-af4e-49617d730aeb",
        "applicationName": "BlueGreenApp",
        "createTime": 1775853737.023,
        "linkedToGitHub": false,
        "computePlatform": "Server"
    }
}
```

### 2. Deployment Group Configuration (Blue-Green with ALB and ASG)

**Command:** `aws deploy get-deployment-group --application-name BlueGreenApp --deployment-group-name BlueGreenDG`

**Result:** ✅ Pass

Key configuration verified:
- **Deployment Style:** `BLUE_GREEN` with `WITH_TRAFFIC_CONTROL`
- **Auto Scaling Group:** `BlueGreenASG` linked
- **Load Balancer / Target Group:** `BlueGreenTG` linked
- **Green Fleet Provisioning:** `COPY_AUTO_SCALING_GROUP`
- **Blue Instance Termination:** `TERMINATE` with 5-minute wait
- **Auto Rollback:** Enabled for `DEPLOYMENT_FAILURE` and `DEPLOYMENT_STOP_ON_ALARM`
- **Service Role:** `arn:aws:iam::628326705801:role/CodeDeployServiceRole`


Full deployment group response:

```json
{
    "deploymentGroupInfo": {
        "applicationName": "BlueGreenApp",
        "deploymentGroupId": "69dee672-4756-42af-8913-ed8567ea4fbe",
        "deploymentGroupName": "BlueGreenDG",
        "deploymentConfigName": "CodeDeployDefault.OneAtATime",
        "autoScalingGroups": [
            {
                "name": "BlueGreenASG",
                "hook": "CodeDeploy-managed-automatic-launch-deployment-hook-BlueGreenDG-c8286fbc-5eb4-4bac-97d1-37c95779c4ad"
            }
        ],
        "serviceRoleArn": "arn:aws:iam::628326705801:role/CodeDeployServiceRole",
        "autoRollbackConfiguration": {
            "enabled": true,
            "events": ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
        },
        "deploymentStyle": {
            "deploymentType": "BLUE_GREEN",
            "deploymentOption": "WITH_TRAFFIC_CONTROL"
        },
        "blueGreenDeploymentConfiguration": {
            "terminateBlueInstancesOnDeploymentSuccess": {
                "action": "TERMINATE",
                "terminationWaitTimeInMinutes": 5
            },
            "deploymentReadyOption": {
                "actionOnTimeout": "CONTINUE_DEPLOYMENT",
                "waitTimeInMinutes": 0
            },
            "greenFleetProvisioningOption": {
                "action": "COPY_AUTO_SCALING_GROUP"
            }
        },
        "loadBalancerInfo": {
            "targetGroupInfoList": [{"name": "BlueGreenTG"}]
        },
        "computePlatform": "Server"
    }
}
```

### 3. S3 Revision Bundle Accessible

**Command:** `aws s3 ls s3://blue-green-deploy-revisions-628326705801/revisions/`

**Result:** ✅ Pass

```
2026-04-10 16:41:07       1575 v1.zip
```

The revision bundle `v1.zip` (1,575 bytes) is present and accessible in the S3 bucket.

### 4. Available Deployment Configurations

**Command:** `aws deploy list-deployment-configs`

**Result:** ✅ Pass

17 deployment configurations available. The EC2/Server-relevant ones are:
- `CodeDeployDefault.AllAtOnce` — shifts all traffic in one step
- `CodeDeployDefault.HalfAtATime` — deploys to half the instances at a time
- `CodeDeployDefault.OneAtATime` — deploys to one instance at a time

(Lambda and ECS configs are also listed but not applicable to this EC2-based project.)

## Summary

| Check | Status | Details |
|-------|--------|---------|
| CodeDeploy Application | ✅ | `BlueGreenApp` exists, compute platform = Server |
| Deployment Group | ✅ | `BlueGreenDG` — BLUE_GREEN with WITH_TRAFFIC_CONTROL |
| ASG Reference | ✅ | Linked to `BlueGreenASG` |
| ALB/Target Group | ✅ | Linked to `BlueGreenTG` |
| Green Fleet Provisioning | ✅ | COPY_AUTO_SCALING_GROUP |
| Blue Instance Termination | ✅ | TERMINATE after 5 min wait |
| Auto Rollback | ✅ | Enabled for DEPLOYMENT_FAILURE and DEPLOYMENT_STOP_ON_ALARM |
| S3 Revision | ✅ | v1.zip present in bucket |
| Deployment Configs | ✅ | 17 configs available (AllAtOnce, HalfAtATime, OneAtATime for EC2) |

All validations passed. Infrastructure is ready for deployment execution in Task 8.
