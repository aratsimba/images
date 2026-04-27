

# Implementation Plan: Build a Cloud Contact Center with Amazon Connect

## Overview

This implementation plan guides you through building a fully functional cloud contact center using Amazon Connect. The approach is progressive: you start by provisioning the foundational Connect instance and storage, then layer on telephony, contact flow design, routing configuration, agent setup, chat support, and finally operational metrics. Each phase builds on the previous one, mirroring how a real contact center is assembled in practice.

The project uses a hybrid approach combining Python boto3 scripts for programmatic provisioning (instance creation, phone number management, queue/routing configuration, metrics retrieval) with AWS Console operations for visual tasks like contact flow design and the agent Contact Control Panel (CCP). Four Python components are implemented: InstanceManager, TelephonyManager, ContactCenterConfig, and MetricsRetriever. These components encapsulate all SDK interactions and follow the interfaces defined in the design specification.

Key milestones include: (1) an active Connect instance with storage configured, (2) a claimed phone number routing calls through a branching contact flow, (3) queues, routing profiles, and agents configured for skills-based routing with voice and chat, (4) a working end-to-end agent experience via the CCP, and (5) real-time and historical metrics retrieval. Dependencies flow linearly — the instance must exist before claiming numbers, contact flows must exist before associating phone numbers, and queues/routing profiles must exist before creating agents.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for Amazon Connect, Amazon S3, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Ensure your IAM user/role has the following policies: `AmazonConnect_FullAccess`, `AmazonS3FullAccess` (or scoped equivalents)
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2 and verify: `aws --version`
    - Install Python 3.12 and verify: `python3 --version`
    - Install boto3: `pip install boto3`
    - Create project directory structure: `mkdir -p components` and create `components/__init__.py`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region to one that supports Amazon Connect: `export AWS_DEFAULT_REGION=us-east-1`
    - Verify Amazon Connect service availability: `aws connect list-instances`
    - Check Amazon Connect service quotas (instances per account defaults to 2): `aws service-quotas get-service-quota --service-code connect --quota-code L-6E2CBD4A`
    - _Requirements: (all)_

- [ ] 2. Amazon Connect Instance Provisioning (InstanceManager)
  - [ ] 2.1 Implement InstanceManager component
    - Create `components/instance_manager.py` with class `InstanceManager`
    - Initialize boto3 clients: `self.connect_client = boto3.client('connect')` and `self.s3_client = boto3.client('s3')`
    - Implement `create_instance(instance_alias, identity_management_type)` using `connect_client.create_instance()` with `IdentityManagementType='CONNECT_MANAGED'`, `InstanceAlias=instance_alias`, and `InboundCallsEnabled=True`, `OutboundCallsEnabled=True`
    - Implement `get_instance_status(instance_id)` using `connect_client.describe_instance()`
    - Implement `wait_until_active(instance_id)` with polling loop (check status every 10 seconds, timeout after 5 minutes)
    - Implement `list_instances()` using `connect_client.list_instances()`
    - Implement `delete_instance(instance_id)` using `connect_client.delete_instance()`
    - Handle `DuplicateResourceException` to prevent duplicate instance creation
    - _Requirements: 1.1, 1.4_
  - [ ] 2.2 Implement instance storage configuration
    - Implement `configure_instance_storage(instance_id, resource_type, bucket_name, prefix)` using `connect_client.associate_instance_storage_config()`
    - Create an S3 bucket for storage: `aws s3 mb s3://<your-connect-storage-bucket>`
    - Configure storage for resource types: `CALL_RECORDINGS`, `CHAT_TRANSCRIPTS`, and `EXPORTED_REPORTS`
    - Implement `get_instance_settings(instance_id)` using `connect_client.describe_instance()` and `connect_client.list_instance_storage_configs()` to display telephony, data streaming, and storage settings
    - _Requirements: 1.2, 1.3_
  - [ ] 2.3 Create and verify the Connect instance
    - Create a runner script `scripts/create_instance.py` that instantiates `InstanceManager`, calls `create_instance()`, waits until active, then configures all three storage types
    - Run the script and verify the instance reaches `ACTIVE` state
    - Verify in AWS Console: navigate to Amazon Connect → Instances and confirm the instance appears
    - Verify settings by calling `get_instance_settings()` and confirming telephony and storage configuration
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 3. Telephony and Phone Number Configuration (TelephonyManager)
  - [ ] 3.1 Implement TelephonyManager component
    - Create `components/telephony_manager.py` with class `TelephonyManager`
    - Initialize boto3 client: `self.connect_client = boto3.client('connect')`
    - Implement `list_available_phone_numbers(instance_id, country_code, phone_number_type)` using `connect_client.list_phone_numbers_v2()` or `connect_client.search_available_phone_numbers()` with `TargetArn`, `PhoneNumberCountryCode`, and `PhoneNumberType` (DID or TOLL_FREE)
    - Implement `claim_phone_number(instance_id, phone_number, contact_flow_id)` using `connect_client.claim_phone_number()` with `TargetArn` set to the instance ARN
    - Implement `associate_phone_number_to_flow(phone_number_id, instance_id, contact_flow_id)` using `connect_client.associate_phone_number_contact_flow()` to change the associated contact flow
    - Implement `list_claimed_phone_numbers(instance_id)` using `connect_client.list_phone_numbers_v2()`
    - Implement `release_phone_number(phone_number_id)` using `connect_client.release_phone_number()`
    - _Requirements: 2.1, 2.2_
  - [ ] 3.2 Claim a phone number and associate with default flow
    - Create `scripts/setup_telephony.py` that lists available DID or toll-free numbers for country code `US`
    - Claim one phone number from the available list (note: phone number association with a contact flow will be updated after the contact flow is created in the next task)
    - List claimed phone numbers to verify the number is associated with the instance
    - Record the `phone_number_id` and `phone_number` (E.164 format) for later use
    - _Requirements: 2.1, 2.2, 2.3_

