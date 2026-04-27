
# AWS CodeDeploy Blue-Green Deployment Tasks Analysis and Recommendations

**Document Version:** 1.0  
**Analysis Date:** April 10, 2026  
**Reviewed By:** Senior Technical Curriculum Developer  
**Project:** AWS CodeDeploy Blue-Green Deployment Learning Module

---

## Executive Summary: Review Questions Assessment

### 1. Are tasks in a logical sequence? Do prerequisites come first?

**Assessment: ✅ Yes, Excellent Sequencing**

The task flow follows a clear dependency chain with no circular dependencies:

1. **Prerequisites (Task 1)** → Environment setup, tools, AWS configuration
2. **IAM Foundation (Task 2)** → Roles and profiles needed by all other resources
3. **Infrastructure (Task 3)** → ALB, ASG, EC2 instances
4. **Checkpoint (Task 4)** → Validate infrastructure before proceeding
5. **Application Revision (Task 5)** → AppSpec and S3 upload
6. **CodeDeploy Configuration (Task 6)** → Application and deployment group
7. **Checkpoint (Task 7)** → Validate CodeDeploy setup
8. **Deployment Execution (Task 8)** → First deployment with monitoring
9. **Advanced Scenarios (Task 9)** → Traffic shifting strategies and rollback
10. **Checkpoint (Task 10)** → End-to-end validation
11. **Cleanup (Task 11)** → Resource teardown

**Dependency Flow:** Each task builds on previous tasks. Prerequisites are properly positioned at the start. IAM roles must exist before infrastructure, infrastructure must be healthy before CodeDeploy configuration, and revisions must be uploaded before deployments.

**Verdict:** Task sequencing is logical and follows proper dependency order.

---

### 2. Are tasks appropriately sized? Not too big (unclear), not too small (trivial)?

**Assessment: ⚠️ Mixed - Some Tasks Too Large**

**Well-Sized Tasks:**
- Task 2.1 (CodeDeploy Service Role): Single focused objective ✅
- Task 5.2 (S3 Upload): Clear scope ✅
- Task 6.1 (Create Application): Simple, focused ✅
- Task 8.1 (Trigger Deployment): Single action ✅

**Oversized Tasks Requiring Split:**

| Task | Issue | Recommendation |
|------|-------|----------------|
| **Task 3.2** | Combines 4 activities: launch template, user data script, web server install, ASG creation | Split into Task 3.2 (Launch Template) and Task 3.3 (Auto Scaling Group) |
| **Task 5.1** | Combines AppSpec generation, 3 shell scripts, and bundling | Split into Task 5.1 (AppSpec Generation) and Task 5.2 (Hook Scripts and Bundle) |
| **Task 9.1** | Combines new revision creation, HalfAtATime test, linear test, termination config | Split into Task 9.1 (HalfAtATime) and Task 9.2 (OneAtATime) |

**Undersized Tasks:**
- None identified - all tasks have sufficient substance

**Verdict:** Most tasks are appropriately sized, but 3 tasks need splitting to improve clarity and reduce cognitive load.

---

### 3. Does each task reference back to requirements?

**Assessment: ✅ Yes, Comprehensive Traceability**

Every task includes `_Requirements: X.X, X.X_` references linking back to the requirements document.

**Coverage Analysis:**
- ✅ All 8 requirements from the requirements document are referenced
- ✅ Multiple tasks map to each requirement (appropriate for complex requirements)
- ✅ Bidirectional traceability is possible (requirement → tasks, task → requirements)

**Examples:**
- Task 2.1 references Requirements 1.1, 1.2 (IAM setup)
- Task 3.2 references Requirements 2.1, 2.3, 2.4, 3.1, 3.2, 3.3 (Infrastructure)
- Task 8.2 references Requirements 6.2, 6.3, 6.4, 7.4, 3.3 (Monitoring)

**Verdict:** Excellent requirement traceability throughout all tasks.

---

### 4. Are Prerequisites, Checkpoint, and Cleanup tasks included?

**Assessment: ✅ Yes, All Present and Well-Structured**

**Prerequisites (Task 1):**
- ✅ 1.1: AWS Account and Credentials
- ✅ 1.2: Required Tools and SDKs (AWS CLI, Python 3.12, boto3)
- ✅ 1.3: AWS Region and Resource Configuration (VPC, subnets, security groups)
- ✅ 1.4: Create Project Structure

