

# Requirements Document

## Introduction

This learning project guides you through designing and deploying a highly available architecture on AWS using Elastic Load Balancing and EC2 Auto Scaling. High availability is a foundational principle of cloud architecture — it ensures that applications remain accessible and responsive even when individual components fail or entire Availability Zones experience outages. By building this project, you will gain hands-on experience with the core AWS services and patterns that underpin production-grade resilient systems.

The project focuses on creating a multi-tier web application that spans multiple Availability Zones, automatically scales capacity based on demand, and self-heals when instances become unhealthy. You will configure load balancing to distribute traffic, define Auto Scaling groups with appropriate scaling policies, implement health checks at multiple layers, and design the underlying network architecture to support fault tolerance. These skills map directly to real-world scenarios where architects must balance availability targets, cost efficiency, and operational complexity.

By the end of this project, you will understand how to eliminate single points of failure, how Auto Scaling groups maintain desired capacity across zones, how Elastic Load Balancing routes traffic away from unhealthy targets, and how these components integrate to form a self-healing, elastically scalable architecture.

## Glossary

- **availability_zone**: An isolated location within an AWS Region, consisting of one or more discrete data centers with redundant power, networking, and connectivity, used to build fault-tolerant applications.
- **auto_scaling_group**: A logical grouping of EC2 instances managed by Amazon EC2 Auto Scaling that automatically maintains a specified number of instances and can scale capacity based on defined conditions.
- **elastic_load_balancing**: An AWS service that automatically distributes incoming application traffic across multiple targets such as EC2 instances across multiple Availability Zones.
- **application_load_balancer**: A Layer 7 load balancer that routes HTTP/HTTPS traffic based on content of the request, supporting path-based and host-based routing.
- **cross_zone_load_balancing**: A load balancer feature that distributes traffic evenly across all registered instances in all enabled Availability Zones, regardless of which zone received the request.
- **target_group**: A logical grouping of targets (such as EC2 instances) that a load balancer routes requests to, along with health check configuration for those targets.
- **scaling_policy**: A rule that defines when and how an Auto Scaling group adds or removes instances, typically based on CloudWatch metrics such as CPU utilization or request count.
- **launch_template**: A configuration template that specifies instance configuration information (AMI, instance type, key pair, security groups) used by an Auto Scaling group to launch EC2 instances.
- **health_check**: A periodic test performed by either the load balancer or Auto Scaling group to determine whether an instance is functioning correctly and should receive traffic.
- **desired_capacity**: The number of instances that an Auto Scaling group attempts to maintain at any given time, adjustable manually or automatically via scaling policies.
- **static_stability**: An architecture pattern where sufficient resources are pre-provisioned across Availability Zones so that the system can withstand the loss of a zone without needing to launch new resources.

## Requirements

### Requirement 1: Multi-AZ VPC Network Architecture

**User Story:** As a cloud architecture learner, I want to create a VPC with public and private subnets spanning multiple Availability Zones, so that I can establish the network foundation required for a highly available deployment.

#### Acceptance Criteria

1. WHEN the learner creates a VPC with subnets in at least two Availability Zones, THE architecture SHALL have at least one public subnet and one private subnet in each Availability Zone.
2. THE public subnets SHALL be associated with a route table that directs internet-bound traffic through an internet gateway, enabling load balancer accessibility from the internet.
3. THE private subnets SHALL be associated with a route table that directs internet-bound traffic through a NAT gateway, enabling instances to access the internet for updates without being directly reachable from the internet.
4. THE subnets SHALL each have a CIDR block with sufficient IP address space to accommodate the maximum number of instances that Auto Scaling may provision during peak demand.

### Requirement 2: Application Load Balancer Configuration

**User Story:** As a cloud architecture learner, I want to deploy an Application Load Balancer that distributes incoming traffic across multiple Availability Zones, so that I can provide a single entry point for users and eliminate instance-level single points of failure.

#### Acceptance Criteria

1. WHEN the learner creates an Application Load Balancer, THE load balancer SHALL be configured to span the public subnets across at least two Availability Zones.
2. THE load balancer SHALL have a listener configured to accept incoming traffic and forward it to a target group associated with the application instances.
3. THE load balancer SHALL have cross-zone load balancing enabled so that traffic is distributed evenly across all registered instances regardless of their Availability Zone.
4. THE load balancer's security group SHALL permit inbound traffic from the internet on the application port while restricting all other inbound access.

### Requirement 3: Launch Template for Application Instances

**User Story:** As a cloud architecture learner, I want to define a launch template that specifies the instance configuration for my application tier, so that Auto Scaling can consistently launch identically configured instances.

#### Acceptance Criteria

1. WHEN the learner creates a launch template, THE template SHALL specify an Amazon Machine Image, instance type, and security group configuration appropriate for the application tier.
2. THE launch template's security group SHALL permit inbound traffic only from the load balancer's security group, ensuring instances are not directly accessible from the internet.
3. THE launch template SHALL include user data that bootstraps the instance with a basic web application upon launch, enabling immediate verification of traffic routing through the load balancer.

