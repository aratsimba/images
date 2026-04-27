# Deployment Manager - CodeDeploy application and deployment group

import boto3
from botocore.exceptions import ClientError

codedeploy = boto3.client("codedeploy")


# ---------------------------------------------------------------------------
# CodeDeploy Application
# ---------------------------------------------------------------------------

def create_application(app_name: str) -> str:
    """Create a CodeDeploy application for the EC2/On-Premises compute platform."""
    try:
        resp = codedeploy.create_application(
            applicationName=app_name,
            computePlatform="Server",
        )
        app_id = resp["applicationId"]
        print(f"Created CodeDeploy application '{app_name}' (id: {app_id})")
        return app_id
    except ClientError as e:
        if e.response["Error"]["Code"] == "ApplicationAlreadyExistsException":
            print(
                f"Application '{app_name}' already exists in this region. "
                "Using the existing application."
            )
            return app_name
        raise


def list_deployment_configs() -> list:
    """List available deployment configurations."""
    resp = codedeploy.list_deployment_configs()
    configs = resp.get("deploymentConfigsList", [])
    print("Available deployment configurations:")
    for cfg in configs:
        print(f"  - {cfg}")
    return configs


# ---------------------------------------------------------------------------
# Blue-Green Deployment Group
# ---------------------------------------------------------------------------

def create_blue_green_deployment_group(
    app_name: str,
    group_name: str,
    service_role_arn: str,
    asg_name: str,
    target_group_name: str,
    auto_rollback_enabled: bool = True,
    termination_wait_minutes: int = 5,
) -> str:
    """Create a blue-green deployment group linked to an ASG and ALB target group."""
    params = dict(
        applicationName=app_name,
        deploymentGroupName=group_name,
        serviceRoleArn=service_role_arn,
        deploymentStyle={
            "deploymentType": "BLUE_GREEN",
            "deploymentOption": "WITH_TRAFFIC_CONTROL",
        },
        autoScalingGroups=[asg_name],
        loadBalancerInfo={
            "targetGroupInfoList": [{"name": target_group_name}],
        },
        blueGreenDeploymentConfiguration={
            "terminateBlueInstancesOnDeploymentSuccess": {
                "action": "TERMINATE",
                "terminationWaitTimeInMinutes": termination_wait_minutes,
            },
            "deploymentReadyOption": {
                "actionOnTimeout": "CONTINUE_DEPLOYMENT",
                "waitTimeInMinutes": 0,
            },
            "greenFleetProvisioningOption": {
                "action": "COPY_AUTO_SCALING_GROUP",
            },
        },
    )

    if auto_rollback_enabled:
        params["autoRollbackConfiguration"] = {
            "enabled": True,
            "events": [
                "DEPLOYMENT_FAILURE",
                "DEPLOYMENT_STOP_ON_ALARM",
            ],
        }

    try:
        resp = codedeploy.create_deployment_group(**params)
        dg_id = resp["deploymentGroupId"]
        print(
            f"Created blue-green deployment group '{group_name}' "
            f"(id: {dg_id}) for application '{app_name}'"
        )
        return dg_id
    except ClientError as e:
        if e.response["Error"]["Code"] == "DeploymentGroupAlreadyExistsException":
            print(
                f"Deployment group '{group_name}' already exists for "
                f"application '{app_name}'. Using the existing group."
            )
            return group_name
        raise


# ---------------------------------------------------------------------------
# Create Deployment
# ---------------------------------------------------------------------------

def create_deployment(
    app_name: str,
    group_name: str,
    revision_location: dict,
    deployment_config_name: str = "CodeDeployDefault.AllAtOnce",
    description: str = "",
) -> str:
    """Trigger a deployment for the given application and deployment group."""
    resp = codedeploy.create_deployment(
        applicationName=app_name,
        deploymentGroupName=group_name,
        revision=revision_location,
        deploymentConfigName=deployment_config_name,
        description=description or f"Deployment to {group_name}",
    )
    deployment_id = resp["deploymentId"]
    print(
        f"Created deployment {deployment_id} "
        f"(config: {deployment_config_name})"
    )
    return deployment_id


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

def delete_deployment_group(app_name: str, group_name: str) -> None:
    """Delete a deployment group from a CodeDeploy application."""
    try:
        codedeploy.delete_deployment_group(
            applicationName=app_name,
            deploymentGroupName=group_name,
        )
        print(f"Deleted deployment group '{group_name}' from '{app_name}'")
    except ClientError as e:
        if e.response["Error"]["Code"] in (
            "DeploymentGroupDoesNotExistException",
            "ApplicationDoesNotExistException",
        ):
            print(f"Deployment group '{group_name}' does not exist, skipping")
        else:
            raise


def delete_application(app_name: str) -> None:
    """Delete a CodeDeploy application and all associated deployment groups."""
    try:
        codedeploy.delete_application(applicationName=app_name)
        print(f"Deleted CodeDeploy application '{app_name}'")
    except ClientError as e:
        if e.response["Error"]["Code"] == "ApplicationDoesNotExistException":
            print(f"Application '{app_name}' does not exist, skipping")
        else:
            raise
