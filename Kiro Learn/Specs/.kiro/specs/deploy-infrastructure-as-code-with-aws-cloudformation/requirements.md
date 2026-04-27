

# Requirements Document

## Introduction

This project guides you through deploying infrastructure as code (IaC) using AWS CloudFormation. Instead of manually provisioning AWS resources through the console, you will define your infrastructure in declarative template files, deploy them as stacks, and manage their lifecycle — experiencing firsthand how IaC brings consistency, repeatability, and version-control practices to cloud infrastructure management.

Infrastructure as Code is a foundational practice in modern cloud operations. By treating infrastructure definitions the same way you treat application source code — with version control, review processes, and automated deployment — you dramatically reduce configuration drift, human error, and the time required to reproduce environments. AWS CloudFormation is the native AWS service for this practice, and understanding it is essential for anyone working with AWS at scale.

In this learning exercise, you will author CloudFormation templates in YAML, use parameters and outputs to make templates flexible and composable, deploy stacks that provision real AWS resources, perform stack updates to understand change management, and explore drift detection to see how CloudFormation helps maintain infrastructure integrity. By the end, you will have hands-on experience with the full CloudFormation lifecycle from template authoring through stack deletion.

## Glossary

- **infrastructure_as_code**: The practice of defining and managing cloud infrastructure through machine-readable configuration files rather than manual processes.
- **cloudformation_template**: A JSON or YAML text file that serves as a blueprint describing the AWS resources and their configurations to be provisioned.
- **cloudformation_stack**: A collection of AWS resources created, updated, and deleted together as a single unit from a CloudFormation template.
- **stack_parameters**: Input values defined in a template that allow customization at deployment time, making templates reusable across environments.
- **stack_outputs**: Values exported from a stack after deployment, such as resource identifiers or endpoints, that can be referenced by other stacks or users.
- **drift_detection**: A CloudFormation feature that identifies when the actual state of provisioned resources differs from the expected state defined in the template.
- **change_set**: A preview of the changes CloudFormation will make to a stack when you update it, allowing you to review modifications before applying them.
- **template_format_version**: A declaration at the top of a CloudFormation template that identifies the template's capabilities and structure.
- **intrinsic_functions**: Built-in CloudFormation functions (such as Ref and Join) used within templates to assign values that are available only at runtime.
- **resource_dependencies**: The relationships between resources in a template that determine the order in which CloudFormation creates, updates, or deletes them.

## Requirements

### Requirement 1: CloudFormation Template Authoring

**User Story:** As an infrastructure-as-code learner, I want to author a CloudFormation template in YAML that defines AWS resources with proper structure and sections, so that I understand how to express infrastructure declaratively.

#### Acceptance Criteria

1. WHEN the learner creates a CloudFormation template with the required Resources section and at least one valid resource definition, THE template SHALL pass CloudFormation template validation without errors.
2. THE template SHALL include a template format version declaration and a human-readable description that communicates the template's purpose.
3. IF the learner submits a template with syntax errors or references to unsupported resource types, THEN CloudFormation SHALL reject the template with a validation error before any resources are created.

### Requirement 2: Parameterized Template Design

**User Story:** As an infrastructure-as-code learner, I want to add parameters to my CloudFormation template with types, defaults, and constraints, so that I can make a single template reusable across different environments and configurations.

#### Acceptance Criteria

1. WHEN the learner defines parameters with types such as String, Number, or AWS-specific parameter types, THE template SHALL accept values at deployment time and use them in resource configurations.
2. THE template SHALL include at least one parameter with a default value, allowed values or allowed pattern constraint, and a description, so that invalid inputs are rejected before stack creation begins.
3. IF the learner does not supply a value for a parameter that has a default, THEN CloudFormation SHALL use the default value for that parameter during stack creation.
4. IF the learner supplies a parameter value that violates a defined constraint, THEN CloudFormation SHALL reject the stack creation and report the constraint violation.

