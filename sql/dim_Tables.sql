-- Create Date Dimension Table (critical for time intelligence)
CREATE TABLE dim.Date (
    DateKey INT NOT NULL PRIMARY KEY,
    Date DATE NOT NULL,
    DayOfWeek TINYINT NOT NULL,
    DayName NVARCHAR(10) NOT NULL,
    DayOfMonth TINYINT NOT NULL,
    DayOfYear SMALLINT NOT NULL,
    WeekOfYear TINYINT NOT NULL,
    MonthName NVARCHAR(10) NOT NULL,
    MonthOfYear TINYINT NOT NULL,
    Quarter TINYINT NOT NULL,
    QuarterName NVARCHAR(6) NOT NULL,
    Year SMALLINT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL,
    HolidayName NVARCHAR(50) NULL
);
GO

-- Populate Date Dimension with data from 2011 to 2025
;WITH CTE_Dates AS (
    SELECT CAST('2011-01-01' AS DATE) AS [Date]
    UNION ALL
    SELECT DATEADD(DAY, 1, [Date]) FROM CTE_Dates
    WHERE DATEADD(DAY, 1, [Date]) <= '2025-12-31'
)
INSERT INTO dim.Date (
    DateKey, Date, DayOfWeek, DayName, DayOfMonth, 
    DayOfYear, WeekOfYear, MonthName, MonthOfYear, 
    Quarter, QuarterName, Year, IsWeekend, IsHoliday, HolidayName
)
SELECT 
    CONVERT(INT, CONVERT(VARCHAR, [Date], 112)) AS DateKey,
    [Date],
    DATEPART(WEEKDAY, [Date]) AS DayOfWeek,
    DATENAME(WEEKDAY, [Date]) AS DayName,
    DATEPART(DAY, [Date]) AS DayOfMonth,
    DATEPART(DAYOFYEAR, [Date]) AS DayOfYear,
    DATEPART(WEEK, [Date]) AS WeekOfYear,
    DATENAME(MONTH, [Date]) AS MonthName,
    DATEPART(MONTH, [Date]) AS MonthOfYear,
    DATEPART(QUARTER, [Date]) AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, [Date]) AS VARCHAR) AS QuarterName,
    DATEPART(YEAR, [Date]) AS Year,
    CASE WHEN DATEPART(WEEKDAY, [Date]) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    0 AS IsHoliday, -- You can populate holidays separately
    NULL AS HolidayName
FROM CTE_Dates
OPTION (MAXRECURSION 10000);
GO

-- Create Customer Dimension Table
CREATE TABLE dim.Customer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CustomerAlternateKey NVARCHAR(25) NULL,
    PersonType NCHAR(2) NULL,
    Title NVARCHAR(8) NULL,
    FirstName NVARCHAR(50) NULL,
    MiddleName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NULL,
    NameStyle BIT NULL,
    EmailAddress NVARCHAR(50) NULL,
    EmailPromotion INT NULL,
    AddressLine1 NVARCHAR(60) NULL,
    AddressLine2 NVARCHAR(60) NULL,
    City NVARCHAR(30) NULL,
    StateProvinceName NVARCHAR(50) NULL,
    PostalCode NVARCHAR(15) NULL,
    CountryRegionName NVARCHAR(50) NULL,
    TerritoryName NVARCHAR(50) NULL,
    TerritoryGroup NVARCHAR(50) NULL,
    StoreID INT NULL,
    StoreName NVARCHAR(50) NULL,
    CustomerType NVARCHAR(15) NOT NULL,
    AccountNumber NVARCHAR(10) NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.Customer (
    CustomerID, CustomerAlternateKey, PersonType, Title, FirstName, MiddleName, LastName,
    NameStyle, EmailAddress, EmailPromotion, AddressLine1, AddressLine2, City, 
    StateProvinceName, PostalCode, CountryRegionName, TerritoryName, TerritoryGroup,
    StoreID, StoreName, CustomerType, AccountNumber, StartDate, EndDate, Status
)
SELECT 
    c.CustomerID,
    'AW' + CAST(c.CustomerID AS NVARCHAR(20)) AS CustomerAlternateKey,
    p.PersonType,
    p.Title,
    p.FirstName,
    p.MiddleName,
    p.LastName,
    p.NameStyle,
    ea.EmailAddress,
    p.EmailPromotion,
    a.AddressLine1,
    a.AddressLine2,
    a.City,
    sp.Name AS StateProvinceName,
    a.PostalCode,
    cr.Name AS CountryRegionName,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    s.BusinessEntityID AS StoreID,
    s.Name AS StoreName,
    CASE 
        WHEN s.BusinessEntityID IS NOT NULL AND p.BusinessEntityID IS NOT NULL THEN 'StoreContact'
        WHEN s.BusinessEntityID IS NOT NULL THEN 'Store'
        ELSE 'Individual'
    END AS CustomerType,
    CASE 
        WHEN p.BusinessEntityID IS NULL THEN 'S' + CAST(s.BusinessEntityID AS VARCHAR(10))
        ELSE 'P' + CAST(p.BusinessEntityID AS VARCHAR(10))
    END AS AccountNumber,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    'Current' AS Status
