

# Requirements Document

## Introduction

This project guides you through building a Business Intelligence (BI) dashboard using Amazon QuickSight, a cloud-powered analytics service that enables interactive data visualization, ad hoc exploration, and insight sharing across an organization. You will learn how to connect QuickSight to AWS data sources, prepare datasets for analysis, and create compelling visualizations and dashboards that transform raw data into actionable business insights.

Business intelligence is a foundational capability for data-driven organizations. Understanding how to build dashboards that surface key performance indicators (KPIs), trends, and anomalies empowers teams to make faster, better-informed decisions. Amazon QuickSight removes the need to manage BI infrastructure while providing features like in-memory computation with SPICE, natural language querying, and machine learning-powered insights — making it an excellent platform for learning modern BI practices.

In this learning exercise, you will work through the full BI workflow: provisioning a QuickSight account, connecting to and preparing data from AWS sources such as Amazon S3 or Amazon Athena, building interactive analyses with multiple visualization types, and publishing a shareable dashboard. You will also explore advanced features including calculated fields, filtering, and ML-powered forecasting to deepen your understanding of self-service analytics.

## Glossary

- **quicksight_account**: A provisioned Amazon QuickSight environment within an AWS account, configured with an edition (Standard or Enterprise) and user management settings.
- **data_source**: A connection configuration in QuickSight that points to an external data store such as Amazon S3, Amazon Athena, Amazon RDS, Amazon Redshift, or a file upload.
- **dataset**: A prepared and optionally transformed collection of data imported or queried from a data source, ready for use in QuickSight analyses and visualizations.
- **spice**: Super-fast, Parallel, In-memory Calculation Engine — QuickSight's in-memory storage that accelerates query performance by importing and caching data for interactive exploration.
- **analysis**: A QuickSight workspace where users build and arrange visualizations, apply filters, and explore data interactively before publishing.
- **visual**: An individual chart, graph, table, or KPI widget within an analysis that represents a specific view of the underlying dataset.
- **dashboard**: A read-only, published snapshot of an analysis that can be shared with other QuickSight users for viewing and interactive filtering.
- **calculated_field**: A custom field created using expressions and functions within a dataset or analysis to derive new metrics or dimensions from existing data.
- **kpi**: Key Performance Indicator — a measurable value displayed in a dashboard that demonstrates how effectively a business objective is being achieved.
- **story**: A guided, sequential tour through specific views of an analysis, used to convey key points or the evolution of an analytical finding for collaboration.

## Requirements

### Requirement 1: QuickSight Account Setup and Data Source Connection

**User Story:** As a BI learner, I want to set up an Amazon QuickSight account and connect it to an AWS data source, so that I can access and analyze data stored in my AWS environment.

#### Acceptance Criteria

1. WHEN the learner signs up for Amazon QuickSight within their AWS account, THE QuickSight environment SHALL be provisioned and accessible through the AWS Management Console.
2. WHEN the learner grants QuickSight access to specific AWS services (such as Amazon S3 or Amazon Athena), THE QuickSight security and permissions configuration SHALL reflect the authorized services.
3. WHEN the learner creates a new data source connection pointing to a supported AWS service, THE data source SHALL be validated and listed as available for dataset creation.
4. IF the learner provides incorrect connection details or insufficient permissions for a data source, THEN QuickSight SHALL indicate a connection failure and the data source SHALL not be created.

### Requirement 2: Dataset Preparation and SPICE Import

**User Story:** As a BI learner, I want to create a dataset from my connected data source and import it into SPICE, so that I can explore the data interactively with fast query performance.

#### Acceptance Criteria

1. WHEN the learner creates a dataset from a configured data source, THE dataset SHALL display the available tables or files and allow the learner to select which data to include.
2. WHEN the learner chooses to import data into SPICE, THE dataset SHALL be ingested into the in-memory engine and the SPICE capacity usage SHALL reflect the imported data size.
3. WHEN the learner applies data preparation steps such as renaming fields, changing data types, or excluding columns, THE resulting dataset SHALL reflect those transformations when used in an analysis.
4. IF the learner's SPICE capacity is insufficient for the dataset size, THEN QuickSight SHALL notify the learner of the capacity limitation before completing the import.

