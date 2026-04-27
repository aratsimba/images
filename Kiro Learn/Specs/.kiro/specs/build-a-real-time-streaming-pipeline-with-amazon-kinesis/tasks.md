

# Implementation Plan: Real-time Streaming Pipeline with Amazon Kinesis

## Overview

This implementation plan guides you through building an end-to-end real-time streaming data pipeline on AWS using Amazon Kinesis Data Streams for ingestion, Managed Service for Apache Flink for real-time processing, Amazon Data Firehose for delivery to S3, AWS Glue for cataloging, and Amazon Athena for ad-hoc querying. The pipeline follows the standard streaming architecture pattern: produce → ingest → process → deliver → catalog → query, with CloudWatch providing observability throughout.

The implementation progresses through four phases. First, we provision the foundational infrastructure — Kinesis streams, S3 bucket, and Firehose delivery stream. Second, we build the data producer and verify ingestion into the raw stream. Third, we deploy the Apache Flink application for tumbling-window aggregations and connect the processed output through Firehose to S3. Fourth, we catalog the delivered data with AWS Glue and query it with Athena, then add CloudWatch monitoring. Each phase builds on the previous one, and checkpoints validate the pipeline at critical integration points.

Key dependencies dictate the task ordering: the Kinesis Data Streams must exist before the producer can send data; the S3 bucket and Glue database must exist before Firehose can deliver with Parquet conversion; Flink requires both the input and output streams; and Athena queries depend on Glue having cataloged the S3 data. IAM roles for Firehose, Flink, and Glue are created as part of the provisioning tasks since the design uses programmatic boto3-based setup rather than infrastructure-as-code frameworks.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for Kinesis, Firehose, Flink (KinesisAnalyticsV2), S3, Glue, Athena, CloudWatch, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`; verify: `python3 -c "import boto3; print(boto3.__version__)"`
    - Create project directory structure: `mkdir -p components flink_app` and create `__init__.py` files
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Verify Kinesis shard limits: `aws kinesis describe-limits`
    - Create IAM roles for Firehose (S3 write, Glue access), Flink (Kinesis read/write, S3 read), and Glue Crawler (S3 read, Glue catalog write) — note the ARNs for later use
    - Confirm Athena query result S3 location is available (e.g., `s3://your-athena-results-bucket/`)
    - _Requirements: (all)_

- [ ] 2. Provision Streaming Infrastructure
  - [ ] 2.1 Implement StreamProvisioner module
    - Create `components/stream_provisioner.py` with `StreamProvisioner` class
    - Implement `create_data_stream(stream_name, shard_count, retention_hours)` using `boto3.client('kinesis').create_stream()` and `increase_stream_retention_period()` for retention > 24 hours
    - Implement `wait_stream_active(stream_name)` using a polling loop on `describe_stream()` until StreamStatus is ACTIVE
    - Implement `describe_stream(stream_name)` to return stream details including ARN, shard count, and retention period
    - Implement `delete_data_stream(stream_name)` using `delete_stream()`
    - Implement `create_s3_bucket(bucket_name)` using `boto3.client('s3').create_bucket()`
    - Implement `create_delivery_stream(delivery_stream_name, source_stream_arn, s3_bucket_arn, buffer_seconds, buffer_mb, parquet_enabled, glue_database, glue_table)` using `boto3.client('firehose').create_delivery_stream()` with `KinesisStreamSourceConfiguration`, `ExtendedS3DestinationConfiguration` (including `Prefix` with date-based partitioning `year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/`), and optional `DataFormatConversionConfiguration` for Parquet
    - Implement `delete_delivery_stream(delivery_stream_name)`
    - _Requirements: 1.1, 1.2, 1.3, 4.1, 4.2, 4.3, 4.4_
  - [ ] 2.2 Provision raw and aggregated Kinesis Data Streams
    - Create the raw data stream (e.g., `streaming-pipeline-raw`) with 2 shards and 48-hour retention
    - Create the aggregated output stream (e.g., `streaming-pipeline-aggregated`) with 1 shard and 48-hour retention
    - Wait for both streams to become ACTIVE
    - Verify: `aws kinesis describe-stream-summary --stream-name streaming-pipeline-raw` confirms ACTIVE status and 48-hour retention
    - Test that creating a stream with a duplicate name raises `ResourceInUseException`
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.3 Provision S3 bucket and Firehose delivery stream
    - Create the S3 destination bucket (e.g., `streaming-pipeline-data-<account-id>`)
    - Create a Glue database (needed for Parquet conversion schema reference — create early via `boto3.client('glue').create_database()`)
    - Create the Firehose delivery stream sourced from the aggregated Kinesis stream, targeting S3 with buffer interval of 60 seconds, buffer size of 1 MB, Parquet conversion enabled, and date-based prefix partitioning
    - Verify: `aws firehose describe-delivery-stream --delivery-stream-name streaming-pipeline-firehose` confirms ACTIVE status
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1_

