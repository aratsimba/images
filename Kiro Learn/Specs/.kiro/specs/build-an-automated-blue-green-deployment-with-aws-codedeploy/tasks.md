

# Implementation Plan: Automated Blue-Green Deployment with AWS CodeDeploy

## Overview

This implementation plan guides learners through building an automated blue-green deployment pipeline using AWS CodeDeploy on the EC2 compute platform. The approach is script-driven, using Python with boto3 to provision and orchestrate all AWS resources. The plan follows a logical progression: foundational IAM setup, infrastructure provisioning (ALB, Auto Scaling, EC2 instances with CodeDeploy agent), application revision preparation, CodeDeploy application and deployment group configuration, deployment execution with traffic shifting strategies, and rollback scenarios.

The implementation is organized into key phases. First, the IAM foundation and compute infrastructure are established, including the CodeDeploy service role, EC2 instance profiles, an Application Load Balancer with target groups, and an Auto Scaling group with instances running the CodeDeploy agent. Next, the application revision is bundled with an AppSpec file containing lifecycle hooks and uploaded to S3. Then the CodeDeploy application and blue-green deployment group are configured, linking the ASG, ALB, and traffic shifting settings. Finally, deployments are executed using different strategies (all-at-once, canary, linear), and rollback behavior is tested.

Dependencies flow linearly: IAM roles must exist before infrastructure can be provisioned, infrastructure must be healthy before CodeDeploy can target it, and revisions must be uploaded before deployments can be triggered. Checkpoints after infrastructure setup and after the first successful deployment ensure incremental validation. The five Python components (IAMSetup, InfraManager, RevisionManager, DeploymentManager, DeploymentMonitor) map directly to the task progression.

## Tasks

- [x] 1. Prerequisites - Environment Setup
  - [x] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for IAM, EC2, ELB, Auto Scaling, S3, and CodeDeploy
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [x] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3` and verify with `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [x] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Identify a VPC with at least two public subnets across different AZs for ALB deployment
    - Identify or create a security group allowing HTTP (port 80) inbound traffic and all outbound traffic
    - Note the VPC ID, subnet IDs, and security group ID for use in later tasks
    - Verify default VPC exists: `aws ec2 describe-vpcs --filters Name=isDefault,Values=true`
    - _Requirements: (all)_
  - [x] 1.4 Create Project Structure
    - Create project directory: `mkdir -p blue-green-deploy/components blue-green-deploy/app-source/scripts`
    - Create empty Python files: `iam_setup.py`, `infra_manager.py`, `revision_manager.py`, `deployment_manager.py`, `deployment_monitor.py` in `components/`
    - _Requirements: (all)_

- [x] 2. IAM Roles and Instance Profiles
  - [x] 2.1 Implement CodeDeploy Service Role
    - Create `components/iam_setup.py` with the `create_codedeploy_service_role(role_name)` function
    - Create an IAM role with trust policy allowing `codedeploy.amazonaws.com` to assume the role
    - Attach the AWS managed policy `AWSCodeDeployRole` which grants permissions for EC2, Auto Scaling, and ELB interactions
    - Attach an inline policy granting `iam:PassRole`, `ec2:RunInstances`, and `ec2:CreateTags` permissions — these are required for blue-green deployments where CodeDeploy copies the Auto Scaling group to provision green instances
    - Implement `get_role_arn(role_name)` to retrieve the role ARN
    - Add a 10-second wait after role creation for IAM propagation
    - Verify: `aws iam get-role --role-name CodeDeployServiceRole`
    - _Requirements: 1.1, 1.2_
  - [x] 2.2 Implement EC2 Instance Profile
    - Implement `create_ec2_instance_profile(profile_name, role_name)` function
    - Create an IAM role with trust policy allowing `ec2.amazonaws.com` to assume it
    - Attach policies: `AmazonS3ReadOnlyAccess` (for revision retrieval) and `AmazonSSMManagedInstanceCore` (for CodeDeploy agent communication)
    - Create an instance profile, add the role to the instance profile
    - Implement `delete_roles_and_profiles(role_name, profile_name)` for cleanup
    - Verify: `aws iam get-instance-profile --instance-profile-name CodeDeployInstanceProfile`
    - _Requirements: 2.2, 2.1_
  - [x] 2.3 Provision IAM Resources
    - Run the IAM setup functions to create the actual AWS resources:
      - Call `create_codedeploy_service_role('CodeDeployServiceRole')` to create the CodeDeploy service role
      - Call `create_ec2_instance_profile('CodeDeployInstanceProfile', 'CodeDeployEC2Role')` to create the EC2 instance profile
    - Verify the role exists: `aws iam get-role --role-name CodeDeployServiceRole`
    - Verify the instance profile exists: `aws iam get-instance-profile --instance-profile-name CodeDeployInstanceProfile`
    - _Requirements: 1.1, 1.2, 2.1, 2.2_