- [ ] 4. Contact Flow Design (AWS Console)
  - [ ] 4.1 Create a contact flow with branching logic
    - Log in to the Amazon Connect admin console (URL found in instance overview)
    - Navigate to **Routing → Contact flows** and click **Create contact flow**
    - Name the flow (e.g., "Main Inbound Flow")
    - Add a **Play prompt** block at the entry point with a welcome message (e.g., "Welcome to our contact center")
    - Add a **Get customer input** block with DTMF menu: Press 1 for Sales, Press 2 for Support
    - Branch based on input: route "1" to a **Set working queue** block (Sales queue) and "2" to another **Set working queue** block (Support queue) — queues will be created in the next task; use placeholder names or the default queue for now
    - After each Set working queue, add a **Transfer to queue** block
    - Add an error branch from **Get customer input** to a **Play prompt** block ("Sorry, we didn't understand your selection") followed by a **Disconnect** block
    - Add error branches on **Transfer to queue** blocks leading to a **Play prompt** ("All agents are busy, please try again later") then **Disconnect**
    - **Publish** the contact flow and note the Contact Flow ID
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ] 4.2 Associate phone number with the contact flow
    - Use `TelephonyManager.associate_phone_number_to_flow()` to link the claimed phone number to the published contact flow ID
    - Create or update `scripts/associate_phone_to_flow.py` to perform this association
    - Verify by calling `list_claimed_phone_numbers()` and confirming the `contact_flow_id` matches
    - _Requirements: 2.2, 2.3, 3.1_