### Requirement 3: Calculated Fields and Data Enrichment

**User Story:** As a BI learner, I want to create calculated fields within my dataset, so that I can derive new metrics and dimensions that are not present in the raw data.

#### Acceptance Criteria

1. WHEN the learner creates a calculated field using arithmetic expressions on existing numeric fields, THE new field SHALL be available as a selectable measure in the analysis.
2. WHEN the learner creates a calculated field using conditional or string functions, THE field SHALL correctly evaluate the expression for each row of data and be usable as a dimension or measure.
3. IF the learner defines a calculated field with an invalid expression or references a non-existent field, THEN QuickSight SHALL display a validation error and the calculated field SHALL not be saved.

### Requirement 4: Interactive Analysis with Multiple Visualization Types

**User Story:** As a BI learner, I want to build an analysis containing multiple visualization types such as bar charts, line charts, pie charts, tables, and KPI widgets, so that I can understand how different visual formats communicate data insights effectively.

#### Acceptance Criteria

1. WHEN the learner creates a new analysis from a prepared dataset, THE analysis workspace SHALL allow adding, arranging, and resizing multiple visuals on one or more sheets.
2. WHEN the learner selects a visualization type and assigns fields to the appropriate field wells (such as axes, values, and groupings), THE visual SHALL render the data according to the selected chart type.
3. WHEN the learner adds a KPI visual with a target value and a comparison metric, THE KPI widget SHALL display the current value, trend direction, and progress toward the target.
4. WHEN the learner modifies the field assignments or visualization type of an existing visual, THE visual SHALL re-render to reflect the updated configuration immediately.

### Requirement 5: Filters and Interactive Controls

**User Story:** As a BI learner, I want to apply filters and add interactive controls to my analysis, so that I can enable dynamic data exploration and allow viewers to focus on specific subsets of data.

#### Acceptance Criteria

1. WHEN the learner adds a filter on a dimension field (such as a date range, category, or region), THE visuals scoped to that filter SHALL display only the data matching the filter criteria.
2. WHEN the learner adds a filter control to a sheet, THE control SHALL appear as an interactive widget (such as a dropdown, slider, or search box) that viewers can use to dynamically adjust the displayed data.
3. IF the learner applies multiple filters simultaneously, THEN THE visuals SHALL display data that satisfies all active filter conditions together.
4. WHEN the learner configures a filter to apply to specific visuals rather than the entire sheet, THE filter SHALL affect only the designated visuals while other visuals remain unfiltered.

### Requirement 6: ML-Powered Insights and Forecasting

**User Story:** As a BI learner, I want to add machine learning-powered forecasting and anomaly detection to my visualizations, so that I can understand how QuickSight's built-in ML capabilities enhance business analysis without requiring data science expertise.

#### Acceptance Criteria

1. WHEN the learner enables forecasting on a time-series line chart, THE visual SHALL display projected future data points beyond the existing data range with a confidence interval.
2. WHEN the learner enables anomaly detection on a visual with time-series data, THE analysis SHALL identify and highlight data points that deviate significantly from expected patterns.
3. WHEN the learner adds a narrative insight (auto-narrative) to the analysis, THE insight SHALL generate a natural language summary describing key trends, outliers, or notable changes in the underlying data.

### Requirement 7: Dashboard Publishing and Sharing

**User Story:** As a BI learner, I want to publish my analysis as a dashboard and share it with other users, so that I can understand how QuickSight distributes read-only BI content across an organization.

#### Acceptance Criteria

1. WHEN the learner publishes an analysis as a dashboard, THE dashboard SHALL be created as a read-only view that preserves all visuals, layouts, filters, and interactive controls from the analysis.
2. WHEN the learner shares the dashboard with another QuickSight user or group, THE specified recipients SHALL be able to view and interact with the dashboard's filters and drill-down capabilities without modifying the underlying analysis.
3. IF the learner updates the source analysis and republishes the dashboard, THEN THE dashboard SHALL reflect the latest changes from the analysis.
4. WHEN a viewer interacts with filters or controls on the published dashboard, THE viewer's filter selections SHALL apply only to their own session and SHALL NOT affect other viewers' experiences.
