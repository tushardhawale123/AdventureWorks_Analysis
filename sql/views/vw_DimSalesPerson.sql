CREATE OR ALTER VIEW dbo.vw_DimSalesPerson AS
SELECT
    -- Keys
    sp.BusinessEntityID AS SalesPersonID,
    sp.TerritoryID,
    
    -- Person details
    p.FirstName,
    p.LastName,
    p.FirstName + ' ' + p.LastName AS SalesPersonName,
    e.JobTitle,
    
    -- Territory information
    st.Name AS TerritoryName,
    st.[Group] AS Region,
    
    -- Sales metrics
    sp.SalesQuota,
    sp.Bonus,
    sp.CommissionPct,
    sp.SalesYTD,
    sp.SalesLastYear,
    
    -- Employee details
    e.HireDate,
    e.BirthDate,
    e.Gender,
    DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsWithCompany,
    
    -- Department information
    d.Name AS Department,
    d.GroupName AS DepartmentGroup,
    
    -- Current status
    CASE
        WHEN e.CurrentFlag = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS Status
FROM
    Sales.SalesPerson sp
    JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
    JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
    LEFT JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID
    LEFT JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
        AND edh.EndDate IS NULL
    LEFT JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID;
