

# Implementation Plan: AWS Cloud Practitioner Essentials

## Overview

This implementation plan guides the learner through building a complete AWS cloud architecture that reinforces the core concepts tested on the AWS Certified Cloud Practitioner (CLF-C02) exam. The approach is hands-on: rather than studying services in isolation, the learner provisions real AWS resources — a multi-AZ VPC, EC2 instance, RDS database, S3 bucket, IAM users/policies, CloudWatch alarms, and SNS notifications — that work together as a cohesive architecture. Shell scripts using AWS CLI handle infrastructure provisioning (networking, compute, database), while Python boto3 scripts manage S3 operations, IAM configuration, and monitoring setup.

The plan follows a logical dependency order across four phases. Phase 1 establishes prerequisites and the network foundation (VPC, subnets, security groups). Phase 2 builds the compute and database layers (EC2 in public subnet, RDS in private subnet). Phase 3 adds storage, security, and monitoring (S3 with versioning, IAM least-privilege policies, CloudWatch alarms with SNS). Phase 4 covers cost visibility, tagging verification, architecture review against the Well-Architected Framework, and mandatory resource cleanup.

Key dependencies dictate task ordering: the VPC and security groups must exist before EC2 or RDS can be launched; the EC2 instance must be running before RDS connectivity can be tested; the S3 bucket must exist before IAM read-only policies can reference it; and all resources must be provisioned before tagging verification and the architecture review. The ProjectConfig and ProvisionedResources data models are populated incrementally as each task completes, with resource IDs passed forward to downstream tasks.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account (Free Tier eligible recommended)
    - Configure AWS CLI: `aws configure` (set access key, secret key, default region, output format)
    - Verify access: `aws sts get-caller-identity`
    - Confirm the IAM user has AdministratorAccess policy attached for lab provisioning
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3` and verify with `python3 -c "import boto3; print(boto3.__version__)"`
    - Install a MySQL client (e.g., `mysql` CLI) for RDS connectivity testing
    - _Requirements: (all)_
  - [ ] 1.3 Project Configuration and Directory Structure
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `mkdir -p components/`
    - Create a `config.sh` file defining the `ProjectConfig` values: `PROJECT_NAME="ccp-lab"`, `ENVIRONMENT="learning"`, `REGION="us-east-1"`, `VPC_CIDR="10.0.0.0/16"`, public subnet CIDRs `["10.0.1.0/24", "10.0.2.0/24"]`, private subnet CIDRs `["10.0.3.0/24", "10.0.4.0/24"]`, AZs `["us-east-1a", "us-east-1b"]`
    - Create a `resources.sh` file to store `ProvisionedResources` IDs as they are created (vpc_id, subnet_ids, etc.)
    - Define the `TagSet` variables: `TAG_PROJECT="ccp-lab"`, `TAG_ENVIRONMENT="learning"`
    - _Requirements: 7.1_

- [ ] 2. VPC and Network Foundation
  - [ ] 2.1 Create VPC, Subnets, and Internet Gateway
    - Create `components/network_provisioner.sh`
    - Implement `create_vpc`: `aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Project,Value=ccp-lab},{Key=Environment,Value=learning}]'` — capture VPC ID
    - Implement `create_subnet` for four subnets: public subnet 1 (10.0.1.0/24, us-east-1a), public subnet 2 (10.0.2.0/24, us-east-1b), private subnet 1 (10.0.3.0/24, us-east-1a), private subnet 2 (10.0.4.0/24, us-east-1b) — tag each with Project and Environment
    - Enable auto-assign public IP on both public subnets: `aws ec2 modify-subnet-attribute --subnet-id <id> --map-public-ip-on-launch`
    - Implement `create_internet_gateway`: create IGW, attach to VPC, tag with Project/Environment
    - Verify: `aws ec2 describe-vpcs --vpc-ids <vpc-id>` shows available state; `aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpc-id>` shows 4 subnets across 2 AZs
    - _Requirements: 1.1, 1.2, 1.3, 7.1_
  - [ ] 2.2 Configure Route Tables and Security Groups
    - Implement `create_route_table`: create a public route table, add route `0.0.0.0/0 -> IGW`, associate both public subnets — tag with Project/Environment
    - Verify private subnets use the VPC main route table (no internet route), confirming public vs. private isolation
    - Implement `create_security_group` for EC2 (SGWeb): allow inbound SSH (port 22) from learner's IP only (`curl ifconfig.me`), tag with Project/Environment — capture SG ID
    - Implement `create_security_group` for RDS (SGDb): allow inbound MySQL (port 3306) from EC2 security group ID only (security group referencing), tag with Project/Environment — capture SG ID
    - Implement `create_db_subnet_group`: create RDS subnet group from both private subnets: `aws rds create-db-subnet-group --db-subnet-group-name ccp-lab-db-subnets --subnet-ids <priv-sub-1> <priv-sub-2> --db-subnet-group-description "CCP Lab private subnets"` — tag with Project/Environment
    - Save all resource IDs to `resources.sh`
    - Verify: `aws ec2 describe-security-groups --group-ids <sg-web> <sg-db>` shows correct inbound rules
    - _Requirements: 1.2, 1.4, 5.2, 7.1_

