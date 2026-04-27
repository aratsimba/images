# Implementation Plan: Build a Decoupled Architecture with Amazon SQS and SNS

## Overview

This implementation plan guides learners through building a complete decoupled messaging architecture using Amazon SNS and Amazon SQS. The approach follows an incremental build strategy: first establishing the foundational messaging infrastructure (SNS topic and SQS queues), then wiring components together with subscriptions and the fanout pattern, followed by implementing advanced features like message filtering and dead-letter queues, and finally adding observability through CloudWatch metrics.

The plan is organized into logical phases. Phase one covers environment setup and core resource creation — the SNS topic via TopicManager and SQS queues via QueueManager. Phase two focuses on connecting these resources through subscriptions, publishing messages, and consuming them from multiple queues to demonstrate the fanout pattern via MessagingWorkflow. Phase three adds message filtering and dead-letter queue configuration to show production-grade resilience patterns. Phase four introduces monitoring through the MetricsViewer component. Checkpoints are placed after infrastructure creation and after the full workflow is operational to validate incremental progress.

Tasks are ordered by dependency: the SNS topic must exist before queues can subscribe, subscriptions must be active before publishing can demonstrate fanout, and messages must flow before monitoring has data to display. Each Python module maps to a design component and is built as a standalone file under the `components/` directory, with all interactions driven through boto3 SDK calls executed as CLI scripts.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for SNS, SQS, and CloudWatch
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Confirm SNS access: `aws sns list-topics`
    - Confirm SQS access: `aws sqs list-queues`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`
    - Verify boto3: `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 Project Structure and Region Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `mkdir -p components`
    - Create `components/__init__.py` as an empty file
    - Ensure IAM user/role has policies: `AmazonSNSFullAccess`, `AmazonSQSFullAccess`, `CloudWatchReadOnlyAccess`
    - _Requirements: (all)_

- [ ] 2. Implement TopicManager and Create SNS Topic
  - [ ] 2.1 Build the TopicManager component
    - Create `components/topic_manager.py`
    - Initialize boto3 SNS client: `self.sns_client = boto3.client('sns')`
    - Implement `create_topic(topic_name)` using `sns_client.create_topic(Name=topic_name)`, returning the TopicArn
    - Implement `get_topic_attributes(topic_arn)` using `sns_client.get_topic_attributes(TopicArn=topic_arn)`
    - Implement `list_topics()` using `sns_client.list_topics()`, returning a list of topic ARNs
    - Implement `delete_topic(topic_arn)` using `sns_client.delete_topic(TopicArn=topic_arn)`
    - _Requirements: 1.1, 1.2_
  - [ ] 2.2 Create the SNS topic and verify configuration
    - Write a script `scripts/create_topic.py` that instantiates TopicManager and calls `create_topic("order-notifications")`
    - Run the script and save the returned topic ARN for use in subsequent tasks
    - Call `get_topic_attributes()` to confirm the topic is active and is a Standard topic (not FIFO)
    - Call `list_topics()` and verify `order-notifications` appears in the list
    - Verify via CLI: `aws sns get-topic-attributes --topic-arn <topic_arn>`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ]* 2.3 Verify publishing to a topic with no subscriptions
    - Publish a test message to the topic before any subscriptions are created using `sns_client.publish(TopicArn=topic_arn, Subject="Test", Message="No subscribers test")`
    - Confirm the publish call succeeds and returns a MessageId without error
    - Confirm no messages are delivered anywhere (no subscriptions exist)
    - **Property 1: Topic accepts messages with no subscribers without error**
    - **Validates: Requirements 1.3**

