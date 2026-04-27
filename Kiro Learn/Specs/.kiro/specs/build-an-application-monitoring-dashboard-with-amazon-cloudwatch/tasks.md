

# Implementation Plan: Application Monitoring Dashboard with Amazon CloudWatch

## Overview

This implementation builds an Application Monitoring Dashboard using Amazon CloudWatch through four Python components: DashboardManager, MetricsPublisher, AlarmsManager, and LogsInsightsManager. Each component uses boto3 to interact with AWS services and contributes widget definitions that are assembled into a comprehensive dashboard providing cross-service observability.

The approach follows an incremental build-up strategy. After setting up the environment and project structure, we implement each component in dependency order: first the DashboardManager (foundation for all widgets), then MetricsPublisher (custom metrics), AlarmsManager (alarms and SNS), and LogsInsightsManager (metric filters, Logs Insights, and Contributor Insights). Each component adds widgets to the dashboard progressively. The final phase covers dashboard sharing, export, operational best practices, and verification of the complete dashboard.

Key dependencies dictate ordering: the DashboardManager must exist before any widgets can be assembled; an EC2 instance and log group must be running before metrics and logs can be visualized; SNS topics must be created before alarms can reference them; and metric filters must exist before their generated metrics can be displayed. Checkpoints after major milestones validate that each layer of the dashboard is functioning correctly before proceeding.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with permissions for CloudWatch, CloudWatch Logs, SNS, and EC2
    - Configure AWS CLI: `aws configure`
    - Verify access: `aws sts get-caller-identity`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2; verify: `aws --version`
    - Install Python 3.12; verify: `python3 --version`
    - Install boto3: `pip install boto3`; verify: `python3 -c "import boto3; print(boto3.__version__)"`
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Prerequisite Resources
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Ensure at least one EC2 instance is running: `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId"`
    - Ensure a CloudWatch Logs log group exists with sample log data (e.g., `/aws/app/sample-logs`): `aws logs describe-log-groups --log-group-name-prefix /aws/app/`
    - If no log group exists, create one and push sample JSON log events containing fields like `statusCode`, `latency`, `sourceIP`: `aws logs create-log-group --log-group-name /aws/app/sample-logs` then use `aws logs put-log-events` to insert sample data
    - Create the project directory structure: `mkdir -p cloudwatch-dashboard/components` and create `cloudwatch-dashboard/components/__init__.py`
    - _Requirements: (all)_

- [ ] 2. Implement DashboardManager and Create Initial Dashboard
  - [ ] 2.1 Create DashboardManager component
    - Create `components/dashboard_manager.py` with class `DashboardManager`
    - Initialize `boto3.client('cloudwatch')` in the constructor
    - Implement `create_dashboard(dashboard_name, dashboard_body)` using `put_dashboard()` API — serialize dashboard_body to JSON
    - Implement `get_dashboard(dashboard_name)` using `get_dashboard()` API
    - Implement `delete_dashboard(dashboard_name)` using `delete_dashboards()` API
    - Implement `assemble_dashboard(widgets)` that returns a `DashboardBody` dictionary with `{"widgets": widgets}`
    - Implement `export_dashboard_body(dashboard_name)` that calls `get_dashboard()` and returns the raw JSON string for version control
    - _Requirements: 1.1, 1.4, 7.4_
  - [ ] 2.2 Implement widget builder functions
    - Implement `build_markdown_widget(title, description, x, y, width, height)` returning a `WidgetDefinition` dict with `type: "text"` and markdown-formatted properties
    - Implement `build_metric_widget(metrics, title, view, x, y, width, height, period)` returning a `WidgetDefinition` dict with `type: "metric"` — `view` parameter supports `"timeSeries"`, `"singleValue"`, `"gauge"`, `"bar"`
    - Implement `build_alarm_status_widget(alarm_arns, title, x, y, width, height)` returning a `WidgetDefinition` dict with `type: "alarm"`
    - Implement `build_log_insights_widget(log_group_name, query, title, x, y, width, height)` returning a `WidgetDefinition` dict with `type: "log"` and the query in properties
    - Implement `build_contributor_insights_widget(rule_name, title, x, y, width, height)` returning a `WidgetDefinition` dict with `type: "explorer"` referencing the Contributor Insights rule
    - _Requirements: 1.2, 1.3, 2.3_
  - [ ] 2.3 Create initial dashboard with markdown and EC2 metric widgets
    - Create a main script `build_dashboard.py` that orchestrates dashboard creation
    - Use `build_markdown_widget()` to create a header widget with dashboard title, purpose description, and scope explanation at position (0, 0)
    - Use `build_metric_widget()` to add EC2 CPUUtilization metric widget — metrics format: `["AWS/EC2", "CPUUtilization", "InstanceId", "<your-instance-id>"]` with `view: "timeSeries"`, grouped in a compute section
    - Use `build_metric_widget()` to add EC2 NetworkIn/NetworkOut metrics widget with `view: "timeSeries"`
    - Assemble widgets using `assemble_dashboard()` and create the dashboard with `create_dashboard("AppMonitoringDashboard", body)`
    - Verify dashboard exists: `aws cloudwatch get-dashboard --dashboard-name AppMonitoringDashboard`
    - Verify updating with same name updates rather than duplicates by calling `create_dashboard()` again with the same name
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.4_