- [ ] 3. EC2 Compute and RDS Database Deployment
  - [ ] 3.1 Launch EC2 Instance in Public Subnet
    - Create `components/compute_provisioner.sh`
    - Implement `create_key_pair`: `aws ec2 create-key-pair --key-name ccp-lab-key --query 'KeyMaterial' --output text > ccp-lab-key.pem` then `chmod 400 ccp-lab-key.pem`
    - Implement `launch_instance`: `aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --instance-type t2.micro --subnet-id <public-subnet-1> --security-group-ids <sg-web> --key-name ccp-lab-key --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=ccp-lab},{Key=Environment,Value=learning}]'` — capture instance ID
    - Implement `get_instance_status` and `get_public_ip`: wait for running state, retrieve public IP
    - Test SSH connectivity: `ssh -i ccp-lab-key.pem ec2-user@<public-ip>`
    - Save instance ID and public IP to `resources.sh`
    - _Requirements: 2.1, 2.2, 2.3, 7.1_
  - [ ] 3.2 Test EC2 Stop/Start Lifecycle
    - Implement `stop_instance`: `aws ec2 stop-instances --instance-ids <id>` — wait for stopped state
    - Implement `start_instance`: `aws ec2 start-instances --instance-ids <id>` — wait for running state
    - Verify the EBS volume data persists after stop/start (note the public IP may change)
    - Confirm the instance returns to running state and is SSH-accessible again
    - _Requirements: 2.4_
  - [ ] 3.3 Launch RDS MySQL in Private Subnet
    - Create `components/database_provisioner.sh`
    - Implement `create_rds_instance`: `aws rds create-db-instance --db-instance-identifier ccp-lab-db --engine mysql --db-instance-class db.t3.micro --master-username admin --master-user-password <secure-password> --allocated-storage 20 --db-subnet-group-name ccp-lab-db-subnets --vpc-security-group-ids <sg-db> --no-publicly-accessible --tags Key=Project,Value=ccp-lab Key=Environment,Value=learning`
    - Implement `wait_until_available`: `aws rds wait db-instance-available --db-instance-identifier ccp-lab-db` (may take 5-10 minutes)
    - Implement `get_endpoint`: `aws rds describe-db-instances --db-instance-identifier ccp-lab-db --query 'DBInstances[0].Endpoint.Address' --output text`
    - Implement `generate_connection_script`: create a script to run from EC2 that connects via `mysql -h <endpoint> -u admin -p`
    - SSH into EC2, install mysql client (`sudo yum install mysql -y`), connect to RDS endpoint, create a table with sample data, query it, disconnect and reconnect to verify persistence
    - Verify: RDS is NOT accessible from local machine (only from EC2 via security group reference)
    - Save RDS identifier and endpoint to `resources.sh`
    - _Requirements: 5.1, 5.2, 5.3, 7.1_

