

# Requirements Document

## Introduction

This project guides you through building a serverless REST API using AWS Lambda and Amazon API Gateway, with Amazon DynamoDB as the data store. Serverless architectures allow developers to focus on application logic rather than infrastructure management, and this pattern—API Gateway fronting Lambda functions that interact with DynamoDB—is one of the most foundational architectures in modern cloud development.

By completing this project, you will understand how to expose HTTP endpoints through API Gateway, handle requests with Lambda functions, and persist data in DynamoDB. You will work through the full lifecycle of a serverless API: defining resources and methods, integrating them with backend compute, storing and retrieving data, deploying to a stage, and testing the complete request flow. This hands-on experience builds the core skills needed for designing and implementing serverless applications on AWS.

The project follows a progressive approach: first establishing the data layer, then building the compute logic, connecting it through an API layer, and finally deploying and validating the end-to-end system.

## Glossary

- **rest_api**: A REST API resource in Amazon API Gateway that provides a collection of HTTP endpoints organized into resources and methods, used to expose backend services to clients.
- **lambda_function**: An AWS Lambda function that runs application code in response to events without requiring server provisioning or management.
- **lambda_proxy_integration**: An API Gateway integration type where the complete HTTP request (headers, query parameters, path parameters, body) is passed directly to a Lambda function as a structured event, and the function's response determines the full HTTP response.
- **resource**: A logical entity within an API Gateway REST API that represents a URL path segment (e.g., `/items` or `/items/{id}`) and can have one or more HTTP methods associated with it.
- **stage**: A named deployment snapshot of an API Gateway API (e.g., `dev`, `prod`) that provides a unique invoke URL for clients to call.
- **deployment**: The act of publishing a configured API Gateway API to a stage, making it accessible to clients via a public endpoint.
- **cors**: Cross-Origin Resource Sharing — a mechanism that allows a REST API to be called from web applications hosted on different domains.
- **invoke_url**: The publicly accessible URL generated when an API is deployed to a stage, used by clients to send requests to the API.

## Requirements

### Requirement 1: DynamoDB Table for API Data Persistence

**User Story:** As a serverless API learner, I want to create a DynamoDB table to serve as the data store for my REST API, so that I can persist and retrieve structured data through API requests.

#### Acceptance Criteria

1. WHEN the learner creates a DynamoDB table with a partition key suitable for uniquely identifying items, THE table SHALL become active and ready for read/write operations.
2. THE table SHALL use on-demand capacity mode to simplify configuration and accommodate variable request patterns during the learning exercise.
3. THE table's key schema SHALL support retrieving individual items by their unique identifier as well as storing items with multiple attributes beyond the key.

### Requirement 2: Lambda Functions for CRUD Business Logic

**User Story:** As a serverless API learner, I want to create Lambda functions that implement create, read, update, and delete operations against my DynamoDB table, so that I understand how serverless compute handles API backend logic.

#### Acceptance Criteria

1. WHEN a Lambda function receives an event representing a create operation with a valid item payload, THE function SHALL store the item in the DynamoDB table and return a structured response indicating success.
2. WHEN a Lambda function receives an event representing a read operation with an item identifier, THE function SHALL retrieve the matching item from the DynamoDB table and return it in the response body.
3. WHEN a Lambda function receives an event representing a delete operation with an item identifier, THE function SHALL remove the item from the DynamoDB table and return a structured response confirming the deletion.
4. IF a Lambda function receives a request referencing an item that does not exist in the table, THEN THE function SHALL return a structured response indicating that no matching item was found.

### Requirement 3: Lambda Execution Role and Permissions

**User Story:** As a serverless API learner, I want to configure an IAM execution role for my Lambda functions with appropriate permissions, so that I understand how serverless applications use least-privilege access to interact with other AWS services.

#### Acceptance Criteria

1. THE Lambda execution role SHALL grant the function permission to write logs to Amazon CloudWatch Logs for monitoring and debugging purposes.
2. THE Lambda execution role SHALL grant the function permission to perform read and write operations on the specific DynamoDB table used by the API, following the principle of least privilege.
3. IF the Lambda function attempts to access a DynamoDB table or AWS resource not specified in its execution role policy, THEN THE operation SHALL be denied.

### Requirement 4: REST API Resource and Method Structure

**User Story:** As a serverless API learner, I want to define a REST API in API Gateway with resources and HTTP methods for each CRUD operation, so that I understand how API structure maps to backend functionality.

#### Acceptance Criteria

1. WHEN the learner creates a REST API in API Gateway, THE API SHALL contain a resource path representing the data collection (e.g., `/items`) that supports methods for creating new items and listing or retrieving items.
2. THE API SHALL include a child resource with a path parameter (e.g., `/items/{id}`) that supports methods for retrieving, updating, and deleting individual items by their identifier.
3. WHEN the learner configures each method, THE method SHALL use Lambda proxy integration to connect to the corresponding Lambda function, passing the full request context to the function.
4. THE API SHALL have CORS configured on its resources so that the endpoints can be invoked from browser-based clients on different domains.

### Requirement 5: API Deployment and Stage Configuration

**User Story:** As a serverless API learner, I want to deploy my REST API to a stage and obtain a public invoke URL, so that I understand how API Gateway makes APIs accessible to external clients.

#### Acceptance Criteria

1. WHEN the learner deploys the REST API to a named stage, THE deployment SHALL generate a publicly accessible invoke URL that includes the stage name in the path.
2. THE deployed API SHALL route incoming requests to the correct Lambda function based on the resource path and HTTP method specified in the request.
3. IF the learner makes changes to the API configuration (such as adding a new method or modifying an integration) without redeploying, THEN THE live stage SHALL continue to serve the previously deployed configuration until a new deployment is performed.

### Requirement 6: End-to-End API Testing and Validation

**User Story:** As a serverless API learner, I want to test each endpoint of my deployed REST API by sending requests and verifying responses, so that I can confirm the entire serverless stack works together correctly.

#### Acceptance Criteria

1. WHEN the learner sends a request to the create endpoint with a valid item payload, THE API SHALL return a response containing the created item and THE item SHALL be verifiable in the DynamoDB table.
2. WHEN the learner sends a request to the read endpoint with a valid item identifier, THE API SHALL return a response containing the item's attributes as stored in DynamoDB.
3. WHEN the learner sends a request to the delete endpoint with a valid item identifier, THE API SHALL return a success response and a subsequent read request for the same identifier SHALL indicate the item no longer exists.
4. IF the learner sends a request with a malformed payload or missing required fields, THEN THE API SHALL return an error response with a meaningful message rather than an unhandled exception.