- [x] 3. Infrastructure - ALB, Auto Scaling Group, and EC2 Instances
  - [x] 3.1 Implement ALB and Target Group Creation
    - Create `components/infra_manager.py` with `create_application_load_balancer(alb_name, subnet_ids, security_group_id)` using `boto3.client('elbv2')`
    - Implement `create_target_group(tg_name, vpc_id, health_check_path)` with health check configured on path `/` with interval 30s, healthy threshold 2
    - Implement `create_listener(alb_arn, target_group_arn, port)` to create an HTTP listener on port 80 forwarding to the target group
    - Implement `get_target_group_health(target_group_arn)` to check registered target health status
    - Verify ALB creation: `aws elbv2 describe-load-balancers --names BlueGreenALB`
    - _Requirements: 3.1, 3.2_
  - [x] 3.2 Implement Launch Template and Auto Scaling Group
    - Implement `create_launch_template(template_name, ami_id, instance_type, instance_profile_name, security_group_id, user_data_script)` using `boto3.client('ec2')`
    - Create a user data script that installs the CodeDeploy agent: `yum install -y ruby wget && wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install && chmod +x ./install && ./install auto`
    - Also install a simple web server (e.g., Apache) in user data to serve as the baseline application
    - Use Amazon Linux 2023 AMI (look up with SSM parameter: `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64`)
    - Implement `create_auto_scaling_group(asg_name, launch_template_id, target_group_arn, subnet_ids, desired_capacity)` with desired capacity of 2 instances
    - Tag the ASG with `Name=BlueGreenDemo` so CodeDeploy can identify deployment targets
    - Implement `delete_infrastructure(alb_arn, target_group_arn, asg_name, launch_template_id)` for cleanup
    - Verify instances are running: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names BlueGreenASG`
    - _Requirements: 2.1, 2.3, 2.4, 3.1, 3.2, 3.3_
  - [x] 3.3 Provision Infrastructure Resources
    - Run the infrastructure functions to create the actual AWS resources:
      - Call `create_application_load_balancer('BlueGreenALB', subnet_ids, security_group_id)` to create the ALB
      - Call `create_target_group('BlueGreenTG', vpc_id, '/')` to create the target group with health checks
      - Call `create_listener(alb_arn, tg_arn, 80)` to create the HTTP listener
      - Look up the Amazon Linux 2023 AMI via SSM parameter `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64`
      - Call `create_launch_template('BlueGreenLT', ami_id, 't2.micro', 'CodeDeployInstanceProfile', security_group_id, user_data_script)` with user data that installs Apache and the CodeDeploy agent
      - Call `create_auto_scaling_group('BlueGreenASG', template_id, tg_arn, subnet_ids, 2)` to launch 2 instances
    - Wait 1-2 minutes for instances to boot and the CodeDeploy agent to start
    - Verify ALB is active: `aws elbv2 describe-load-balancers --names BlueGreenALB`
    - Verify ASG instances are launching: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names BlueGreenASG`
    - _Requirements: 2.1, 2.3, 2.4, 3.1, 3.2, 3.3_

