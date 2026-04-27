# Requirements Document

## Introduction

This project guides the learner through building a multi-tier web application on AWS, implementing the foundational three-tier architecture pattern consisting of a presentation tier, a logic tier, and a data tier. Multi-tier architecture is one of the most enduring and widely-used patterns in software engineering, and understanding how to implement it using cloud services is an essential skill for any cloud practitioner or solutions architect.

The learner will gain hands-on experience with network isolation using Amazon VPC, serverless compute and API management, static website hosting, user authentication, and managed database services. By separating the application into distinct tiers with enforced security boundaries, the learner will understand how decoupled architectures improve security, scalability, and maintainability. The project emphasizes the AWS Well-Architected Framework principles, particularly around security and operational excellence.

Through this exercise, the learner will deploy a functional web application where a static frontend communicates with a serverless backend through a managed API layer, which in turn reads and writes data to a managed database — all within a properly configured virtual network with appropriate access controls and high-availability considerations.

## Glossary

- **multi_tier_architecture**: An application design pattern that separates components into distinct layers (presentation, logic, data), each performing specific functions and communicable only through defined interfaces.
- **presentation_tier**: The user-facing layer of the application responsible for rendering the interface and handling user interactions, typically hosted as a static website or single-page application.
- **logic_tier**: The middle layer containing business logic that processes requests from the presentation tier and interacts with the data tier; implemented here using serverless functions and an API gateway.
- **data_tier**: The persistence layer responsible for storing and retrieving application data, implemented using a managed database service.
- **vpc**: Amazon Virtual Private Cloud — an isolated virtual network within AWS where you launch resources with control over IP addressing, subnets, route tables, and gateways.
- **public_subnet**: A VPC subnet whose route table includes a route to an internet gateway, allowing resources within it to be directly reachable from the internet.
- **private_subnet**: A VPC subnet with no direct route to an internet gateway, isolating resources from inbound internet traffic.
- **nat_gateway**: A managed network address translation service that allows resources in private subnets to initiate outbound connections to the internet while remaining unreachable from inbound internet traffic.
- **security_group**: A stateful virtual firewall that controls inbound and outbound traffic at the resource level within a VPC.
- **network_acl**: A stateless firewall that controls inbound and outbound traffic at the subnet level within a VPC.
- **availability_zone**: A physically distinct, independent data center infrastructure within an AWS Region, used to provide high availability through redundancy.

## Requirements

### Requirement 1: VPC and Multi-Tier Network Design

**User Story:** As a cloud architecture learner, I want to create a custom VPC with public and private subnets organized into distinct tiers, so that I understand how network isolation forms the foundation of a secure multi-tier application.

#### Acceptance Criteria

1. WHEN the learner creates a custom VPC with a specified CIDR block, THE VPC SHALL be available and capable of hosting subnets across multiple Availability Zones.
2. THE network design SHALL include at least three subnet tiers: public subnets for the presentation/ingress layer, private subnets for the logic tier, and isolated private subnets for the data tier, each deployed across at least two Availability Zones.
3. WHEN the learner configures route tables, THE public subnets SHALL route internet-bound traffic through an internet gateway, AND THE logic-tier private subnets SHALL route internet-bound traffic through a NAT gateway, AND THE data-tier subnets SHALL have no route to the internet.
4. THE VPC SHALL have DNS resolution and DNS hostnames enabled to support service discovery within the network.

### Requirement 2: Network Security Boundaries Between Tiers

**User Story:** As a cloud security learner, I want to configure security groups and network ACLs to enforce communication rules between tiers, so that I understand how to implement the principle of least privilege at the network level.

#### Acceptance Criteria

1. THE web/presentation tier security group SHALL allow inbound traffic only on standard web protocols from the internet, and THE logic tier security group SHALL allow inbound traffic only from the presentation tier's security group.
2. THE data tier security group SHALL allow inbound database traffic only from the logic tier's security group, and SHALL NOT allow any direct inbound traffic from the internet or the presentation tier.
3. WHEN the learner configures network ACLs for each tier's subnets, THE ACLs SHALL restrict traffic to only the ports and protocols required for inter-tier communication, providing a secondary layer of defense beyond security groups.
4. IF a resource in the presentation tier attempts to communicate directly with the data tier, THEN THE security group and network ACL rules SHALL deny the connection.

### Requirement 3: Data Tier with Managed Database

**User Story:** As a cloud database learner, I want to deploy a managed NoSQL database in the isolated data-tier subnets, so that I can persist application data in a scalable, serverless data store that is protected from direct internet access.

#### Acceptance Criteria

