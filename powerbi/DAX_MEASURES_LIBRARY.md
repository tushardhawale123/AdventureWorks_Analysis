# DAX Measures Library

# AdventureWorks Analysis - DAX Measures Library

This document provides a comprehensive reference for all DAX measures used in the AdventureWorks Analysis Power BI reports.

## Sales Measures

### Core Sales Metrics
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Total Sales | `SUM(SalesOrderDetail[LineTotal])` | Sum of all sales line totals |
| Total Orders | `DISTINCTCOUNT(SalesOrderHeader[SalesOrderID])` | Count of distinct sales orders |
| Average Order Value | `DIVIDE([Total Sales], [Total Orders], 0)` | Average value per order |
| Order Count | `COUNTROWS(SalesOrderHeader)` | Count of all orders |
| Items Sold | `SUM(SalesOrderDetail[OrderQty])` | Total quantity of items sold |
| Average Unit Price | `DIVIDE([Total Sales], [Items Sold], 0)` | Average price per unit sold |

### Time Intelligence
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Sales YTD | `TOTALYTD([Total Sales], 'Date'[Date])` | Year-to-date sales |
| Sales MTD | `TOTALMTD([Total Sales], 'Date'[Date])` | Month-to-date sales |
| Sales QTD | `TOTALQTD([Total Sales], 'Date'[Date])` | Quarter-to-date sales |
| Sales PY | `CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))` | Sales for same period last year |
| Sales YoY % | `DIVIDE([Total Sales] - [Sales PY], [Sales PY], 0)` | Year-over-year percentage growth |
| Sales Rolling 12M | `CALCULATE([Total Sales], DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -12, MONTH))` | Rolling 12-month sales |

### Sales Analysis
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Margin | `[Total Sales] - [Total Cost]` | Gross margin (sales minus costs) |
| Margin % | `DIVIDE([Margin], [Total Sales], 0)` | Margin as percentage of sales |
| Sales per Day | `DIVIDE([Total Sales], COUNTROWS(VALUES('Date'[Date])), 0)` | Average sales per day |
| Sales per Customer | `DIVIDE([Total Sales], DISTINCTCOUNT(Customer[CustomerID]), 0)` | Average sales per customer |
| Customers with Orders | `DISTINCTCOUNT(SalesOrderHeader[CustomerID])` | Count of customers who placed orders |
| New Customers | `CALCULATE(DISTINCTCOUNT(Customer[CustomerID]), Customer[FirstPurchaseDate] = MAX('Date'[Date]))` | Count of first-time customers |

## Product Measures

### Product Performance
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Product Count | `DISTINCTCOUNT(Product[ProductID])` | Count of distinct products sold |
| Avg Sales per Product | `DIVIDE([Total Sales], [Product Count], 0)` | Average sales per product |
| Top Product Sales | `MAXX(TOPN(1, ALL(Product), [Product Sales]), [Product Sales])` | Sales of the top-selling product |
| Product Sales | `CALCULATE([Total Sales], ALLEXCEPT(Product, Product[ProductID]))` | Sales by individual product |
| Product Margin % | `DIVIDE(CALCULATE([Margin], ALLEXCEPT(Product, Product[ProductID])), CALCULATE([Total Sales], ALLEXCEPT(Product, Product[ProductID])), 0)` | Margin percentage by product |
| Days Since Last Sale | `DATEDIFF(MAX(SalesOrderHeader[OrderDate]), TODAY(), DAY)` | Days since the most recent sale |

### Category Analysis
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Category Sales | `CALCULATE([Total Sales], ALLEXCEPT(ProductCategory, ProductCategory[ProductCategoryID]))` | Sales by product category |
| Category Sales % | `DIVIDE([Category Sales], [Total Sales], 0)` | Category sales as percentage of total |
| Subcategory Sales | `CALCULATE([Total Sales], ALLEXCEPT(ProductSubcategory, ProductSubcategory[ProductSubcategoryID]))` | Sales by product subcategory |
| Subcategory Sales % | `DIVIDE([Subcategory Sales], [Category Sales], 0)` | Subcategory sales as percentage of category |
| Top Category | `MAXX(TOPN(1, ALL(ProductCategory), [Category Sales]), ProductCategory[Name])` | Name of top-selling category |

## Inventory Measures

