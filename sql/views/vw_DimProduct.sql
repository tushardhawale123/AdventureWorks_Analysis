CREATE OR ALTER VIEW dbo.vw_DimProduct AS
SELECT
    -- Keys
    p.ProductID,
    p.ProductSubcategoryID,
    ps.ProductCategoryID,
    
    -- Product attributes
    p.Name AS ProductName,
    p.ProductNumber,
    ISNULL(p.Color, 'N/A') AS Color,
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
        WHEN 1 THEN 'Finished Goods'
        ELSE 'Raw Material'
    END AS ProductType,
    
    CASE p.MakeFlag
        WHEN 1 THEN 'Manufactured In-house'
        ELSE 'Purchased'
    END AS SourceType,
    
    -- Product classification (custom)
    CASE
        WHEN p.ListPrice >= 2000 THEN 'Premium'
        WHEN p.ListPrice >= 1000 THEN 'High-end'
        WHEN p.ListPrice >= 500 THEN 'Mid-range'
        ELSE 'Economy'
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
    LEFT JOIN Production.ProductModel pm ON p.ProductModelID = pm.ProductModelID;