- [x] 4. Checkpoint - Validate Infrastructure
  - Wait for ASG instances to reach "InService" state: `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names BlueGreenASG`
  - Verify CodeDeploy agent is running on instances by SSHing or checking: `aws ssm send-command --instance-ids <id> --document-name "AWS-RunShellScript" --parameters commands=["systemctl status codedeploy-agent"]`
  - Verify ALB target group shows healthy targets: `aws elbv2 describe-target-health --target-group-arn <tg-arn>`
  - Test the ALB DNS endpoint returns a response: `curl http://<alb-dns-name>`
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Application Revision with AppSpec File
  - [x] 5.1 Implement AppSpec Generation and Bundling
    - Create `components/revision_manager.py` with `generate_appspec(file_mappings, hooks)` function
    - Generate a YAML AppSpec file defining `os: linux`, a `files` section with at least one `AppSpecFileMapping` (e.g., source `/src` to destination `/var/www/html`), and a `hooks` section with lifecycle events
    - Define `AppSpecHook` entries for `BeforeInstall` (stop existing server), `AfterInstall` (set permissions), and `ValidateService` (curl localhost to verify app is running)
    - Create shell scripts in `app-source/scripts/`: `before_install.sh`, `after_install.sh`, `validate_service.sh`
    - Implement `create_revision_bundle(appspec_content, source_dir, output_path)` to create a zip archive containing the AppSpec file, application files, and hook scripts
    - _Requirements: 4.1, 4.3, 4.4_
  - [x] 5.2 Implement S3 Upload and Revision Location
    - Implement `create_revision_bucket(bucket_name)` to create an S3 bucket for storing revisions
    - Implement `upload_revision(bucket_name, bundle_path, key)` to upload the zip bundle
    - Implement `get_revision_location(bucket_name, key)` returning a `RevisionLocation` dictionary with `revisionType: "S3"`, `s3Location` containing bucket, key, and `bundleType: "zip"`
    - Implement `delete_revision_bucket(bucket_name)` that empties and deletes the bucket
    - _Requirements: 4.2_
  - [x] 5.3 Provision Revision Resources
    - Run the revision manager functions to create the actual AWS resources:
      - Call `generate_appspec(file_mappings, hooks)` with file mappings for `/src` → `/var/www/html` and hooks for BeforeInstall, AfterInstall, and ValidateService
      - Call `create_revision_bundle(appspec_content, 'app-source', 'revision.zip')` to create the zip archive
      - Call `create_revision_bucket('blue-green-deploy-revisions-<account-id>')` to create the S3 bucket
      - Call `upload_revision(bucket_name, bundle_path, 'revisions/v1.zip')` to upload the revision
    - Verify upload: `aws s3 ls s3://<bucket-name>/revisions/`
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 6. CodeDeploy Application and Blue-Green Deployment Group
  - [x] 6.1 Create CodeDeploy Application
    - Create `components/deployment_manager.py` with `create_application(app_name)` using `boto3.client('codedeploy')`
    - Specify `computePlatform='Server'` for EC2/On-Premises
    - Handle `ApplicationAlreadyExistsException` gracefully with a descriptive message
    - Implement `list_deployment_configs()` to list available deployment configurations (e.g., `CodeDeployDefault.AllAtOnce`, `CodeDeployDefault.HalfAtATime`)
    - Verify: `aws deploy get-application --application-name BlueGreenApp`
    - _Requirements: 1.1, 1.3_
  - [x] 6.2 Create Blue-Green Deployment Group
    - Implement `create_blue_green_deployment_group(app_name, group_name, service_role_arn, asg_name, target_group_name, auto_rollback_enabled, termination_wait_minutes)` using `BlueGreenConfig` data model
    - Set `deploymentType='BLUE_GREEN'` and `deploymentOption='WITH_TRAFFIC_CONTROL'`
    - Configure `blueGreenDeploymentConfiguration` with `greenFleetProvisioningOption` set to `COPY_AUTO_SCALING_GROUP`
    - Set `terminateBlueInstancesOnDeploymentSuccess` action to `TERMINATE` with the specified wait time
    - Configure `loadBalancerInfo` with the target group name
    - Enable `autoRollbackConfiguration` with events `DEPLOYMENT_FAILURE` and `DEPLOYMENT_STOP_ON_ALARM` when `auto_rollback_enabled` is true
    - Implement `delete_deployment_group(app_name, group_name)` and `delete_application(app_name)` for cleanup
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 8.1_
  - [x] 6.3 Provision CodeDeploy Resources
    - Run the deployment manager functions to create the actual AWS resources:
      - Call `create_application('BlueGreenApp')` to register the CodeDeploy application with Server compute platform
      - Call `list_deployment_configs()` to verify available deployment configurations
      - Call `create_blue_green_deployment_group('BlueGreenApp', 'BlueGreenDG', service_role_arn, 'BlueGreenASG', 'BlueGreenTG', True, 5)` to create the deployment group
    - Verify application exists: `aws deploy get-application --application-name BlueGreenApp`
    - Verify deployment group exists: `aws deploy get-deployment-group --application-name BlueGreenApp --deployment-group-name BlueGreenDG`
    - _Requirements: 1.1, 1.3, 5.1, 5.2, 5.3, 5.4, 8.1_

