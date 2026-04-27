

# Implementation Plan: DynamoDB Data Model for a Serverless Application

## Overview

This implementation plan guides you through designing and building a single-table DynamoDB data model for an e-commerce serverless application. The approach follows DynamoDB's access-pattern-first methodology: you will first document access patterns, then design composite key structures and indexes to support them, create the table with sample data, validate queries, implement transactions, and finally integrate DynamoDB Streams with a Lambda function for event-driven processing.

The plan is organized into three phases. The first phase covers setup, access pattern documentation, and table creation with sample data (Tasks 1–4). The second phase focuses on querying, transactions, and stream integration (Tasks 5–8). The final phase validates end-to-end functionality and tears down resources (Tasks 9–10). Each phase builds on the previous one, so tasks should be completed in order.

Key dependencies include: the table must exist before loading data, GSIs must be active before querying them, sample data must be loaded before running queries or transactions, and DynamoDB Streams must be enabled before deploying the Lambda trigger. All Python scripts use boto3 and interact directly with DynamoDB — no infrastructure-as-code frameworks are required.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for DynamoDB, Lambda, and IAM
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Install boto3: `pip install boto3`
    - Create project directory structure: `mkdir -p components && touch components/__init__.py`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and IAM Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure IAM permissions for: `dynamodb:*`, `lambda:CreateFunction`, `lambda:DeleteFunction`, `lambda:InvokeFunction`, `lambda:CreateEventSourceMapping`, `lambda:DeleteEventSourceMapping`, `lambda:GetFunction`, `iam:PassRole`, `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:DeleteRole`, `iam:DetachRolePolicy`, `logs:*`
    - Create a Lambda execution IAM role with `AWSLambdaBasicExecutionRole` and `AmazonDynamoDBReadOnlyAccess` policies; note the role ARN for later use
    - _Requirements: (all)_

