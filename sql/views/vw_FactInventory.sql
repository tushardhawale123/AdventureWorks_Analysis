CREATE OR ALTER VIEW dbo.vw_FactInventory AS
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
        WHEN pi.Quantity <= 0 THEN 'Out of Stock'
        WHEN pi.Quantity <= p.ReorderPoint THEN 'Below Reorder Point'
        WHEN pi.Quantity <= p.SafetyStockLevel THEN 'Low Stock'
        ELSE 'In Stock'
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
    JOIN Production.Location l ON pi.LocationID = l.LocationID;
