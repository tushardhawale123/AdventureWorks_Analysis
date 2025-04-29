-- 1. Customer Base Overview
WITH CustomerMetrics AS (
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
        st.Name AS TerritoryName,
        st.[Group] AS Region,
        
        -- Order metrics
        COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
        SUM(soh.TotalDue) AS TotalSpend,
        
        -- Activity metrics
        MIN(soh.OrderDate) AS FirstPurchaseDate,
        MAX(soh.OrderDate) AS LastPurchaseDate,
        DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastPurchase,
        DATEDIFF(DAY, MIN(soh.OrderDate), MAX(soh.OrderDate)) AS CustomerLifespan,
        
        -- Value metrics
        SUM(soh.TotalDue) / COUNT(DISTINCT soh.SalesOrderID) AS AvgOrderValue,
        COUNT(DISTINCT soh.SalesOrderID) * 1.0 / 
            NULLIF(DATEDIFF(MONTH, MIN(soh.OrderDate), GETDATE()), 0) AS MonthlyOrderFrequency,
            
        -- Channel preference
        SUM(CASE WHEN soh.OnlineOrderFlag = 1 THEN soh.TotalDue ELSE 0 END) / 
            NULLIF(SUM(soh.TotalDue), 0) AS OnlineSalesRatio
    FROM
        Sales.Customer c
        LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
        LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
        LEFT JOIN Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
        LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID,
        c.PersonID,
        c.StoreID,
        p.FirstName,
        p.LastName,
        s.Name,
        st.Name,
        st.[Group]
)
SELECT 
    CustomerID,
    CustomerType,
    CustomerName,
    TerritoryName,
    Region,
    OrderCount,
    TotalSpend,
    FirstPurchaseDate,
    LastPurchaseDate,
    DaysSinceLastPurchase,
    CustomerLifespan,
    AvgOrderValue,
    MonthlyOrderFrequency,
    OnlineSalesRatio,
    
    -- Recency-Frequency-Monetary (RFM) Scores (1-5 scale, 5 being best)
    NTILE(5) OVER (ORDER BY DaysSinceLastPurchase ASC) AS RecencyScore,
    NTILE(5) OVER (ORDER BY MonthlyOrderFrequency DESC) AS FrequencyScore,
    NTILE(5) OVER (ORDER BY TotalSpend DESC) AS MonetaryScore,
    
    -- Customer Status
    CASE
        WHEN DaysSinceLastPurchase <= 90 THEN 'Active'
        WHEN DaysSinceLastPurchase <= 365 THEN 'Recent'
        ELSE 'Inactive'
    END AS CustomerStatus,
    
    -- Value Segment
    CASE
        WHEN TotalSpend >= 50000 THEN 'High Value'
        WHEN TotalSpend >= 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS ValueSegment
FROM
    CustomerMetrics
ORDER BY
    TotalSpend DESC;

-- 2. RFM Segmentation
WITH CustomerRFM AS (
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
        MAX(soh.OrderDate) AS LastOrderDate,
        DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS Recency,
        COUNT(DISTINCT soh.SalesOrderID) AS Frequency,
        SUM(soh.TotalDue) AS Monetary,
        NTILE(5) OVER (ORDER BY DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) ASC) AS R,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT soh.SalesOrderID) DESC) AS F,
        NTILE(5) OVER (ORDER BY SUM(soh.TotalDue) DESC) AS M
    FROM
        Sales.Customer c
        LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
        LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
        JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID,
        c.PersonID,
        c.StoreID,
        p.FirstName,
        p.LastName,
        s.Name
)
SELECT
    CustomerID,
    CustomerType,
    CustomerName,
    LastOrderDate,
    Recency,
    Frequency,
    Monetary,
    R, F, M,
    CAST(R AS VARCHAR) + CAST(F AS VARCHAR) + CAST(M AS VARCHAR) AS RFM_Score,
    CASE
        WHEN R = 5 AND F = 5 AND M = 5 THEN 'Champions'
        WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Loyal Customers'
        WHEN R >= 3 AND F >= 3 AND M >= 3 THEN 'Potential Loyalists'
        WHEN R >= 4 AND F >= 1 AND M >= 4 THEN 'Recent High Spenders'
        WHEN R >= 4 AND F <= 2 AND M <= 2 THEN 'New Customers'
        WHEN R = 5 AND F = 1 AND M >= 3 THEN 'Promising'
        WHEN R <= 2 AND F >= 3 AND M >= 3 THEN 'At Risk'
        WHEN R <= 2 AND F >= 3 AND M <= 2 THEN 'Cannot Lose'
        WHEN R <= 2 AND F <= 2 AND M >= 3 THEN 'Hibernate'
        WHEN R <= 1 AND F <= 1 AND M <= 1 THEN 'Lost'
        ELSE 'Other'
    END AS CustomerSegment
FROM
    CustomerRFM
ORDER BY
    R DESC, F DESC, M DESC;

-- 3. Customer Purchase Pattern Analysis
SELECT
    c.CustomerID,
    CASE
        WHEN c.PersonID IS NOT NULL THEN p.FirstName + ' ' + p.LastName
        ELSE s.Name
    END AS CustomerName,
    
    -- Product Category Preferences
    pc.Name AS ProductCategory,
    COUNT(DISTINCT sod.SalesOrderID) AS OrderCount,
    SUM(sod.LineTotal) AS CategorySpend,
    SUM(sod.LineTotal) / SUM(SUM(sod.LineTotal)) OVER (PARTITION BY c.CustomerID) AS CategoryPercentage