**Checkpoints:**
- ✅ **Task 4**: Validate Infrastructure (after infrastructure setup)
  - Verifies ASG instances InService
  - Verifies CodeDeploy agent running
  - Verifies ALB target group health
  - Tests ALB DNS endpoint
  
- ✅ **Task 7**: Validate CodeDeploy Configuration (after CodeDeploy setup)
  - Confirms application exists
  - Confirms deployment group configured correctly
  - Verifies revision accessibility
  
- ✅ **Task 10**: End-to-End Validation (after all deployments)
  - Verifies deployment history
  - Confirms latest version deployed
  - Validates rollback events
  - Checks blue instance handling

**Cleanup (Task 11):**
- ✅ 11.1: Delete CodeDeploy Resources (deployment group, application)
- ✅ 11.2: Delete Infrastructure Resources (ASG, launch template, ALB, target group)
- ✅ 11.3: Delete S3 and IAM Resources (bucket, roles, instance profile)

**Quality Assessment:**
- Each checkpoint includes specific verification commands (AWS CLI)
- Checkpoints validate critical milestones before proceeding
- "Ensure all tests pass, ask the user if questions arise" provides clear guidance
- Cleanup follows proper deletion order (reverse dependency order)
- Includes warning about ongoing costs and CodeDeploy-created ASGs

**Verdict:** Prerequisites, checkpoints, and cleanup are comprehensive and well-structured.

---

### 5. Can a developer follow the tasks step-by-step without ambiguity?

**Assessment: ⚠️ Mostly Clear, Significant Ambiguities**

**Strengths:**
- ✅ Specific AWS CLI commands provided for verification
- ✅ File paths and directory structure specified
- ✅ Function signatures included (e.g., `create_codedeploy_service_role(role_name)`)
- ✅ boto3 client names specified (e.g., `boto3.client('elbv2')`)
- ✅ Concrete examples (e.g., AMI lookup via SSM parameter)

**Critical Ambiguities Identified:**

| Task | Ambiguity | Impact | Recommendation |
|------|-----------|--------|----------------|
| **1.3** | "Identify a VPC" - doesn't specify default vs new | High | Add: "Use default VPC if it has 2+ public subnets across AZs. Otherwise, create new VPC." |
| **1.3** | Security group rules incomplete | High | Provide complete rules: ALB (80/443 from [IP_ADDRESS]), EC2 (80/443 from ALB SG, 443 out to [IP_ADDRESS]) |
| **3.2** | User data script hardcodes us-east-1 | High | Provide region-agnostic script using instance metadata |
| **3.2** | "simple web server (e.g., Apache)" vague | Medium | Specify exact commands: `yum install -y httpd && systemctl start httpd` |
| **5.1** | Hook script content not specified | High | Provide complete script examples |
| **5.1** | "application files" undefined | High | Specify sample HTML page with version number |
| **6.2** | boto3 parameter structure not shown | High | Provide complete code snippet for deployment group creation |
| **9.1** | "HalfAtATime **or** canary" unclear | Medium | Clarify EC2 platform limitations (no true canary/linear) |
| **9.2** | "deliberately failing script" not specified | Medium | Show how to modify validate_service.sh to exit 1 |

**Estimated Developer Experience:**
- **With current specification**: 20-30 hours (frequent blockers due to ambiguities)
- **With enhanced specification**: 12-16 hours (smooth progression)

**Verdict:** Tasks are mostly clear but contain critical ambiguities that will block developer progress without additional specification.

---

### 6. Are the tasks achievable in Kiro IDE? Do they produce a working deliverable?

**Assessment: ⚠️ Partially Achievable, Significant Gaps**

**Achievable in Kiro IDE:**
- ✅ Python script development (all 5 components)
- ✅ boto3 SDK usage
- ✅ AWS CLI commands for verification
- ✅ File creation and directory structure
- ✅ YAML generation for AppSpec
- ✅ Shell script creation

**Challenging in Kiro IDE:**

