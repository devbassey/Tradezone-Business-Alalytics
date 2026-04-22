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

-- ── flag Verification ──────────────────────────────────────────
SELECT 'customers - missing email'    AS issue, COUNT(*) FROM customers WHERE flag_missing_email   = TRUE
UNION ALL
SELECT 'customers - missing signup',           COUNT(*) FROM customers WHERE flag_missing_signup  = TRUE
UNION ALL
SELECT 'orders - missing total',               COUNT(*) FROM orders    WHERE flag_missing_total   = TRUE
UNION ALL
SELECT 'orders - missing delivery date',       COUNT(*) FROM orders    WHERE flag_missing_delivery = TRUE
UNION ALL
SELECT 'products - missing price',             COUNT(*) FROM products  WHERE flag_missing_price   = TRUE;



----QUESTION 2; Removing Duplicate Records
-- A: fist, we identify the duplicate rows in customers, sellers and orders.

-- ─────────────────────────────────────────────
-- IDENTIFY DUPLICATE ROWS
-- ─────────────────────────────────────────────

-- ── 1. CUSTOMERS ──────────────────────────────
-- Duplicates = same customer_id appearing more than once

SELECT
    customer_id,
    COUNT(*)        AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- See the full duplicate rows side by side
SELECT *
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)
ORDER BY customer_id;


-- ── 2. SELLERS ────────────────────────────────
-- Duplicates = same seller_id appearing more than once

SELECT
    seller_id,
    COUNT(*)        AS duplicate_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- See the full duplicate rows side by side
SELECT *
FROM sellers
WHERE seller_id IN (
    SELECT seller_id
    FROM sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
)
ORDER BY seller_id;


-- ── 3. ORDERS ─────────────────────────────────
-- Duplicates = same order_id appearing more than once

SELECT
    order_id,
    COUNT(*)        AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- See the full duplicate rows side by side
SELECT *
FROM orders
WHERE order_id IN (
    SELECT order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;


-- ── 4. SUMMARY COUNT ACROSS ALL THREE TABLES ──
-- Run this for a quick overview before deciding what to delete
--- no duplicates was found
SELECT 'customers' AS table_name,
       COUNT(*)    AS total_duplicate_rows
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM customers
    GROUP BY customer_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'sellers',
       COUNT(*)
FROM sellers
WHERE seller_id IN (
    SELECT seller_id FROM sellers
    GROUP BY seller_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'orders',
       COUNT(*)
FROM orders
WHERE order_id IN (
    SELECT order_id FROM orders
    GROUP BY order_id HAVING COUNT(*) > 1
);