- [ ] 3. Implement MetricsPublisher and Add Cross-Service Metrics
  - [ ] 3.1 Create MetricsPublisher component
    - Create `components/metrics_publisher.py` with class `MetricsPublisher`
    - Initialize `boto3.client('cloudwatch')` in the constructor
    - Implement `publish_custom_metric(namespace, metric_name, value, unit, dimensions)` using `put_metric_data()` — dimensions format: `[{"Name": "AppName", "Value": "SampleApp"}]`
    - Implement `publish_metric_batch(namespace, metric_data)` using `put_metric_data()` with multiple `MetricDatum` entries in the `MetricData` list for batch publishing
    - Implement `get_metric_statistics(namespace, metric_name, dimensions, start_time, end_time, period, statistics)` using `get_metric_statistics()`
    - Implement `list_custom_metrics(namespace)` using `list_metrics()` filtered by namespace
    - _Requirements: 3.1, 3.2_
  - [ ] 3.2 Publish custom metrics and add cross-service widgets to dashboard
    - Publish a custom metric: namespace `"CustomApp"`, metric name `"RequestLatency"`, unit `"Milliseconds"`, dimension `[{"Name": "Environment", "Value": "Production"}]` — publish several data points with varying values
    - Publish a second custom metric: `"ErrorCount"` with unit `"Count"` in the same namespace
    - Verify custom metric appears: `aws cloudwatch list-metrics --namespace CustomApp`
    - Use `get_metric_statistics()` to verify data retrieval for the published custom metric
    - Add a metric widget for the custom `RequestLatency` metric using `build_metric_widget()` with `view: "gauge"`
    - Add metric widgets from a second AWS service (e.g., `AWS/EBS` VolumeReadOps or `AWS/EC2` StatusCheckFailed) using `build_metric_widget()` with `view: "singleValue"` to demonstrate different visualization types
    - Group custom metric widgets separately from AWS service metric widgets in the layout using distinct y-positions
    - Update the dashboard with all new widgets using `assemble_dashboard()` and `create_dashboard()`
    - _Requirements: 2.2, 2.3, 3.1, 3.2, 3.3_

