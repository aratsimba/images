

# Implementation Plan: Build a Business Intelligence Dashboard with Amazon QuickSight

## Overview

This implementation plan guides you through building a complete Business Intelligence dashboard using Amazon QuickSight. The workflow begins with environment setup and sample data generation, progresses through QuickSight account provisioning and data source configuration, and culminates in building interactive analyses with ML-powered insights and publishing a shareable dashboard. The approach combines Python SDK automation for data preparation and QuickSight API operations with console-driven visual tasks for chart building, filtering, and ML features.

The plan is organized into three major phases. Phase one covers prerequisites, data generation, and S3 upload (SampleDataGenerator component). Phase two handles QuickSight account setup, data source/dataset creation, calculated fields, and SPICE import (QuickSightDataManager component). Phase three focuses on building the interactive analysis in the console, adding filters and ML insights, then publishing and sharing the dashboard programmatically (DashboardManager component).

Key dependencies dictate task ordering: S3 data must exist before QuickSight can connect to it, datasets must be created before analyses can be built, and analyses must exist before dashboards can be published. Checkpoints are placed after data infrastructure setup and after analysis creation to validate progress incrementally before proceeding.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with billing enabled
    - Configure AWS CLI: `aws configure` (set access key, secret key, region)
    - Verify access: `aws sts get-caller-identity`
    - Note your AWS Account ID from the output — it is required for all QuickSight API calls
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install required Python libraries: `pip install boto3 pandas`
    - Create project directory structure: `mkdir -p components data`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and IAM Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure your IAM user/role has permissions for: `s3:*`, `quicksight:*`, `iam:*` (for QuickSight service role)
    - Create an S3 bucket for sample data: `aws s3api create-bucket --bucket <your-qs-data-bucket> --region us-east-1`
    - Verify bucket creation: `aws s3 ls s3://<your-qs-data-bucket>/`
    - _Requirements: (all)_

- [ ] 2. Generate Sample Sales Data and Upload to S3
  - [ ] 2.1 Implement the SampleDataGenerator component
    - Create file `components/sample_data_generator.py`
    - Implement `generate_sales_data(num_records, start_date, end_date)` using pandas to create a DataFrame with all `SalesRecord` fields: `order_id`, `order_date`, `region`, `category`, `product_name`, `quantity`, `unit_price`, `revenue`, `cost`, `customer_segment`
    - Use randomized but realistic data: regions (`North America`, `Europe`, `Asia Pacific`, `Latin America`), categories (`Electronics`, `Clothing`, `Home`, `Office`), customer segments (`Enterprise`, `SMB`, `Consumer`)
    - Ensure data spans at least 2 years (e.g., 2022-01-01 to 2024-12-31) to support time-series forecasting
    - Implement `save_to_csv(data, file_path)` to write the DataFrame to a local CSV file at `data/sales_data.csv`
    - Generate at least 5000 records for meaningful visualizations
    - Verify: run the function and confirm CSV file exists with correct columns and row count
    - _Requirements: 2.1, 6.1, 6.2_
  - [ ] 2.2 Upload CSV and S3 manifest to S3
    - Implement `upload_to_s3(bucket_name, file_path, s3_key)` using `boto3.client('s3')` and `upload_file()`
    - Implement `create_s3_manifest(bucket_name, csv_key)` returning an `S3Manifest` dictionary with `fileLocations` containing the S3 URI and `globalUploadSettings` with `format: CSV`, `delimiter: ","`, `textqualifier: "\""` 
    - Implement `upload_manifest(bucket_name, manifest, manifest_key)` to serialize the manifest as JSON and upload via `put_object()`
    - Upload CSV to `s3://<bucket>/data/sales_data.csv` and manifest to `s3://<bucket>/manifests/sales_manifest.json`
    - Verify: `aws s3 ls s3://<your-qs-data-bucket>/data/` and `aws s3 ls s3://<your-qs-data-bucket>/manifests/`
    - _Requirements: 1.3, 2.1_

