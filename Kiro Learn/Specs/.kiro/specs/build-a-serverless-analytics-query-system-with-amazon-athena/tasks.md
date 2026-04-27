

# Implementation Plan: Serverless Analytics Query System with Amazon Athena

## Overview

This implementation builds a serverless analytics query system using Amazon Athena, Amazon S3, and AWS Glue Data Catalog. The project follows a progressive approach: first establishing the S3 data lake foundation with sample sales data in both CSV and Parquet formats, then defining schema metadata in the Glue Data Catalog, executing interactive SQL queries through Athena, and finally layering on optimization and governance features including partitioning, workgroups, saved queries, and IAM access controls.

The implementation is organized into logical phases. Phase one covers environment setup and the S3 data lake with data uploads. Phase two builds the Glue Data Catalog with database and table definitions. Phase three focuses on core Athena querying capabilities. Phase four adds partitioning for cost optimization, workgroup configuration for cost control, saved queries for reusability, and IAM-based access control. Each phase builds on the previous, with checkpoints to validate end-to-end functionality at key milestones.

All five components from the design — DataLakeManager, CatalogManager, QueryEngine, WorkgroupManager, and AccessController — are implemented as Python modules using boto3. The project uses a realistic sales dataset (SalesRecord model) to demonstrate analytical queries. Dependencies flow naturally: S3 data must exist before Glue tables can reference it, Glue tables must exist before Athena can query them, and workgroups must be created before queries can be scoped to them.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for S3, Glue, Athena, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python --version`
    - Install dependencies: `pip install boto3 pyarrow`
    - Verify boto3: `python -c "import boto3; print(boto3.__version__)"`
    - Verify pyarrow: `python -c "import pyarrow; print(pyarrow.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 Project Structure and Region Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Create project directory structure: `mkdir -p components data`
    - Create `components/__init__.py` for the Python package
    - Define sample SalesRecord data in `data/sample_sales.py` with fields: order_id, order_date, region, product_category, product_name, quantity, unit_price, total_amount
    - Generate at least 50 sample records spanning multiple months (e.g., 2024-01 through 2024-04) and regions (e.g., us-east, us-west, eu-west)
    - _Requirements: (all)_

- [ ] 2. S3 Data Lake Storage and Data Upload
  - [ ] 2.1 Implement DataLakeManager component
    - Create `components/data_lake_manager.py` with class DataLakeManager
    - Initialize with `boto3.client('s3')` and import `pyarrow` for Parquet support
    - Implement `create_data_bucket(bucket_name)`: create S3 bucket with `BlockPublicAccess` set to block all public access; return bucket name
    - Implement `configure_query_result_location(bucket_name, result_prefix)`: return the full S3 URI `s3://bucket_name/result_prefix/` for Athena query results
    - Implement `upload_csv_data(bucket_name, prefix, file_path)`: upload a local CSV file to S3 under the specified prefix; return S3 key
    - Implement `generate_and_upload_parquet(bucket_name, prefix, records)`: convert list of dictionaries to Parquet using pyarrow and upload to S3; return S3 key
    - Implement `upload_partitioned_data(bucket_name, base_prefix, partition_column, records, file_format)`: organize records into partition-compatible prefix structure (e.g., `base_prefix/order_date=2024-01/data.csv`), upload files per partition; return list of S3 prefixes
    - Implement `list_objects_under_prefix(bucket_name, prefix)`: list all object keys under a given S3 prefix; return list of keys
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 4.1_
  - [ ] 2.2 Create S3 bucket and upload sample data
    - Run a script that calls `create_data_bucket()` to create the analytics bucket with Block Public Access enabled
    - Generate sample sales CSV file from sample data and upload via `upload_csv_data()` to prefix `raw-data/csv/sales/`
    - Generate and upload Parquet version via `generate_and_upload_parquet()` to prefix `raw-data/parquet/sales/`
    - Call `configure_query_result_location()` with prefix `athena-results/` to prepare the query result path
    - Upload partitioned data via `upload_partitioned_data()` to prefix `raw-data/partitioned/sales/` partitioned by `order_date`
    - Verify uploads: call `list_objects_under_prefix()` for each prefix and confirm files exist
    - Verify Block Public Access: `aws s3api get-public-access-block --bucket <bucket-name>`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 4.1_