| Challenge | Impact | Mitigation |
|-----------|--------|------------|
| **VPC/Subnet/Security Group Setup** | High - Tasks assume these exist but don't create them | Add Task 0 with CloudFormation template or boto3 scripts |
| **SSH/SSM Access for Agent Verification** | Medium - Checkpoint requires instance access | Remove SSH requirement, verify via deployment success |
| **Real-Time Monitoring Output** | Low - Polling may not display well | Add logging to file |

**Working Deliverable Assessment:**

**What Works:**
- ✅ All 5 Python components will be functional
- ✅ IAM roles and instance profiles created
- ✅ ALB, target groups, and ASG provisioned
- ✅ CodeDeploy application and deployment group configured
- ✅ Deployments execute and traffic shifts
- ✅ Rollback scenarios demonstrate failure handling

**Critical Gaps Preventing Complete Deliverable:**

1. **Network Infrastructure (High Impact)**
   - Tasks assume VPC, subnets, security groups exist
   - Without proper networking:
     - ALB creation fails (needs 2 subnets in different AZs)
     - EC2 instances lack internet access for CodeDeploy agent
     - Security groups don't allow ALB → EC2 traffic

2. **Application Source Files (High Impact)**
   - Task 5.1 mentions "application files" but doesn't specify content
   - Without sample application:
     - Cannot create meaningful revision
     - `/src` directory referenced in AppSpec doesn't exist
     - No way to verify deployment success

3. **Hook Script Implementation (High Impact)**
   - Task 5.1 lists hook scripts but doesn't provide content
   - Without working scripts:
     - BeforeInstall: What to stop?
     - AfterInstall: What permissions to set?
     - ValidateService: What to validate?

4. **Wait Conditions (Medium Impact)**
   - Tasks mention waiting but don't implement wait logic
   - Without wait functions:
     - Race conditions between resource creation
     - Deployments triggered before infrastructure ready
     - Unclear timeout handling

5. **Error Handling (Medium Impact)**
   - No error handling examples in Python scripts
   - Without error handling:
     - Cryptic boto3 exceptions
     - No recovery guidance
     - Difficult debugging

**Estimated Completion Time in Kiro IDE:**
- **With current specification**: 20-30 hours (due to gaps and ambiguities)
- **With enhanced specification**: 12-16 hours (smooth implementation)

**Verdict:** Tasks are partially achievable but require significant enhancements (network setup, sample application, hook scripts, wait conditions) to produce a working deliverable in Kiro IDE.

---

## Overall Assessment Summary

| Criterion | Rating | Key Issue | Priority |
|-----------|--------|-----------|----------|
| Task Sequencing | ✅ Excellent | None - proper dependency order | N/A |
| Task Sizing | ⚠️ Mixed | 3 tasks oversized, need splitting | P2 |
| Requirements Traceability | ✅ Excellent | None - comprehensive coverage | N/A |
| Prerequisites/Checkpoints/Cleanup | ✅ Excellent | None - all present and well-structured | N/A |
| Step-by-Step Clarity | ⚠️ Ambiguous | Critical gaps in specifications | P1 |
| Kiro IDE Achievability | ⚠️ Partial | Missing network setup, app files, scripts | P1 |

**Overall Recommendation:** Tasks are well-structured with excellent sequencing and traceability, but require Priority 1 enhancements (network infrastructure, sample application, hook scripts) before implementation to ensure learner success in Kiro IDE.

---

## Priority 1: Critical Enhancements for Success

### 1. Add Task 0: Network Infrastructure Setup

**New Task 0: Create Network Infrastructure**

_Requirements: All (prerequisite for infrastructure)_

Create VPC, subnets, internet gateway, and security groups required for blue-green deployment.

**Subtasks:**

**0.1: Create VPC and Subnets**

Implement `NetworkSetup` component with function to create VPC with 2 public subnets across different availability zones.

