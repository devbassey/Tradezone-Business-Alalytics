-- Q5: Customer Spend Segmentation in 2024

WITH customer_spend AS (
    SELECT
        o.customer_id,
        SUM(o.total_amount) AS total_spend
    FROM orders o
    WHERE DATE_PART('year', o.order_date) = 2024
      AND o.total_amount IS NOT NULL
    GROUP BY o.customer_id
),
segmented AS (
    SELECT
        customer_id,
        total_spend,
        CASE
            WHEN total_spend >= 100000 THEN 'High Spender'
            WHEN total_spend >= 50000  THEN 'Medium Spender'
            ELSE                            'Low Spender'
        END AS segment
    FROM customer_spend
)
SELECT
    segment,
    COUNT(customer_id)              AS customer_count,
    ROUND(AVG(total_spend), 2)      AS avg_spend,
    ROUND(SUM(total_spend), 2)      AS total_revenue_contribution
FROM segmented
GROUP BY segment
ORDER BY avg_spend DESC;