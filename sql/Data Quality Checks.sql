-- Sample data quality check procedure
CREATE PROCEDURE Check_DataQuality
AS
BEGIN
    -- Table to store data quality issues
    CREATE TABLE #QualityIssues (
        TableName VARCHAR(100),
        ColumnName VARCHAR(100),
        IssueType VARCHAR(50),
        RecordCount INT,
        IssueDescription VARCHAR(500)
    );
    
    -- Check for missing product categories
    INSERT INTO #QualityIssues
    SELECT 
        'DimProduct',
        'ProductCategoryName',
        'Missing Value',
        COUNT(*),
        'Products with missing category'
    FROM DimProduct
    WHERE ProductCategoryName IS NULL
    AND IsCurrent = 1
    HAVING COUNT(*) > 0;
    
    -- Check for invalid unit prices
    INSERT INTO #QualityIssues
    SELECT 
        'FactSales',
        'UnitPrice',
        'Invalid Value',
        COUNT(*),
        'Sales with zero or negative unit price'
    FROM FactSales
    WHERE UnitPrice <= 0
    HAVING COUNT(*) > 0;
    
    -- Output or log the results
    SELECT * FROM #QualityIssues;
    
    -- Log issues to permanent table
    INSERT INTO ETL_QualityIssueLog (
        CheckDate, TableName, ColumnName, IssueType, RecordCount, IssueDescription
    )
    SELECT 
        GETDATE(), TableName, ColumnName, IssueType, RecordCount, IssueDescription
    FROM #QualityIssues;
    
    DROP TABLE #QualityIssues;
END;