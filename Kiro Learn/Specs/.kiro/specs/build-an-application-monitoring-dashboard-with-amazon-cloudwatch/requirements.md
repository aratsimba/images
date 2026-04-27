

# Requirements Document

## Introduction

This project guides you through building an Application Monitoring Dashboard using Amazon CloudWatch. CloudWatch is a foundational AWS observability service that provides unified visibility into cloud resources and the applications running on them. Understanding how to design and configure effective dashboards is a critical skill for anyone responsible for operating, maintaining, or troubleshooting applications in the AWS Cloud.

In this learning exercise, you will create a CloudWatch dashboard that brings together metrics, alarms, and log insights to provide a holistic view of application health and performance. You will work with standard AWS service metrics, configure alarms to detect threshold breaches, visualize log data alongside metrics, and explore advanced features like Contributor Insights and cross-service observability. The goal is to build a single-pane-of-glass monitoring experience that could serve as the operational nerve center for a cloud-based application.

By completing this project, you will understand how CloudWatch collects and visualizes operational data, how to design dashboards that follow operational best practices, and how to correlate signals across metrics, logs, and alarms to quickly identify and respond to performance issues.

## Glossary

- **cloudwatch_dashboard**: A customizable page in the CloudWatch console that displays a collection of widgets showing metrics, logs, alarms, and other operational data for AWS resources and applications.
- **cloudwatch_metric**: A time-ordered set of data points representing the behavior of an AWS resource or application component, collected at user-defined intervals.
- **cloudwatch_alarm**: A rule that continuously monitors a single CloudWatch metric against a user-defined threshold and transitions between states (OK, ALARM, INSUFFICIENT_DATA) based on evaluation results.
- **metric_widget**: A visual component on a dashboard that renders metric data as a line graph, stacked area chart, number, gauge, or bar chart.
- **markdown_widget**: A text-based dashboard widget that uses Markdown formatting to add titles, descriptions, links, and contextual documentation to a dashboard.
- **custom_metric**: A metric published to CloudWatch by an application or script rather than automatically emitted by an AWS service, used to track application-specific key performance indicators.
- **metric_filter**: A CloudWatch Logs feature that extracts numeric values or counts from log events and converts them into CloudWatch metrics for graphing and alarming.
- **contributor_insights**: A CloudWatch feature that analyzes high-cardinality fields in log or time-series data to identify the top contributors to a given metric pattern.
- **cloudwatch_agent**: Software installed on an EC2 instance or on-premises server that collects system-level metrics and application logs and sends them to CloudWatch.
- **automatic_dashboard**: A pre-built, service-specific dashboard that CloudWatch provides out of the box for supported AWS services, requiring no manual configuration.

## Requirements

### Requirement 1: CloudWatch Dashboard Creation and Layout

**User Story:** As a cloud monitoring learner, I want to create a CloudWatch dashboard with descriptive context and logically arranged widgets, so that I can build a centralized view of application health.

#### Acceptance Criteria

1. WHEN the learner creates a new CloudWatch dashboard with a descriptive name, THE dashboard SHALL be accessible from the CloudWatch console and ready to accept widgets.
2. THE dashboard SHALL include at least one Markdown widget that provides a title, description, and explanation of the dashboard's purpose and scope.
3. WHEN the learner adds multiple widgets to the dashboard, THE widgets SHALL be arranged in logical groupings (e.g., compute metrics together, error-related metrics together) to support efficient visual scanning.
4. IF the learner specifies a dashboard name that already exists within the same account, THEN THE service SHALL update the existing dashboard rather than creating a duplicate.

### Requirement 2: AWS Service Metric Visualization

**User Story:** As a cloud monitoring learner, I want to add widgets that visualize standard AWS service metrics, so that I can monitor the operational health of compute, storage, and other resources.

#### Acceptance Criteria

1. WHEN the learner adds a metric widget for an EC2 instance, THE widget SHALL display at least CPU utilization and network traffic metrics over a selectable time range.
2. THE dashboard SHALL include metrics from at least two different AWS services (e.g., EC2 and a database or load balancing service) to demonstrate cross-service visibility.
3. WHEN the learner selects different visualization types (line graph, number, gauge) for different metrics, THE dashboard SHALL render each widget in its chosen format to best represent the underlying data.
4. WHEN the learner adjusts the dashboard time range, THE metric widgets SHALL update to reflect data for the newly selected period.

