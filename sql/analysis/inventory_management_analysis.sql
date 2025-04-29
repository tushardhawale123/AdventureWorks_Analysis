-- 1. Current Inventory Status
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    pc.Name AS Category,
    ps.Name AS Subcategory,
    p.Color,
    p.Size,
    p.SafetyStockLevel,
    p.ReorderPoint,
    SUM(pi.Quantity) AS CurrentStockLevel,
    p.StandardCost AS UnitCost,
    SUM(pi.Quantity) * p.StandardCost AS InventoryValue,
    CASE
        WHEN SUM(pi.Quantity) <= 0 THEN 'Out of Stock'
        WHEN SUM(pi.Quantity) < p.ReorderPoint THEN 'Below Reorder Point'
        WHEN SUM(pi.Quantity) < p.SafetyStockLevel THEN 'Below Safety Stock'
        ELSE 'Adequate Stock'
    END AS StockStatus
FROM
    Production.Product p
    LEFT JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY
    p.ProductID,
    p.Name,
    p.ProductNumber,
    pc.Name,
    ps.Name,
    p.Color,
    p.Size,
    p.SafetyStockLevel,
    p.ReorderPoint,
    p.StandardCost
ORDER BY
    StockStatus ASC,
    InventoryValue DESC;

-- 2. Inventory Turnover Analysis
WITH ProductSales AS (
    SELECT
        p.ProductID,
        p.Name AS ProductName,
        SUM(sod.OrderQty) AS QuantitySold,
        SUM(sod.LineTotal) AS SalesAmount,
        MIN(soh.OrderDate) AS FirstSaleDate,
        MAX(soh.OrderDate) AS LastSaleDate
    FROM
        Production.Product p
        LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
        LEFT JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    GROUP BY
        p.ProductID,
        p.Name
),
AvgInventory AS (
    SELECT
        p.ProductID,
        AVG(CAST(pi.Quantity AS FLOAT)) AS AvgStockLevel
    FROM
        Production.Product p
        JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
    GROUP BY
        p.ProductID
)
SELECT
    p.ProductID,
    p.Name AS ProductName,
    pc.Name AS Category,
    ps.Name AS Subcategory,
    p.SafetyStockLevel,
    p.ReorderPoint,
    SUM(pi.Quantity) AS CurrentStockLevel,
    ai.AvgStockLevel,
    ps.QuantitySold,
    CASE
        WHEN ai.AvgStockLevel = 0 THEN NULL
        ELSE ps.QuantitySold / ai.AvgStockLevel
    END AS InventoryTurnoverRate,
    CASE
        WHEN ps.QuantitySold = 0 THEN NULL
        ELSE 365.0 / (ps.QuantitySold / NULLIF(ai.AvgStockLevel, 0))
    END AS DaysOfInventory,
    p.StandardCost,
    SUM(pi.Quantity) * p.StandardCost AS CurrentInventoryValue,
    DATEDIFF(DAY, ps.LastSaleDate, GETDATE()) AS DaysSinceLastSale
FROM
    Production.Product p
    LEFT JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    LEFT JOIN ProductSales ps ON p.ProductID = ps.ProductID
    LEFT JOIN AvgInventory ai ON p.ProductID = ai.ProductID
GROUP BY
    p.ProductID,
    p.Name,
    pc.Name,
    ps.Name,
    p.SafetyStockLevel,
    p.ReorderPoint,
    p.StandardCost,
    ai.AvgStockLevel,
    ps.QuantitySold,
    ps.LastSaleDate
ORDER BY
    DaysOfInventory ASC;

-- 3. Stock Replenishment Recommendations
WITH ProductDemand AS (
    SELECT
        p.ProductID,
        p.Name AS ProductName,
        -- 30-day demand
        ISNULL((
            SELECT SUM(sod.OrderQty)
            FROM Sales.SalesOrderDetail sod
            JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
            WHERE s
