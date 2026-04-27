
# AWS CodeDeploy Blue-Green Deployment Design Analysis and Recommendations

**Document Version:** 1.0  
**Analysis Date:** April 10, 2026  
**Reviewed By:** Senior Solutions Architect  
**Project:** AWS CodeDeploy Blue-Green Deployment Learning Module

---

## Executive Summary: Review Questions Assessment

### 1. Is the architecture diagram (Mermaid) clear and correct? Does it show the right AWS services?

**Assessment: ⚠️ Partially Clear and Correct**

**Strengths:**
- Clear visual separation between Python scripts and AWS services
- Shows correct service interactions and data flow
- Includes all necessary AWS services for blue-green deployment (CodeDeploy, EC2, Auto Scaling, ALB, S3, IAM)

**Critical Gaps:**
- Missing VPC representation (subnets referenced but VPC boundary not shown)
- Security groups referenced in code but not visualized
- CodeDeploy agent on EC2 instances not explicitly shown
- IAM permission flow from instance profile to S3 not depicted
- Internet gateway missing (required for CodeDeploy agent communication)

**Verdict:** The diagram shows the right AWS services but lacks critical networking components (VPC, subnets, security groups, internet gateway) that are essential for implementation.

---

### 2. Are components well-defined with clear interfaces? (5-8 components expected)

**Assessment: ✅ Well-Defined (5 components)**

All five components have clear interfaces with appropriate function signatures:
- **IAMSetup**: 4 functions - ✅ Clear scope (IAM only)
- **InfraManager**: 7 functions - ✅ Comprehensive (ALB, target groups, ASG, launch templates)
- **RevisionManager**: 6 functions - ✅ Complete (S3, AppSpec, bundling)
- **DeploymentManager**: 6 functions - ✅ Appropriate (CodeDeploy application and deployment groups)
- **DeploymentMonitor**: 6 functions - ✅ Good separation (status tracking, rollback)

**Interface Issues Identified:**
1. `InfraManager.create_launch_template`: `user_data_script` parameter should specify base64 encoding requirement
2. `RevisionManager.generate_appspec`: Return type should clarify YAML format
3. `DeploymentManager.create_blue_green_deployment_group`: Missing deployment style parameter
4. `DeploymentMonitor.wait_for_deployment`: Missing timeout parameter

**Missing Functions:**
- IAMSetup: Function to verify role permissions
- InfraManager: Function to verify CodeDeploy agent status
- RevisionManager: Function to validate AppSpec before bundling
- DeploymentManager: Function to update deployment group configuration
- DeploymentMonitor: Function to retrieve agent logs from instances

**Verdict:** Components are well-defined with clear boundaries, but interfaces need refinement for production readiness.

---

### 3. Are data model definitions (TYPE) accurate and complete?

**Assessment: ⚠️ Mostly Accurate, Incomplete**

**Accurate Models:**
- ✅ AppSpecFileMapping: Correct structure
- ✅ AppSpecHook: Correct lifecycle events
- ✅ InstanceTarget: Appropriate fields
- ✅ LifecycleEvent: Correct structure

**Incomplete Models:**

**RevisionLocation** - Missing fields:
- `version`: S3 version ID for versioned buckets
- `etag`: ETag for revision verification

**BlueGreenConfig** - Critical missing fields:
- `deployment_style`: WITH_TRAFFIC_CONTROL or WITHOUT_TRAFFIC_CONTROL
- `green_fleet_provisioning_option`: COPY_AUTO_SCALING_GROUP or DISCOVER_EXISTING
- `blue_instance_termination_option`: TERMINATE or KEEP_ALIVE

**DeploymentStatus** - Issues:
- "Baking" is not a standard CodeDeploy status (should be removed)
- Missing `deployment_overview` field for instance counts by status

**InstanceTarget** - Missing:
- `instance_id`: EC2 instance identifier

**Verdict:** Data models are structurally sound but missing critical fields required for full blue-green deployment configuration.

---

