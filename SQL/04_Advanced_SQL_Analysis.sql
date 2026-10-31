-- ============================================================
-- AXON MANUFACTURING ANALYTICS
-- FILE: 04_Advanced_SQL_Analysis.sql
-- PURPOSE: Advanced SQL Analysis
-- ============================================================

-- ============================================================
-- 1. Rank Departments by Production Quantity
-- ============================================================

WITH Department_Production AS (
    SELECT
        d.Dept_Name,
        SUM(f.Produced_Qty) AS Total_Produced_Qty
    FROM fact_Production f
    LEFT JOIN dim_Department d
        ON f.Dept_ID = d.Dept_ID
    WHERE f.Doc_Num IS NOT NULL
    GROUP BY d.Dept_Name
)
SELECT
    Dept_Name,
    Total_Produced_Qty,
    RANK() OVER (
        ORDER BY Total_Produced_Qty DESC
    ) AS Production_Rank
FROM Department_Production;

-- ============================================================
-- 2. Rank Machines by Rejection Quantity
-- ============================================================

WITH Machine_Rejection AS (
    SELECT
        Machine_Code,
        SUM(Rejected_Qty) AS Total_Rejected_Qty
    FROM fact_Production
    WHERE Doc_Num IS NOT NULL
    GROUP BY Machine_Code
)
SELECT
    Machine_Code,
    Total_Rejected_Qty,
    DENSE_RANK() OVER (
        ORDER BY Total_Rejected_Qty DESC
    ) AS Rejection_Rank
FROM Machine_Rejection;

-- ============================================================
-- 3. Monthly Production Running Total
-- ============================================================

WITH Monthly_Production AS (
    SELECT
        YEAR(Date_FK) AS Production_Year,
        MONTH(Date_FK) AS Month_Number,
        MONTHNAME(Date_FK) AS Month_Name,
        SUM(Produced_Qty) AS Total_Produced_Qty
    FROM fact_Production
    WHERE Doc_Num IS NOT NULL
    GROUP BY
        YEAR(Date_FK),
        MONTH(Date_FK),
        MONTHNAME(Date_FK)
)
SELECT
    Production_Year,
    Month_Name,
    Total_Produced_Qty,
    SUM(Total_Produced_Qty) OVER (
        PARTITION BY Production_Year
        ORDER BY Month_Number
    ) AS Running_Production_Total
FROM Monthly_Production
ORDER BY Production_Year, Month_Number;

-- ============================================================
-- 4. Month-over-Month Production Comparison
-- ============================================================

WITH Monthly_Production AS (
    SELECT
        YEAR(Date_FK) AS Production_Year,
        MONTH(Date_FK) AS Month_Number,
        SUM(Produced_Qty) AS Total_Produced_Qty
    FROM fact_Production
    WHERE Doc_Num IS NOT NULL
    GROUP BY YEAR(Date_FK), MONTH(Date_FK)
),
Production_Comparison AS (
    SELECT
        Production_Year,
        Month_Number,
        Total_Produced_Qty,
        LAG(Total_Produced_Qty) OVER (
            ORDER BY Production_Year, Month_Number
        ) AS Previous_Month_Production
    FROM Monthly_Production
)
SELECT
    Production_Year,
    Month_Number,
    Total_Produced_Qty,
    Previous_Month_Production,
    Total_Produced_Qty - Previous_Month_Production
        AS Production_Change,
    ROUND(
        (Total_Produced_Qty - Previous_Month_Production)
        / NULLIF(Previous_Month_Production, 0) * 100,
        2
    ) AS Growth_Pct
FROM Production_Comparison;

-- ============================================================
-- 5. Department-wise Production Contribution
-- ============================================================

WITH Department_Production AS (
    SELECT
        d.Dept_Name,
        SUM(f.Produced_Qty) AS Total_Produced_Qty
    FROM fact_Production f
    LEFT JOIN dim_Department d
        ON f.Dept_ID = d.Dept_ID
    WHERE f.Doc_Num IS NOT NULL
    GROUP BY d.Dept_Name
)
SELECT
    Dept_Name,
    Total_Produced_Qty,
    ROUND(
        Total_Produced_Qty /
        NULLIF(SUM(Total_Produced_Qty) OVER (), 0) * 100,
        2
    ) AS Production_Contribution_Pct
