

# Requirements Document

## Introduction

This project guides learners through building a real-time streaming data pipeline using Amazon Kinesis. Streaming data pipelines are foundational to modern data architectures, enabling organizations to process and analyze data as it arrives rather than waiting for batch collection cycles. Use cases range from real-time analytics dashboards and IoT telemetry processing to fraud detection and live application monitoring.

The learner will construct an end-to-end pipeline that ingests simulated streaming data into Amazon Kinesis Data Streams, processes and transforms that data using Amazon Managed Service for Apache Flink, delivers results to Amazon S3 via Amazon Data Firehose for persistent storage, and makes the stored data queryable using AWS Glue Data Catalog and Amazon Athena. This progression mirrors real-world streaming architectures and teaches the learner how each service fits into the pipeline.

By completing this project, the learner will gain hands-on experience with streaming ingestion, real-time processing with windowed aggregations, delivery to a data lake, and ad-hoc querying of streaming results — core competencies for data engineering and real-time analytics on AWS.

## Glossary

- **data_stream**: A Kinesis Data Streams resource composed of shards that durably stores streaming records for a configurable retention period, acting as a buffer between producers and consumers.
- **shard**: A unit of capacity within a Kinesis data stream that determines the throughput for both data ingestion and consumption.
- **record**: A unit of data stored in a Kinesis data stream, consisting of a partition key, sequence number, and data blob.
- **partition_key**: A value used to distribute records across shards within a stream, determining which shard a given record is assigned to.
- **data_producer**: An application or script that puts records into a Kinesis data stream for downstream processing.
- **delivery_stream**: An Amazon Data Firehose resource that captures, optionally transforms, and delivers streaming data to a specified AWS destination such as Amazon S3.
- **tumbling_window**: A fixed-duration, non-overlapping time window used in stream processing to group and aggregate records that arrive within each window interval.
- **streaming_analytics_application**: A Managed Service for Apache Flink application that reads from a streaming source, performs real-time transformations or aggregations, and writes results to a destination.
- **data_catalog**: An AWS Glue metadata store that maintains table definitions and schemas, making data in S3 queryable by services like Amazon Athena.

## Requirements

### Requirement 1: Kinesis Data Stream Provisioning

**User Story:** As a streaming data learner, I want to create and configure a Kinesis data stream with appropriate capacity settings, so that I have a durable ingestion layer to receive real-time records.

#### Acceptance Criteria

1. WHEN the learner creates a Kinesis data stream with a specified name and shard count, THE stream SHALL transition to an active status and be ready to accept records.
2. THE data stream SHALL be configured with a retention period greater than the default 24 hours (e.g., 48 hours) so the learner can observe how retention affects record availability.
3. IF the learner specifies a stream name that already exists in the same account and region, THEN THE service SHALL return an error and the existing stream SHALL remain unchanged.

### Requirement 2: Streaming Data Ingestion

**User Story:** As a streaming data learner, I want to produce and send records into my Kinesis data stream from a simulated data source, so that I understand how streaming producers push data into an ingestion layer.

#### Acceptance Criteria

1. WHEN the learner sends records to the active data stream with valid partition keys, THE records SHALL be accepted and assigned sequence numbers confirming successful ingestion.
2. THE producer SHALL distribute records across shards by using varied partition key values so the learner can observe how partition keys affect shard distribution.
3. WHEN the learner sends a batch of multiple records in a single request, THE stream SHALL accept all valid records and report the shard assignment for each.
4. IF the learner sends records at a rate that exceeds the shard's write capacity, THEN THE service SHALL throttle the requests, allowing the learner to observe capacity-based back-pressure behavior.

### Requirement 3: Real-Time Stream Processing with Managed Service for Apache Flink

**User Story:** As a streaming data learner, I want to create a Managed Service for Apache Flink application that reads from my Kinesis data stream and performs time-windowed aggregations, so that I can transform raw streaming data into summarized insights in real time.

#### Acceptance Criteria