- [ ] 4. Checkpoint - Validate Dashboard with Metrics
  - Open CloudWatch console and navigate to Dashboards, verify "AppMonitoringDashboard" appears
  - Confirm markdown widget displays title and description
  - Confirm EC2 CPU and network metric widgets render with data over selectable time range
  - Confirm custom metric widget displays published RequestLatency data
  - Confirm at least two different AWS services are represented on the dashboard
  - Confirm different visualization types (line graph, number/singleValue, gauge) are rendered correctly
  - Adjust dashboard time range in the console and verify metric widgets update accordingly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement AlarmsManager with SNS Integration
  - [ ] 5.1 Create AlarmsManager component
    - Create `components/alarms_manager.py` with class `AlarmsManager`
    - Initialize `boto3.client('cloudwatch')` and `boto3.client('sns')` in the constructor
    - Implement `create_sns_topic(topic_name)` using `sns.create_topic()`, return the topic ARN
    - Implement `subscribe_email(topic_arn, email)` using `sns.subscribe(Protocol='email')`, return subscription ARN
    - Implement `create_alarm(alarm_name, namespace, metric_name, dimensions, threshold, comparison_operator, evaluation_periods, period, statistic, alarm_actions, ok_actions)` using `put_metric_alarm()`
    - Implement `get_alarm_state(alarm_name)` using `describe_alarms(AlarmNames=[alarm_name])`
    - Implement `list_alarms()` using `describe_alarms()` returning all alarm details
    - Implement `get_alarm_arns(alarm_names)` that calls `describe_alarms()` and extracts ARNs
    - Implement `delete_alarm(alarm_name)` using `delete_alarms()`
    - Implement `delete_sns_topic(topic_arn)` using `sns.delete_topic()`
    - _Requirements: 4.1, 4.2_
  - [ ] 5.2 Create alarms and add alarm status widget to dashboard
    - Create an SNS topic: `create_sns_topic("AppMonitoringAlarms")` and note the returned ARN
    - Subscribe an email endpoint: `subscribe_email(topic_arn, "your-email@example.com")` — confirm subscription from email inbox
    - Create a CPU utilization alarm: `create_alarm("HighCPUAlarm", "AWS/EC2", "CPUUtilization", [...], threshold=80.0, comparison_operator="GreaterThanThreshold", evaluation_periods=2, period=300, statistic="Average", alarm_actions=[topic_arn], ok_actions=[topic_arn])`
    - Create a custom metric alarm: `create_alarm("HighErrorCount", "CustomApp", "ErrorCount", [...], threshold=10.0, comparison_operator="GreaterThanThreshold", evaluation_periods=1, period=60, statistic="Sum", alarm_actions=[topic_arn], ok_actions=[topic_arn])`
    - Retrieve alarm ARNs using `get_alarm_arns(["HighCPUAlarm", "HighErrorCount"])`
    - Add alarm status widget to dashboard using `build_alarm_status_widget(alarm_arns, "Alarm Status", ...)` — this widget shows OK, ALARM, and INSUFFICIENT_DATA states with visual indicators
    - Update dashboard with the alarm status widget using `assemble_dashboard()` and `create_dashboard()`
    - Verify alarm states: `get_alarm_state("HighCPUAlarm")` — confirm state is OK or INSUFFICIENT_DATA
    - Verify alarm transitions: publish a high custom ErrorCount value to trigger the alarm, then verify it transitions to ALARM; publish low values and verify it returns to OK
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 6. Implement LogsInsightsManager with Metric Filters and Contributor Insights
  - [ ] 6.1 Create LogsInsightsManager component
    - Create `components/logs_insights_manager.py` with class `LogsInsightsManager`
    - Initialize `boto3.client('logs')` and `boto3.client('cloudwatch')` in the constructor
    - Implement `create_metric_filter(log_group_name, filter_name, filter_pattern, metric_namespace, metric_name, metric_value, default_value)` using `put_metric_filter()` with `metricTransformations` parameter
    - Implement `delete_metric_filter(log_group_name, filter_name)` using `delete_metric_filter()`
    - Implement `run_insights_query(log_group_name, query, start_time, end_time)` using `start_query()` and `get_query_results()` — poll until query completes
    - Implement `create_contributor_insights_rule(rule_name, log_group_name, rule_body)` using `cloudwatch.put_insight_rule()` — rule_body should be JSON-serialized `ContributorInsightsRuleBody`
    - Implement `get_contributor_insights_report(rule_name, start_time, end_time)` using `cloudwatch.get_insight_rule_report()`
    - Implement `delete_contributor_insights_rule(rule_name)` using `cloudwatch.delete_insight_rules()`
    - _Requirements: 5.1, 5.3, 6.1_
  - [ ] 6.2 Create metric filters and add log-based widgets to dashboard
    - Create a metric filter on the sample log group: `create_metric_filter("/aws/app/sample-logs", "ErrorCountFilter", "ERROR", "CustomApp/Logs", "LogErrorCount", "1", 0.0)` — this counts ERROR occurrences
    - Verify the metric filter generates a metric: `aws cloudwatch list-metrics --namespace CustomApp/Logs`
    - Add a metric widget displaying the `LogErrorCount` metric alongside the `ErrorCount` custom metric using `build_metric_widget()` to enable visual correlation
    - Run a Logs Insights query: `run_insights_query("/aws/app/sample-logs", "fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)", start_time, end_time)`
    - Add a Logs Insights query widget using `build_log_insights_widget("/aws/app/sample-logs", query_string, "Error Log Analysis", ...)`
    - _Requirements: 5.1, 5.2, 5.3_
  - [ ] 6.3 Configure Contributor Insights and add to dashboard
    - Create a Contributor Insights rule: `create_contributor_insights_rule("TopErrorSources", "/aws/app/sample-logs", rule_body)` where `rule_body` contains `ContributorInsightsRuleBody` with `Schema: {"Name": "CloudWatchLogRule", "Version": 1}`, `Keys` like `["sourceIP"]`, and `AggregateOn: "Count"`
    - Verify the rule is active: `get_contributor_insights_report("TopErrorSources", start_time, end_time)` — confirm it returns a ranked list of top contributors
    - Add Contributor Insights widget to dashboard using `build_contributor_insights_widget("TopErrorSources", "Top Error Contributors", ...)`
    - Update the complete dashboard with all new widgets
    - _Requirements: 6.1, 6.2_

