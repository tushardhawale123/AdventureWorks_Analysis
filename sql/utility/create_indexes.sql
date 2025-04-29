SET NOCOUNT ON;
PRINT '============================================================';
PRINT 'Starting index creation process for AdventureWorks Analytics';
PRINT 'Start time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '============================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @IndexStartTime DATETIME;
    DECLARE @IndexName NVARCHAR(128);
    DECLARE @TableName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- =============================================
    -- Sales Order Header Indexes
    -- =============================================
    SET @IndexStartTime = GETDATE();
    SET @TableName = 'Sales.SalesOrderHeader';
    
    -- Index for OrderDate filtering (frequently used in time-based analysis)
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderHeader_OrderDate' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesOrderHeader_OrderDate';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesOrderHeader_OrderDate ON Sales.SalesOrderHeader (OrderDate)
        INCLUDE (CustomerID, SalesPersonID, TerritoryID, TotalDue);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesOrderHeader_OrderDate already exists on ' + @TableName;
    END
    
    -- Index for Customer analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderHeader_CustomerID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesOrderHeader_CustomerID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesOrderHeader_CustomerID ON Sales.SalesOrderHeader (CustomerID)
        INCLUDE (OrderDate, TotalDue, OnlineOrderFlag);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesOrderHeader_CustomerID already exists on ' + @TableName;
    END
    
    -- Index for Territory analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderHeader_TerritoryID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesOrderHeader_TerritoryID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesOrderHeader_TerritoryID ON Sales.SalesOrderHeader (TerritoryID)
        INCLUDE (OrderDate, TotalDue);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesOrderHeader_TerritoryID already exists on ' + @TableName;
    END
    
    -- Index for SalesPerson analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderHeader_SalesPersonID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesOrderHeader_SalesPersonID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesOrderHeader_SalesPersonID ON Sales.SalesOrderHeader (SalesPersonID)
        INCLUDE (OrderDate, TotalDue);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesOrderHeader_SalesPersonID already exists on ' + @TableName;
    END
    
    -- =============================================
    -- Sales Order Detail Indexes
    -- =============================================
    SET @TableName = 'Sales.SalesOrderDetail';
    
    -- Index for Product analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderDetail_ProductID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesOrderDetail_ProductID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesOrderDetail_ProductID ON Sales.SalesOrderDetail (ProductID)
        INCLUDE (OrderQty, UnitPrice, UnitPriceDiscount, LineTotal);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesOrderDetail_ProductID already exists on ' + @TableName;
    END

    -- Index for Special Offer analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderDetail_SpecialOfferID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesOrderDetail_SpecialOfferID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesOrderDetail_SpecialOfferID ON Sales.SalesOrderDetail (SpecialOfferID, ProductID)
        INCLUDE (OrderQty, UnitPrice, LineTotal);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesOrderDetail_SpecialOfferID already exists on ' + @TableName;
    END
    
    -- =============================================
    -- Customer Indexes
    -- =============================================
    SET @TableName = 'Sales.Customer';
    
    -- Index for Customer analysis by type (Individual vs Store)
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_PersonID_StoreID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_Customer_PersonID_StoreID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_Customer_PersonID_StoreID ON Sales.Customer (PersonID, StoreID, TerritoryID);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_Customer_PersonID_StoreID already exists on ' + @TableName;
    END
    
    -- =============================================
    -- Product Indexes
    -- =============================================
    SET @TableName = 'Production.Product';
    
    -- Index for Product Category analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Product_ProductSubcategoryID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_Product_ProductSubcategoryID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_Product_ProductSubcategoryID ON Production.Product (ProductSubcategoryID)
        INCLUDE (Name, ProductNumber, StandardCost, ListPrice, Color, Size);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_Product_ProductSubcategoryID already exists on ' + @TableName;
    END
    
    -- Index for Price Range analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Product_ListPrice' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_Product_ListPrice';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_Product_ListPrice ON Production.Product (ListPrice)
        INCLUDE (ProductID, Name, StandardCost);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_Product_ListPrice already exists on ' + @TableName;
    END
    
    -- =============================================
    -- ProductInventory Indexes
    -- =============================================
    SET @TableName = 'Production.ProductInventory';
    
    -- Index for Inventory analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProductInventory_ProductID_LocationID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_ProductInventory_ProductID_LocationID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_ProductInventory_ProductID_LocationID ON Production.ProductInventory (ProductID, LocationID)
        INCLUDE (Quantity, Shelf, Bin);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_ProductInventory_ProductID_LocationID already exists on ' + @TableName;
    END

    -- =============================================
    -- SalesPerson Indexes
    -- =============================================
    SET @TableName = 'Sales.SalesPerson';
    
    -- Index for SalesPerson Territory analysis
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesPerson_TerritoryID' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_SalesPerson_TerritoryID';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_SalesPerson_TerritoryID ON Sales.SalesPerson (TerritoryID)
        INCLUDE (BusinessEntityID, SalesQuota, Bonus, CommissionPct, SalesYTD);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_SalesPerson_TerritoryID already exists on ' + @TableName;
    END
    
    -- =============================================
    -- Person Indexes
    -- =============================================
    SET @TableName = 'Person.Person';
    
    -- Index for Name searches
    SET @IndexStartTime = GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Person_LastName_FirstName' AND object_id = OBJECT_ID(@TableName))
    BEGIN
        SET @IndexName = 'IX_Person_LastName_FirstName';
        PRINT 'Creating index ' + @IndexName + ' on ' + @TableName;
        CREATE INDEX IX_Person_LastName_FirstName ON Person.Person (LastName, FirstName)
        INCLUDE (BusinessEntityID, MiddleName, Title, EmailPromotion);
        PRINT 'Index ' + @IndexName + ' created in ' + 
              CAST(DATEDIFF(MILLISECOND, @IndexStartTime, GETDATE()) AS VARCHAR) + 'ms';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_Person_LastName_FirstName already exists on ' + @TableName;
    END
    
    COMMIT TRANSACTION;
    
    -- Update statistics on key tables
    PRINT 'Updating statistics on Sales.SalesOrderHeader...';
    UPDATE STATISTICS Sales.SalesOrderHeader;
    
    PRINT 'Updating statistics on Sales.SalesOrderDetail...';
    UPDATE STATISTICS Sales.SalesOrderDetail;
    
    PRINT 'Updating statistics on Production.Product...';
    UPDATE STATISTICS Production.Product;
    
    PRINT 'Updating statistics on Sales.Customer...';
    UPDATE STATISTICS Sales.Customer;
    
    PRINT 'Index creation and statistics update completed successfully';
    
END TRY
BEGIN CATCH
    -- Error handling
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    PRINT '==============================================================';
    PRINT 'ERROR: Index creation failed with the following error details:';
    PRINT '==============================================================';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
    PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10));
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT 'Error Message: ' + ERROR_MESSAGE();
END CATCH

PRINT '============================================================';
PRINT 'Index creation process completed';
PRINT 'End time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '============================================================';
GO