- [ ] 4. Checkpoint - Validate Network, Compute, and Database Infrastructure
  - Verify VPC has 4 subnets across 2 AZs: `aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpc-id> --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]'`
  - Verify EC2 instance is running in public subnet with SSH access
  - Verify RDS is in private subnet, accessible only from EC2 (not from internet)
  - Verify security groups enforce least-privilege: SSH from learner IP only, MySQL from EC2 SG only
  - Verify all resources have Project and Environment tags
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. S3 Storage and IAM Security Configuration
  - [ ] 5.1 Create S3 Bucket with Versioning
    - Create `components/storage_manager.py`
    - Implement `create_bucket`: create bucket with globally unique name (e.g., `ccp-lab-<account-id>-<region>`), apply Project and Environment tags via `put_bucket_tagging`
    - Implement `enable_block_public_access`: `s3_client.put_public_access_block(Bucket=bucket_name, PublicAccessBlockConfiguration={'BlockPublicAcls': True, 'IgnorePublicAcls': True, 'BlockPublicPolicy': True, 'RestrictPublicBuckets': True})`
    - Implement `enable_versioning`: `s3_client.put_bucket_versioning(Bucket=bucket_name, VersioningConfiguration={'Status': 'Enabled'})`
    - Implement `upload_object`: upload a test file, capture VersionId
    - Implement `get_object`: download and verify the object matches the uploaded file
    - Upload a modified version of the same object key, then implement `list_object_versions` to confirm both versions are retained
    - Verify: `aws s3api get-public-access-block --bucket <name>` shows all four Block Public Access settings enabled
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 7.1_
  - [ ] 5.2 Configure IAM Users, Groups, and Least-Privilege Policies
    - Create `components/security_manager.py`
    - Implement `create_group`: create IAM group `ccp-lab-s3-readers`
    - Implement `create_user`: create IAM user `ccp-lab-reader`
    - Implement `add_user_to_group`: add user to group
    - Implement `create_s3_readonly_policy`: create a custom IAM policy granting `s3:GetObject` and `s3:ListBucket` on the specific S3 bucket ARN only
    - Implement `attach_policy_to_group`: attach the policy to the group
    - Implement `test_permission`: use `iam.simulate_principal_policy()` to verify the user CAN perform `s3:GetObject` on the bucket and CANNOT perform `s3:DeleteBucket` — confirm AccessDenied for unauthorized actions
    - Implement `get_mfa_status`: check MFA device status on root account or IAM user; document the steps to enable MFA via Console (note: MFA enablement is a Console operation)
    - Save IAM user name, group name, and policy ARN to `resources.sh`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 7.1_

- [ ] 6. Monitoring, Alerting, and Cost Visibility
  - [ ] 6.1 Set Up CloudWatch Alarm and SNS Notification
    - Create `components/monitoring_manager.py`
    - Implement `create_sns_topic`: create topic `ccp-lab-alerts`, subscribe learner's email address, tag with Project/Environment
    - Remind learner to check email and confirm SNS subscription (handle `SubscriptionConfirmationPending`)
    - Implement `get_metric_data`: query `CPUUtilization` for the EC2 instance (wait 5-10 minutes if `MetricDataNotAvailable`)
    - Implement `create_cpu_alarm`: create alarm `ccp-lab-cpu-high` on CPUUtilization > 80% for 1 evaluation period, action = SNS topic ARN
    - Implement `get_alarm_state`: verify alarm is in OK state initially
    - Optionally generate CPU load on EC2 (`stress` tool or `dd` command) to trigger ALARM state and receive email notification
    - Save SNS topic ARN and alarm name to `resources.sh`
    - _Requirements: 6.1, 6.2, 6.3, 7.1_
  - [ ] 6.2 Verify Resource Tags and Explore Billing Dashboard
    - Implement `verify_resource_tags`: iterate over all resource ARNs in `ProvisionedResources`, use `resourcegroupstaggingapi` to verify each has Project=ccp-lab and Environment=learning tags
    - Navigate to AWS Billing and Cost Management dashboard in Console: identify charges by service (EC2, RDS, S3)
    - Navigate to Free Tier usage page: review current usage against Free Tier limits for EC2, RDS, S3
    - Document findings: which services show charges, which are within Free Tier
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 7. Checkpoint - Validate Complete Architecture
  - Verify S3 bucket has Block Public Access enabled, versioning active, and both object versions retrievable
  - Verify IAM user inherits group policy, can read S3 objects, and is denied unauthorized actions
  - Verify CloudWatch displays EC2 CPU metrics and alarm is configured with SNS action
  - Verify SNS subscription is confirmed and notification would be received on ALARM
  - Verify all resources across VPC, EC2, RDS, S3, IAM, CloudWatch, SNS have Project and Environment tags
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Architecture Review and Documentation
  - [ ] 8.1 Create Architecture Diagram
    - Produce a simple architecture diagram (using draw.io, Lucidchart, or ASCII art) showing: VPC with public/private subnets across 2 AZs, Internet Gateway, EC2 in public subnet, RDS in private subnet, security group references, S3 bucket, CloudWatch alarm, SNS topic, IAM policies
    - Label all components with their resource types and relationships (matching the Mermaid diagram from the design document)
    - _Requirements: 8.3_
  - [ ] 8.2 Well-Architected Framework Review
    - Document how the project addresses the **Security** pillar: IAM least-privilege, security groups, Block Public Access, MFA, private subnet for RDS
    - Document how the project addresses the **Operational Excellence** pillar: CloudWatch monitoring, SNS alerting, resource tagging for organization
    - Document how the project addresses the **Cost Optimization** pillar: Free Tier awareness, cost allocation tags, resource cleanup plan
    - Identify gaps: e.g., **Reliability** — RDS is single-AZ (describe how Multi-AZ deployment would address this); **Performance Efficiency** — no auto-scaling or load balancing (describe how these services would help)
    - Capture the review as a `WellArchitectedReview` document with pillar, addressed_by, gap_description, and remediation fields for each pillar assessed
    - _Requirements: 8.1, 8.2_

