

# Implementation Plan: Build a Secure VPC Network with Public and Private Subnets

## Overview

This implementation plan guides learners through building a secure multi-tier VPC network on AWS using Python 3.12 with boto3. The approach follows a layered progression: first establishing the core network infrastructure (VPC, subnets, gateways, and routing), then applying security controls (security groups and network ACLs), launching EC2 instances for verification, and finally enabling VPC Flow Logs for network monitoring. Each phase builds on the previous one, ensuring learners understand how components interconnect before adding complexity.

The project is organized into key milestones: network foundation (VPC, subnets, Internet Gateway, NAT Gateways, route tables), security layer (security groups and NACLs), connectivity verification (EC2 instances in both tiers with bastion pattern testing), and observability (VPC Flow Logs with CloudWatch Logs). A dedicated ConnectivityVerifier component validates the architecture at each stage. This ordering mirrors real-world VPC design — you must have a functioning network before applying security controls, and you need running instances to verify the design works.

Dependencies flow strictly forward: subnets depend on the VPC, NAT Gateways depend on public subnets and Elastic IPs, route tables depend on gateways, security groups and NACLs depend on the VPC and subnets, EC2 instances depend on all preceding resources, and Flow Logs depend on the VPC being fully operational. The cleanup task at the end ensures all resources — especially cost-incurring NAT Gateways and Elastic IPs — are properly torn down.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for VPC, EC2, CloudWatch Logs, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3` and verify with `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and EC2 Key Pair Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure an existing EC2 key pair for SSH access: `aws ec2 describe-key-pairs`
    - If no key pair exists, create one: `aws ec2 create-key-pair --key-name secure-vpc-key --query 'KeyMaterial' --output text > secure-vpc-key.pem && chmod 400 secure-vpc-key.pem`
    - Create the project directory structure: `mkdir -p components` and create `components/__init__.py`
    - Define the `VPCConfig` data model in `components/config.py` with fields: `vpc_cidr`, `vpc_name`, `region`, `public_subnet_cidrs`, `private_subnet_cidrs`, `key_pair_name`
    - _Requirements: (all)_

- [ ] 2. VPC, Subnets, and Internet Gateway
  - [ ] 2.1 Implement VPCManager - VPC and Subnet Creation
    - Create `components/vpc_manager.py` with class `VPCManager` using `boto3.client('ec2')`
    - Implement `get_availability_zones(region)` to retrieve at least two AZs
    - Implement `create_vpc(cidr_block, name)` that creates a VPC with CIDR `10.0.0.0/16`, enables DNS support and hostnames, tags it, and returns the `vpc_id`
    - Implement `create_subnet(vpc_id, cidr_block, az, is_public, name)` with proper tagging; create four subnets: public subnets `10.0.1.0/24` and `10.0.2.0/24`, private subnets `10.0.3.0/24` and `10.0.4.0/24`, distributed across two AZs
    - Implement `enable_auto_assign_public_ip(subnet_id)` and call it for each public subnet
    - Verify VPC is available: `aws ec2 describe-vpcs --filters "Name=tag:Name,Values=secure-vpc"`
    - Verify subnets are in two AZs: `aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"`
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [ ] 2.2 Implement VPCManager - Internet Gateway and Public Routing
    - Implement `create_and_attach_internet_gateway(vpc_id, name)` that creates an IGW, attaches it to the VPC, and returns the `igw_id`
    - Implement `create_route_table(vpc_id, name)` to create a public route table
    - Implement `create_route(route_table_id, destination_cidr, gateway_id, nat_gateway_id)` to add `0.0.0.0/0` route pointing to the IGW
    - Implement `associate_route_table(route_table_id, subnet_id)` and associate the public route table with both public subnets
    - Verify IGW is attached: `aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<vpc-id>"`
    - Verify public route table has IGW route: `aws ec2 describe-route-tables --route-table-ids <rt-id>`
    - _Requirements: 2.1, 2.2, 2.3_