- [ ] 3. QuickSight Account Setup and Data Source Connection
  - [ ] 3.1 Sign up for Amazon QuickSight and configure permissions
    - Navigate to the AWS Console → Amazon QuickSight
    - Sign up for QuickSight (Enterprise edition is required for this project — ML-powered anomaly detection, forecasting, and auto-narrative insights used in Task 7.2 are Enterprise Edition features only)
    - During setup, grant QuickSight access to Amazon S3 and select your data bucket
    - After provisioning, verify QuickSight is accessible by navigating to the QuickSight console home page
    - Note your QuickSight user ARN and identity region for later API calls
    - If already signed up, go to Manage QuickSight → Security & permissions → Add or remove S3 access to ensure your bucket is authorized
    - _Requirements: 1.1, 1.2_
  - [ ] 3.2 Implement QuickSightDataManager - data source creation
    - Create file `components/quicksight_data_manager.py`
    - Initialize `boto3.client('quicksight')` in the constructor
    - Implement `create_s3_data_source(aws_account_id, data_source_id, data_source_name, bucket_name, manifest_key)` using `create_data_source()` API with `Type='S3'` and `S3Parameters` pointing to the manifest S3 URI
    - Implement `describe_data_source(aws_account_id, data_source_id)` to check data source status
    - Handle `ResourceExistsException` by logging and continuing, `AccessDeniedException` by advising permission fix, and `InvalidParameterValueException` by reporting manifest path issues
    - Run the creation function; verify the data source status is `CREATION_SUCCESSFUL` via `describe_data_source()`
    - _Requirements: 1.3, 1.4_
  - [ ]* 3.3 Validate data source connection failure handling
    - **Property 1: Data Source Validation on Invalid Input**
    - Test with an incorrect manifest path and verify `InvalidParameterValueException` is raised
    - Test with a bucket QuickSight has no access to and verify `AccessDeniedException` is raised
    - **Validates: Requirements 1.4**

- [ ] 4. Checkpoint - Validate Data Pipeline
  - Confirm the S3 bucket contains `data/sales_data.csv` and `manifests/sales_manifest.json`
  - Confirm QuickSight is provisioned and accessible in the AWS Console
  - Confirm the data source appears in QuickSight → Datasets → Data sources with a successful status
  - Run `describe_data_source()` programmatically and verify `Status` is `CREATION_SUCCESSFUL`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Dataset Creation, SPICE Import, and Calculated Fields
  - [ ] 5.1 Create dataset and import into SPICE
    - Implement `create_dataset(aws_account_id, dataset_id, dataset_name, data_source_id, columns, import_mode)` in `QuickSightDataManager`
    - Define `ColumnDefinition` list matching the CSV schema: `order_id: STRING`, `order_date: DATETIME`, `region: STRING`, `category: STRING`, `product_name: STRING`, `quantity: INTEGER`, `unit_price: DECIMAL`, `revenue: DECIMAL`, `cost: DECIMAL`, `customer_segment: STRING`
    - Set `import_mode='SPICE'` to trigger in-memory import
    - Implement `check_ingestion_status(aws_account_id, dataset_id, ingestion_id)` using `describe_ingestion()` to poll until status is `COMPLETED`
    - Implement `describe_dataset(aws_account_id, dataset_id)` to verify dataset metadata and SPICE consumption
    - Handle `LimitExceededException` by notifying about SPICE capacity limits
    - Verify: dataset shows as imported in QuickSight console and `describe_dataset()` returns expected column count
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - [ ] 5.2 Add calculated fields for data enrichment
    - Implement `add_calculated_field(aws_account_id, dataset_id, field_name, expression)` using `update_dataset()` API to add calculated fields to the existing dataset's logical table map
    - Create calculated field `profit` with expression `{revenue} - {cost}` (arithmetic)
    - Create calculated field `profit_margin` with expression `({revenue} - {cost}) / {revenue} * 100` (arithmetic)
    - Create calculated field `order_year` with expression `extract('YYYY', {order_date})` (date function)
    - Create calculated field `revenue_tier` with expression `ifelse({revenue} >= 1000, 'High', {revenue} >= 500, 'Medium', 'Low')` (conditional/string)
    - Test with an invalid expression (e.g., referencing non-existent field `{fake_field}`) and verify validation error is returned
    - Verify: open dataset in QuickSight console and confirm calculated fields appear in the field list
    - _Requirements: 3.1, 3.2, 3.3_
  - [ ] 5.3 Implement cleanup functions for data source and dataset
    - Implement `delete_data_source(aws_account_id, data_source_id)` using `delete_data_source()` API
    - Implement `delete_dataset(aws_account_id, dataset_id)` using `delete_dataset()` API
    - Handle `ResourceNotFoundException` gracefully for idempotent cleanup
    - Verify: test delete on a temporary test resource; confirm it no longer appears in `describe_*` calls
    - _Requirements: 2.1, 1.3_

