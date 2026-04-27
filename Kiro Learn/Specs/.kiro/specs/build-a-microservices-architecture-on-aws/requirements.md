# Requirements Document

## Introduction

This project guides learners through building a microservices architecture on AWS, transforming a conceptual monolithic application into a set of independently deployable services. Microservices are an architectural approach where software is designed as a collection of small, autonomous services that communicate over well-defined APIs. By completing this project, learners will gain hands-on experience with the core AWS services and patterns that enable scalable, fault-tolerant, and independently deployable microservices.

The project centers on a simple forum application composed of three microservices — a user service, a topic service, and a message service — each running on a different compute platform to demonstrate the flexibility of microservices design. Learners will implement one service using AWS Lambda (serverless), one using containers on Amazon ECS, and one using Amazon EC2, all fronted by an Application Load Balancer with path-based routing. This multi-compute approach mirrors real-world patterns described in the AWS "Implementing Microservices on AWS" whitepaper.

Beyond basic deployment, learners will explore cross-cutting concerns essential to any microservices architecture: service discovery, centralized logging and monitoring, independent data stores per service, and asynchronous inter-service communication. The project is scoped as a learning exercise and prioritizes breadth of understanding over production-grade hardening.

## Glossary

- **microservice**: A small, independently deployable service focused on a specific business domain that communicates with other services through well-defined APIs.
- **path_based_routing**: An Application Load Balancer feature that directs incoming requests to different target groups based on the URL path pattern (e.g., /users, /topics, /messages).
- **target_group**: A logical grouping of compute resources (Lambda functions, ECS tasks, or EC2 instances) that receive traffic from a load balancer.
- **service_discovery**: The mechanism by which microservices locate and communicate with each other, managed through AWS Cloud Map or load balancer DNS names.
- **container_task_definition**: A configuration in Amazon ECS that describes one or more containers, including image, resource limits, and environment variables.
- **event_driven_communication**: An asynchronous pattern where services publish events to a message broker (such as Amazon SNS or Amazon SQS) rather than calling each other directly.
- **database_per_service**: A microservices pattern where each service owns and manages its own data store, preventing direct database sharing between services.
- **availability_zone**: An isolated location within an AWS Region that provides redundancy and fault tolerance when services are distributed across multiple zones.

## Requirements

### Requirement 1: API Gateway with Path-Based Routing

**User Story:** As a microservices learner, I want to configure an Application Load Balancer with path-based routing rules, so that a single entry point can direct traffic to the correct backend microservice based on the request path.

#### Acceptance Criteria

1. WHEN the learner creates an Application Load Balancer with listener rules for distinct URL path patterns (e.g., /users/\*, /topics/\*, /messages/\*), THE load balancer SHALL route each request to the corresponding target group.
2. THE Application Load Balancer SHALL be deployed across at least two Availability Zones to provide fault tolerance for incoming traffic.
3. IF a request arrives with a path that does not match any configured routing rule, THEN THE load balancer SHALL return a fixed-response default action indicating the path is not found.
4. THE load balancer SHALL perform health checks against each target group and SHALL only route traffic to targets reporting as healthy.

### Requirement 2: Serverless Microservice with AWS Lambda

**User Story:** As a microservices learner, I want to deploy a user service as an AWS Lambda function behind the Application Load Balancer, so that I understand how to build a serverless microservice that scales automatically without managing infrastructure.

#### Acceptance Criteria

1. WHEN the learner creates a Lambda function and registers it as a target in a load balancer target group, THE function SHALL be invocable through the load balancer's path-based routing rule for the /users path.
2. THE Lambda function SHALL read from and write to its own dedicated Amazon DynamoDB table to persist user data, following the database-per-service pattern.
3. THE Lambda function SHALL use an IAM execution role that grants only the minimum permissions needed to access its dedicated data store and write logs.
4. WHEN multiple concurrent requests arrive at the /users path, THE Lambda service SHALL scale the function concurrently to handle the load without learner intervention.

### Requirement 3: Container-Based Microservice with Amazon ECS

**User Story:** As a microservices learner, I want to deploy a message service as a containerized application on Amazon ECS with AWS Fargate, so that I understand how to run and manage microservices using containers without provisioning servers.

#### Acceptance Criteria