- [ ] 5. Checkpoint - Validate Instance, Telephony, and Contact Flow
  - Verify the Connect instance is in `ACTIVE` state by running `get_instance_status()`
  - Verify S3 storage is configured for call recordings, chat transcripts, and exported reports
  - Verify at least one phone number is claimed and associated with the contact flow
  - Place a test call to the claimed phone number from a personal phone and verify the welcome prompt plays and menu options are presented
  - Verify pressing an invalid key triggers the error path and disconnect message
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Queues, Routing Profiles, and Agent Configuration (ContactCenterConfig)
  - [ ] 6.1 Implement ContactCenterConfig component
    - Create `components/contact_center_config.py` with class `ContactCenterConfig`
    - Initialize: `self.connect_client = boto3.client('connect')`
    - Implement `create_hours_of_operation(instance_id, name, timezone, schedule)` using `connect_client.create_hours_of_operation()` with `Config` containing day/time entries matching the `DaySchedule` data model
    - Implement `create_queue(instance_id, name, hours_of_operation_id, description)` using `connect_client.create_queue()`
    - Implement `list_queues(instance_id)` using `connect_client.list_queues()`
    - Implement `create_routing_profile(instance_id, name, default_outbound_queue_id, queue_configs, channel_concurrencies)` using `connect_client.create_routing_profile()` with `MediaConcurrencies` for VOICE (concurrency=1) and CHAT (concurrency=3)
    - Implement `list_routing_profiles(instance_id)` using `connect_client.list_routing_profiles()`
    - Implement `list_security_profiles(instance_id)` using `connect_client.list_security_profiles()`
    - Implement `create_agent_user(instance_id, username, password, routing_profile_id, security_profile_ids, identity_info)` using `connect_client.create_user()` with `IdentityInfo` (first_name, last_name, email), `PhoneConfig` (PhoneType='SOFT_PHONE'), and assigned profiles
    - Implement `list_users(instance_id)` using `connect_client.list_users()`
    - Implement `get_contact_flow_list(instance_id)` using `connect_client.list_contact_flows()`
    - _Requirements: 4.1, 4.2, 4.3, 6.1_
  - [ ] 6.2 Set up routing chain: hours → queues → routing profiles → agents
    - Create `scripts/setup_routing.py` that orchestrates the full routing chain
    - Create hours of operation (e.g., "Business Hours" — Monday–Friday 8:00–18:00, timezone "America/New_York")
    - Create two queues: "Sales Queue" and "Support Queue", each with the hours of operation ID
    - Update the contact flow in the AWS Console to set the correct queue IDs in the **Set working queue** blocks (replace placeholders from Task 4)
    - Create a routing profile (e.g., "General Agent Profile") with `default_outbound_queue_id` set to Sales Queue, `queue_configs` mapping both queues for VOICE and CHAT channels with priority 1 and delay 0
    - Look up the "Agent" security profile ID using `list_security_profiles()`
    - Create an agent user with username, password, routing profile ID, security profile ID, and identity info
    - Verify by listing queues, routing profiles, and users
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 6.3 Enable chat channel support
    - Verify chat is enabled on the instance (chat is enabled by default on Amazon Connect instances)
    - Confirm the routing profile includes CHAT channel concurrency (set to 3 concurrent chats) in the `channel_concurrencies` parameter
    - Verify queues are accessible for chat contacts by confirming queue configs in the routing profile include CHAT channel entries
    - Test chat initiation using the Amazon Connect test chat interface in the admin console (Communications → Test chat)
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 7. Agent Experience with the Contact Control Panel (AWS Console)
  - [ ] 7.1 Log in to CCP and handle a voice contact
    - Open the Contact Control Panel URL (found in the Connect instance overview page)
    - Log in with the agent credentials created in Task 6
    - Set agent status to **Available**
    - Place a test call to the claimed phone number, navigate through the IVR menu, and verify the call is presented to the agent in the CCP
    - Accept the call and verify CCP controls: **Hold**, **Mute**, **Transfer**, and **Disconnect** are available
    - End the call using Disconnect and verify the agent enters After Contact Work (ACW) state
    - Record a disposition/notes during ACW, then set status back to Available
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 7.2 Handle a chat contact via CCP
    - Initiate a test chat from the Amazon Connect admin console (Communications → Test chat) or using the Amazon Connect chat test page
    - Verify the chat contact is routed through the contact flow and presented to the agent in the CCP
    - Exchange messages as both customer and agent to confirm bidirectional chat works
    - Verify the agent can handle the chat alongside the ability to receive additional chats (up to concurrency limit)
    - _Requirements: 5.1, 5.2, 6.2, 6.3_