```python
# components/network_setup.py
import boto3
from typing import List, Tuple

class NetworkSetup:
    def __init__(self, region: str):
        self.ec2 = boto3.client('ec2', region_name=region)
        self.region = region
    
    def create_vpc(self, vpc_name: str, cidr_block: str = '10.0.0.0/16') -> str:
        """Create VPC for CodeDeploy infrastructure."""
        response = self.ec2.create_vpc(
            CidrBlock=cidr_block,
            TagSpecifications=[
                {
                    'ResourceType': 'vpc',
                    'Tags': [{'Key': 'Name', 'Value': vpc_name}]
                }
            ]
        )
        vpc_id = response['Vpc']['VpcId']
        
        # Enable DNS hostnames
        self.ec2.modify_vpc_attribute(
            VpcId=vpc_id,
            EnableDnsHostnames={'Value': True}
        )
        
        print(f"Created VPC: {vpc_id}")
        return vpc_id
    
    def create_subnets(
        self,
        vpc_id: str,
        subnet_name_prefix: str
    ) -> List[str]:
        """Create 2 public subnets across different AZs."""
        # Get available AZs
        azs_response = self.ec2.describe_availability_zones(
            Filters=[{'Name': 'state', 'Values': ['available']}]
        )
        azs = [az['ZoneName'] for az in azs_response['AvailabilityZones'][:2]]
        
        subnet_ids = []
        cidr_blocks = ['10.0.1.0/24', '10.0.2.0/24']
        
        for idx, (az, cidr) in enumerate(zip(azs, cidr_blocks)):
            response = self.ec2.create_subnet(
                VpcId=vpc_id,
                CidrBlock=cidr,
                AvailabilityZone=az,
                TagSpecifications=[
                    {
                        'ResourceType': 'subnet',
                        'Tags': [{'Key': 'Name', 'Value': f'{subnet_name_prefix}-{idx+1}'}]
                    }
                ]
            )
            subnet_id = response['Subnet']['SubnetId']
            
            # Enable auto-assign public IP
            self.ec2.modify_subnet_attribute(
                SubnetId=subnet_id,
                MapPublicIpOnLaunch={'Value': True}
            )
            
            subnet_ids.append(subnet_id)
            print(f"Created subnet {subnet_id} in {az}")
        
        return subnet_ids
    
    def create_internet_gateway(self, vpc_id: str, igw_name: str) -> str:
        """Create and attach internet gateway to VPC."""
        response = self.ec2.create_internet_gateway(
            TagSpecifications=[
                {
                    'ResourceType': 'internet-gateway',
                    'Tags': [{'Key': 'Name', 'Value': igw_name}]
                }
            ]
        )
        igw_id = response['InternetGateway']['InternetGatewayId']
        
        # Attach to VPC
        self.ec2.attach_internet_gateway(
            InternetGatewayId=igw_id,
            VpcId=vpc_id
        )
        
        print(f"Created and attached Internet Gateway: {igw_id}")
        return igw_id
    
    def create_route_table(
        self,
        vpc_id: str,
        igw_id: str,
        subnet_ids: List[str],
        rt_name: str
    ) -> str:
        """Create route table with internet gateway route."""
        response = self.ec2.create_route_table(
            VpcId=vpc_id,
            TagSpecifications=[
                {
                    'ResourceType': 'route-table',
                    'Tags': [{'Key': 'Name', 'Value': rt_name}]
                }
            ]
        )
        rt_id = response['RouteTable']['RouteTableId']
        
        # Add route to internet gateway
        self.ec2.create_route(
            RouteTableId=rt_id,
            DestinationCidrBlock='[IP_ADDRESS]',
            GatewayId=igw_id
        )
        
        # Associate with subnets
        for subnet_id in subnet_ids:
            self.ec2.associate_route_table(
                RouteTableId=rt_id,
                SubnetId=subnet_id
            )
        
        print(f"Created route table {rt_id} with internet gateway route")
        return rt_id
```

**Verification:**
```bash
aws ec2 describe-vpcs --vpc-ids <vpc-id>
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<vpc-id>"
```

**0.2: Create Security Groups**

Implement function to create security groups for ALB and EC2 instances with proper rules.