### 4. Are error scenarios identified with appropriate handling strategies?

**Assessment: ✅ Good Coverage, Some Gaps**

**Covered:** 12 error scenarios with appropriate learner actions
- Application/deployment group existence errors ✅
- Invalid configuration errors ✅
- Revision errors ✅
- Lifecycle hook failures ✅

**Missing Critical Errors:**
1. **InvalidIamSessionArnException**: Service role lacks permissions
2. **InstanceNotRegisteredException**: CodeDeploy agent not communicating
3. **InvalidTargetGroupPairException**: Target group/ALB mismatch
4. **ThrottlingException**: API rate limits
5. **ResourceNotFoundException**: Referenced resources don't exist
6. **InvalidEC2TagException**: Tag filters don't match instances

**Strategy Gaps:**
- No retry logic for transient failures
- No logging strategy specification
- Missing CloudWatch Logs integration guidance

**Verdict:** Good error coverage for common scenarios, but missing critical operational errors and recovery strategies.

---

### 5. Can a developer actually implement this design in a reasonable time?

**Assessment: ⚠️ Implementable with Challenges**

**Estimated Implementation Time: 16-24 hours** (experienced developer)

**Component Breakdown:**
- IAMSetup: 2-3 hours ✅
- InfraManager: 5-6 hours ⚠️ (ALB + ASG complexity)
- RevisionManager: 2-3 hours ✅
- DeploymentManager: 4-5 hours ⚠️ (blue-green config complexity)
- DeploymentMonitor: 3-4 hours ✅

**Implementation Challenges:**

1. **User Data Script Complexity**: CodeDeploy agent installation requires region-specific S3 URLs - not specified
2. **Timing Dependencies**: No wait conditions specified (ALB active before listener, instances healthy before deployment)
3. **Cleanup Complexity**: Deletion order not specified (must reverse dependency order)
4. **Missing Validation**: No pre-flight checks (agent running, target group health)
5. **Polling Logic**: Timeout, backoff, error handling not specified

**Missing Implementation Details:**
- VPC and subnet selection strategy
- Security group rules (ALB: 80/443, SSH: 22, CodeDeploy: 443 outbound)
- AMI selection criteria
- Region-specific agent installation URLs
- S3 bucket naming and region constraints

**Verdict:** Implementable but requires significant additional specification to avoid implementation pitfalls and ensure learner success.

---

### 6. Does the design follow AWS Well-Architected best practices?

**Assessment: ⚠️ Partial Alignment**

| Pillar | Rating | Key Issues |
|--------|--------|------------|
| Operational Excellence | ⚠️ | No logging strategy, no CloudWatch integration, missing runbook |
| Security | ⚠️ | No S3 encryption, security groups undefined, no VPC endpoints |
| Reliability | ⚠️ | No multi-AZ specification, no deployment alarms, no minimum healthy hosts |
| Performance Efficiency | ✅ | ALB and Auto Scaling configured appropriately |
| Cost Optimization | ⚠️ | No termination timing guidance, no instance sizing recommendations |
| Sustainability | ❌ | Not addressed |

**Verdict:** Design addresses core functionality but lacks Well-Architected alignment in security, reliability, and operational excellence.

---

### 7. Is it a "minimum implementable unit"? Not too broad, not too trivial?

**Assessment: ✅ Yes, Appropriate Scope**

**Not Too Broad:**
- ✅ Limited to EC2 compute platform (excludes Lambda/ECS)
- ✅ Single load balancer type (ALB)
- ✅ Excludes CI/CD pipeline complexity
- ✅ Focused on CodeDeploy, not full DevOps toolchain

**Not Too Trivial:**
- ✅ Requires understanding of multiple AWS services
- ✅ Involves complex orchestration (traffic shifting, rollback)
- ✅ Real-world applicable pattern
- ✅ Demonstrates zero-downtime deployment

**Scope Concerns:**

