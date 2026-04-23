-- Q6: Payment Method Preferences by State

WITH payment_summary AS (
    SELECT
        c.state,
        p.payment_method,
        COUNT(p.payment_id)         AS transaction_count,
        ROUND(SUM(p.amount), 2)     AS total_amount
    FROM payments p
    JOIN orders   o ON p.order_id    = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.state, p.payment_method
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY state ORDER BY transaction_count DESC) AS rnk
    FROM payment_summary
)
SELECT
    state,
    payment_method,
    transaction_count,
    total_amount,
    CASE WHEN rnk = 1 THEN 'Most Popular' ELSE '' END AS popularity_flag
FROM ranked
ORDER BY state, transaction_count DESC;
