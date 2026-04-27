

# Requirements Document

## Introduction

This project guides learners through building an automated blue-green deployment pipeline using AWS CodeDeploy. Blue-green deployment is a release strategy that reduces downtime and risk by running two identical production environments—blue (current) and green (new)—and shifting traffic between them. By completing this project, learners will understand how to automate application deployments with zero-downtime traffic cutover, safe rollback capabilities, and flexible traffic routing strategies.

The project focuses on the EC2 compute platform, where CodeDeploy orchestrates the provisioning of replacement instances, application installation, traffic rerouting through Elastic Load Balancing, and optional termination of the original environment. Learners will configure the full deployment lifecycle: creating a CodeDeploy application, defining deployment groups with blue-green settings, preparing application revisions with AppSpec files, and executing deployments with different traffic shifting strategies.

By the end of this project, learners will have hands-on experience with the core CodeDeploy concepts—applications, deployment groups, revisions, and deployment configurations—and will understand how these components integrate with Auto Scaling groups and Elastic Load Balancing to deliver a production-grade deployment workflow.

## Glossary

- **blue_environment**: The currently running production environment that serves live traffic before a deployment begins.
- **green_environment**: The newly provisioned replacement environment where the updated application revision is deployed and validated before receiving production traffic.
- **appspec_file**: An application specification file unique to CodeDeploy that defines the deployment actions, lifecycle event hooks, and file mappings for a deployment.
- **application_revision**: An archive file containing deployable content and an AppSpec file, stored in Amazon S3 or a GitHub repository, that CodeDeploy deploys to target instances.
- **deployment_group**: A set of EC2 instances or an Auto Scaling group, along with deployment configuration and settings, that CodeDeploy targets during a deployment.
- **deployment_configuration**: A set of rules that determines how traffic is shifted during a deployment, such as canary, linear, or all-at-once strategies.
- **lifecycle_event_hooks**: Scripts that run at defined stages during a deployment (e.g., BeforeInstall, AfterInstall, ValidateService) to perform custom actions like testing or configuration.
- **traffic_shifting**: The process of redirecting production traffic from the blue environment to the green environment through Elastic Load Balancing.
- **codedeploy_agent**: A software agent installed on EC2 instances that enables them to participate in CodeDeploy deployments.

## Requirements

### Requirement 1: CodeDeploy Application and Service Role Setup

**User Story:** As a deployment automation learner, I want to create a CodeDeploy application for the EC2/On-Premises compute platform with the necessary IAM service role, so that I can establish the foundation for managing blue-green deployments.

#### Acceptance Criteria

1. WHEN the learner creates a CodeDeploy application specifying the EC2/On-Premises compute platform, THE application SHALL be registered and visible in the CodeDeploy console.
2. THE CodeDeploy service role SHALL have permissions to interact with EC2 instances, Auto Scaling groups, and Elastic Load Balancing resources required for blue-green deployments.
3. IF the learner attempts to create an application with a name that already exists in the same region and account, THEN THE service SHALL return an error and the existing application SHALL remain unchanged.

### Requirement 2: EC2 Instances with CodeDeploy Agent

**User Story:** As a deployment automation learner, I want to provision EC2 instances with the CodeDeploy agent installed and an appropriate IAM instance profile attached, so that the instances can participate in CodeDeploy deployments.

#### Acceptance Criteria

1. WHEN the learner launches EC2 instances with the CodeDeploy agent installed, THE agent SHALL be running and able to communicate with the CodeDeploy service.
2. THE EC2 instances SHALL have an IAM instance profile attached that grants permissions to retrieve application revisions from Amazon S3.
3. THE EC2 instances SHALL be tagged or part of an Auto Scaling group so that CodeDeploy can identify them as deployment targets.
4. IF the CodeDeploy agent is not running on a target instance, THEN THE deployment to that instance SHALL fail and report the instance as unhealthy.

### Requirement 3: Elastic Load Balancing for Traffic Routing

**User Story:** As a deployment automation learner, I want to configure an Elastic Load Balancing load balancer with target groups, so that CodeDeploy can route traffic between the blue and green environments during deployment.

#### Acceptance Criteria

1. WHEN the learner creates a load balancer with the blue environment instances registered in a target group, THE load balancer SHALL distribute incoming traffic to those instances.
2. THE load balancer SHALL have health checks configured so that only healthy instances receive traffic.
3. WHEN a deployment completes traffic shifting, THE green environment instances SHALL be registered with the load balancer target group and THE blue environment instances SHALL be deregistered.