- [ ] 7. Checkpoint - Validate Full Dashboard Functionality
  - Open CloudWatch console, verify dashboard shows all widget types: markdown, metric (multiple views), alarm status, Logs Insights query, and Contributor Insights
  - Verify alarm status widget shows correct states with visual indicators for OK, ALARM, and INSUFFICIENT_DATA
  - Verify metric filter widget displays log-derived metric alongside related service metrics
  - Verify Logs Insights query widget executes and displays results
  - Verify Contributor Insights widget shows ranked top contributors
  - Navigate to CloudWatch automatic dashboards (left panel → "Overview" or service-specific auto-dashboards) and review at least one auto-dashboard for an active AWS service (e.g., EC2)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Dashboard Sharing, Export, and Operational Best Practices
  - [ ] 8.1 Implement dashboard sharing and enable auto-refresh
    - Implement `enable_sharing(dashboard_name)` in DashboardManager — note: CloudWatch dashboard sharing requires enabling it via the console or `aws cloudwatch enable-insight-rules` is not the correct API; use the CloudWatch console: Actions → Share dashboard → generate shareable link for users without AWS credentials
    - Document the sharing steps: navigate to dashboard → Actions → Share dashboard → choose sharing option → copy shareable URL
    - Configure dashboard auto-refresh: in the console, select a refresh interval (e.g., 1 minute or 5 minutes) from the auto-refresh dropdown — verify widgets update automatically at the specified frequency
    - _Requirements: 7.1, 7.3_
  - [ ] 8.2 Apply hierarchical design and export dashboard
    - Reorganize the dashboard layout with a hierarchical pattern: place a high-level overview section at the top (markdown header + alarm status + key number widgets showing critical KPIs) and detailed drill-down sections below (expanded metric graphs, Logs Insights, Contributor Insights)
    - Ensure logical groupings: compute metrics together, error-related metrics together, log analysis widgets together — use distinct y-coordinates for each section
    - Update dashboard with the reorganized layout using `assemble_dashboard()` and `create_dashboard()`
    - Export dashboard body using `export_dashboard_body("AppMonitoringDashboard")` — save the returned JSON string to `dashboard_export.json` for version control
    - Verify export: read `dashboard_export.json` and confirm it contains all widget definitions
    - _Requirements: 1.3, 6.3, 7.2, 7.4_
  - [ ]* 8.3 Validate operational best practices
    - **Property 1: Dashboard Sharing Accessibility**
    - **Validates: Requirements 7.1, 7.3**

- [ ] 9. Checkpoint - Final Validation
  - Verify the complete dashboard displays all required components: markdown header, EC2 metrics (CPU + network), cross-service metrics, custom metrics, alarm status, metric filter widget, Logs Insights query widget, and Contributor Insights widget
  - Verify hierarchical layout with overview section and drill-down sections
  - Verify auto-refresh is configured and widgets update periodically
  - Verify dashboard body export file `dashboard_export.json` is valid JSON and redeployable
  - Confirm dashboard sharing is enabled and a shareable link is available
  - Confirm at least one CloudWatch automatic dashboard was reviewed
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Cleanup - Resource Teardown
  - [ ] 10.1 Delete CloudWatch dashboard and alarms
    - Delete the dashboard: `aws cloudwatch delete-dashboards --dashboard-names AppMonitoringDashboard`
    - Delete alarms: `aws cloudwatch delete-alarms --alarm-names HighCPUAlarm HighErrorCount`
    - Verify: `aws cloudwatch describe-alarms --alarm-names HighCPUAlarm HighErrorCount` returns empty
    - _Requirements: (all)_
  - [ ] 10.2 Delete Contributor Insights rules, metric filters, and SNS resources
    - Delete Contributor Insights rule: `aws cloudwatch delete-insight-rules --rule-names TopErrorSources`
    - Delete metric filter: `aws logs delete-metric-filter --log-group-name /aws/app/sample-logs --filter-name ErrorCountFilter`
    - Delete SNS subscriptions: `aws sns list-subscriptions-by-topic --topic-arn <topic-arn>` then `aws sns unsubscribe --subscription-arn <sub-arn>` for each
    - Delete SNS topic: `aws sns delete-topic --topic-arn <topic-arn>`
    - _Requirements: (all)_
  - [ ] 10.3 Clean up sample resources and verify
    - If the log group was created for this exercise: `aws logs delete-log-group --log-group-name /aws/app/sample-logs`
    - Remove custom metrics data — note: CloudWatch custom metrics expire automatically based on retention, no manual deletion needed
    - Delete exported file: `rm dashboard_export.json`
    - Verify no dashboard remains: `aws cloudwatch list-dashboards` — confirm AppMonitoringDashboard is not listed
    - Verify no lingering SNS topics: `aws sns list-topics` — confirm the AppMonitoringAlarms topic is removed
    - **Warning**: If you created an EC2 instance solely for this exercise, terminate it to avoid ongoing charges: `aws ec2 terminate-instances --instance-ids <instance-id>`
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The EC2 instance and log group are prerequisites that must exist before starting task 2; if they don't exist, create them in task 1.3
- CloudWatch dashboard sharing via API is limited; the console-based sharing approach is documented in task 8.1
- Custom metrics may take up to 15 minutes to appear after publishing (in calls to ListMetrics); allow time before verifying in widgets
- Contributor Insights requires JSON-formatted log events for field extraction; ensure sample log data follows JSON format