1. **Traffic Shifting Limitation**: EC2/On-Premises platform only supports AllAtOnce, HalfAtATime, OneAtATime - not true canary or linear shifting (those require Lambda/ECS). This limits learning value.

2. **Missing Prerequisites**: Assumes VPC, subnets, security groups exist but doesn't specify creation. Should add prerequisite setup or reference existing infrastructure.

3. **Agent Installation Complexity**: User data installation is error-prone. Consider pre-baked AMI or detailed script.

**Verdict:** Appropriate minimum implementable unit with focused learning objective, but traffic shifting limitations and missing prerequisites should be addressed.

---

## Overall Assessment Summary

| Criterion | Rating | Key Issue |
|-----------|--------|-----------|
| Architecture Diagram | ⚠️ Partial | Missing VPC, security groups, networking |
| Component Interfaces | ✅ Good | Minor refinements needed |
| Data Models | ⚠️ Incomplete | BlueGreenConfig missing critical fields |
| Error Handling | ✅ Good | Missing operational errors |
| Implementability | ⚠️ Challenging | Needs more implementation detail |
| Well-Architected | ⚠️ Gaps | Security, reliability, ops excellence |
| Scope | ✅ Appropriate | Traffic shifting limitations noted |

**Overall Recommendation:** The design is fundamentally sound but requires Priority 1 and Priority 2 enhancements before implementation to ensure learner success and production readiness.

---

## Priority 1: Critical Fixes and Enhancements

### 1. Complete BlueGreenConfig Data Model

**Current (Incomplete):**
```python
TYPE BlueGreenConfig:
    app_name: string
    group_name: string
    service_role_arn: string
    asg_name: string
    target_group_name: string
    auto_rollback_enabled: boolean
    termination_wait_minutes: integer
```

**Enhanced (Complete):**
```python
TYPE BlueGreenConfig:
    app_name: string
    group_name: string
    service_role_arn: string
    asg_name: string
    target_group_name: string
    
    # Deployment style configuration
    deployment_type: string  # 'BLUE_GREEN' or 'IN_PLACE'
    deployment_option: string  # 'WITH_TRAFFIC_CONTROL' or 'WITHOUT_TRAFFIC_CONTROL'
    
    # Green fleet provisioning
    green_fleet_provisioning_action: string  # 'COPY_AUTO_SCALING_GROUP' or 'DISCOVER_EXISTING'
    
    # Blue instance termination
    blue_instance_termination_action: string  # 'TERMINATE' or 'KEEP_ALIVE'
    termination_wait_minutes: integer  # 0-2880 (48 hours max)
    
    # Rollback configuration
    auto_rollback_enabled: boolean
    rollback_on_deployment_failure: boolean
    rollback_on_deployment_stop: boolean
    rollback_on_alarm_threshold: boolean
    alarm_configuration: Optional[AlarmConfiguration]

TYPE AlarmConfiguration:
    enabled: boolean
    alarm_names: List[string]  # CloudWatch alarm names
    ignore_poll_alarm_failure: boolean
```

### 2. Add NetworkSetup Component

**New Component Interface:**
```python
INTERFACE NetworkSetup:
    FUNCTION create_vpc(
        vpc_name: string,
        cidr_block: string = '10.0.0.0/16'
    ) -> string
        """Creates VPC for CodeDeploy infrastructure.
        
        Returns: VPC ID
        """
    
    FUNCTION create_subnets(
        vpc_id: string,
        availability_zones: List[string],
        public_cidr_blocks: List[string],
        private_cidr_blocks: List[string]
    ) -> Tuple[List[string], List[string]]
        """Creates public and private subnets across multiple AZs.
        
        Returns: (public_subnet_ids, private_subnet_ids)
        """
    
    FUNCTION create_internet_gateway(vpc_id: string) -> string
        """Creates and attaches internet gateway to VPC.
        
        Returns: Internet gateway ID
        """
    
    FUNCTION create_security_groups(
        vpc_id: string
    ) -> Tuple[string, string]
        """Creates security groups for ALB and EC2 instances.
        
        ALB Security Group Rules:
        - Inbound: 80 (HTTP) from [IP_ADDRESS]
        - Inbound: 443 (HTTPS) from [IP_ADDRESS]
        - Outbound: All traffic
        
        EC2 Security Group Rules:
        - Inbound: 80 from ALB security group
        - Inbound: 443 from ALB security group
        - Inbound: 22 (SSH) from your IP (for debugging)
        - Outbound: 443 to [IP_ADDRESS] (CodeDeploy agent communication)
        
        Returns: (alb_security_group_id, ec2_security_group_id)
        """
    
    FUNCTION delete_network_infrastructure(
        vpc_id: string,
        subnet_ids: List[string],
        igw_id: string,
        security_group_ids: List[string]
    ) -> None
        """Deletes network infrastructure in correct dependency order."""
```

