

# Implementation Plan: Cloud Cost Management with AWS Cost Explorer

## Overview

This implementation plan guides you through setting up a comprehensive cloud cost management solution using AWS Cost Explorer and related AWS Billing and Cost Management services. The approach is console-and-CLI-driven, requiring no application code — you will configure services through the AWS Management Console and automate operations with AWS CLI v2 commands. The project follows a logical progression from enabling foundational services to building advanced monitoring and reporting capabilities.

The plan is organized into three phases. First, you will establish the foundation by enabling Cost Explorer and configuring cost organization tools (cost allocation tags and cost categories). Second, you will build analytical capabilities by exploring cost data across multiple dimensions, generating forecasts, and creating budgets with alerts. Third, you will set up automated anomaly detection and create a saved reporting workflow for ongoing cost governance. Each phase builds on the previous one, ensuring data and configurations are available for subsequent steps.

Key dependencies drive the task ordering: Cost Explorer must be enabled first (with up to 24 hours for data preparation), cost allocation tags must be activated before they can be used in filters and groupings, and anomaly monitors must exist before subscriptions can be created. Checkpoints are placed after foundational setup and after the analytical capabilities phase to validate progress before advancing.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account (management account preferred for Organizations features)
    - Configure AWS CLI v2: `aws configure` (set access key, secret key, default region, output format)
    - Verify access: `aws sts get-caller-identity`
    - Confirm billing access is enabled for IAM users in Account Settings (if not using root)
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and Permissions
    - Install AWS CLI v2 if not present; verify: `aws --version` (must be 2.x)
    - Set default region to us-east-1: `export AWS_DEFAULT_REGION=us-east-1`
    - Verify IAM permissions for Cost Explorer, Budgets, and Cost Anomaly Detection:
      - Required policies: `ce:*`, `budgets:*`, `aws-portal:ViewBilling`, `aws-portal:ViewAccount`
    - Tag at least 2-3 existing AWS resources with a user-defined tag (e.g., `Project=CostDemo`, `Environment=dev`) to generate taggable cost data for later tasks
    - _Requirements: (all)_

- [ ] 2. Enable and Configure AWS Cost Explorer
  - [ ] 2.1 Enable Cost Explorer and verify data availability
    - Navigate to AWS Billing and Cost Management console → Cost Explorer
    - Enable Cost Explorer for the first time (implements `CostExplorerSetup.enable_cost_explorer()`)
    - Note: Initial data preparation takes up to 24 hours; current month and previous 13 months of data will be prepared
    - Verify data availability by checking the Cost Explorer dashboard loads with cost data (implements `CostExplorerSetup.verify_data_availability()`)
    - _Requirements: 1.1, 1.2_
  - [ ] 2.2 Configure default dashboard and member account access
    - View the default Cost Explorer dashboard grouped by service for the current month (implements `CostExplorerSetup.view_default_dashboard()`)
    - Confirm the dashboard displays cost data organized by default time range and grouped by service
    - If using AWS Organizations management account: navigate to Cost Management Preferences → configure Cost Explorer access for member accounts (implements `CostExplorerSetup.configure_member_account_access()`)
    - Verify the Billing and Cost Management home page cost breakdown widget displays spending trends for the last six months
    - _Requirements: 1.2, 1.3, 7.3_

