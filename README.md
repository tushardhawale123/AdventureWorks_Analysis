# AdventureWorks Data Analysis Project

## Overview
This repository contains SQL scripts and Power BI solutions for analyzing the AdventureWorks database. The project delivers comprehensive business insights through interactive dashboards focused on sales performance, inventory management, product profitability, and executive KPIs. It demonstrates SQL data extraction, transformation, modeling, and visualization techniques using Microsoft's sample AdventureWorks database.

## Data Source
The AdventureWorks2019 sample database was used for this project, available from Microsoft's official link:
https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

## Repository Contents
- **SQL Scripts**: TSQL queries for data transformation and analysis
- **Data Dictionary**: Documentation of database schema and relationships
- **Metadata**: Foreign key relationships and table row counts for reference
- **Power BI Reports**: Interactive dashboards and reports (PBIX files)
- **Documentation**: Implementation guides and technical details

## Repository Structure
```
AdventureWorks_Analysis/
│
├── README.md                          # Project overview and documentation
├── DATA_DICTIONARY.md                 # Comprehensive data dictionary
│
├── sql/                               # SQL scripts directory
│   ├── analysis/                      # Analytical queries
│   │   ├── sales_performance.sql      # Sales analysis queries
│   │   ├── product_profitability.sql  # Product analysis
│   │   ├── customer_segmentation.sql  # Customer analysis
│   │   └── inventory_management.sql   # Inventory analysis
│   │
│   ├── views/                         # Views for Power BI consumption
│   │   ├── vw_DimCustomer.sql         # Customer dimension view
│   │   ├── vw_DimProduct.sql          # Product dimension view
│   │   ├── vw_DimDate.sql             # Date dimension view
│   │   ├── vw_FactSales.sql           # Sales fact view
│   │   └── vw_FactInventory.sql       # Inventory fact view
│   │
│   └── utility/                       # Utility scripts
│       ├── create_indexes.sql         # Performance optimization scripts
│       └── refresh_views.sql          # View refresh utility
│
├── powerbi/                           # Power BI files
│   ├── AdventureWorks_Executive.pbix  # Executive dashboard
│   ├── AdventureWorks_Sales.pbix      # Sales analysis
│   ├── AdventureWorks_Product.pbix    # Product analysis
│   └── AdventureWorks_Inventory.pbix  # Inventory management
│
├── data/                              # Data files
│   └── metadata/                      # Database metadata
│       ├── foreign_key_relationships.csv
│       └── table_row_counts.csv
│
├── docs/                              # Documentation
│   ├── dax_measures.md                # DAX measures documentation
│   ├── power_query_transformations.md # Power Query transformations
│   └── implementation_guide.md        # Implementation instructions
│
└── images/                            # Dashboard screenshots
    ├── exec_dash.png                  # Executive dashboard
    ├── sales_dash.png                 # Sales dashboard
    ├── product_dash.png               # Product dashboard
    └── inventory_dash.png             # Inventory dashboard
```

## Power BI Dashboards

### Executive Dashboard
Provides a high-level overview of key business metrics and KPIs including:
- YTD Sales vs Target
- Top Products by Revenue
- Sales Trends by Territory
- Margin Analysis
- Key Customer Segments

### Sales Dashboard
Detailed sales analysis with filtering capabilities by:
- Territory, Product Category, Time Period
- Customer Segmentation
- Sales Channel Comparison
- Order Fulfillment Analysis
- Sales Representative Performance

### Product Dashboard
Comprehensive product performance analysis including:
- Category and Subcategory Performance
- Product Profitability
- Price Point Analysis
- Inventory-to-Sales Ratio
- Product Lifecycle Stage Analysis

### Inventory Dashboard
Inventory optimization and management metrics:
- Current Stock Levels vs Reorder Points
- Inventory Turnover Rates
- Slow-Moving Inventory Identification
- Stock Value by Location
- Days-of-Supply Analysis

## Key Analysis Areas

### Sales Performance
- Territory-based sales analysis
- Time-based trends (YoY, QoQ, MoM)
- Customer purchasing patterns
- Sales channel effectiveness
- Order value and frequency analysis

### Product Profitability
- Margin analysis by product and category
- Price elasticity impact
- Special offer effectiveness
- Cross-selling opportunities
- Product cost analysis

### Inventory Management
- Stock optimization recommendations
- Turnover rates by product category
- Seasonal inventory planning
- Stock-out risk assessment
- Warehouse capacity utilization

### Customer Insights
- RFM (Recency, Frequency, Monetary) segmentation
- Customer lifetime value estimation
- Geographic distribution analysis
- Customer acquisition and retention trends
- Purchase behavior patterns

