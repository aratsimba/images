# Task 5 & 6: Manual Provisioning and tasks.md Update

## Context

Tasks 5 and 6 were originally completed as code-only — the Python functions were implemented but never actually executed to create AWS resources. This was caught before Task 7 (Checkpoint - Validate CodeDeploy Configuration), and the resources were provisioned manually in a follow-up session.

## Problem Identified

Tasks 2 and 3 each had explicit "Provision" subtasks (2.3 and 3.3) that said "Run the functions to create the actual AWS resources." Tasks 5 and 6 lacked these, having only implementation subtasks with verification commands that implicitly assumed resources existed. This gap caused the provisioning to be missed during initial task execution.

## Manual Provisioning — Task 5

Ran the revision manager functions from `blue-green-deploy/`:

```python
from components.revision_manager import (
    generate_appspec, create_revision_bundle,
    create_revision_bucket, upload_revision, get_revision_location,
)

# Generated AppSpec with file mappings and lifecycle hooks
file_mappings = [{'source': '/src', 'destination': '/var/www/html'}]
hooks = [
    {'event_name': 'BeforeInstall', 'script_location': 'scripts/before_install.sh', 'timeout': 300, 'runas': 'root'},
    {'event_name': 'AfterInstall', 'script_location': 'scripts/after_install.sh', 'timeout': 300, 'runas': 'root'},
    {'event_name': 'ValidateService', 'script_location': 'scripts/validate_service.sh', 'timeout': 300, 'runas': 'root'},
]
appspec_content = generate_appspec(file_mappings, hooks)

# Bundled, created bucket, uploaded
bundle_path = create_revision_bundle(appspec_content, 'app-source', 'revision.zip')
create_revision_bucket('blue-green-deploy-revisions-628326705801')
upload_revision('blue-green-deploy-revisions-628326705801', bundle_path, 'revisions/v1.zip')
```

### Verification

```bash
$ aws s3 ls s3://blue-green-deploy-revisions-628326705801/revisions/
2026-04-10 16:41:07       1575 v1.zip
```

## Manual Provisioning — Task 6

Ran the deployment manager functions from `blue-green-deploy/`:

```python
from components.deployment_manager import (
    create_application, list_deployment_configs,
    create_blue_green_deployment_group,
)

create_application('BlueGreenApp')
list_deployment_configs()
create_blue_green_deployment_group(
    app_name='BlueGreenApp',
    group_name='BlueGreenDG',
    service_role_arn='arn:aws:iam::628326705801:role/CodeDeployServiceRole',
    asg_name='BlueGreenASG',
    target_group_name='BlueGreenTG',
    auto_rollback_enabled=True,
    termination_wait_minutes=5,
)
```

### Results

- Application ID: `f1725c38-bdab-42d1-af4e-49617d730aeb`
- Deployment Group ID: `69dee672-4756-42af-8913-ed8567ea4fbe`

### Verification

```bash
$ aws deploy get-application --application-name BlueGreenApp
# Confirmed: BlueGreenApp, Server platform

$ aws deploy get-deployment-group --application-name BlueGreenApp --deployment-group-name BlueGreenDG
# Confirmed: BLUE_GREEN type, WITH_TRAFFIC_CONTROL, auto-rollback enabled
```

## tasks.md Modification

To prevent this gap from recurring, two new provisioning subtasks were added to `tasks.md`:

### Added: 5.3 Provision Revision Resources
- Calls `generate_appspec()`, `create_revision_bundle()`, `create_revision_bucket()`, `upload_revision()`
- Includes verification: `aws s3 ls s3://<bucket-name>/revisions/`
- Marked as completed

### Added: 6.3 Provision CodeDeploy Resources
- Calls `create_application('BlueGreenApp')`, `list_deployment_configs()`, `create_blue_green_deployment_group(...)`
- Includes verification: `aws deploy get-application` and `aws deploy get-deployment-group`
- Marked as completed

These follow the same pattern as existing subtasks 2.3 (Provision IAM Resources) and 3.3 (Provision Infrastructure Resources).