### Requirement 3: Stack Deployment and Resource Provisioning

**User Story:** As an infrastructure-as-code learner, I want to deploy my CloudFormation template as a stack and see the actual AWS resources get created, so that I understand how declarative templates translate into running infrastructure.

#### Acceptance Criteria

1. WHEN the learner deploys a valid template, CloudFormation SHALL create a stack and provision all defined resources, with the stack reaching a CREATE_COMPLETE status upon success.
2. THE stack SHALL display all defined outputs, such as resource identifiers or generated endpoint URLs, so the learner can verify and reference the provisioned resources.
3. IF a resource within the stack fails to create, THEN CloudFormation SHALL roll back all resources in the stack to their previous state and the stack SHALL display a CREATE_FAILED or ROLLBACK_COMPLETE status with a descriptive failure reason.

### Requirement 4: Stack Updates and Change Sets

**User Story:** As an infrastructure-as-code learner, I want to modify my template and update an existing stack using change sets, so that I understand how CloudFormation manages infrastructure changes safely and predictably.

#### Acceptance Criteria

1. WHEN the learner creates a change set for an existing stack with a modified template, CloudFormation SHALL generate a preview listing each resource that will be added, modified, or removed, along with the type of change (replacement or in-place update).
2. WHEN the learner executes an approved change set, CloudFormation SHALL apply only the described changes to the stack, and the stack SHALL reach UPDATE_COMPLETE status upon success.
3. IF the learner creates a change set that results in no differences from the current stack, THEN CloudFormation SHALL indicate that no changes are detected.
4. IF a stack update fails during execution, THEN CloudFormation SHALL automatically roll back the stack to its previous known-good state.

### Requirement 5: Resource Dependencies and Intrinsic Functions

**User Story:** As an infrastructure-as-code learner, I want to use intrinsic functions and resource references in my template to wire resources together, so that I understand how CloudFormation manages dependencies and runtime values.

#### Acceptance Criteria

1. WHEN the learner uses a reference from one resource to another within the template, CloudFormation SHALL automatically determine the correct creation order based on the dependency and provision resources in that order.
2. THE template SHALL use at least two different intrinsic functions (such as Ref, Join, Select, or GetAtt) to dynamically compose values that are only known at deployment time.
3. IF the learner defines a circular dependency between resources, THEN CloudFormation SHALL reject the template with a validation error describing the dependency cycle.

### Requirement 6: Drift Detection and Infrastructure Integrity

**User Story:** As an infrastructure-as-code learner, I want to use drift detection on a deployed stack to identify when resources have been modified outside of CloudFormation, so that I understand how IaC helps maintain infrastructure consistency.

#### Acceptance Criteria

1. WHEN the learner initiates drift detection on a stack where no out-of-band changes have been made, CloudFormation SHALL report the stack's drift status as IN_SYNC.
2. WHEN the learner manually modifies a stack-managed resource outside of CloudFormation and then runs drift detection, CloudFormation SHALL report the stack's drift status as DRIFTED and identify the specific resource and property differences.
3. THE drift detection results SHALL clearly display the expected property values from the template alongside the actual current values of the resource.

### Requirement 7: Stack Cleanup and Resource Deletion

**User Story:** As an infrastructure-as-code learner, I want to delete my CloudFormation stack and confirm that all associated resources are removed, so that I understand the full lifecycle of infrastructure managed as code and avoid ongoing charges.

#### Acceptance Criteria

1. WHEN the learner deletes a stack, CloudFormation SHALL remove all resources that were created as part of that stack and the stack SHALL reach DELETE_COMPLETE status.
2. THE learner SHALL verify that the AWS resources previously created by the stack are no longer present in the account after deletion completes.
3. IF a resource within the stack cannot be deleted due to a dependency or protection setting, THEN CloudFormation SHALL report the failure with a reason and the stack SHALL remain in DELETE_FAILED status, allowing the learner to resolve the issue and retry.
