CREATE VIEW gold.report_products AS
WITH base_query AS(
	SELECT 
			f.order_number,
			f.customer_key,
			f.order_date,
			f.sales_amount,
			f.quantity,
			p.product_key,
			p.product_name,
			p.category,
			p.subcategory,
			p.maintenance,
			p.cost
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL)

,product_aggregation AS(

SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		maintenance,
		cost,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT customer_key) AS total_customers,
		MAX(order_date) AS last_order_date,
		(EXTRACT(YEAR  FROM MAX(order_date)) - EXTRACT(YEAR  FROM MIN(order_date))) * 12
	  + (EXTRACT(MONTH FROM MAX(order_date)) - EXTRACT(MONTH FROM MIN(order_date)))  AS lifespan
FROM base_query 
GROUP BY
		product_key,
		product_name,
		category,
		subcategory,
		maintenance,
		cost
	)

SELECT  product_key,
		product_name,
		category,
		subcategory,
		maintenance,
		cost,
		total_orders,
		total_sales,
		total_quantity,
		total_customers,
		last_order_date,
		CASE WHEN total_orders = 0 THEN 0 
			 ELSE total_sales/total_orders 
		END AS avg_order_revenue,
		CASE WHEN total_orders >50000 THEN 'High_Performer'
			 WHEN total_orders >10000 THEN 'Mid_Performer'
			 ELSE 'Low_Performer'
		END AS product_segment,
		lifespan
	FROM product_aggregation