- [ ] 2. Define Access Patterns and Design the Single-Table Data Model
  - [ ] 2.1 Document six access patterns for the e-commerce domain
    - Create `docs/access_patterns.md` documenting each access pattern with: name, entity type, operation (read/write), lookup keys, sort/filter conditions, and target (base_table, GSI1, or GSI2)
    - AP1: Get user by ID — read, base table, PK=`USER#<id>`, SK=`USER#<id>`
    - AP2: Get orders for a user — read, base table, PK=`USER#<id>`, SK begins_with `ORDER#`
    - AP3: Get order items by order — read, base table, PK=`ORDER#<id>`, SK begins_with `PRODUCT#`
    - AP4: Get products by category — read, GSI2, GSI2PK=`CATEGORY#<cat>`, GSI2SK begins_with `PRODUCT#`
    - AP5: Get order by order ID (inverted index) — read, GSI1, GSI1PK=`ORDER#<id>`
    - AP6: Get all products — read, base table scan with filter `entity_type = Product`
    - Verify: one-to-many (user → orders) and many-to-many (orders ↔ products via OrderLineItem) relationships are represented
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 2.2 Design the single-table key schema and entity item structures
    - Create `docs/data_model.md` documenting the table name (`ECommerceTable`), primary key (`PK` partition key, `SK` sort key), and all entity types
    - Define UserItem: PK=`USER#<user_id>`, SK=`USER#<user_id>`, attributes: entity_type, user_id, name, email, created_at
    - Define OrderItem: PK=`USER#<user_id>`, SK=`ORDER#<order_id>`, attributes: entity_type, order_id, user_id, status, total_amount, order_date, GSI1PK=`ORDER#<order_id>`, GSI1SK=`ORDER#<order_id>`
    - Define OrderLineItem: PK=`ORDER#<order_id>`, SK=`PRODUCT#<product_id>`, attributes: entity_type, order_id, product_id, quantity, unit_price
    - Define ProductItem: PK=`PRODUCT#<product_id>`, SK=`PRODUCT#<product_id>`, attributes: entity_type, product_id, product_name, category, price, inventory_count, GSI2PK=`CATEGORY#<category>`, GSI2SK=`PRODUCT#<product_id>`
    - Define GSI1: partition key=`GSI1PK`, sort key=`GSI1SK`, projection=ALL (inverted index for order lookup)
    - Define GSI2: partition key=`GSI2PK`, sort key=`GSI2SK`, projection=INCLUDE with `product_name, price, inventory_count` (products by category)
    - Verify: composite key prefixes clearly distinguish all four entity types; document maps each access pattern to its key condition
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 3. Implement TableManager and Create the DynamoDB Table
  - [ ] 3.1 Implement `components/table_manager.py`
    - Create the `TableManager` class using `boto3.client('dynamodb')` and `boto3.resource('dynamodb')`
    - Implement `create_table()`: create table with PK (String), SK (String), on-demand billing mode, and GSI definitions for GSI1 (GSI1PK/GSI1SK, projection ALL) and GSI2 (GSI2PK/GSI2SK, projection INCLUDE with NonKeyAttributes)
    - Implement `wait_until_active()`: use `boto3.resource('dynamodb').Table(name).wait_until_exists()` and poll until table status is ACTIVE
    - Implement `describe_table()`: return table description including GSI status
    - Implement `enable_streams()`: update table with `StreamSpecification` setting `StreamEnabled=True` and `StreamViewType='NEW_AND_OLD_IMAGES'`; return the stream ARN
    - Implement `deploy_stream_processor()`: create Lambda function from zipped handler code, with Python 3.12 runtime, the IAM role ARN from prerequisites, timeout 60s, memory 128MB; return function ARN
    - Implement `create_event_source_mapping()`: create event source mapping linking the stream ARN to the Lambda function with `StartingPosition='LATEST'`
    - Implement `delete_table()`: delete the DynamoDB table
    - _Requirements: 3.1, 3.2, 7.1, 7.2_
  - [ ] 3.2 Run TableManager to create the table with GSIs
    - Create a script `scripts/setup_table.py` that instantiates TableManager, calls `create_table('ECommerceTable', 'PK', 'SK', gsi_definitions)` with both GSI1 and GSI2 definitions
    - Call `wait_until_active('ECommerceTable')` and verify table is active
    - Verify table creation: `aws dynamodb describe-table --table-name ECommerceTable` — confirm BillingMode is PAY_PER_REQUEST, both GSIs exist and are ACTIVE
    - _Requirements: 3.1, 3.2, 4.1, 4.4_

- [ ] 4. Implement DataLoader and Populate Sample Data
  - [ ] 4.1 Implement `components/data_loader.py`
    - Create the `DataLoader` class using `boto3.resource('dynamodb').Table()`
    - Implement `generate_sample_items()`: return a list of at least 15 items across all four entity types — at minimum: 3 users, 4 orders (distributed across users for one-to-many), 4 products (across at least 2 categories), and 6 order line items (linking orders to multiple products for many-to-many)
    - Include GSI1PK/GSI1SK attributes on OrderItem entries and GSI2PK/GSI2SK attributes on ProductItem entries
    - Implement `batch_write_items()`: use `table.batch_writer()` to write items in batches of 25
    - Implement `count_items_by_type()`: scan the table and count items grouped by `entity_type` attribute; return a dictionary like `{"User": 3, "Order": 4, "Product": 4, "OrderLineItem": 6}`
    - _Requirements: 3.3, 3.4_
  - [ ] 4.2 Load sample data and verify
    - Create `scripts/load_data.py` that calls `generate_sample_items()` and `batch_write_items()`
    - Call `count_items_by_type()` and print results to confirm at least 15 items across all entity types
    - Verify with CLI: `aws dynamodb scan --table-name ECommerceTable --select COUNT`
    - _Requirements: 3.3, 3.4_