### Requirement 4: Application Revision with AppSpec File

**User Story:** As a deployment automation learner, I want to create an application revision bundle containing an AppSpec file and deployable content, so that CodeDeploy knows how to install and validate my application on target instances.

#### Acceptance Criteria

1. WHEN the learner creates an AppSpec file defining file mappings and lifecycle event hooks, THE revision bundle SHALL include both the AppSpec file and the application source files in an archive format.
2. THE application revision SHALL be uploaded to an Amazon S3 bucket and be accessible by the CodeDeploy service role.
3. THE AppSpec file SHALL define at least the files section (specifying source and destination paths) and one or more lifecycle event hooks (such as BeforeInstall, AfterInstall, or ValidateService) to run validation scripts.
4. IF the AppSpec file is malformed or missing required sections, THEN THE deployment SHALL fail during the initialization phase with a descriptive error.

### Requirement 5: Blue-Green Deployment Group Configuration

**User Story:** As a deployment automation learner, I want to configure a deployment group with blue-green deployment type settings, so that CodeDeploy provisions replacement instances and manages traffic shifting automatically.

#### Acceptance Criteria

1. WHEN the learner creates a deployment group with the blue-green deployment type, THE deployment group SHALL specify the load balancer and target group to use for traffic routing.
2. THE deployment group SHALL define how the green environment is provisioned, either by copying an existing Auto Scaling group or by specifying EC2 instance tags.
3. THE deployment group SHALL include a configuration for handling the original (blue) environment after deployment, either terminating the instances after a specified wait time or keeping them running.
4. IF the deployment group is not associated with a load balancer, THEN THE service SHALL reject the blue-green deployment group configuration.

### Requirement 6: Executing a Blue-Green Deployment

**User Story:** As a deployment automation learner, I want to execute a blue-green deployment and observe the full lifecycle of environment provisioning, application installation, and traffic shifting, so that I understand how zero-downtime deployments work in practice.

#### Acceptance Criteria

1. WHEN the learner initiates a deployment with the blue-green deployment type, THE service SHALL provision new (green) instances, install the application revision on them, and execute the lifecycle event hooks defined in the AppSpec file.
2. WHILE the deployment is in progress, THE learner SHALL be able to monitor the deployment status and view lifecycle event results for each instance in the deployment group.
3. WHEN all green instances pass their lifecycle event hooks including validation, THE service SHALL shift traffic from the blue environment to the green environment through the configured load balancer.
4. IF a lifecycle event hook script fails on any instance, THEN THE deployment SHALL stop and report the failure, leaving traffic routed to the original blue environment.

### Requirement 7: Deployment Configuration and Traffic Shifting Strategies

**User Story:** As a deployment automation learner, I want to experiment with different traffic shifting strategies (all-at-once, canary, and linear), so that I understand how to control the risk and speed of production deployments.

#### Acceptance Criteria

1. WHEN the learner selects an all-at-once deployment configuration, THE service SHALL shift all traffic from the blue environment to the green environment in a single step.
2. WHEN the learner selects a canary deployment configuration, THE service SHALL shift a specified percentage of traffic to the green environment first, wait for a defined interval, and then shift the remaining traffic.
3. WHEN the learner selects a linear deployment configuration, THE service SHALL shift traffic in equal increments at regular intervals until all traffic is routed to the green environment.
4. THE learner SHALL be able to configure the wait time before the original blue environment instances are terminated after a successful deployment.

### Requirement 8: Deployment Rollback

**User Story:** As a deployment automation learner, I want to configure automatic rollback settings and manually trigger a rollback of a failed deployment, so that I can restore the previous application version with minimal downtime.

#### Acceptance Criteria

1. WHEN the learner enables automatic rollback on the deployment group, THE service SHALL automatically roll back to the last known good revision if a deployment fails or an alarm threshold is breached.
2. WHEN a rollback is triggered during a blue-green deployment, THE service SHALL reroute traffic back to the original blue environment instances.
3. IF the learner manually stops a deployment that is in progress, THEN THE service SHALL halt the traffic shifting and the blue environment SHALL continue serving production traffic.
4. WHEN a rollback completes, THE deployment history SHALL show the rollback event with details about the original deployment that was reverted.