- [ ] 3. Configure Cost Allocation Tags and Cost Categories
  - [ ] 3.1 Activate cost allocation tags
    - Navigate to Billing and Cost Management → Cost Allocation Tags
    - List available tags and identify user-defined tags (implements `TagAndCategoryManager.list_cost_allocation_tags()`)
    - Activate the user-defined tag `Project` (and optionally `Environment`) by selecting and clicking "Activate" (implements `TagAndCategoryManager.activate_cost_allocation_tag("Project")`)
    - Note: Activated tags become available in Cost Explorer after the next data refresh cycle (up to 24 hours)
    - Verify activated tags show status "Active" in the Cost Allocation Tags console
    - _Requirements: 3.1, 3.3_
  - [ ] 3.2 Create a cost category definition
    - Create a cost category using AWS CLI (implements `TagAndCategoryManager.create_cost_category()`):
      ```
      aws ce create-cost-category-definition \
        --name "TeamCosts" \
        --rules '[{"Value":"Production","Rule":{"Tags":{"Key":"Environment","Values":["prod","production"],"MatchOptions":["EQUALS"]}}},{"Value":"Development","Rule":{"Tags":{"Key":"Environment","Values":["dev","development"],"MatchOptions":["EQUALS"]}}}]' \
        --rule-version "CostCategoryExpression.v1"
      ```
    - List cost categories to verify creation: `aws ce list-cost-category-definitions` (implements `TagAndCategoryManager.list_cost_categories()`)
    - Confirm the cost category appears as a grouping option in the Cost Explorer console
    - _Requirements: 3.2_

- [ ] 4. Checkpoint - Validate Foundation Setup
  - Verify Cost Explorer is enabled and displays cost data grouped by service
  - Verify cost allocation tags are activated (check status in Billing console)
  - Verify cost category "TeamCosts" exists: `aws ce list-cost-category-definitions`
  - Verify the Billing home page cost breakdown widget displays spending trends
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Analyze Costs Using Filters and Grouping Dimensions
  - [ ] 5.1 Filter and group costs by service and region in the console
    - In Cost Explorer, apply a filter by service (e.g., "Amazon EC2") and observe filtered results (implements `CostAnalyzer.get_cost_by_service()`)
    - Group cost data by service to see each service's contribution to total cost
    - Apply a filter by region (e.g., "us-east-1") and group by region (implements `CostAnalyzer.get_cost_by_region()`)
    - Toggle between DAILY and MONTHLY granularity for the same view
    - _Requirements: 2.1, 2.2, 2.4_
  - [ ] 5.2 Apply multiple filters and group by tags using CLI
    - Apply multiple filters simultaneously in the console (e.g., service = "Amazon EC2" AND region = "us-east-1") and verify the intersection is displayed (implements `CostAnalyzer.get_cost_filtered()`)
    - Query costs grouped by the activated `Project` tag using CLI (implements `CostAnalyzer.get_cost_by_tag()`):
      ```
      aws ce get-cost-and-usage \
        --time-period Start=2024-01-01,End=2024-02-01 \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --group-by Type=TAG,Key=Project
      ```
    - Verify untagged resources appear separately in the tag-based grouping output
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.3_