- [ ] 3. AWS Glue Data Catalog - Database and Table Definitions
  - [ ] 3.1 Implement CatalogManager component
    - Create `components/catalog_manager.py` with class CatalogManager
    - Initialize with `boto3.client('glue')`
    - Define `ColumnDefinition` as a dictionary with `name` and `type` keys
    - Implement `create_database(database_name)`: create a Glue database; return database name
    - Implement `create_external_table(database_name, table_name, columns, s3_location, input_format)`: create an external table using `glue.create_table()` with appropriate SerDe for CSV (`org.apache.hadoop.hive.serde2.OpenCSVSerde`) or Parquet (`org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe`); return table name
    - Implement `create_partitioned_table(database_name, table_name, columns, partition_keys, s3_location, input_format)`: create a partitioned external table with partition key columns; return table name
    - Implement `add_partitions(database_name, table_name, partitions)`: call `glue.batch_create_partition()` with list of PartitionInput (values + s3_location)
    - Implement `update_table_add_column(database_name, table_name, new_column)`: fetch current table via `get_table()`, append column, call `glue.update_table()`
    - Implement `get_table(database_name, table_name)`: return table metadata dictionary
    - Implement `delete_database(database_name, delete_tables)`: delete all tables in database if `delete_tables=True`, then delete database
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.1_
  - [ ] 3.2 Create Glue database and table definitions
    - Call `create_database()` with a descriptive name (e.g., `analytics_db`)
    - Define sales table columns: order_id (string), order_date (string), region (string), product_category (string), product_name (string), quantity (int), unit_price (double), total_amount (double)
    - Call `create_external_table()` for the CSV sales table pointing to `s3://<bucket>/raw-data/csv/sales/`
    - Call `create_external_table()` for the Parquet sales table pointing to `s3://<bucket>/raw-data/parquet/sales/` with input_format `parquet`
    - Call `create_partitioned_table()` for partitioned sales table with partition key `order_date` (string), pointing to `s3://<bucket>/raw-data/partitioned/sales/`
    - Call `add_partitions()` to register each partition (e.g., values=["2024-01"], s3_location=`s3://<bucket>/raw-data/partitioned/sales/order_date=2024-01/`)
    - Verify: call `get_table()` for each table and confirm column definitions and S3 locations
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.1_

- [ ] 4. Checkpoint - Validate Data Lake and Catalog Setup
  - Verify S3 bucket exists with Block Public Access enabled: `aws s3api get-public-access-block --bucket <bucket-name>`
  - Verify CSV, Parquet, and partitioned data files exist: `aws s3 ls s3://<bucket>/raw-data/ --recursive`
  - Verify Glue database appears: `aws glue get-database --name analytics_db`
  - Verify all three tables exist: `aws glue get-tables --database-name analytics_db`
  - Verify partitions loaded: `aws glue get-partitions --database-name analytics_db --table-name <partitioned_table>`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Interactive SQL Querying with Athena
  - [ ] 5.1 Implement QueryEngine component
    - Create `components/query_engine.py` with class QueryEngine
    - Initialize with `boto3.client('athena')`
    - Implement `execute_query(query_sql, database_name, result_location, workgroup)`: call `athena.start_query_execution()` with QueryString, QueryExecutionContext (Database), ResultConfiguration (OutputLocation), and WorkGroup; return query_execution_id
    - Implement `wait_for_query(query_execution_id)`: poll `athena.get_query_execution()` until state is SUCCEEDED, FAILED, or CANCELLED; return QueryResult with status, data_scanned_bytes, execution_time_ms, result_s3_path
    - Implement `get_query_results(query_execution_id)`: call `athena.get_query_results()` with pagination; parse ResultSet rows into list of dictionaries; return results
    - Implement `get_data_scanned_bytes(query_execution_id)`: extract `DataScannedInBytes` from query execution statistics; return integer
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ] 5.2 Execute analytical queries and compare formats
    - Execute a basic SELECT query against the CSV table: `SELECT * FROM csv_sales LIMIT 10`; verify results are returned from S3 data
    - Execute queries with SQL features: `SELECT region, SUM(total_amount) FROM csv_sales WHERE quantity > 2 GROUP BY region ORDER BY SUM(total_amount) DESC`; verify correct aggregation, filtering, and sorting
    - Verify query results are written to the configured query_result_location in S3: call `list_objects_under_prefix()` on the results prefix
    - Record `data_scanned_bytes` from the CSV query using `get_data_scanned_bytes()`
    - Execute the same query against the Parquet table and record data_scanned_bytes
    - Print comparison: confirm Parquet scans less data than CSV for equivalent queries
    - _Requirements: 1.4, 3.1, 3.2, 3.3, 3.4_
  - [ ]* 5.3 Validate schema mismatch behavior and table update
    - **Property 1: Schema-Data Consistency**
    - Create a table with intentionally mismatched column types or names; execute a query and verify it returns errors or null values for mismatched columns
    - Call `update_table_add_column()` to add a new column to an existing table; execute a query referencing the new column and verify the updated schema is reflected without modifying underlying data
    - **Validates: Requirements 2.3, 2.4**

