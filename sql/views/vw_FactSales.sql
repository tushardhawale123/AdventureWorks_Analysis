CREATE OR ALTER VIEW dbo.vw_FactSales AS
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
    ISNULL(cc.CardType, 'N/A') AS CardType,
    soh.CurrencyRateID,
    ISNULL(cr.EndOfDayRate, 1) AS CurrencyConversionRate,
    
    -- Shipping information
    soh.ShipMethodID,
    sm.Name AS ShippingMethod,
    soh.Freight AS FreightCost,
    
    -- Status
    CASE soh.Status
        WHEN 1 THEN 'In Process'
        WHEN 2 THEN 'Approved'
        WHEN 3 THEN 'Backordered'
        WHEN 4 THEN 'Rejected'
        WHEN 5 THEN 'Shipped'
        WHEN 6 THEN 'Cancelled'
        ELSE 'Unknown'
    END AS OrderStatus,
    
    -- Special offer
    sod.SpecialOfferID,
    so.Description AS SpecialOfferDescription,
    so.DiscountPct AS PromotionalDiscount,
    
    -- Sales reason
    STRING_AGG(sr.Name, ', ') AS SalesReasons,
    
    -- Calculated delivery performance
    CASE
        WHEN soh.ShipDate IS NULL THEN NULL
        ELSE DATEDIFF(day, soh.OrderDate, soh.ShipDate)
    END AS DaysToShip,
    
    CASE
        WHEN soh.ShipDate IS NULL THEN 'Not Shipped'
        WHEN soh.ShipDate <= soh.DueDate THEN 'On Time'
        ELSE 'Late'
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
    so.DiscountPct;