- [ ] 6. Build Interactive Analysis with Multiple Visualization Types
  - [ ] 6.1 Create analysis and build core visuals (Console)
    - In QuickSight console, click "New analysis" and select the dataset created in Task 5
    - Create a **bar chart**: assign `category` to X-axis and `revenue` (Sum) to Value — shows revenue by product category
    - Create a **line chart**: assign `order_date` to X-axis (aggregated by Month) and `revenue` (Sum) to Value — shows revenue trend over time
    - Create a **pie chart**: assign `region` to Group/Color and `revenue` (Sum) to Value — shows revenue distribution by region
    - Create a **pivot table**: assign `region` and `category` to Rows, `customer_segment` to Columns, and `revenue` (Sum) to Values
    - Arrange and resize visuals across the sheet for a clear layout
    - Verify: each visual renders data correctly; modify a visual's type (e.g., switch bar to horizontal bar) and confirm it re-renders immediately
    - _Requirements: 4.1, 4.2, 4.4_
  - [ ] 6.2 Add KPI widgets and additional visuals (Console)
    - Add a **KPI visual**: set `revenue` (Sum) as the primary value, `cost` (Sum) as the comparison/target metric
    - Verify the KPI widget displays current revenue, trend direction indicator, and progress relative to cost
    - Add a second KPI for `profit_margin` (calculated field) to show average profit margin
    - Add a **donut chart** for `customer_segment` breakdown by revenue
    - Optionally add a second sheet for detailed drill-down views
    - Verify: KPI widget shows trend direction and comparison; all visuals reflect calculated fields correctly
    - _Requirements: 4.2, 4.3, 4.4_

