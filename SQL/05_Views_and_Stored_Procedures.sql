
-- ============================================================
-- PART A: SQL VIEWS
-- ============================================================

-- Q1. Create a view for overall production summary

CREATE OR REPLACE VIEW vw_Production_Summary AS
SELECT
    COUNT(DISTINCT Doc_Num) AS Total_Work_Orders,
    SUM(WO_Qty) AS Total_Ordered_Qty,
    SUM(Processed_Qty) AS Total_Processed_Qty,
    SUM(Produced_Qty) AS Total_Produced_Qty,
    SUM(Rejected_Qty) AS Total_Rejected_Qty,
    SUM(Total_Value) AS Total_Manufacturing_Cost,
    ROUND(
        SUM(Produced_Qty) / NULLIF(SUM(Processed_Qty), 0) * 100, 2
    ) AS Efficiency_Rate_Pct,
    ROUND(
        SUM(Processed_Qty) / NULLIF(SUM(WO_Qty), 0) * 100, 2
    ) AS Machine_Utilization_Pct
FROM fact_Production
WHERE Doc_Num IS NOT NULL;


-- Q2. Create a view for monthly production performance

CREATE OR REPLACE VIEW vw_Monthly_Production AS
SELECT
    d.Year,
    d.Month_Num,
    d.Month_Name,
    SUM(f.WO_Qty) AS Total_Ordered_Qty,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    SUM(f.Total_Value) AS Total_Manufacturing_Value
FROM fact_Production f
JOIN dim_Date d
    ON f.Date_FK = d.Date
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    d.Year,
    d.Month_Num,
    d.Month_Name;


-- Q3. Create a view for quality and rejection summary

CREATE OR REPLACE VIEW vw_Quality_Summary AS
SELECT
    SUM(Processed_Qty) AS Total_Processed_Qty,
    SUM(Produced_Qty) AS Total_Produced_Qty,
    SUM(Rejected_Qty) AS Total_Rejected_Qty,

    ROUND(
        SUM(Rejected_Qty) / NULLIF(SUM(Produced_Qty), 0) * 100, 2
    ) AS Rejection_Rate_Pct,

    ROUND(
        SUM(Rejected_Qty) / NULLIF(SUM(Processed_Qty), 0) * 100, 2
    ) AS Wastage_Pct,

    ROUND(
        SUM(Rejected_Qty) /
        NULLIF(SUM(Produced_Qty) - SUM(Rejected_Qty), 0) * 100, 2
    ) AS Total_Wastage_Pct

FROM fact_Production
WHERE Doc_Num IS NOT NULL;


-- Q4. Create a view for machine-wise performance

CREATE OR REPLACE VIEW vw_Machine_Performance AS
SELECT
    m.Machine_Code,
    m.Machine_Type,
    COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
    SUM(f.WO_Qty) AS Total_Ordered_Qty,
    SUM(f.Processed_Qty) AS Total_Processed_Qty,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    ROUND(
        SUM(f.Rejected_Qty) /
        NULLIF(SUM(f.Produced_Qty), 0) * 100, 2
    ) AS Rejection_Rate_Pct,
    SUM(f.Per_Day_Machine_Cost) AS Total_Machine_Cost
FROM fact_Production f
JOIN dim_Machine m
    ON f.Machine_Code = m.Machine_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    m.Machine_Code,
    m.Machine_Type;


-- Q5. Create a view for operation-wise performance

CREATE OR REPLACE VIEW vw_Operation_Performance AS
SELECT
    o.Operation_Code,
    o.Operation_Name,
    COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    ROUND(
        SUM(f.Rejected_Qty) /
        NULLIF(SUM(f.Produced_Qty), 0) * 100, 2
    ) AS Rejection_Rate_Pct
FROM fact_Production f
JOIN dim_Operation o
    ON f.Operation_Code = o.Operation_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    o.Operation_Code,
    o.Operation_Name;


-- Q6. Create a view for buyer-wise delivery performance

CREATE OR REPLACE VIEW vw_Buyer_Delivery_Performance AS
SELECT
    b.Buyer_ID,
    b.Buyer_Name,
    COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,

    SUM(CASE
        WHEN f.Delivery_Status = 'On Time' THEN 1
        ELSE 0
    END) AS On_Time_Orders,

    SUM(CASE
        WHEN f.Delivery_Status = 'Late' THEN 1
        ELSE 0
    END) AS Late_Orders,

    SUM(CASE
        WHEN f.Delivery_Status = 'Early' THEN 1
        ELSE 0
    END) AS Early_Orders,

    ROUND(
        SUM(CASE
            WHEN f.Delivery_Status = 'On Time' THEN 1
            ELSE 0
        END) /
        NULLIF(COUNT(f.Doc_Num), 0) * 100, 2
    ) AS On_Time_Delivery_Pct,

    SUM(f.Total_Value) AS Total_Manufacturing_Value

FROM fact_Production f
JOIN dim_Buyer b
    ON f.Buyer_ID = b.Buyer_ID
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    b.Buyer_ID,
    b.Buyer_Name;


-- Q7. Create a view for employee-wise quality performance

CREATE OR REPLACE VIEW vw_Employee_Quality_Performance AS
SELECT
    e.Employee_Code,
    e.Employee_Name,
    e.Department,
    COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
    SUM(f.Produced_Qty) AS Total_Produced_Qty,
    SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
    ROUND(
        SUM(f.Rejected_Qty) /
        NULLIF(SUM(f.Produced_Qty), 0) * 100, 2
    ) AS Rejection_Rate_Pct
FROM fact_Production f
JOIN dim_Employee e
    ON f.Employee_Code = e.Employee_Code