- [ ] 8. Checkpoint - Validate End-to-End Contact Routing
  - Place an inbound call, navigate the IVR to Sales, and confirm the agent receives the call in the CCP
  - Place another call and select Support to verify branching routes to the correct queue
  - Initiate a chat and verify it routes to the agent alongside voice capability
  - Verify that when no agents are available (set agent to offline), contacts remain queued
  - Confirm call recordings are being stored in the configured S3 bucket: `aws s3 ls s3://<your-connect-storage-bucket>/connect/<instance-alias>/CallRecordings/`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Real-Time and Historical Metrics (MetricsRetriever)
  - [ ] 9.1 Implement MetricsRetriever component
    - Create `components/metrics_retriever.py` with class `MetricsRetriever`
    - Initialize: `self.connect_client = boto3.client('connect')`
    - Implement `get_current_metric_data(instance_id, filters, groupings, metrics)` using `connect_client.get_current_metric_data()` with `CurrentMetrics` for `CONTACTS_IN_QUEUE`, `AGENTS_AVAILABLE`, `OLDEST_CONTACT_AGE`, and `AGENTS_ONLINE`
    - Implement `get_metric_data_v2(instance_id, start_time, end_time, filters, groupings, metrics)` using `connect_client.get_metric_data_v2()` for historical metrics: `CONTACTS_HANDLED`, `AVG_HANDLE_TIME`, `SERVICE_LEVEL`
    - Implement `search_contacts(instance_id, time_range, search_criteria)` using `connect_client.search_contacts()` to find contacts by time range
    - Implement `get_contact_details(instance_id, contact_id)` using `connect_client.describe_contact()` to retrieve individual contact data
    - _Requirements: 7.1, 7.2, 7.4_
  - [ ] 9.2 Retrieve and display metrics
    - Create `scripts/get_metrics.py` to demonstrate all metrics capabilities
    - Query real-time metrics grouped by queue and display contacts in queue, agents available, and oldest contact age
    - Query historical metrics for the past 24 hours grouped by queue, then by agent, then by routing profile — display contact volumes, average handle time, and service level
    - Filter metrics by specific queue ID and channel to demonstrate filtering capabilities
    - Search contacts from the past 24 hours and retrieve details for one contact to verify call recording storage
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ]* 9.3 Validate metrics in AWS Console
    - **Property 1: Real-Time Dashboard Accuracy**
    - **Validates: Requirements 7.1, 7.2, 7.3**
    - Open Amazon Connect admin console → Analytics → Real-time metrics and compare with script output
    - Open Historical metrics and generate a report grouped by queue for the same time range
    - Verify dashboard values match API query results

- [ ] 10. Checkpoint - Full System Validation
  - Run `scripts/create_instance.py` output to confirm instance is active with storage configured
  - Run `scripts/setup_telephony.py` output to confirm phone number is claimed and associated
  - Run `scripts/setup_routing.py` output to confirm queues, routing profiles, and agents exist
  - Place a test call end-to-end: dial in → IVR menu → agent pickup → call recording → metrics visible
  - Initiate a test chat end-to-end: chat → routing → agent handles in CCP
  - Run `scripts/get_metrics.py` and verify real-time and historical data is returned
  - Verify call recordings exist in S3
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Release telephony resources
    - Release all claimed phone numbers using `TelephonyManager.release_phone_number()` for each phone number ID
    - Verify: `TelephonyManager.list_claimed_phone_numbers()` returns empty list
    - _Requirements: (all)_
  - [ ] 11.2 Delete Connect instance and associated resources
    - Delete the Amazon Connect instance using `InstanceManager.delete_instance(instance_id)`
    - Note: Deleting the instance automatically removes all queues, routing profiles, contact flows, users, and hours of operation within it
    - Verify deletion: `InstanceManager.list_instances()` should no longer show the instance
    - _Requirements: (all)_
  - [ ] 11.3 Clean up S3 storage
    - Empty and delete the S3 bucket used for call recordings and transcripts: `aws s3 rb s3://<your-connect-storage-bucket> --force`
    - Verify: `aws s3 ls s3://<your-connect-storage-bucket>` should return "NoSuchBucket" error
    - _Requirements: (all)_
  - [ ] 11.4 Verify complete cleanup
    - Run `aws connect list-instances` and confirm no project instances remain
    - Check AWS Cost Explorer to ensure no ongoing Amazon Connect charges
    - Note: Amazon Connect charges are pay-per-use; once the instance and phone numbers are deleted, no further charges accrue
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Task 4 (Contact Flow Design) and Task 7 (Agent CCP Experience) are performed in the AWS Console since the visual flow editor and CCP are browser-based tools not available via SDK
- Phone numbers may take a few minutes to become active after claiming; allow time before test calls
- The agent password must meet Amazon Connect complexity requirements (8+ chars, uppercase, lowercase, number)
- Chat testing can be done via the built-in test chat widget in the Amazon Connect admin console without deploying a customer-facing chat widget