**Sample Implementation - Create Security Groups:**
```python
def create_security_groups(self, vpc_id: str) -> Tuple[str, str]:
    """Create security groups for ALB and EC2 instances."""
    ec2 = boto3.client('ec2')
    
    # Create ALB security group
    alb_sg_response = ec2.create_security_group(
        GroupName='codedeploy-alb-sg',
        Description='Security group for Application Load Balancer',
        VpcId=vpc_id
    )
    alb_sg_id = alb_sg_response['GroupId']
    
    # ALB inbound rules
    ec2.authorize_security_group_ingress(
        GroupId=alb_sg_id,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': 80,
                'ToPort': 80,
                'IpRanges': [{'CidrIp': '[IP_ADDRESS]', 'Description': 'HTTP from internet'}]
            },
            {
                'IpProtocol': 'tcp',
                'FromPort': 443,
                'ToPort': 443,
                'IpRanges': [{'CidrIp': '[IP_ADDRESS]', 'Description': 'HTTPS from internet'}]
            }
        ]
    )
    
    # Create EC2 security group
    ec2_sg_response = ec2.create_security_group(
        GroupName='codedeploy-ec2-sg',
        Description='Security group for EC2 instances',
        VpcId=vpc_id
    )
    ec2_sg_id = ec2_sg_response['GroupId']
    
    # EC2 inbound rules
    ec2.authorize_security_group_ingress(
        GroupId=ec2_sg_id,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': 80,
                'ToPort': 80,
                'UserIdGroupPairs': [{'GroupId': alb_sg_id, 'Description': 'HTTP from ALB'}]
            },
            {
                'IpProtocol': 'tcp',
                'FromPort': 443,
                'ToPort': 443,
                'UserIdGroupPairs': [{'GroupId': alb_sg_id, 'Description': 'HTTPS from ALB'}]
            }
        ]
    )
    
    # EC2 outbound rule for CodeDeploy agent
    ec2.authorize_security_group_egress(
        GroupId=ec2_sg_id,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': 443,
                'ToPort': 443,
                'IpRanges': [{'CidrIp': '[IP_ADDRESS]', 'Description': 'HTTPS for CodeDeploy agent'}]
            }
        ]
    )
    
    return alb_sg_id, ec2_sg_id
```

### 3. CodeDeploy Agent Installation User Data Script

**Complete User Data Script (Region-Aware):**
```bash
#!/bin/bash
set -e

# Determine region from instance metadata
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Update system packages
yum update -y

# Install Ruby (required for CodeDeploy agent)
yum install -y ruby wget

# Download CodeDeploy agent installer from region-specific bucket
cd /home/ec2-user
wget https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install

# Make installer executable
chmod +x ./install

# Install CodeDeploy agent
./install auto

# Verify agent is running
if sudo service codedeploy-agent status | grep -q "running"; then
    echo "CodeDeploy agent installed and running successfully"
else
    echo "ERROR: CodeDeploy agent failed to start"
    exit 1
fi

# Configure agent to start on boot
sudo systemctl enable codedeploy-agent

# Install sample web server for testing
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create health check endpoint
echo "OK" > /var/www/html/health

# Log installation completion
echo "Instance setup completed at $(date)" >> /var/log/user-data.log
```

