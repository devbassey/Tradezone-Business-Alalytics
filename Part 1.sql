SELECT * FROM customers;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM payments;
SELECT * FROM products;
SELECT * FROM reviews;
SELECT * FROM sellers;



SELECT COUNT(*) FROM customers; --> shows there are originally 865 rows in this table

--> PART A: DATA CLEANING AND PREPARATION
--Question 1: Identifying null/missing values

-- checking for null values in the customers table
SELECT *
FROM customers
WHERE NOT (
    customer_id IS NOT NULL
    AND first_name IS NOT NULL
    AND last_name IS NOT NULL
    AND email IS NOT NULL
    AND city IS NOT NULL
    AND state IS NOT NULL
    AND signup_date IS NOT NULL
    AND account_status IS NOT NULL
); --> Shows that email has null values. Even though the email is not useful for the analysis, deleting it would cause data redundancy.

SELECT COUNT(*)
FROM customers
where email is null; --> There are 16 rows with null values in the customers table.

-- checking for null values in the order_items table
SELECT *
FROM orders
WHERE NOT (
    order_id IS NOT NULL
    AND customer_id IS NOT NULL
    AND seller_id IS NOT NULL
    AND order_date IS NOT NULL
    AND delivery_date IS NOT NULL
    AND order_status IS NOT NULL
	AND total_amount IS NOT NULL
); --> there are null values in the delivery_date

--HANDLING THE MISSING VALUES
-- Some customer emails are NULL. We set them to a placeholder (not critical for analysis).
UPDATE customers 
SET email = 'no_email@tradezone.com' 
WHERE email IS NULL;


SELECT email, COUNT(*) AS duplicate_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;