FROM 
    AdventureWorks2019.Sales.Customer c
    LEFT JOIN AdventureWorks2019.Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Person.EmailAddress ea ON p.BusinessEntityID = ea.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Sales.Store s ON c.StoreID = s.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
    LEFT JOIN AdventureWorks2019.Person.BusinessEntityAddress bea ON 
        COALESCE(p.BusinessEntityID, s.BusinessEntityID) = bea.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Person.Address a ON bea.AddressID = a.AddressID
    LEFT JOIN AdventureWorks2019.Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
    LEFT JOIN AdventureWorks2019.Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE bea.AddressTypeID = 2 -- Main Office; Use a different logic if needed
   OR bea.AddressTypeID IS NULL;
GO


-- Create Product Dimension Table
CREATE TABLE dim.Product (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductAlternateKey NVARCHAR(25) NULL,
    ProductName NVARCHAR(50) NOT NULL,
    ProductNumber NVARCHAR(25) NOT NULL,
    MakeFlag BIT NOT NULL,
    FinishedGoodsFlag BIT NOT NULL,
    Color NVARCHAR(15) NULL,
    SafetyStockLevel SMALLINT NOT NULL,
    ReorderPoint SMALLINT NOT NULL,
    StandardCost MONEY NOT NULL,
    ListPrice MONEY NOT NULL,
    Size NVARCHAR(5) NULL,
    SizeUnitMeasureCode NVARCHAR(3) NULL,
    WeightUnitMeasureCode NVARCHAR(3) NULL,
    Weight DECIMAL(8, 2) NULL,
    DaysToManufacture INT NOT NULL,
    ProductLine NVARCHAR(2) NULL,
    Class NVARCHAR(2) NULL,
    Style NVARCHAR(2) NULL,
    ProductSubcategoryID INT NULL,
    ProductSubcategoryName NVARCHAR(50) NULL,
    ProductCategoryID INT NULL,
    ProductCategoryName NVARCHAR(50) NULL,
    ProductModelID INT NULL,
    ProductModelName NVARCHAR(50) NULL,
    SellStartDate DATETIME NOT NULL,
    SellEndDate DATETIME NULL,
    DiscontinuedDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.Product (
    ProductID, ProductAlternateKey, ProductName, ProductNumber, MakeFlag, FinishedGoodsFlag,
    Color, SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, Size,
    SizeUnitMeasureCode, WeightUnitMeasureCode, Weight, DaysToManufacture,
    ProductLine, Class, Style, ProductSubcategoryID, ProductSubcategoryName,
    ProductCategoryID, ProductCategoryName, ProductModelID, ProductModelName,
    SellStartDate, SellEndDate, DiscontinuedDate, Status, StartDate, EndDate
)
SELECT 
    p.ProductID,
    p.ProductNumber AS ProductAlternateKey,
    p.Name AS ProductName,
    p.ProductNumber,
    p.MakeFlag,
    p.FinishedGoodsFlag,
    p.Color,
    p.SafetyStockLevel,
    p.ReorderPoint,
    p.StandardCost,
    p.ListPrice,
    p.Size,
    p.SizeUnitMeasureCode,
    p.WeightUnitMeasureCode,
    p.Weight,
    p.DaysToManufacture,
    p.ProductLine,
    p.Class,
    p.Style,
    ps.ProductSubcategoryID,
    ps.Name AS ProductSubcategoryName,
    pc.ProductCategoryID,
    pc.Name AS ProductCategoryName,
    pm.ProductModelID,
    pm.Name AS ProductModelName,
    p.SellStartDate,
    p.SellEndDate,
    p.DiscontinuedDate,
    CASE 
        WHEN p.SellEndDate IS NULL THEN 'Current' 
        ELSE 'Discontinued'
    END AS Status,
    GETDATE() AS StartDate,
    NULL AS EndDate
FROM 
    AdventureWorks2019.Production.Product p
    LEFT JOIN AdventureWorks2019.Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN AdventureWorks2019.Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    LEFT JOIN AdventureWorks2019.Production.ProductModel pm ON p.ProductModelID = pm.ProductModelID;
GO


ALTER TABLE dim.Product
ALTER COLUMN Status NVARCHAR(15) NOT NULL;


-- Create Territory Dimension Table
CREATE TABLE dim.Territory (
    TerritoryKey INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID INT NOT NULL,
    TerritoryName NVARCHAR(50) NOT NULL,
    TerritoryGroup NVARCHAR(50) NOT NULL,
    CountryRegionCode NVARCHAR(3) NOT NULL,
    CountryRegionName NVARCHAR(50) NOT NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.Territory (
    TerritoryID, TerritoryName, TerritoryGroup, 
    CountryRegionCode, CountryRegionName
)
SELECT 
    st.TerritoryID,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    cr.CountryRegionCode,
    cr.Name AS CountryRegionName
FROM 
    AdventureWorks2019.Sales.SalesTerritory st
    JOIN AdventureWorks2019.Person.CountryRegion cr ON st.CountryRegionCode = cr.CountryRegionCode;
GO


-- Create Sales Person Dimension Table
CREATE TABLE dim.SalesPerson (
    SalesPersonKey INT IDENTITY(1,1) PRIMARY KEY,
    BusinessEntityID INT NOT NULL,
    SalesPersonID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(8) NULL,
    SalesQuota MONEY NULL,
    Bonus MONEY NOT NULL,
    CommissionPct SMALLMONEY NOT NULL,
    SalesYTD MONEY NOT NULL,
    SalesLastYear MONEY NOT NULL,
    TerritoryID INT NULL,
    TerritoryName NVARCHAR(50) NULL,
    TerritoryGroup NVARCHAR(50) NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.SalesPerson (
    BusinessEntityID, SalesPersonID, FirstName, LastName, Title,
    SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear,
    TerritoryID, TerritoryName, TerritoryGroup,
    StartDate, EndDate, Status
)
SELECT 
    sp.BusinessEntityID,
    sp.BusinessEntityID AS SalesPersonID,
    p.FirstName,
    p.LastName,
    p.Title,
    sp.SalesQuota,
    sp.Bonus,
    sp.CommissionPct,
    sp.SalesYTD,
    sp.SalesLastYear,
    sp.TerritoryID,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    'Current' AS Status
FROM 
    AdventureWorks2019.Sales.SalesPerson sp
    JOIN AdventureWorks2019.Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID;
GO


-- Create Vendor Dimension Table
CREATE TABLE dim.Vendor (
    VendorKey INT IDENTITY(1,1) PRIMARY KEY,
    BusinessEntityID INT NOT NULL,
    VendorID INT NOT NULL,
    VendorName NVARCHAR(50) NOT NULL,
    AccountNumber NVARCHAR(15) NOT NULL,
    CreditRating TINYINT NOT NULL,
    PreferredVendorStatus BIT NOT NULL,
    ActiveFlag BIT NOT NULL,
    PurchasingWebServiceURL NVARCHAR(1024) NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.Vendor (
    BusinessEntityID, VendorID, VendorName, AccountNumber,
    CreditRating, PreferredVendorStatus, ActiveFlag,
    PurchasingWebServiceURL, StartDate, EndDate, Status
)
SELECT 
    v.BusinessEntityID,
    v.BusinessEntityID AS VendorID,
    v.Name AS VendorName,
    v.AccountNumber,
    v.CreditRating,
    v.PreferredVendorStatus,
    CASE 
        WHEN v.ActiveFlag = 1 THEN 1 
        ELSE 0
    END AS ActiveFlag,
    v.PurchasingWebServiceURL,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    CASE 
        WHEN v.ActiveFlag = 1 THEN 'Current' 
        ELSE 'Inactive'
    END AS Status
FROM 
    AdventureWorks2019.Purchasing.Vendor v;
GO

----------------------


-- Create Product Category Dimension Table
CREATE TABLE dim.ProductCategory (
    ProductCategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductCategoryID INT NOT NULL,
    ProductCategoryAlternateKey NVARCHAR(50) NULL,
    ProductCategoryName NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.ProductCategory (
    ProductCategoryID, 
    ProductCategoryAlternateKey,
    ProductCategoryName,
    ModifiedDate,
    StartDate,
    EndDate,
    Status
)
SELECT 
    pc.ProductCategoryID,
    'PC-' + CAST(pc.ProductCategoryID AS NVARCHAR(10)) AS ProductCategoryAlternateKey,
    pc.Name AS ProductCategoryName,
    pc.ModifiedDate,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    'Current' AS Status
FROM 
    AdventureWorks2019.Production.ProductCategory pc;
GO

-- Create index for improved lookup performance
CREATE NONCLUSTERED INDEX IX_DimProductCategory_ProductCategoryID
ON dim.ProductCategory(ProductCategoryID);
GO

------------------------------------------

-- Create Product Subcategory Dimension Table
CREATE TABLE dim.ProductSubcategory (
    ProductSubcategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductSubcategoryID INT NOT NULL,
    ProductSubcategoryAlternateKey NVARCHAR(50) NULL,
    ProductSubcategoryName NVARCHAR(50) NOT NULL,
    ProductCategoryKey INT NOT NULL,
    ProductCategoryID INT NOT NULL,
    ProductCategoryName NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL,
    CONSTRAINT FK_DimProductSubcategory_DimProductCategory FOREIGN KEY (ProductCategoryKey)
    REFERENCES dim.ProductCategory (ProductCategoryKey)
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.ProductSubcategory (
    ProductSubcategoryID,
    ProductSubcategoryAlternateKey,
    ProductSubcategoryName,
    ProductCategoryKey,
    ProductCategoryID,
    ProductCategoryName,
    ModifiedDate,
    StartDate,
    EndDate,
    Status
)
SELECT 
    ps.ProductSubcategoryID,
    'PSC-' + CAST(ps.ProductSubcategoryID AS NVARCHAR(10)) AS ProductSubcategoryAlternateKey,
    ps.Name AS ProductSubcategoryName,
    pc.ProductCategoryKey,
    ps.ProductCategoryID,
    pc.ProductCategoryName,
    ps.ModifiedDate,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    'Current' AS Status
FROM 
    AdventureWorks2019.Production.ProductSubcategory ps
    JOIN dim.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID;
GO

-- Create indexes for improved lookup and join performance
CREATE NONCLUSTERED INDEX IX_DimProductSubcategory_ProductSubcategoryID
ON dim.ProductSubcategory(ProductSubcategoryID);

CREATE NONCLUSTERED INDEX IX_DimProductSubcategory_ProductCategoryID
ON dim.ProductSubcategory(ProductCategoryID);
GO

------------------------------------------------

-- Create Department Dimension Table
CREATE TABLE dim.Department (
    DepartmentKey INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentID SMALLINT NOT NULL,
    DepartmentName NVARCHAR(50) NOT NULL,
    GroupName NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.Department (
    DepartmentID,
    DepartmentName,
    GroupName,
    ModifiedDate,
    StartDate,
    EndDate,
    Status
)
SELECT 
    d.DepartmentID,
    d.Name AS DepartmentName,
    d.GroupName,
    d.ModifiedDate,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    'Current' AS Status
FROM 
    AdventureWorks2019.HumanResources.Department d;
GO

-- Create index for improved lookup performance
CREATE NONCLUSTERED INDEX IX_DimDepartment_DepartmentID
ON dim.Department(DepartmentID);
GO

-----------------------------------------

-- Create Employee Dimension Table
CREATE TABLE dim.Employee (
    EmployeeKey INT IDENTITY(1,1) PRIMARY KEY,
    BusinessEntityID INT NOT NULL,
    PersonID INT NOT NULL,
    EmployeeNationalIDAlternateKey NVARCHAR(15) NULL,
    ParentEmployeeKey INT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    NameStyle BIT NOT NULL,
    Title NVARCHAR(8) NULL,
    HireDate DATE NOT NULL,
    BirthDate DATE NOT NULL,
    LoginID NVARCHAR(256) NOT NULL,
    EmailAddress NVARCHAR(50) NULL,
    Phone NVARCHAR(25) NULL,
    MaritalStatus NCHAR(1) NOT NULL,
    EmergencyContactName NVARCHAR(50) NULL,
    EmergencyContactPhone NVARCHAR(25) NULL,
    SalariedFlag BIT NOT NULL,
    Gender NCHAR(1) NOT NULL,
    PayFrequency TINYINT NOT NULL,
    BaseRate MONEY NOT NULL,
    VacationHours SMALLINT NOT NULL,
    SickLeaveHours SMALLINT NOT NULL,
    CurrentFlag BIT NOT NULL,
    SalesPersonFlag BIT NOT NULL,
    DepartmentName NVARCHAR(50) NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    Status NVARCHAR(10) NOT NULL,
    CONSTRAINT FK_DimEmployee_ParentEmployeeKey FOREIGN KEY (ParentEmployeeKey)
    REFERENCES dim.Employee(EmployeeKey)
);
GO

-- Insert from AdventureWorks
INSERT INTO dim.Employee (
    BusinessEntityID,
    PersonID,
    EmployeeNationalIDAlternateKey,
    ParentEmployeeKey,
    FirstName,
    MiddleName,
    LastName,
    NameStyle,
    Title,
    HireDate,
    BirthDate,
    LoginID,
    EmailAddress,
    Phone,
    MaritalStatus,
    EmergencyContactName,
    EmergencyContactPhone,
    SalariedFlag,
    Gender,
    PayFrequency,
    BaseRate,
    VacationHours,
    SickLeaveHours,
    CurrentFlag,
    SalesPersonFlag,
    DepartmentName,
    StartDate,
    EndDate,
    Status
)
SELECT 
    e.BusinessEntityID,
    p.BusinessEntityID AS PersonID,
    e.NationalIDNumber AS EmployeeNationalIDAlternateKey,
    NULL AS ParentEmployeeKey, -- Will update parent keys in a separate step
    p.FirstName,
    p.MiddleName,
    p.LastName,
    p.NameStyle,
    p.Title,
    e.HireDate,
    e.BirthDate,
    e.LoginID,
    ea.EmailAddress,
    pp.PhoneNumber AS Phone,
    e.MaritalStatus,
    ec.FirstName + ' ' + ec.LastName AS EmergencyContactName,
    ecp.PhoneNumber AS EmergencyContactPhone,
    e.SalariedFlag,
    e.Gender,
    eph.PayFrequency,
    eph.Rate AS BaseRate,
    e.VacationHours,
    e.SickLeaveHours,
    e.CurrentFlag,
    CASE WHEN sp.BusinessEntityID IS NULL THEN 0 ELSE 1 END AS SalesPersonFlag,
    d.Name AS DepartmentName,
    GETDATE() AS StartDate,
    NULL AS EndDate,
    CASE WHEN e.CurrentFlag = 1 THEN 'Current' ELSE 'Inactive' END AS Status
FROM 
    AdventureWorks2019.HumanResources.Employee e
    JOIN AdventureWorks2019.Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Person.EmailAddress ea ON p.BusinessEntityID = ea.BusinessEntityID
    LEFT JOIN AdventureWorks2019.Person.PersonPhone pp ON p.BusinessEntityID = pp.BusinessEntityID AND pp.PhoneNumberTypeID = 1 -- Business phone
    LEFT JOIN AdventureWorks2019.Sales.SalesPerson sp ON e.BusinessEntityID = sp.BusinessEntityID
    LEFT JOIN AdventureWorks2019.HumanResources.EmployeeDepartmentHistory edh ON 
        e.BusinessEntityID = edh.BusinessEntityID AND edh.EndDate IS NULL
    LEFT JOIN AdventureWorks2019.HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
    LEFT JOIN AdventureWorks2019.HumanResources.EmployeePayHistory eph ON 
        e.BusinessEntityID = eph.BusinessEntityID
    -- Emergency contact info (using the first contact found as example)
    LEFT JOIN (
        SELECT 
            bec.BusinessEntityID,
            p2.FirstName,
            p2.LastName,
            pp2.PhoneNumber,
            ROW_NUMBER() OVER (PARTITION BY bec.BusinessEntityID ORDER BY bec.BusinessEntityID) AS RowNum
        FROM 
            AdventureWorks2019.Person.BusinessEntityContact bec
            JOIN AdventureWorks2019.Person.ContactType ct ON bec.ContactTypeID = ct.ContactTypeID
            JOIN AdventureWorks2019.Person.Person p2 ON bec.PersonID = p2.BusinessEntityID
            LEFT JOIN AdventureWorks2019.Person.PersonPhone pp2 ON p2.BusinessEntityID = pp2.BusinessEntityID
        WHERE 
            ct.Name = 'Emergency Contact'
    ) ec ON e.BusinessEntityID = ec.BusinessEntityID AND ec.RowNum = 1
    LEFT JOIN AdventureWorks2019.Person.PersonPhone ecp ON ec.PhoneNumber = ecp.PhoneNumber;
GO

-- Update parent employee keys based on organization structure
UPDATE e
SET ParentEmployeeKey = m.EmployeeKey
FROM dim.Employee e
JOIN AdventureWorks2019.HumanResources.Employee he ON e.BusinessEntityID = he.BusinessEntityID
JOIN (
    SELECT 
        OrganizationNode.GetAncestor(1) AS ParentNode,
        BusinessEntityID 
    FROM AdventureWorks2019.HumanResources.Employee
    WHERE OrganizationNode.GetAncestor(1) IS NOT NULL
) os ON he.BusinessEntityID = os.BusinessEntityID
JOIN AdventureWorks2019.HumanResources.Employee pe ON pe.OrganizationNode = os.ParentNode
JOIN dim.Employee m ON pe.BusinessEntityID = m.BusinessEntityID;
GO

-- Create indexes for improved lookup and join performance
CREATE NONCLUSTERED INDEX IX_DimEmployee_BusinessEntityID
ON dim.Employee(BusinessEntityID);

CREATE NONCLUSTERED INDEX IX_DimEmployee_Status
ON dim.Employee(Status);
GO

----------------------------------


-- Add columns to DimProduct to link to subcategory and category properly
ALTER TABLE dim.Product
ADD ProductSubcategoryKey INT NULL,
    CONSTRAINT FK_DimProduct_DimProductSubcategory FOREIGN KEY (ProductSubcategoryKey)
    REFERENCES dim.ProductSubcategory (ProductSubcategoryKey);
GO

-- Update the product dimension with subcategory keys
UPDATE p
SET p.ProductSubcategoryKey = ps.ProductSubcategoryKey
FROM dim.Product p
JOIN dim.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE p.ProductSubcategoryID IS NOT NULL;
GO

-- Create index for improved join performance
CREATE NONCLUSTERED INDEX IX_DimProduct_ProductSubcategoryKey
ON dim.Product(ProductSubcategoryKey);
GO


-- Add EmployeeKey column to DimSalesPerson
ALTER TABLE dim.SalesPerson
ADD EmployeeKey INT NULL,
    CONSTRAINT FK_DimSalesPerson_DimEmployee FOREIGN KEY (EmployeeKey)
    REFERENCES dim.Employee (EmployeeKey);
GO

-- Update the SalesPerson dimension with Employee keys
UPDATE sp
SET sp.EmployeeKey = e.EmployeeKey
FROM dim.SalesPerson sp
JOIN dim.Employee e ON sp.BusinessEntityID = e.BusinessEntityID;
GO

-- Create index for improved join performance
CREATE NONCLUSTERED INDEX IX_DimSalesPerson_EmployeeKey
ON dim.SalesPerson(EmployeeKey);
GO