**Python Function to Generate Base64-Encoded User Data:**
```python
import base64

def generate_user_data_script(region: str) -> str:
    """Generate base64-encoded user data script for CodeDeploy agent installation."""
    
    script = f"""#!/bin/bash
set -e

# Use specified region
REGION={region}

# Update system packages
yum update -y

# Install Ruby (required for CodeDeploy agent)
yum install -y ruby wget

# Download CodeDeploy agent installer
cd /home/ec2-user
wget https://aws-codedeploy-${{REGION}}.s3.${{REGION}}.amazonaws.com/latest/install

# Install CodeDeploy agent
chmod +x ./install
./install auto

# Verify agent is running
if sudo service codedeploy-agent status | grep -q "running"; then
    echo "CodeDeploy agent installed successfully"
else
    echo "ERROR: CodeDeploy agent failed to start"
    exit 1
fi

# Enable agent on boot
sudo systemctl enable codedeploy-agent

# Install web server
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "OK" > /var/www/html/health

echo "Setup completed at $(date)" >> /var/log/user-data.log
"""
    
    # Base64 encode for boto3
    encoded = base64.b64encode(script.encode('utf-8')).decode('utf-8')
    return encoded
```

### 4. Wait Conditions and Validation Functions

**InfraManager - Wait for Healthy Instances:**
```python
def wait_for_healthy_instances(
    self,
    target_group_arn: str,
    expected_count: int,
    timeout_seconds: int = 300
) -> bool:
    """Wait for instances to pass target group health checks."""
    import time
    
    elbv2 = boto3.client('elbv2')
    start_time = time.time()
    poll_interval = 10
    
    while time.time() - start_time < timeout_seconds:
        try:
            response = elbv2.describe_target_health(
                TargetGroupArn=target_group_arn
            )
            
            healthy_count = sum(
                1 for target in response['TargetHealthDescriptions']
                if target['TargetHealth']['State'] == 'healthy'
            )
            
            print(f"Healthy instances: {healthy_count}/{expected_count}")
            
            if healthy_count >= expected_count:
                print(f"All {expected_count} instances are healthy")
                return True
            
            time.sleep(poll_interval)
            
        except ClientError as e:
            print(f"Error checking target health: {e}")
            time.sleep(poll_interval)
    
    print(f"Timeout: Only {healthy_count}/{expected_count} instances healthy after {timeout_seconds}s")
    return False
```

**DeploymentMonitor - Wait for Deployment with Exponential Backoff:**
```python
def wait_for_deployment(
    self,
    deployment_id: str,
    timeout_seconds: int = 1800,
    initial_poll_interval: int = 10
) -> str:
    """Wait for deployment to complete with exponential backoff."""
    import time
    
    codedeploy = boto3.client('codedeploy')
    start_time = time.time()
    poll_interval = initial_poll_interval
    max_poll_interval = 60
    
    while time.time() - start_time < timeout_seconds:
        try:
            response = codedeploy.get_deployment(
                deploymentId=deployment_id
            )
            
            status = response['deploymentInfo']['status']
            print(f"Deployment status: {status}")
            
            # Terminal states
            if status in ['Succeeded', 'Failed', 'Stopped']:
                return status
            
            # Wait before next poll
            time.sleep(poll_interval)
            
            # Exponential backoff (cap at max_poll_interval)
            poll_interval = min(poll_interval * 1.5, max_poll_interval)
            
        except ClientError as e:
            print(f"Error checking deployment status: {e}")
            time.sleep(poll_interval)
    
    print(f"Timeout: Deployment did not complete within {timeout_seconds}s")
    return 'Timeout'
```

