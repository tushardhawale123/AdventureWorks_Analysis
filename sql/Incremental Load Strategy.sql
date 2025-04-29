-- Incremental fact table loading example for Sales
CREATE PROCEDURE Load_FactSales_Incremental
    @LastLoadDate DATETIME
AS
BEGIN
    INSERT INTO FactSales (
        SalesOrderID, CustomerKey, ProductKey, DateKey, 
        TerritoryKey, SalesPersonKey, OrderQty, UnitPrice, 
        UnitPriceDiscount, LineTotal, Tax, Freight, TotalDue
    )
    SELECT 
        sod.SalesOrderDetailID,
        ISNULL(dc.CustomerKey, -1) AS CustomerKey,
        ISNULL(dp.ProductKey, -1) AS ProductKey,
        ISNULL(dd.DateKey, -1) AS DateKey,
        ISNULL(dt.TerritoryKey, -1) AS TerritoryKey,
        ISNULL(dsp.SalesPersonKey, -1) AS SalesPersonKey,
        sod.OrderQty,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.LineTotal,
        soh.TaxAmt,
        soh.Freight,
        soh.TotalDue
    FROM Sales.SalesOrderDetail sod
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    LEFT JOIN DimCustomer dc ON soh.CustomerID = dc.CustomerID AND dc.IsCurrent = 1
    LEFT JOIN DimProduct dp ON sod.ProductID = dp.ProductID AND dp.IsCurrent = 1
    LEFT JOIN DimDate dd ON CAST(soh.OrderDate AS DATE) = dd.FullDate
    LEFT JOIN DimTerritory dt ON soh.TerritoryID = dt.TerritoryID
    LEFT JOIN DimSalesPerson dsp ON soh.SalesPersonID = dsp.SalesPersonID
    WHERE soh.ModifiedDate > @LastLoadDate
      AND NOT EXISTS (
          SELECT 1 FROM FactSales 
          WHERE SalesOrderID = sod.SalesOrderDetailID
      );
      
    -- Update load tracking table
    UPDATE ETL_LoadTracking 
    SET LastLoadDate = GETDATE()
    WHERE TableName = 'FactSales';
END;