- [ ] 6. Table Partitioning for Query Optimization
  - [ ] 6.1 Execute partition-optimized queries and compare data scanned
    - Execute a query against the partitioned table with a WHERE clause on the partition column: `SELECT * FROM partitioned_sales WHERE order_date = '2024-01'`; record data_scanned_bytes
    - Execute the same logical query against the unpartitioned CSV table filtering by order_date; record data_scanned_bytes
    - Compare: verify the partitioned query scans significantly less data than the unpartitioned query
    - Execute a query against the partitioned table WITHOUT filtering on the partition column: `SELECT COUNT(*) FROM partitioned_sales`; record data_scanned_bytes
    - Compare with the unpartitioned table full scan: verify data_scanned is comparable, demonstrating that without partition filtering all partitions are scanned
    - Print a summary table showing data_scanned_bytes for each scenario
    - _Requirements: 4.1, 4.2, 4.3_

- [ ] 7. Checkpoint - Validate Querying and Partitioning
  - Execute a fresh analytical query and confirm results are correct and appear in the S3 result location
  - Verify data_scanned_bytes is reported for every query execution
  - Confirm partitioned query with WHERE on partition column scans less data than equivalent unpartitioned query
  - Confirm partitioned query without partition filter scans comparable data to unpartitioned table
  - Confirm Parquet format reduces data_scanned compared to CSV
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Workgroup Configuration and Cost Control
  - [ ] 8.1 Implement WorkgroupManager component
    - Create `components/workgroup_manager.py` with class WorkgroupManager
    - Initialize with `boto3.client('athena')`
    - Implement `create_workgroup(workgroup_name, result_location, encryption_option, per_query_data_limit_mb)`: create workgroup with `ResultConfiguration` (OutputLocation, EncryptionConfiguration if provided), and `BytesScannedCutoffPerQuery` set to `per_query_data_limit_mb * 1024 * 1024`; return workgroup name
    - Implement `get_workgroup(workgroup_name)`: return workgroup configuration dictionary
    - Implement `update_workgroup_limit(workgroup_name, per_query_data_limit_mb)`: update the per-query data scan limit
    - Implement `get_workgroup_metrics(workgroup_name)`: retrieve workgroup usage metrics (note: may require CloudWatch or workgroup query history); return WorkgroupMetrics
    - Implement `list_workgroups()`: return list of workgroup names
    - Implement `delete_workgroup(workgroup_name)`: delete the specified workgroup with `RecursiveDeleteOption=True`
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 8.2 Create workgroups and demonstrate cost controls
    - Create a workgroup (e.g., `analytics-workgroup`) with a designated query_result_location and SSE_S3 encryption
    - Create a second workgroup (e.g., `limited-workgroup`) with a low per-query data scan limit (e.g., 1 MB)
    - Execute a query in `analytics-workgroup`; verify results go to the workgroup's result location
    - Execute a query in `limited-workgroup` that exceeds the 1 MB limit; verify the query is cancelled by polling `wait_for_query()` and confirming the query execution state is `CANCELLED` (Athena cancels the query asynchronously; no exception is raised by `start_query_execution()` itself)
    - Call `update_workgroup_limit()` to increase the limit; re-execute and verify success
    - Call `get_workgroup_metrics()` for each workgroup; verify independent tracking of queries and data scanned
    - Verify switching between workgroups maintains independent query history: call `get_workgroup()` for each and confirm separate configurations
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 9. Saved Queries and Access Control
  - [ ] 9.1 Implement saved query functions in QueryEngine
    - Add `create_named_query(name, description, database_name, query_sql, workgroup)` to QueryEngine: call `athena.create_named_query()`; return named_query_id
    - Add `list_named_queries(workgroup)` to QueryEngine: call `athena.list_named_queries()` with WorkGroup parameter; return list of IDs
    - Add `get_named_query(named_query_id)` to QueryEngine: call `athena.get_named_query()`; return NamedQuery with id, name, description, database, sql, workgroup
    - Add `execute_named_query(named_query_id, result_location)` to QueryEngine: retrieve the named query's SQL, then call `execute_query()` with it; return query_execution_id
    - Create a named query (e.g., "Top Products by Revenue") in `analytics-workgroup`; save and verify it persists via `list_named_queries()`
    - Create a second named query in `limited-workgroup`; verify each named query is associated with its respective workgroup via `list_named_queries()` for each workgroup
    - Execute a saved named query via `execute_named_query()`; verify it returns up-to-date results from current S3 data
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ] 9.2 Implement AccessController component and configure IAM policies
    - Create `components/access_controller.py` with class AccessController
    - Initialize with `boto3.client('iam')`
    - Implement `create_athena_s3_policy(policy_name, allowed_s3_prefixes, result_location)`: create an IAM policy JSON that allows Athena execution (`athena:StartQueryExecution`, `athena:GetQueryExecution`, `athena:GetQueryResults`), Glue catalog read access, S3 read on specified prefixes only, and S3 write on result_location; call `iam.create_policy()`; return policy ARN
    - Implement `create_deny_athena_policy(policy_name)`: create an IAM policy that explicitly denies all Athena actions; return policy ARN
    - Implement `attach_policy_to_user(user_name, policy_arn)`: call `iam.attach_user_policy()`
    - Implement `detach_policy_from_user(user_name, policy_arn)`: call `iam.detach_user_policy()`
    - Implement `delete_policy(policy_arn)`: call `iam.delete_policy()`
    - Create an allow policy restricting S3 access to specific prefixes; verify the policy document grants only the intended S3 paths
    - Create a deny policy; document that attaching it to a user would prevent Athena query execution
    - Verify that S3 data with server-side encryption (SSE-S3 or SSE-KMS) is queryable by Athena when the executing identity has appropriate permissions (reference existing encrypted query results from workgroup setup)
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 10. Checkpoint - Validate Complete Analytics System
  - Verify workgroups are configured with independent result locations and cost controls
  - Test that a query exceeding the per-query scan limit is cancelled
  - Verify named queries are saved, retrievable, executable, and scoped to their workgroups
  - Verify IAM policies are created with correct S3 prefix restrictions and Athena permissions
  - Confirm encrypted data in S3 is queryable through Athena
  - Run a full end-to-end flow: upload data → create table → query via workgroup → save as named query → re-execute
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Delete Athena resources
    - Delete all named queries: retrieve IDs via `list_named_queries()` for each workgroup, then `aws athena delete-named-query --named-query-id <id>` for each
    - Delete workgroups: `aws athena delete-work-group --work-group <name> --recursive-delete-option`
    - _Requirements: (all)_
  - [ ] 11.2 Delete Glue Data Catalog resources
    - Delete all tables in the database: `aws glue delete-table --database-name analytics_db --name <table_name>` for each table
    - Delete the Glue database: `aws glue delete-database --name analytics_db`
    - Alternatively, use `delete_database(database_name, delete_tables=True)` from CatalogManager
    - _Requirements: (all)_
  - [ ] 11.3 Delete S3 and IAM resources
    - Empty and delete the S3 bucket: `aws s3 rb s3://<bucket-name> --force`
    - Detach any IAM policies from test users: `aws iam detach-user-policy --user-name <user> --policy-arn <arn>`
    - Delete IAM policies created for this project: `aws iam delete-policy --policy-arn <arn>`
    - _Requirements: (all)_
  - [ ] 11.4 Verify cleanup
    - Verify S3 bucket is deleted: `aws s3api head-bucket --bucket <bucket-name>` should return an error
    - Verify Glue database is gone: `aws glue get-database --name analytics_db` should return EntityNotFoundException
    - Verify workgroups are deleted: `aws athena list-work-groups` should not list project workgroups
    - Check AWS Cost Explorer for any remaining Athena query charges
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- The sample dataset uses SalesRecord data spanning multiple months and regions to enable meaningful partitioning and aggregation demonstrations
- Athena queries incur costs based on data scanned; the partitioning and Parquet format tasks demonstrate cost reduction strategies
- IAM access control tasks (9.2) create policy documents and verify their structure; full end-to-end IAM testing requires creating a separate test IAM user, which learners can optionally do
- The `primary` workgroup in Athena always exists and cannot be deleted; only custom workgroups created in this project should be cleaned up
