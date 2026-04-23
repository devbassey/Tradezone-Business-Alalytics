-- Q4: Quarterly Revenue Trends — 2023 vs 2024

SELECT
    DATE_PART('year',  order_date)                  AS year,
    DATE_PART('quarter', order_date)                AS quarter,
    ROUND(SUM(total_amount), 2)                     AS total_revenue,
    ROUND(AVG(total_amount), 2)                     AS avg_order_value,
    COUNT(order_id)                                 AS total_orders
FROM orders
WHERE total_amount IS NOT NULL
  AND DATE_PART('year', order_date) IN (2023, 2024)
GROUP BY year, quarter
ORDER BY year, quarter;

-- To find the quarter with strongest growth, compare same quarters across years:
WITH quarterly AS (
    SELECT
        DATE_PART('year',    order_date) AS yr,
        DATE_PART('quarter', order_date) AS qtr,
        SUM(total_amount)                AS revenue
    FROM orders
    WHERE total_amount IS NOT NULL
    GROUP BY yr, qtr
)
SELECT
    q2024.qtr                                       AS quarter,
    ROUND(q2024.revenue, 2)                         AS revenue_2024,
    ROUND(q2023.revenue, 2)                         AS revenue_2023,
    ROUND(q2024.revenue - q2023.revenue, 2)         AS growth_amount,
    ROUND(100.0*(q2024.revenue-q2023.revenue)/q2023.revenue, 1) AS growth_pct
FROM quarterly q2024
JOIN quarterly q2023 ON q2024.qtr = q2023.qtr
    AND q2024.yr = 2024 AND q2023.yr = 2023
ORDER BY growth_pct DESC;