### Inventory Analysis
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Current Inventory Qty | `SUM(ProductInventory[Quantity])` | Current inventory quantity |
| Inventory Value | `SUMX(ProductInventory, ProductInventory[Quantity] * RELATED(Product[StandardCost]))` | Current inventory value at standard cost |
| Avg Inventory Days | `DIVIDE([Current Inventory Qty], ([Items Sold] / COUNTROWS(VALUES('Date'[Date]))), 0)` | Avg days of inventory based on sales rate |
| Stock to Sales Ratio | `DIVIDE([Inventory Value], [Total Sales], 0)` | Ratio of inventory value to sales |
| Low Stock Products | `COUNTAX(Product, CALCULATE(SUM(ProductInventory[Quantity]), ALLEXCEPT(Product, Product[ProductID])) < Product[ReorderPoint])` | Count of products below reorder point |
| Out of Stock Products | `COUNTAX(Product, CALCULATE(SUM(ProductInventory[Quantity]), ALLEXCEPT(Product, Product[ProductID])) = 0)` | Count of products with zero inventory |

## Customer Measures

### Customer Analysis
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Customer Count | `DISTINCTCOUNT(Customer[CustomerID])` | Count of distinct customers |
| Active Customers | `CALCULATE(DISTINCTCOUNT(Customer[CustomerID]), FILTER(SalesOrderHeader, SalesOrderHeader[OrderDate] >= DATE(YEAR(NOW()), MONTH(NOW())-12, DAY(NOW()))))` | Customers with orders in last 12 months |
| Customer Retention % | `DIVIDE([Active Customers], [Customer Count], 0)` | Percentage of retained customers |
| Avg Customer Age (Days) | `AVERAGEX(Customer, DATEDIFF(Customer[FirstPurchaseDate], NOW(), DAY))` | Average customer relationship age in days |
| Returning Customers | `CALCULATE(DISTINCTCOUNT(SalesOrderHeader[CustomerID]), FILTER(SalesOrderHeader, COUNTROWS(FILTER(SalesOrderHeader, SalesOrderHeader[CustomerID] = EARLIER(SalesOrderHeader[CustomerID]))) > 1))` | Count of customers with multiple orders |
| Avg Orders per Customer | `DIVIDE([Order Count], [Customer Count], 0)` | Average number of orders per customer |

## Territory Measures

### Geographic Analysis
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Territory Sales | `CALCULATE([Total Sales], ALLEXCEPT(SalesTerritory, SalesTerritory[TerritoryID]))` | Sales by territory |
| Territory Sales % | `DIVIDE([Territory Sales], [Total Sales], 0)` | Territory sales as percentage of total |
| Territory YoY % | `DIVIDE([Territory Sales] - CALCULATE([Territory Sales], SAMEPERIODLASTYEAR('Date'[Date])), CALCULATE([Territory Sales], SAMEPERIODLASTYEAR('Date'[Date])), 0)` | Territory year-over-year growth |
| Top Territory | `MAXX(TOPN(1, ALL(SalesTerritory), [Territory Sales]), SalesTerritory[Name])` | Name of top-selling territory |
| State Sales | `CALCULATE([Total Sales], ALLEXCEPT(StateProvince, StateProvince[StateProvinceID]))` | Sales by state/province |
| Country Sales | `CALCULATE([Total Sales], ALLEXCEPT(CountryRegion, CountryRegion[CountryRegionCode]))` | Sales by country |

## Employee Measures

### Sales Employee Performance
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Sales per Employee | `DIVIDE([Total Sales], DISTINCTCOUNT(SalesPerson[BusinessEntityID]), 0)` | Average sales per sales employee |
| Quota Achievement % | `DIVIDE([Total Sales], SUM(SalesPersonQuotaHistory[SalesQuota]), 0)` | Sales as percentage of quota |
| Employees Above Quota | `COUNTAX(SalesPerson, CALCULATE([Total Sales], ALLEXCEPT(SalesPerson, SalesPerson[BusinessEntityID])) > CALCULATE(MAX(SalesPersonQuotaHistory[SalesQuota]), ALLEXCEPT(SalesPerson, SalesPerson[BusinessEntityID])))` | Count of employees exceeding quota |
| Avg Quota | `AVERAGE(SalesPersonQuotaHistory[SalesQuota])` | Average sales quota |
| Top Performer | `MAXX(TOPN(1, ALL(SalesPerson), CALCULATE([Total Sales], ALLEXCEPT(SalesPerson, SalesPerson[BusinessEntityID]))), SalesPerson[SalesPersonName])` | Name of top-performing salesperson |

