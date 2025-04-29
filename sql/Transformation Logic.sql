-- Sample transformation for building DimProduct
CREATE PROCEDURE Transform_DimProduct
AS
BEGIN
    -- Identify new or changed products
    MERGE INTO DimProduct AS target
    USING (
        SELECT 
            p.ProductID,
            p.Name AS ProductName,
            p.ProductNumber,
            p.Color,
            p.StandardCost,
            p.ListPrice,
            p.Size,
            p.Weight,
            pc.Name AS ProductCategoryName,
            ps.Name AS ProductSubcategoryName,
            GETDATE() AS EffectiveStartDate,
            CAST(NULL AS DATETIME) AS EffectiveEndDate,
            1 AS IsCurrent
        FROM Production.Product p
        LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
        LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    ) AS source
    ON target.ProductID = source.ProductID AND target.IsCurrent = 1
    
    -- Handle updates with SCD Type 2 logic
    WHEN MATCHED AND (
        ISNULL(target.ProductName,'') <> ISNULL(source.ProductName,'') OR
        ISNULL(target.Color,'') <> ISNULL(source.Color,'') OR
        ISNULL(target.StandardCost,0) <> ISNULL(source.StandardCost,0) OR
        ISNULL(target.ListPrice,0) <> ISNULL(source.ListPrice,0) OR
        ISNULL(target.Size,'') <> ISNULL(source.Size,'') OR
        ISNULL(target.Weight,0) <> ISNULL(source.Weight,0) OR
        ISNULL(target.ProductCategoryName,'') <> ISNULL(source.ProductCategoryName,'') OR
        ISNULL(target.ProductSubcategoryName,'') <> ISNULL(source.ProductSubcategoryName,'')
    ) THEN
        -- Expire the current record
        UPDATE SET 
            target.EffectiveEndDate = GETDATE(),
            target.IsCurrent = 0
            
    WHEN NOT MATCHED THEN
        -- Insert new products
        INSERT (
            ProductID, ProductName, ProductNumber, Color, StandardCost, 
            ListPrice, Size, Weight, ProductCategoryName, ProductSubcategoryName,
            EffectiveStartDate, EffectiveEndDate, IsCurrent
        )
        VALUES (
            source.ProductID, source.ProductName, source.ProductNumber, source.Color, source.StandardCost,
            source.ListPrice, source.Size, source.Weight, source.ProductCategoryName, source.ProductSubcategoryName,
            source.EffectiveStartDate, source.EffectiveEndDate, source.IsCurrent
        );
        
    -- Insert new versions of changed records
    INSERT INTO DimProduct (
        ProductID, ProductName, ProductNumber, Color, StandardCost, 
        ListPrice, Size, Weight, ProductCategoryName, ProductSubcategoryName,
        EffectiveStartDate, EffectiveEndDate, IsCurrent
    )
    SELECT 
        source.ProductID, source.ProductName, source.ProductNumber, source.Color, source.StandardCost,
        source.ListPrice, source.Size, source.Weight, source.ProductCategoryName, source.ProductSubcategoryName,
        GETDATE(), NULL, 1
    FROM (
        -- Same subquery as above
        SELECT 
            p.ProductID,
            p.Name AS ProductName,
            p.ProductNumber,
            p.Color,
            p.StandardCost,
            p.ListPrice,
            p.Size,
            p.Weight,
            pc.Name AS ProductCategoryName,
            ps.Name AS ProductSubcategoryName,
            GETDATE() AS EffectiveStartDate,
            CAST(NULL AS DATETIME) AS EffectiveEndDate,
            1 AS IsCurrent
        FROM Production.Product p
        LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
        LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    ) AS source
    JOIN DimProduct AS target 
        ON target.ProductID = source.ProductID 
        AND target.EffectiveEndDate = GETDATE()
        AND target.IsCurrent = 0;
END;