

# Requirements Document

## Introduction

This project guides you through designing and building a DynamoDB data model for a serverless application. DynamoDB is a fully managed, serverless NoSQL database that delivers consistent single-digit millisecond performance at any scale, making it a cornerstone of serverless architectures on AWS. Understanding how to model data effectively in DynamoDB is a foundational skill for building modern cloud-native applications.

Unlike relational databases where you design a normalized schema first and then write queries, DynamoDB data modeling starts with your application's access patterns and works backward to define table structures, key schemas, and indexes. This "access-pattern-first" approach is central to getting the most out of DynamoDB. In this project, you will design a single-table data model for a realistic serverless use case, implement it with items and indexes, and verify that your model efficiently supports multiple query patterns.

By completing this project, you will gain hands-on experience with core DynamoDB concepts including partition keys, sort keys, secondary indexes, and single-table design — skills that directly translate to building production serverless applications with services like Lambda and API Gateway.

## Glossary

- **partition_key**: The primary key attribute that DynamoDB uses to distribute data across partitions; every item must include this attribute, and its value determines which physical partition stores the item.
- **sort_key**: An optional second key attribute that, combined with the partition key, forms a composite primary key; enables range-based queries and multiple items per partition key value.
- **single_table_design**: A DynamoDB modeling pattern where multiple entity types (e.g., users, orders, products) are stored in one table, using carefully structured key values to represent different entities and relationships.
- **global_secondary_index**: An index with a partition key and optional sort key that can differ from the base table's keys, enabling queries on alternate access patterns across all items in the table.
- **local_secondary_index**: An index that shares the base table's partition key but uses a different sort key, enabling alternate sort-order queries within the same partition.
- **access_pattern**: A specific way your application reads or writes data, defined by the query parameters, filters, and sort orders needed to fulfill a business requirement.
- **item_collection**: A group of items in a table or index that share the same partition key value.
- **composite_key**: A key attribute whose value is constructed by combining multiple logical fields (e.g., `STATUS#TIMESTAMP`), enabling flexible query patterns within DynamoDB's key structure.
- **on_demand_capacity**: A DynamoDB billing mode where you pay per read and write request without pre-provisioning throughput, ideal for learning and workloads with unpredictable traffic.

## Requirements

### Requirement 1: Define Access Patterns for a Serverless Application Domain

**User Story:** As a cloud database learner, I want to identify and document the access patterns for a serverless application domain (e.g., an e-commerce store with users, orders, and products), so that I understand how access-pattern-first design drives DynamoDB data modeling decisions.

#### Acceptance Criteria

1. THE learner SHALL define at least six distinct access patterns spanning at least three entity types (e.g., get user by ID, get all orders for a user, get order items by order, query products by category).
2. WHEN the learner documents each access pattern, THE documentation SHALL specify the entity type involved, the lookup key(s), any required sort or filter conditions, and whether the operation is a read or a write.
3. THE documented access patterns SHALL include at least one one-to-many relationship (e.g., a user with multiple orders) and at least one many-to-many relationship (e.g., orders containing multiple products).

### Requirement 2: Design a Single-Table Data Model with Composite Keys

**User Story:** As a cloud database learner, I want to design a single-table DynamoDB data model that stores multiple entity types using composite keys, so that I can learn how single-table design consolidates related data for efficient access.

#### Acceptance Criteria

1. THE data model SHALL use a single DynamoDB table with a composite primary key (partition key and sort key) that accommodates all defined entity types through structured key value prefixes or patterns.
2. WHEN the learner defines the key schema, THE partition key and sort key values SHALL use composite key patterns (e.g., `USER#<id>`, `ORDER#<id>`) that clearly distinguish between entity types.
3. THE data model SHALL represent at least three distinct entity types as items within the same table, each identifiable by its key structure.
4. THE data model design SHALL be documented in a format compatible with NoSQL Workbench or an equivalent entity-relationship diagram showing all entity types, their attributes, and their key mappings.

### Requirement 3: Create the DynamoDB Table and Load Sample Data

