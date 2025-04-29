# AdventureWorks 2019 Power BI - Technical Documentation

## Database Connection Details

### Connection Method
- Direct Query / Import Mode: [Specify which you used]
- Server: [Server name or connection details]
- Authentication: [Authentication method used]

## Data Model Details

### Table Relationships
| Primary Table | Primary Column | Foreign Table | Foreign Column | Relationship Type |
|--------------|---------------|--------------|---------------|------------------|
| DimProduct | ProductKey | FactSales | ProductKey | Many-to-One |
| DimCustomer | CustomerKey | FactSales | CustomerKey | Many-to-One |
| DimDate | DateKey | FactSales | OrderDateKey | Many-to-One |
| DimTerritory | TerritoryKey | FactSales | TerritoryKey | Many-to-One |

### Calculated Tables
| Table Name | DAX Query | Purpose |
|------------|----------|---------|
| DateTable | `CALENDAR(DATE(2011,1,1), DATE(2019,12,31))` | Date dimension for time intelligence |
| SalesTargets | `...` | Table for comparing actual vs target sales |

## Power Query Transformations

### Product Table Transformations
```
let
    Source = Sql.Database("server", "AdventureWorks2019"),
    Production_Product = Source{[Schema="Production",Item="Product"]}[Data],
    #"Merged Queries" = Table.NestedJoin(
        Production_Product,
        {"ProductSubcategoryID"}, 
        ProductSubcategory, 
        {"ProductSubcategoryID"}, 
        "ProductSubcategory", 
        JoinKind.LeftOuter
    ),
    #"Expanded ProductSubcategory" = Table.ExpandTableColumn(
        #"Merged Queries", 
        "ProductSubcategory", 
        {"ProductCategoryID", "Name"}, 
        {"ProductSubcategory.ProductCategoryID", "ProductSubcategory.Name"}
    )
in
    #"Expanded ProductSubcategory"
```

### Sales Data Transformations
[Include your specific Power Query M code here]

## Calculated Measures Documentation

### Sales Metrics
| Measure Name | DAX Formula | Purpose |
|-------------|------------|---------|
| Total Sales | `SUM(Sales[SalesAmount])` | Calculates the sum of all sales |
| Sales YoY% | `VAR CurrentYearSales = [Total Sales] VAR PreviousYearSales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date])) RETURN DIVIDE(CurrentYearSales - PreviousYearSales, PreviousYearSales, BLANK())` | Year-over-year sales growth percentage |

### Profit Metrics
| Measure Name | DAX Formula | Purpose |
|-------------|------------|---------|
| Total Profit | `SUM(Sales[SalesAmount]) - SUM(Sales[TotalProductCost])` | Calculates total profit |
| Profit Margin | `DIVIDE([Total Profit], [Total Sales], 0)` | Calculates profit as percentage of sales |

## Performance Optimization Techniques
1. **Query Folding Implementation**:
   - All Power Query transformations were designed to leverage query folding
   - Complex transformations were moved to the database layer where possible

2. **DAX Optimization**:
   - Avoided complex calculations in iterative contexts
   - Used variables to store intermediate results
   - Implemented filter context modifications carefully

3. **Data Volume Management**:
   - Filtered unnecessary historical data before import
   - Implemented incremental refresh with the following parameters:
     - Refresh Window: Rolling 3 years
     - Increment: 1 month

## Report Pages Implementation Details

### Executive Dashboard
- **KPI Cards**: Implemented using the Card visual with conditional formatting
- **Timeline**: Implemented using the Timeline slicer custom visual
- **Main Chart**: Uses small multiples technique for year-over-year comparison

### Geographic Analysis Implementation
- Map visual uses latitude/longitude for precise positioning
- Custom tooltips provide detailed regional performance metrics
- Region highlighting implemented via bookmarks and selection panes

## Known Issues and Limitations
1. Territory data missing for some international sales (workaround: created "Unknown" territory)
2. Product costs only available from 2016 onward (note: profit calculations only valid for this period)
3. Customer data required extensive cleansing; some records may still contain inconsistencies