WHERE f.Doc_Num IS NOT NULL
GROUP BY
    e.Employee_Code,
    e.Employee_Name,
    e.Department;


-- Q8. Create a view for delivery status distribution

CREATE OR REPLACE VIEW vw_Delivery_Status_Summary AS
SELECT
    Delivery_Status,
    COUNT(Doc_Num) AS Total_Orders,
    ROUND(
        COUNT(Doc_Num) /
        NULLIF(
            (SELECT COUNT(Doc_Num)
             FROM fact_Production
             WHERE Doc_Num IS NOT NULL), 0
        ) * 100, 2
    ) AS Order_Percentage
FROM fact_Production
WHERE Doc_Num IS NOT NULL
GROUP BY Delivery_Status;


-- ============================================================
-- PART B: STORED PROCEDURES
-- ============================================================

USE axon_mfg;


-- Q9. Retrieve production details by department

DROP PROCEDURE IF EXISTS sp_Get_Production_By_Department;

DELIMITER //

CREATE PROCEDURE sp_Get_Production_By_Department(
    IN p_dept_id VARCHAR(5)
)
BEGIN
    SELECT
        d.Dept_ID,
        d.Dept_Name,
        COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
        SUM(f.WO_Qty) AS Total_Ordered_Qty,
        SUM(f.Produced_Qty) AS Total_Produced_Qty,
        SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
        SUM(f.Total_Value) AS Total_Manufacturing_Value

    FROM fact_Production f

    JOIN dim_Department d
        ON f.Dept_ID = d.Dept_ID

    WHERE f.Doc_Num IS NOT NULL
      AND f.Dept_ID = p_dept_id

    GROUP BY
        d.Dept_ID,
        d.Dept_Name;

END //


-- Q10. Retrieve production details within a date range

DROP PROCEDURE IF EXISTS sp_Get_Production_By_Date_Range;

CREATE PROCEDURE sp_Get_Production_By_Date_Range(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN

    SELECT
        f.Doc_Num,
        f.Date_FK,
        d.Dept_Name,
        b.Buyer_Name,
        f.WO_Qty,
        f.Processed_Qty,
        f.Produced_Qty,
        f.Rejected_Qty,
        f.Delivery_Status,
        f.Total_Value

    FROM fact_Production f

    LEFT JOIN dim_Department d
        ON f.Dept_ID = d.Dept_ID

    LEFT JOIN dim_Buyer b
        ON f.Buyer_ID = b.Buyer_ID

    WHERE f.Doc_Num IS NOT NULL
      AND f.Date_FK BETWEEN p_start_date AND p_end_date

    ORDER BY f.Date_FK;

END //


-- Q11. Retrieve machine-wise quality performance

DROP PROCEDURE IF EXISTS sp_Get_Quality_By_Machine;

CREATE PROCEDURE sp_Get_Quality_By_Machine(
    IN p_machine_code VARCHAR(10)
)
BEGIN

    SELECT
        m.Machine_Code,
        m.Machine_Type,
        COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
        SUM(f.Produced_Qty) AS Total_Produced_Qty,
        SUM(f.Rejected_Qty) AS Total_Rejected_Qty,

        ROUND(
            SUM(f.Rejected_Qty) /
            NULLIF(SUM(f.Produced_Qty), 0) * 100,
            2
        ) AS Rejection_Rate_Pct

    FROM fact_Production f

    JOIN dim_Machine m
        ON f.Machine_Code = m.Machine_Code

    WHERE f.Doc_Num IS NOT NULL
      AND f.Machine_Code = p_machine_code

    GROUP BY
        m.Machine_Code,
        m.Machine_Type;

END //


-- Q12. Retrieve buyer-wise performance

DROP PROCEDURE IF EXISTS sp_Get_Buyer_Performance;

CREATE PROCEDURE sp_Get_Buyer_Performance(
    IN p_buyer_id VARCHAR(10)
)
BEGIN

    SELECT
        b.Buyer_ID,
        b.Buyer_Name,
        COUNT(DISTINCT f.Doc_Num) AS Total_Work_Orders,
        SUM(f.WO_Qty) AS Total_Ordered_Qty,
        SUM(f.Produced_Qty) AS Total_Produced_Qty,
        SUM(f.Rejected_Qty) AS Total_Rejected_Qty,
        SUM(f.Total_Value) AS Total_Manufacturing_Value,

        ROUND(
            SUM(
                CASE
                    WHEN f.Delivery_Status = 'On Time'
                    THEN 1
                    ELSE 0
                END
            ) /
            NULLIF(COUNT(f.Doc_Num), 0) * 100,
            2
        ) AS On_Time_Delivery_Pct

    FROM fact_Production f

    JOIN dim_Buyer b
        ON f.Buyer_ID = b.Buyer_ID

    WHERE f.Doc_Num IS NOT NULL
      AND f.Buyer_ID = p_buyer_id

    GROUP BY
        b.Buyer_ID,
        b.Buyer_Name;

END //

DELIMITER ;


-- ============================================================
-- PART C: TEST STORED PROCEDURES
-- ============================================================

-- Q9 Test
-- Replace with an actual department ID.

CALL sp_Get_Production_By_Department('D01');


-- Q10 Test
-- Use dates within your dataset's date range.

CALL sp_Get_Production_By_Date_Range(
    '2015-01-01',
    '2015-12-31'
);


-- Q11 Test
-- Replace with an actual machine code.

CALL sp_Get_Quality_By_Machine('MC001');


-- Q12 Test
-- Replace with an actual buyer ID.

CALL sp_Get_Buyer_Performance('B01');