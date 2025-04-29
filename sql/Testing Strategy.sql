-- Test script example for data quality testing
CREATE PROCEDURE Test_DimCustomer_Quality
AS
BEGIN
    -- Test for duplicate keys
    IF EXISTS (
        SELECT CustomerKey, COUNT(*) 
        FROM DimCustomer 
        WHERE IsCurrent = 1
        GROUP BY CustomerKey 
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR('Duplicate keys found in DimCustomer', 16, 1);
        RETURN -1;
    END;
    
    -- Test for orphaned references
    IF EXISTS (
        SELECT fs.CustomerKey
        FROM FactSales fs
        LEFT JOIN DimCustomer dc ON fs.CustomerKey = dc.CustomerKey
        WHERE dc.CustomerKey IS NULL
    )
    BEGIN
        RAISERROR('Orphaned references found in FactSales to DimCustomer', 16, 1);
        RETURN -1;
    END;
    
    -- Test for data completeness
    DECLARE @MissingCount INT;
    SELECT @MissingCount = COUNT(*) 
    FROM Sales.Customer sc
    LEFT JOIN DimCustomer dc ON sc.CustomerID = dc.CustomerID AND dc.IsCurrent = 1
    WHERE dc.CustomerID IS NULL;
    
    IF @MissingCount > 0
    BEGIN
        RAISERROR('Missing %d customers in DimCustomer', 16, 1, @MissingCount);
        RETURN -1;
    END;
    
    PRINT 'All DimCustomer quality tests passed';
    RETURN 0;
END;