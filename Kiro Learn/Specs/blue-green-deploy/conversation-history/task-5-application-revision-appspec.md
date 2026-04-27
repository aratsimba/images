# Task 5: Application Revision with AppSpec File

**Started:** 2026-04-10
**Completed:** 2026-04-10

## Overview

Implemented the full revision management pipeline: AppSpec file generation, lifecycle hook scripts, revision bundling into zip archives, and S3 upload/download operations. This task produced the `revision_manager.py` module with six functions and three shell scripts that CodeDeploy will execute during deployments.

## Key Concepts Discussed

- **AppSpec File** — a YAML file that acts as a "recipe card" for CodeDeploy, defining which files go where on the target instance and which scripts run at each deployment stage
- **Lifecycle Event Hooks** — scripts that execute at defined stages during deployment: `BeforeInstall` (stop old server), `AfterInstall` (set permissions, start server), `ValidateService` (verify app is healthy)
- **Revision Bundle** — a zip archive containing the AppSpec file at the root, application source files, and hook scripts; CodeDeploy requires `appspec.yml` at the zip root
- **S3 as Revision Storage** — CodeDeploy fetches revision bundles from S3 during deployment; the `RevisionLocation` dictionary tells CodeDeploy the bucket, key, and bundle type
- **RevisionLocation** — a structured dictionary (`revisionType: "S3"`, `s3Location: {bucket, key, bundleType: "zip"}`) that CodeDeploy uses to locate and download the revision

### Analogies Used

- AppSpec as a moving company checklist — file mappings say where boxes go, hooks are the stages (clear the room, set things down, do a walk-through)
- YAML as a restaurant order ticket — structured, human-readable format
- S3 bucket as a self-storage facility — rent a unit, store your box, write down the address for the delivery driver
- Revision bundle as a packed moving box with a packing list on top
- `delete_revision_bucket` needing to empty first — like returning a storage unit that still has boxes inside

## Files Created / Modified

### New Files
- `blue-green-deploy/app-source/scripts/before_install.sh` — stops httpd if running
- `blue-green-deploy/app-source/scripts/after_install.sh` — sets permissions on `/var/www/html`, starts and enables httpd
- `blue-green-deploy/app-source/scripts/validate_service.sh` — curls localhost with 5 retries at 5-second intervals, exits 1 on failure
- `blue-green-deploy/app-source/src/index.html` — sample application content ("Blue-Green Deployment Demo, Version 1.0")

### Modified Files
- `blue-green-deploy/components/revision_manager.py` — replaced stubs with full implementations

## Implementation Details

### Task 5.1: AppSpec Generation and Bundling

| Function | Purpose |
|----------|---------|
| `generate_appspec(file_mappings, hooks)` | Produces YAML string with `version: 0.0`, `os: linux`, `files` section, and `hooks` section |
| `create_revision_bundle(appspec_content, source_dir, output_path)` | Creates a zip with `appspec.yml` at root, walks `source_dir` adding all files (skips `.gitkeep`) |

#### Hook Scripts

| Script | Lifecycle Event | What It Does |
|--------|----------------|--------------|
| `before_install.sh` | BeforeInstall | `systemctl stop httpd` (tolerates failure if not running) |
| `after_install.sh` | AfterInstall | `chmod -R 755` and `chown apache:apache` on `/var/www/html`, then starts/enables httpd |
| `validate_service.sh` | ValidateService | Curls `http://localhost/` up to 5 times, expects HTTP 200, exits 1 if all attempts fail |

#### Zip Bundle Structure
```
revision.zip
├── appspec.yml
├── src/
│   └── index.html
└── scripts/
    ├── before_install.sh
    ├── after_install.sh
    └── validate_service.sh
```

### Task 5.2: S3 Upload and Revision Location

| Function | Purpose |
|----------|---------|
| `create_revision_bucket(bucket_name)` | Creates S3 bucket; handles us-east-1 (no LocationConstraint); handles `BucketAlreadyOwnedByYou` |
| `upload_revision(bucket_name, bundle_path, key)` | Uploads zip to S3, returns `s3://bucket/key` URI |
| `get_revision_location(bucket_name, key)` | Returns `RevisionLocation` dict for CodeDeploy API calls |
| `delete_revision_bucket(bucket_name)` | Paginates through all objects, deletes them, then deletes bucket; handles `NoSuchBucket` |

## Issues Encountered

None — the implementation went smoothly. The existing project structure (empty `scripts/` directory, stub `revision_manager.py`) was well-prepared from earlier tasks.

## Next Steps

Task 6: Create the CodeDeploy Application and Blue-Green Deployment Group, which will use `get_revision_location()` to point deployments at the S3 revision.
