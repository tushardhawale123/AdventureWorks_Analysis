CREATE OR ALTER VIEW dbo.vw_DimDate AS
WITH CTE_DatesTable AS (
    SELECT CAST('2011-01-01' AS date) AS DateValue 
    UNION ALL
    SELECT DATEADD(day, 1, DateValue)
    FROM CTE_DatesTable
    WHERE DATEADD(day, 1, DateValue) <= '2025-12-31'
)
SELECT
    -- Date keys
    CAST(CONVERT(varchar, DateValue, 112) AS int) AS DateKey,
    DateValue AS [Date],
    
    -- Calendar hierarchy
    YEAR(DateValue) AS [Year],
    CONCAT('Q', DATEPART(quarter, DateValue)) AS [Quarter],
    MONTH(DateValue) AS MonthNumber,
    DATENAME(month, DateValue) AS MonthName,
    DAY(DateValue) AS [Day],
    
    -- Day properties
    DATEPART(dayofyear, DateValue) AS DayOfYear,
    DATENAME(weekday, DateValue) AS DayOfWeek,
    CASE 
        WHEN DATENAME(weekday, DateValue) IN ('Saturday', 'Sunday') THEN 1 
        ELSE 0 
    END AS IsWeekend,
    
    -- Week information
    DATEPART(week, DateValue) AS WeekOfYear,
    
    -- Month End flag
    CASE 
        WHEN DateValue = EOMONTH(DateValue) THEN 1 
        ELSE 0 
    END AS IsMonthEnd,
    
    -- Fiscal Year (assuming July-June fiscal year)
    CASE 
        WHEN MONTH(DateValue) >= 7 THEN YEAR(DateValue) + 1 
        ELSE YEAR(DateValue) 
    END AS FiscalYear,
    
    -- Fiscal Quarter
    CONCAT('FQ', 
        CASE 
            WHEN MONTH(DateValue) BETWEEN 7 AND 9 THEN 1
            WHEN MONTH(DateValue) BETWEEN 10 AND 12 THEN 2
            WHEN MONTH(DateValue) BETWEEN 1 AND 3 THEN 3
            WHEN MONTH(DateValue) BETWEEN 4 AND 6 THEN 4
        END) AS FiscalQuarter,
    
    -- Year-Month for sorting
    CONCAT(YEAR(DateValue), '-', RIGHT('0' + CAST(MONTH(DateValue) AS varchar(2)), 2)) AS YearMonth,
    
    -- Current date flags
    CASE WHEN DateValue = CAST(GETDATE() AS date) THEN 1 ELSE 0 END AS IsToday,
    CASE WHEN DateValue = DATEADD(DAY, -1, CAST(GETDATE() AS date)) THEN 1 ELSE 0 END AS IsYesterday,
    CASE 
        WHEN DateValue BETWEEN DATEADD(DAY, -30, CAST(GETDATE() AS date)) AND CAST(GETDATE() AS date) 
        THEN 1 ELSE 0 
    END AS IsLast30Days
FROM 
    CTE_DatesTable
OPTION (MAXRECURSION 5000);
