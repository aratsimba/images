# Infrastructure Manager - ALB, target groups, Auto Scaling group

import base64
import boto3
from botocore.exceptions import ClientError

elbv2 = boto3.client("elbv2")
ec2 = boto3.client("ec2")
autoscaling = boto3.client("autoscaling")
ssm = boto3.client("ssm")


# ---------------------------------------------------------------------------
# Application Load Balancer and Target Groups
# ---------------------------------------------------------------------------

def create_application_load_balancer(
    alb_name: str, subnet_ids: list, security_group_id: str
) -> str:
    """Create an internet-facing Application Load Balancer and return its ARN."""
    try:
        resp = elbv2.create_load_balancer(
            Name=alb_name,
            Subnets=subnet_ids,
            SecurityGroups=[security_group_id],
            Scheme="internet-facing",
            Type="application",
            IpAddressType="ipv4",
        )
        alb_arn = resp["LoadBalancers"][0]["LoadBalancerArn"]
        dns_name = resp["LoadBalancers"][0]["DNSName"]
        print(f"Created ALB: {alb_arn}")
        print(f"ALB DNS: {dns_name}")
        return alb_arn
    except ClientError as e:
        if e.response["Error"]["Code"] == "DuplicateLoadBalancerName":
            print(f"ALB {alb_name} already exists, looking up ARN...")
            resp = elbv2.describe_load_balancers(Names=[alb_name])
            alb_arn = resp["LoadBalancers"][0]["LoadBalancerArn"]
            print(f"Found existing ALB: {alb_arn}")
            return alb_arn
        raise


def create_target_group(
    tg_name: str, vpc_id: str, health_check_path: str
) -> str:
    """Create a target group with health checks and return its ARN."""
    try:
        resp = elbv2.create_target_group(
            Name=tg_name,
            Protocol="HTTP",
            Port=80,
            VpcId=vpc_id,
            HealthCheckProtocol="HTTP",
            HealthCheckPath=health_check_path,
            HealthCheckIntervalSeconds=30,
            HealthyThresholdCount=2,
            TargetType="instance",
        )
        tg_arn = resp["TargetGroups"][0]["TargetGroupArn"]
        print(f"Created target group: {tg_arn}")
        return tg_arn
    except ClientError as e:
        if e.response["Error"]["Code"] == "DuplicateTargetGroupName":
            print(f"Target group {tg_name} already exists, looking up ARN...")
            resp = elbv2.describe_target_groups(Names=[tg_name])
            tg_arn = resp["TargetGroups"][0]["TargetGroupArn"]
            print(f"Found existing target group: {tg_arn}")
            return tg_arn
        raise


def create_listener(
    alb_arn: str, target_group_arn: str, port: int
) -> str:
    """Create an HTTP listener on the ALB forwarding to the target group."""
    try:
        resp = elbv2.create_listener(
            LoadBalancerArn=alb_arn,
            Protocol="HTTP",
            Port=port,
            DefaultActions=[
                {
                    "Type": "forward",
                    "TargetGroupArn": target_group_arn,
                }
            ],
        )
        listener_arn = resp["Listeners"][0]["ListenerArn"]
        print(f"Created listener on port {port}: {listener_arn}")
        return listener_arn
    except ClientError as e:
        if e.response["Error"]["Code"] == "DuplicateListener":
            print(f"Listener on port {port} already exists, looking up ARN...")
            resp = elbv2.describe_listeners(LoadBalancerArn=alb_arn)
            for listener in resp["Listeners"]:
                if listener["Port"] == port:
                    print(f"Found existing listener: {listener['ListenerArn']}")
                    return listener["ListenerArn"]
        raise


def get_target_group_health(target_group_arn: str) -> list:
    """Check the health status of targets registered with the target group."""
    resp = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
    targets = resp["TargetHealthDescriptions"]
    for t in targets:
        target_id = t["Target"]["Id"]
        state = t["TargetHealth"]["State"]
        print(f"  Target {target_id}: {state}")
    return targets


# ---------------------------------------------------------------------------
# Launch Template and Auto Scaling Group
# ---------------------------------------------------------------------------

