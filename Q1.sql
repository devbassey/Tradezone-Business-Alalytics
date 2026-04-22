-- Q1: CUSTOMER ACQUISITION & 30-DAY CONVERSION
-- Top 5 states by new customer sign-ups in 2024
-- + percentage who purchased within first 30 days


-- How many new customers signed up in 2024 per state?
SELECT
    state,
    COUNT(*) AS signups_2024
FROM customers
WHERE EXTRACT(YEAR FROM signup_date) = 2024
GROUP BY state
ORDER BY signups_2024 DESC;