**RevisionManager - Validate AppSpec Before Bundling:**
```python
def validate_appspec(self, appspec_content: str) -> Tuple[bool, List[str]]:
    """Validate AppSpec YAML structure and required sections."""
    import yaml
    
    errors = []
    
    try:
        appspec = yaml.safe_load(appspec_content)
    except yaml.YAMLError as e:
        return False, [f"Invalid YAML syntax: {e}"]
    
    # Check required sections
    if 'version' not in appspec:
        errors.append("Missing required 'version' field")
    elif appspec['version'] != 0.0:
        errors.append("Version must be 0.0")
    
    if 'os' not in appspec:
        errors.append("Missing required 'os' field")
    elif appspec['os'] not in ['linux', 'windows']:
        errors.append("OS must be 'linux' or 'windows'")
    
    if 'files' not in appspec:
        errors.append("Missing required 'files' section")
    else:
        for idx, file_mapping in enumerate(appspec['files']):
            if 'source' not in file_mapping:
                errors.append(f"File mapping {idx}: missing 'source'")
            if 'destination' not in file_mapping:
                errors.append(f"File mapping {idx}: missing 'destination'")
            elif not file_mapping['destination'].startswith('/'):
                errors.append(f"File mapping {idx}: destination must be absolute path")
    
    # Validate hooks
    valid_hooks = {
        'ApplicationStop', 'BeforeInstall', 'AfterInstall',
        'ApplicationStart', 'ValidateService'
    }
    
    if 'hooks' in appspec:
        for hook_name, hook_list in appspec['hooks'].items():
            if hook_name not in valid_hooks:
                errors.append(f"Invalid hook name: {hook_name}. Valid: {valid_hooks}")
            
            for idx, hook in enumerate(hook_list):
                if 'location' not in hook:
                    errors.append(f"Hook {hook_name}[{idx}]: missing 'location'")
                
                if 'timeout' in hook:
                    if not isinstance(hook['timeout'], int):
                        errors.append(f"Hook {hook_name}[{idx}]: timeout must be integer")
                    elif hook['timeout'] < 1 or hook['timeout'] > 3600:
                        errors.append(f"Hook {hook_name}[{idx}]: timeout must be 1-3600 seconds")
    
    return len(errors) == 0, errors
```

### 5. Sample AppSpec File with Lifecycle Hooks

**Complete AppSpec Example:**
```yaml
version: 0.0
os: linux

files:
  - source: /src
    destination: /var/www/html
  - source: /config/app.conf
    destination: /etc/myapp/app.conf

permissions:
  - object: /var/www/html
    owner: apache
    group: apache
    mode: 755
    type:
      - directory
  - object: /var/www/html/*
    owner: apache
    group: apache
    mode: 644
    type:
      - file

hooks:
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 60
      runas: root
  
  BeforeInstall:
    - location: scripts/install_dependencies.sh
      timeout: 300
      runas: root
  
  AfterInstall:
    - location: scripts/configure_app.sh
      timeout: 180
      runas: root
    - location: scripts/set_permissions.sh
      timeout: 60
      runas: root
  
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 120
      runas: root
  
  ValidateService:
    - location: scripts/validate.sh
      timeout: 60
      runas: root
```

**Sample Validation Script (scripts/validate.sh):**
```bash
#!/bin/bash

# Validate web server is running
if ! systemctl is-active --quiet httpd; then
    echo "ERROR: httpd service is not running"
    exit 1
fi

# Validate health endpoint responds
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
if [ "$HEALTH_CHECK" != "200" ]; then
    echo "ERROR: Health check failed with status $HEALTH_CHECK"
    exit 1
fi

# Validate application responds
APP_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$APP_CHECK" != "200" ]; then
    echo "ERROR: Application check failed with status $APP_CHECK"
    exit 1
fi

echo "Validation successful: All checks passed"
exit 0
```

---

## Priority 2: Implementation Support

### 1. Enhanced Architecture Diagram

