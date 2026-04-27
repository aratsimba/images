

# Implementation Plan: Build a Static Website with Amazon S3

## Overview

This project implements a static website hosted on Amazon S3 using Python scripts built with boto3. The implementation follows a straightforward progression: set up the development environment, build three Python components (BucketManager, WebsiteConfigurator, ContentUploader), create sample website content, and deploy everything to S3. Each component maps directly to a phase of the S3 static website hosting workflow.

The key milestones are: (1) environment and project setup, (2) BucketManager implementation for bucket lifecycle operations, (3) WebsiteConfigurator implementation for hosting and permissions, (4) ContentUploader implementation for file uploads and verification, and (5) end-to-end deployment and validation of the live website. Checkpoints after the bucket creation phase and after full deployment ensure incremental validation.

Dependencies flow naturally — the bucket must exist before hosting can be configured, hosting and permissions must be set before content serves correctly, and content must be uploaded before the website can be verified. The project concludes with cleanup to remove all AWS resources and avoid ongoing charges.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for S3 operations
    - Configure AWS CLI: `aws configure` (set access key, secret key, default region)
    - Verify access: `aws sts get-caller-identity`
    - Verify S3 access: `aws s3 ls`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`
    - Install requests library for website verification: `pip install requests`
    - Verify boto3: `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 Project Structure Setup
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `mkdir -p components website`
    - Create `components/__init__.py` to make it a Python package
    - Create placeholder files: `components/bucket_manager.py`, `components/website_configurator.py`, `components/content_uploader.py`
    - _Requirements: (all)_

- [ ] 2. Implement BucketManager Component
  - [ ] 2.1 Create the BucketManager class with bucket lifecycle methods
    - Create `components/bucket_manager.py` with `import boto3` and `from botocore.exceptions import ClientError`
    - Implement `create_bucket(bucket_name, region)` that calls `s3_client.create_bucket()` with `CreateBucketConfiguration` for non-us-east-1 regions; return the response dictionary
    - Implement `bucket_exists(bucket_name)` using `s3_client.head_bucket()` wrapped in try/except returning boolean
    - Implement `list_buckets()` using `s3_client.list_buckets()` returning a list of `BucketInfo` dictionaries with `bucket_name`, `region`, and `creation_date`
    - Implement `empty_bucket(bucket_name)` using `s3_client.list_objects_v2()` and `s3_client.delete_objects()` to remove all objects
    - Implement `delete_bucket(bucket_name)` that calls `empty_bucket()` first, then `s3_client.delete_bucket()`
    - Handle errors: `BucketAlreadyExists`, `BucketAlreadyOwnedByYou`, `InvalidBucketName`, `NoSuchBucket`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Test BucketManager by creating an S3 bucket
    - Create `scripts/create_bucket.py` that imports BucketManager and creates a bucket with a globally unique name (e.g., `my-static-site-<random-suffix>`)
    - Run the script: `python3 scripts/create_bucket.py`
    - Verify the bucket exists: `aws s3api head-bucket --bucket <bucket-name>`
    - Verify the bucket is listed: `aws s3 ls | grep <bucket-name>`
    - Test error handling by attempting to create a bucket with an invalid name (e.g., uppercase letters)
    - _Requirements: 1.1, 1.2, 1.3_

- [ ] 3. Implement WebsiteConfigurator Component
  - [ ] 3.1 Create website hosting configuration methods
    - Create `components/website_configurator.py` with `import boto3` and `import json`
    - Implement `enable_website_hosting(bucket_name, index_document, error_document)` using `s3_client.put_bucket_website()` with `WebsiteConfiguration` containing `IndexDocument` and `ErrorDocument` settings
    - Implement `get_website_configuration(bucket_name)` using `s3_client.get_bucket_website()` returning the configuration dictionary; handle `NoSuchWebsiteConfiguration` error
    - Implement `get_website_endpoint(bucket_name, region)` that constructs and returns the endpoint URL: `http://{bucket_name}.s3-website-{region}.amazonaws.com` (adjust format for regions using dot notation)
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 3.2 Create public access and bucket policy methods
    - Implement `disable_block_public_access(bucket_name)` using `s3_client.put_public_access_block()` setting all four Block Public Access flags to `False`
    - Implement `get_block_public_access(bucket_name)` using `s3_client.get_public_access_block()` returning a `PublicAccessConfig` dictionary
    - Implement `apply_public_read_policy(bucket_name)` that constructs a JSON policy granting `s3:GetObject` to principal `"*"` on resource `arn:aws:s3:::{bucket_name}/*` and applies it via `s3_client.put_bucket_policy()`
    - Implement `get_bucket_policy(bucket_name)` using `s3_client.get_bucket_policy()` and parsing the JSON response
    - Handle errors: `AccessDenied` when Block Public Access is still enabled
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 4. Checkpoint - Validate Bucket and Hosting Configuration
  - Create a test script `scripts/configure_hosting.py` that enables website hosting with `index.html` as index document and `404.html` as error document
  - Run the script and verify hosting is enabled: `aws s3api get-bucket-website --bucket <bucket-name>`
  - Verify the website endpoint URL is correctly constructed and displayed
  - Verify Block Public Access is disabled: `aws s3api get-public-access-block --bucket <bucket-name>`
  - Verify the bucket policy is applied: `aws s3api get-bucket-policy --bucket <bucket-name>`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Create Website Content
  - [ ] 5.1 Create the index document and error document
    - Create `website/index.html` with a complete HTML page including `<!DOCTYPE html>`, a heading, a paragraph, and a link to the CSS stylesheet (`css/style.css`)
    - Create `website/404.html` with a styled error page displaying a "Page Not Found" message and a link back to the home page
    - _Requirements: 4.1, 4.3_
  - [ ] 5.2 Create supporting CSS and organize files in folders
    - Create `website/css/style.css` with basic styling (fonts, colors, layout) for both pages
    - Optionally add an image file to `website/images/` to test image upload and content type detection
    - Verify folder structure: `website/index.html`, `website/404.html`, `website/css/style.css`, `website/images/`
    - _Requirements: 4.1, 4.4_

