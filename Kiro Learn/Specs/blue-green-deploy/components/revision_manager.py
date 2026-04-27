# Revision Manager - AppSpec generation, bundling, S3 upload

import os
import zipfile

import yaml
import boto3
from botocore.exceptions import ClientError


# ---------------------------------------------------------------------------
# AppSpec Generation
# ---------------------------------------------------------------------------

def generate_appspec(file_mappings: list, hooks: list) -> str:
    """Generate a YAML AppSpec file for CodeDeploy.

    Args:
        file_mappings: List of dicts with 'source' and 'destination' keys.
        hooks: List of dicts with 'event_name', 'script_location',
               'timeout', and 'runas' keys.

    Returns:
        A YAML string representing the AppSpec content.
    """
    appspec = {
        "version": 0.0,
        "os": "linux",
        "files": [
            {"source": m["source"], "destination": m["destination"]}
            for m in file_mappings
        ],
        "hooks": {},
    }

    for hook in hooks:
        appspec["hooks"][hook["event_name"]] = [
            {
                "location": hook["script_location"],
                "timeout": hook["timeout"],
                "runas": hook["runas"],
            }
        ]

    return yaml.dump(appspec, default_flow_style=False, sort_keys=False)


# ---------------------------------------------------------------------------
# Revision Bundling
# ---------------------------------------------------------------------------

def create_revision_bundle(
    appspec_content: str, source_dir: str, output_path: str
) -> str:
    """Create a zip archive containing the AppSpec file, app files, and scripts.

    Args:
        appspec_content: YAML string for the appspec.yml file.
        source_dir: Path to the app-source directory (contains src/ and scripts/).
        output_path: Destination path for the zip archive.

    Returns:
        The absolute path to the created zip file.
    """
    output_path = os.path.abspath(output_path)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # Add the AppSpec file at the root of the archive
        zf.writestr("appspec.yml", appspec_content)

        # Walk the source directory and add all files
        source_dir = os.path.abspath(source_dir)
        for root, _dirs, files in os.walk(source_dir):
            for filename in files:
                if filename == ".gitkeep":
                    continue
                filepath = os.path.join(root, filename)
                arcname = os.path.relpath(filepath, source_dir)
                zf.write(filepath, arcname)

    print(f"Created revision bundle: {output_path}")
    return output_path


# ---------------------------------------------------------------------------
# S3 Operations (stubs for task 5.2)
# ---------------------------------------------------------------------------

s3 = boto3.client("s3")


def create_revision_bucket(bucket_name: str) -> None:
    """Create an S3 bucket for storing revision bundles.

    For us-east-1, no LocationConstraint is needed. For other regions,
    a CreateBucketConfiguration with the appropriate LocationConstraint
    is required.

    Args:
        bucket_name: Name of the S3 bucket to create.
    """
    try:
        # us-east-1 does not accept a LocationConstraint
        region = s3.meta.region_name
        if region == "us-east-1":
            s3.create_bucket(Bucket=bucket_name)
        else:
            s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={"LocationConstraint": region},
            )
        print(f"Created S3 bucket: {bucket_name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "BucketAlreadyOwnedByYou":
            print(f"Bucket already exists and is owned by you: {bucket_name}")
        else:
            raise


def upload_revision(bucket_name: str, bundle_path: str, key: str) -> str:
    """Upload a revision bundle zip to S3.

    Args:
        bucket_name: Target S3 bucket name.
        bundle_path: Local path to the zip bundle file.
        key: S3 object key for the uploaded file.

    Returns:
        The S3 URI of the uploaded object (s3://bucket/key).
    """
    s3.upload_file(bundle_path, bucket_name, key)
    s3_uri = f"s3://{bucket_name}/{key}"
    print(f"Uploaded revision to {s3_uri}")
    return s3_uri


def get_revision_location(bucket_name: str, key: str) -> dict:
    """Return a CodeDeploy RevisionLocation dictionary for an S3 revision.

    Args:
        bucket_name: S3 bucket containing the revision.
        key: S3 object key of the revision bundle.

    Returns:
        A dictionary matching the CodeDeploy RevisionLocation structure.
    """
    return {
        "revisionType": "S3",
        "s3Location": {
            "bucket": bucket_name,
            "key": key,
            "bundleType": "zip",
        },
    }


def delete_revision_bucket(bucket_name: str) -> None:
    """Empty and delete the revision S3 bucket.

    Lists all objects in the bucket, deletes them, then deletes the bucket.

    Args:
        bucket_name: Name of the S3 bucket to delete.
    """
    try:
        # List and delete all objects in the bucket
        paginator = s3.get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=bucket_name):
            objects = page.get("Contents", [])
            if objects:
                delete_keys = [{"Key": obj["Key"]} for obj in objects]
                s3.delete_objects(
                    Bucket=bucket_name,
                    Delete={"Objects": delete_keys},
                )

        s3.delete_bucket(Bucket=bucket_name)
        print(f"Deleted S3 bucket: {bucket_name}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchBucket":
            print(f"Bucket does not exist: {bucket_name}")
        else:
            raise
