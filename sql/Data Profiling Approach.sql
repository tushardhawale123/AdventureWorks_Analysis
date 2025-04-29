-- Sample data profiling T-SQL script template for any table
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT ColumnName) AS UniqueValues,
    MIN(ColumnName) AS MinValue,
    MAX(ColumnName) AS MaxValue,
    AVG(CAST(ColumnName AS FLOAT)) AS AvgValue, -- For numeric columns
    SUM(CASE WHEN ColumnName IS NULL THEN 1 ELSE 0 END) AS NullCount,
    SUM(CASE WHEN LEN(TRIM(ColumnName)) = 0 THEN 1 ELSE 0 END) AS EmptyCount
FROM SchemaName.TableName;