- [ ] 3. Implement QueueManager and Provision SQS Queues
  - [ ] 3.1 Build the QueueManager component
    - Create `components/queue_manager.py`
    - Initialize boto3 SQS client: `self.sqs_client = boto3.client('sqs')`
    - Implement `create_queue(queue_name, visibility_timeout=30, message_retention_period=345600)` using `sqs_client.create_queue()` with `Attributes` dict for `VisibilityTimeout` and `MessageRetentionPeriod`
    - Implement `get_queue_url(queue_name)` using `sqs_client.get_queue_url(QueueName=queue_name)`
    - Implement `get_queue_arn(queue_url)` using `sqs_client.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['QueueArn'])`
    - Implement `get_queue_attributes(queue_url)` using `sqs_client.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['All'])`
    - Implement `set_queue_policy(queue_url, queue_arn, topic_arn)` — construct an IAM policy JSON that allows `sns.amazonaws.com` to `sqs:SendMessage` on the queue ARN conditioned on the topic ARN, then call `sqs_client.set_queue_attributes()` with the Policy attribute
    - Implement `configure_dead_letter_queue(source_queue_url, dlq_arn, max_receive_count)` — set the `RedrivePolicy` attribute as JSON: `{"deadLetterTargetArn": dlq_arn, "maxReceiveCount": max_receive_count}`
    - Implement `delete_queue(queue_url)` using `sqs_client.delete_queue(QueueUrl=queue_url)`
    - _Requirements: 2.1, 2.2, 2.4, 3.2, 6.1_
  - [ ] 3.2 Create consumer queues and dead-letter queues
    - Write a script `scripts/create_queues.py` that instantiates QueueManager
    - Create two dead-letter queues: `create_queue("order-inventory-dlq", visibility_timeout=30, message_retention_period=345600)` and `create_queue("order-shipping-dlq", visibility_timeout=30, message_retention_period=345600)`
    - Create two consumer queues: `create_queue("order-inventory-queue", visibility_timeout=30, message_retention_period=345600)` and `create_queue("order-shipping-queue", visibility_timeout=30, message_retention_period=345600)`
    - Configure dead-letter queues: call `configure_dead_letter_queue(inventory_queue_url, inventory_dlq_arn, max_receive_count=3)` and same for shipping
    - Set queue access policies: call `set_queue_policy(inventory_queue_url, inventory_queue_arn, topic_arn)` and same for shipping queue
    - Verify each queue exists: `aws sqs get-queue-attributes --queue-url <url> --attribute-names All`
    - Confirm `RedrivePolicy` is set on both source queues and `Policy` allows SNS delivery
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.2, 6.1, 6.2_

- [ ] 4. Checkpoint - Validate Infrastructure Setup
  - Verify the SNS topic exists: `aws sns get-topic-attributes --topic-arn <topic_arn>`
  - Verify all four SQS queues exist: `aws sqs list-queues --queue-name-prefix order-`
  - Confirm inventory and shipping queues have `RedrivePolicy` pointing to their respective DLQs
  - Confirm queue access policies allow `sns.amazonaws.com` to send messages
  - Confirm visibility timeout and message retention period are set correctly on each queue
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement MessagingWorkflow - Subscriptions and Fanout
  - [ ] 5.1 Build the MessagingWorkflow component - subscription management
    - Create `components/messaging_workflow.py`
    - Initialize both boto3 clients: `self.sns_client = boto3.client('sns')` and `self.sqs_client = boto3.client('sqs')`
    - Implement `subscribe_queue(topic_arn, queue_arn)` using `sns_client.subscribe(TopicArn=topic_arn, Protocol='sqs', Endpoint=queue_arn)`, returning the SubscriptionArn
    - Implement `set_filter_policy(subscription_arn, filter_policy)` using `sns_client.set_subscription_attributes(SubscriptionArn=subscription_arn, AttributeName='FilterPolicy', AttributeValue=json.dumps(filter_policy))`
    - Implement `list_subscriptions(topic_arn)` using `sns_client.list_subscriptions_by_topic(TopicArn=topic_arn)`, returning list of subscription dicts
    - Implement `unsubscribe(subscription_arn)` using `sns_client.unsubscribe(SubscriptionArn=subscription_arn)`
    - _Requirements: 3.1, 3.2, 5.1, 5.3_
  - [ ] 5.2 Build the MessagingWorkflow component - publish and consume
    - Implement `publish_message(topic_arn, subject, message, message_attributes)` — convert `message_attributes` dict to SNS MessageAttributes format (each with `DataType` and `StringValue`), then call `sns_client.publish(TopicArn=topic_arn, Subject=subject, Message=message, MessageAttributes=...)`; return the MessageId
    - Implement `receive_messages(queue_url, max_messages=1, wait_time=5)` using `sqs_client.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=max_messages, WaitTimeSeconds=wait_time, MessageAttributeNames=['All'])`, returning the list of messages
    - Implement `delete_message(queue_url, receipt_handle)` using `sqs_client.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt_handle)`
    - _Requirements: 4.1, 4.2, 4.3_
  - [ ] 5.3 Subscribe queues and test the fanout pattern
    - Write a script `scripts/setup_subscriptions.py` that subscribes both queues to the SNS topic using `subscribe_queue()`
    - Call `list_subscriptions(topic_arn)` and verify both subscriptions are confirmed (SubscriptionArn is not `PendingConfirmation`)
    - Publish a test order message: `publish_message(topic_arn, "New Order", '{"order_id": "ORD-001", "customer_name": "Alice", "item": "Widget", "quantity": 2, "total_amount": 49.99}', {"department": {"DataType": "String", "StringValue": "all"}})`
    - Receive the message from the inventory queue and verify the body contains the original content wrapped in SNS metadata JSON
    - Receive the message from the shipping queue and verify an independent copy exists
    - Delete the message from one queue and confirm it remains available in the other queue
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4_
  - [ ]* 5.4 Verify visibility timeout behavior
    - Receive a message from a queue but do NOT delete it
    - Attempt to receive again immediately — confirm the message is not visible
    - Wait for the visibility timeout (30 seconds) to expire, then receive again — confirm the message reappears
    - Delete the message after verification
    - **Property 2: Visibility timeout hides messages temporarily then restores them**
    - **Validates: Requirements 4.4**

