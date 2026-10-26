-- Check whether the menu cuisine and the restaurant cusine match
SELECT r.id, r.cuisine AS restaurant_cuisine, m.cuisine AS menu_cuisine
FROM zomato_retail.restaurant r
JOIN zomato_retail.menu m ON r.id = m.r_id
LIMIT 20;

---Revenue By cuisine
SELECT  r.cuisine ,SUM(o.sales_amount) AS TotalRevenue
FROM zomato_retail.restaurant r 
JOIN zomato_retail.orders o ON r.id = o.r_id
GROUP BY r.cuisine
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Revenue By city
SELECT r.city ,SUM(o.sales_amount) AS TotalRevenue
FROM zomato_retail.restaurant r 
JOIN zomato_retail.orders o ON r.id = o.r_id
GROUP BY r.city
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Top Spenders
SELECT u.user_id,u.name,SUM(o.sales_amount) AS TopSpenders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON  u.user_id = o.user_id
GROUP BY u.user_id,u.name
ORDER BY TopSpenders DESC
LIMIT 20;

-- Check whether these are bulk orders or distinct seperate orders
SELECT u.name,COUNT(DISTINCT(order_date)) AS NumOrders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON  u.user_id = o.user_id
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

-- check whether the transactions happen multiple times a Day or one time on different days
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

-- Top Spender Amanda Ballard
SELECT o.order_date, o.sales_qty, o.sales_amount, o.currency
FROM zomato_retail.orders o
WHERE o.user_id = '70591'
ORDER BY o.sales_amount DESC;

-- data distibution
SELECT 
    MIN(sales_qty) AS min_qty,
    MAX(sales_qty) AS max_qty,
    AVG(sales_qty) AS avg_qty,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales_qty) AS median_qty,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sales_qty) AS p95_qty,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY sales_qty) AS p99_qty
FROM zomato_retail.orders;

-- Top spenders removing the largest ordes quantity
SELECT u.user_id,u.name,SUM(o.sales_amount) AS TopSpenders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON  u.user_id = o.user_id
WHERE o.sales_qty <215
GROUP BY u.user_id,u.name
ORDER BY TopSpenders DESC
LIMIT 10;

-- SELECT u.name,COUNT(DISTINCT(order_date)) AS NumOrders
SELECT u.user_id,u.name, COUNT(*) AS NumOrders, COUNT(DISTINCT o.order_date) AS NumDistinctDates
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON  u.user_id = o.user_id
WHERE u.user_id IN (
	SELECT u.user_id
    FROM zomato_retail.users u
    JOIN zomato_retail.orders o ON u.user_id = o.user_id 
	WHERE o.sales_qty <215
    GROUP BY u.user_id
    ORDER BY SUM(o.sales_amount) DESC 
    LIMIT 10
) AND  o.sales_qty <215
GROUP BY u.user_id, u.name
ORDER BY NumOrders DESC
LIMIT 10;

 -- Revenue by occupation
SELECT u."Occupation", 
    AVG(o.sales_amount) AS AvgSpend,
    SUM(o.sales_amount) AS TotalSpend,
    COUNT(*) AS NumOrders
FROM zomato_retail.users u
JOIN zomato_retail.orders o ON u.user_id = o.user_id
GROUP BY u."Occupation"
ORDER BY AvgSpend DESC;

-- Distinct users per occupation
SELECT u."Occupation",COUNT(DISTINCT user_id) AS NumUsers
FROM zomato_retail.users u
GROUP BY  u."Occupation"
ORDER BY NumUsers DESC;

-- Check 1: orders referencing a user_id that doesn’t exist in users
SELECT o.user_id, o.order_date, o.sales_amount
FROM zomato_retail.orders o
LEFT JOIN zomato_retail.users u ON o.user_id = u.user_id
WHERE u.user_id IS NULL;

-- Check 2: same idea, for restaurant references
SELECT o.r_id, o.order_date, o.sales_amount
FROM zomato_retail.orders o
LEFT JOIN zomato_retail.restaurant r ON o.r_id = r.id
WHERE r.id IS NULL;

SELECT COUNT(*) AS OrphanedOrders, SUM(o.sales_amount) AS OrphanedRevenue
FROM zomato_retail.orders o
LEFT JOIN zomato_retail.restaurant r ON o.r_id = r.id
WHERE r.id IS NULL;

SELECT COUNT(*) AS NullRidInOrders
FROM zomato_retail.orders
WHERE r_id IS NULL;


-- Distinct dates
SELECT order_date, COUNT(*) AS NumOrdersOnThisDate
FROM zomato_retail.orders
GROUP BY order_date
ORDER BY NumOrdersOnThisDate DESC;