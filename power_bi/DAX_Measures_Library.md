# AdventureWorks DAX Measures Library

## Sales Measures

### Revenue Metrics
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `Total Sales` | `SUM(Sales[SalesAmount])` | Total sales amount across all transactions | Sales & Exec Dashboards |
| `Sales YTD` | `CALCULATE([Total Sales], DATESYTD('Date'[Date]))` | Year-to-date sales | Exec Dashboard |
| `Sales MTD` | `CALCULATE([Total Sales], DATESMTD('Date'[Date]))` | Month-to-date sales | Sales Dashboard |

### Growth Metrics  
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `PY Sales` | `CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))` | Prior year sales for selected period | Sales & Exec Dashboards |
| `Sales YoY %` | `DIVIDE([Total Sales] - [PY Sales], [PY Sales], 0)` | Year-over-year percent growth | Exec Dashboard |
| `Sales vs Target` | `DIVIDE([Total Sales], SUM(Targets[TargetAmount]), 0)` | Achievement percentage against targets | Exec Dashboard |

## Product Measures

### Inventory Metrics
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `Current Inventory Value` | `SUMX(Inventory, Inventory[Quantity] * Product[StandardCost])` | Value of current inventory at standard cost | Inventory Dashboard |
| `Average Unit Cost` | `DIVIDE(SUM(Product[StandardCost]), COUNTROWS(Product))` | Average unit cost across all products | Product Dashboard |
| `Safety Stock Value` | `SUMX(Product, Product[SafetyStockLevel] * Product[StandardCost])` | Value of safety stock at standard cost | Inventory Dashboard |

### Product Performance
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `Product Count` | `COUNTROWS(Product)` | Total number of products | Product Dashboard |
| `Avg Product Margin %` | `AVERAGEX(Product, Product[MarginPercent])` | Average margin percentage across products | Product Dashboard |
| `Top Products Filter` | `IF(ISFILTERED(Product[ProductID]), RANK.EQ(SUM(Sales[SalesAmount]), [Total Sales], DESC) <= 10)` | Helper for top 10 product filtering | Product Dashboard |

## Customer Measures

### Customer Analysis
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `Customer Count` | `DISTINCTCOUNT(Sales[CustomerID])` | Count of unique customers | Sales Dashboard |
| `Avg Sales per Customer` | `DIVIDE([Total Sales], [Customer Count], 0)` | Average sales amount per customer | Sales Dashboard |
| `Returning Customers` | `CALCULATE([Customer Count], FILTER(Customer, Customer[OrderCount] > 1))` | Count of customers with more than one order | Sales Dashboard |

## Time Intelligence Measures

### Period Comparisons
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `Sales PQ` | `CALCULATE([Total Sales], PREVIOUSQUARTER('Date'[Date]))` | Sales in previous quarter | Exec Dashboard |
| `QoQ Change %` | `DIVIDE([Total Sales] - [Sales PQ], [Sales PQ], 0)` | Quarter-over-quarter percentage change | Exec Dashboard |
| `Rolling 12M Sales` | `CALCULATE([Total Sales], DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -12, MONTH))` | Sales in trailing 12 months | Exec Dashboard |

## Model Health Measures

### Diagnostic Measures
| Measure Name | DAX Formula | Description | Used In |
|-------------|------------|-------------|---------|
| `Missing Product Count` | `COUNTROWS(FILTER(Sales, ISBLANK(RELATED(Product[ProductKey]))))` | Count of sales records with missing product keys | Data Quality |
| `Data Last Refreshed` | `MAX('RefreshLog'[RefreshTimestamp])` | Timestamp of last data refresh | All Dashboards |
