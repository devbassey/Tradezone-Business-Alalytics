-- Q7: Review Ratings and Sales Performance

WITH product_ratings AS (
    SELECT
        r.product_id,
        ROUND(AVG(r.rating), 2) AS avg_rating
    FROM reviews r
    WHERE r.rating IS NOT NULL
    GROUP BY r.product_id
),
product_revenue AS (
    SELECT
        oi.product_id,
        ROUND(SUM(oi.line_total), 2) AS total_revenue
    FROM order_items oi
    GROUP BY oi.product_id
)
SELECT
    CASE
        WHEN pr.avg_rating >= 4.0 THEN 'High Rated'
        WHEN pr.avg_rating >= 3.0 THEN 'Mid Rated'
        ELSE                           'Low Rated'
    END                                     AS rating_category,
    COUNT(p.product_id)                     AS product_count,
    ROUND(SUM(rv.total_revenue), 2)         AS total_revenue,
    ROUND(AVG(p.unit_price), 2)             AS avg_unit_price
FROM products p
JOIN product_ratings pr ON p.product_id = pr.product_id
JOIN product_revenue rv ON p.product_id = rv.product_id
GROUP BY rating_category
ORDER BY total_revenue DESC;