- [ ] 7. Filters, Interactive Controls, and ML-Powered Insights
  - [ ] 7.1 Add filters and interactive controls (Console)
    - Add a **date range filter** on `order_date` scoped to all visuals on the sheet
    - Add a **category filter** (list type) on `region` and add it as a **dropdown control** to the sheet
    - Add a **customer segment filter** as a **search box control** so viewers can type to filter
    - Configure the region filter to apply only to the bar chart and pie chart (visual-specific scoping); verify the line chart remains unfiltered when region is changed
    - Apply multiple filters simultaneously (e.g., date range + region) and verify visuals show only data matching all active conditions
    - Verify: interactive controls appear on the sheet; selecting a filter value updates scoped visuals dynamically
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 7.2 Enable ML-powered forecasting and insights (Console)
    - On the time-series line chart (revenue by month), click "Add forecast" — configure forecast periods (e.g., 3 months forward) with confidence intervals
    - Verify: the line chart extends beyond existing data with projected values and a shaded confidence band
    - Enable **anomaly detection** on the time-series visual: go to Insights → Anomaly detection and configure for the revenue metric
    - Verify: anomalous data points are highlighted on the visual
    - Add an **auto-narrative insight** widget to the analysis: click "Add insight" and select narrative
    - Verify: the narrative generates a natural language summary describing trends, outliers, or notable changes in the data
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 8. Checkpoint - Validate Analysis
  - Open the analysis in QuickSight console and verify it contains: bar chart, line chart, pie chart, pivot table, KPI widgets, and at least one additional visual
  - Confirm all calculated fields (`profit`, `profit_margin`, `order_year`, `revenue_tier`) are used in at least one visual
  - Test interactive filter controls: change region dropdown and date range; verify scoped visuals update correctly
  - Confirm the forecast extends the line chart with projected data points and confidence intervals
  - Confirm anomaly detection highlights are visible and auto-narrative provides a text summary
  - Note the analysis ARN from the QuickSight console (needed for dashboard publishing)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Publish Dashboard and Share
  - [ ] 9.1 Implement DashboardManager component
    - Create file `components/dashboard_manager.py`
    - Initialize `boto3.client('quicksight')` in the constructor
    - Implement `create_template_from_analysis(aws_account_id, template_id, template_name, analysis_arn, dataset_references)` using `create_template()` API with a `SourceAnalysis` containing the analysis ARN and `DatasetReference` list
    - Implement `create_dashboard(aws_account_id, dashboard_id, dashboard_name, template_arn, dataset_references)` using `create_dashboard()` API with the template ARN and `DashboardPublishOptions` enabling `AdHocFilteringOption` and `ExportToCSVOption`
    - Implement `describe_dashboard(aws_account_id, dashboard_id)` to check dashboard creation status
    - Implement `list_dashboards(aws_account_id)` using `list_dashboards()` API
    - Run template creation followed by dashboard creation; poll `describe_dashboard()` until status is `CREATION_SUCCESSFUL`
    - Verify: dashboard appears in QuickSight console under Dashboards with all visuals, filters, and layout preserved
    - _Requirements: 7.1, 7.2_
  - [ ] 9.2 Share, update, and manage dashboard
    - Implement `share_dashboard(aws_account_id, dashboard_id, principal_id)` using `update_dashboard_permissions()` to grant `quicksight:DescribeDashboard` and `quicksight:QueryDashboard` actions to the specified principal ARN
    - Implement `update_dashboard(aws_account_id, dashboard_id, template_arn, dataset_references)` using `update_dashboard()` API for republishing after analysis changes
    - Implement `delete_dashboard(aws_account_id, dashboard_id)` and `delete_template(aws_account_id, template_id)` for cleanup
    - Handle `ResourceNotFoundException`, `ConflictException`, and `ResourceExistsException` appropriately
    - Test sharing: share the dashboard with another QuickSight user (or your own reader role) and verify they can view and interact with filters
    - Test update: make a small change in the analysis, create a new template version, update the dashboard, and verify changes are reflected
    - Verify: open the dashboard as a viewer; confirm filters and drill-downs work; confirm filter selections are session-scoped and do not persist across viewers
    - _Requirements: 7.2, 7.3, 7.4_
  - [ ]* 9.3 Validate dashboard isolation and read-only properties
    - **Property 2: Dashboard Viewer Session Isolation**
    - Open the dashboard in two separate browser sessions; apply different filter selections in each; confirm each session's filters are independent
    - Confirm the dashboard is read-only: viewers cannot modify visuals, add new charts, or alter the underlying analysis
    - **Validates: Requirements 7.1, 7.4**

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete QuickSight resources
    - Delete the dashboard: run `delete_dashboard(aws_account_id, dashboard_id)`
    - Delete the template: run `delete_template(aws_account_id, template_id)`
    - Delete the dataset: run `delete_dataset(aws_account_id, dataset_id)`
    - Delete the data source: run `delete_data_source(aws_account_id, data_source_id)`
    - Verify: `list_dashboards()` no longer includes the deleted dashboard; `describe_dataset()` and `describe_data_source()` return `ResourceNotFoundException`
    - _Requirements: (all)_
  - [ ] 10.2 Delete S3 resources and optionally unsubscribe QuickSight
    - Delete S3 objects: `aws s3 rm s3://<your-qs-data-bucket>/ --recursive`
    - Delete S3 bucket: `aws s3 rb s3://<your-qs-data-bucket>`
    - Verify bucket is deleted: `aws s3 ls s3://<your-qs-data-bucket>` should return an error
    - **Optional**: If you no longer need QuickSight, unsubscribe via Manage QuickSight → Account settings → Delete QuickSight to avoid ongoing per-user charges
    - **Warning**: QuickSight charges per-user/month even on Standard edition — unsubscribe if this was only for learning
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Tasks 6 and 7 are primarily performed in the QuickSight console (visual builder) since chart creation, filter controls, and ML insights are console-driven features — the design doc acknowledges this hybrid approach
- The QuickSight analysis ARN is obtained from the console and must be passed to the DashboardManager for template and dashboard creation
- SPICE capacity on the Standard and Enterprise editions includes 10 GB per author user — the 5000-record sample dataset is well within this limit
- All seven requirements are covered: Req 1 (Task 3), Req 2 (Task 5.1), Req 3 (Task 5.2), Req 4 (Task 6), Req 5 (Task 7.1), Req 6 (Task 7.2), Req 7 (Task 9)