**User Story:** As a cloud database learner, I want to create my designed DynamoDB table and populate it with sample data representing multiple entity types, so that I can validate my data model against real data.

#### Acceptance Criteria

1. WHEN the learner creates the DynamoDB table with the designed partition key and sort key schema, THE table SHALL become active and ready for read/write operations.
2. THE table SHALL use on-demand capacity mode to simplify the learning exercise and avoid manual throughput provisioning.
3. WHEN the learner loads sample data, THE table SHALL contain at least 15 items spanning all defined entity types, with realistic attribute values that represent meaningful relationships between entities.
4. THE loaded items SHALL include examples of the one-to-many and many-to-many relationships defined in the access patterns.

### Requirement 4: Implement Global Secondary Indexes for Alternate Access Patterns

**User Story:** As a cloud database learner, I want to add global secondary indexes to my table, so that I can support access patterns that require querying on attributes other than the base table's primary key.

#### Acceptance Criteria

1. WHEN the learner adds a global secondary index, THE index SHALL use a partition key and optional sort key that differ from the base table's primary key to enable at least one access pattern not achievable through the base table alone.
2. THE learner SHALL create at least one global secondary index that enables an "inverted index" pattern (e.g., swapping the base table's partition key and sort key) to support relationship traversal in the opposite direction.
3. WHEN the learner queries the global secondary index, THE results SHALL return only the items matching the specified index key conditions, demonstrating that the index correctly supports the intended access pattern.
4. THE global secondary index SHALL project only the attributes needed for its target access patterns, demonstrating understanding of index projection options (ALL, KEYS_ONLY, or INCLUDE).

### Requirement 5: Query and Scan Operations Across Access Patterns

**User Story:** As a cloud database learner, I want to execute query and scan operations against my table and indexes, so that I can verify my data model supports all defined access patterns efficiently.

#### Acceptance Criteria

1. WHEN the learner performs a query operation with a partition key value and a sort key condition (e.g., begins-with or between), THE results SHALL return only the matching items from the relevant item collection.
2. WHEN the learner performs a query using a global secondary index, THE results SHALL satisfy an access pattern that cannot be fulfilled by the base table's key schema alone.
3. THE learner SHALL demonstrate that each of the six defined access patterns is satisfied by either a base table query or a secondary index query, without requiring a full table scan.
4. IF the learner performs a scan operation, THE learner SHALL apply a filter expression and document why a scan was necessary versus a query, demonstrating understanding of the efficiency tradeoff.

### Requirement 6: Manage Related Items with DynamoDB Transactions

**User Story:** As a cloud database learner, I want to use DynamoDB transactions to write related items atomically, so that I understand how to maintain data consistency across multiple entity types in a single-table design.

#### Acceptance Criteria

1. WHEN the learner performs a transactional write involving multiple items (e.g., creating an order and updating product inventory), THE operation SHALL either succeed for all items or fail for all items, maintaining data consistency.
2. IF a transaction includes a condition check that is not satisfied (e.g., insufficient inventory), THEN THE entire transaction SHALL be rolled back and no items SHALL be modified.
3. THE learner SHALL use a transactional read to retrieve related items across entity types in a single, consistent operation, demonstrating the difference between eventually consistent and strongly consistent access to related data.

### Requirement 7: Integrate with a Serverless Compute Trigger Using DynamoDB Streams

**User Story:** As a cloud database learner, I want to enable DynamoDB Streams on my table and connect it to a serverless function, so that I understand how data changes in DynamoDB can trigger downstream processing in a serverless architecture.

#### Acceptance Criteria

1. WHEN the learner enables DynamoDB Streams on the table, THE stream SHALL capture item-level changes including inserts, updates, and deletes.
2. WHEN a new item is written to the table, THE stream SHALL trigger a Lambda function that logs or processes the change event, demonstrating the event-driven integration between DynamoDB and Lambda.
3. THE learner SHALL configure the stream view type to include both old and new item images, so that the triggered function can compare before-and-after states of modified items.
4. WHEN the learner updates an existing item, THE triggered function SHALL receive both the previous and updated attribute values, demonstrating change data capture capability.