## Tools & Technologies Used
- **SQL Server 2019**: For data querying and analysis
- **Power BI Desktop**: For visualization and dashboard creation
- **DAX**: For measures and calculated columns
- **Power Query (M)**: For data transformation
- **Star Schema Modeling**: For dimensional model design
- **GitHub**: For version control and collaboration

## Installation & Setup

### Database Setup
1. Download AdventureWorks2019 database from Microsoft
2. Restore database in SQL Server Management Studio:
   ```sql
   RESTORE DATABASE AdventureWorks2019
   FROM DISK = 'C:\Path\To\AdventureWorks2019.bak'
   WITH MOVE 'AdventureWorks2017' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2019.mdf',
   MOVE 'AdventureWorks2017_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2019_log.ldf'
   ```
3. Create the analytical views by executing the SQL scripts in the `sql/views` folder

### Power BI Setup
1. Open the PBIX files in the `powerbi` folder
2. Update the data source connection to your SQL Server instance
3. Refresh the data model
4. Review the data model relationships to ensure proper configuration

## Example Queries

### Sales by Territory and Year
```sql
SELECT 
    st.Name AS TerritoryName, 
    st.[Group] AS Region,
    YEAR(soh.OrderDate) AS OrderYear,
    FORMAT(SUM(soh.TotalDue), 'C') AS TotalSales,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    COUNT(DISTINCT soh.CustomerID) AS CustomerCount
FROM 
    Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY 
    st.Name, 
    st.[Group],
    YEAR(soh.OrderDate)
ORDER BY 
    Region, 
    TerritoryName, 
    OrderYear;
```

### Product Profitability
```sql
SELECT 
    p.Name AS ProductName,
    pc.Name AS Category,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
    SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost)) AS TotalProfit,
    (SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost)) / SUM(sod.LineTotal)) * 100 AS ProfitMarginPct
FROM 
    Sales.SalesOrderDetail sod
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.Name,
    pc.Name
ORDER BY 
    TotalProfit DESC;
```

## Data Model

The Power BI model follows a star schema design with:

### Fact Tables
- **FactSales**: Sales transaction data at the line item level
- **FactInventory**: Current inventory levels by product and location

### Dimension Tables
- **DimDate**: Calendar dates with fiscal and reporting attributes
- **DimCustomer**: Customer information with demographics
- **DimProduct**: Product details with categories and costs
- **DimTerritory**: Geographic regions and sales territories
- **DimSalesPerson**: Sales team information and targets

### Key Relationships
- FactSales[ProductID] → DimProduct[ProductID]
- FactSales[CustomerID] → DimCustomer[CustomerID]
- FactSales[OrderDate] → DimDate[Date]
- FactSales[TerritoryID] → DimTerritory[TerritoryID]
- FactInventory[ProductID] → DimProduct[ProductID]

## Key DAX Measures

```
// Total Sales
Total Sales = SUM(FactSales[SalesAmount])

// Year-to-Date Sales
Sales YTD = 
TOTALYTD([Total Sales], 'DimDate'[Date])

// Previous Year Sales for Comparison
Sales PY = 
CALCULATE([Total Sales], SAMEPERIODLASTYEAR('DimDate'[Date]))

// Year-over-Year Growth
YoY Growth % = 
DIVIDE([Total Sales] - [Sales PY], [Sales PY], 0)

// Gross Margin
Margin = 
SUM(FactSales[SalesAmount]) - SUM(FactSales[ProductCost])

// Margin Percent
Margin % = 
DIVIDE([Margin], SUM(FactSales[SalesAmount]), 0)

// Inventory Turnover Rate
Inventory Turnover = 
DIVIDE(
    CALCULATE([Total Sales], 'DimDate'[DateKey] >= TODAY() - 90),
    AVERAGEX(FactInventory, [InventoryValue])
)
```

## Learning Notes
This project is part of my ongoing learning journey as a data analyst. While I've aimed for production-ready code, some scripts and dashboards are experimental and may contain areas for improvement. I'm continuously refining my skills in SQL optimization, Power BI development, and data modeling.

Some complex queries and DAX formulas were developed with AI assistance to tackle challenging analytical problems. These sections are marked with comments and have been manually reviewed, though there may still be opportunities for optimization.

## Future Enhancements
- Implement automated data refresh with Power Automate
- Add predictive analytics for sales forecasting
- Develop mobile-optimized dashboard layouts
- Create customer segmentation using RFM analysis
- Implement row-level security for territory-based access

## Contact
Created by [Tushar Dhawale](https://github.com/tushardhawale123)  
Last Updated: 2025-04-29