**Recommended Complete Diagram:**
```mermaid
flowchart TB
    subgraph Scripts["Python Scripts (boto3)"]
        NET[NetworkSetup]
        IAM[IAMSetup]
        INFRA[InfraManager]
        REV[RevisionManager]
        DEP[DeploymentManager]
        MON[DeploymentMonitor]
    end
    
    subgraph VPC["VPC (10.0.0.0/16)"]
        IGW[Internet Gateway]
        
        subgraph PublicSubnets["Public Subnets (Multi-AZ)"]
            ALB[Application Load Balancer]
            SG_ALB[SG: ALB<br/>In: 80,443 from [IP_ADDRESS]]
        end
        
        subgraph PrivateSubnets["Private Subnets (Multi-AZ)"]
            subgraph ASG["Auto Scaling Group"]
                EC2A["EC2 Instance<br/>+ CodeDeploy Agent"]
                EC2B["EC2 Instance<br/>+ CodeDeploy Agent"]
            end
            SG_EC2[SG: EC2<br/>In: 80,443 from ALB<br/>Out: 443 to Internet]
        end
        
        TG[Target Group<br/>Health: /health]
    end
    
    subgraph AWS["AWS Services"]
        IAMSVC[IAM<br/>Service Role + Instance Profile]
        S3[Amazon S3<br/>Revision Bucket]
        CD[AWS CodeDeploy<br/>Application + Deployment Group]
    end
    
    NET -->|1. Create VPC & Subnets| VPC
    NET -->|2. Create IGW| IGW
    NET -->|3. Create Security Groups| SG_ALB
    NET -->|3. Create Security Groups| SG_EC2
    
    IAM -->|4. Create Roles| IAMSVC
    
    INFRA -->|5. Create ALB| ALB
    INFRA -->|6. Create Target Group| TG
    INFRA -->|7. Create ASG| ASG
    
    REV -->|8. Upload Revision| S3
    
    DEP -->|9. Create Application| CD
    DEP -->|10. Create Deployment Group| CD
    DEP -->|11. Trigger Deployment| CD
    
    MON -->|12. Monitor Status| CD
    
    ALB -->|Forward Traffic| TG
    TG -->|Route to| EC2A
    TG -->|Route to| EC2B
    
    CD -->|Manage Traffic| ALB
    CD -->|Deploy Application| EC2A
    CD -->|Deploy Application| EC2B
    
    EC2A -->|Pull Revision| S3
    EC2B -->|Pull Revision| S3
    
    EC2A -->|Agent Communication| IGW
    EC2B -->|Agent Communication| IGW
    IGW -->|HTTPS| CD
    
    IAMSVC -.->|Instance Profile| EC2A
    IAMSVC -.->|Instance Profile| EC2B
    IAMSVC -.->|Service Role| CD
```

### 2. Complete Data Models

**Enhanced RevisionLocation:**
```python
TYPE RevisionLocation:
    revision_type: string       # 'S3' or 'GitHub'
    bucket: string              # S3 bucket name
    key: string                 # S3 object key
    bundle_type: string         # 'zip', 'tar', or 'tgz'
    version: Optional[string]   # S3 version ID (if versioning enabled)
    etag: Optional[string]      # S3 ETag for verification
```

**Enhanced InstanceTarget:**
```python
TYPE InstanceTarget:
    deployment_id: string
    target_id: string           # CodeDeploy target identifier
    instance_id: string         # EC2 instance ID
    target_arn: string          # Instance ARN
    status: string              # 'Pending', 'InProgress', 'Succeeded', 'Failed', 'Skipped'
    last_updated_at: datetime
    lifecycle_events: List[LifecycleEvent]
```

**Enhanced DeploymentStatus:**
```python
TYPE DeploymentStatus:
    deployment_id: string
    application_name: string
    deployment_group_name: string
    status: string              # 'Created', 'Queued', 'InProgress', 'Succeeded', 'Failed', 'Stopped', 'Ready'
    deployment_config_name: string
    revision: RevisionLocation
    create_time: datetime
    start_time: Optional[datetime]
    complete_time: Optional[datetime]
    deployment_overview: DeploymentOverview
    rollback_info: Optional[RollbackInfo]
    error_information: Optional[ErrorInformat