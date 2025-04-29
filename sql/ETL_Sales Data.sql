-- Sample extraction script for Sales data
CREATE PROCEDURE Extract_SalesData
AS
BEGIN
    SELECT 
        soh.SalesOrderID,
        soh.CustomerID,
        soh.OrderDate,
        soh.DueDate,
        soh.ShipDate,
        soh.Status,
        soh.SalesOrderNumber,
        soh.TerritoryID,
        soh.SalesPersonID,
        soh.TotalDue,
        soh.TaxAmt,
        soh.Freight,
        sod.SalesOrderDetailID,
        sod.ProductID,
        sod.OrderQty,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.LineTotal
    INTO #TempSalesExtract
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID;
    
    -- Additional logic for data extraction
END;