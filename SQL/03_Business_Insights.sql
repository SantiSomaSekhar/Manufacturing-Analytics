-- ============================================================
-- AXON MANUFACTURING ANALYTICS
-- FILE: 03_Business_Insights.sql
-- PURPOSE: Business Questions and Insights
-- ============================================================

-- ============================================================
-- 1. Which department produces the highest quantity?
-- ============================================================

SELECT
    d.Dept_Name,
    SUM(f.Produced_Qty) AS Total_Produced_Qty
FROM fact_Production f
LEFT JOIN dim_Department d
    ON f.Dept_ID = d.Dept_ID
WHERE f.Doc_Num IS NOT NULL
GROUP BY d.Dept_Name
ORDER BY Total_Produced_Qty DESC;

-- ============================================================
-- 2. Which month has the highest production?
-- ============================================================

SELECT
    dt.Month_Name,
    dt.Month_Num,
    SUM(f.Produced_Qty) AS Total_Produced_Qty
FROM fact_Production f
LEFT JOIN dim_Date dt
    ON f.Date_FK = dt.Date
WHERE f.Doc_Num IS NOT NULL
GROUP BY dt.Month_Name, dt.Month_Num
ORDER BY Total_Produced_Qty DESC;

-- ============================================================
-- 3. Which operation has the highest rejection?
-- ============================================================

SELECT
    o.Operation_Name,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty
FROM fact_Production f
LEFT JOIN dim_Operation o
    ON f.Operation_Code = o.Operation_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY o.Operation_Name
ORDER BY Total_Rejected_Qty DESC;

-- ============================================================
-- 4. Which machines have the highest rejection?
-- ============================================================

SELECT
    m.Machine_Code,
    m.Machine_Type,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty
FROM fact_Production f
LEFT JOIN dim_Machine m
    ON f.Machine_Code = m.Machine_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY m.Machine_Code, m.Machine_Type
ORDER BY Total_Rejected_Qty DESC;


-- ============================================================
-- 5. Which buyers have the best on-time delivery?
-- ============================================================

SELECT
    b.Buyer_Name,
    COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
    COUNT(DISTINCT CASE
        WHEN f.Delivery_Status = 'On Time'
        THEN f.Doc_Num
    END) AS On_Time_Orders,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN f.Delivery_Status = 'On Time'
            THEN f.Doc_Num
        END) /
        NULLIF(COUNT(DISTINCT f.Doc_Num), 0) * 100,
        2
    ) AS On_Time_Delivery_Pct
FROM fact_Production f
LEFT JOIN dim_Buyer b
    ON f.Buyer_ID = b.Buyer_ID
WHERE f.Doc_Num IS NOT NULL
GROUP BY b.Buyer_Name
ORDER BY On_Time_Delivery_Pct DESC;

-- ============================================================
-- 6. Which employees have the highest rejected quantity?
-- ============================================================

SELECT
    e.Employee_Code,
    e.Employee_Name,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty
FROM fact_Production f
LEFT JOIN dim_Employee e
    ON f.Employee_Code = e.Employee_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY e.Employee_Code, e.Employee_Name
ORDER BY Total_Rejected_Qty DESC;

-- ============================================================
-- 7. Which departments have the highest rejection rates?
-- ============================================================

SELECT
    d.Dept_Name,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    ROUND(
        SUM(f.Rejected_Qty) /
        NULLIF(SUM(f.Produced_Qty), 0) * 100,
        2
    ) AS Rejection_Rate_Pct
FROM fact_Production f
LEFT JOIN dim_Department d
    ON f.Dept_ID = d.Dept_ID
WHERE f.Doc_Num IS NOT NULL
GROUP BY d.Dept_Name
ORDER BY Rejection_Rate_Pct DESC;

-- ============================================================
-- 8. What is the distribution of delivery statuses?
-- ============================================================

SELECT
    Delivery_Status,
    COUNT(DISTINCT Doc_Num) AS Total_Work_Orders,
    ROUND(
        COUNT(DISTINCT Doc_Num) /
        NULLIF(
            (SELECT COUNT(DISTINCT Doc_Num)
             FROM fact_Production
             WHERE Doc_Num IS NOT NULL),
            0
        ) * 100,
        2
    ) AS Delivery_Status_Pct
FROM fact_Production
WHERE Doc_Num IS NOT NULL
GROUP BY Delivery_Status
ORDER BY Total_Work_Orders DESC;

-- ============================================================
-- 9. Which buyers generate the highest production value?
-- ============================================================

SELECT
    b.Buyer_Name,
    SUM(f.Total_Value) AS Total_Manufacturing_Value
FROM fact_Production f
LEFT JOIN dim_Buyer b
    ON f.Buyer_ID = b.Buyer_ID
WHERE f.Doc_Num IS NOT NULL
GROUP BY b.Buyer_Name
ORDER BY Total_Manufacturing_Value DESC;


-- ============================================================
-- 10. Rank departments by production performance.
-- ============================================================

SELECT
    d.Dept_Name,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    RANK() OVER (
        ORDER BY SUM(f.Produced_Qty) DESC
    ) AS Production_Rank
FROM fact_Production f
LEFT JOIN dim_Department d
    ON f.Dept_ID = d.Dept_ID
WHERE f.Doc_Num IS NOT NULL
GROUP BY d.Dept_Name;

-- ============================================================
-- END OF BUSINESS INSIGHTS
-- ============================================================