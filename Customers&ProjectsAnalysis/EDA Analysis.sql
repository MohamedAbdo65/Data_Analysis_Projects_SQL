SELECT * FROM information_schema.tables
where table_schema NOT IN('pg_catalog' , 'information_schema')
--show columns in particular schema
SELECT * FROM information_schema.columns
where table_schema NOT IN('pg_catalog' , 'information_schema')
--show distinct country values
SELECT DISTINCT country FROM gold.dim_customers
--granularity between category and subcategory and prodact
SELECT DISTINCT category , subcategory,product_name FROM gold.dim_products
order by 1,2,3
--first order date and last order date and calculate range monthes between
SELECT MIN(order_date) AS first_oder_date , MAX(order_date) AS last_order_date,
		 (MAX(order_date)- MIN(order_date))/30 AS order_range_months
FROM gold.fact_sales
-- min birthdate and max and calculate age for each one
SELECT  MIN(birth_date) AS oldest_customer , MAX(birth_date) AS youngest_customer,
		AGE(CURRENT_DATE , MIN(birth_date)) AS oldest_customer_age ,
		AGE(CURRENT_DATE , MAX(birth_date)) AS youngest_customer_age
FROM gold.dim_customers
--sum total sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

--sum total items
SELECT SUM(quantity) AS total_items FROM gold.fact_sales

--calculate average price
SELECT AVG(price) AS avg_price FROM gold.fact_sales
--count total orders
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales
--count total products
SELECT COUNT(product_key) AS total_products FROM gold.dim_products
SELECT COUNT(product_name) AS total_products FROM gold.dim_products

--count total customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales


--make a conclusion table form all measures
SELECT 'Total Sales' AS measure_name ,SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Total_Quantity' ,SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price',AVG(price)FROM gold.fact_sales
UNION ALL
SELECT  'Total Orders',COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products',COUNT(product_key) FROM gold.dim_products
UNION ALL
SELECT 'Total Customer',COUNT(customer_key) FROM gold.dim_customers

--total_customers by country
SELECT country , COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

--find total_customers by gender
SELECT gender , COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC
--find total_products by category
SELECT category , COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC
--find average cost in each category
SELECT category ,ROUND(AVG(cost),2) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC

--find total revenue for each category
SELECT p.category ,SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC


--find total revenue by customer also  top 10 spenders
SELECT c.customer_key , c.first_name , c.last_name ,
		SUM(f.sales_amount) AS total_reveneue
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_customers AS c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key , c.first_name , c.last_name 
ORDER BY total_reveneue DESC
LIMIT 10

--find the distribution of sold items across countries
SELECT c.country ,
		SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_customers AS c 
ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC

--find top 5 products generete the hightest revenue
SELECT  p.product_name,
		SUM(f.sales_amount) AS total_reveneue
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_reveneue DESC
LIMIT 5
--find top 5 products generete the LOWEST revenue
SELECT  p.product_name,
		SUM(f.sales_amount) AS total_reveneue
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_reveneue 
LIMIT 5
 --using window_function RANK() , ROW_NUMBER()
SELECT*
FROM(
	SELECT  p.product_name,
			SUM(f.sales_amount) AS total_reveneue,
			RANK() OVER(ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales AS f 
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	GROUP BY p.product_name)t
WHERE rank_products <=5

--FIND TOP 10 customers make orders
SELECT c.customer_key , c.first_name , c.last_name ,
		COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_customers AS c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key , c.first_name , c.last_name 
ORDER BY total_orders DESC
LIMIT 10

-- find lowest 3 customers make orders 
SELECT c.customer_key , c.first_name , c.last_name ,
		COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f 
LEFT JOIN gold.dim_customers AS c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key , c.first_name , c.last_name 
ORDER BY total_orders 
LIMIT 3