### Requirement 3: Custom Metric Publishing and Display

**User Story:** As a cloud monitoring learner, I want to publish and visualize a custom metric in CloudWatch, so that I understand how to monitor application-specific key performance indicators that are not automatically reported by AWS services.

#### Acceptance Criteria

1. WHEN the learner publishes a custom metric with a namespace, metric name, and at least one dimension, THE metric SHALL appear in the CloudWatch custom namespaces and be selectable for dashboard widgets.
2. THE custom metric SHALL include a meaningful unit of measurement (e.g., Count, Milliseconds, Percent) that accurately describes the data being tracked.
3. WHEN the learner adds the custom metric to a dashboard widget, THE widget SHALL display the custom metric data alongside or independently of standard AWS service metrics.

### Requirement 4: CloudWatch Alarm Configuration and Dashboard Integration

**User Story:** As a cloud monitoring learner, I want to create CloudWatch alarms that monitor key metrics and display alarm states on my dashboard, so that I can quickly identify when resources breach operational thresholds.

#### Acceptance Criteria

1. WHEN the learner creates a CloudWatch alarm with a defined threshold, evaluation period, and comparison operator, THE alarm SHALL transition to the ALARM state when the monitored metric breaches the threshold.
2. THE alarm SHALL be configured with a notification action that sends a message to an Amazon SNS topic when the alarm state changes.
3. WHEN the learner adds an alarm status widget to the dashboard, THE widget SHALL display the current state of all configured alarms with visual indicators distinguishing OK, ALARM, and INSUFFICIENT_DATA states.
4. IF the monitored metric returns to within the defined threshold, THEN THE alarm SHALL transition back to the OK state and the dashboard widget SHALL reflect the updated state.

### Requirement 5: Log Insights and Metric Filters on the Dashboard

**User Story:** As a cloud monitoring learner, I want to visualize log data and create metric filters from application logs, so that I can correlate log events with performance metrics on the same dashboard.

#### Acceptance Criteria

1. WHEN the learner creates a metric filter on a CloudWatch Logs log group with a defined filter pattern, THE filter SHALL generate a corresponding CloudWatch metric that counts or extracts values from matching log events.
2. THE dashboard SHALL include at least one widget that displays the metric generated by the metric filter alongside related service metrics to enable visual correlation.
3. WHEN the learner adds a CloudWatch Logs Insights query widget to the dashboard, THE widget SHALL execute the query against a specified log group and display the results within the dashboard.

### Requirement 6: Contributor Insights and Advanced Observability

**User Story:** As a cloud monitoring learner, I want to enable Contributor Insights and explore automatic dashboards, so that I can identify top contributors to resource usage patterns and understand CloudWatch's built-in observability capabilities.

#### Acceptance Criteria

1. WHEN the learner creates a Contributor Insights rule for a supported resource, THE rule SHALL analyze incoming data and produce a ranked list of top contributors based on the specified key fields.
2. WHEN the learner adds the Contributor Insights results to the dashboard, THE widget SHALL display the top contributors with their relative contribution values.
3. THE learner SHALL navigate to and review at least one CloudWatch automatic dashboard for an active AWS service to understand the pre-built monitoring views that CloudWatch provides without manual configuration.

### Requirement 7: Dashboard Sharing and Operational Best Practices

**User Story:** As a cloud monitoring learner, I want to configure dashboard sharing and apply operational design best practices, so that I can distribute monitoring views to stakeholders and maintain dashboards as applications evolve.

#### Acceptance Criteria

1. WHEN the learner enables dashboard sharing, THE dashboard SHALL be accessible via a shareable link to users who may not have direct AWS console credentials.
2. THE dashboard SHALL demonstrate a hierarchical design pattern with at least one high-level overview section and one detailed drill-down section, supporting efficient operational triage.
3. WHEN the learner configures the dashboard auto-refresh interval, THE dashboard SHALL periodically update all widgets at the specified frequency without requiring manual page reloads.
4. THE dashboard configuration SHALL be exportable as a dashboard body definition so that it can be version-controlled and redeployed consistently across environments.