1. WHEN the learner creates a DynamoDB table with a partition key and optional sort key, THE table SHALL become active and support read and write operations from the logic tier.
2. THE DynamoDB table SHALL use on-demand capacity mode to automatically scale with request volume without requiring manual throughput provisioning.
3. THE database SHALL be accessible only from resources within the VPC by configuring a VPC endpoint for DynamoDB, ensuring data-tier traffic does not traverse the public internet.

### Requirement 4: Serverless Logic Tier with Lambda Functions

**User Story:** As a serverless computing learner, I want to create Lambda functions that implement the application's business logic and connect to the data tier, so that I understand how to build a scalable logic tier without managing servers.

#### Acceptance Criteria

1. WHEN the learner creates Lambda functions for core application operations (create, read, update, delete), EACH function SHALL successfully execute within the logic tier's private subnets inside the VPC.
2. THE Lambda functions SHALL be configured with an IAM execution role that grants only the minimum permissions necessary to interact with the data tier, following the principle of least privilege.
3. WHEN a Lambda function processes a valid request, THE function SHALL read from or write to the DynamoDB table and return a structured response indicating success or the requested data.
4. IF a Lambda function receives a malformed or invalid input, THEN THE function SHALL return a meaningful error response without exposing internal system details.

### Requirement 5: API Gateway as the Application Interface

**User Story:** As an API design learner, I want to create a REST API using Amazon API Gateway that routes client requests to the appropriate Lambda functions, so that I understand how a managed API layer decouples the presentation and logic tiers.

#### Acceptance Criteria

1. WHEN the learner creates a REST API with defined resources and methods, THE API Gateway SHALL route each request to the corresponding Lambda function based on the resource path and HTTP method.
2. THE API Gateway SHALL be configured with request validation to reject requests that do not conform to the expected input models before they reach the Lambda functions.
3. WHEN the API is deployed to a stage, THE stage SHALL expose a publicly accessible invoke URL that the presentation tier can use to send requests.
4. THE API Gateway SHALL have CORS (Cross-Origin Resource Sharing) configured to allow requests from the presentation tier's hosting domain while restricting requests from unauthorized origins.

### Requirement 6: Static Presentation Tier with Content Delivery

**User Story:** As a web hosting learner, I want to deploy a static single-page application to Amazon S3 and serve it through Amazon CloudFront, so that I understand how to build a serverless, globally distributed presentation tier.

#### Acceptance Criteria

1. WHEN the learner uploads static web assets (HTML, CSS, JavaScript) to an S3 bucket configured for static website hosting, THE content SHALL be accessible through CloudFront but NOT directly through the S3 bucket's public URL.
2. THE S3 bucket SHALL have Block Public Access enabled, with access granted exclusively through a CloudFront origin access control policy.
3. WHEN a user loads the web application in a browser, THE presentation tier SHALL communicate with the logic tier exclusively through the API Gateway endpoints, demonstrating proper tier separation.
4. THE CloudFront distribution SHALL serve content over HTTPS using a managed SSL/TLS certificate.

### Requirement 7: User Authentication and Access Control

**User Story:** As a cloud security learner, I want to integrate Amazon Cognito for user sign-up and sign-in, so that I understand how to protect the logic tier with authentication and ensure only authorized users can access application functionality.

#### Acceptance Criteria

1. WHEN the learner creates a Cognito user pool, THE user pool SHALL support user registration with email verification and secure password policies.
2. WHEN an authenticated user makes a request through the presentation tier, THE API Gateway SHALL validate the user's token using a Cognito authorizer before forwarding the request to the Lambda function.
3. IF a request arrives at the API Gateway without a valid authentication token, THEN THE API Gateway SHALL reject the request and THE Lambda function SHALL NOT be invoked.

### Requirement 8: High Availability and Multi-AZ Deployment

**User Story:** As a cloud reliability learner, I want to deploy the application's components across multiple Availability Zones, so that I understand how to design architectures that remain operational during the failure of a single Availability Zone.

#### Acceptance Criteria

1. THE VPC subnets for each tier SHALL span at least two Availability Zones, ensuring that no single Availability Zone failure removes an entire tier from service.
2. WHEN the learner configures the NAT gateway infrastructure, THE design SHALL include NAT gateways in multiple Availability Zones so that logic-tier functions maintain outbound internet access even if one Availability Zone becomes unavailable.
3. THE serverless components (Lambda, API Gateway, DynamoDB, S3, CloudFront) SHALL leverage the inherent multi-AZ availability provided by these managed services without requiring the learner to manually configure replication or failover for them.
