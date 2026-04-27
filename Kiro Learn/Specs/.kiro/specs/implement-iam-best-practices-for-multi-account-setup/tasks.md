

# Implementation Plan: IAM Best Practices for Multi-Account Setup

## Overview

This implementation plan guides learners through building a secure multi-account AWS environment using IAM best practices. The work is organized into phases: first establishing the AWS Organizations foundation with organizational units and service control policies, then configuring centralized identity management through IAM Identity Center, followed by implementing cross-account IAM roles with least-privilege policies and permission boundaries, and finally setting up audit logging and credential hygiene practices.

The approach follows a logical dependency chain — Organizations must exist before SCPs can be applied, IAM Identity Center requires an organization, and cross-account roles need member accounts to be in place. Each phase builds on the previous one, with Python boto3 scripts automating provisioning and verification across six modules (OrgManager, SCPManager, IdentityCenterManager, CrossAccountRoleManager, AuditManager, CredentialManager). Checkpoints after major milestones validate that the multi-account architecture is functioning correctly before proceeding.

Key dependencies include: the management account must have Organizations enabled before any other work begins; the Security account and its S3 logging bucket must exist before configuring the organization CloudTrail trail; and cross-account roles in the Workload account must be created before testing role assumption and permission boundaries. The learner will primarily work from the management account, switching context to member accounts through role assumption as needed.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS management account with root or admin-level access
    - Configure AWS CLI: `aws configure` (set access key, secret key, default region)
    - Verify access: `aws sts get-caller-identity`
    - Confirm the account is not already part of an AWS Organization (or plan to use existing): `aws organizations describe-organization 2>&1 || echo "No organization yet"`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3` and verify with `python3 -c "import boto3; print(boto3.__version__)"`
    - Create project directory structure: `mkdir -p components` and create `__init__.py`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure the management account has permissions for: Organizations, IAM, IAM Identity Center (sso-admin, identitystore), CloudTrail, S3, IAM Access Analyzer, STS
    - Prepare email addresses for member accounts (Security account, Workload account) — each AWS account requires a unique email
    - Create a `config.py` file to store account IDs, OU names, and other constants used across modules
    - _Requirements: (all)_

- [ ] 2. AWS Organizations Structure and OrgManager Module
  - [ ] 2.1 Implement OrgManager component
    - Create `components/org_manager.py` with a class implementing all interface functions: `create_organization`, `create_organizational_unit`, `list_organizational_units`, `create_account`, `move_account`, `list_accounts_for_ou`, `get_organization_root_id`
    - Use `boto3.client('organizations')` for all API calls
    - Handle `AlreadyInOrganizationException` and `DuplicateOrganizationalUnitException` gracefully
    - Define the `OrganizationStructure` and `OrgUnit` data models as dataclasses or typed dictionaries
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Create organization and organizational units
    - Call `create_organization(feature_set='ALL')` to enable all features including consolidated billing and policy management
    - Retrieve the root ID with `get_organization_root_id()`
    - Create three OUs under root: `create_organizational_unit(root_id, 'Security')`, `create_organizational_unit(root_id, 'Workloads')`, `create_organizational_unit(root_id, 'Sandbox')`
    - Verify OUs exist: `list_organizational_units(root_id)` and confirm all three appear
    - _Requirements: 1.1, 1.2_
  - [ ] 2.3 Create and organize member accounts
    - Create Security account: `create_account(email='security@example.com', account_name='SecurityAccount')`
    - Create Workload account: `create_account(email='workload@example.com', account_name='WorkloadAccount')`
    - Wait for account creation to complete (poll `describe_create_account_status`)
    - Move Security account to Security OU: `move_account(security_account_id, root_id, security_ou_id)`
    - Move Workload account to Workloads OU: `move_account(workload_account_id, root_id, workloads_ou_id)`
    - Verify placement: `list_accounts_for_ou(security_ou_id)` and `list_accounts_for_ou(workloads_ou_id)`
    - _Requirements: 1.2, 1.3_

- [ ] 3. Service Control Policies and SCPManager Module
  - [ ] 3.1 Implement SCPManager component
    - Create `components/scp_manager.py` with all interface functions: `create_region_restriction_scp`, `create_cloudtrail_protection_scp`, `create_custom_scp`, `attach_policy_to_target`, `detach_policy_from_target`, `list_policies_for_target`, `enable_policy_type`
    - Define the `ServiceControlPolicy` data model
    - Use `boto3.client('organizations')` for all calls
    - Handle `PolicyTypeNotEnabledException` by calling `enable_policy_type(root_id, 'SERVICE_CONTROL_POLICY')` first
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - [ ] 3.2 Create and attach SCPs to organizational units
    - Enable SCP policy type: `enable_policy_type(root_id, 'SERVICE_CONTROL_POLICY')`
    - Create region restriction SCP: `create_region_restriction_scp(allowed_regions=['us-east-1', 'us-west-2'], policy_name='RegionRestriction')` — policy should deny all actions with `StringNotEquals` condition on `aws:RequestedRegion`
    - Create CloudTrail protection SCP: `create_cloudtrail_protection_scp(policy_name='CloudTrailProtection')` — deny `cloudtrail:StopLogging`, `cloudtrail:DeleteTrail`
    - Attach region restriction SCP to Workloads OU: `attach_policy_to_target(region_scp_id, workloads_ou_id)`
    - Attach CloudTrail protection SCP to Workloads OU: `attach_policy_to_target(ct_scp_id, workloads_ou_id)`
    - Verify with `list_policies_for_target(workloads_ou_id)` — both policies should appear
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ]* 3.3 Validate SCP enforcement behavior
    - **Property 1: SCP Intersection and Management Account Exemption**
    - **Validates: Requirements 2.3, 2.4**
    - Assume a role in the Workload account and attempt to create a resource in a denied region — verify `AccessDeniedException`
    - Attempt to stop CloudTrail from the Workload account — verify denial
    - Verify the management account can still perform denied actions (management account is exempt from SCPs)
    - Test that attaching multiple SCPs results in intersection of permissions (action must be allowed by all SCPs)

- [ ] 4. Checkpoint - Validate Organizations and SCP Foundation
  - Verify organization exists with all features: `aws organizations describe-organization`
  - List OUs and confirm Security, Workloads, and Sandbox exist under root
  - Confirm member accounts are in correct OUs: `aws organizations list-accounts-for-parent --parent-id <ou-id>`
  - Verify SCPs are attached: `aws organizations list-policies-for-target --target-id <ou-id> --filter SERVICE_CONTROL_POLICY`
  - Test SCP enforcement from a member account (region restriction and CloudTrail protection)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. IAM Identity Center and IdentityCenterManager Module
  - [ ] 5.1 Implement IdentityCenterManager component
    - Create `components/identity_center_manager.py` with all interface functions: `get_identity_center_instance`, `create_user`, `create_group`, `add_user_to_group`, `create_permission_set`, `assign_permission_set`, `remove_permission_set_assignment`, `configure_mfa_enforcement`
    - Define the `PermissionSetConfig` data model
    - Use `boto3.client('sso-admin')` and `boto3.client('identitystore')` for API calls
    - Handle `ConflictException` for duplicate users/groups
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 6.2_
  - [ ] 5.2 Enable Identity Center and create users, groups, and permission sets
    - Enable IAM Identity Center at the organization level (via console or verify with `get_identity_center_instance()`)
    - Create users: `create_user(identity_store_id, 'admin-user', 'Admin User', 'admin@example.com')` and `create_user(identity_store_id, 'readonly-user', 'ReadOnly User', 'readonly@example.com')`
    - Create groups: `create_group(identity_store_id, 'Administrators')` and `create_group(identity_store_id, 'ReadOnlyUsers')`
    - Add users to appropriate groups: `add_user_to_group(identity_store_id, admin_group_id, admin_user_id)`
    - Create permission sets: `create_permission_set(instance_arn, 'AdministratorAccess', ['arn:aws:iam::aws:policy/AdministratorAccess'], 'PT4H')`, `create_permission_set(instance_arn, 'ReadOnlyAccess', ['arn:aws:iam::aws:policy/ReadOnlyAccess'], 'PT1H')`, and `create_permission_set(instance_arn, 'PowerUserAccess', ['arn:aws:iam::aws:policy/PowerUserAccess'], 'PT2H')`
    - _Requirements: 3.1, 3.2_
  - [ ] 5.3 Assign permission sets and configure MFA enforcement
    - Assign ReadOnly permission set to readonly-user for Workload account: `assign_permission_set(instance_arn, readonly_ps_arn, workload_account_id, readonly_user_id, 'USER')`
    - Assign Administrator permission set to admin group for Security account: `assign_permission_set(instance_arn, admin_ps_arn, security_account_id, admin_group_id, 'GROUP')`
    - Configure MFA enforcement: `configure_mfa_enforcement(instance_arn, 'REQUIRED')` — users must register MFA before accessing accounts
    - Verify assignments by listing account assignments for each permission set
    - Test removing a permission set assignment: `remove_permission_set_assignment(instance_arn, readonly_ps_arn, workload_account_id, readonly_user_id, 'USER')` — user should lose access
    - Re-assign the permission set for subsequent tasks
    - _Requirements: 3.2, 3.3, 3.4, 6.2_

- [ ] 6. Cross-Account Roles, Permission Boundaries, and MFA Enforcement
  - [ ] 6.1 Implement CrossAccountRoleManager component
    - Create `components/cross_account_role_manager.py` with all interface functions: `create_cross_account_role`, `build_trust_policy`, `attach_least_privilege_policy`, `attach_permission_boundary`, `create_permission_boundary_policy`, `assume_role`, `create_mfa_enforcement_policy`
    - Define the `CrossAccountRole` data model
    - Use `boto3.client('iam')` and `boto3.client('sts')` for API calls
    - Handle `EntityAlreadyExistsException`, `MalformedPolicyDocumentException`, and `InvalidIdentityTokenException`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 6.1, 6.3_
  - [ ] 6.2 Create cross-account roles with trust policies and least-privilege permissions
    - Build trust policy with external ID: `build_trust_policy(source_account_id=mgmt_account_id, source_principal_arn='arn:aws:iam::<mgmt>:root', external_id='unique-external-id-123', require_mfa=False)`
    - Create cross-account role in Workload account: `create_cross_account_role(role_name='CrossAccountS3Reader', trust_policy=trust_policy, max_session_duration=3600)`
    - Attach least-privilege inline policy granting only `s3:GetObject` and `s3:ListBucket` on specific resources: `attach_least_privilege_policy('CrossAccountS3Reader', 'S3ReadPolicy', policy_document)`
    - Build a second trust policy with MFA requirement: `build_trust_policy(source_account_id=mgmt_account_id, source_principal_arn='arn:aws:iam::<mgmt>:root', external_id=None, require_mfa=True)`
    - Create MFA-required role: `create_cross_account_role(role_name='CrossAccountAdmin', trust_policy=mfa_trust_policy, max_session_duration=7200)`
    - Create MFA enforcement policy for sensitive actions: `create_mfa_enforcement_policy('MFARequired', ['iam:*', 's3:DeleteBucket'])`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 6.1, 6.3_
  - [ ] 6.3 Implement permission boundaries for delegated administration
    - Create permission boundary policy that excludes IAM administrative actions: `create_permission_boundary_policy('DelegatedAdminBoundary', boundary_doc)` — deny `iam:CreateRole`, `iam:DeleteRole`, `iam:PutRolePermissionsBoundary`, `iam:AttachRolePolicy` without boundary condition
    - Attach permission boundary to a delegated admin role: `attach_permission_boundary('CrossAccountAdmin', boundary_policy_arn)`
    - Verify effective permissions are the intersection of identity policy and boundary
    - Test that the bounded role cannot modify its own permission boundary
    - Test that the bounded role cannot create new roles without boundaries
    - _Requirements: 5.1, 5.2, 5.3_
  - [ ] 6.4 Test role assumption and verify security controls
    - Assume cross-account role with external ID: `assume_role(role_arn='arn:aws:iam::<workload>:role/CrossAccountS3Reader', session_name='test-session', external_id='unique-external-id-123')` — verify temporary credentials returned
    - Verify assumption fails without correct external ID
    - Verify temporary credentials expire after configured `max_session_duration`
    - Attempt to assume MFA-required role without MFA — verify failure
    - Verify assumed role can only perform allowed actions (S3 read) and is denied other actions
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 6.3_

- [ ] 7. Checkpoint - Validate Cross-Account Access and Identity Center
  - Verify IAM Identity Center instance is active: `aws sso-admin list-instances`
  - List permission sets and confirm ReadOnly, Administrator, PowerUser exist
  - Verify permission set assignments for member accounts
  - Test cross-account role assumption with external ID from management account
  - Verify permission boundary restricts delegated admin role from IAM escalation
  - Confirm MFA enforcement is configured in Identity Center
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. CloudTrail Audit Logging and AuditManager Module
  - [ ] 8.1 Implement AuditManager component
    - Create `components/audit_manager.py` with all interface functions: `create_logging_bucket`, `create_organization_trail`, `start_logging`, `create_access_analyzer`, `list_access_analyzer_findings`, `lookup_cross_account_events`
    - Define the `AccessAnalyzerFinding` data model
    - Use `boto3.client('cloudtrail')`, `boto3.client('s3')`, and `boto3.client('accessanalyzer')` for API calls
    - Handle `BucketAlreadyExistsException` and `InsufficientS3BucketPolicyException`
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ] 8.2 Create centralized logging bucket and organization trail
    - Create S3 logging bucket in Security account: `create_logging_bucket(bucket_name='org-cloudtrail-logs-<account-id>', organization_id=org_id)` — configure bucket policy to allow `cloudtrail.amazonaws.com` to deliver logs from all organization accounts
    - Create organization trail from management account: `create_organization_trail(trail_name='OrgTrail', bucket_name='org-cloudtrail-logs-<account-id>')` — set `IsOrganizationTrail=True` and `IsMultiRegionTrail=True`
    - Start logging: `start_logging(trail_name='OrgTrail')`
    - Verify trail captures events from all member accounts
    - _Requirements: 7.1, 7.2_
  - [ ] 8.3 Configure IAM Access Analyzer and verify cross-account event logging
    - Create IAM Access Analyzer at organization level: `create_access_analyzer(analyzer_name='OrgAnalyzer', analyzer_type='ORGANIZATION')`
    - List findings: `list_access_analyzer_findings(analyzer_arn)` — identify any IAM roles or resource policies granting external access
    - Perform a cross-account role assumption to generate a CloudTrail event
    - Query CloudTrail for role assumption events: `lookup_cross_account_events('OrgTrail', start_time, end_time)` — verify the log entry contains assuming principal, assumed role ARN, role session name, and source account
    - _Requirements: 7.3, 7.4_

- [ ] 9. Credential Management and CredentialManager Module
  - [ ] 9.1 Implement CredentialManager component
    - Create `components/credential_manager.py` with all interface functions: `generate_credential_report`, `parse_credential_report`, `find_stale_access_keys`, `deactivate_access_key`, `delete_access_key`, `check_root_user_security`, `list_users_without_mfa`
    - Define the `CredentialReportEntry` data model
    - Use `boto3.client('iam')` for all calls
    - Handle `CredentialReportNotReadyException` with retry logic (wait and poll)
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  - [ ] 9.2 Generate credential reports and audit access key hygiene
    - Generate credential report: `generate_credential_report()` — wait for report to be ready
    - Parse the report: `parse_credential_report()` — extract all users with access key status, age, last usage, and MFA enrollment
    - Find stale access keys: `find_stale_access_keys(max_age_days=90)` — list keys older than 90 days or never used
    - Deactivate an unused key: `deactivate_access_key(user_name, access_key_id)` (use a test IAM user key)
    - Delete a deactivated key: `delete_access_key(user_name, access_key_id)`
    - _Requirements: 8.2, 8.3_
  - [ ] 9.3 Verify root user security and MFA enrollment
    - Check root user security: `check_root_user_security()` — verify MFA is enabled and no active access keys exist for root
    - List users without MFA: `list_users_without_mfa()` — identify IAM users lacking MFA devices
    - Verify workloads use IAM roles with temporary credentials rather than long-term access keys (document the pattern using the cross-account role created earlier as the example)
    - _Requirements: 8.1, 8.4_

- [ ] 10. Checkpoint - Validate Audit and Credential Management
  - Verify organization trail is logging: `aws cloudtrail get-trail-status --name OrgTrail`
  - Confirm logs are delivered to centralized S3 bucket: `aws s3 ls s3://org-cloudtrail-logs-<account-id>/AWSLogs/`
  - Verify IAM Access Analyzer is active and review findings
  - Run credential report and confirm it includes all IAM users with key status and MFA info
  - Verify root user has MFA enabled and no active access keys
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Remove IAM Identity Center assignments and permission sets
    - Remove all permission set assignments: `aws sso-admin delete-account-assignment` for each user/group-account-permission set combination
    - Delete permission sets: `aws sso-admin delete-permission-set --instance-arn <arn> --permission-set-arn <arn>` for each permission set
    - Delete Identity Center users and groups (via identitystore API)
    - _Requirements: (all)_
  - [ ] 11.2 Delete IAM roles, policies, and CloudTrail resources
    - Delete cross-account IAM roles in Workload account: detach all policies, delete inline policies, remove permission boundary, then `aws iam delete-role --role-name CrossAccountS3Reader` and `aws iam delete-role --role-name CrossAccountAdmin`
    - Delete permission boundary policy: `aws iam delete-policy --policy-arn <boundary-arn>`
    - Delete MFA enforcement policy if created as managed policy
    - Stop and delete organization trail: `aws cloudtrail stop-logging --name OrgTrail` then `aws cloudtrail delete-trail --name OrgTrail`
    - Delete IAM Access Analyzer: `aws accessanalyzer delete-analyzer --analyzer-name OrgAnalyzer`
    - _Requirements: (all)_
  - [ ] 11.3 Remove SCPs, OUs, and organization resources
    - Detach all SCPs from OUs: `aws organizations detach-policy --policy-id <id> --target-id <ou-id>` for each SCP
    - Delete SCPs: `aws organizations delete-policy --policy-id <id>` for RegionRestriction and CloudTrailProtection
    - Move member accounts back to root before deleting OUs
    - Delete OUs: `aws organizations delete-organizational-unit --organizational-unit-id <ou-id>` for Security, Workloads, Sandbox
    - Empty and delete the centralized logging S3 bucket: `aws s3 rm s3://org-cloudtrail-logs-<account-id> --recursive` then `aws s3 rb s3://org-cloudtrail-logs-<account-id>`
    - **Note**: Member accounts can be closed via the AWS CLI (`aws organizations close-account`) or SDK (`CloseAccount` API), or through the AWS Organizations console. Be aware that active member accounts may incur costs.
    - _Requirements: (all)_
  - [ ] 11.4 Verify cleanup
    - Verify no SCPs remain attached: `aws organizations list-policies --filter SERVICE_CONTROL_POLICY`
    - Verify no trails exist: `aws cloudtrail describe-trails`
    - Verify IAM roles are deleted in Workload account
    - Verify S3 logging bucket is removed: `aws s3 ls | grep org-cloudtrail`
    - Check IAM Identity Center for remaining assignments: `aws sso-admin list-instances`
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Member accounts created via AWS Organizations cannot be deleted immediately — they must be closed through the AWS Organizations console (or via the `aws organizations close-account` CLI / `CloseAccount` SDK API) and have a 90-day post-closure period before permanent deletion. Plan accordingly for cleanup.
- Some operations (enabling IAM Identity Center, configuring MFA devices) may require console interaction in addition to CLI/SDK automation
- When working in member accounts, use `aws sts assume-role` to obtain temporary credentials before running commands targeting those accounts
- The management account is exempt from SCPs — this is by AWS design and is validated in task 3.3