1. WHEN the learner creates an ECS task definition, builds a container image, and pushes it to Amazon ECR, THE image SHALL be stored in a private repository and referenced by the task definition.
2. WHEN the learner creates an ECS service using Fargate launch type, THE service SHALL maintain the desired count of running tasks and SHALL register those tasks with the load balancer target group for the /messages path.
3. THE ECS service SHALL distribute tasks across at least two Availability Zones to provide high availability.
4. THE container SHALL connect to its own dedicated data store (separate from the user service's data store) to persist message data, following the database-per-service pattern.

### Requirement 4: EC2-Based Microservice

**User Story:** As a microservices learner, I want to deploy a topic service on an Amazon EC2 instance, so that I understand how traditional server-based compute can participate alongside serverless and container-based services in a microservices architecture.

#### Acceptance Criteria

1. WHEN the learner launches an EC2 instance and deploys the topic service application on it, THE instance SHALL be registered with the load balancer target group for the /topics path and SHALL respond to routed requests.
2. THE EC2 instance SHALL be placed in a private subnet and SHALL receive internet-bound traffic only through the Application Load Balancer in a public subnet.
3. THE topic service SHALL use its own dedicated data store, independent from the user and message services' data stores.
4. THE EC2 instance SHALL have a security group that allows inbound traffic only from the Application Load Balancer's security group on the application port.

### Requirement 5: Asynchronous Inter-Service Communication

**User Story:** As a microservices learner, I want to set up event-driven communication between microservices using Amazon SNS and Amazon SQS, so that I understand how services can communicate asynchronously without direct coupling.

#### Acceptance Criteria

1. WHEN the learner creates an SNS topic and subscribes an SQS queue to it, THE messages published to the SNS topic SHALL be delivered to the subscribed SQS queue.
2. WHEN one microservice publishes an event (e.g., a new topic is created), THE consuming microservice SHALL receive and process that event from its SQS queue without the publishing service needing to know the consumer's endpoint.
3. IF a message in the SQS queue fails processing multiple times, THEN THE queue SHALL move the message to a configured dead-letter queue for later inspection.
4. THE SQS queue SHALL have an access policy that permits only the associated SNS topic to send messages to it.

### Requirement 6: Centralized Logging and Monitoring

**User Story:** As a microservices learner, I want to configure centralized logging and monitoring across all three microservices, so that I can observe the behavior and health of a distributed system from a single location.

#### Acceptance Criteria

1. THE Lambda function, ECS tasks, and EC2 instance SHALL all send application logs to Amazon CloudWatch Logs, each in a distinct log group identified by service name.
2. WHEN the learner creates a CloudWatch dashboard, THE dashboard SHALL display key metrics from all three compute platforms (Lambda invocations, ECS task health, EC2 instance metrics) in a unified view.
3. WHEN a metric breaches a defined threshold (e.g., elevated error count for any service), THE CloudWatch alarm SHALL send a notification to an SNS topic that the learner has subscribed to.
4. THE EC2-based service SHALL use the CloudWatch agent to publish custom application-level logs and metrics, since it does not have built-in CloudWatch integration like Lambda and ECS with awslogs driver.

### Requirement 7: Networking and Service Isolation

**User Story:** As a microservices learner, I want to design a VPC with public and private subnets across multiple Availability Zones, so that I understand how to network microservices securely while maintaining high availability.

#### Acceptance Criteria

1. WHEN the learner creates a VPC with public and private subnets in at least two Availability Zones, THE Application Load Balancer SHALL be placed in the public subnets and THE compute resources (ECS tasks, EC2 instances) SHALL be placed in private subnets.
2. THE private subnets SHALL route outbound internet traffic through a NAT Gateway to allow compute resources to pull container images and install dependencies without being directly reachable from the internet.
3. EACH microservice's compute resource SHALL have its own security group, and THE security groups SHALL restrict inbound access to only the traffic sources required for that service's operation.
4. IF a learner attempts to access a microservice's compute resource directly from the internet (bypassing the load balancer), THEN THE network configuration SHALL deny the connection.

### Requirement 8: Independent Deployment and Service Resilience

**User Story:** As a microservices learner, I want to update and redeploy a single microservice without affecting the other running services, so that I understand the autonomy and independent deployability that microservices architecture provides.

#### Acceptance Criteria

1. WHEN the learner updates and redeploys the container-based message service (e.g., by pushing a new image and updating the ECS service), THE user service and topic service SHALL continue to operate and respond to requests without interruption.
2. WHEN the ECS service performs a rolling update, THE load balancer SHALL drain connections from old tasks before deregistering them and SHALL begin routing to new tasks only after they pass health checks.
3. IF one microservice becomes unavailable (e.g., the Lambda function encounters an error), THEN THE other microservices SHALL continue to function independently and THE load balancer SHALL return the default error response only for requests routed to the unhealthy service.
4. THE learner SHALL be able to verify independent deployability by confirming that the other services' health check status and response behavior remain unchanged during a single service's redeployment.
