
-- FINANCIAL TRANSACTION ANALYSIS PROJECT
-- DAY 2: SQL DATA ANALYSIS


USE financial_analysis;


-- Q1: View all transactions
SELECT *
FROM financial_transactions;


-- Q2: Count total transactions
SELECT
    COUNT(*) AS total_transactions
FROM financial_transactions;


-- Q3: Calculate financial KPIs
SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount,
    ROUND(AVG(amount_usd), 2) AS average_transaction,
    ROUND(MAX(amount_usd), 2) AS highest_transaction,
    ROUND(MIN(amount_usd), 2) AS lowest_transaction
FROM financial_transactions;


-- Q4: Transactions by status
SELECT
    status,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY status
ORDER BY total_transactions DESC;


-- Q5: Transactions by payment channel
SELECT
    channel,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY channel
ORDER BY total_transactions DESC;


-- Q6: Transactions by merchant category
SELECT
    merchant_category,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY merchant_category
ORDER BY total_amount DESC;


-- Q7: Top 10 highest-value transactions
SELECT
    transaction_id,
    customer_id,
    amount_usd,
    transaction_datetime,
    status
FROM financial_transactions
ORDER BY amount_usd DESC
LIMIT 10;


-- Q8: Daily transaction trends
SELECT
    DATE(transaction_datetime) AS transaction_date,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY DATE(transaction_datetime)
ORDER BY transaction_date;


-- Q9: Transactions by country
SELECT
    country,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY country
ORDER BY total_amount DESC;


-- Q10: Transactions flagged for review
SELECT
    transaction_id,
    customer_id,
    amount_usd,
    review_flag,
    status
FROM financial_transactions
WHERE LOWER(TRIM(review_flag)) IN
    ('true', '1', 'yes', 'review', 'flagged');


-- Q11: High-value transactions
SELECT
    transaction_id,
    customer_id,
    amount_usd,
    is_high_value
FROM financial_transactions
WHERE is_high_value = 1
ORDER BY amount_usd DESC;


-- Q12: After-hours transactions
SELECT
    transaction_id,
    customer_id,
    transaction_datetime,
    amount_usd,
    is_after_hours
FROM financial_transactions
WHERE LOWER(TRIM(is_after_hours)) IN ('true', '1');


-- Q13: Top 10 customers by transaction value
SELECT
    customer_id,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 10;


-- Q14: Monthly transaction trends
SELECT
    DATE_FORMAT(transaction_datetime, '%Y-%m') AS month,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_transactions
GROUP BY DATE_FORMAT(transaction_datetime, '%Y-%m')
ORDER BY month;


-- Q15: Check duplicate transaction IDs
SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM financial_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;



-- END OF DAY 2 SQL ANALYSIS
-- Q16: Create Financial Risk Dashboard View

CREATE OR REPLACE VIEW financial_risk_dashboard AS
SELECT
    transaction_id,
    transaction_datetime,
    DATE(transaction_datetime) AS transaction_date,
    customer_id,
    account_id,
    transaction_type,
    merchant_category,
    amount_usd,
    channel,
    country,
    status,
    is_high_value,
    is_after_hours,
    review_flag,

    CASE
        WHEN status = 'Completed' THEN amount_usd
        ELSE 0
    END AS completed_amount,

    CASE
        WHEN status = 'Declined' THEN 1
        ELSE 0
    END AS declined_flag,

    CASE
        WHEN is_high_value = 1
             AND LOWER(TRIM(is_after_hours)) IN ('true', '1')
        THEN 'High Priority'

        WHEN is_high_value = 1
             OR LOWER(TRIM(is_after_hours)) IN ('true', '1')
        THEN 'Medium Priority'

        ELSE 'Low Priority'
    END AS risk_category

FROM financial_transactions;

-- Q17: Verify Financial Risk Dashboard View

SELECT *
FROM financial_risk_dashboard
LIMIT 10;

-- Q18: Analyze Financial Risk Categories
SELECT
    risk_category,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount_usd), 2) AS total_amount
FROM financial_risk_dashboard
GROUP BY risk_category
ORDER BY transaction_count DESC;


-- Q19: Calculate Financial Performance KPIs

SELECT
    COUNT(*) AS total_transactions,

    ROUND(SUM(completed_amount), 2)
        AS completed_transaction_value,

    SUM(declined_flag)
        AS declined_transactions,

    ROUND(
        100.0 * SUM(declined_flag) / NULLIF(COUNT(*), 0),
        2
    ) AS decline_rate_percentage

FROM financial_risk_dashboard;

-- Q20: Rank Customers by Transaction Amount

SELECT
    customer_id,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS total_amount,
    RANK() OVER (
        ORDER BY SUM(amount_usd) DESC
    ) AS customer_rank
FROM financial_transactions
GROUP BY customer_id
ORDER BY customer_rank
LIMIT 10;

-- Q21: Daily Financial Transaction Trends
WITH daily_transactions AS (
    SELECT
        DATE(transaction_datetime) AS transaction_date,
        COUNT(*) AS transaction_count,
        ROUND(SUM(amount_usd), 2) AS daily_amount
    FROM financial_transactions
    GROUP BY DATE(transaction_datetime)
)

SELECT
    transaction_date,
    transaction_count,
    daily_amount,
    ROUND(
        SUM(daily_amount) OVER (
            ORDER BY transaction_date
        ), 2
    ) AS running_total
FROM daily_transactions
ORDER BY transaction_date;

-- Q22: Transaction Status Percentage
SELECT
    status,
    COUNT(*) AS transaction_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM financial_transactions),
        2
    ) AS percentage
FROM financial_transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- Q23: Identify High-Priority Transactions


SELECT
    transaction_id,
    customer_id,
    transaction_datetime,
    amount_usd,
    is_high_value,
    is_after_hours,
    risk_category
FROM financial_risk_dashboard
WHERE risk_category = 'High Priority'
ORDER BY amount_usd DESC;

-- Q24: Analyze Transaction Risk by Channel

SELECT
    channel,
    COUNT(*) AS total_transactions,

    SUM(
        CASE
            WHEN risk_category = 'High Priority'
            THEN 1 ELSE 0
        END
    ) AS high_priority_transactions,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN risk_category = 'High Priority'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS high_priority_percentage

FROM financial_risk_dashboard
GROUP BY channel
ORDER BY high_priority_percentage DESC;

-- Q25: Financial Transaction Data Quality

SELECT
    COUNT(*) AS total_records,

    SUM(
        CASE
            WHEN transaction_id IS NULL
                 OR TRIM(transaction_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_transaction_ids,

    SUM(
        CASE
            WHEN customer_id IS NULL
                 OR TRIM(customer_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_customer_ids,

    SUM(
        CASE
            WHEN amount_usd IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_amounts

FROM financial_transactions;