- [ ] 9. Cleanup - Resource Teardown
  - [ ] 9.1 Delete Monitoring and IAM Resources
    - Delete CloudWatch alarm: implement `delete_alarm` — `aws cloudwatch delete-alarms --alarm-names ccp-lab-cpu-high`
    - Delete SNS subscription and topic: implement `delete_sns_topic` — `aws sns delete-topic --topic-arn <arn>`
    - Detach policy from group: `aws iam detach-group-policy --group-name ccp-lab-s3-readers --policy-arn <arn>`
    - Delete IAM policy: `aws iam delete-policy --policy-arn <arn>`
    - Remove user from group and delete: implement `delete_user_and_group` — `aws iam remove-user-from-group`, `aws iam delete-user`, `aws iam delete-group`
    - _Requirements: 7.4_
  - [ ] 9.2 Delete Compute, Database, and Storage Resources
    - Delete S3 objects (all versions): implement `delete_bucket_and_objects` — `aws s3api delete-objects` for all versions, then `aws s3 rb s3://<bucket-name>`
    - Delete RDS instance: implement `delete_rds_instance` — `aws rds delete-db-instance --db-instance-identifier ccp-lab-db --skip-final-snapshot` — wait for deletion
    - Terminate EC2 instance: implement `terminate_instance` — `aws ec2 terminate-instances --instance-ids <id>` — wait for terminated state
    - Delete key pair: `aws ec2 delete-key-pair --key-name ccp-lab-key` and remove local `.pem` file
    - _Requirements: 7.4_
  - [ ] 9.3 Delete Network Resources and Verify
    - Delete DB subnet group: `aws rds delete-db-subnet-group --db-subnet-group-name ccp-lab-db-subnets`
    - Delete security groups (EC2 SG, RDS SG): `aws ec2 delete-security-group --group-id <sg-id>` (delete in order: RDS SG first if referenced)
    - Delete subnets (all 4): `aws ec2 delete-subnet --subnet-id <id>`
    - Detach and delete internet gateway: `aws ec2 detach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>`, then `aws ec2 delete-internet-gateway --internet-gateway-id <igw-id>`
    - Delete route table (custom public route table): `aws ec2 delete-route-table --route-table-id <rtb-id>`
    - Delete VPC: `aws ec2 delete-vpc --vpc-id <vpc-id>`
    - Verify cleanup: `aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=ccp-lab` should return empty results
    - Check Billing Dashboard to confirm resources are no longer accruing charges
    - **Warning**: RDS instances and NAT Gateways (if created) incur charges even when idle — ensure deletion is confirmed before concluding
    - _Requirements: 7.4_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability (format: `_Requirements: X.Y_`)
- Checkpoints (Tasks 4 and 7) ensure incremental validation at major milestones
- Resource IDs are stored in `resources.sh` throughout the project and used during cleanup — keep this file updated after every provisioning step
- RDS creation (Task 3.3) may take 5-10 minutes; CloudWatch metrics (Task 6.1) may take 5-10 minutes to populate — plan accordingly
- The project uses Free Tier eligible resources (t2.micro EC2, db.t3.micro RDS, S3 standard) but learners should monitor the Free Tier usage page to avoid unexpected charges
- MFA enablement (Requirement 4.4) is documented as a Console-based step since programmatic MFA device creation requires a physical or virtual MFA device
- All `ProvisionedResources` fields from the data model are populated incrementally across Tasks 2-6 and consumed during Task 9 for cleanup