FROM
    Sales.Customer c
    LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
    JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product pr ON sod.ProductID = pr.ProductID
    LEFT JOIN Production.ProductSubcategory ps ON pr.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE
    pc.Name IS NOT NULL
GROUP BY
    c.CustomerID,
    c.PersonID,
    p.FirstName,
    p.LastName,
    s.Name,
    pc.Name
ORDER BY
    c.CustomerID,
    CategorySpend DESC;

-- 4. Customer Purchase Seasonality
WITH CustomerSeasonality AS (
    SELECT
        c.CustomerID,
        CASE
            WHEN c.PersonID IS NOT NULL THEN p.FirstName + ' ' + p.LastName
            ELSE s.Name
        END AS CustomerName,
        YEAR(soh.OrderDate) AS OrderYear,
        DATEPART(QUARTER, soh.OrderDate) AS OrderQuarter,
        MONTH(soh.OrderDate) AS OrderMonth,
        DATENAME(MONTH, soh.OrderDate) AS MonthName,
        COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
        SUM(soh.TotalDue) AS TotalSpend
    FROM
        Sales.Customer c
        LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
        LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
        JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID,
        c.PersonID,
        p.FirstName,
        p.LastName,
        s.Name,
        YEAR(soh.OrderDate),
        DATEPART(QUARTER, soh.OrderDate),
        MONTH(soh.OrderDate),
        DATENAME(MONTH, soh.OrderDate)
)
SELECT
    cs.CustomerID,
    cs.CustomerName,
    cs.OrderYear,
    'Q' + CAST(cs.OrderQuarter AS VARCHAR) AS Quarter,
    cs.MonthName,
    cs.OrderCount,
    cs.TotalSpend,
    cs.TotalSpend / SUM(cs.TotalSpend) OVER (PARTITION BY cs.CustomerID, cs.OrderYear) AS YearlySpendPercentage,
    AVG(cs.TotalSpend) OVER (PARTITION BY cs.CustomerID, cs.OrderMonth) AS AvgMonthlySpend,
    RANK() OVER (PARTITION BY cs.CustomerID ORDER BY SUM(cs.TotalSpend) OVER (PARTITION BY cs.CustomerID, cs.OrderMonth) DESC) AS MonthRank
FROM
    CustomerSeasonality cs
ORDER BY
    cs.CustomerID,
    cs.OrderYear,
    cs.OrderMonth;

-- 5. Customer Lifetime Value Prediction
WITH CustomerHistory AS (
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
        
        -- Purchase history
        MIN(soh.OrderDate) AS FirstPurchaseDate,
        MAX(soh.OrderDate) AS LastPurchaseDate,
        DATEDIFF(MONTH, MIN(soh.OrderDate), MAX(soh.OrderDate)) + 1 AS TotalMonths,
        COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
        SUM(soh.TotalDue) AS TotalSpend,
        
        -- Average metrics
        SUM(soh.TotalDue) / COUNT(DISTINCT soh.SalesOrderID) AS AvgOrderValue,
        COUNT(DISTINCT soh.SalesOrderID) * 1.0 / 
            NULLIF(DATEDIFF(MONTH, MIN(soh.OrderDate), MAX(soh.OrderDate)) + 1, 0) AS MonthlyPurchaseFrequency,
            
        -- Churn risk
        DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS DaysSinceLastPurchase
    FROM
        Sales.Customer c
        LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
        LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
        JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY
        c.CustomerID,
        c.PersonID,
        c.StoreID,
        p.FirstName,
        p.LastName,
        s.Name
)
SELECT
    CustomerID,
    CustomerType,
    CustomerName,
    FirstPurchaseDate,
    LastPurchaseDate,
    TotalMonths,
    TotalOrders,
    TotalSpend,
    AvgOrderValue,
    MonthlyPurchaseFrequency,
    DaysSinceLastPurchase,
    
    -- Customer Lifetime Value projections
    CASE
        -- Churned customers
        WHEN DaysSinceLastPurchase > 365 THEN TotalSpend
        -- Active customers - project for 36 months (3 years)
        ELSE TotalSpend + (36 * MonthlyPurchaseFrequency * AvgOrderValue * 
              (1 - (0.10 * (DaysSinceLastPurchase / 365.0)))) -- Applying a decay factor based on recency
    END AS ProjectedLifetimeValue,
    
    -- Churn probability
    CASE
        WHEN DaysSinceLastPurchase <= 30 THEN 0.05 -- Very low
        WHEN DaysSinceLastPurchase <= 90 THEN 0.10 -- Low
        WHEN DaysSinceLastPurchase <= 180 THEN 0.25 -- Medium
        WHEN DaysSinceLastPurchase <= 365 THEN 0.50 -- High
        ELSE 0.90 -- Very high
    END AS ChurnProbability,
    
    -- Retention recommendations
    CASE
        WHEN DaysSinceLastPurchase <= 30 THEN 'Regular Engagement'
        WHEN DaysSinceLastPurchase <= 90 THEN 'Promotional Offer'
        WHEN DaysSinceLastPurchase <= 180 THEN 'Re-engagement Campaign'
        WHEN DaysSinceLastPurchase <= 365 THEN 'Win-back Strategy'
        ELSE 'Reactivation or Archive'
    END AS RetentionStrategy
FROM
    CustomerHistory
ORDER BY
    ProjectedLifetimeValue DESC;
