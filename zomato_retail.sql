-- Check whether restaurant.cuisine and menu.cuisine hold the same values
-- (investigating possible data redundancy between the two tables)
SELECT r.id, r.cuisine AS restaurant_cuisine, m.cuisine AS menu_cuisine
FROM zomato_retail.restaurant r
JOIN zomato_retail.menu m ON r.id = m.r_id
LIMIT 20;

-- Which cuisine generates the most total order revenue?
SELECT r.cuisine, SUM(o.sales_amount) AS TotalRevenue
FROM zomato_retail.restaurant r 
JOIN zomato_retail.orders o ON r.id = o.r_id
GROUP BY r.cuisine
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Which city generates the most total order revenue?
SELECT r.city, SUM(o.sales_amount) AS TotalRevenue
FROM zomato_retail.restaurant r 
JOIN zomato_retail.orders o ON r.id = o.r_id
GROUP BY r.city
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Top 20 spenders by total order value (initial, unfiltered pass)
SELECT u.user_id, u.name, SUM(o.sales_amount) AS TopSpenders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.name
ORDER BY TopSpenders DESC
LIMIT 20;

-- Check whether top spenders' totals come from repeat orders on different
-- days, versus a small number of transactions
SELECT u.name, COUNT(DISTINCT(order_date)) AS NumOrders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
WHERE u.user_id IN (
	SELECT u.user_id
    FROM zomato_retail.users u
    JOIN zomato_retail.orders o ON u.user_id = o.user_id 
    GROUP BY u.user_id
    ORDER BY SUM(o.sales_amount) DESC 
    LIMIT 10
)
GROUP BY u.name
ORDER BY NumOrders DESC
LIMIT 10;

-- Confirm whether low order counts reflect few orders overall, or several
-- orders landing on the same day (COUNT(*) vs COUNT(DISTINCT order_date))
SELECT u.name, COUNT(*) AS NumOrders, COUNT(DISTINCT o.order_date) AS NumDistinctDates
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
WHERE u.user_id IN (
    SELECT u.user_id
    FROM zomato_retail.users u
    JOIN zomato_retail.orders o ON u.user_id = o.user_id 
    GROUP BY u.user_id
    ORDER BY SUM(o.sales_amount) DESC 
    LIMIT 10
)
GROUP BY u.name
ORDER BY NumOrders DESC;

-- Investigate top spender (Amanda Ballard) directly: inspect her individual
-- orders to look for an outlier transaction
SELECT o.order_date, o.sales_qty, o.sales_amount, o.currency
FROM zomato_retail.orders o
WHERE o.user_id = '70591'
ORDER BY o.sales_amount DESC;

-- Check the overall distribution of sales_qty across all orders, to find a
-- data-driven outlier threshold instead of guessing a cutoff
SELECT 
    MIN(sales_qty) AS min_qty,
    MAX(sales_qty) AS max_qty,
    AVG(sales_qty) AS avg_qty,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales_qty) AS median_qty,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sales_qty) AS p95_qty,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY sales_qty) AS p99_qty
FROM zomato_retail.orders;

-- Top spenders re-ranked, excluding orders above the 99th percentile
-- (sales_qty >= 215) to remove bulk/corporate transactions
SELECT u.user_id, u.name, SUM(o.sales_amount) AS TopSpenders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
WHERE o.sales_qty < 215
GROUP BY u.user_id, u.name
ORDER BY TopSpenders DESC
LIMIT 10;

-- Verify these new, genuine top spenders show real repeat-purchase
-- behavior (order count matching distinct order dates), same bulk-order
-- filter applied consistently in both the subquery and outer query
SELECT u.user_id, u.name, COUNT(*) AS NumOrders, COUNT(DISTINCT o.order_date) AS NumDistinctDates
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
WHERE u.user_id IN (
	SELECT u.user_id
    FROM zomato_retail.users u
    JOIN zomato_retail.orders o ON u.user_id = o.user_id 
	WHERE o.sales_qty < 215
    GROUP BY u.user_id
    ORDER BY SUM(o.sales_amount) DESC 
    LIMIT 10
) AND o.sales_qty < 215
GROUP BY u.user_id, u.name
ORDER BY NumOrders DESC
LIMIT 10;

-- Does average spending differ by occupation?
SELECT u."Occupation", 
    AVG(o.sales_amount) AS AvgSpend,
    SUM(o.sales_amount) AS TotalSpend,
    COUNT(*) AS NumOrders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
GROUP BY u."Occupation"
ORDER BY AvgSpend DESC;

-- Check number of unique users per occupation, to compare against the
-- order-count ranking above and test whether revenue differences are a
-- population-size effect rather than a behavioral difference
SELECT u."Occupation", COUNT(DISTINCT user_id) AS NumUsers
FROM zomato_retail.users u
GROUP BY u."Occupation"
ORDER BY NumUsers DESC;

-- Check 1: orders referencing a user_id that doesn't exist in users
SELECT o.user_id, o.order_date, o.sales_amount
FROM zomato_retail.orders o
LEFT JOIN zomato_retail.users u ON o.user_id = u.user_id
WHERE u.user_id IS NULL;

-- Check 2: orders referencing a r_id that doesn't exist in restaurant
SELECT o.r_id, o.order_date, o.sales_amount
FROM zomato_retail.orders o
LEFT JOIN zomato_retail.restaurant r ON o.r_id = r.id
WHERE r.id IS NULL;

-- Quantify the orphaned orders: how many, and how much revenue they
-- represent
SELECT COUNT(*) AS OrphanedOrders, SUM(o.sales_amount) AS OrphanedRevenue
FROM zomato_retail.orders o
LEFT JOIN zomato_retail.restaurant r ON o.r_id = r.id
WHERE r.id IS NULL;

-- Confirm the orphaned rows are explained by r_id being NULL in the source
-- data, not a genuine mismatch against restaurant.id
SELECT COUNT(*) AS NullRidInOrders
FROM zomato_retail.orders
WHERE r_id IS NULL;
