# Deployment Monitor - Status tracking, lifecycle events, deployment history

import time
import boto3
from botocore.exceptions import ClientError

codedeploy = boto3.client("codedeploy")


# ---------------------------------------------------------------------------
# Deployment Status
# ---------------------------------------------------------------------------

def get_deployment_status(deployment_id: str) -> dict:
    """Return DeploymentStatus data for a given deployment.

    Keys: deployment_id, status, deployment_config, create_time,
          complete_time, rollback_info, error_info
    """
    resp = codedeploy.get_deployment(deploymentId=deployment_id)
    info = resp["deploymentInfo"]

    result = {
        "deployment_id": info["deploymentId"],
        "status": info["status"],
        "deployment_config": info.get("deploymentConfigName", ""),
        "create_time": info.get("createTime"),
        "complete_time": info.get("completeTime"),
        "rollback_info": info.get("rollbackInfo"),
        "error_info": info.get("errorInformation"),
    }
    return result


# ---------------------------------------------------------------------------
# Instance Targets
# ---------------------------------------------------------------------------

def get_instance_targets(deployment_id: str) -> list:
    """Retrieve InstanceTarget details for every target in the deployment."""
    # First, list the target IDs
    target_ids = []
    try:
        resp = codedeploy.list_deployment_targets(deploymentId=deployment_id)
        target_ids = resp.get("targetIds", [])
    except ClientError as e:
        print(f"  Could not list targets: {e}")
        return []

    if not target_ids:
        return []

    # Batch-fetch target details
    resp = codedeploy.batch_get_deployment_targets(
        deploymentId=deployment_id,
        targetIds=target_ids,
    )

    targets = []
    for t in resp.get("deploymentTargets", []):
        instance_target = t.get("instanceTarget") or t.get("ecsTarget") or {}
        lifecycle_events = instance_target.get("lifecycleEvents", [])
        targets.append({
            "target_id": t.get("deploymentTargetType", "") + ":" + (instance_target.get("targetId") or t.get("instanceTarget", {}).get("targetId", "")),
            "status": instance_target.get("status", "Unknown"),
            "lifecycle_events": [
                {
                    "event_name": le.get("lifecycleEventName", ""),
                    "status": le.get("status", ""),
                    "start_time": le.get("startTime"),
                    "end_time": le.get("endTime"),
                    "diagnostics": le.get("diagnostics"),
                }
                for le in lifecycle_events
            ],
        })
    return targets


# ---------------------------------------------------------------------------
# Lifecycle Events
# ---------------------------------------------------------------------------

def get_lifecycle_events(deployment_id: str, target_id: str) -> list:
    """Retrieve LifecycleEvent data for a specific target in a deployment."""
    resp = codedeploy.batch_get_deployment_targets(
        deploymentId=deployment_id,
        targetIds=[target_id],
    )

    events = []
    for t in resp.get("deploymentTargets", []):
        instance_target = t.get("instanceTarget") or t.get("ecsTarget") or {}
        for le in instance_target.get("lifecycleEvents", []):
            events.append({
                "event_name": le.get("lifecycleEventName", ""),
                "status": le.get("status", ""),
                "start_time": le.get("startTime"),
                "end_time": le.get("endTime"),
                "diagnostics": le.get("diagnostics"),
            })
    return events


# ---------------------------------------------------------------------------
# Wait / Poll
# ---------------------------------------------------------------------------

TERMINAL_STATUSES = {"Succeeded", "Failed", "Stopped", "Ready"}


def wait_for_deployment(deployment_id: str, poll_interval_seconds: int = 15) -> str:
    """Poll deployment status every N seconds until it reaches a terminal state.

    Prints status updates to stdout. Returns the final status string.
    """
    print(f"\n{'='*60}")
    print(f"  Monitoring deployment: {deployment_id}")
    print(f"{'='*60}\n")

    while True:
        status_data = get_deployment_status(deployment_id)
        status = status_data["status"]
        config = status_data["deployment_config"]
        print(f"  [{time.strftime('%H:%M:%S')}]  Status: {status}  (config: {config})")

        if status in TERMINAL_STATUSES:
            print(f"\n  Deployment reached terminal status: {status}")
            if status_data.get("error_info"):
                err = status_data["error_info"]
                print(f"  Error code: {err.get('code', 'N/A')}")
                print(f"  Error message: {err.get('message', 'N/A')}")
            if status_data.get("rollback_info"):
                rb = status_data["rollback_info"]
                print(f"  Rollback triggered by: {rb.get('rollbackTriggeringDeploymentId', 'N/A')}")
                print(f"  Rollback message: {rb.get('rollbackMessage', 'N/A')}")
            print()
            return status

        time.sleep(poll_interval_seconds)


# ---------------------------------------------------------------------------
# Stop Deployment
# ---------------------------------------------------------------------------

def stop_deployment(deployment_id: str, auto_rollback: bool = True) -> None:
    """Stop an in-progress deployment.

    Args:
        deployment_id: The deployment to stop.
        auto_rollback: If True, CodeDeploy will roll back to the last known
                       good revision. Defaults to True.
    """
    try:
        codedeploy.stop_deployment(
            deploymentId=deployment_id,
            autoRollbackEnabled=auto_rollback,
        )
        print(f"  Stop requested for deployment {deployment_id} "
              f"(autoRollback={auto_rollback})")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        msg = e.response["Error"]["Message"]
        if code == "DeploymentAlreadyCompletedException":
            print(f"  Deployment {deployment_id} already completed — cannot stop.")
        else:
            print(f"  Error stopping deployment {deployment_id}: {code} — {msg}")


# ---------------------------------------------------------------------------
# Deployment History
# ---------------------------------------------------------------------------

def list_deployments(app_name: str, group_name: str) -> list:
    """Retrieve deployment history for an application / deployment group.

    Returns a list of DeploymentStatus dictionaries (most recent first).
    """
    resp = codedeploy.list_deployments(
        applicationName=app_name,
        deploymentGroupName=group_name,
    )
    deployment_ids = resp.get("deployments", [])

    if not deployment_ids:
        print("No deployments found.")
        return []

    # Fetch details for each deployment
    details_resp = codedeploy.batch_get_deployments(deploymentIds=deployment_ids)
    deployments = []
    for info in details_resp.get("deploymentsInfo", []):
        deployments.append({
            "deployment_id": info["deploymentId"],
            "status": info["status"],
            "deployment_config": info.get("deploymentConfigName", ""),
            "create_time": info.get("createTime"),
            "complete_time": info.get("completeTime"),
            "rollback_info": info.get("rollbackInfo"),
            "error_info": info.get("errorInformation"),
        })

    print(f"Found {len(deployments)} deployment(s) for {app_name}/{group_name}:")
    for d in deployments:
        ct = d["create_time"].strftime("%Y-%m-%d %H:%M:%S") if d["create_time"] else "N/A"
        print(f"  {d['deployment_id']}  status={d['status']}  config={d['deployment_config']}  created={ct}")
    return deployments
