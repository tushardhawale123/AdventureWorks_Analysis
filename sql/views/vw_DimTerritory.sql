CREATE OR ALTER VIEW dbo.vw_DimTerritory AS
SELECT
    -- Keys
    st.TerritoryID,
    st.CountryRegionCode,
    
    -- Territory attributes
    st.Name AS TerritoryName,
    st.[Group] AS Region,
    cr.Name AS CountryRegionName,
    
    -- Geography grouping (for maps)
    CASE st.[Group]
        WHEN 'North America' THEN 1
        WHEN 'Europe' THEN 2
        WHEN 'Pacific' THEN 3
        ELSE 4
    END AS RegionSortOrder,
    
    -- Sales management
    ISNULL(p.FirstName + ' ' + p.LastName, 'Unassigned') AS SalesManager,
    
    -- Cost centers
    st.CostYTD,
    st.CostLastYear,
    
    -- YTD calculations
    CASE
        WHEN st.SalesYTD = 0 THEN 0
        ELSE st.CostYTD / st.SalesYTD
    END AS CostToSalesRatioYTD
FROM
    Sales.SalesTerritory st
    LEFT JOIN Person.CountryRegion cr ON st.CountryRegionCode = cr.CountryRegionCode
    LEFT JOIN (
        SELECT
            sp.TerritoryID,
            p.FirstName,
            p.LastName,
            ROW_NUMBER() OVER (PARTITION BY sp.TerritoryID ORDER BY sp.ModifiedDate DESC) as RowNum
        FROM
            Sales.SalesPerson sp
            JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
    ) p ON st.TerritoryID = p.TerritoryID AND p.RowNum = 1;
