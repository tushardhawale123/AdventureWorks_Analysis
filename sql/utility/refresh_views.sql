SET NOCOUNT ON;
PRINT '============================================================';
PRINT 'Starting analytics view refresh process';
PRINT 'Start time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '============================================================';

DECLARE @ViewStartTime DATETIME;
DECLARE @TotalStartTime DATETIME = GETDATE();
DECLARE @ViewName NVARCHAR(128);
DECLARE @SchemaName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ErrorMessage NVARCHAR(MAX);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @RowCount INT;

-- Log table for refresh operations
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ViewRefreshLog' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ViewRefreshLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        ViewName NVARCHAR(128) NOT NULL,
        RefreshDateTime DATETIME NOT NULL DEFAULT GETDATE(),
        DurationMS INT NOT NULL,
        Status NVARCHAR(50) NOT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        RowCount INT NULL
    );
    PRINT 'Created logging table dbo.ViewRefreshLog';
END

BEGIN TRY
    -- =============================================
    -- 1. DimDate View
    -- =============================================
    SET @ViewName = 'vw_DimDate';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    WITH CTE_DatesTable AS (
        SELECT CAST(''2011-01-01'' AS date) AS DateValue 
        UNION ALL
        SELECT DATEADD(day, 1, DateValue)
        FROM CTE_DatesTable
        WHERE DATEADD(day, 1, DateValue) <= ''2025-12-31''
    )
    SELECT
        -- Date keys
        CAST(CONVERT(varchar, DateValue, 112) AS int) AS DateKey,
        DateValue AS [Date],
        
        -- Calendar hierarchy
        YEAR(DateValue) AS [Year],
        CONCAT(''Q'', DATEPART(quarter, DateValue)) AS [Quarter],
        MONTH(DateValue) AS MonthNumber,
        DATENAME(month, DateValue) AS MonthName,
        DAY(DateValue) AS [Day],
        
        -- Day properties
        DATEPART(dayofyear, DateValue) AS DayOfYear,
        DATENAME(weekday, DateValue) AS DayOfWeek,
        CASE 
            WHEN DATENAME(weekday, DateValue) IN (''Saturday'', ''Sunday'') THEN 1 
            ELSE 0 
        END AS IsWeekend,
        
        -- Week information
        DATEPART(week, DateValue) AS WeekOfYear,
        
        -- Month End flag
        CASE 
            WHEN DateValue = EOMONTH(DateValue) THEN 1 
            ELSE 0 
        END AS IsMonthEnd,
        
        -- Fiscal Year (assuming July-June fiscal year)
        CASE 
            WHEN MONTH(DateValue) >= 7 THEN YEAR(DateValue) + 1 
            ELSE YEAR(DateValue) 
        END AS FiscalYear,
        
        -- Fiscal Quarter
        CONCAT(''FQ'', 
            CASE 
                WHEN MONTH(DateValue) BETWEEN 7 AND 9 THEN 1
                WHEN MONTH(DateValue) BETWEEN 10 AND 12 THEN 2
                WHEN MONTH(DateValue) BETWEEN 1 AND 3 THEN 3
                WHEN MONTH(DateValue) BETWEEN 4 AND 6 THEN 4
            END) AS FiscalQuarter,
        
        -- Year-Month for sorting
        CONCAT(YEAR(DateValue), ''-'', RIGHT(''0'' + CAST(MONTH(DateValue) AS varchar(2)), 2)) AS YearMonth,
        
        -- Current date flags
        CASE WHEN DateValue = CAST(GETDATE() AS date) THEN 1 ELSE 0 END AS IsToday,
        CASE WHEN DateValue = DATEADD(DAY, -1, CAST(GETDATE() AS date)) THEN 1 ELSE 0 END AS IsYesterday,
        CASE 
            WHEN DateValue BETWEEN DATEADD(DAY, -30, CAST(GETDATE() AS date)) AND CAST(GETDATE() AS date) 
            THEN 1 ELSE 0 
        END AS IsLast30Days
    FROM 
        CTE_DatesTable
    OPTION (MAXRECURSION 5000);';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- 2. DimCustomer View
    -- =============================================
    SET @ViewName = 'vw_DimCustomer';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    SELECT 
        -- Keys
        c.CustomerID,
        c.PersonID,
        c.StoreID,
        c.TerritoryID,
        
        -- Customer attributes
        CASE
            WHEN p.BusinessEntityID IS NOT NULL THEN 
                p.FirstName + '' '' + ISNULL(p.MiddleName + '' '', '''') + p.LastName
            ELSE s.Name
        END AS CustomerName,
        
        CASE
            WHEN c.PersonID IS NULL THEN ''Store''
            ELSE ''Individual''
        END AS CustomerType,
        
        -- Person details (for individual customers)
        p.FirstName,
        p.MiddleName,
        p.LastName,
        p.Title,
        CASE p.EmailPromotion
            WHEN 0 THEN ''No Email Promotions''
            WHEN 1 THEN ''Email Promotions to Customer''
            WHEN 2 THEN ''Email Promotions from Partners''
        END AS EmailPromotionStatus,
        
        -- Store details (for store customers)
        s.Name AS StoreName,
        CASE 
            WHEN s.BusinessEntityID IS NOT NULL THEN
                ISNULL(sprs.FirstName + '' '', '''') + ISNULL(sprs.LastName, ''No Sales Person'')
            ELSE NULL
        END AS StoreSalesPerson,
        
        -- Address information
        a.AddressLine1,
        a.AddressLine2,
        a.City,
        sp.Name AS StateProvinceName,
        sp.StateProvinceCode,
        cr.Name AS CountryRegionName,
        a.PostalCode,
        
        -- Territory grouping
        st.Name AS TerritoryName,
        st.[Group] AS Region,
        
        -- Additional customer metadata
        CASE
            WHEN soh.CustomerID IS NOT NULL THEN 1
            ELSE 0
        END AS HasOrders,
        
        MIN(soh.OrderDate) AS FirstOrderDate,
        MAX(soh.OrderDate) AS MostRecentOrderDate,
        COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders
    FROM 
        Sales.Customer c
        LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
        LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
        LEFT JOIN Sales.SalesPerson sp ON s.SalesPersonID = sp.BusinessEntityID
        LEFT JOIN Person.Person sprs ON sp.BusinessEntityID = sprs.BusinessEntityID
        LEFT JOIN Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
        LEFT JOIN Person.BusinessEntityAddress bea ON 
            CASE 
                WHEN c.PersonID IS NOT NULL THEN c.PersonID
                ELSE c.StoreID
            END = bea.BusinessEntityID
        LEFT JOIN Person.Address a ON bea.AddressID = a.AddressID
        LEFT JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
        LEFT JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
        LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID,
        c.PersonID,
        c.StoreID,
        c.TerritoryID,
        p.BusinessEntityID,
        p.FirstName,
        p.MiddleName,
        p.LastName,
        p.Title,
        p.EmailPromotion,
        s.Name,
        s.BusinessEntityID,
        sprs.FirstName,
        sprs.LastName,
        a.AddressLine1,
        a.AddressLine2,
        a.City,
        sp.Name,
        sp.StateProvinceCode,
        cr.Name,
        a.PostalCode,
        st.Name,
        st.[Group];';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- 3. DimProduct View
    -- =============================================
    SET @ViewName = 'vw_DimProduct';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    SELECT
        -- Keys
        p.ProductID,
        p.ProductSubcategoryID,
        ps.ProductCategoryID,
        
        -- Product attributes
        p.Name AS ProductName,
        p.ProductNumber,
        ISNULL(p.Color, ''N/A'') AS Color,
        p.Size,
        p.SizeUnitMeasureCode,
        p.WeightUnitMeasureCode,
        p.Weight,
        p.StandardCost,
        p.ListPrice,
        
        -- Product categorization
        ps.Name AS ProductSubcategory,
        pc.Name AS ProductCategory,
        pm.Name AS ProductModel,
        
        -- Product status
        CASE p.FinishedGoodsFlag
            WHEN 1 THEN ''Finished Goods''
            ELSE ''Raw Material''
        END AS ProductType,
        
        CASE p.MakeFlag
            WHEN 1 THEN ''Manufactured In-house''
            ELSE ''Purchased''
        END AS SourceType,
        
        -- Product classification (custom)
        CASE
            WHEN p.ListPrice >= 2000 THEN ''Premium''
            WHEN p.ListPrice >= 1000 THEN ''High-end''
            WHEN p.ListPrice >= 500 THEN ''Mid-range''
            ELSE ''Economy''
        END AS PriceCategory,
        
        -- Inventory details
        p.SafetyStockLevel,
        p.ReorderPoint,
        
        -- Product lifecycle
        p.SellStartDate,
        p.SellEndDate,
        
        -- Status flags
        CASE
            WHEN p.SellEndDate IS NULL THEN 1
            WHEN p.SellEndDate > GETDATE() THEN 1
            ELSE 0
        END AS IsActive,
        
        CASE
            WHEN p.ListPrice = 0 THEN 1
            ELSE 0
        END AS IsZeroPriced,
        
        -- Calculated metrics
        DATEDIFF(day, p.SellStartDate, ISNULL(p.SellEndDate, GETDATE())) AS DaysInMarket,
        CASE
            WHEN p.ListPrice = 0 THEN 0
            ELSE (p.ListPrice - p.StandardCost) / p.ListPrice
        END AS GrossMarginPct
    FROM
        Production.Product p
        LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
        LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
        LEFT JOIN Production.ProductModel pm ON p.ProductModelID = pm.ProductModelID;';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- 4. DimTerritory View
    -- =============================================
    SET @ViewName = 'vw_DimTerritory';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    SELECT
        -- Keys
        st.TerritoryID,
        st.CountryRegionCode,
        
        -- Territory attributes
        st.Name AS TerritoryName,
        st.[Group] AS Region,
        cr.Name AS CountryRegionName,
        
        -- Geography grouping (for maps)
        CASE st.[Group]
            WHEN ''North America'' THEN 1
            WHEN ''Europe'' THEN 2
            WHEN ''Pacific'' THEN 3
            ELSE 4
        END AS RegionSortOrder,
        
        -- Sales management
        ISNULL(p.FirstName + '' '' + p.LastName, ''Unassigned'') AS SalesManager,
        
        -- Cost centers
        st.CostYTD,
        st.CostLastYear,
        
        -- YTD calculations
        CASE
            WHEN st.SalesYTD = 0 THEN 0
            ELSE st.CostYTD / st.SalesYTD
        END AS CostToSalesRatioYTD
    FROM
        Sales.SalesTerritory st
        LEFT JOIN Person.CountryRegion cr ON st.CountryRegionCode = cr.CountryRegionCode
        LEFT JOIN (
            SELECT
                sp.TerritoryID,
                p.FirstName,
                p.LastName,
                ROW_NUMBER() OVER (PARTITION BY sp.TerritoryID ORDER BY sp.ModifiedDate DESC) as RowNum
            FROM
                Sales.SalesPerson sp
                JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
        ) p ON st.TerritoryID = p.TerritoryID AND p.RowNum = 1;';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- 5. DimSalesPerson View
    -- =============================================
    SET @ViewName = 'vw_DimSalesPerson';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    SELECT
        -- Keys
        sp.BusinessEntityID AS SalesPersonID,
        sp.TerritoryID,
        
        -- Person details
        p.FirstName,
        p.LastName,
        p.FirstName + '' '' + p.LastName AS SalesPersonName,
        e.JobTitle,
        
        -- Territory information
        st.Name AS TerritoryName,
        st.[Group] AS Region,
        
        -- Sales metrics
        sp.SalesQuota,
        sp.Bonus,
        sp.CommissionPct,
        sp.SalesYTD,
        sp.SalesLastYear,
        
        -- Employee details
        e.HireDate,
        e.BirthDate,
        e.Gender,
        DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsWithCompany,
        
        -- Department information
        d.Name AS Department,
        d.GroupName AS DepartmentGroup,
        
        -- Current status
        CASE
            WHEN e.CurrentFlag = 1 THEN ''Active''
            ELSE ''Inactive''
        END AS Status
    FROM
        Sales.SalesPerson sp
        JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
        JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
        LEFT JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID
        LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
            AND edh.EndDate IS NULL
        LEFT JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID;';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- 6. FactSales View
    -- =============================================
    SET @ViewName = 'vw_FactSales';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    SELECT
        -- Keys
        sod.SalesOrderID,
        sod.SalesOrderDetailID,
        soh.CustomerID,
        sod.ProductID,
        soh.SalesPersonID,
        soh.TerritoryID,
        
        -- Date keys for date dimension
        CAST(CONVERT(varchar, soh.OrderDate, 112) AS int) AS OrderDateKey,
        CAST(CONVERT(varchar, soh.DueDate, 112) AS int) AS DueDateKey,
        CAST(CONVERT(varchar, soh.ShipDate, 112) AS int) AS ShipDateKey,
        
        -- Dates
        soh.OrderDate,
        soh.DueDate,
        soh.ShipDate,
        
        -- Quantity and revenue
        sod.OrderQty,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.LineTotal AS SalesAmount,
        sod.OrderQty * sod.UnitPrice AS GrossAmount,
        sod.OrderQty * sod.UnitPriceDiscount AS DiscountAmount,
        
        -- Calculated fields
        sod.OrderQty * p.StandardCost AS ProductCost,
        sod.LineTotal - (sod.OrderQty * p.StandardCost) AS Margin,
        
        -- Order information
        soh.OnlineOrderFlag,
        soh.PurchaseOrderNumber,
        soh.AccountNumber,
        soh.CreditCardID,
        ISNULL(cc.CardType, ''N/A'') AS CardType,
        soh.CurrencyRateID,
        ISNULL(cr.EndOfDayRate, 1) AS CurrencyConversionRate,
        
        -- Shipping information
        soh.ShipMethodID,
        sm.Name AS ShippingMethod,
        soh.Freight AS FreightCost,
        
        -- Status
        CASE soh.Status
            WHEN 1 THEN ''In Process''
            WHEN 2 THEN ''Approved''
            WHEN 3 THEN ''Backordered''
            WHEN 4 THEN ''Rejected''
            WHEN 5 THEN ''Shipped''
            WHEN 6 THEN ''Cancelled''
            ELSE ''Unknown''
        END AS OrderStatus,
        
        -- Special offer
        sod.SpecialOfferID,
        so.Description AS SpecialOfferDescription,
        so.DiscountPct AS PromotionalDiscount,
        
        -- Sales reason
        STRING_AGG(sr.Name, '', '') AS SalesReasons,
        
        -- Calculated delivery performance
        CASE
            WHEN soh.ShipDate IS NULL THEN NULL
            ELSE DATEDIFF(day, soh.OrderDate, soh.ShipDate)
        END AS DaysToShip,
        
        CASE
            WHEN soh.ShipDate IS NULL THEN ''Not Shipped''
            WHEN soh.ShipDate <= soh.DueDate THEN ''On Time''
            ELSE ''Late''
        END AS DeliveryPerformance
    FROM
        Sales.SalesOrderDetail sod
        INNER JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
        INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
        LEFT JOIN Sales.SpecialOffer so ON sod.SpecialOfferID = so.SpecialOfferID
        LEFT JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
        LEFT JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
        LEFT JOIN Purchasing.ShipMethod sm ON soh.ShipMethodID = sm.ShipMethodID
        LEFT JOIN Sales.CreditCard cc ON soh.CreditCardID = cc.CreditCardID
        LEFT JOIN Sales.CurrencyRate cr ON soh.CurrencyRateID = cr.CurrencyRateID
        LEFT JOIN Sales.SalesOrderHeaderSalesReason sosr ON soh.SalesOrderID = sosr.SalesOrderID
        LEFT JOIN Sales.SalesReason sr ON sosr.SalesReasonID = sr.SalesReasonID
    GROUP BY
        sod.SalesOrderID,
        sod.SalesOrderDetailID,
        soh.CustomerID,
        sod.ProductID,
        soh.SalesPersonID,
        soh.TerritoryID,
        soh.OrderDate,
        soh.DueDate,
        soh.ShipDate,
        sod.OrderQty,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.LineTotal,
        p.StandardCost,
        soh.OnlineOrderFlag,
        soh.PurchaseOrderNumber,
        soh.AccountNumber,
        soh.CreditCardID,
        cc.CardType,
        soh.CurrencyRateID,
        cr.EndOfDayRate,
        soh.ShipMethodID,
        sm.Name,
        soh.Freight,
        soh.Status,
        sod.SpecialOfferID,
        so.Description,
        so.DiscountPct;';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- 7. FactInventory View
    -- =============================================
    SET @ViewName = 'vw_FactInventory';
    SET @SchemaName = 'dbo';
    SET @ViewStartTime = GETDATE();
    PRINT 'Refreshing ' + @SchemaName + '.' + @ViewName + '...';
    
    SET @SQL = '
    IF EXISTS (SELECT * FROM sys.views WHERE name = ''' + @ViewName + ''' AND schema_id = SCHEMA_ID(''' + @SchemaName + '''))
        DROP VIEW ' + @SchemaName + '.' + @ViewName + ';';
    EXEC sp_executesql @SQL;
    
    SET @SQL = '
    CREATE VIEW ' + @SchemaName + '.' + @ViewName + ' AS
    SELECT
        -- Keys
        pi.ProductID,
        pi.LocationID,
        
        -- Current inventory
        pi.Shelf,
        pi.Bin,
        pi.Quantity,
        
        -- Product information
        p.StandardCost,
        p.ListPrice,
        
        -- Calculated inventory values
        pi.Quantity * p.StandardCost AS InventoryCostValue,
        pi.Quantity * p.ListPrice AS InventoryRetailValue,
        
        -- Location information
        l.Name AS LocationName,
        l.CostRate AS LocationCostRate,
        l.Availability AS LocationAvailability,
        
        -- Inventory status
        CASE
            WHEN pi.Quantity <= 0 THEN ''Out of Stock''
            WHEN pi.Quantity <= p.ReorderPoint THEN ''Below Reorder Point''
            WHEN pi.Quantity <= p.SafetyStockLevel THEN ''Low Stock''
            ELSE ''In Stock''
        END AS StockStatus,
        
        -- Inventory metrics
        CASE
            WHEN p.ReorderPoint = 0 THEN NULL
            ELSE CAST(pi.Quantity AS float) / CAST(p.ReorderPoint AS float)
        END AS ReorderPointRatio,
        
        -- Product dynamics
        ISNULL((SELECT SUM(OrderQty) 
                FROM Sales.SalesOrderDetail sod
                JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
                WHERE sod.ProductID = pi.ProductID
                AND soh.OrderDate >= DATEADD(day, -90, GETDATE())), 0) AS Last90DaysSales,
        
        -- Days of supply calculation
        CASE
            WHEN (SELECT SUM(OrderQty) / 90.0
                  FROM Sales.SalesOrderDetail sod
                  JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
                  WHERE sod.ProductID = pi.ProductID
                  AND soh.OrderDate >= DATEADD(day, -90, GETDATE())) > 0
            THEN pi.Quantity / (SELECT SUM(OrderQty) / 90.0
                               FROM Sales.SalesOrderDetail sod
                               JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
                               WHERE sod.ProductID = pi.ProductID
                               AND soh.OrderDate >= DATEADD(day, -90, GETDATE()))
            ELSE NULL
        END AS EstimatedDaysOfSupply,
        
        -- Latest Modify Date
        pi.ModifiedDate AS InventoryLastUpdated
    FROM
        Production.ProductInventory pi
        JOIN Production.Product p ON pi.ProductID = p.ProductID
        JOIN Production.Location l ON pi.LocationID = l.LocationID;';
    EXEC sp_executesql @SQL;
    
    -- Get row count
    SET @SQL = 'SELECT @RowCount = COUNT(*) FROM ' + @SchemaName + '.' + @ViewName;
    EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT;
    
    -- Log successful refresh
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Success', @RowCount);
    
    PRINT @SchemaName + '.' + @ViewName + ' refreshed successfully in ' + 
          CAST(DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()) AS VARCHAR) + 'ms with ' + 
          CAST(@RowCount AS VARCHAR) + ' rows';

    -- =============================================
    -- Final Summary
    -- =============================================
    PRINT '============================================================';
    PRINT 'View refresh completed successfully';
    PRINT 'Total duration: ' + CAST(DATEDIFF(SECOND, @TotalStartTime, GETDATE()) AS VARCHAR) + ' seconds';
    PRINT 'End time: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '============================================================';
    
    -- Print summary
    SELECT 
        ViewName,
        RefreshDateTime,
        DurationMS AS ExecutionTimeMS,
        Status,
        RowCount
    FROM 
        dbo.ViewRefreshLog
    WHERE 
        RefreshDateTime >= @TotalStartTime
    ORDER BY 
        RefreshDateTime;
    