- [ ] 5. Checkpoint - Validate Table Structure and Data
  - Confirm table is ACTIVE with on-demand billing: `aws dynamodb describe-table --table-name ECommerceTable | grep BillingMode`
  - Confirm both GSIs (GSI1, GSI2) are ACTIVE: check `GlobalSecondaryIndexes` in describe-table output
  - Confirm at least 15 items loaded: `aws dynamodb scan --table-name ECommerceTable --select COUNT`
  - Verify composite key structure by querying a sample user: `aws dynamodb query --table-name ECommerceTable --key-condition-expression "PK = :pk" --expression-attribute-values '{":pk":{"S":"USER#user1"}}'`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement QueryRunner and Validate All Access Patterns
  - [ ] 6.1 Implement `components/query_runner.py`
    - Create the `QueryRunner` class using `boto3.resource('dynamodb').Table()`
    - Implement `query_by_partition_key()`: query table with `KeyConditionExpression` on PK only
    - Implement `query_with_sort_key_condition()`: query with PK and `SK begins_with` condition using `Key().begins_with()`
    - Implement `query_gsi()`: query a named GSI with partition key and optional sort key condition
    - Implement `scan_with_filter()`: perform a full table scan with `FilterExpression` and `ExpressionAttributeValues`; document why this is less efficient than a query
    - Implement `validate_all_access_patterns()`: execute all six access patterns and return a dictionary mapping each pattern name to its results and item count
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 6.2 Execute and validate all six access patterns
    - Create `scripts/run_queries.py` that calls `validate_all_access_patterns('ECommerceTable')`
    - AP1 — Get user by ID: `query_by_partition_key` with PK=`USER#user1`, verify returns exactly one User item
    - AP2 — Get orders for a user: `query_with_sort_key_condition` with PK=`USER#user1`, SK prefix=`ORDER#`, verify returns order items for that user
    - AP3 — Get order items by order: `query_with_sort_key_condition` with PK=`ORDER#order1`, SK prefix=`PRODUCT#`, verify returns OrderLineItem entries
    - AP4 — Get products by category: `query_gsi` with index=`GSI2`, PK=`CATEGORY#Electronics`, verify returns products in that category
    - AP5 — Get order by order ID (inverted index): `query_gsi` with index=`GSI1`, PK=`ORDER#order1`, verify returns the order item demonstrating inverted index pattern
    - AP6 — Get all products: `scan_with_filter` with filter `entity_type = Product`, document efficiency tradeoff versus query
    - Print results for each pattern and confirm all six return expected items
    - _Requirements: 4.2, 4.3, 5.1, 5.2, 5.3, 5.4_

