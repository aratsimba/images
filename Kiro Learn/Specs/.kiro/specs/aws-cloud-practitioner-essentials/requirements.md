

# Requirements Document

## Introduction

This project is a hands-on learning exercise designed to build foundational knowledge of the AWS Cloud, aligned with the AWS Cloud Practitioner Essentials course curriculum. The learner will gain practical experience with core AWS services spanning compute, networking, storage, databases, security, and monitoring — the essential building blocks of any cloud deployment.

The AWS Certified Cloud Practitioner (CLF-C02) exam validates overall knowledge of the AWS Cloud across four domains: Cloud Concepts, Security and Compliance, Cloud Technology and Services, and Billing/Pricing/Support. Rather than studying these topics in isolation, this project takes a learn-by-doing approach: the learner will provision and configure real AWS resources that mirror a simplified cloud architecture, reinforcing conceptual understanding through hands-on practice.

By completing this project, the learner will understand how AWS services work together in a real environment, grasp the shared responsibility model through direct configuration of security controls, observe cost and billing behaviors firsthand, and build confidence navigating the AWS Management Console and core service dashboards. The project is scoped as a learning exercise — not a production system — and emphasizes breadth of service exposure over architectural depth.

## Glossary

- **virtual_private_cloud**: An isolated virtual network within AWS where the learner launches and organizes cloud resources with control over IP addressing, subnets, and routing.
- **security_group**: A virtual firewall that controls inbound and outbound traffic at the instance level within a VPC.
- **shared_responsibility_model**: The AWS framework that divides security responsibilities between AWS (security of the cloud infrastructure) and the customer (security in the cloud, including data and access configuration).
- **availability_zone**: A physically separate data center location within an AWS Region, used to provide redundancy and fault tolerance.
- **iam_policy**: A JSON-based document that defines permissions, specifying which actions are allowed or denied on which AWS resources.
- **block_public_access**: An S3 account-level and bucket-level setting that prevents public access to objects regardless of individual object permissions.
- **cloudwatch_alarm**: A monitoring rule that watches a single metric and triggers a notification or action when the metric crosses a defined threshold.
- **on_demand_capacity**: A pricing and provisioning mode where resources are consumed and billed based on actual usage without upfront commitments or capacity planning.
- **cost_allocation_tag**: A metadata key-value pair applied to AWS resources that enables cost tracking and categorization in billing reports.

## Requirements

### Requirement 1: VPC and Network Foundation

**User Story:** As a cloud practitioner learner, I want to create a Virtual Private Cloud with public and private subnets across multiple Availability Zones, so that I understand how AWS networking provides isolation, segmentation, and high availability.

#### Acceptance Criteria

1. WHEN the learner creates a VPC with a specified CIDR block, THE VPC SHALL be available and THE learner SHALL be able to create subnets within it.
2. THE VPC SHALL contain at least one public subnet (associated with an internet gateway and route table allowing internet-bound traffic) and at least one private subnet (with no direct internet route).
3. WHEN the learner creates subnets in at least two different Availability Zones, THE subnets SHALL be independently addressable and THE architecture SHALL demonstrate the concept of multi-AZ redundancy.
4. THE VPC SHALL have a security group configured to allow inbound traffic only on a specific port for the learner's intended application, demonstrating the principle of least privilege at the network level.

### Requirement 2: EC2 Compute Instance Deployment

**User Story:** As a cloud practitioner learner, I want to launch an Amazon EC2 instance in my public subnet and connect to it, so that I understand how cloud compute resources are provisioned, configured, and accessed.

#### Acceptance Criteria

1. WHEN the learner launches an EC2 instance with a specified Amazon Machine Image and instance type, THE instance SHALL reach a running state within the learner's VPC public subnet.
2. THE instance SHALL be associated with a security group that permits inbound access only from the learner's IP address, demonstrating security group controls.
3. WHEN the learner assigns a key pair to the instance at launch, THE learner SHALL be able to use that key pair to establish a remote connection to the instance.
4. IF the learner stops and restarts the instance, THEN THE instance SHALL retain its attached storage volume data and return to a running state, demonstrating the difference between stopping and terminating.

### Requirement 3: S3 Storage and Data Management

**User Story:** As a cloud practitioner learner, I want to create an Amazon S3 bucket, upload objects, and configure access controls, so that I understand how cloud object storage works and how to secure data at rest.

#### Acceptance Criteria

1. WHEN the learner creates an S3 bucket with a globally unique name in a specified Region, THE bucket SHALL be available for storing objects.
2. THE bucket SHALL have Block Public Access enabled at the bucket level, demonstrating the AWS best practice of restricting public access by default.
3. WHEN the learner uploads an object to the bucket, THE object SHALL be stored durably and SHALL be retrievable using its key.
4. WHEN the learner enables versioning on the bucket and uploads a modified version of an existing object, THE bucket SHALL retain both the current and previous versions of that object.

