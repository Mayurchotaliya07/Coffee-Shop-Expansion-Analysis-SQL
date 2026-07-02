-- Total coffee cunsumer if city has 0.25% drinks coffee

SELECT
		city_name,
        population * 0.25 AS total_coffe_consumer
FROM city;

-- total revenue generated from coffee sales across all cities in the last quarter of 2023

SELECT
		SUM(total) AS total_sales
FROM sales
WHERE QUARTER(sale_date) = 4 AND YEAR(sale_date) = 2023;

-- How many units of each coffee product have been sold?

SELECT
		p.product_name AS product_name,
        COUNT(s.product_id) AS total_unit_ordered
FROM products p 
LEFT JOIN sales s
ON p.product_id = s.product_id
GROUP BY p.product_name;

-- average sales amount per customer in each city?

WITH customer_sales AS
(
SELECT
		c.city_name AS city_name,
        cs.customer_id AS customer_id,
        SUM(s.total) AS total_revenue
FROM city c
INNER JOIN customers cs
ON c.city_id = cs.city_id
INNER JOIN sales s 
ON cs.customer_id = s.customer_id
GROUP BY c.city_name,cs.customer_id
)
SELECT
		city_name,
        AVG(total_revenue) AS average_revenue
FROM customer_sales
GROUP BY city_name;

-- list of cities along with their populations and estimated coffee consumers.


SELECT
		city_name,
        population,
        ROUND((population * 0.25)/1000000,2) AS coffee_consumer_in_millions,
        COUNT(DISTINCT s.customer_id) AS current_coffee_consumer
FROM city c
INNER JOIN customers cs 
ON c.city_id = cs.city_id
INNER JOIN sales s
ON cs.customer_id = s.customer_id
GROUP BY city_name,population
ORDER BY current_coffee_consumer DESC;

-- top 3 selling products in each city based on sales volume

WITH revenue AS
(
SELECT
		c.city_name AS city_name,
        p.product_name AS product_name,
        COUNT(s.product_id) AS total_orders
FROM city c
INNER JOIN customers cs 
ON c.city_id = cs.city_id
INNER JOIN sales s 
ON cs.customer_id = s.customer_id
INNER JOIN products p 
ON s.product_id = p.product_id
GROUP BY c.city_name , p.product_name
)
SELECT
		*
FROM (
SELECT
		*,
        DENSE_RANK() OVER(
        PARTITION BY city_name
        ORDER BY total_orders DESC
        ) AS ranks
FROM revenue)t
WHERE ranks <=3;

-- unique customers are there in each city who have purchased coffee products

SELECT
		c.city_name,
        COUNT(DISTINCT cs.customer_id) AS total_customers
FROM city c
INNER JOIN customers cs 
ON c.city_id = cs.city_id
INNER JOIN sales s 
ON cs.customer_id = s.customer_id
INNER JOIN products p 
ON s.product_id = p.product_id
WHERE p.product_id BETWEEN 1 AND 14
GROUP BY c.city_name;

-- each city and their average sale per customer and avg rent per customer

WITH avg_rent AS
(
SELECT
		city,
        ROUND((rent / total_customer),2) AS average_rent_per_customer
FROM (
SELECT
		c.city_name AS city,
        c.estimated_rent AS rent,
        COUNT(cs.customer_id) AS total_customer
FROM city c
INNER JOIN customers cs
ON c.city_id = cs.city_id
GROUP BY c.city_name,c.estimated_rent)y
)		
,avg_customer_sales AS
(
SELECT
		city,
		ROUND(AVG(total_revenue),2) AS average_customer_sale
FROM (
SELECT
		c.city_name AS city,
        cs.customer_id AS customer_id,
        SUM(s.total) AS total_revenue
FROM city c 
INNER JOIN customers cs
ON c.city_id = cs.city_id
INNER JOIN sales s
ON cs.customer_id = s.customer_id
GROUP BY c.city_name,cs.customer_id)t
GROUP BY city
)
SELECT
		ar.city,
        acs.average_customer_sale,
        ar.average_rent_per_customer
FROM avg_rent ar
INNER JOIN avg_customer_sales acs
ON ar.city = acs.city;

-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH month_sales AS
(
SELECT
		c.city_name AS city,
		MONTH(sale_date) AS month_no,
		YEAR(sale_date) AS year,
        SUM(total) AS month_sales
FROM sales s
INNER JOIN customers cs
ON s.customer_id = cs.customer_id
INNER JOIN city c
ON cs.city_id = c.city_id
GROUP BY month_no,year,c.city_name
)
SELECT
		*,
        ROUND(((month_sales - previous_month_sales)/previous_month_sales)*100,2) AS growth_percentage
FROM (
SELECT
		*,
        LAG(month_sales) OVER(
        PARTITION BY city
        ORDER BY year ASC,month_no ASC
        ) AS previous_month_sales
FROM month_sales)t;

-- top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT
		*
FROM (
SELECT
		*,
        DENSE_RANK() OVER(
        ORDER BY total_sales DESC
        ) AS ranks
FROM (
SELECT
		c.city_name AS city,
        SUM(s.total) AS total_sales,
        c.estimated_rent AS rent,
        COUNT( DISTINCT s.customer_id) AS total_customer,
        (c.population * 0.25)/1000000 AS estimate_coffee_consumer_in_millions
FROM city c
INNER JOIN customers cs
ON c.city_id = cs.city_id
INNER JOIN sales s 
ON cs.customer_id = s.customer_id
GROUP BY c.city_name,c.estimated_rent,c.population)t)y

-- Recommendation
-- City 1: Pune
--         1. High total sales
-- 		2. Avg rant per customer is very low
--          3. Avg sales per customer is also high

-- City 2: Chennai
-- 		1. High total sales
-- 		2. High coffe consumer 
--          3. Avg per customer sales is also high
--          4. Avg rent per customer is also low

--  City 3: Jaipur
--           1. High total sales
--           2. High total customers 
--           3.  Avg customer sales and Avg rent per customer ratio is very good