- [ ] 6. Generate Cost Forecasts and Set Up Budgets
  - [ ] 6.1 Generate and interpret spending forecasts
    - In Cost Explorer console, select a future time range to view the ML-based spending forecast alongside historical data
    - Verify the forecast includes a confidence interval (upper and lower bounds)
    - Generate a filtered forecast using CLI (implements `ForecastViewer.get_cost_forecast()` and `ForecastViewer.get_filtered_forecast()`):
      ```
      aws ce get-cost-forecast \
        --time-period Start=2025-02-01,End=2025-03-01 \
        --granularity MONTHLY \
        --metric UNBLENDED_COST
      ```
    - Generate a service-filtered forecast:
      ```
      aws ce get-cost-forecast \
        --time-period Start=2025-02-01,End=2025-03-01 \
        --granularity MONTHLY \
        --metric UNBLENDED_COST \
        --filter '{"Dimensions":{"Key":"SERVICE","Values":["Amazon EC2"]}}'
      ```
    - Verify forecast output includes `Total`, `Mean`, and confidence interval values
    - _Requirements: 4.1, 4.2, 4.3_
  - [ ] 6.2 Create a monthly cost budget with alert notifications
    - Get your AWS account ID: `aws sts get-caller-identity --query Account --output text`
    - Create a monthly cost budget (implements `BudgetManager.create_monthly_budget()`):
      ```
      aws budgets create-budget --account-id <ACCOUNT_ID> \
        --budget '{"BudgetName":"MonthlyCostBudget","BudgetLimit":{"Amount":"100","Unit":"USD"},"TimeUnit":"MONTHLY","BudgetType":"COST"}'
      ```
    - Add alert notifications at 80% and 100% thresholds (implements `BudgetManager.add_budget_notification()`):
      ```
      aws budgets create-notification --account-id <ACCOUNT_ID> \
        --budget-name MonthlyCostBudget \
        --notification '{"NotificationType":"ACTUAL","ComparisonOperator":"GREATER_THAN","Threshold":80,"ThresholdType":"PERCENTAGE"}' \
        --subscribers '[{"SubscriptionType":"EMAIL","Address":"your-email@example.com"}]'
      ```
    - _Requirements: 5.1, 5.2_
  - [ ] 6.3 Create a filtered budget and verify budget status
    - Create a budget filtered by a specific service (implements `BudgetManager.create_filtered_budget()`):
      ```
      aws budgets create-budget --account-id <ACCOUNT_ID> \
        --budget '{"BudgetName":"EC2Budget","BudgetLimit":{"Amount":"50","Unit":"USD"},"TimeUnit":"MONTHLY","BudgetType":"COST","CostFilters":{"Service":["Amazon Elastic Compute Cloud - Compute"]}}'
      ```
    - Describe all budgets to verify creation and status (implements `BudgetManager.describe_budgets()`):
      ```
      aws budgets describe-budgets --account-id <ACCOUNT_ID>
      ```
    - Verify output shows budget name, limit, actual spend, and forecasted spend
    - Navigate to AWS Budgets dashboard in the console and confirm budget status display including actual vs. budgeted amounts
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 7. Checkpoint - Validate Analytics and Budgets
  - Verify Cost Explorer filters and groupings work across service, region, and tag dimensions
  - Verify cost forecasts display with confidence intervals
  - Verify budgets exist: `aws budgets describe-budgets --account-id <ACCOUNT_ID>`
  - Verify filtered budget tracks only the specified service
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Configure Cost Anomaly Detection
  - [ ] 8.1 Create an anomaly detection monitor
    - Create a service-level cost anomaly monitor (implements `AnomalyDetectionManager.create_service_monitor()`):
      ```
      aws ce create-anomaly-monitor \
        --anomaly-monitor '{"MonitorName":"ServiceCostMonitor","MonitorType":"DIMENSIONAL","MonitorDimension":"SERVICE"}'
      ```
    - List monitors to verify creation and capture the MonitorArn (implements `AnomalyDetectionManager.list_monitors()`):
      ```
      aws ce get-anomaly-monitors
      ```
    - _Requirements: 6.1_
  - [ ] 8.2 Create an alert subscription and review anomalies
    - Create an alert subscription linked to the monitor (implements `AnomalyDetectionManager.create_alert_subscription()`):
      ```
      aws ce create-anomaly-subscription \
        --anomaly-subscription '{"SubscriptionName":"DailyCostAlerts","MonitorArnList":["<MONITOR_ARN>"],"Threshold":10.0,"Frequency":"DAILY","Subscribers":[{"Type":"EMAIL","Address":"your-email@example.com"}],"ThresholdExpression":{"Dimensions":{"Key":"ANOMALY_TOTAL_IMPACT_ABSOLUTE","Values":["10"],"MatchOptions":["GREATER_THAN_OR_EQUAL"]}}}'
      ```
    - Query for any existing anomalies (implements `AnomalyDetectionManager.get_anomalies()`):
      ```
      aws ce get-anomalies \
        --date-interval '{"StartDate":"2024-01-01","EndDate":"2025-01-31"}'
      ```
    - Navigate to the Cost Anomaly Detection page in the console and verify the monitor and subscription appear
    - Review the anomaly details page layout: severity, duration, root cause service, root cause account, expected vs. actual spend
    - _Requirements: 6.2, 6.3, 6.4_

