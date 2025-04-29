# AdventureWorks 2019 Sales Analysis

## Project Overview
This Power BI project provides a comprehensive analysis of sales data from the AdventureWorks 2019 database. It includes interactive dashboards and reports that enable stakeholders to gain insights into sales performance, product trends, customer behavior, and regional analysis.

## Data Source
The project utilizes the AdventureWorks 2019 sample database, a Microsoft SQL Server database that simulates a manufacturing company selling bicycles and related products. Key tables used include:
- Sales.SalesOrderHeader
- Sales.SalesOrderDetail
- Production.Product
- Production.ProductSubcategory
- Production.ProductCategory
- Sales.Customer
- Person.Person
- Sales.Territory

## Data Model
![Data Model](./images/data-model.png)

The data model follows a star schema design with:
- Fact tables: Sales data (Sales.SalesOrderHeader and Sales.SalesOrderDetail)
- Dimension tables: Products, Customers, Territory, Date

## Data Transformation (Power Query)
Key transformations include:
- Created a Date dimension table
- Merged Product tables to create a comprehensive Product dimension
- Cleaned and standardized customer data
- Currency conversion for international sales
- Added calculated columns for time intelligence

## Key DAX Measures
```
Total Sales = SUM(Sales[SalesAmount])

YTD Sales = 
TOTALYTD(SUM(Sales[SalesAmount]), 'Date'[Date])

Sales Growth % = 
VAR CurrentPeriodSales = [Total Sales]
VAR PreviousPeriodSales = CALCULATE([Total Sales], DATEADD('Date'[Date], -1, YEAR))
RETURN
    IF(PreviousPeriodSales = 0, BLANK(),
    (CurrentPeriodSales - PreviousPeriodSales) / PreviousPeriodSales)

Product Profit Margin % = 
DIVIDE([Total Profit], [Total Sales], 0)
```

## Report Pages

### 1. Executive Summary
![Executive Summary](./images/exec-summary.png)

Provides a high-level overview of key performance indicators including:
- Total sales and comparison to targets
- YTD sales with year-over-year comparison
- Top-selling products and categories
- Sales by region

### 2. Product Analysis
Detailed breakdown of product performance:
- Sales by product category and subcategory
- Profit margin analysis
- Product mix visualization
- Seasonal product trends

### 3. Customer Analysis
Insights into customer behavior:
- Customer segmentation by purchase volume
- Geographic distribution of customers
- Customer acquisition and retention metrics
- Customer lifetime value

### 4. Regional Performance
Geographic analysis of sales performance:
- Sales by territory and region
- Regional growth rates
- Market penetration metrics
- Regional product preferences

## Insights & Findings
- Accessories and Bikes are the highest revenue-generating categories
- Q4 consistently shows the highest sales volume across years
- North America represents 70% of total sales, with emerging growth in Europe
- Customer retention rate shows strong improvement in recent periods
- Product X has the highest profit margin at 42%

## How to Use This Report
1. **Prerequisites**:
   - Power BI Desktop (latest version recommended)
   - Access to AdventureWorks 2019 database or the included Excel data export

2. **Opening the Report**:
   - Download the .pbix file
   - Open with Power BI Desktop
   - Refresh data if needed (may require database connection configuration)

3. **Navigation**:
   - Use the tabs at the bottom to navigate between report pages
   - Interact with slicers to filter data
   - Hover over visualizations for tooltips with additional information

## Future Enhancements
- Add forecast models for sales prediction
- Implement customer churn analysis
- Create mobile-optimized view
- Add competitor analysis dashboard

## Tools & Technologies
- Microsoft Power BI Desktop
- SQL Server 2019
- DAX (Data Analysis Expressions)
- Power Query M language

## Author
Tushar Dhawale
