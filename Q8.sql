-- Q8: Top Seller Bonus Qualification — 2024

SELECT
    s.seller_id,
    s.seller_name,
    COUNT(DISTINCT o.order_id)      AS total_orders,
    ROUND(AVG(r.rating), 2)         AS avg_rating,
    ROUND(SUM(o.total_amount), 2)   AS total_revenue
FROM orders o
JOIN sellers s  ON o.seller_id  = s.seller_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE DATE_PART('year', o.order_date) = 2024
  AND o.order_status = 'Delivered'
  AND o.total_amount IS NOT NULL
GROUP BY s.seller_id, s.seller_name
HAVING COUNT(DISTINCT o.order_id) >= 10
   AND ROUND(AVG(r.rating), 2) >= 4.0
ORDER BY total_revenue DESC
LIMIT 10;
