--> Part A: Data Cleaning & Preparation <--

--Birdseye view of all the tables
SELECT * FROM customers
LIMIT 10;

SELECT * FROM order_items
LIMIT 10;

SELECT * FROM orders
LIMIT 10;

SELECT * FROM payments
LIMIT 10;

SELECT * FROM reviews
LIMIT 10;

SELECT * FROM sellers
LIMIT 10;


--> PART A: CLEANING SECTION<-----
----QUESTION 1; Handling Missing Values

-- Flag customers with missing email (do not delete — they still made purchases)
-- We will exclude them only from email-related analysis
-- COUNT of affected rows:
SELECT COUNT(*) AS missing_emails 
FROM customers 
WHERE email IS NULL OR TRIM(email) = ''; --> Shows that there are 16 null values in the email column


-- Orders with NULL total_amount — flag but do not delete
-- These may be cancelled/pending orders
SELECT COUNT(*) AS null_total_orders 
FROM orders 
WHERE total_amount IS NULL; --> Shows that there are 150 null values in the total_amount column

-- Products with NULL unit_price — these cannot appear in revenue calculations
-- Decision: exclude from revenue queries using WHERE unit_price IS NOT NULL
SELECT 
	product_id, 
	product_name 
FROM 
	products 
WHERE 
	unit_price IS NULL;


-- ─────────────────────────────────────────────
-- FLAG MISSING VALUES — Add flag columns
-- ─────────────────────────────────────────────

-- 1. FLAG customers with missing email
ALTER TABLE customers ADD COLUMN IF NOT EXISTS flag_missing_email BOOLEAN DEFAULT FALSE;

UPDATE customers
SET flag_missing_email = TRUE
WHERE email IS NULL OR TRIM(email) = '';

-- 2. FLAG customers with missing signup_date
ALTER TABLE customers ADD COLUMN IF NOT EXISTS flag_missing_signup BOOLEAN DEFAULT FALSE;

UPDATE customers
SET flag_missing_signup = TRUE
WHERE signup_date IS NULL;

-- 3. FLAG orders with NULL total_amount
ALTER TABLE orders ADD COLUMN IF NOT EXISTS flag_missing_total BOOLEAN DEFAULT FALSE;

UPDATE orders
SET flag_missing_total = TRUE
WHERE total_amount IS NULL;

-- 4. FLAG orders with NULL delivery_date (affects Q3 fulfilment calculation)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS flag_missing_delivery BOOLEAN DEFAULT FALSE;

UPDATE orders
SET flag_missing_delivery = TRUE
WHERE delivery_date IS NULL;

-- 5. FLAG products with NULL unit_price (cannot be used in revenue queries)
ALTER TABLE products ADD COLUMN IF NOT EXISTS flag_missing_price BOOLEAN DEFAULT FALSE;

UPDATE products
SET flag_missing_price = TRUE
WHERE unit_price IS NULL;

-- ── Verify your flags ──────────────────────────────────────────
SELECT 'customers - missing email'    AS issue, COUNT(*) FROM customers WHERE flag_missing_email   = TRUE
UNION ALL
SELECT 'customers - missing signup',           COUNT(*) FROM customers WHERE flag_missing_signup  = TRUE
UNION ALL
SELECT 'orders - missing total',               COUNT(*) FROM orders    WHERE flag_missing_total   = TRUE
UNION ALL
SELECT 'orders - missing delivery date',       COUNT(*) FROM orders    WHERE flag_missing_delivery = TRUE
UNION ALL
SELECT 'products - missing price',             COUNT(*) FROM products  WHERE flag_missing_price   = TRUE;

















































-- Fix inconsistent city names in the customers table

UPDATE customers
SET city = TRIM(INITCAP(REPLACE(REPLACE(city, '-', ' '), 'Port Harcourt', 'Port Harcourt')));

-- Fix known variants manually
UPDATE customers SET city = 'Port Harcourt'
WHERE LOWER(TRIM(city)) IN ('port-harcourt', 'portharcourt');

UPDATE sellers
SET city = TRIM(INITCAP(REPLACE(city, '-', ' ')));

UPDATE sellers SET city = 'Port Harcourt'
WHERE LOWER(TRIM(city)) IN ('port-harcourt', 'portharcourt');



-- Normalise category names to Title Case
UPDATE products
SET category = INITCAP(LOWER(TRIM(category)));

UPDATE sellers
SET product_category = INITCAP(LOWER(TRIM(product_category)));


-- Remove duplicate customers (same customer_id)
DELETE FROM customers
WHERE ctid NOT IN (
  SELECT MIN(ctid) FROM customers GROUP BY customer_id
);



-- Remove duplicate sellers
DELETE FROM sellers
WHERE ctid NOT IN (
  SELECT MIN(ctid) FROM sellers GROUP BY seller_id
);

-- Remove duplicate orders
DELETE FROM orders
WHERE ctid NOT IN (
  SELECT MIN(ctid) FROM orders GROUP BY order_id
);










-- Flag orders where total_amount differs from sum of line items by more than ₦10
SELECT
    o.order_id,
    o.total_amount           AS recorded_total,
    SUM(oi.line_total)       AS calculated_total,
    ABS(o.total_amount - SUM(oi.line_total)) AS difference
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - SUM(oi.line_total)) > 10
ORDER BY difference DESC;

-- Note the count of flagged orders. Do NOT delete — flag for finance team.



-- Check for out-of-range ratings
SELECT review_id, rating FROM reviews
WHERE rating < 1 OR rating > 5;

-- Rating of 0 found in dataset — this is invalid
-- Decision: set 0-rated reviews to NULL (unrated) rather than deleting
-- Deleting would lose order linkage data
UPDATE reviews SET rating = NULL WHERE rating = 0;



-- Check for negative unit prices
SELECT product_id, product_name, unit_price
FROM products
WHERE unit_price < 0;

-- Check for negative line totals in order_items
SELECT item_id, order_id, unit_price, quantity, line_total
FROM order_items
WHERE unit_price < 0 OR line_total < 0;