- [x] 7. Checkpoint - Validate CodeDeploy Configuration
  - Confirm CodeDeploy application exists: `aws deploy get-application --application-name BlueGreenApp`
  - Confirm deployment group is configured as blue-green with correct ALB and ASG references
  - Verify revision bundle is accessible in S3 by the CodeDeploy service role
  - List available deployment configs: `aws deploy list-deployment-configs`
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Execute Blue-Green Deployment and Monitor
  - [x] 8.1 Trigger All-at-Once Deployment
    - Implement `create_deployment(app_name, group_name, revision_location, deployment_config_name, description)` in `deployment_manager.py`
    - Execute a deployment using `CodeDeployDefault.AllAtOnce` configuration
    - Pass the `RevisionLocation` dictionary from `get_revision_location()`
    - The deployment should provision green instances, install the revision, run lifecycle hooks, and shift all traffic at once
    - Verify deployment is created: `aws deploy get-deployment --deployment-id <id>`
    - _Requirements: 6.1, 7.1_
  - [x] 8.2 Implement Deployment Monitoring
    - Create `components/deployment_monitor.py` with `get_deployment_status(deployment_id)` returning `DeploymentStatus` data
    - Implement `get_instance_targets(deployment_id)` using `batch_get_deployment_targets` to get `InstanceTarget` details
    - Implement `get_lifecycle_events(deployment_id, target_id)` to retrieve `LifecycleEvent` data for each target
    - Implement `wait_for_deployment(deployment_id, poll_interval_seconds)` that polls every N seconds and prints status updates until deployment completes or fails
    - Implement `list_deployments(app_name, group_name)` to retrieve deployment history
    - Monitor the all-at-once deployment to completion, observing green instance provisioning, application installation, and traffic shift
    - Verify green instances are registered with the ALB target group after completion: `aws elbv2 describe-target-health --target-group-arn <tg-arn>`
    - _Requirements: 6.2, 6.3, 6.4, 7.4, 3.3_