def create_launch_template(
    template_name: str,
    ami_id: str,
    instance_type: str,
    instance_profile_name: str,
    security_group_id: str,
    user_data_script: str,
) -> str:
    """Create an EC2 launch template and return its ID."""
    encoded_user_data = base64.b64encode(user_data_script.encode("utf-8")).decode("utf-8")
    try:
        resp = ec2.create_launch_template(
            LaunchTemplateName=template_name,
            LaunchTemplateData={
                "ImageId": ami_id,
                "InstanceType": instance_type,
                "IamInstanceProfile": {"Name": instance_profile_name},
                "SecurityGroupIds": [security_group_id],
                "UserData": encoded_user_data,
            },
        )
        template_id = resp["LaunchTemplate"]["LaunchTemplateId"]
        print(f"Created launch template: {template_id}")
        return template_id
    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidLaunchTemplateName.AlreadyExistsException":
            print(f"Launch template {template_name} already exists, looking up ID...")
            resp = ec2.describe_launch_templates(
                LaunchTemplateNames=[template_name]
            )
            template_id = resp["LaunchTemplates"][0]["LaunchTemplateId"]
            print(f"Found existing launch template: {template_id}")
            return template_id
        raise


def create_auto_scaling_group(
    asg_name: str,
    launch_template_id: str,
    target_group_arn: str,
    subnet_ids: list,
    desired_capacity: int,
) -> None:
    """Create an Auto Scaling group attached to the target group."""
    try:
        autoscaling.create_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            LaunchTemplate={
                "LaunchTemplateId": launch_template_id,
                "Version": "$Latest",
            },
            MinSize=desired_capacity,
            MaxSize=desired_capacity,
            DesiredCapacity=desired_capacity,
            VPCZoneIdentifier=",".join(subnet_ids),
            TargetGroupARNs=[target_group_arn],
            Tags=[
                {
                    "ResourceId": asg_name,
                    "ResourceType": "auto-scaling-group",
                    "Key": "Name",
                    "Value": "BlueGreenDemo",
                    "PropagateAtLaunch": True,
                }
            ],
        )
        print(f"Created Auto Scaling group: {asg_name} (desired={desired_capacity})")
    except ClientError as e:
        if e.response["Error"]["Code"] == "AlreadyExists":
            print(f"Auto Scaling group {asg_name} already exists")
        else:
            raise


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

def delete_infrastructure(
    alb_arn: str,
    target_group_arn: str,
    asg_name: str,
    launch_template_id: str,
) -> None:
    """Tear down infrastructure: ASG, launch template, ALB listener, target group, ALB."""
    # Delete Auto Scaling group (force-delete terminates instances)
    try:
        autoscaling.delete_auto_scaling_group(
            AutoScalingGroupName=asg_name, ForceDelete=True
        )
        print(f"Deleted Auto Scaling group: {asg_name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "ValidationError":
            print(f"Auto Scaling group {asg_name} not found, skipping")
        else:
            raise

    # Delete launch template
    try:
        ec2.delete_launch_template(LaunchTemplateId=launch_template_id)
        print(f"Deleted launch template: {launch_template_id}")
    except ClientError as e:
        if e.response["Error"]["Code"] in (
            "InvalidLaunchTemplateId.NotFound",
            "InvalidLaunchTemplateId.Malformed",
        ):
            print(f"Launch template {launch_template_id} not found, skipping")
        else:
            raise

    # Delete ALB listeners first
    try:
        listeners = elbv2.describe_listeners(LoadBalancerArn=alb_arn)
        for listener in listeners["Listeners"]:
            elbv2.delete_listener(ListenerArn=listener["ListenerArn"])
            print(f"Deleted listener: {listener['ListenerArn']}")
    except ClientError:
        print("No listeners found or ALB not found, skipping")

    # Delete target group
    try:
        elbv2.delete_target_group(TargetGroupArn=target_group_arn)
        print(f"Deleted target group: {target_group_arn}")
    except ClientError:
        print(f"Target group {target_group_arn} not found, skipping")

    # Delete ALB
    try:
        elbv2.delete_load_balancer(LoadBalancerArn=alb_arn)
        print(f"Deleted ALB: {alb_arn}")
    except ClientError:
        print(f"ALB {alb_arn} not found, skipping")

    print("Infrastructure cleanup complete")
