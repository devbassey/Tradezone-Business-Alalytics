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
-- Identify Duplicate Emails in Customers

-- Step 1: See which emails appear more than once
SELECT
    email,
    COUNT(*)        AS occurrence_count
FROM customers
WHERE email IS NOT NULL
  AND TRIM(email) != ''
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;


-- Step 2: See the full records behind those duplicate emails
-- This shows you WHO shares an email so you can decide what to do
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    signup_date,
    account_status
FROM customers
WHERE email IN (
    SELECT email
    FROM customers
    WHERE email IS NOT NULL
    AND TRIM(email) != ''
    GROUP BY email
    HAVING COUNT(*) > 1
)
ORDER BY email, signup_date;


-- Step 3: Flag them (do not delete yet)
ALTER TABLE customers ADD COLUMN IF NOT EXISTS flag_duplicate_email BOOLEAN DEFAULT FALSE;

UPDATE customers
SET flag_duplicate_email = TRUE
WHERE email IN (
    SELECT email
    FROM customers
    WHERE email IS NOT NULL
    AND TRIM(email) != ''
    GROUP BY email
    HAVING COUNT(*) > 1
);

-- Step 4: Confirm how many rows were flagged
SELECT COUNT(*) AS customers_with_duplicate_email
FROM customers
WHERE flag_duplicate_email = TRUE; -->30 rows were flagged as duplicate rows


-- ─────────────────────────────────────────────
-- OPTION A: Keep the earliest account, flag the rest
-- Use this if the duplicates look like the same person
-- who registered twice
-- ─────────────────────────────────────────────

ALTER TABLE customers ADD COLUMN IF NOT EXISTS flag_duplicate_keep BOOLEAN DEFAULT FALSE;

-- Mark the OLDEST account per email as the one to keep
UPDATE customers
SET flag_duplicate_keep = TRUE
WHERE ctid IN (
    SELECT DISTINCT ON (email) ctid
    FROM customers
    WHERE email IS NOT NULL
      AND TRIM(email) != ''
    ORDER BY email, signup_date ASC  -- earliest signup = keeper
);

-- Preview what will be kept vs removed
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    signup_date,
    CASE WHEN flag_duplicate_keep = TRUE THEN 'KEEP' ELSE 'REMOVE' END AS decision
FROM customers
WHERE flag_duplicate_email = TRUE
ORDER BY email, signup_date;


-- ─────────────────────────────────────────────
-- STEP 1: SEE WHICH DUPLICATE CUSTOMERS
--         ARE STILL REFERENCED IN ORDERS
-- ─────────────────────────────────────────────

SELECT
    c.customer_id,
    COUNT(*) OVER (PARTITION BY c.customer_id)  AS copies_in_customers,
    o.order_id,
    c.ctid
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IN (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)
ORDER BY c.customer_id, c.ctid;



-- STEP A: Delete duplicates that have NO orders

DELETE FROM customers
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM customers
    GROUP BY customer_id
)
AND customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
);

-- STEP B: For duplicates that DO have orders,
--         keep the MIN ctid copy, delete the rest
--         PostgreSQL allows this because we are keeping
--         the row that the orders point to

DELETE FROM customers
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM customers
    GROUP BY customer_id
)
AND customer_id IN (
    SELECT DISTINCT customer_id FROM orders
);


-- STEP 3: CONFIRM IT WORKED
-- ─────────────────────────────────────────────

SELECT customer_id, COUNT(*) AS copies
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1; -- If this returns zero rows, you are clean.

-- Delete Duplicate Rows from customers
DELETE FROM customers
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM customers
    GROUP BY customer_id
);


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


-- QUESTION 3: STANDARDISE CITY NAMES
-- ─────────────────────────────────────────────

-- First, see all the messy variations currently in the data
SELECT DISTINCT city FROM customers ORDER BY city;
SELECT DISTINCT city FROM sellers   ORDER BY city;

-- Fix customers city names
-- TRIM removes leading/trailing spaces
-- INITCAP makes First Letter Uppercase, rest lowercase
UPDATE customers
SET city = INITCAP(TRIM(city));

-- Fix the Port Harcourt and Lago S variations specifically
-- (Port-Harcourt, PortHarcourt, port harcourt all become Port Harcourt)
--> Customers Table
UPDATE customers
SET city = 'Port Harcourt'
WHERE LOWER(TRIM(city)) IN (
    'port-harcourt',
    'portharcourt',
    'port  harcourt'   --> double space variant
);

-- (Fix Lago S to Lagos)
UPDATE customers 
SET city = 'Lagos' 
WHERE TRIM(city) ILIKE 'Lago %s';

--> Sellers Table
UPDATE sellers
SET city = INITCAP(TRIM(city));

UPDATE sellers
SET city = 'Port Harcourt'
WHERE LOWER(TRIM(city)) IN (
    'port-harcourt',
    'portharcourt',
    'port  harcourt'   --> double space variant
);

-- (Fix Lago S to Lagos)
UPDATE sellers 
SET city = 'Lagos' 
WHERE TRIM(city) ILIKE 'Lago %s';

-- Verify — all cities in customers and sellers table now clean
SELECT DISTINCT city FROM customers ORDER BY city;
SELECT DISTINCT city FROM sellers   ORDER BY city;



-- SECTION 2: STANDARDISE DATE COLUMNS
-- ─────────────────────────────────────────────

-- PostgreSQL stores DATE columns as YYYY-MM-DD internally already.
-- The issue is when dates were loaded as VARCHAR/TEXT instead of DATE.
-- Run this check first to see what data types your columns actually are:

SELECT
    column_name,
    data_type,
    table_name
FROM information_schema.columns
WHERE table_name IN ('customers', 'sellers', 'orders', 'payments', 'reviews')
  AND column_name LIKE '%date%'
ORDER BY table_name, column_name; --> Note: All date columns confirmed as DATE type. Format is YYYY-MM-DD by default.


select 
	payment_date 
from 
	payments; --> No change needed for payments.payment_date as it is TIMESTAMP that stores both date and time


-- SECTION 3: NORMALISE PRODUCT CATEGORY NAMES TO TITLE CASE
-- ─────────────────────────────────────────────