END TRY
BEGIN CATCH
    -- Error handling
    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
    
    -- Log error
    INSERT INTO dbo.ViewRefreshLog (ViewName, RefreshDateTime, DurationMS, Status, ErrorMessage, RowCount)
    VALUES (@SchemaName + '.' + @ViewName, GETDATE(), DATEDIFF(MILLISECOND, @ViewStartTime, GETDATE()), 'Failed', @ErrorMessage, NULL);
    
    PRINT '============================================================';
    PRINT 'ERROR: View refresh failed with the following error:';
    PRINT '============================================================';
    PRINT 'Error Message: ' + @ErrorMessage;
    PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS VARCHAR);
    PRINT 'Error State: ' + CAST(@ErrorState AS VARCHAR);
    PRINT 'Failed View: ' + @SchemaName + '.' + @ViewName;
    PRINT '============================================================';
    
    -- Raise error to calling application
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO

-- Create a stored procedure to schedule refresh
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_RefreshAnalyticsViews' AND schema_id = SCHEMA_ID('dbo'))
    DROP PROCEDURE dbo.sp_RefreshAnalyticsViews;
GO

CREATE PROCEDURE dbo.sp_RefreshAnalyticsViews
AS
BEGIN
    EXEC dbo.refresh_views;
END;
GO

-- Add instructions for scheduling
PRINT '============================================================';
PRINT 'To schedule automatic refreshes, use SQL Server Agent:';
PRINT '1. Create a SQL Server Agent Job';
PRINT '2. Add a job step to execute: EXEC dbo.sp_RefreshAnalyticsViews';
PRINT '3. Set the schedule (e.g., daily at 2:00 AM)';
PRINT '============================================================';
GO