- [ ] 7. Implement TransactionManager for Atomic Operations
  - [ ] 7.1 Implement `components/transaction_manager.py`
    - Create the `TransactionManager` class using `boto3.client('dynamodb')`
    - Implement `transact_create_order()`: use `transact_write_items()` to atomically put an order item, put multiple order line items, and update product inventory counts (decrement `inventory_count`) in a single transaction
    - Implement `transact_create_order_with_condition()`: same as above but add `ConditionExpression` checks on each product ensuring `inventory_count >= :requested_qty`; if any condition fails, the entire transaction rolls back
    - Implement `transact_read_related_items()`: use `transact_get_items()` to read a user, an order, and a product in a single consistent read operation
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ] 7.2 Test transactions with success and failure scenarios
    - Create `scripts/run_transactions.py`
    - Test successful transaction: create a new order with line items and inventory updates; verify all items exist in the table afterward
    - Test failed transaction: attempt to create an order with a condition check that fails (e.g., request quantity exceeding inventory); catch `TransactionCanceledException` and verify no items were modified
    - Test transactional read: read a user, order, and product atomically; print results showing consistent snapshot across entity types
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 8. Checkpoint - Validate Queries and Transactions
  - Verify all six access patterns return correct results by running `scripts/run_queries.py`
  - Verify successful transaction creates all expected items
  - Verify failed transaction rolls back completely with no partial writes
  - Verify transactional read returns consistent data across entity types
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Implement StreamProcessor and DynamoDB Streams Integration
  - [ ] 9.1 Implement `components/stream_processor.py` Lambda handler
    - Implement `handler(event, context)`: iterate over `event['Records']`, call `process_record()` for each, return summary with status code 200
    - Implement `process_record(record)`: extract `eventName` (INSERT, MODIFY, REMOVE), `dynamodb.NewImage`, and `dynamodb.OldImage`; log event type and item keys; if MODIFY, call `compare_images()`
    - Implement `compare_images(old_image, new_image)`: compare all attributes between old and new images, return a list of dictionaries describing changed attributes (attribute name, old value, new value)
    - Log all output using Python's `logging` module so results appear in CloudWatch Logs
    - _Requirements: 7.1, 7.3, 7.4_
  - [ ] 9.2 Deploy stream processor and create event source mapping
    - Enable DynamoDB Streams on the table by calling `table_manager.enable_streams('ECommerceTable', 'NEW_AND_OLD_IMAGES')`; capture the returned stream ARN
    - Package `components/stream_processor.py` into a ZIP file for Lambda deployment
    - Call `table_manager.deploy_stream_processor('ECommerceStreamProcessor', 'stream_processor.handler', role_arn)` to create the Lambda function
    - Call `table_manager.create_event_source_mapping('ECommerceStreamProcessor', stream_arn)` to connect the stream to the function
    - Verify Lambda function exists: `aws lambda get-function --function-name ECommerceStreamProcessor`
    - _Requirements: 7.1, 7.2_
  - [ ] 9.3 Test stream processing with insert and update operations
    - Create `scripts/test_streams.py` that writes a new item to the table (INSERT event) and then updates an existing item's attribute (MODIFY event)
    - Wait 10–15 seconds for stream processing
    - Check CloudWatch Logs for the Lambda function: `aws logs filter-log-events --log-group-name /aws/lambda/ECommerceStreamProcessor --start-time $(date -d '5 minutes ago' +%s000)`
    - Verify INSERT event is logged with new image data
    - Verify MODIFY event is logged with both old and new images and changed attributes are identified
    - _Requirements: 7.2, 7.3, 7.4_

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete Lambda and event source mapping
    - List event source mappings: `aws lambda list-event-source-mappings --function-name ECommerceStreamProcessor`
    - Delete event source mapping: `aws lambda delete-event-source-mapping --uuid <mapping-uuid>`
    - Delete Lambda function: `aws lambda delete-function --function-name ECommerceStreamProcessor`
    - Verify: `aws lambda get-function --function-name ECommerceStreamProcessor` should return ResourceNotFoundException
    - _Requirements: (all)_
  - [ ] 10.2 Delete DynamoDB table
    - Delete table: `aws dynamodb delete-table --table-name ECommerceTable`
    - Wait for deletion: `aws dynamodb wait table-not-exists --table-name ECommerceTable`
    - Verify: `aws dynamodb describe-table --table-name ECommerceTable` should return ResourceNotFoundException
    - _Requirements: (all)_
  - [ ] 10.3 Delete IAM role and clean up logs
    - Detach policies from Lambda execution role: `aws iam detach-role-policy --role-name ECommerceStreamProcessorRole --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole` and `aws iam detach-role-policy --role-name ECommerceStreamProcessorRole --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess`
    - Delete IAM role: `aws iam delete-role --role-name ECommerceStreamProcessorRole`
    - Delete CloudWatch log group: `aws logs delete-log-group --log-group-name /aws/lambda/ECommerceStreamProcessor`
    - Verify no remaining resources by checking: `aws dynamodb list-tables`, `aws lambda list-functions`, `aws iam list-roles | grep ECommerce`
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- All scripts use boto3 with Python 3.12; no infrastructure-as-code frameworks are required
- The table uses on-demand (PAY_PER_REQUEST) billing mode to avoid provisioned throughput management during learning
- DynamoDB Streams processing may have a few seconds of latency; allow 10–15 seconds before checking CloudWatch Logs
- If you encounter `ResourceInUseException`, the table already exists — delete it first or use a different table name
