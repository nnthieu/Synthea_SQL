--1. Financial Analysis
-- Match claims with transactions 
SELECT c.id, 
       SUM(t.amount) AS total_amount,
       SUM(t.payments) AS total_payments
FROM claims c
LEFT JOIN claims_transactions t ON c.id = t.claimid
GROUP BY c.id
HAVING SUM(t.amount) IS NULL ;

--Top claim categories by amount:
SELECT type, COUNT(*) AS total_claims, 
       SUM(amount) AS total_amount, SUM(payments) AS total_payments
FROM claims_transactions
GROUP BY type
ORDER BY total_amount DESC
LIMIT 10;

-- Unprocessed claims
SELECT claimid, type, fromdate
FROM claims_transactions
WHERE type = 'CHARGE' 
AND fromdate < CURRENT_DATE - INTERVAL '30 days';

-- day interval between date of charge and payment: average proccessing time
SELECT 
    ct.claimid,
    MAX(CASE WHEN ct.type = 'CHARGE' THEN ct.fromdate END) AS charge_date,
    MAX(CASE WHEN ct.type = 'PAYMENT' THEN ct.fromdate END) AS payment_date,
    DATE_PART('day', 
              MAX(CASE WHEN ct.type = 'PAYMENT' THEN ct.fromdate END) - 
              MAX(CASE WHEN ct.type = 'CHARGE' THEN ct.fromdate END)
    ) AS interval_days
FROM claims_transactions ct
WHERE ct.type IN ('CHARGE', 'PAYMENT')
GROUP BY ct.claimid
HAVING MAX(CASE WHEN ct.type = 'CHARGE' THEN ct.fromdate END) IS NOT NULL
   AND MAX(CASE WHEN ct.type = 'PAYMENT' THEN ct.fromdate END) IS NOT NULL
ORDER BY ct.claimid;

-- claims NOT YET PAYMENT

SELECT 
    ct.claimid,
    MAX(CASE WHEN ct.type = 'CHARGE' THEN ct.fromdate END) AS charge_date,
    MAX(CASE WHEN ct.type = 'PAYMENT' THEN ct.fromdate END) AS payment_date,
    DATE_PART('day', 
              CURRENT_DATE - 
              MAX(CASE WHEN ct.type = 'CHARGE' THEN ct.fromdate END)
    ) AS days_since_charge
FROM claims_transactions ct
WHERE ct.type IN ('CHARGE', 'PAYMENT')
GROUP BY ct.claimid
HAVING MAX(CASE WHEN ct.type = 'CHARGE' THEN ct.fromdate END) IS NOT NULL
   AND MAX(CASE WHEN ct.type = 'PAYMENT' THEN ct.fromdate END) IS NULL
ORDER BY ct.claimid;

-- summarize amount of payments by claimid

SELECT claimid, COUNT(claimid) AS total_claims, SUM(payments) AS total_claimed_payments
FROM claims_transactions
WHERE fromdate BETWEEN '2024-01-01' AND '2024-12-31';


-- Total number of claims and amount by type
SELECT type, COUNT(*) AS claim_count, SUM(amount) AS total_amount, SUM(payments) AS total_payments
FROM claims_transactions
WHERE fromdate BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY type
ORDER BY 
    claimid;


-- Amount of payment by type
SELECT 
    claimid,
    SUM(CASE WHEN type = 'CHARGE' THEN amount ELSE 0 END) AS CHARGE_total_amount,
    SUM(CASE WHEN type = 'PAYMENT' THEN payments ELSE 0 END) AS PAYMENT_total_payments,
    SUM(CASE WHEN type = 'TRANSFEROUT' THEN amount ELSE 0 END) AS TRANSFEROUT_total_amount,
    SUM(CASE WHEN type = 'TRANSFERIN' THEN payments ELSE 0 END) AS TRANSFERIN_total_payments
    
FROM 
    claims_transactions
GROUP BY 
    claimid
ORDER BY 
    claimid;

-- Payments over the time (year)

SELECT 
    EXTRACT(YEAR FROM FROMDATE) AS payment_year, 
    SUM(PAYMENTS) AS total_payments
FROM 
    claims_transactions
GROUP BY 
    EXTRACT(YEAR FROM FROMDATE)
ORDER BY 
    payment_year ASC;

-- Payments over the time (month)
SELECT 
    EXTRACT(MONTH FROM FROMDATE) AS payment_month, 
    SUM(PAYMENTS) AS total_payments
FROM 
    claims_transactions
WHERE fromdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    EXTRACT(MONTH FROM FROMDATE)
ORDER BY 
    payment_month ASC;

-- for month-year format
SELECT 
    TO_CHAR(FROMDATE, 'Mon-YYYY') AS month_year, 
    SUM(PAYMENTS) AS total_payments
FROM 
    claims_transactions
WHERE 
    FROMDATE BETWEEN '2023-01-01' AND '2024-12-31'
GROUP BY 
    TO_CHAR(FROMDATE, 'Mon-YYYY')
ORDER BY 
    TO_DATE(TO_CHAR(FROMDATE, 'Mon-YYYY'), 'Mon-YYYY') ASC;

-- Analyze OUTSTANDING to identify unpaid balances or overdue claims.

SELECT 
    CLAIMID,
    PATIENTID,
    PROVIDERID,
    OUTSTANDING,
    FROMDATE::DATE AS start_date,
    TODATE::DATE AS end_date
FROM 
    claims_transactions
WHERE 
    OUTSTANDING > 0
ORDER BY 
    OUTSTANDING DESC; -- Sort by the highest outstanding balance

--Query to Identify Overdue Claims

SELECT 
    CLAIMID,
    PATIENTID,
    PROVIDERID,
    OUTSTANDING,
    FROMDATE::DATE AS start_date,
    TODATE::DATE AS end_date,
    (CURRENT_DATE - TODATE::DATE) AS days_overdue
FROM 
    claims_transactions
WHERE 
    OUTSTANDING > 0 
    AND TODATE < CURRENT_DATE
ORDER BY 
    days_overdue DESC; -- Sort by the most overdue claims

--2. operational analysis
--Service Utilization:Count PLACEOFSERVICE occurrences to see which locations are most commonly used.
SELECT PLACEOFSERVICE, COUNT(*) AS Occurrences
FROM claims_transactions
GROUP BY PLACEOFSERVICE
ORDER BY Occurrences DESC;

--Analyze PROCEDURECODE frequency to determine popular or costly services.
SELECT 
    ct.PROCEDURECODE, 
    COALESCE(p.description, 'Unknown Procedure') AS description,
    COUNT(*) AS Frequency, 
    ROUND(CAST(SUM(ct.AMOUNT) AS NUMERIC), 2) AS TotalCost, 
    ROUND(CAST(AVG(ct.AMOUNT) AS NUMERIC), 2) AS AverageCost
FROM 
    claims_transactions ct
LEFT JOIN procedures p ON ct.PROCEDURECODE = p.code
GROUP BY 
    ct.PROCEDURECODE
ORDER BY 
    Frequency DESC;

--Calculate average time between FROMDATE and TODATE to measure claim processing speed.
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM (TODATE - FROMDATE)) / 86400), 2) AS AvgProcessingTimeDays
FROM 
    claims_transactions
WHERE 
    TODATE IS NOT NULL AND FROMDATE IS NOT NULL;