## Executive Dashboard Measures

### KPI Measures
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Revenue Target | `VAR CurrentYearStart = DATE(YEAR(MAX('Date'[Date])), 1, 1) RETURN CALCULATE(SUM('KPI Targets'[RevenueTarget]), FILTER('KPI Targets', 'KPI Targets'[Year] = YEAR(CurrentYearStart)))` | Revenue target from targets table |
| Target Achievement % | `DIVIDE([Total Sales], [Revenue Target], 0)` | Percentage of target achieved |
| Growth Target | `VAR CurrentYear = YEAR(MAX('Date'[Date])) VAR PriorYearSales = CALCULATE([Total Sales], FILTER(ALL('Date'), YEAR('Date'[Date]) = CurrentYear - 1)) RETURN PriorYearSales * 1.1` | Target of 10% growth over prior year |
| Profit Target Achievement % | `DIVIDE([Margin], [Profit Target], 0)` | Percentage of profit target achieved |
| Days Left in Period | `DATEDIFF(MAX('Date'[Date]), ENDOFQUARTER(MAX('Date'[Date])), DAY)` | Days remaining in current quarter |
| Required Daily Sales | `DIVIDE([Revenue Target] - [Total Sales], [Days Left in Period], 0)` | Daily sales needed to reach target |

## Conditional Formatting Measures

### Status Indicators
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Sales Status | `IF([Target Achievement %] >= 1, "Achieved", IF([Target Achievement %] >= 0.9, "At Risk", "Behind"))` | Status based on target achievement |
| Product Status | `IF([Current Inventory Qty] = 0, "Out of Stock", IF([Current Inventory Qty] < [ReorderPoint], "Low Stock", "In Stock"))` | Product inventory status |
| YoY Status | `IF([Sales YoY %] > 0.05, "Growth", IF([Sales YoY %] > 0, "Stable", "Declining"))` | Status based on year-over-year performance |
| Margin Status | `IF([Margin %] > 0.4, "Excellent", IF([Margin %] > 0.3, "Good", IF([Margin %] > 0.2, "Average", "Poor")))` | Status based on margin percentage |

## Time Calculation Measures

### Date Intelligence
| Measure Name | DAX Formula | Description |
|-------------|-------------|-------------|
| Days Since Last Purchase | `DATEDIFF(MAX(SalesOrderHeader[OrderDate]), TODAY(), DAY)` | Days since most recent order |
| Order Fulfillment Days | `AVERAGEX(SalesOrderHeader, DATEDIFF(SalesOrderHeader[OrderDate], SalesOrderHeader[ShipDate], DAY))` | Average days between order and shipment |
| Weekday Sales | `CALCULATE([Total Sales], FILTER('Date', WEEKDAY('Date'[Date], 1) <= 5))` | Sales on weekdays |
| Weekend Sales | `CALCULATE([Total Sales], FILTER('Date', WEEKDAY('Date'[Date], 1) > 5))` | Sales on weekends |
| Weekend Sales % | `DIVIDE([Weekend Sales], [Total Sales], 0)` | Percentage of sales on weekends |
| Quarter over Quarter Growth | `DIVIDE([Total Sales] - CALCULATE([Total Sales], PREVIOUSQUARTER('Date'[Date])), CALCULATE([Total Sales], PREVIOUSQUARTER('Date'[Date])), 0)` | Quarterly growth percentage |

## Notes on Measure Usage

1. **Filter Context Awareness**
   - All measures respond to filters applied in reports
   - Measures use CALCULATE for context transition where needed
   - Time intelligence measures require a proper date table with continuous dates

2. **Performance Considerations**
   - Complex measures are optimized for large data volumes
   - Context transitions are minimized for performance
   - Variables (VAR) are used to prevent redundant calculations

3. **Naming Conventions**
   - All measure names are concise and clear
   - Related measures are grouped with consistent prefixes
   - Percentage measures end with %

4. **Dependencies**
   - All measures assume standard AdventureWorks schema
   - Date table with proper date hierarchy is required
   - Calculated columns may be created to support certain measures

5. **Formatting Standards**
   - Sales and monetary values: Currency with 2 decimal places
   - Percentages: Percentage with 1 decimal place
   - Counts: Whole numbers
   - Averages: Varies based on measure context