FROM Department_Production
ORDER BY Total_Produced_Qty DESC;

-- ============================================================
-- 6. Top 3 Operations by Rejected Quantity
-- ============================================================

WITH Operation_Rejection AS (
    SELECT
        o.Operation_Name,
        SUM(f.Rejected_Qty) AS Total_Rejected_Qty
    FROM fact_Production f
    LEFT JOIN dim_Operation o
        ON f.Operation_Code = o.Operation_Code
    WHERE f.Doc_Num IS NOT NULL
    GROUP BY o.Operation_Name
),
Ranked_Operations AS (
    SELECT
        Operation_Name,
        Total_Rejected_Qty,
        DENSE_RANK() OVER (
            ORDER BY Total_Rejected_Qty DESC
        ) AS Rejection_Rank
    FROM Operation_Rejection
)
SELECT *
FROM Ranked_Operations
WHERE Rejection_Rank <= 3;

-- ============================================================
-- 7. Employee-wise Rejection Rate
-- ============================================================

SELECT
    e.Employee_Code,
    e.Employee_Name,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    ROUND(
        SUM(f.Rejected_Qty) /
        NULLIF(SUM(f.Produced_Qty), 0) * 100,
        2
    ) AS Rejection_Rate_Pct,
    RANK() OVER (
        ORDER BY
            SUM(f.Rejected_Qty) /
            NULLIF(SUM(f.Produced_Qty), 0) DESC
    ) AS Rejection_Rate_Rank
FROM fact_Production f
LEFT JOIN dim_Employee e
    ON f.Employee_Code = e.Employee_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY e.Employee_Code, e.Employee_Name;

-- ============================================================
-- 8. Buyer-wise Manufacturing Value Contribution
-- ============================================================

WITH Buyer_Value AS (
    SELECT
        b.Buyer_Name,
        SUM(f.Total_Value) AS Total_Value
    FROM fact_Production f
    LEFT JOIN dim_Buyer b
        ON f.Buyer_ID = b.Buyer_ID
    WHERE f.Doc_Num IS NOT NULL
    GROUP BY b.Buyer_Name
)
SELECT
    Buyer_Name,
    Total_Value,
    ROUND(
        Total_Value /
        NULLIF(SUM(Total_Value) OVER (), 0) * 100,
        2
    ) AS Value_Contribution_Pct
FROM Buyer_Value
ORDER BY Total_Value DESC;

-- ============================================================
-- 9. Identify Above-Average Production Work Orders
-- ============================================================

SELECT
    Doc_Num,
    Produced_Qty
FROM fact_Production
WHERE Doc_Num IS NOT NULL
  AND Produced_Qty > (
      SELECT AVG(Produced_Qty)
      FROM fact_Production
      WHERE Doc_Num IS NOT NULL
  )
ORDER BY Produced_Qty DESC;

-- ============================================================
-- 10. Department-wise Monthly Production Ranking
-- ============================================================

WITH Monthly_Department_Production AS (
    SELECT
        d.Dept_Name,
        YEAR(f.Date_FK) AS Production_Year,
        MONTH(f.Date_FK) AS Month_Number,
        SUM(f.Produced_Qty) AS Total_Produced_Qty
    FROM fact_Production f
    LEFT JOIN dim_Department d
        ON f.Dept_ID = d.Dept_ID
    WHERE f.Doc_Num IS NOT NULL
    GROUP BY
        d.Dept_Name,
        YEAR(f.Date_FK),
        MONTH(f.Date_FK)
)
SELECT
    *,
    RANK() OVER (
        PARTITION BY Production_Year, Month_Number
        ORDER BY Total_Produced_Qty DESC
    ) AS Department_Rank
FROM Monthly_Department_Production
ORDER BY Production_Year, Month_Number, Department_Rank;


-- ============================================================
-- END OF ADVANCED SQL ANALYSIS
-- ============================================================