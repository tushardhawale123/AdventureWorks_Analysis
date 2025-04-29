-- Example SCD Type 2 dimension structure for DimProduct
CREATE TABLE DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,              -- Business key
    ProductName NVARCHAR(50) NOT NULL,
    ProductNumber NVARCHAR(25) NOT NULL,
    Color NVARCHAR(15) NULL,
    StandardCost MONEY NULL,
    ListPrice MONEY NULL,
    Size NVARCHAR(5) NULL,
    Weight DECIMAL(8, 2) NULL,
    ProductCategoryName NVARCHAR(50) NULL,
    ProductSubcategoryName NVARCHAR(50) NULL,
    EffectiveStartDate DATETIME NOT NULL,
    EffectiveEndDate DATETIME NULL,
    IsCurrent BIT NOT NULL DEFAULT 1
);