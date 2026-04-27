

# Requirements Document

## Introduction

This project guides learners through implementing IAM best practices for a multi-account AWS environment — one of the most critical foundational skills for any cloud practitioner. In real-world organizations, AWS environments rarely consist of a single account; instead, they span multiple accounts to achieve security isolation, billing separation, and operational independence. Understanding how to manage identities, permissions, and access controls across these account boundaries is essential for building a secure cloud foundation.

The learner will set up an AWS Organizations structure, configure centralized identity management through IAM Identity Center, establish cross-account access patterns using IAM roles with least-privilege policies, and implement governance guardrails using service control policies. Along the way, they will apply security best practices including multi-factor authentication enforcement, permission boundaries, credential management, and audit logging with CloudTrail.

By completing this project, learners will gain hands-on experience with the IAM security practices recommended by the AWS Well-Architected Framework and will understand how to design an identity and access management strategy that scales across multiple AWS accounts.

## Glossary

- **management_account**: The root AWS account in an AWS Organizations structure that has authority over all member accounts and is used for billing consolidation and organizational policy management.
- **member_account**: An AWS account that belongs to an AWS Organization and is subject to governance policies applied by the management account.
- **service_control_policy**: An AWS Organizations policy type that sets the maximum available permissions for member accounts, acting as a guardrail regardless of individual IAM policies.
- **permission_set**: A collection of IAM policies defined in IAM Identity Center that determines what a user can do when they access a specific AWS account.
- **trust_policy**: A JSON policy attached to an IAM role that specifies which principals (users, roles, accounts, or services) are allowed to assume that role.
- **external_id**: A unique identifier used in IAM role trust policies to mitigate the confused deputy problem when granting cross-account access to third parties.
- **permission_boundary**: An advanced IAM feature that sets the maximum permissions an IAM entity (user or role) can have, regardless of the identity-based policies attached to it.
- **role_assumption**: The process by which a principal obtains temporary security credentials to act with the permissions of an IAM role, including across account boundaries.
- **attribute_based_access_control**: An authorization strategy that uses attributes (tags) attached to users and resources to make dynamic access control decisions.

## Requirements

### Requirement 1: AWS Organizations Multi-Account Structure

**User Story:** As a cloud security learner, I want to create an AWS Organizations structure with a management account and member accounts organized into organizational units, so that I can establish the foundational account hierarchy needed for centralized governance.

#### Acceptance Criteria

1. WHEN the learner enables AWS Organizations from the management account, THE organization SHALL be created with all features enabled, including consolidated billing and policy management capabilities.
2. WHEN the learner creates organizational units for distinct workload categories (e.g., Security, Workloads, Sandbox), THE organizational units SHALL appear in the organization hierarchy and be available for account placement.
3. WHEN the learner moves a member account into an organizational unit, THE account SHALL inherit any service control policies attached to that organizational unit.

### Requirement 2: Service Control Policies for Guardrails

**User Story:** As a cloud security learner, I want to define and apply service control policies to organizational units, so that I can establish preventive guardrails that limit the maximum permissions available to accounts regardless of their individual IAM policies.

#### Acceptance Criteria

1. WHEN the learner creates a service control policy that denies access to specific AWS regions, THE member accounts within the targeted organizational unit SHALL be unable to create or manage resources in those denied regions.
2. WHEN the learner attaches a service control policy that prevents disabling CloudTrail, THE IAM principals in affected accounts SHALL be unable to stop or delete trail logging even if their IAM policies grant full CloudTrail permissions.
3. IF the learner attaches multiple service control policies to an organizational unit, THEN THE effective permissions SHALL be the intersection of all attached policies, meaning an action must be allowed by every attached policy to succeed.
4. THE management account SHALL remain unaffected by service control policies, regardless of which policies are attached to the root of the organization.

### Requirement 3: Centralized Identity Management with IAM Identity Center

**User Story:** As a cloud security learner, I want to configure IAM Identity Center as the centralized access point for human users across all accounts in my organization, so that I can manage authentication and authorization from a single location instead of creating individual IAM users in each account.

#### Acceptance Criteria

1. WHEN the learner enables IAM Identity Center at the organization level, THE service SHALL be available to manage user access across all member accounts in the organization.
2. WHEN the learner creates permission sets with varying levels of access (e.g., read-only, administrator, power-user), THE permission sets SHALL be assignable to users or groups for specific AWS accounts.
3. WHEN the learner assigns a user a permission set for a specific member account, THE user SHALL be able to access that account through the IAM Identity Center portal with only the permissions defined in the assigned permission set.
4. IF the learner removes a user's permission set assignment for an account, THEN THE user SHALL no longer be able to access that account through IAM Identity Center.

