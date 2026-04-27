# Requirements Document

## Introduction

This project guides learners through building a secure VPC network architecture with public and private subnets on AWS. VPC design is a foundational skill for cloud practitioners, as nearly every production workload depends on a well-architected network that balances accessibility with security. Understanding how to isolate resources across subnet tiers, control traffic flow, and enable secure outbound connectivity is essential for anyone pursuing cloud networking or solutions architecture.

The learner will create a multi-tier VPC spanning multiple Availability Zones, configure public subnets with internet-facing connectivity and private subnets for protected workloads. They will set up NAT Gateways to allow private resources to reach the internet without exposing them to inbound traffic, and apply layered security controls using security groups and network ACLs. Finally, the learner will enable VPC Flow Logs to gain visibility into network traffic patterns and verify that the architecture is functioning as intended.

This hands-on exercise follows the principle of defense in depth — placing internet-facing components in public subnets and sensitive workloads in private subnets, with controlled pathways between them. By the end, the learner will have a working, resilient network foundation suitable for hosting multi-tier applications securely.

## Glossary

- **vpc**: Virtual Private Cloud — an isolated virtual network within AWS where you launch resources with full control over IP addressing, subnets, routing, and security.
- **public_subnet**: A subnet whose route table includes a route to an Internet Gateway, making resources within it reachable from the internet (when assigned a public IP).
- **private_subnet**: A subnet whose route table has no route to an Internet Gateway, preventing direct inbound internet access to its resources.
- **internet_gateway**: A horizontally scaled, redundant VPC component that enables communication between resources in a VPC and the internet.
- **nat_gateway**: A managed Network Address Translation service placed in a public subnet that allows resources in private subnets to initiate outbound internet connections while blocking inbound traffic.
- **route_table**: A set of rules (routes) that determine where network traffic from subnets is directed.
- **security_group**: A stateful virtual firewall that controls inbound and outbound traffic at the resource (network interface) level.
- **network_acl**: A stateless firewall that controls inbound and outbound traffic at the subnet level, evaluated before security groups.
- **availability_zone**: A physically isolated data center location within an AWS Region, used to build resilient architectures.
- **vpc_flow_logs**: A feature that captures information about IP traffic going to and from network interfaces in a VPC for monitoring and troubleshooting.
- **cidr_block**: Classless Inter-Domain Routing block — a range of IP addresses assigned to a VPC or subnet.
- **elastic_ip**: A static, public IPv4 address that can be associated with resources such as NAT Gateways.

## Requirements

### Requirement 1: VPC and Subnet Creation

**User Story:** As a cloud networking learner, I want to create a VPC with both public and private subnets across multiple Availability Zones, so that I can understand how to design a resilient multi-tier network architecture.

#### Acceptance Criteria

1. WHEN the learner creates a VPC with a specified CIDR block, THE VPC SHALL become available and ready for subnet and gateway associations.
2. WHEN the learner creates subnets within the VPC, THE subnets SHALL be distributed across at least two Availability Zones, with each zone containing at least one public subnet and one private subnet.
3. THE CIDR blocks assigned to each subnet SHALL be non-overlapping ranges within the VPC's CIDR block.
4. IF the learner specifies a CIDR block that conflicts with an existing subnet in the same VPC, THEN THE service SHALL return an error and no subnet SHALL be created.

### Requirement 2: Internet Gateway and Public Subnet Routing

**User Story:** As a cloud networking learner, I want to attach an Internet Gateway to my VPC and configure public subnet route tables, so that I can enable internet connectivity for resources in public subnets.

#### Acceptance Criteria

1. WHEN the learner creates and attaches an Internet Gateway to the VPC, THE Internet Gateway SHALL be in an attached state and associated with exactly one VPC.
2. WHEN the learner creates a route table for public subnets with a default route pointing to the Internet Gateway, THE route table SHALL direct all non-local traffic (0.0.0.0/0) through the Internet Gateway.
3. WHEN the learner associates the public route table with a public subnet, THE resources launched in that subnet with a public IP address SHALL be able to send and receive traffic from the internet.

### Requirement 3: NAT Gateway and Private Subnet Routing

**User Story:** As a cloud networking learner, I want to deploy NAT Gateways in public subnets and configure private subnet route tables, so that private resources can initiate outbound internet connections without being exposed to inbound internet traffic.

