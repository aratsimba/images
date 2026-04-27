

# Requirements Document

## Introduction

This project guides you through deploying and scaling a web application on Amazon EC2, one of the most foundational skills in cloud computing. You will gain hands-on experience launching virtual servers, configuring networking and security, distributing traffic across multiple instances, and automatically scaling capacity in response to demand. These are core competencies for anyone building or managing applications in the AWS Cloud.

Understanding how to deploy and scale on EC2 matters because nearly every production workload requires reliable compute capacity that can adapt to changing traffic patterns. By working through this project, you will learn how EC2 instances, Elastic Load Balancing, and EC2 Auto Scaling work together to create a resilient, cost-effective web hosting architecture. You will also explore how to configure security groups, select appropriate instance types, and set up health checks — all essential elements of a well-architected deployment.

The project follows a progressive approach: you will start by launching a single EC2 instance running a web server, then expand to a multi-instance architecture behind a load balancer, and finally configure Auto Scaling to handle traffic fluctuations automatically. By the end, you will have a working, scalable web application architecture and a practical understanding of the AWS services that power it.

## Glossary

- **ec2_instance**: A virtual server in the AWS Cloud running on Amazon EC2, providing configurable CPU, memory, storage, and networking capacity.
- **security_group**: A virtual firewall that controls inbound and outbound traffic for EC2 instances at the instance level.
- **key_pair**: A set of cryptographic keys (public and private) used to securely connect to an EC2 instance.
- **user_data**: A script provided at instance launch that runs automatically when the instance starts for the first time, typically used to install and configure software.
- **elastic_load_balancer**: An AWS service that automatically distributes incoming application traffic across multiple targets such as EC2 instances.
- **target_group**: A logical grouping of targets (such as EC2 instances) that a load balancer routes requests to, including health check configuration.
- **auto_scaling_group**: A collection of EC2 instances managed by EC2 Auto Scaling that automatically adjusts capacity based on defined scaling policies.
- **launch_template**: A reusable configuration template that specifies instance settings (AMI, instance type, security groups, key pair, user data) for launching EC2 instances.
- **availability_zone**: A distinct, isolated data center location within an AWS Region, used to provide fault tolerance and high availability.
- **dynamic_scaling_policy**: An Auto Scaling policy that adjusts the number of instances in response to real-time changes in a specified metric such as CPU utilization.
- **health_check**: A periodic test performed by a load balancer or Auto Scaling group to determine whether an instance is healthy and able to serve traffic.

## Requirements

### Requirement 1: Launch a Web Server on an EC2 Instance

**User Story:** As a cloud computing learner, I want to launch an EC2 instance running a web server, so that I can understand how to deploy a basic web application on a virtual server in the AWS Cloud.

#### Acceptance Criteria

1. WHEN the learner launches an EC2 instance with a specified Amazon Machine Image (AMI) and instance type, THE instance SHALL reach the running state and be accessible over the network.
2. THE instance SHALL execute a user data script at launch that installs and starts a web server and deploys a simple web page (such as a "Hello, World!" page).
3. WHEN the learner connects to the instance's public IP address or public DNS name using a web browser, THE web server SHALL return the deployed web page content.
4. THE instance SHALL be launched with a key pair so that the learner can establish a secure remote connection for administration and troubleshooting.

### Requirement 2: Configure Security Groups for Web Traffic

**User Story:** As a cloud computing learner, I want to configure security groups that control inbound and outbound traffic to my EC2 instances, so that I understand how to secure network access to web applications in AWS.

#### Acceptance Criteria

1. THE security group associated with the web server instance SHALL allow inbound HTTP traffic (port 80) from any source so that the web application is publicly accessible.
2. THE security group SHALL allow inbound SSH (Linux) or RDP (Windows) traffic only from the learner's IP address, restricting remote administrative access.
3. IF the learner removes the inbound HTTP rule from the security group, THEN THE web application SHALL become unreachable from a browser, and when the rule is restored, access SHALL resume without restarting the instance.
4. THE security group SHALL deny all other inbound traffic that is not explicitly permitted by an inbound rule.

### Requirement 3: Deploy Multiple Instances Across Availability Zones

