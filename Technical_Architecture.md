# AdventureWorks Data Warehouse - Technical Architecture

## Overview
This document describes the technical architecture of the AdventureWorks Data Warehouse project, including data flow, system components, and integration points.

## Architecture Diagram
```
[Source]                  [ETL Layer]                [Data Warehouse]           [Semantic Layer]      [Presentation]
+---------------+        +-----------------+        +-------------------+      +---------------+     +--------------+
| AdventureWorks|        | Staging         |        | Dimension Tables  |      | Power BI      |     | Power BI     |
| OLTP Database |------->| Database        |------->| Fact Tables       |----->| Semantic     |---->| Reports &    |
| (SQL Server)  |        | (SQL Server)    |        | (SQL Server)      |      | Model        |     | Dashboards   |
+---------------+        +-----------------+        +-------------------+      +---------------+     +--------------+
      ^                          |                           ^
      |                          v                           |
+---------------+        +-----------------+                 |
| Reference     |        | Error Logging   |                 |
| Data          |------->| & Monitoring    |-----------------+
| (Excel, CSV)  |        | (SQL Server)    |
+---------------+        +-----------------+
```

## Component Descriptions

### Source Systems
- **AdventureWorks OLTP Database**: Primary source system containing all business transactions
- **Reference Data**: Supplementary data from external sources (e.g., currency exchange rates)

### ETL Layer
- **Staging Database**: Temporary storage for extracted data before transformation
- **TSQL Stored Procedures**: Extract, transform and load routines
- **Error Logging & Monitoring**: Tracks ETL job execution, data quality issues, and load statistics

### Data Warehouse
- **Dimension Tables**: Store descriptive attributes for business entities (customers, products, etc.)
- **Fact Tables**: Store business metrics and measurements associated with business events
- **Partitioning Strategy**: Fact tables are partitioned by date for improved performance

### Semantic Layer
- **Power BI Semantic Model**: Contains business metrics, KPIs, and dimensional hierarchies
- **Row-level Security**: Implements data access controls based on user roles

### Presentation Layer
- **Power BI Reports**: Interactive visualizations for business users
- **Power BI Dashboards**: Aggregated views of KPIs and metrics
- **Excel Integration**: Self-service analysis capabilities

## Data Flow Process
1. Data is extracted from source systems using TSQL stored procedures
2. Extracted data is staged in the staging database
3. Data quality checks are performed on staged data
4. Dimension tables are updated using SCD Type 2 methodology
5. Fact tables are incrementally loaded
6. Semantic model is refreshed
7. Reports and dashboards receive updated data

## Security Implementation
- Column-level encryption for sensitive data
- Row-level security in the semantic model
- Role-based access control for dashboard users
- Audit logging for data access and modifications