#### Acceptance Criteria

1. WHEN the learner creates a NAT Gateway in a public subnet with an associated Elastic IP, THE NAT Gateway SHALL reach an available state and reside in the specified public subnet.
2. THE learner SHALL deploy a NAT Gateway in a public subnet in each Availability Zone to provide zone-independent outbound connectivity for private subnets.
3. WHEN the learner configures private subnet route tables with a default route pointing to the NAT Gateway in the same Availability Zone, THE resources in private subnets SHALL be able to initiate outbound internet connections.
4. THE private subnet route tables SHALL NOT contain a route to the Internet Gateway, ensuring that resources in private subnets remain unreachable from inbound internet traffic.

### Requirement 4: Security Group Configuration

**User Story:** As a cloud networking learner, I want to create and configure security groups with least-privilege inbound and outbound rules, so that I can control traffic to and from resources at the instance level.

#### Acceptance Criteria

1. WHEN the learner creates a security group within the VPC, THE security group SHALL be associated with the VPC and allow rule configuration for inbound and outbound traffic.
2. THE learner SHALL configure a security group for public-facing resources that permits inbound traffic only on specific required ports (e.g., HTTP, HTTPS, or SSH) from defined source addresses.
3. THE learner SHALL configure a security group for private resources that permits inbound traffic only from the security group associated with the public-tier resources, restricting direct access from external sources.
4. IF the learner does not specify any outbound rules, THEN THE security group SHALL allow all outbound traffic by default.

### Requirement 5: Network ACL Configuration

**User Story:** As a cloud networking learner, I want to configure network ACLs on both public and private subnets, so that I can understand how stateless subnet-level firewall rules add a second layer of defense alongside security groups.

#### Acceptance Criteria

1. WHEN the learner creates a custom network ACL and associates it with a subnet, THE network ACL SHALL replace the default network ACL for that subnet and evaluate traffic according to the learner's defined rules.
2. THE network ACL rules SHALL be evaluated in numeric order, and THE first matching rule SHALL determine whether traffic is allowed or denied.
3. THE learner SHALL configure network ACL rules for public subnets that allow inbound traffic on required ports and allow outbound traffic on ephemeral ports to support return traffic.
4. THE learner SHALL configure network ACL rules for private subnets that restrict inbound traffic to sources within the VPC CIDR block.

### Requirement 6: Connectivity Verification with EC2 Instances

**User Story:** As a cloud networking learner, I want to launch EC2 instances in both public and private subnets to verify that the network architecture works as designed, so that I can confirm public instances are internet-accessible and private instances can only reach the internet through the NAT Gateway.

#### Acceptance Criteria

1. WHEN the learner launches an EC2 instance in a public subnet with a public IP address and the public-tier security group, THE instance SHALL be reachable from the internet on the ports allowed by the security group.
2. WHEN the learner launches an EC2 instance in a private subnet with the private-tier security group, THE instance SHALL NOT be directly reachable from the internet.
3. WHEN a private subnet instance initiates an outbound internet connection, THE traffic SHALL route through the NAT Gateway and THE instance SHALL successfully reach external internet endpoints.
4. WHEN the learner connects to the private instance via the public instance (bastion/jump host pattern), THE connection SHALL succeed only when the private-tier security group allows inbound traffic from the public-tier security group.

### Requirement 7: VPC Flow Logs and Network Monitoring

**User Story:** As a cloud networking learner, I want to enable VPC Flow Logs and review captured traffic data, so that I can understand how to monitor and troubleshoot network communication in a VPC environment.

#### Acceptance Criteria

1. WHEN the learner enables VPC Flow Logs on the VPC, THE flow logs SHALL capture accepted and rejected traffic information for network interfaces within the VPC.
2. THE learner SHALL configure VPC Flow Logs to publish to either CloudWatch Logs or an S3 bucket for storage and analysis.
3. WHEN traffic flows between the public and private subnets or to the internet, THE flow log records SHALL contain source and destination IP addresses, ports, protocol, and the accept/reject action.
4. WHEN the learner reviews the flow log data, THE records SHALL reflect the allow and deny decisions made by the security groups and network ACLs configured in the architecture.
