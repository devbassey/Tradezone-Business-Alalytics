-- Q1: CUSTOMER ACQUISITION & 30-DAY CONVERSION
-- Top 5 states by new customer sign-ups in 2024
-- + percentage who purchased within first 30 days


-- How many new customers signed up in 2024 per state?
SELECT
    state,
    COUNT(*) AS signups_2024
FROM customers
WHERE EXTRACT(YEAR FROM signup_date) = 2024
GROUP BY state
ORDER BY signups_2024 DESC;

-- For a specific customer, what does their
-- signup date vs first order date look like?
-- (Useful to manually verify your logic is correct)
SELECT
    c.customer_id,
    c.state,
    c.signup_date,
    MIN(o.order_date)                           AS first_order_date,
    MIN(o.order_date) - c.signup_date           AS days_to_first_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE EXTRACT(YEAR FROM c.signup_date) = 2024
GROUP BY c.customer_id, c.state, c.signup_date
ORDER BY c.signup_date
LIMIT 20;


-- ─────────────────────────────────────────────
-- STEP 2: THE MAIN QUERY
-- ─────────────────────────────────────────────

WITH new_customers_2024 AS (
    -- All customers who signed up in 2024
    -- One row per customer
    SELECT
        customer_id,
        state,
        signup_date
    FROM customers
    WHERE EXTRACT(YEAR FROM signup_date) = 2024
      AND signup_date IS NOT NULL
      AND state       IS NOT NULL
),

purchase_check AS (
    -- For each 2024 customer, check whether they
    -- placed at least one order within 30 days
    -- of their signup date
    SELECT
        nc.customer_id,
        nc.state,
        nc.signup_date,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM orders o
                WHERE o.customer_id = nc.customer_id
                  AND o.order_date >= nc.signup_date
                  AND o.order_date <= nc.signup_date + INTERVAL '30 days'
                  AND o.total_amount IS NOT NULL
            )
            THEN 1
            ELSE 0
        END                                     AS converted
    FROM new_customers_2024 nc
),

state_summary AS (
    -- Aggregate to state level
    SELECT
        state,
        COUNT(*)                                AS total_signups,
        SUM(converted)                          AS converted_within_30_days,
        COUNT(*) - SUM(converted)               AS not_converted
    FROM purchase_check
    GROUP BY state
)

SELECT
    state,
    total_signups,
    converted_within_30_days,
    not_converted,
    ROUND(
        100.0 * converted_within_30_days
        / NULLIF(total_signups, 0)
    , 1)                                        AS conversion_rate_pct
FROM state_summary
ORDER BY total_signups DESC
LIMIT 5;