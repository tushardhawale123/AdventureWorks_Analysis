CREATE OR ALTER VIEW Sales.vw_DimCustomer AS
SELECT 
    c.CustomerID,
    c.PersonID,
    c.StoreID,
    c.TerritoryID,
    p.FirstName + ' ' + ISNULL(p.MiddleName + ' ', '') + p.LastName AS CustomerName,
    s.Name AS StoreName,
    st.Name AS TerritoryName,
    st.[Group] AS Region,
    CASE
        WHEN c.PersonID IS NULL THEN 'Store'
        ELSE 'Individual'
    END AS CustomerType
FROM 
    Sales.Customer c
    LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
    LEFT JOIN Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID;
