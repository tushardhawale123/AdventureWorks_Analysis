SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    pc.Name AS Category,
    ps.Name AS Subcategory,
    SUM(sod.OrderQty) AS TotalQuantitySold,
    SUM(sod.LineTotal) AS TotalSales,
    SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
    SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS GrossProfit,
    (SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost)) / SUM(sod.LineTotal) AS GrossProfitMargin,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    COUNT(DISTINCT soh.CustomerID) AS CustomerCount
FROM 
    Production.Product p
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.ProductID,
    p.Name,
    p.ProductNumber,
    pc.Name,
    ps.Name
ORDER BY 
    GrossProfit DESC;

-- 2. Product Profitability Trends by Year and Quarter
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    YEAR(soh.OrderDate) AS SalesYear,
    'Q' + CAST(DATEPART(QUARTER, soh.OrderDate) AS VARCHAR) AS SalesQuarter,
    SUM(sod.OrderQty) AS QuantitySold,
    SUM(sod.LineTotal) AS TotalSales,
    SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
    SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS GrossProfit,
    (SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost)) / SUM(sod.LineTotal) AS GrossProfitMargin
FROM 
    Production.Product p
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY 
    p.ProductID,
    p.Name,
    YEAR(soh.OrderDate),
    DATEPART(QUARTER, soh.OrderDate)
ORDER BY 
    p.ProductID,
    SalesYear,
    SalesQuarter;

-- 3. Product Performance by Territory
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    st.Name AS TerritoryName,
    st.[Group] AS Region,
    SUM(sod.OrderQty) AS QuantitySold,
    SUM(sod.LineTotal) AS TotalSales,
    SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
    SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS GrossProfit,
    (SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost)) / SUM(sod.LineTotal) AS GrossProfitMargin
FROM 
    Production.Product p
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY 
    p.ProductID,
    p.Name,
    st.Name,
    st.[Group]
ORDER BY 
    p.ProductID,
    TotalSales DESC;

-- 4. Special Offer Impact on Product Sales
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    so.SpecialOfferID,
    so.Description AS OfferDescription,
    so.DiscountPct,
    COUNT(DISTINCT sod.SalesOrderID) AS OrderCount,
    SUM(sod.OrderQty) AS QuantitySold,
    SUM(sod.LineTotal) AS TotalSales,
    SUM(sod.OrderQty * p.StandardCost) AS TotalCost,
    SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost) AS GrossProfit,
    (SUM(sod.LineTotal) - SUM(sod.OrderQty * p.StandardCost)) / SUM(sod.LineTotal) AS GrossProfitMargin
FROM 
    Production.Product p
    JOIN Sales.SpecialOfferProduct sop ON p.ProductID = sop.ProductID
    JOIN Sales.SpecialOffer so ON sop.SpecialOfferID = so.SpecialOfferID
    JOIN Sales.SalesOrderDetail sod ON sop.SpecialOfferID = sod.SpecialOfferID AND sop.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY 
    p.ProductID,
    p.Name,
    so.SpecialOfferID,
    so.Description,
    so.DiscountPct
ORDER BY 
    p.ProductID,
    QuantitySold DESC;