- [ ] 3. NAT Gateways and Private Subnet Routing
  - [ ] 3.1 Deploy NAT Gateways in Each Availability Zone
    - Implement `allocate_elastic_ip(name)` to allocate an Elastic IP and return the allocation ID; allocate two EIPs (one per AZ)
    - Implement `create_nat_gateway(subnet_id, elastic_ip_allocation_id, name)` to create a NAT Gateway in a public subnet
    - Implement `wait_nat_gateway_available(nat_gateway_id)` using EC2 waiter to wait for the NAT Gateway to reach `available` state
    - Create one NAT Gateway in each public subnet (one per AZ), each with its own Elastic IP
    - Verify NAT Gateways are available: `aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<vpc-id>"`
    - _Requirements: 3.1, 3.2_
  - [ ] 3.2 Configure Private Subnet Route Tables
    - Create a separate private route table for each AZ using `create_route_table(vpc_id, name)`
    - Add `0.0.0.0/0` route in each private route table pointing to the NAT Gateway in the same AZ using `create_route(route_table_id, "0.0.0.0/0", gateway_id=None, nat_gateway_id=<nat-gw-id>)`
    - Associate each private route table with the corresponding private subnet using `associate_route_table`
    - Verify private route tables have NAT Gateway routes and NO IGW routes: `aws ec2 describe-route-tables --route-table-ids <rt-id>`
    - _Requirements: 3.3, 3.4_

