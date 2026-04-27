# Task 1: Prerequisites - Environment Setup — Conversation History

## Mini Lecture

Before writing any code, we set up the workspace — like a chef preparing their kitchen before cooking. We covered:

- **AWS credentials** as your "permission slip" to use Amazon's cloud
- **Tools** (AWS CLI, Python, boto3) as the screwdriver, Allen key, etc.
- **VPC/subnets/security groups** as the "rooms" and "doors" inside AWS's cloud network
- **Project folders** as organized workspace to keep everything tidy

Game plan: Check AWS credentials → Verify tools installed → Discover network resources → Create project folders

---

## Subtask 1.1: AWS Account and Credentials

**Action:** Ran `aws sts get-caller-identity`

**Result:** Verified successfully.
- Account: `628326705801`
- User: `alain-is` with AdministratorAccess

---

## Subtask 1.2: Required Tools and SDKs

**Action:** Verified installed tools.

**Results:**
- AWS CLI: v1.38.38 ✅
- Python: 3.12.11 ✅
- boto3: 1.26.0 ✅

---

## Subtask 1.3: AWS Region and Resource Configuration

**Action:** Discovered default VPC, subnets, and created a security group (with user confirmation).

**Results:**
- Region: `us-east-1`
- Default VPC: `vpc-dd1d2ea7`
- Subnets:
  - `subnet-db0eb996` (us-east-1a, 172.31.16.0/20)
  - `subnet-0b4dad54` (us-east-1b, 172.31.32.0/20)
- Security Group: `BlueGreenDemoSG` (`sg-0b3c48c4a7116fefc`) — HTTP port 80 inbound, all outbound
- All resource IDs saved to `blue-green-deploy/config.json`

---

## Subtask 1.4: Create Project Structure

**Action:** Created directories and stub files.

**Result:**
```
blue-green-deploy/
├── components/
│   ├── iam_setup.py
│   ├── infra_manager.py
│   ├── revision_manager.py
│   ├── deployment_manager.py
│   └── deployment_monitor.py
├── app-source/
│   └── scripts/
└── config.json
```

---

## Summary

All 4 subtasks completed. Environment is ready with verified AWS access, tools, discovered network resources (VPC, 2 subnets across AZs, security group), and the project skeleton with all five component stubs.
