
-- ============================================================
-- AXON MANUFACTURING ANALYTICS
-- PURPOSE: Calculate all 19 manufacturing KPIs
-- ============================================================

-- ============================================================
-- SECTION 1: PRODUCTION & EFFICIENCY KPIs (1-11)
-- ============================================================

-- KPI 1-11: Overall Production Dashboard KPIs

SELECT
    COUNT(DISTINCT Doc_Num) AS Total_Work_Orders,
    SUM(WO_Qty) AS Total_WO_Qty,
    SUM(Produced_Qty) AS Total_Manufactured_Qty,
    SUM(Processed_Qty) AS Total_Processed_Qty,
    ROUND(
        SUM(Produced_Qty) / NULLIF(SUM(Processed_Qty), 0) * 100,
        2
    ) AS Efficiency_Rate_Pct,
    ROUND(
        SUM(Processed_Qty) / NULLIF(SUM(WO_Qty), 0) * 100,
        2
    ) AS Machine_Utilization_Pct,
    ROUND(SUM(Total_Value), 2) AS Total_Manufacturing_Cost,
    ROUND(
        SUM(Total_Value) / NULLIF(SUM(Produced_Qty), 0),
        2
    ) AS Cost_Per_Unit,
    ROUND(AVG(Per_Day_Machine_Cost), 2)
        AS Avg_Per_Day_Machine_Cost,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN Delivery_Status = 'On Time' THEN Doc_Num
        END)
        / NULLIF(COUNT(DISTINCT Doc_Num), 0) * 100,
        2
    ) AS On_Time_Delivery_Pct,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN Is_Repeat_Order = 'Yes' THEN Doc_Num
        END)
        / NULLIF(COUNT(DISTINCT Doc_Num), 0) * 100,
        2
    ) AS Repeat_Order_Pct
FROM fact_Production
WHERE Doc_Num IS NOT NULL;

-- ============================================================
-- SECTION 2: QUALITY & REJECTION KPIs (12-15)
-- ============================================================

-- KPI 12-15: Overall Quality Dashboard KPIs

SELECT
    SUM(Rejected_Qty) AS Total_Rejected_Qty,
    ROUND(
        SUM(Rejected_Qty) /
        NULLIF(SUM(Produced_Qty), 0) * 100,
        2
    ) AS Rejection_Rate_Pct,
    ROUND(
        SUM(Rejected_Qty) /
        NULLIF(SUM(Processed_Qty), 0) * 100,
        2
    ) AS Wastage_Pct,
    ROUND(
        SUM(Rejected_Qty) /
        NULLIF(
            SUM(Produced_Qty) - SUM(Rejected_Qty),
            0
        ) * 100,
        2
    ) AS Total_Wastage_Pct
FROM fact_Production
WHERE Doc_Num IS NOT NULL;

-- ============================================================
-- SECTION 3: EMPLOYEE-WISE REJECTED QUANTITY (KPI 16)
-- ============================================================

SELECT
    f.Employee_Code,
    e.Employee_Name,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    RANK() OVER (
        ORDER BY SUM(f.Rejected_Qty) DESC
    ) AS Rejection_Rank
FROM fact_Production f
LEFT JOIN dim_Employee e
    ON f.Employee_Code = e.Employee_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    f.Employee_Code,
    e.Employee_Name
ORDER BY Total_Rejected_Qty DESC;

-- ============================================================
-- SECTION 4: MACHINE-WISE REJECTED QUANTITY (KPI 17)
-- ============================================================

SELECT
    f.Machine_Code,
    m.Machine_Type,
    m.Operation_Name,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    RANK() OVER (
        ORDER BY SUM(f.Rejected_Qty) DESC
    ) AS Rejection_Rank
FROM fact_Production f
LEFT JOIN dim_Machine m
    ON f.Machine_Code = m.Machine_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    f.Machine_Code,
    m.Machine_Type,
    m.Operation_Name
ORDER BY Total_Rejected_Qty DESC;

-- ============================================================
-- SECTION 5: OPERATION-WISE REJECTED QUANTITY (KPI 18)
-- ============================================================

SELECT
    f.Operation_Code,
    o.Operation_Name,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    RANK() OVER (
        ORDER BY SUM(f.Rejected_Qty) DESC
    ) AS Rejection_Rank
FROM fact_Production f
LEFT JOIN dim_Operation o
    ON f.Operation_Code = o.Operation_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    f.Operation_Code,
    o.Operation_Name
ORDER BY Total_Rejected_Qty DESC;

-- ============================================================
-- SECTION 6: DEPARTMENT-WISE MANUFACTURED VS REJECTED (KPI 19)
-- ============================================================

SELECT
    f.Dept_ID,
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
GROUP BY
    f.Dept_ID,
    d.Dept_Name
ORDER BY Total_Rejected_Qty DESC;

-- ============================================================
-- END OF KPI ANALYSIS
-- TOTAL: 19 KPIs
-- ============================================================