

# Implementation Plan: Full-Text Search Application with Amazon OpenSearch

## Overview

This implementation plan guides learners through building a full-text search application for an e-commerce product catalog using Amazon OpenSearch Service. The project follows a progressive approach: first provisioning the OpenSearch domain infrastructure, then designing index mappings with custom analyzers, ingesting sample product data, and finally implementing increasingly sophisticated search capabilities including full-text queries, filtering, aggregations, fuzzy matching, synonyms, and autocomplete.

The plan is organized into key phases. The first phase covers environment setup and OpenSearch domain provisioning, which requires waiting for the domain to become active (typically 15-20 minutes). The second phase focuses on index design with explicit mappings and data ingestion, establishing the foundation for all search operations. The third phase implements the full range of search capabilities — from basic match queries through advanced features like fuzziness, synonyms, and search-as-you-type. The final phase covers monitoring and visualization using OpenSearch Dashboards.

A critical dependency is that the OpenSearch domain must be fully active before any index, data, or search operations can proceed. All Python components (`DomainManager`, `IndexManager`, `DataIngester`, `SearchClient`) interact with the domain via the `opensearch-py` client library and share connection configuration. Tasks are ordered to build incrementally so learners can validate each capability before moving to the next.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions to create OpenSearch Service domains
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - Confirm IAM permissions include `es:*` actions for OpenSearch Service
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Python 3.12: verify with `python3 --version`
    - Create project directory and virtual environment: `python3 -m venv venv && source venv/bin/activate`
    - Install dependencies: `pip install opensearch-py boto3 requests-aws4auth`
    - Create project structure: `mkdir -p components` and create `components/__init__.py`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Choose a unique OpenSearch domain name (e.g., `product-search-<your-initials>`)
    - Choose master username and a strong master password for fine-grained access control
    - Note: OpenSearch domain creation takes 15-20 minutes; plan accordingly
    - _Requirements: (all)_

