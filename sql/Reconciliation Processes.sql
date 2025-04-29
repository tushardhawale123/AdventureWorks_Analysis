CREATE PROCEDURE Validate_SalesFactLoad
AS
BEGIN
    DECLARE @SourceCount INT, @TargetCount INT, @Variance INT;
    DECLARE @BodyMessage NVARCHAR(MAX); -- Add this variable for email body
    
    -- Get source count
    SELECT @SourceCount = COUNT(*) 
    FROM Sales.SalesOrderDetail;
    
    -- Get target count
    SELECT @TargetCount = COUNT(*) 
    FROM FactSales;
    
    -- Calculate variance
    SET @Variance = @SourceCount - @TargetCount;
    
    -- Log the results
    INSERT INTO ETL_ValidationLog (
        ValidationDate, TableName, SourceCount, TargetCount, 
        Variance, PassedValidation, Comments
    )
    VALUES (
        GETDATE(), 'FactSales', @SourceCount, @TargetCount, 
        @Variance, IIF(@Variance = 0, 1, 0), 
        CASE 
            WHEN @Variance = 0 THEN 'Validation passed'
            ELSE 'Count mismatch detected'
        END
    );
    
    -- Generate alert for failures
    IF @Variance <> 0
    BEGIN
        -- Build body message safely
        SET @BodyMessage = 'Count mismatch detected in FactSales load.' + CHAR(13) + CHAR(10) +
                           'Source count: ' + CAST(@SourceCount AS VARCHAR(20)) + CHAR(13) + CHAR(10) +
                           'Target count: ' + CAST(@TargetCount AS VARCHAR(20)) + CHAR(13) + CHAR(10) +
                           'Variance: ' + CAST(@Variance AS VARCHAR(20));
        
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ETL Notifications',
            @recipients = 'data.team@example.com',
            @subject = 'ETL Validation Failed: FactSales',
            @body = @BodyMessage;
    END
END;