```python
def create_security_groups(
    self,
    vpc_id: str,
    alb_sg_name: str,
    ec2_sg_name: str
) -> Tuple[str, str]:
    """Create security groups for ALB and EC2 instances."""
    
    # Create ALB security group
    alb_sg_response = self.ec2.create_security_group(
        GroupName=alb_sg_name,
        Description='Security group for Application Load Balancer',
        VpcId=vpc_id,
        TagSpecifications=[
            {
                'ResourceType': 'security-group',
                'Tags': [{'Key': 'Name', 'Value': alb_sg_name}]
            }
        ]
    )
    alb_sg_id = alb_sg_response['GroupId']
    
    # ALB inbound rules (HTTP and HTTPS from internet)
    self.ec2.authorize_security_group_ingress(
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
    
    print(f"Created ALB security group: {alb_sg_id}")
    
    # Create EC2 security group
    ec2_sg_response = self.ec2.create_security_group(
        GroupName=ec2_sg_name,
        Description='Security group for EC2 instances',
        VpcId=vpc_id,
        TagSpecifications=[
            {
                'ResourceType': 'security-group',
                'Tags': [{'Key': 'Name', 'Value': ec2_sg_name}]
            }
        ]
    )
    ec2_sg_id = ec2_sg_response['GroupId']
    
    # EC2 inbound rules (HTTP/HTTPS from ALB only)
    self.ec2.authorize_security_group_ingress(
        GroupId=ec2_sg_id,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': 80,
                'ToPort': 80,
                'UserIdGroupPairs': [
                    {'GroupId': alb_sg_id, 'Description': 'HTTP from ALB'}
                ]
            },
            {
                'IpProtocol': 'tcp',
                'FromPort': 443,
                'ToPort': 443,
                'UserIdGroupPairs': [
                    {'GroupId': alb_sg_id, 'Description': 'HTTPS from ALB'}
                ]
            }
        ]
    )
    
    # EC2 outbound rule (HTTPS for CodeDeploy agent)
    # Note: Default outbound rule allows all traffic, but we'll be explicit
    self.ec2.authorize_security_group_egress(
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
    
    print(f"Created EC2 security group: {ec2_sg_id}")
    
    return alb_sg_id, ec2_sg_id
```

**Verification:**
```bash
aws ec2 describe-security-groups --group-ids <alb-sg-id> <ec2-sg-id>
```

---

### 2. Provide Complete Sample Application

**Application Structure:**

```
app-source/
├── src/
│   └── index.html
└── scripts/
    ├── before_install.sh
    ├── after_install.sh
    └── validate_service.sh
```

