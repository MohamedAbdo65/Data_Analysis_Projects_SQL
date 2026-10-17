--find total sales over order date AS YEARS
SELECT EXTRACT(YEAR FROM order_date) AS order_year , 
		SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year
ORDER BY total_sales DESC

SELECT EXTRACT(YAER FROM order_date) AS order_year , 
		SUM(sales_amount) AS total_sales , 
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(quantity) AS total_items
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year
ORDER BY order_year
-- find data over year and month 
SELECT	EXTRACT(YEAR FROM order_date) AS order_year,
		EXTRACT(MONTH FROM order_date) AS order_month , 
		SUM(sales_amount) AS total_sales , 
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(quantity) AS total_items
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year , order_month
ORDER BY order_year , order_month

-----Cumulative Analysis 
SELECT order_month , total_sales,
		SUM(total_sales) OVER(ORDER BY order_month) AS running_total_sales 
FROM(
	SELECT DATE_TRUNC('month',order_date)::DATE AS order_month , --DATE_TRUNC('month',order_date)::DATE  EXTRACT(MONTH FROM order_date)
	 		SUM(sales_amount) AS total_sales 
	FROM gold.fact_sales 
	WHERE  order_date IS NOT NULL
	GROUP BY order_month
	ORDER BY order_month)t

SELECT order_month , total_sales,
		SUM(total_sales) OVER(PARTITION BY order_month ORDER BY order_month) AS running_total_sales 
FROM(
	SELECT DATE_TRUNC('month',order_date)::DATE AS order_month , --DATE_TRUNC('month',order_date)::DATE  EXTRACT(MONTH FROM order_date)
	 		SUM(sales_amount) AS total_sales 
	FROM gold.fact_sales 
	WHERE  order_date IS NOT NULL
	GROUP BY order_month
	ORDER BY order_month)t


SELECT order_year , total_sales,
		SUM(total_sales) OVER(ORDER BY order_year) AS running_total_sales ,
		ROUND(AVG(avg_price) OVER(ORDER BY order_year) ,2)AS moving_avg_price 
FROM(
	SELECT DATE_TRUNC('year',order_date)::DATE AS order_year , --DATE_TRUNC('month',order_date)::DATE  EXTRACT(MONTH FROM order_date)
	 		SUM(sales_amount) AS total_sales ,
			AVG(price) AS avg_price
	FROM gold.fact_sales 
	WHERE  order_date IS NOT NULL
	GROUP BY order_year
	ORDER BY order_year)t



--YOY Sales Analysis
WITH yearly_product_sales AS(
	SELECT EXTRACT(year FROM f.order_date) AS order_year,
		   p.product_name ,
		   SUM(f.sales_amount) AS current_sales
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY order_year,p.product_name )
SELECT order_year ,
	   product_name,
	   current_sales,
	   ROUND(AVG(current_sales)OVER(PARTITION BY product_name),1) AS avg_sales,
	   current_sales -  ROUND(AVG(current_sales)OVER(PARTITION BY product_name),1) AS diff_avg,
	   CASE WHEN current_sales -  ROUND(AVG(current_sales)OVER(PARTITION BY product_name),1) > 0 THEN 'Above AVG'
	   		WHEN current_sales -  ROUND(AVG(current_sales)OVER(PARTITION BY product_name),1) < 0 THEN 'Below AVG'
			ELSE 'AVG'
		END AS avg_change,
		LAG(current_sales)OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
		current_sales - LAG(current_sales)OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py_year,
		CASE WHEN current_sales -  LAG(current_sales)OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	   		WHEN current_sales -  LAG(current_sales)OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
			ELSE 'No change'
		END AS sales_change
FROM yearly_product_sales
ORDER BY product_name , order_year


--calculate the propotion of each category over all sales 
WITH category_sales AS (
		SELECT category ,
			   SUM(sales_amount) AS total_sales
		FROM gold.fact_sales AS f
		LEFT JOIN gold.dim_products AS p
		ON f.product_key = p.product_key
		GROUP BY category)
SELECT category ,
	   total_sales,
	   SUM(total_sales)OVER() AS overall_sales,
	   CONCAT(ROUND((total_sales /SUM(total_sales)OVER()) *100 , 2) , '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC




--------------------------------------------------------------------------
WITH product_segments AS (	
	SELECT product_key,
			product_name,
			cost ,
			CASE WHEN cost < 100 THEN 'Below 100'
				 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
				 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
				 WHEN cost BETWEEN 1000 AND 2000 THEN '1000-2000'
				 ELSE 'Above 2000'
			 END AS cost_range	
	FROM  gold.dim_products)
SELECT cost_range ,
		COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range 
ORDER BY total_products DESC

-----------------------------------------------------------------------------------------------------------------
WITH customer_spending AS (
	SELECT c.customer_key,
			SUM(f.sales_amount) AS total_spending,
			MIN(f.order_date) AS first_order,
			MAX(f.order_date) AS last_order,
			 (EXTRACT(YEAR  FROM MAX(f.order_date)) - EXTRACT(YEAR  FROM MIN(f.order_date))) * 12
	  + (EXTRACT(MONTH FROM MAX(f.order_date)) - EXTRACT(MONTH FROM MIN(f.order_date)))  AS lifespan
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_customers AS c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key)
SELECT customer_segment	,
		COUNT(customer_key) AS total_customers
FROM(
	SELECT 	customer_key,
			total_spending,
			lifespan,
			CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
				 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
				 ELSE 'New'
			END AS customer_segment
	FROM customer_spending)t
GROUP BY customer_segment
ORDER BY total_customers DESC