- [ ] 4. Checkpoint - Validate Network Foundation
  - Verify VPC exists with correct CIDR block (`10.0.0.0/16`)
  - Verify four subnets across two AZs with non-overlapping CIDRs
  - Verify Internet Gateway is attached to the VPC
  - Verify public route tables have `0.0.0.0/0` → IGW route
  - Verify private route tables have `0.0.0.0/0` → NAT Gateway route and no IGW route
  - Verify two NAT Gateways are available (one per AZ)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Security Groups and Network ACLs
  - [ ] 5.1 Implement SecurityManager - Security Groups
    - Create `components/security_manager.py` with class `SecurityManager` using `boto3.client('ec2')`
    - Implement `create_security_group(vpc_id, group_name, description)` returning the `group_id`
    - Implement `add_ingress_rule(security_group_id, protocol, from_port, to_port, source)` for CIDR-based rules
    - Implement `add_ingress_rule_from_sg(security_group_id, protocol, from_port, to_port, source_sg_id)` for security-group-based rules
    - Create a public-tier security group allowing inbound SSH (22), HTTP (80), and HTTPS (443) from `0.0.0.0/0`; note default outbound allows all traffic
    - Create a private-tier security group allowing inbound SSH (22) only from the public-tier security group ID using `add_ingress_rule_from_sg`
    - Implement `describe_security_group(security_group_id)` to verify rules
    - Verify: `aws ec2 describe-security-groups --group-ids <public-sg-id> <private-sg-id>`
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 5.2 Implement SecurityManager - Network ACLs
    - Implement `create_network_acl(vpc_id, name)` returning the `nacl_id`
    - Implement `add_network_acl_rule(nacl_id, rule_number, protocol, port_range_from, port_range_to, cidr_block, egress, action)` supporting both inbound and outbound rules
    - Create a public subnet NACL with inbound rules: allow SSH (22, rule 100), HTTP (80, rule 110), HTTPS (443, rule 120) from `0.0.0.0/0`, allow ephemeral ports (1024-65535, rule 130) from `0.0.0.0/0`; outbound rules: allow all traffic (rule 100) to `0.0.0.0/0`; add deny-all rules at rule 200 for both directions
    - Create a private subnet NACL with inbound rules: allow all traffic from VPC CIDR `10.0.0.0/16` (rule 100), allow ephemeral ports (1024-65535, rule 110) from `0.0.0.0/0` for NAT return traffic; outbound rules: allow all traffic (rule 100) to `0.0.0.0/0`; add deny-all rules at rule 200 for inbound
    - Implement `associate_network_acl(nacl_id, subnet_id)` and associate public NACL with public subnets, private NACL with private subnets
    - Implement `describe_network_acl(nacl_id)` to verify rule configuration
    - Verify rules are evaluated in numeric order and first match applies
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 6. EC2 Instances and Connectivity Verification
  - [ ] 6.1 Implement InstanceManager - Launch EC2 Instances
    - Create `components/instance_manager.py` with class `InstanceManager` using `boto3.client('ec2')`
    - Implement `launch_instance(subnet_id, security_group_id, key_name, instance_name, assign_public_ip)` using Amazon Linux 2023 AMI; returns `instance_id`
    - Implement `wait_instance_running(instance_id)` using EC2 waiter
    - Implement `get_instance_info(instance_id)` returning a dictionary with public IP, private IP, subnet ID, and state
    - Launch a public instance (bastion host) in one public subnet with `assign_public_ip=True` and the public-tier security group
    - Launch a private instance in one private subnet with `assign_public_ip=False` and the private-tier security group
    - Implement `terminate_instances(instance_ids)` and `wait_instances_terminated(instance_ids)` for cleanup
    - Verify instances are running: `aws ec2 describe-instances --instance-ids <pub-id> <priv-id>`
    - _Requirements: 6.1, 6.2_
  - [ ] 6.2 Implement ConnectivityVerifier - Validate Architecture
    - Create `components/connectivity_verifier.py` with class `ConnectivityVerifier` using `boto3.client('ec2')`
    - Implement `verify_public_instance_has_public_ip(instance_id)` — confirm public instance has a public IP assigned
    - Implement `verify_private_instance_no_public_ip(instance_id)` — confirm private instance has NO public IP
    - Implement `verify_route_table_has_igw_route(route_table_id)` and `verify_route_table_no_igw_route(route_table_id)` for public/private route validation
    - Implement `verify_route_table_has_nat_route(route_table_id)` for private route validation
    - Implement `verify_security_group_allows_port(security_group_id, port, source)` to confirm expected rules exist
    - Implement `verify_nacl_rule_exists(nacl_id, rule_number, port, action, egress)` to confirm NACL rules
    - Implement `print_architecture_summary(vpc_id)` that prints all VPC resources, subnets, route tables, gateways, and security configurations
    - Run all verification functions and confirm: public instance is internet-reachable on allowed ports, private instance has no public IP, private subnet routes through NAT Gateway, and private SG only allows traffic from public SG (bastion pattern)
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 7. Checkpoint - Validate Security and Connectivity
  - Confirm public instance has a public IP and is in a subnet with IGW route
  - Confirm private instance has no public IP and is in a subnet with NAT Gateway route only
  - Verify public-tier security group allows SSH/HTTP/HTTPS inbound
  - Verify private-tier security group allows inbound only from public-tier security group
  - Verify public NACL allows required ports inbound and ephemeral ports for return traffic
  - Verify private NACL restricts inbound to VPC CIDR
  - Verify bastion pattern: private SG allows SSH from public SG, enabling jump host access
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. VPC Flow Logs and Network Monitoring
  - [ ] 8.1 Implement FlowLogManager - Enable VPC Flow Logs
    - Create `components/flow_log_manager.py` with class `FlowLogManager` using `boto3.client('ec2')`, `boto3.client('logs')`, and `boto3.client('iam')`
    - Implement `create_flow_log_role(role_name)` that creates an IAM role with a trust policy for `vpc-flow-logs.amazonaws.com` and attaches a policy allowing `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, `logs:DescribeLogGroups`, and `logs:DescribeLogStreams`; returns the `role_arn`
    - Implement `create_log_group(log_group_name)` to create a CloudWatch Logs log group
    - Implement `create_vpc_flow_log(vpc_id, log_group_name, role_arn, traffic_type)` with `traffic_type="ALL"` to capture both accepted and rejected traffic; returns `flow_log_id`
    - Verify flow log is active: `aws ec2 describe-flow-logs --filter "Name=resource-id,Values=<vpc-id>"`
    - _Requirements: 7.1, 7.2_
  - [ ] 8.2 Query and Analyze Flow Log Records
    - Implement `get_flow_log_records(log_group_name, start_time, end_time)` that queries CloudWatch Logs Insights or uses `filter_log_events` to retrieve flow log entries
    - Parse flow log records to extract `FlowLogRecord` fields: `timestamp`, `src_addr`, `dst_addr`, `src_port`, `dst_port`, `protocol`, `action`
    - Allow a few minutes for flow logs to populate after traffic generation
    - Verify records contain source/destination IPs, ports, protocol, and ACCEPT/REJECT actions reflecting the security group and NACL decisions
    - Implement `delete_flow_log(flow_log_id)`, `delete_log_group(log_group_name)`, and `delete_flow_log_role(role_name)` for cleanup
    - Verify flow log data in CloudWatch: `aws logs filter-log-events --log-group-name <log-group-name> --limit 10`
    - _Requirements: 7.3, 7.4_

- [ ] 9. Checkpoint - Full Architecture Validation
  - Run `print_architecture_summary(vpc_id)` to display the complete VPC architecture
  - Verify all 7 requirements are met: VPC with multi-AZ subnets, IGW with public routing, NAT Gateways with private routing, security groups with least-privilege rules, NACLs with subnet-level controls, EC2 instances confirming connectivity patterns, and Flow Logs capturing traffic
  - Confirm the `DeployedResources` data model can be populated with all created resource IDs
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Terminate EC2 Instances
    - Terminate public and private instances using `terminate_instances(instance_ids)`
    - Wait for termination: `wait_instances_terminated(instance_ids)`
    - Verify: `aws ec2 describe-instances --instance-ids <ids> --query 'Reservations[].Instances[].State.Name'`
    - _Requirements: (all)_
  - [ ] 10.2 Delete VPC Flow Logs and Monitoring Resources
    - Delete VPC Flow Log: `delete_flow_log(flow_log_id)`
    - Delete CloudWatch Log Group: `delete_log_group(log_group_name)`
    - Delete IAM Flow Log Role (detach policies first): `delete_flow_log_role(role_name)`
    - Verify: `aws ec2 describe-flow-logs --filter "Name=resource-id,Values=<vpc-id>"` returns empty
    - _Requirements: (all)_
  - [ ] 10.3 Delete VPC Networking Resources
    - Implement and run `delete_vpc_resources(vpc_id)` in the following order:
    - Delete NAT Gateways: `aws ec2 delete-nat-gateway --nat-gateway-id <id>` (wait for deleted state — **NAT Gateways incur hourly charges**)
    - Release Elastic IPs: `aws ec2 release-address --allocation-id <id>` (**Elastic IPs incur charges when not associated**)
    - Delete custom route table associations and route tables
    - Delete custom network ACLs (subnets revert to default NACL)
    - Delete security groups (non-default)
    - Detach and delete Internet Gateway: `aws ec2 detach-internet-gateway` then `aws ec2 delete-internet-gateway`
    - Delete subnets: `aws ec2 delete-subnet --subnet-id <id>` for all four subnets
    - Delete VPC: `aws ec2 delete-vpc --vpc-id <vpc-id>`
    - Verify: `aws ec2 describe-vpcs --vpc-ids <vpc-id>` returns not found
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- **Cost Warning**: NAT Gateways and Elastic IPs incur charges while provisioned. Complete the cleanup task promptly after finishing the exercise to avoid unnecessary costs.
- The project creates resources in the order required by AWS dependencies: VPC → Subnets → IGW → EIP → NAT Gateway → Route Tables → Security Groups → NACLs → EC2 Instances → Flow Logs. Cleanup reverses this order.
- Flow Logs may take 5-15 minutes to begin delivering records to CloudWatch Logs after creation.