- [ ] 9. Build Saved Reports and Cost Review Workflow
  - [ ] 9.1 Create and save multiple Cost Explorer reports
    - In Cost Explorer, create a service-level cost breakdown view (grouped by service, monthly, last 3 months) and save as report named "Service Cost Breakdown"
    - Create a tag-based project cost view (grouped by `Project` tag, monthly) and save as "Project Cost View"
    - Create a month-over-month trend analysis (grouped by service, monthly, last 6 months) and save as "Monthly Trend Analysis"
    - Verify all three reports appear in the Saved Reports list with filters, groupings, and time range settings preserved
    - _Requirements: 7.1, 7.2_
  - [ ] 9.2 Verify the Billing home page cost breakdown widget
    - Navigate to the Billing and Cost Management home page
    - Verify the cost breakdown widget displays spending trends for the last six months
    - Test selecting different dimensions from the dropdown: Service, AWS Region, Cost allocation tag, Cost category
    - Confirm the widget updates to reflect the selected grouping dimension
    - _Requirements: 7.3_

- [ ] 10. Checkpoint - Validate Complete Cost Management Setup
  - Verify anomaly monitor exists: `aws ce get-anomaly-monitors`
  - Verify anomaly subscription exists: `aws ce get-anomaly-subscriptions`
  - Verify saved reports are accessible in Cost Explorer (open each and confirm settings preserved)
  - Verify Billing home page cost breakdown widget shows data grouped by service, region, tag, and cost category
  - Confirm budgets show actual vs. budgeted amounts in the Budgets dashboard
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Delete budgets
    - Delete the monthly cost budget: `aws budgets delete-budget --account-id <ACCOUNT_ID> --budget-name MonthlyCostBudget` (implements `BudgetManager.delete_budget()`)
    - Delete the filtered EC2 budget: `aws budgets delete-budget --account-id <ACCOUNT_ID> --budget-name EC2Budget`
    - Verify deletion: `aws budgets describe-budgets --account-id <ACCOUNT_ID>`
    - _Requirements: (all)_
  - [ ] 11.2 Delete anomaly detection resources
    - Delete the anomaly subscription: `aws ce delete-anomaly-subscription --subscription-arn <SUBSCRIPTION_ARN>` (implements `AnomalyDetectionManager.delete_subscription()`)
    - Delete the anomaly monitor: `aws ce delete-anomaly-monitor --monitor-arn <MONITOR_ARN>` (implements `AnomalyDetectionManager.delete_monitor()`)
    - Verify deletion: `aws ce get-anomaly-monitors` and `aws ce get-anomaly-subscriptions`
    - _Requirements: (all)_
  - [ ] 11.3 Delete cost category and deactivate tags
    - Delete the cost category: `aws ce delete-cost-category-definition --cost-category-arn <CATEGORY_ARN>` (implements `TagAndCategoryManager.delete_cost_category()`)
    - Verify deletion: `aws ce list-cost-category-definitions`
    - Deactivate cost allocation tags in the Billing console (navigate to Cost Allocation Tags, select activated tags, click "Deactivate")
    - Note: Cost Explorer itself cannot be disabled once enabled, but incurs no additional charges. Saved reports can be manually deleted from the Saved Reports list if desired.
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Cost Explorer data preparation takes up to 24 hours after initial enablement — plan to complete Task 2 and then proceed to Task 3 (tag activation also requires a refresh cycle), returning to verify data availability before Task 5
- Cost allocation tags require up to 24 hours after activation before appearing in Cost Explorer — activate them early in the workflow
- AWS Budgets allows up to 2 free budgets with actions per account; additional budgets with actions incur charges
- Cost Anomaly Detection is automatically configured with a default monitor when Cost Explorer is first enabled; the task creates an additional explicit monitor for learning purposes
- All CLI commands use placeholder values (e.g., `<ACCOUNT_ID>`, `<MONITOR_ARN>`) — replace with actual values from your environment