- [ ] 6. Implement Message Filtering
  - [ ] 6.1 Apply filter policies to subscriptions
    - Write a script `scripts/setup_filters.py`
    - Remove existing subscriptions using `unsubscribe()` and re-subscribe both queues to get fresh subscription ARNs
    - Apply filter policy to inventory subscription: `set_filter_policy(inventory_sub_arn, {"department": ["inventory", "all"]})`
    - Apply filter policy to shipping subscription: `set_filter_policy(shipping_sub_arn, {"department": ["shipping", "all"]})`
    - Verify filter policies via `sns_client.get_subscription_attributes()` for each subscription
    - _Requirements: 5.1_
  - [ ] 6.2 Test filtered message delivery
    - Publish a message with attribute `department=inventory`: `publish_message(topic_arn, "Inventory Update", '{"order_id": "ORD-002", "item": "Gadget", "quantity": 5}', {"department": {"DataType": "String", "StringValue": "inventory"}})`
    - Receive from inventory queue — confirm the message arrives
    - Receive from shipping queue (with short wait) — confirm NO message is delivered
    - Publish a message with attribute `department=all` and confirm BOTH queues receive it
    - Clean up: delete all received messages
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 7. Checkpoint - Validate End-to-End Messaging and Filtering
  - Publish a message with `department=shipping` and verify only the shipping queue receives it
  - Publish a message with `department=all` and verify both queues receive it
  - Retrieve a message from each queue and verify the body contains original content with SNS metadata
  - Delete messages from both queues and confirm they are no longer retrievable
  - Verify dead-letter queue configuration is in place by checking `RedrivePolicy` on source queues
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Test Dead-Letter Queue Behavior
  - [ ] 8.1 Simulate failed message processing to trigger DLQ redrive
    - Publish a message with `department=all` so both queues receive it
    - On the inventory queue, receive the message but do NOT delete it; let visibility timeout expire (repeat this receive-without-delete cycle 3 times to exceed `maxReceiveCount`)
    - After the third failed receive cycle, wait briefly then check the inventory DLQ: `receive_messages(inventory_dlq_url, max_messages=1, wait_time=10)`
    - Confirm the original message content and attributes are preserved in the DLQ message
    - _Requirements: 6.1, 6.2, 6.4_
  - [ ] 8.2 Verify successful processing prevents DLQ delivery
    - Publish another message and receive it from the shipping queue
    - Delete the message immediately after first receive using `delete_message()`
    - Verify the shipping DLQ remains empty (no messages available)
    - _Requirements: 6.3_

