-- Get all tables with row counts
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    SUM(rows) AS Row_Count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.is_ms_shipped = 0
    AND p.index_id IN (0,1)
GROUP BY SCHEMA_NAME(schema_id), name
ORDER BY SchemaName, TableName;

-- Get foreign key relationships to understand entity connections
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTableName,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumnName
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY TableName, ReferencedTableName;