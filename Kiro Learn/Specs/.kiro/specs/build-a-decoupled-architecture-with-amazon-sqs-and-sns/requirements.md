

# Requirements Document

## Introduction

This project guides learners through building a decoupled architecture using Amazon Simple Notification Service (SNS) and Amazon Simple Queue Service (SQS). Decoupled architectures are foundational to modern cloud application design, enabling independent scaling, improved fault tolerance, and flexible evolution of system components. By separating message producers from consumers, learners will experience firsthand how loosely coupled systems handle varying workloads without tight coordination between components.

The project focuses on the fanout messaging pattern, where a single published event triggers multiple independent processing workflows. Learners will create an SNS topic that distributes messages to multiple SQS queues, simulating a real-world scenario such as an order processing system where different departments (e.g., inventory, shipping, billing) each receive and process the same order notification independently. This pattern is one of the most widely used integration approaches in AWS-based architectures.

Through this hands-on exercise, learners will gain practical experience with pub/sub messaging, queue-based message consumption, message filtering, dead-letter queue configuration, and monitoring — building a complete end-to-end decoupled pipeline that demonstrates the resilience and scalability benefits of asynchronous communication on AWS.

## Glossary

- **sns_topic**: An Amazon SNS communication channel to which publishers send messages and from which subscribers receive notifications.
- **sqs_queue**: An Amazon SQS message queue that stores messages until a consumer retrieves and processes them.
- **fanout_pattern**: An architecture pattern where a single message published to an SNS topic is delivered to multiple subscribed SQS queues for parallel processing.
- **dead_letter_queue**: An SQS queue designated to receive messages that cannot be successfully processed after a configured number of attempts, enabling troubleshooting and reprocessing.
- **message_filtering**: An SNS subscription feature that allows an SQS queue to receive only a subset of messages published to a topic based on filter criteria defined in a subscription filter policy.
- **visibility_timeout**: The period during which a message retrieved from an SQS queue is hidden from other consumers, preventing duplicate processing.
- **pub_sub_model**: A publish-subscribe messaging paradigm where publishers send messages to a topic without knowledge of subscribers, and subscribers receive messages without knowledge of publishers.

## Requirements

### Requirement 1: SNS Topic Creation and Configuration

**User Story:** As a cloud messaging learner, I want to create an SNS topic that serves as the central publishing point for my decoupled architecture, so that I can understand how pub/sub messaging enables producers to send messages without knowing about consumers.

#### Acceptance Criteria

1. WHEN the learner creates an SNS topic with a specified name, THE topic SHALL become active and available for publishing messages and accepting subscriptions.
2. THE topic SHALL be configured as a Standard topic type to support maximum throughput and best-effort ordering for this learning exercise.
3. IF the learner publishes a message to the topic with no subscriptions configured, THEN THE message SHALL be accepted by the topic without error but not delivered to any endpoint.

### Requirement 2: SQS Queue Provisioning for Multiple Consumers

**User Story:** As a cloud messaging learner, I want to create multiple SQS queues representing different processing workloads, so that I can understand how independent consumers can process the same event at their own pace.

#### Acceptance Criteria

1. WHEN the learner creates an SQS queue with a specified name, THE queue SHALL become available for sending and receiving messages.
2. THE queues SHALL be configured as Standard queues with a visibility timeout sufficient to allow simulated message processing without premature redelivery.
3. WHEN the learner creates at least two SQS queues (e.g., representing inventory processing and shipping processing), THE queues SHALL operate independently and not share message consumption state.
4. THE queues SHALL have a message retention period configured so that unprocessed messages persist long enough for the learner to observe and retrieve them.

### Requirement 3: SNS-to-SQS Fanout Subscription

**User Story:** As a cloud messaging learner, I want to subscribe multiple SQS queues to a single SNS topic, so that I can implement the fanout pattern and observe how one published message reaches multiple consumers simultaneously.