-- 5. Top Product Combinations (Market Basket Analysis)
WITH ProductPairs AS (
    SELECT
        p1.ProductID AS Product1ID,
        p1.Name AS Product1Name,
        p2.ProductID AS Product2ID,
        p2.Name AS Product2Name,
        COUNT(DISTINCT sod1.SalesOrderID) AS OrdersTogether
    FROM
        Sales.SalesOrderDetail sod1
        JOIN Production.Product p1 ON sod1.ProductID = p1.ProductID
        JOIN Sales.SalesOrderDetail sod2 ON sod1.SalesOrderID = sod2.SalesOrderID
            AND sod1.ProductID < sod2.ProductID -- Ensures each pair is counted only once
        JOIN Production.Product p2 ON sod2.ProductID = p2.ProductID
    GROUP BY
        p1.ProductID,
        p1.Name,
        p2.ProductID,
        p2.Name
)
SELECT
    pp.Product1ID,
    pp.Product1Name,
    pp.Product2ID,
    pp.Product2Name,
    pp.OrdersTogether,
    (SELECT COUNT(DISTINCT SalesOrderID) FROM Sales.SalesOrderDetail WHERE ProductID = pp.Product1ID) AS Product1OrderCount,
    (SELECT COUNT(DISTINCT SalesOrderID) FROM Sales.SalesOrderDetail WHERE ProductID = pp.Product2ID) AS Product2OrderCount,
    pp.OrdersTogether * 1.0 / (SELECT COUNT(DISTINCT SalesOrderID) FROM Sales.SalesOrderDetail WHERE ProductID = pp.Product1ID) AS Confidence1to2,
    pp.OrdersTogether * 1.0 / (SELECT COUNT(DISTINCT SalesOrderID) FROM Sales.SalesOrderDetail WHERE ProductID = pp.Product2ID) AS Confidence2to1
FROM
    ProductPairs pp
WHERE
    pp.OrdersTogether > 5 -- Minimum threshold for relevance
ORDER BY
    pp.OrdersTogether DESC;

-- 6. Product Price Elasticity Analysis
WITH ProductPriceChanges AS (
    SELECT
        p.ProductID,
        p.Name AS ProductName,
        plph1.StartDate,
        plph1.ListPrice AS OldPrice,
        plph2.ListPrice AS NewPrice,
        (plph2.ListPrice - plph1.ListPrice) / plph1.ListPrice AS PriceChangePct,
        (
            SELECT AVG(OrderQty * 1.0 / DATEDIFF(DAY, soh.OrderDate, DATEADD(DAY, 30, soh.OrderDate)))
            FROM Sales.SalesOrderDetail sod
            JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
            WHERE sod.ProductID = p.ProductID
            AND soh.OrderDate BETWEEN DATEADD(DAY, -30, plph1.StartDate) AND plph1.StartDate
        ) AS AvgDailySalesBefore,
        (
            SELECT AVG(OrderQty * 1.0 / DATEDIFF(DAY, soh.OrderDate, DATEADD(DAY, 30, soh.OrderDate)))
            FROM Sales.SalesOrderDetail sod
            JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
            WHERE sod.ProductID = p.ProductID
            AND soh.OrderDate BETWEEN plph2.StartDate AND DATEADD(DAY, 30, plph2.StartDate)
        ) AS AvgDailySalesAfter
    FROM
        Production.Product p
        JOIN Production.ProductListPriceHistory plph1 ON p.ProductID = plph1.ProductID
        JOIN Production.ProductListPriceHistory plph2 ON p.ProductID = plph2.ProductID
        AND plph1.StartDate < plph2.StartDate
        AND NOT EXISTS (
            SELECT 1 
            FROM Production.ProductListPriceHistory plph3
            WHERE p.ProductID = plph3.ProductID
            AND plph3.StartDate > plph1.StartDate
            AND plph3.StartDate < plph2.StartDate
        )
)
SELECT
    ProductID,
    ProductName,
    OldPrice,
    NewPrice,
    PriceChangePct,
    AvgDailySalesBefore,
    AvgDailySalesAfter,
    (AvgDailySalesAfter - AvgDailySalesBefore) / AvgDailySalesBefore AS SalesChangePct,
    CASE 
        WHEN PriceChangePct = 0 THEN NULL
        ELSE ((AvgDailySalesAfter - AvgDailySalesBefore) / AvgDailySalesBefore) / PriceChangePct
    END AS PriceElasticity
FROM
    ProductPriceChanges
WHERE
    AvgDailySalesBefore > 0
    AND AvgDailySalesAfter > 0
ORDER BY
    ABS(PriceChangePct) DESC;