**User Story:** As a cloud computing learner, I want to launch web server instances in multiple Availability Zones, so that I understand how to design for high availability and fault tolerance in AWS.

#### Acceptance Criteria

1. WHEN the learner launches EC2 instances using the same launch template, THE instances SHALL be deployed across at least two different Availability Zones within the same AWS Region.
2. THE launch template SHALL define the AMI, instance type, security group, key pair, and user data script so that every instance launched from it runs an identical web server configuration.
3. WHEN any individual instance is terminated or becomes unhealthy, THE web application SHALL remain accessible through the instances running in the other Availability Zone(s).

### Requirement 4: Distribute Traffic with an Application Load Balancer

**User Story:** As a cloud computing learner, I want to set up an Application Load Balancer to distribute incoming traffic across my EC2 instances, so that I understand how Elastic Load Balancing improves application reliability and performance.

#### Acceptance Criteria

1. WHEN the learner creates an Application Load Balancer with a listener on port 80 and registers EC2 instances in a target group, THE load balancer SHALL distribute incoming HTTP requests across all healthy registered instances.
2. THE load balancer SHALL be configured as internet-facing and span at least two Availability Zones, using subnets in each zone.
3. WHEN a registered instance fails its health check, THE load balancer SHALL stop routing traffic to that instance, and WHEN the instance recovers, THE load balancer SHALL resume routing traffic to it.
4. WHEN the learner accesses the load balancer's DNS name from a web browser, THE load balancer SHALL return the web page content served by one of the healthy target instances.

### Requirement 5: Configure EC2 Auto Scaling for Dynamic Capacity

**User Story:** As a cloud computing learner, I want to configure an Auto Scaling group with a dynamic scaling policy, so that I understand how AWS automatically adjusts compute capacity in response to changing demand.

#### Acceptance Criteria

1. WHEN the learner creates an Auto Scaling group referencing the launch template and associated target group, THE group SHALL maintain a minimum number of running instances (at least 2) and define a maximum capacity limit.
2. WHEN average CPU utilization across the group exceeds a defined threshold (such as 50%), THE Auto Scaling group SHALL launch additional instances up to the maximum capacity to handle the increased load.
3. WHEN average CPU utilization drops below the threshold, THE Auto Scaling group SHALL gradually terminate excess instances while maintaining at least the minimum number of healthy instances.
4. THE Auto Scaling group SHALL launch new instances across the configured Availability Zones and automatically register them with the target group so that the load balancer begins routing traffic to them.

### Requirement 6: Verify Scaling Behavior and Instance Health

**User Story:** As a cloud computing learner, I want to observe how Auto Scaling responds to load changes and how unhealthy instances are replaced, so that I can validate that my scalable architecture works as intended.

#### Acceptance Criteria

1. WHEN the learner generates simulated load on the web application (such as CPU stress on running instances), THE Auto Scaling group SHALL detect the metric change and launch new instances within the defined scaling policy parameters.
2. WHEN the learner manually terminates an instance within the Auto Scaling group, THE group SHALL detect the reduction below the desired capacity and launch a replacement instance automatically.
3. THE learner SHALL be able to observe scaling activity history in the Auto Scaling group, including events for instance launches and terminations with their associated reasons.
4. WHILE the Auto Scaling group is adding or removing instances, THE load balancer SHALL continue to serve traffic through the remaining healthy instances without interruption to the web application.

### Requirement 7: Optimize Costs with Appropriate Instance Configuration

**User Story:** As a cloud computing learner, I want to understand how instance type selection and Auto Scaling group settings affect cost, so that I can make informed decisions about balancing performance and expense.

#### Acceptance Criteria

1. THE learner SHALL select an instance type from the free-tier-eligible or small general-purpose instance family to minimize costs during the learning exercise.
2. THE Auto Scaling group SHALL be configured with a maximum capacity limit that prevents runaway scaling and unexpected charges during testing.
3. WHEN the learner has completed the exercise, THE learner SHALL be able to delete the Auto Scaling group, load balancer, target group, and all associated EC2 instances to stop incurring charges, with no resources remaining in a running state.