#### Acceptance Criteria

1. WHEN the learner subscribes an SQS queue to the SNS topic, THE subscription SHALL be confirmed and active, enabling automatic message delivery from the topic to the queue.
2. THE SQS queue access policy SHALL be configured to allow the SNS topic to deliver messages to the subscribed queue.
3. WHEN a message is published to the SNS topic with multiple subscribed queues, THE message SHALL be delivered to all subscribed SQS queues, and each queue SHALL contain an independent copy of the message.
4. WHEN the learner retrieves a message from one subscribed queue, THE copies in other subscribed queues SHALL remain unaffected and independently retrievable.

### Requirement 4: Message Publishing and Consumption Workflow

**User Story:** As a cloud messaging learner, I want to publish messages to the SNS topic and consume them from the subscribed SQS queues, so that I can observe the complete lifecycle of a message in a decoupled architecture.

#### Acceptance Criteria

1. WHEN the learner publishes a message with a subject and body to the SNS topic, THE message content SHALL be available for retrieval from each subscribed SQS queue.
2. WHEN the learner retrieves a message from an SQS queue, THE message body SHALL contain the original published content along with SNS metadata in a structured format.
3. WHEN the learner successfully processes and deletes a message from an SQS queue, THE message SHALL no longer be available for retrieval from that queue.
4. IF the learner retrieves a message but does not delete it before the visibility timeout expires, THEN THE message SHALL become available for retrieval again from the same queue.

### Requirement 5: Message Filtering on Subscriptions

**User Story:** As a cloud messaging learner, I want to apply subscription filter policies so that specific SQS queues receive only relevant messages, so that I can understand how message filtering reduces unnecessary processing in consumer workloads.

#### Acceptance Criteria

1. WHEN the learner applies a subscription filter policy to an SNS-to-SQS subscription based on a message attribute, THE subscribed queue SHALL receive only messages whose attributes match the filter criteria.
2. WHEN a message is published with attributes that match one subscription's filter policy but not another, THE matching queue SHALL receive the message and THE non-matching queue SHALL NOT receive it.
3. IF no filter policy is set on a subscription, THEN THE subscribed queue SHALL receive all messages published to the topic regardless of message attributes.

### Requirement 6: Dead-Letter Queue Configuration for Failed Processing

**User Story:** As a cloud messaging learner, I want to configure dead-letter queues for my SQS consumer queues, so that I can understand how failed messages are captured for troubleshooting without blocking the main processing pipeline.

#### Acceptance Criteria

1. WHEN the learner configures a dead-letter queue on a source SQS queue with a maximum receive count, THE messages that exceed the maximum receive count SHALL be moved to the dead-letter queue.
2. THE dead-letter queue SHALL retain the original message content and attributes, allowing the learner to inspect failed messages for troubleshooting.
3. IF a message is successfully processed and deleted before reaching the maximum receive count, THEN THE message SHALL NOT appear in the dead-letter queue.
4. WHEN the learner inspects the dead-letter queue, THE messages present SHALL reflect only those that failed processing from the associated source queue.

### Requirement 7: Monitoring and Observability with Amazon CloudWatch

**User Story:** As a cloud messaging learner, I want to monitor my SNS topics and SQS queues using Amazon CloudWatch, so that I can observe message flow, detect delivery issues, and understand operational visibility in a decoupled architecture.

#### Acceptance Criteria

1. WHEN messages are published to the SNS topic, THE learner SHALL be able to view CloudWatch metrics reflecting the number of messages published and the number of messages delivered to subscriptions.
2. WHEN messages accumulate in an SQS queue, THE learner SHALL be able to view CloudWatch metrics reflecting the approximate number of visible messages and the approximate number of messages not visible (in-flight).
3. WHEN messages are moved to the dead-letter queue, THE learner SHALL be able to observe the dead-letter queue depth through CloudWatch metrics to identify processing failures.