- [ ] 6. Implement ContentUploader Component
  - [ ] 6.1 Create file upload and content type methods
    - Create `components/content_uploader.py` with `import boto3`, `import os`, `import mimetypes`, and `import requests`
    - Implement `get_content_type(file_path)` using `mimetypes.guess_type()` to return the MIME type (e.g., `text/html`, `text/css`, `image/png`); default to `application/octet-stream`
    - Implement `upload_file(bucket_name, file_path, object_key)` using `s3_client.upload_file()` with `ExtraArgs={'ContentType': get_content_type(file_path)}`; handle `FileNotFoundError`
    - Implement `upload_directory(bucket_name, directory_path, prefix)` that walks the directory with `os.walk()`, uploads each file with the correct relative key (preserving folder structure), and returns a list of uploaded object keys
    - Implement `list_objects(bucket_name, prefix)` using `s3_client.list_objects_v2()` returning a list of `UploadedObject` dictionaries with `key`, `size`, and `content_type`
    - _Requirements: 4.1, 4.4_
  - [ ] 6.2 Create website verification method
    - Implement `verify_website(endpoint_url)` that sends an HTTP GET request to the endpoint URL using `requests.get()` and returns a dictionary with `status_code`, `content_length`, and `content_type`
    - Handle `ConnectionError` for cases where DNS propagation hasn't completed; include retry logic with a brief delay
    - Test with a non-existent path to verify the error document is returned
    - _Requirements: 4.2, 4.3_

- [ ] 7. Deploy and Verify the Static Website
  - [ ] 7.1 Upload website content and verify objects
    - Create `scripts/deploy_website.py` that uses ContentUploader to upload the entire `website/` directory to the S3 bucket
    - Run the script: `python3 scripts/deploy_website.py`
    - Verify objects are uploaded: `aws s3 ls s3://<bucket-name>/ --recursive`
    - Confirm files are listed including `index.html`, `404.html`, `css/style.css`, and any images
    - _Requirements: 4.1, 4.4_
  - [ ] 7.2 Verify website is live and functional
    - Use `verify_website()` to confirm the index page is served at the website endpoint root URL (HTTP 200)
    - Open the website endpoint URL in a browser and confirm the styled page renders correctly
    - Request a non-existent path (e.g., `/nonexistent-page`) and confirm the 404 error document is returned
    - Verify files in subdirectories are accessible (e.g., `<endpoint>/css/style.css`)
    - _Requirements: 4.2, 4.3, 4.4_

- [ ] 8. Checkpoint - End-to-End Validation
  - Confirm the S3 bucket exists and is configured for static website hosting with correct index and error documents
  - Confirm Block Public Access is disabled and the public-read bucket policy is applied
  - Confirm all website files (HTML, CSS, images) are uploaded and accessible via the website endpoint
  - Confirm the index document renders when visiting the root URL
  - Confirm the error document renders when visiting a non-existent path
  - Confirm files in folder prefixes serve correctly via URL paths
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Cleanup - Resource Teardown
  - [ ] 9.1 Delete website content and bucket
    - Use BucketManager's `empty_bucket()` to delete all objects from the bucket
    - Verify bucket is empty: `aws s3 ls s3://<bucket-name>/`
    - Delete the bucket policy: `aws s3api delete-bucket-policy --bucket <bucket-name>`
    - Delete the bucket using BucketManager's `delete_bucket()` or: `aws s3 rb s3://<bucket-name>`
    - _Requirements: (all)_
  - [ ] 9.2 Verify cleanup
    - Confirm bucket no longer exists: `aws s3api head-bucket --bucket <bucket-name>` (should return error)
    - Confirm the website endpoint URL returns an error in the browser
    - Check the S3 console to verify no leftover buckets from this project
    - Review AWS Cost Explorer to confirm no ongoing S3 charges
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The bucket name must be globally unique across all AWS accounts — use a random suffix or timestamp
- The website endpoint format varies by region: some use `s3-website-{region}` (dash) and others use `s3-website.{region}` (dot) — the `get_website_endpoint` method should handle both
- After enabling static website hosting, DNS propagation may take a few moments before the endpoint is accessible
- This project creates resources that may incur charges — always complete the cleanup task when finished