**src/index.html:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blue-Green Deployment Demo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3em;
            margin: 0;
        }
        .version {
            font-size: 1.5em;
            margin-top: 20px;
            opacity: 0.9;
        }
        .timestamp {
            font-size: 0.9em;
            margin-top: 10px;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Blue-Green Deployment</h1>
        <div class="version">Version 1.0</div>
        <div class="timestamp">Deployed: <span id="timestamp"></span></div>
    </div>
    <script>
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
```

**For Version 2.0 (Task 9.1), change:**
```html
<div class="version">Version 2.0</div>
```

**For Version 3.0 (Task 9.2 - failing deployment), change:**
```html
<div class="version">Version 3.0 (Will Fail Validation)</div>
```

---

### 3. Provide Complete Hook Scripts

**scripts/before_install.sh:**
```bash
#!/bin/bash
# BeforeInstall: Stop existing web server before installing new version

set -e

echo "Running BeforeInstall hook..."

# Check if httpd is running
if systemctl is-active --quiet httpd; then
    echo "Stopping Apache web server..."
    systemctl stop httpd
    echo "Apache stopped successfully"
else
    echo "Apache is not running, nothing to stop"
fi

# Clean up old application files
if [ -d "/var/www/html" ]; then
    echo "Cleaning up old application files..."
    rm -rf /var/www/html/*
    echo "Cleanup completed"
fi

echo "BeforeInstall hook completed successfully"
exit 0
```

**scripts/after_install.sh:**
```bash
#!/bin/bash
# AfterInstall: Set proper permissions and ownership after files are copied

set -e

echo "Running AfterInstall hook..."

# Set ownership to apache user
echo "Setting ownership to apache:apache..."
chown -R apache:apache /var/www/html

# Set directory permissions
echo "Setting directory permissions..."
find /var/www/html -type d -exec chmod 755 {} \;

# Set file permissions
echo "Setting file permissions..."
find /var/www/html -type f -exec chmod 644 {} \;

# Verify permissions
echo "Verifying permissions..."
ls -la /var/www/html/

echo "AfterInstall hook completed successfully"
exit 0
```

**scripts/validate_service.sh:**
```bash
#!/bin/bash
# ValidateService: Verify the application is running and responding correctly

set -e

echo "Running ValidateService hook..."

# Wait for httpd to be fully started
echo "Waiting for Apache to start..."
sleep 5

# Check if httpd is running
if ! systemctl is-active --quiet httpd; then
    echo "ERROR: Apache is not running"
    exit 1
fi

echo "Apache is running"

# Test localhost connection
echo "Testing localhost connection..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: HTTP request failed with status code $HTTP_CODE"
    exit 1
fi

echo "HTTP request successful (status: $HTTP_CODE)"

# Verify content is accessible
echo "Verifying application content..."
CONTENT=$(curl -s http://localhost/)

if [[ $CONTENT == *"Blue-Green Deployment"* ]]; then
    echo "Application content verified successfully"
else
    echo "ERROR: Application content verification failed"
    exit 1
fi

# Check health endpoint
echo "Checking health endpoint..."
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)

if [ "$HEALTH_CODE" != "200" ]; then
    echo "WARNING: Health endpoint returned status $HEALTH_CODE"
    # Don't fail deployment for health endpoint
fi

echo "ValidateService hook completed successfully"
exit 0
```

**For Task 9.2 (Failing Deployment), modify validate_service.sh:**
```bash
#!/bin/bash
# ValidateService: Deliberately fail for rollback testing

set -e

echo "Running ValidateService hook (WILL FAIL FOR TESTING)..."

# Simulate validation failure
echo "ERROR: Simulated validation failure for rollback testing"
exit 1
```

---

### 4. Region-Agnostic User Data Script

**Complete User Data Script for Task 3.2:**

```bash
#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script at $(date)"

# Get region from instance metadata
echo "Detecting AWS region..."
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
echo "Region detected: $REGION"

# Update system packages
echo "Updating system packages..."
yum update -y

# Install Ruby (required for CodeDeploy agent)
echo "Installing Ruby and wget..."
yum install -y ruby wget

# Download CodeDeploy agent installer from region-specific bucket
echo "Downloading CodeDeploy agent installer..."
cd /home/ec2-user
wget https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install

# Make installer executable
chmod +x ./install

# Install CodeDeploy agent
echo "Installing CodeDeploy agent..."
./install auto

# Wait for agent to start
echo "Waiting for CodeDeploy agent to start..."
sleep 10

# Verify agent is running
if systemctl is-active --quiet codedeploy-agent; then
    echo "CodeDeploy agent installed and running successfully"
else
    echo "ERROR: CodeDeploy agent failed to start"
    systemctl status codedeploy-agent
    exit 1
fi

# Enable agent to start on boot
echo "Enabling CodeDeploy agent on boot..."
systemctl enable codedeploy-agent

# Install Apache web server
echo "Installing Apache web server..."
yum install -y httpd

# Start Apache
echo "Starting Apache..."
systemctl start httpd
systemctl enable httpd

# Create health check endpoint
echo "Creating health check endpoint..."
echo "OK" > /var/www/html/health

# Create default page (will be replaced by deployment)
echo "Creating default page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Initial State</title>
</head>
<body>
    <h1>Initial State - Waiting for Deployment</h1>
    <p>This page will be replaced by the first CodeDeploy deployment.</p>
</body>
</html>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Verify Apache is serving content
echo "Verifying Apache is serving content..."
sleep 5
if curl -s http://localhost/ > /dev/null; then
    echo "Apache is serving content successfully"
else
    echo "WARNING: Apache may not be serving content correctly"
fi

echo "User data script completed successfully at $(date)"
```

**Python Function to Generate Base64-Encoded User Data:**

```python
import base64

def generate_user_data_script(region: str) -> str:
    """Generate base64-encoded user data script for CodeDeploy agent installation.
    
    Args:
        region: AWS region (e.g., 'us-east-1')
    
    Returns:
        Base64-encoded user data script
    """
    
    script = f"""#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user data script at $(date)"

REGION={region}
echo "Region: $REGION"

yum update -y
yum install -y ruby wget

cd /home/ec2-user
wget https://aws-codedeploy-${{REGION}}.s3.${{REGION}}.amazonaws.com/latest/install
chmod +x ./install
./install auto

sleep 10

if systemctl is-activ