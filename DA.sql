SELECT * FROM data_analytics.project;
SELECT COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM project;
SELECT CustomerID,
    COUNT(*) AS TransactionFrequency,          -- Frequency of transactions
    SUM(totalsales) AS Total_Sales,         -- Total sales for the customer
    AVG(totalsales) AS AveragePurchaseSize -- Average purchase size
FROM 
    (select CustomerID, quantity*unitprice as totalsales from project) as a
GROUP BY 
    CustomerID
ORDER BY 
    Total_Sales DESC;  
DESC PROJECT;
WITH RecencyCTE AS (
    SELECT
        CustomerID,
        DATEDIFF(
            CURRENT_DATE(),
            MAX(STR_TO_DATE(invoicedate,'%Y-%m-%d %H:%i:%s'))
        ) AS Recency
    FROM project
    GROUP BY CustomerID
),
FrequencyCTE AS (
    SELECT
        CustomerID,
        COUNT(*) AS Frequency
    FROM project
    GROUP BY CustomerID
),
MonetaryCTE AS (
    SELECT
        CustomerID,
        SUM(quantity * unitprice) AS Monetary
    FROM project
    GROUP BY CustomerID
)
SELECT
    R.CustomerID,
    R.Recency,
    F.Frequency,
    M.Monetary
FROM RecencyCTE R
JOIN FrequencyCTE F ON R.CustomerID = F.CustomerID
JOIN MonetaryCTE M ON R.CustomerID = M.CustomerID
ORDER BY
    R.Recency ASC,
    F.Frequency DESC,
    M.Monetary DESC;
-- To assign RFM scores (e.g., 1–5 for each metric):
   WITH RecencyCTE AS (
    SELECT
        CustomerID,
        DATEDIFF(
            CURRENT_DATE(),
            MAX(STR_TO_DATE(invoicedate, '%Y-%m-%d %H:%i:%s'))
        ) AS Recency
    FROM project
    GROUP BY CustomerID
),
FrequencyCTE AS (
    SELECT
        CustomerID,
        COUNT(*) AS Frequency
    FROM project
    GROUP BY CustomerID
),
MonetaryCTE AS (
    SELECT
        CustomerID,
        SUM(quantity * unitprice) AS Monetary
    FROM project
    GROUP BY CustomerID
),
RFM AS (
    SELECT
        R.CustomerID,
        NTILE(5) OVER (ORDER BY R.Recency ASC) AS RecencyScore,
        NTILE(5) OVER (ORDER BY F.Frequency DESC) AS FrequencyScore,
        NTILE(5) OVER (ORDER BY M.Monetary DESC) AS MonetaryScore
    FROM RecencyCTE R
    JOIN FrequencyCTE F ON R.CustomerID = F.CustomerID
    JOIN MonetaryCTE M ON R.CustomerID = M.CustomerID
)
SELECT
    CustomerID,
    RecencyScore,
    FrequencyScore,
    MonetaryScore,
    (RecencyScore + FrequencyScore + MonetaryScore) AS RFMScore
FROM RFM
ORDER BY RFMScore DESC;
-- identify declining segment
WITH TotalSales AS (
    SELECT 
        CustomerID,
        SUM(totalsales) AS TotalSales
    FROM 
        (select CustomerID, quantity*unitprice as totalsales from project) as a
    GROUP BY 
        CustomerID
),
DeclineSegment AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN TotalSales >= 2000 THEN 'High Value'
            WHEN TotalSales BETWEEN 800 AND 2000 THEN 'Medium Value'
            WHEN TotalSales BETWEEN 400 AND 799 THEN 'Low Value'
            ELSE 'Dormant'
        END AS SalesSegment
    FROM 
        TotalSales
)
SELECT 
    SalesSegment,
    COUNT(CustomerID) AS CustomerCount
FROM 
    DeclineSegment
GROUP BY 
    SalesSegment
ORDER BY 
    FIELD(SalesSegment, 'High Value', 'Medium Value', 'Low Value', 'Dormant');