- [ ] 3. Build Data Producer and Ingest Records
  - [ ] 3.1 Implement StreamProducer module
    - Create `components/stream_producer.py` with `StreamProducer` class
    - Define the `StreamRecord` data model with fields: `event_id` (UUID), `event_type` (random from "click", "purchase", "pageview"), `user_id`, `amount` (random float), `timestamp` (ISO 8601), and optional `metadata` dict
    - Implement `generate_record(record_type)` to create a `StreamRecord` with randomized values
    - Implement `put_record(stream_name, record, partition_key)` using `kinesis.put_record()` — return response with `ShardId` and `SequenceNumber`
    - Implement `put_record_batch(stream_name, records, partition_keys)` using `kinesis.put_records()` — return per-record shard assignments and any failed record counts
    - Implement `run_continuous_producer(stream_name, records_per_second, duration_seconds)` that sends records with varied partition keys (e.g., rotating user IDs) and returns a `ProducerSummary` with `total_records_sent`, `successful_count`, `failed_count`, `throttled_count`, `duration_seconds`, and `records_per_shard` mapping
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  - [ ] 3.2 Run data ingestion and verify shard distribution
    - Send individual records with `put_record()` and confirm sequence numbers are returned
    - Send a batch of 10+ records with `put_record_batch()` using varied partition keys; verify shard assignments differ across records
    - Run the continuous producer at a moderate rate (e.g., 5 records/second for 60 seconds) and review the `ProducerSummary` for shard distribution
    - Optionally increase the rate beyond shard capacity (1 MB/s or 1000 records/s per shard) to observe `ProvisionedThroughputExceededException` throttling
    - Verify: `aws kinesis get-shard-iterator` and `get-records` to confirm records are in the stream
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Checkpoint - Validate Ingestion Layer
  - Confirm both Kinesis streams are ACTIVE: `aws kinesis list-streams`
  - Confirm Firehose delivery stream is ACTIVE: `aws firehose list-delivery-streams`
  - Verify records exist in the raw stream by consuming with `get-records`
  - Verify the S3 bucket exists: `aws s3 ls s3://streaming-pipeline-data-<account-id>/`
  - Confirm the `ProducerSummary` shows records distributed across multiple shards
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Deploy Real-Time Flink Processing Application
  - [ ] 5.1 Create Flink SQL application code
    - Create `flink_app/streaming_aggregation.sql` with a Flink SQL application that:
      - Defines a source table reading from the raw Kinesis stream (JSON format, `event_type`, `amount`, `timestamp` columns)
      - Defines a sink table writing to the aggregated Kinesis stream (JSON format)
      - Performs a tumbling window aggregation: `SELECT window_start, window_end, event_type, COUNT(*) as record_count, SUM(amount) as total_amount FROM source_table GROUP BY TUMBLE(event_timestamp, INTERVAL '1' MINUTE), event_type`
    - Package the SQL file into a zip archive: `flink_app/streaming_aggregation.zip`
    - This output matches the `FlinkWindowAggregation` data model: `window_start`, `window_end`, `event_type`, `record_count`, `total_amount`
    - _Requirements: 3.1, 3.2, 3.3_
  - [ ] 5.2 Implement FlinkAppManager module
    - Create `components/flink_app_manager.py` with `FlinkAppManager` class
    - Implement `upload_application_code(bucket_name, code_key, local_path)` to upload the zip to S3
    - Implement `create_flink_application(app_name, role_arn, code_bucket, code_key, input_stream_arn, output_stream_arn)` using `kinesisanalyticsv2.create_application()` with `FLINK-1_18` runtime, `STREAMING` application mode, S3 code content, and Kinesis input/output configurations
    - Implement `start_application(app_name)` using `start_application()` with the latest snapshot
    - Implement `stop_application(app_name)`, `describe_application(app_name)`, and `delete_application(app_name)`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [ ] 5.3 Deploy and start the Flink application
    - Upload application code to S3 using `upload_application_code()`
    - Create the Flink application targeting the raw stream as input and the aggregated stream as output
    - Start the application and wait for RUNNING status via `describe_application()`
    - Run the continuous producer for 3–5 minutes to generate data for aggregation
    - Verify: `aws kinesisanalyticsv2 describe-application --application-name <app-name>` shows RUNNING
    - Consume records from the aggregated stream to confirm tumbling window outputs contain `window_start`, `window_end`, `event_type`, `record_count`, and `total_amount`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 6. Checkpoint - Validate Processing and Delivery
  - Confirm Flink application is RUNNING and consuming from the raw stream
  - Verify aggregated records appear in the aggregated Kinesis stream
  - Wait for Firehose buffer interval to elapse and check S3 for delivered objects: `aws s3 ls s3://streaming-pipeline-data-<account-id>/ --recursive`
  - Confirm S3 objects are organized with date-based prefix partitioning (year/month/day/hour)
  - If Parquet conversion is enabled, download a sample file and confirm it is in Parquet format
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Catalog Data with AWS Glue and Query with Amazon Athena
  - [ ] 7.1 Implement GlueCatalogManager module
    - Create `components/glue_catalog_manager.py` with `GlueCatalogManager` class
    - Implement `create_database(database_name)` using `glue.create_database()` (may already exist from task 2.3 — handle `AlreadyExistsException` gracefully)
    - Implement `create_crawler(crawler_name, role_arn, database_name, s3_target_path)` using `glue.create_crawler()` with the S3 target pointing to the Firehose output prefix
    - Implement `start_crawler(crawler_name)` and `wait_crawler_ready(crawler_name)` with polling until crawler state is READY
    - Implement `get_table(database_name, table_name)` and `list_tables(database_name)` to inspect discovered schemas
    - Implement `delete_crawler(crawler_name)` and `delete_database(database_name)`
    - _Requirements: 5.1, 5.2, 5.3_
  - [ ] 7.2 Run crawler and verify catalog table
    - Create and run the Glue crawler against the S3 delivery location
    - Wait for the crawler to complete and verify a table is created in the Glue Data Catalog
    - Inspect the table schema with `get_table()` — confirm column names and data types match the `FlinkWindowAggregation` model (or raw record schema)
    - Run the producer again to generate more data, wait for Firehose delivery, re-run the crawler, and confirm new partitions are added without losing existing metadata
    - _Requirements: 5.1, 5.2, 5.3_
  - [ ] 7.3 Implement AthenaQueryRunner module
    - Create `components/athena_query_runner.py` with `AthenaQueryRunner` class
    - Implement `configure_output(s3_output_location)` to set the Athena query results location
    - Implement `run_query(database_name, query_sql)` using `athena.start_query_execution()` and poll `get_query_execution()` until SUCCEEDED; return `QueryResult` with `rows`, `column_names`, `data_scanned_bytes`, `execution_time_ms`
    - Implement `get_query_status(query_execution_id)` and `get_query_results(query_execution_id)` using `athena.get_query_results()`
    - Implement `run_aggregation_query(database_name, table_name, group_by_column, agg_function, agg_column)` to build and execute a `SELECT group_by_column, agg_function(agg_column) FROM table GROUP BY group_by_column` query
    - Implement `run_partition_filtered_query(database_name, table_name, partition_filter, select_columns)` that adds `WHERE` clauses from partition filter keys (e.g., `year='2024' AND month='01'`)
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ] 7.4 Execute Athena queries and validate results
    - Run a basic `SELECT * FROM <table> LIMIT 10` query and confirm results are returned from S3 data
    - Run an aggregation query (e.g., `SELECT event_type, COUNT(*), SUM(total_amount) FROM <table> GROUP BY event_type`) and verify summarized output
    - Run a partition-filtered query with a date filter and compare `data_scanned_bytes` against the unfiltered query to observe partition pruning
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 8. Implement Pipeline Monitoring
  - [ ] 8.1 Implement PipelineMonitor module
    - Create `components/pipeline_monitor.py` with `PipelineMonitor` class
    - Implement `get_stream_metrics(stream_name, metric_name, period_seconds, minutes_back)` using `cloudwatch.get_metric_statistics()` with namespace `AWS/Kinesis` — support metrics like `IncomingRecords`, `IncomingBytes`, `GetRecords.IteratorAgeMilliseconds`
    - Implement `get_firehose_metrics(delivery_stream_name, metric_name, period_seconds, minutes_back)` with namespace `AWS/Firehose` — support metrics like `DeliveryToS3.Records`, `DeliveryToS3.DataFreshness`
    - Implement `create_iterator_age_alarm(alarm_name, stream_name, threshold_ms)` using `cloudwatch.put_metric_alarm()` on `GetRecords.IteratorAgeMilliseconds`
    - Implement `describe_alarm(alarm_name)` and `delete_alarm(alarm_name)`
    - _Requirements: 7.1, 7.2, 7.3_
  - [ ] 8.2 View metrics and create alarm
    - Retrieve and display Kinesis stream metrics (`IncomingRecords`, `IncomingBytes`) to confirm ingestion activity
    - Retrieve and display Firehose metrics (`DeliveryToS3.Records`, `DeliveryToS3.DataFreshness`) to confirm delivery health
    - Create a CloudWatch alarm on iterator age exceeding 60000 ms (1 minute) for the raw stream
    - Verify alarm creation: `aws cloudwatch describe-alarms --alarm-names streaming-pipeline-iterator-age-alarm`
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 9. Checkpoint - Validate End-to-End Pipeline
  - Run the continuous producer for 2–3 minutes to push fresh data through the entire pipeline
  - Confirm Flink processes and outputs aggregated records to the aggregated stream
  - Confirm Firehose delivers new objects to S3
  - Re-run the Glue crawler and verify new partitions appear
  - Execute an Athena aggregation query on the latest data and confirm results
  - Verify CloudWatch metrics show recent activity for both the Kinesis stream and Firehose delivery stream
  - Confirm the CloudWatch alarm is in OK or ALARM state (not INSUFFICIENT_DATA with active data flowing)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Stop and delete processing resources
    - Stop the Flink application: call `stop_application(app_name)` and wait for READY status
    - Delete the Flink application: call `delete_application(app_name)`
    - Delete the Flink application code from S3: `aws s3 rm s3://<bucket>/flink_app/streaming_aggregation.zip`
    - Delete the CloudWatch alarm: `aws cloudwatch delete-alarms --alarm-names streaming-pipeline-iterator-age-alarm`
    - _Requirements: (all)_
  - [ ] 10.2 Delete delivery and ingestion resources
    - Delete the Firehose delivery stream: `aws firehose delete-delivery-stream --delivery-stream-name streaming-pipeline-firehose`
    - Delete the aggregated Kinesis stream: `aws kinesis delete-stream --stream-name streaming-pipeline-aggregated --enforce-consumer-deletion`
    - Delete the raw Kinesis stream: `aws kinesis delete-stream --stream-name streaming-pipeline-raw --enforce-consumer-deletion`
    - _Requirements: (all)_
  - [ ] 10.3 Delete catalog, storage, and IAM resources
    - Delete the Glue crawler: `aws glue delete-crawler --name streaming-pipeline-crawler`
    - Delete the Glue table(s): `aws glue delete-table --database-name streaming-pipeline-db --name <table-name>`
    - Delete the Glue database: `aws glue delete-database --name streaming-pipeline-db`
    - Empty and delete the S3 data bucket: `aws s3 rb s3://streaming-pipeline-data-<account-id> --force`
    - Empty and delete the Athena results bucket if created: `aws s3 rb s3://your-athena-results-bucket --force`
    - Delete IAM roles created for Firehose, Flink, and Glue (detach policies first, then delete roles)
    - Verify cleanup: `aws kinesis list-streams`, `aws firehose list-delivery-streams`, `aws s3 ls`, `aws glue get-databases`
    - **Warning**: Kinesis Data Streams, Firehose, and Flink applications incur hourly charges while active — confirm all are deleted
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key integration points
- The Flink application requires both the raw and aggregated Kinesis streams to be ACTIVE before deployment — task ordering enforces this dependency
- Firehose Parquet conversion requires a Glue table schema reference, which is why the Glue database is created early in task 2.3
- IAM roles must be created in the prerequisites with appropriate trust policies for each service (firehose.amazonaws.com, kinesisanalytics.amazonaws.com, glue.amazonaws.com)
- Allow 1–2 minutes after Firehose delivery stream creation before expecting S3 objects, as buffering interval must elapse