- [ ] 2. Provision OpenSearch Domain with DomainManager
  - [ ] 2.1 Implement DomainManager component
    - Create `components/domain_manager.py` with a `boto3.client('opensearch')` client
    - Implement `create_domain(domain_name, instance_type, volume_size, master_user, master_password)` that calls `create_domain` API with: `EngineVersion='OpenSearch_2.11'`, single-node cluster (`InstanceCount=1`), `t3.small.search` instance type, EBS volume (10 GB `gp3`), fine-grained access control enabled with internal user database, encryption at rest enabled, node-to-node encryption enabled, and HTTPS enforced
    - Implement `get_domain_status(domain_name)` that calls `describe_domain` and returns domain status details
    - Implement `wait_until_active(domain_name)` that polls `get_domain_status` until `Processing` is `False` and `DomainStatus.Endpoint` is available, returning the endpoint
    - Implement `get_dashboards_url(domain_name)` that retrieves the domain endpoint and constructs the Dashboards URL (`https://<endpoint>/_dashboards`)
    - Implement `delete_domain(domain_name)` that calls `delete_domain` API
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [ ] 2.2 Create the OpenSearch domain and verify activation
    - Create a runner script `scripts/provision_domain.py` that calls `create_domain` with chosen parameters
    - Run the script and wait for the domain to become active using `wait_until_active`
    - Verify domain is active: `aws opensearch describe-domain --domain-name <domain-name> --query 'DomainStatus.Processing'` should return `false`
    - Print and record the domain endpoint and Dashboards URL for subsequent tasks
    - Verify Dashboards access by opening `get_dashboards_url` output in a browser and logging in with master credentials
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 3. Design Product Index and Mappings with IndexManager
  - [ ] 3.1 Implement IndexManager component
    - Create `components/index_manager.py`
    - Implement `create_client(host, port, auth)` that returns an `OpenSearch` client instance configured with HTTPS and the master user credentials
    - Implement `create_product_index(client, index_name)` that creates an index with explicit mapping: `name` as text (with standard analyzer and keyword sub-field), `name_suggest` as `search_as_you_type`, `description` as text, `category` as keyword, `brand` as keyword, `price` as float, `tags` as keyword, `in_stock` as boolean
    - Implement `index_exists(client, index_name)` using `client.indices.exists()`
    - Implement `get_mapping(client, index_name)` using `client.indices.get_mapping()`
    - Implement `delete_index(client, index_name)` using `client.indices.delete()`
    - _Requirements: 2.1, 2.2, 2.3, 7.1_
  - [ ] 3.2 Implement synonym-enabled index creation
    - Implement `create_product_index_with_synonyms(client, index_name, synonyms)` that defines a custom analyzer with a synonym filter (e.g., `["laptop, notebook", "phone, mobile, cellphone"]`), applies the custom analyzer to the `description` field, and retains the standard mapping for all other fields
    - _Requirements: 6.2_
  - [ ] 3.3 Create the product index and verify mapping
    - Create `scripts/setup_index.py` that connects to the domain and calls `create_product_index`
    - Run the script and verify the index was created: call `get_mapping` and confirm all field types match the `IndexMapping` data model
    - Test duplicate index creation: attempt to create the same index again and verify it returns an error (index_already_exists)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Ingest Product Data with DataIngester
  - [ ] 4.1 Implement DataIngester component
    - Create `components/data_ingester.py`
    - Implement `generate_sample_products()` that returns a list of at least 20 `ProductDocument` dictionaries covering multiple categories (Electronics, Clothing, Home, Sports), multiple brands, a range of prices, varied tags, and descriptive text suitable for full-text search testing
    - Implement `index_product(client, index_name, product, doc_id)` using `client.index()` to add a single document
    - Implement `bulk_index_products(client, index_name, products)` using `client.bulk()` or the `helpers.bulk()` method to load all products in one operation, returning success count and any per-document errors
    - Implement `refresh_index(client, index_name)` using `client.indices.refresh()` to make documents immediately searchable
    - _Requirements: 3.1, 3.2_
  - [ ] 4.2 Load sample data and verify ingestion
    - Create `scripts/ingest_data.py` that generates sample products, bulk indexes them, and refreshes the index
    - Run the script and verify document count: `client.count(index=index_name)` should match the number of ingested products
    - Test single document indexing by adding one additional product with `index_product`
    - Test mapping conflict: attempt to index a document with `price` set to a non-numeric string and verify it returns a mapper_parsing_exception error
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 5. Checkpoint - Validate Domain, Index, and Data Foundation
  - Confirm OpenSearch domain is active and accessible via endpoint
  - Confirm product index exists with correct mapping (text, keyword, float, search_as_you_type fields)
  - Confirm all sample products are indexed and searchable (run a `match_all` query)
  - Verify OpenSearch Dashboards is accessible and shows the product index
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement Full-Text Search Queries with SearchClient
  - [ ] 6.1 Implement core search functions
    - Create `components/search_client.py`
    - Define `SearchResult` and `HitItem` as dataclasses or dictionaries matching the data model (total_hits, hits with doc_id/score/source, aggregations)
    - Implement `match_search(client, index_name, field, query_text)` using a `match` query on the specified field; return results with relevance scores
    - Implement `multi_match_search(client, index_name, fields, query_text)` using a `multi_match` query across fields like `["name", "description"]`
    - Implement `phrase_search(client, index_name, field, phrase)` using a `match_phrase` query to find exact phrase matches in order
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [ ] 6.2 Test full-text search queries
    - Create `scripts/run_searches.py` that demonstrates each search type
    - Execute a `match_search` on `description` and verify results include documents containing queried terms, ranked by relevance score
    - Execute a `multi_match_search` across `name` and `description` and verify scoring reflects matches in multiple fields
    - Execute a `phrase_search` and verify exact phrase matches rank higher; confirm relevance scores are present in all results
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 7. Implement Filtering, Sorting, and Aggregations
  - [ ] 7.1 Implement filter, sort, and aggregation functions
    - Implement `filtered_search(client, index_name, query_text, filters)` using a `bool` query with `must` for the match and `filter` context for keyword term filters (category, brand); verify filter does not affect relevance scoring
    - Implement `range_filter_search(client, index_name, query_text, field, gte, lte)` using a `range` filter within `bool/filter` on the `price` field
    - Implement `aggregation_search(client, index_name, agg_field, query_text)` using a `terms` aggregation on keyword fields; return bucket counts in the aggregations field of SearchResult
    - Implement `sorted_search(client, index_name, query_text, sort_field, order)` using the `sort` parameter to order by a numeric or keyword field in ascending or descending order
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - [ ] 7.2 Test filtering, sorting, and aggregation queries
    - Execute `filtered_search` with a category filter and verify only matching-category documents are returned
    - Execute `range_filter_search` with min/max price and verify all results fall within the range
    - Execute `aggregation_search` on `category` and verify response contains bucket counts per category
    - Execute `sorted_search` on `price` ascending and descending; verify result order matches specification
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 8. Implement Fuzziness, Synonyms, and Autocomplete
  - [ ] 8.1 Implement fuzzy search and synonym support
    - Implement `fuzzy_search(client, index_name, field, query_text, fuzziness)` using a `match` query with `fuzziness` parameter (e.g., `"AUTO"` or `"1"`)
    - Test fuzzy search: search with a misspelled term (e.g., "laptp") with fuzziness enabled and verify approximate matches are returned
    - Test without fuzziness: search the same misspelled term without fuzziness and verify zero or only exact matches are returned
    - Create a synonym-enabled index using `create_product_index_with_synonyms`, re-ingest sample data, and verify that searching for a synonym term (e.g., "notebook") returns results that match the equivalent term (e.g., "laptop")
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ] 8.2 Implement search-as-you-type autocomplete
    - Implement `autocomplete_search(client, index_name, field, prefix_text)` using a `multi_match` query against the `name_suggest`, `name_suggest._2gram`, and `name_suggest._3gram` fields with type `bool_prefix`
    - Test with a partial product name prefix (e.g., "wire") and verify results include products whose names begin with or contain the typed characters
    - Verify autocomplete results include relevance scores so the most likely matches appear first
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 9. Checkpoint - Validate All Search Capabilities
  - Run all search scripts and verify: match, multi-match, phrase, filtered, range, aggregation, sorted, fuzzy, synonym, and autocomplete queries all return correct results
  - Confirm relevance scores are present in all search result types
  - Confirm filters do not affect scoring while sort overrides relevance ordering
  - Confirm fuzziness handles typos and synonyms resolve equivalent terms
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Monitoring and Visualization with OpenSearch Dashboards
  - [ ] 10.1 Explore data and run queries in Dashboards
    - Open OpenSearch Dashboards at the domain's Dashboards URL and log in with master credentials
    - Create an index pattern for the product index (e.g., `products`) in the Dashboards Stack Management section
    - Navigate to Discover and verify product documents are visible and browsable
    - Open Dev Tools console and execute a sample search query (e.g., a match query); verify results match programmatic query output
    - _Requirements: 8.1, 8.2_
  - [ ] 10.2 Monitor cluster health
    - In OpenSearch Dashboards, check cluster health indicators: node count, index count, document count, and storage usage
    - Alternatively, run `GET _cluster/health` and `GET _cat/indices?v` from Dev Tools to view cluster status
    - Verify the cluster shows green status with the expected number of indices and documents
    - _Requirements: 8.3_

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Delete OpenSearch index and domain
    - Delete the product index (and any synonym variant index): use `delete_index` from IndexManager or run via Dev Tools: `DELETE /products`
    - Delete the OpenSearch domain: `aws opensearch delete-domain --domain-name <domain-name>`
    - Note: Domain deletion takes several minutes to complete
    - _Requirements: (all)_
  - [ ] 11.2 Verify cleanup
    - Verify domain is deleted: `aws opensearch describe-domain --domain-name <domain-name>` should return a ResourceNotFoundException
    - Check AWS Cost Explorer or Billing Dashboard to confirm no ongoing OpenSearch charges
    - Remove local virtual environment if desired: `rm -rf venv`
    - **Warning:** OpenSearch domains incur hourly charges — ensure the domain is fully deleted to avoid unexpected costs
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The OpenSearch domain takes 15-20 minutes to provision — Task 2.2 includes a wait step; plan other reading or preparation during this time
- The synonym index (Task 8.1) requires creating a separate index with a custom analyzer, re-ingesting data, and testing — this is done within the same task to keep the flow consolidated
- All four design components (DomainManager, IndexManager, DataIngester, SearchClient) are implemented in Tasks 2-4 and 6-8 respectively
- All data models (ProductDocument, SearchResult, HitItem, IndexMapping) are defined and used across Tasks 3, 4, and 6