- [ ] 9. Implement MetricsViewer and Monitor with CloudWatch
  - [ ] 9.1 Build the MetricsViewer component
    - Create `components/metrics_viewer.py`
    - Initialize boto3 CloudWatch client: `self.cloudwatch_client = boto3.client('cloudwatch')`
    - Implement `get_topic_metrics(topic_name, metric_name, period_seconds=300, minutes_back=60)` — use `cloudwatch_client.get_metric_statistics()` with `Namespace='AWS/SNS'`, `Dimensions=[{'Name': 'TopicName', 'Value': topic_name}]`, `MetricName=metric_name`, `StartTime`, `EndTime`, `Period`, `Statistics=['Sum']`; return list of datapoint dicts
    - Implement `get_queue_metrics(queue_name, metric_name, period_seconds=300, minutes_back=60)` — same pattern with `Namespace='AWS/SQS'` and `Dimensions=[{'Name': 'QueueName', 'Value': queue_name}]`
    - Implement `display_topic_summary(topic_name, minutes_back=60)` — call `get_topic_metrics` for `NumberOfMessagesPublished` and `NumberOfNotificationsDelivered`, print formatted summary
    - Implement `display_queue_summary(queue_name, minutes_back=60)` — call `get_queue_metrics` for `ApproximateNumberOfMessagesVisible` and `ApproximateNumberOfMessagesNotVisible`, print formatted summary
    - _Requirements: 7.1, 7.2, 7.3_
  - [ ] 9.2 View metrics for the messaging architecture
    - Write a script `scripts/view_metrics.py` that instantiates MetricsViewer
    - Call `display_topic_summary("order-notifications", minutes_back=120)` and confirm published/delivered counts reflect messages sent during earlier tasks
    - Call `display_queue_summary("order-inventory-queue", minutes_back=120)` and `display_queue_summary("order-shipping-queue", minutes_back=120)` — observe visible and in-flight message counts
    - Call `display_queue_summary("order-inventory-dlq", minutes_back=120)` to observe DLQ depth reflecting the failed messages from Task 8
    - Note: CloudWatch metrics may have a delay of several minutes; if metrics show zero, wait and retry
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 10. Checkpoint - Validate Complete Architecture
  - Run `display_topic_summary` and confirm `NumberOfMessagesPublished` is greater than zero
  - Run `display_queue_summary` for both consumer queues and confirm metrics are visible
  - Run `display_queue_summary` for the inventory DLQ and confirm it shows message depth from failed processing
  - Publish one final message with `department=all`, receive from both queues, delete from both, and verify end-to-end flow
  - Verify all four components (`TopicManager`, `QueueManager`, `MessagingWorkflow`, `MetricsViewer`) are functional
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Remove subscriptions and delete SNS topic
    - List all subscriptions: `aws sns list-subscriptions-by-topic --topic-arn <topic_arn>`
    - Unsubscribe each subscription: `aws sns unsubscribe --subscription-arn <sub_arn>` (repeat for each)
    - Delete the SNS topic: `aws sns delete-topic --topic-arn <topic_arn>`
    - Verify deletion: `aws sns get-topic-attributes --topic-arn <topic_arn>` should return an error
    - _Requirements: (all)_
  - [ ] 11.2 Delete all SQS queues
    - Delete inventory queue: `aws sqs delete-queue --queue-url <inventory_queue_url>`
    - Delete shipping queue: `aws sqs delete-queue --queue-url <shipping_queue_url>`
    - Delete inventory DLQ: `aws sqs delete-queue --queue-url <inventory_dlq_url>`
    - Delete shipping DLQ: `aws sqs delete-queue --queue-url <shipping_dlq_url>`
    - Verify deletion: `aws sqs list-queues --queue-name-prefix order-` should return no results (note: queue deletion may take up to 60 seconds to propagate)
    - _Requirements: (all)_
  - [ ] 11.3 Verify complete cleanup
    - Confirm no SNS topics remain from this project: `aws sns list-topics`
    - Confirm no SQS queues remain from this project: `aws sqs list-queues`
    - Note: CloudWatch metrics will persist for 15 months but incur no additional cost; no cleanup needed
    - Check AWS Billing Dashboard to confirm no ongoing charges from this project
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests that validate specific behavioral requirements but can be skipped for a faster path through the project
- Each task references specific requirements for traceability back to the requirements document
- Checkpoints ensure incremental validation at key milestones — after infrastructure creation (Task 4), after messaging and filtering (Task 7), and after the complete architecture (Task 10)
- CloudWatch metrics may take 5-10 minutes to appear after message activity; plan accordingly when running Task 9
- SQS queue deletion takes up to 60 seconds to propagate; wait before verifying cleanup in Task 11
- Dead-letter queue redrive testing in Task 8 requires patience — you must wait for the visibility timeout to expire between each receive attempt (30 seconds × 3 attempts)