1. WHEN the learner deploys a Flink application configured to read from the Kinesis data stream, THE application SHALL continuously consume incoming records and process them without manual polling.
2. THE Flink application SHALL perform a tumbling window aggregation (e.g., counting or summing a field over a fixed time interval) so that the learner observes how streaming data is grouped and summarized over time boundaries.
3. WHEN the Flink application produces aggregated results, THE output SHALL be written to a designated destination stream or delivery mechanism for downstream consumption.
4. IF the Flink application encounters a processing disruption and recovers, THEN THE application SHALL resume from its last checkpoint so that the learner can observe built-in fault tolerance.

### Requirement 4: Data Delivery to Amazon S3 via Amazon Data Firehose

**User Story:** As a streaming data learner, I want to configure an Amazon Data Firehose delivery stream that captures streaming data and delivers it to an S3 bucket, so that I can persist streaming records in a data lake for later analysis.

#### Acceptance Criteria

1. WHEN the learner creates a Firehose delivery stream with a Kinesis data stream as its source and an S3 bucket as its destination, THE delivery stream SHALL automatically read records from the source stream and write them to S3.
2. THE delivery stream SHALL buffer incoming records and deliver them to S3 based on a configurable buffer size or buffer interval (whichever condition is met first), so the learner understands how Firehose batches delivery.
3. THE delivered objects in S3 SHALL be organized using a date-based prefix partitioning structure (e.g., year/month/day/hour) so the learner can observe how streaming data is organized for efficient querying.
4. IF the learner configures the delivery stream to convert record format to a columnar format such as Apache Parquet, THEN THE objects written to S3 SHALL be stored in that format.

### Requirement 5: Data Cataloging with AWS Glue

**User Story:** As a streaming data learner, I want to catalog the streaming data stored in S3 using AWS Glue Data Catalog, so that the data becomes discoverable and queryable by analytics services.

#### Acceptance Criteria

1. WHEN the learner creates and runs an AWS Glue crawler pointed at the S3 location containing delivered streaming data, THE crawler SHALL discover the data schema and create a corresponding table definition in the Glue Data Catalog.
2. THE catalog table SHALL accurately reflect the column names and data types of the streaming records so that downstream query engines can interpret the data correctly.
3. WHEN new data is delivered to S3 by the Firehose delivery stream and the crawler runs again, THE catalog table SHALL be updated to include any new partitions without losing existing metadata.

### Requirement 6: Ad-Hoc Querying with Amazon Athena

**User Story:** As a streaming data learner, I want to query my streamed and cataloged data using Amazon Athena, so that I can perform SQL-based analysis on data that originated from a real-time pipeline.

#### Acceptance Criteria

1. WHEN the learner runs a SQL query in Athena referencing the Glue Data Catalog table, THE query SHALL execute against the underlying S3 data and return results matching the query criteria.
2. THE learner SHALL be able to run aggregation queries (e.g., GROUP BY, COUNT, SUM) that produce summarized views of the streaming data, confirming that the full pipeline from ingestion to analysis is functional.
3. IF the learner applies a partition filter (e.g., filtering by date partition) in the query, THEN Athena SHALL scan only the relevant S3 partitions, allowing the learner to observe partition pruning behavior through reduced data scanned.

### Requirement 7: Pipeline Monitoring with Amazon CloudWatch

**User Story:** As a streaming data learner, I want to monitor the health and throughput of my streaming pipeline using Amazon CloudWatch, so that I understand how to observe and troubleshoot a real-time data system.

#### Acceptance Criteria

1. WHEN data is flowing through the Kinesis data stream, THE learner SHALL be able to view stream-level CloudWatch metrics such as incoming records count and incoming bytes to confirm ingestion activity.
2. WHEN the Firehose delivery stream is active, THE learner SHALL be able to view delivery-level CloudWatch metrics such as delivery success counts and delivery-to-S3 data freshness to confirm data is reaching the destination.
3. THE learner SHALL create at least one CloudWatch alarm on a pipeline metric (e.g., iterator age on the data stream exceeding a threshold) so that the learner understands how to detect pipeline lag or processing delays.