### Requirement 4: Auto Scaling Group with Multi-AZ Distribution

**User Story:** As a cloud architecture learner, I want to create an Auto Scaling group that launches and maintains instances across multiple Availability Zones, so that my application remains available even if an entire zone fails.

#### Acceptance Criteria

1. WHEN the learner creates an Auto Scaling group referencing the launch template, THE group SHALL be configured to deploy instances across private subnets in at least two Availability Zones.
2. THE Auto Scaling group SHALL be configured with a minimum capacity, maximum capacity, and desired capacity that ensures at least one instance runs in each Availability Zone under normal operating conditions.
3. WHEN the Auto Scaling group is associated with the Application Load Balancer's target group, THE newly launched instances SHALL be automatically registered as targets and begin receiving traffic once they pass health checks.
4. IF an Availability Zone becomes impaired and instances in that zone are lost, THEN THE Auto Scaling group SHALL launch replacement instances in the remaining healthy Availability Zones to maintain the desired capacity.

### Requirement 5: Health Check Configuration for Automated Healing

**User Story:** As a cloud architecture learner, I want to configure health checks at both the infrastructure and application level, so that unhealthy instances are automatically detected, removed from traffic rotation, and replaced.

#### Acceptance Criteria

1. WHEN the learner configures health checks on the target group, THE Application Load Balancer SHALL periodically verify instance health by checking the application's health endpoint and route traffic only to instances that pass the check.
2. WHEN the learner enables Elastic Load Balancing health checks on the Auto Scaling group, THE Auto Scaling group SHALL consider an instance unhealthy if it fails either the EC2 status check or the load balancer health check.
3. IF an instance is marked unhealthy by the Auto Scaling group, THEN THE group SHALL terminate the unhealthy instance and launch a replacement instance to maintain the desired capacity.
4. THE health check grace period on the Auto Scaling group SHALL be configured to allow sufficient time for new instances to complete bootstrapping before health checks begin evaluating them.

### Requirement 6: Dynamic Scaling Policies Based on Demand

**User Story:** As a cloud architecture learner, I want to configure scaling policies that automatically adjust the number of instances based on application demand, so that the architecture can handle traffic spikes while minimizing costs during low-usage periods.

#### Acceptance Criteria

1. WHEN the learner creates a target tracking scaling policy based on a CloudWatch metric (such as average CPU utilization), THE Auto Scaling group SHALL add instances when the metric exceeds the target value and remove instances when the metric falls below the target value.
2. THE Auto Scaling group SHALL respect the configured minimum and maximum capacity boundaries when scaling in or out, preventing the group from scaling below the minimum required for availability or above the cost-safety maximum.
3. WHEN the learner simulates increased load on the application instances, THE Auto Scaling group SHALL launch additional instances within the defined maximum and THE load balancer SHALL begin distributing traffic to the new instances once they are healthy.

### Requirement 7: Monitoring and Observability for the Architecture

**User Story:** As a cloud architecture learner, I want to configure CloudWatch monitoring and alarms for my highly available architecture, so that I can observe scaling events, health check status, and traffic patterns to verify the architecture behaves as designed.

#### Acceptance Criteria

1. THE learner SHALL be able to view Auto Scaling group metrics in CloudWatch, including the number of running instances, scaling activities, and instances in each lifecycle state.
2. THE learner SHALL be able to view Application Load Balancer metrics in CloudWatch, including healthy host count, unhealthy host count, and request count per Availability Zone.
3. WHEN a CloudWatch alarm is configured to trigger on unhealthy host count exceeding a threshold, THE alarm SHALL transition to the alarm state and generate a notification when the condition is met.
4. WHEN a scaling event occurs (scale-out or scale-in), THE Auto Scaling group activity history SHALL record the event with details including the cause, the number of instances affected, and the resulting capacity.

### Requirement 8: Resilience Validation Through Failure Simulation

**User Story:** As a cloud architecture learner, I want to simulate component failures within my architecture, so that I can verify that the self-healing and fault-tolerance mechanisms work correctly and understand how the system recovers.

#### Acceptance Criteria

1. WHEN the learner manually terminates an instance within the Auto Scaling group, THE Auto Scaling group SHALL detect the termination, launch a replacement instance, and restore the desired capacity without manual intervention.
2. WHEN the learner stops the application process on a running instance (causing the load balancer health check to fail), THE load balancer SHALL stop routing traffic to that instance and THE Auto Scaling group SHALL eventually replace it.
3. WHILE an instance is being replaced due to a failure, THE remaining healthy instances SHALL continue serving traffic through the load balancer with no interruption to the application's overall availability.
4. THE learner SHALL be able to confirm recovery by observing the healthy host count in the load balancer return to the expected value after the replacement instance passes its health checks.
