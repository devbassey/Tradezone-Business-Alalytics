-- ═════════════════════════════════════════════════════
-- Q2: PRODUCT PERFORMANCE
-- Top 10 products by total revenue in 2024
-- Includes: product name, category, total revenue,
--           total number of orders
-- Sorted by revenue descending
-- ═════════════════════════════════════════════════════

SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    SUM(oi.line_total)                  AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)        AS avg_selling_price,
    SUM(oi.quantity)                    AS total_units_sold
FROM order_items oi
JOIN products p  ON oi.product_id  = p.product_id
JOIN orders   o  ON oi.order_id    = o.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2024
  AND o.total_amount        IS NOT NULL
  AND p.flag_invalid_price  = FALSE
  AND oi.flag_invalid_line  = FALSE
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_revenue DESC
LIMIT 10;