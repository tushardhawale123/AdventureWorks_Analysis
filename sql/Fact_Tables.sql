-- Create Sales Fact Table
CREATE TABLE fact.Sales (
    SalesOrderDetailID INT NOT NULL PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    SalesOrderNumber NVARCHAR(25) NOT NULL,
    OrderDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    ShipDateKey INT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    TerritoryKey INT NULL,
    SalesPersonKey INT NULL,
    OrderQty SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    UnitPriceDiscountPct MONEY NOT NULL,
    DiscountAmount MONEY NOT NULL,
    LineTotal MONEY NOT NULL,
    TaxAmt MONEY NULL,
    Freight MONEY NULL,
    ExtendedAmount MONEY NOT NULL,
    TotalProductCost MONEY NOT NULL,
    SalesAmount MONEY NOT NULL,
    CONSTRAINT FK_FactSales_DimDate_OrderDateKey FOREIGN KEY (OrderDateKey) REFERENCES dim.Date (DateKey),
    CONSTRAINT FK_FactSales_DimDate_DueDateKey FOREIGN KEY (DueDateKey) REFERENCES dim.Date (DateKey),
    CONSTRAINT FK_FactSales_DimDate_ShipDateKey FOREIGN KEY (ShipDateKey) REFERENCES dim.Date (DateKey),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES dim.Customer (CustomerKey),
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES dim.Product (ProductKey),
    CONSTRAINT FK_FactSales_DimTerritory FOREIGN KEY (TerritoryKey) REFERENCES dim.Territory (TerritoryKey),
    CONSTRAINT FK_FactSales_DimSalesPerson FOREIGN KEY (SalesPersonKey) REFERENCES dim.SalesPerson (SalesPersonKey)
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_FactSales_OrderDateKey ON fact.Sales (OrderDateKey);
CREATE NONCLUSTERED INDEX IX_FactSales_CustomerKey ON fact.Sales (CustomerKey);
CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey ON fact.Sales (ProductKey);
CREATE NONCLUSTERED INDEX IX_FactSales_TerritoryKey ON fact.Sales (TerritoryKey);
CREATE NONCLUSTERED INDEX IX_FactSales_SalesPersonKey ON fact.Sales (SalesPersonKey);
GO

-- Insert from AdventureWorks
INSERT INTO fact.Sales (
    SalesOrderDetailID, SalesOrderID, SalesOrderNumber, OrderDateKey, DueDateKey, ShipDateKey,
    CustomerKey, ProductKey, TerritoryKey, SalesPersonKey,
    OrderQty, UnitPrice, UnitPriceDiscountPct, DiscountAmount, LineTotal,
    TaxAmt, Freight, ExtendedAmount, TotalProductCost, SalesAmount
)
SELECT 
    sod.SalesOrderDetailID,
    soh.SalesOrderID,
    soh.SalesOrderNumber,
    CONVERT(INT, CONVERT(VARCHAR, soh.OrderDate, 112)) AS OrderDateKey,
    CONVERT(INT, CONVERT(VARCHAR, soh.DueDate, 112)) AS DueDateKey,
    CASE WHEN soh.ShipDate IS NULL THEN NULL 
         ELSE CONVERT(INT, CONVERT(VARCHAR, soh.ShipDate, 112)) 
    END AS ShipDateKey,
    c.CustomerKey,
    p.ProductKey,
    t.TerritoryKey,
    sp.SalesPersonKey,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.UnitPrice * sod.UnitPriceDiscount * sod.OrderQty AS DiscountAmount,
    sod.LineTotal,
    soh.TaxAmt / 
        (SELECT COUNT(*) FROM AdventureWorks2019.Sales.SalesOrderDetail 
         WHERE SalesOrderID = soh.SalesOrderID) AS TaxAmt,
    soh.Freight / 
        (SELECT COUNT(*) FROM AdventureWorks2019.Sales.SalesOrderDetail 
         WHERE SalesOrderID = soh.SalesOrderID) AS Freight,
    sod.OrderQty * sod.UnitPrice AS ExtendedAmount,
    CASE 
        WHEN pch.StandardCost IS NULL THEN p.StandardCost * sod.OrderQty
        ELSE pch.StandardCost * sod.OrderQty
    END AS TotalProductCost,
    sod.LineTotal AS SalesAmount
FROM 
    AdventureWorks2019.Sales.SalesOrderDetail sod
    JOIN AdventureWorks2019.Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    JOIN dim.Customer c ON soh.CustomerID = c.CustomerID
    JOIN dim.Product p ON sod.ProductID = p.ProductID
    LEFT JOIN dim.Territory t ON soh.TerritoryID = t.TerritoryID
    LEFT JOIN dim.SalesPerson sp ON soh.SalesPersonID = sp.SalesPersonID
    LEFT JOIN AdventureWorks2019.Production.ProductCostHistory pch ON 
        sod.ProductID = pch.ProductID AND 
        soh.OrderDate BETWEEN pch.StartDate AND ISNULL(pch.EndDate, GETDATE());
GO


------------------------------------


-- Create Product Inventory Fact Table
CREATE TABLE fact.ProductInventory (
    ProductInventoryKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductKey INT NOT NULL,
    DateKey INT NOT NULL,
    LocationID SMALLINT NOT NULL,
    LocationName NVARCHAR(50) NOT NULL,
    Shelf NVARCHAR(10) NOT NULL,
    Bin TINYINT NOT NULL,
    Quantity SMALLINT NOT NULL,
    CONSTRAINT FK_FactProductInventory_DimProduct FOREIGN KEY (ProductKey) REFERENCES dim.Product (ProductKey),
    CONSTRAINT FK_FactProductInventory_DimDate FOREIGN KEY (DateKey) REFERENCES dim.Date (DateKey)
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_FactProductInventory_ProductKey ON fact.ProductInventory (ProductKey);
CREATE NONCLUSTERED INDEX IX_FactProductInventory_DateKey ON fact.ProductInventory (DateKey);
GO

-- Insert from AdventureWorks
INSERT INTO fact.ProductInventory (
    ProductKey, DateKey, LocationID, LocationName, Shelf, Bin, Quantity
)
SELECT 
    p.ProductKey,
    CONVERT(INT, CONVERT(VARCHAR, GETDATE(), 112)) AS DateKey,
    pi.LocationID,
    l.Name AS LocationName,
    pi.Shelf,
    pi.Bin,
    pi.Quantity
FROM 
    AdventureWorks2019.Production.ProductInventory pi
    JOIN dim.Product p ON pi.ProductID = p.ProductID
    JOIN AdventureWorks2019.Production.Location l ON pi.LocationID = l.LocationID;
GO

------------------------------------------


-- Create Purchasing Fact Table
CREATE TABLE fact.Purchasing (
    PurchaseOrderDetailID INT NOT NULL PRIMARY KEY,
    PurchaseOrderID INT NOT NULL,
    PurchaseOrderNumber NVARCHAR(25) NULL,
    OrderDateKey INT NOT NULL,
    DueDateKey INT NOT NULL,
    ShipDateKey INT NULL,
    VendorKey INT NOT NULL,
    ProductKey INT NOT NULL,
    EmployeeID INT NOT NULL,
    OrderQty SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    LineTotal MONEY NOT NULL,
    ReceivedQty DECIMAL(8, 2) NOT NULL,
    RejectedQty DECIMAL(8, 2) NOT NULL,
    StockedQty DECIMAL(8, 2) NOT NULL,
    TotalAmount MONEY NOT NULL,
    CONSTRAINT FK_FactPurchasing_DimDate_OrderDateKey FOREIGN KEY (OrderDateKey) REFERENCES dim.Date (DateKey),
    CONSTRAINT FK_FactPurchasing_DimDate_DueDateKey FOREIGN KEY (DueDateKey) REFERENCES dim.Date (DateKey),
    CONSTRAINT FK_FactPurchasing_DimDate_ShipDateKey FOREIGN KEY (ShipDateKey) REFERENCES dim.Date (DateKey),
    CONSTRAINT FK_FactPurchasing_DimVendor FOREIGN KEY (VendorKey) REFERENCES dim.Vendor (VendorKey),
    CONSTRAINT FK_FactPurchasing_DimProduct FOREIGN KEY (ProductKey) REFERENCES dim.Product (ProductKey)
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_FactPurchasing_OrderDateKey ON fact.Purchasing (OrderDateKey);
CREATE NONCLUSTERED INDEX IX_FactPurchasing_VendorKey ON fact.Purchasing (VendorKey);
CREATE NONCLUSTERED INDEX IX_FactPurchasing_ProductKey ON fact.Purchasing (ProductKey);
GO

-- Insert from AdventureWorks
INSERT INTO fact.Purchasing (
    PurchaseOrderDetailID, PurchaseOrderID, PurchaseOrderNumber,
    OrderDateKey, DueDateKey, ShipDateKey,
    VendorKey, ProductKey, EmployeeID,
    OrderQty, UnitPrice, LineTotal,
    ReceivedQty, RejectedQty, StockedQty, TotalAmount
)
SELECT 
    pod.PurchaseOrderDetailID,
    poh.PurchaseOrderID,
    'PO' + CAST(poh.PurchaseOrderID AS NVARCHAR(10)) AS PurchaseOrderNumber,
    CONVERT(INT, CONVERT(VARCHAR, poh.OrderDate, 112)) AS OrderDateKey,
    CONVERT(INT, CONVERT(VARCHAR, poh.ShipDate, 112)) AS DueDateKey,
    NULL AS ShipDateKey, -- Assuming ShipDate isn't stored in PO tables
    v.VendorKey,
    p.ProductKey,
    poh.EmployeeID,
    pod.OrderQty,
    pod.UnitPrice,
    pod.LineTotal,
    pod.ReceivedQty,
    pod.RejectedQty,
    pod.StockedQty,
    pod.LineTotal AS TotalAmount
FROM 
    AdventureWorks2019.Purchasing.PurchaseOrderDetail pod
    JOIN AdventureWorks2019.Purchasing.PurchaseOrderHeader poh ON pod.PurchaseOrderID = poh.PurchaseOrderID
    JOIN dim.Vendor v ON poh.VendorID = v.VendorID
    JOIN dim.Product p ON pod.ProductID = p.ProductID;
GO


-------------------------------------------



-- Verify dimension tables
SELECT 'DimDate' AS TableName, COUNT(*) AS Row_Count FROM dim.Date
UNION ALL
SELECT 'DimCustomer', COUNT(*) FROM dim.Customer
UNION ALL
SELECT 'DimProduct', COUNT(*) FROM dim.Product
UNION ALL
SELECT 'DimTerritory', COUNT(*) FROM dim.Territory
UNION ALL
SELECT 'DimSalesPerson', COUNT(*) FROM dim.SalesPerson
UNION ALL
SELECT 'DimVendor', COUNT(*) FROM dim.Vendor;

-- Verify fact tables
SELECT 'FactSales' AS TableName, COUNT(*) AS Row_Count FROM fact.Sales
UNION ALL
SELECT 'FactProductInventory', COUNT(*) FROM fact.ProductInventory
UNION ALL
SELECT 'FactPurchasing', COUNT(*) FROM fact.Purchasing;