### Requirement 4: Cross-Account IAM Role Access with Least Privilege

**User Story:** As a cloud security learner, I want to create IAM roles that allow principals in one account to assume roles in another account using trust policies and least-privilege permissions, so that I can implement secure cross-account access for workloads and automation.

#### Acceptance Criteria

1. WHEN the learner creates an IAM role in a target account with a trust policy that specifies a source account principal, THE role SHALL be assumable only by the designated principal from the source account and SHALL return temporary credentials upon successful assumption.
2. WHEN the learner includes an external ID condition in the trust policy, THE role assumption SHALL succeed only when the assuming principal provides the matching external ID value.
3. THE cross-account IAM role SHALL follow least-privilege principles by granting only the specific service actions and resources required for the intended task, rather than using wildcard permissions.
4. WHEN the learner specifies a maximum session duration for the cross-account role, THE temporary credentials obtained through role assumption SHALL expire after the configured duration.

### Requirement 5: Permission Boundaries for Delegated Administration

**User Story:** As a cloud security learner, I want to apply permission boundaries to IAM roles and users, so that I can safely delegate administrative tasks while ensuring that delegated administrators cannot escalate their own privileges beyond a defined ceiling.

#### Acceptance Criteria

1. WHEN the learner attaches a permission boundary to an IAM role, THE effective permissions of that role SHALL be the intersection of its identity-based policies and the permission boundary, meaning the role cannot perform actions outside the boundary even if its policies explicitly allow them.
2. WHEN the learner creates a delegated administrator role with a permission boundary that excludes IAM administrative actions, THE role SHALL be unable to modify its own permission boundary or create new roles without boundaries.
3. IF the learner attempts to use a bounded role to grant permissions that exceed the permission boundary, THEN THE action SHALL be denied regardless of the identity-based policy attached to the role.

### Requirement 6: Multi-Factor Authentication Enforcement

**User Story:** As a cloud security learner, I want to enforce multi-factor authentication for sensitive operations and console access across the multi-account environment, so that I can add a critical layer of identity verification that protects against compromised credentials.

#### Acceptance Criteria

1. WHEN the learner configures an IAM policy with an MFA condition, THE protected actions SHALL be denied for any principal that has not authenticated with a valid MFA device in the current session.
2. WHEN the learner enables MFA enforcement in IAM Identity Center, THE users SHALL be required to register and use an MFA device before accessing any assigned AWS accounts.
3. WHEN the learner creates a cross-account role trust policy with an MFA condition, THE role assumption SHALL succeed only when the assuming principal has completed MFA authentication.

### Requirement 7: CloudTrail Logging and Cross-Account Audit

**User Story:** As a cloud security learner, I want to configure an organization-wide CloudTrail trail that logs IAM and cross-account activity to a centralized logging account, so that I can monitor access patterns, detect anomalies, and maintain an audit trail across the entire multi-account environment.

#### Acceptance Criteria

1. WHEN the learner creates an organization trail from the management account, THE trail SHALL automatically capture management events from all current and future member accounts in the organization.
2. THE trail SHALL deliver log files to a centralized S3 bucket in a dedicated logging account, with a bucket policy that permits CloudTrail delivery from all organization accounts.
3. WHEN a cross-account role assumption occurs, THE CloudTrail log entry SHALL record the assuming principal, the assumed role, the role session name, and the source account, enabling the learner to trace cross-account activity.
4. IF the learner uses IAM Access Analyzer to review cross-account access findings, THEN THE analyzer SHALL identify IAM roles and resource policies that grant access to external principals outside the organization.

### Requirement 8: Credential Management and Access Key Hygiene

**User Story:** As a cloud security learner, I want to implement proper credential management practices including using temporary credentials for workloads and auditing any long-term access keys, so that I can minimize the attack surface associated with static credentials.

#### Acceptance Criteria

1. WHEN the learner configures a workload to use an IAM role (rather than long-term access keys), THE workload SHALL obtain temporary credentials that automatically rotate without manual intervention.
2. WHEN the learner generates a credential report for an account, THE report SHALL identify all IAM users, their access key status, key age, last usage timestamps, and MFA device enrollment status.
3. IF the learner identifies access keys that have not been used within a defined period through the credential report, THEN THE learner SHALL be able to deactivate or delete those unused keys to reduce the risk of credential compromise.
4. THE root user of each account SHALL have MFA enabled and SHALL NOT have active access keys, following the AWS best practice of safeguarding root credentials and avoiding their use for everyday tasks.
