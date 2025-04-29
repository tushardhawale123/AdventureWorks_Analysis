WITH MonthlySales AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        FORMAT(OrderDate, 'MMM yyyy') AS MonthYear,
        SUM(TotalDue) AS TotalSales,
        COUNT(DISTINCT SalesOrderID) AS OrderCount,
        SUM(TotalDue) / COUNT(DISTINCT SalesOrderID) AS AvgOrderValue
    FROM
        Sales.SalesOrderHeader
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate),
        FORMAT(OrderDate, 'MMM yyyy')
)
SELECT
    ms.*,
    LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth) AS PreviousMonthSales,
    CASE 
        WHEN LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth) = 0 THEN NULL
        ELSE (TotalSales - LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth)) / 
             LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth)
    END AS MoMGrowth
FROM
    MonthlySales ms
ORDER BY
    OrderYear,
    OrderMonth;

-- 2. Territory Performance
SELECT
    st.Name AS TerritoryName,
    st.[Group] AS Region,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    SUM(soh.TotalDue) AS TotalSales,
    SUM(soh.TotalDue) / COUNT(DISTINCT soh.SalesOrderID) AS AvgOrderValue,
    COUNT(DISTINCT soh.CustomerID) AS CustomerCount,
    SUM(soh.TotalDue) / COUNT(DISTINCT soh.CustomerID) AS SalesPerCustomer
FROM
    Sales.SalesOrderHeader soh
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name,
    st.[Group]
ORDER BY
    TotalSales DESC;

-- 3. Product Category Performance
SELECT
    pc.Name AS CategoryName,
    ps.Name AS SubcategoryName,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    SUM(sod.LineTotal) AS TotalSales,
    SUM(sod.OrderQty) AS QuantitySold,
    SUM(sod.LineTotal) / SUM(sod.OrderQty) AS AvgUnitPrice,
    SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost)) AS TotalMargin,
    SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost)) / SUM(sod.LineTotal) AS MarginPercent
FROM
    Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY
    pc.Name,
    ps.Name
ORDER BY
    TotalSales DESC;

-- 4. Customer Analysis
WITH CustomerOrders AS (
    SELECT
        c.CustomerID,
        CASE
            WHEN c.PersonID IS NOT NULL THEN 'Individual'
            ELSE 'Store'
        END AS CustomerType,
        CASE
            WHEN c.PersonID IS NOT NULL THEN p.FirstName + ' ' + p.LastName
            ELSE s.Name
        END AS CustomerName,
        COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
        SUM(soh.TotalDue) AS TotalSpend,
        MIN(soh.OrderDate) AS FirstOrderDate,
        MAX(soh.OrderDate) AS LastOrderDate,
        DATEDIFF(DAY, MIN(soh.OrderDate), MAX(soh.OrderDate)) AS CustomerLifespanDays
    FROM
        Sales.Customer c
        LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
        LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
        LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID,
        c.PersonID,
        c.StoreID,
        p.FirstName,
        p.LastName,
        s.Name
)
SELECT
    co.*,
    co.TotalSpend / NULLIF(co.OrderCount, 0) AS AvgOrderValue,
    CASE
        WHEN co.CustomerLifespanDays = 0 THEN co.TotalSpend
        ELSE co.TotalSpend / (co.CustomerLifespanDays / 30.0)
    END AS MonthlySpendRate,
    NTILE(5) OVER (ORDER BY co.TotalSpend DESC) AS SpendQuintile,
    CASE
        WHEN co.LastOrderDate >= DATEADD(MONTH, -6, GETDATE()) THEN 'Active'
        WHEN co.LastOrderDate >= DATEADD(MONTH, -12, GETDATE()) THEN 'Recent'
        ELSE 'Inactive'
    END AS CustomerStatus
FROM
    CustomerOrders co
ORDER BY
    co.TotalSpend DESC;

-- 5. Online vs. In-Store Sales Analysis
SELECT
    YEAR(soh.OrderDate) AS OrderYear,
    MONTH(soh.OrderDate) AS OrderMonth,
    FORMAT(soh.OrderDate, 'MMM yyyy') AS MonthYear,
    CASE soh.OnlineOrderFlag
        WHEN 1 THEN 'Online'
        ELSE 'In-Store'
    END AS SalesChannel,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    SUM(soh.TotalDue) AS TotalSales,
    SUM(soh.TotalDue) / COUNT(DISTINCT soh.SalesOrderID) AS AvgOrderValue,
    COUNT(DISTINCT soh.CustomerID) AS CustomerCount
FROM
    Sales.SalesOrderHeader soh
GROUP BY
    YEAR(soh.OrderDate),
    MONTH(soh.OrderDate),
    FORMAT(soh.OrderDate, 'MMM yyyy'),
    soh.OnlineOrderFlag
ORDER BY
    OrderYear,
    OrderMonth,
    SalesChannel;

-- 6. Sales Person Performance
SELECT
    p.FirstName + ' ' + p.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    st.[Group] AS Region,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    SUM(soh.TotalDue) AS TotalSales,
    sp.SalesQuota AS SalesQuota,
    CASE 
        WHEN sp.SalesQuota IS NULL THEN NULL
        ELSE SUM(soh.TotalDue) / sp.SalesQuota 
    END AS QuotaAttainment,
    SUM(soh.TotalDue) / COUNT(DISTINCT soh.SalesOrderID) AS AvgOrderValue,
    COUNT(DISTINCT soh.CustomerID) AS CustomerCount
FROM
    Sales.SalesOrderHeader soh
    JOIN Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
    JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
    LEFT JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID
WHERE
    soh.SalesPersonID IS NOT NULL
GROUP BY
    p.FirstName,
    p.LastName,
    st.Name,
    st.[Group],
    sp.SalesQuota
ORDER BY
    TotalSales DESC;