### Requirement 4: IAM Security and Access Management

**User Story:** As a cloud practitioner learner, I want to create IAM users, groups, and policies with scoped permissions, so that I understand the shared responsibility model and how AWS identity controls protect cloud resources.

#### Acceptance Criteria

1. WHEN the learner creates an IAM user and adds it to an IAM group with an attached policy, THE user SHALL inherit the permissions defined in the group's policy.
2. THE learner SHALL configure an IAM policy that grants read-only access to a specific S3 bucket, demonstrating the principle of least privilege and resource-level permissions.
3. IF the IAM user attempts to perform an action not permitted by the attached policy (such as deleting a resource), THEN THE service SHALL deny the request and THE resource SHALL remain unchanged.
4. WHEN the learner enables multi-factor authentication on the root account or an IAM user, THE account SHALL require the additional authentication factor for console sign-in, demonstrating a security best practice.

### Requirement 5: Database Provisioning with Amazon RDS

**User Story:** As a cloud practitioner learner, I want to launch a managed relational database instance using Amazon RDS in a private subnet, so that I understand how AWS managed database services simplify operations and how network placement protects data resources.

#### Acceptance Criteria

1. WHEN the learner creates an RDS instance with a specified database engine and places it in a private subnet group, THE database instance SHALL become available and SHALL NOT be directly accessible from the public internet.
2. THE RDS instance SHALL use a security group that permits inbound database connections only from the EC2 instance's security group, demonstrating security group referencing for service-to-service access.
3. WHEN the learner connects to the database from the EC2 instance and creates a table with sample data, THE data SHALL be persisted and queryable across subsequent connections.

### Requirement 6: Monitoring and Alerting with CloudWatch

**User Story:** As a cloud practitioner learner, I want to configure Amazon CloudWatch to monitor my EC2 instance metrics and set up an alarm, so that I understand how AWS provides observability and automated notifications for cloud resources.

#### Acceptance Criteria

1. WHEN the learner navigates to CloudWatch metrics for the running EC2 instance, THE service SHALL display utilization metrics (such as CPU utilization) collected automatically by the service.
2. WHEN the learner creates a CloudWatch alarm on a metric with a defined threshold, THE alarm SHALL transition between OK and ALARM states based on whether the metric crosses the threshold.
3. WHEN the learner configures an Amazon SNS topic as the alarm action and the alarm enters ALARM state, THE learner SHALL receive a notification at the subscribed endpoint (such as an email address).

### Requirement 7: Cost Visibility and Resource Tagging

**User Story:** As a cloud practitioner learner, I want to apply cost allocation tags to all project resources and explore the AWS Billing Dashboard, so that I understand how AWS billing works and how to track and manage cloud costs.

#### Acceptance Criteria

1. THE learner SHALL apply a consistent set of tags (including at minimum a project name tag and an environment tag) to every resource created during this project, demonstrating the tagging best practice for cost tracking and resource organization.
2. WHEN the learner accesses the AWS Billing and Cost Management dashboard, THE dashboard SHALL display cost data and THE learner SHALL be able to identify charges associated with services used in this project.
3. WHEN the learner reviews the AWS Free Tier usage page, THE page SHALL show current usage levels against Free Tier limits for each applicable service, demonstrating awareness of cost controls.
4. WHEN the learner terminates or deletes all project resources at the conclusion of the exercise, THE resources SHALL no longer appear as active and SHALL stop accruing charges, reinforcing the importance of resource cleanup.

### Requirement 8: Architecture Review Against the Well-Architected Framework

**User Story:** As a cloud practitioner learner, I want to review my completed project architecture against the pillars of the AWS Well-Architected Framework, so that I can articulate how cloud best practices apply to real deployments and strengthen my exam readiness.

#### Acceptance Criteria

1. THE learner SHALL document how the project addresses at least three pillars of the AWS Well-Architected Framework (such as Security, Operational Excellence, and Cost Optimization) by mapping specific resource configurations to the relevant pillar principles.
2. WHEN the learner identifies a gap where the project architecture does not fully align with a Well-Architected pillar (such as Reliability through multi-AZ database deployment), THE learner SHALL describe what additional AWS service feature or configuration would address that gap.
3. THE learner SHALL produce a simple architecture diagram that shows the relationships between the VPC, subnets, EC2 instance, RDS instance, S3 bucket, and CloudWatch monitoring, demonstrating an understanding of how core AWS services integrate in a cloud deployment.