- [x] 9. Traffic Shifting Strategies and Rollback
  - [x] 9.1 Experiment with Canary and Linear Strategies
    - Create a new revision with a small application change (e.g., updated HTML content) and upload to S3
    - Execute a deployment using `CodeDeployDefault.HalfAtATime` or a custom canary configuration to observe incremental traffic shifting
    - Observe canary behavior: initial percentage of traffic shifted, wait interval, then remaining traffic shifted
    - Execute another deployment with a linear configuration to observe equal traffic increments at regular intervals
    - Configure `termination_wait_minutes` on the deployment group to observe the blue environment wait period before termination
    - Monitor each deployment using `wait_for_deployment()` and verify traffic routing changes
    - _Requirements: 7.2, 7.3, 7.4_
  - [x] 9.2 Test Deployment Rollback
    - Create a revision with a deliberately failing `ValidateService` hook script (e.g., exit code 1) and upload to S3
    - Trigger a deployment and observe it fail during the lifecycle hook phase
    - Verify automatic rollback is triggered: traffic remains on (or returns to) the blue environment
    - Implement `stop_deployment(deployment_id, auto_rollback)` in `deployment_monitor.py`
    - Test manual stop: trigger a new deployment and call `stop_deployment()` while it is in progress, verify traffic stays with the blue environment
    - Verify deployment history shows rollback events using `list_deployments()`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 6.4_
  - [x] 9.3 Property Test - Rollback Preserves Blue Environment
    - **Property 1: Blue Environment Integrity on Failure**
    - **Validates: Requirements 8.1, 8.2, 8.3**

- [x] 10. Checkpoint - End-to-End Validation
  - Verify at least three deployments completed (all-at-once, canary/linear, failed with rollback) by checking deployment history
  - Confirm the ALB serves the latest successfully deployed application version: `curl http://<alb-dns-name>`
  - Verify rollback deployment appears in history with correct status
  - Confirm blue environment instances were handled according to termination settings
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Cleanup - Resource Teardown
  - [x] 11.1 Delete CodeDeploy Resources
    - Delete deployment group: call `delete_deployment_group('BlueGreenApp', 'BlueGreenDG')` or `aws deploy delete-deployment-group --application-name BlueGreenApp --deployment-group-name BlueGreenDG`
    - Delete application: call `delete_application('BlueGreenApp')` or `aws deploy delete-application --application-name BlueGreenApp`
    - _Requirements: (all)_
  - [x] 11.2 Delete Infrastructure Resources
    - Delete Auto Scaling group (and terminate instances): `aws autoscaling delete-auto-scaling-group --auto-scaling-group-name BlueGreenASG --force-delete`
    - Also delete any copied ASGs created by CodeDeploy during blue-green deployments
    - Delete launch template: `aws ec2 delete-launch-template --launch-template-name BlueGreenLT`
    - Delete ALB listener, then target group, then ALB: use `delete_infrastructure()` or individual CLI commands
    - Verify: `aws elbv2 describe-load-balancers --names BlueGreenALB` should return not found
    - _Requirements: (all)_
  - [x] 11.3 Delete S3 and IAM Resources
    - Empty and delete S3 revision bucket: call `delete_revision_bucket()` or `aws s3 rb s3://<bucket-name> --force`
    - Remove instance profile role, delete instance profile, delete instance role: call `delete_roles_and_profiles()` or use CLI
    - Detach policies and delete CodeDeploy service role: `aws iam detach-role-policy --role-name CodeDeployServiceRole --policy-arn arn:aws:iam::aws:policy/AWSCodeDeployRole && aws iam delete-role --role-name CodeDeployServiceRole`
    - Verify no leftover resources: `aws iam list-roles --query "Roles[?contains(RoleName, 'BlueGreen')]"`
    - **Warning**: Auto Scaling groups and ALBs incur ongoing costs if not deleted. EC2 instances from copied ASGs may persist after deployments.
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The CodeDeploy agent may take 2-3 minutes to start after EC2 instance launch; wait for agent health before proceeding with deployments
- Blue-green deployments with `COPY_AUTO_SCALING_GROUP` provisioning will create additional ASGs; ensure these are cleaned up during teardown
- IAM role propagation can take up to 10 seconds; scripts should include appropriate waits after role creation
- The `termination_wait_minutes` setting controls how long blue instances remain after a successful deployment; set to 5-10 minutes for learning purposes to allow observation
