-- ═════════════════════════════════════════════════════
-- Q3: SELLER FULFILMENT EFFICIENCY
-- Average hours between order placement and delivery
-- Top 20 fastest sellers
-- Minimum 20 completed orders
-- Includes total completed orders and avg customer rating
-- ═════════════════════════════════════════════════════

SELECT
    s.seller_id,
    s.seller_name,
    COUNT(o.order_id)                               AS completed_orders,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (o.delivery_date::TIMESTAMP - o.order_date::TIMESTAMP))
        / 3600), 1
    )                                               AS avg_fulfil_hours,
    ROUND(AVG(r.rating), 2)                         AS avg_rating
FROM orders o
JOIN sellers s ON o.seller_id = s.seller_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'Delivered'
  AND o.delivery_date IS NOT NULL
GROUP BY s.seller_id, s.seller_name
HAVING COUNT(o.order_id) >= 20
ORDER BY avg_fulfil_hours ASC
LIMIT 20;
