
-- SALES TRENDS

-- What were the total sales?
SELECT ROUND(SUM(sales)) AS total_sales
FROM orders;

-- What were the total sales per year?
SELECT YEAR(order_date) AS Year, ROUND(SUM(sales)) AS total_sales
FROM orders
GROUP BY YEAR(order_date)
ORDER BY 1;

-- What were the total orders?
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- What were the total orders per year?
SELECT YEAR(order_date) AS Year, COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY YEAR(order_date)
ORDER BY 1;

-- What were the total sales per month and year?
SELECT YEAR(order_date) AS year, MONTH(order_date) AS month, ROUND(SUM(sales)) AS total_sales
FROM orders
GROUP BY 1,2
ORDER BY 1;

-- What were the average order values per year?
SELECT 
    YEAR(order_date) AS year,
    SUM(sales) / COUNT(DISTINCT order_id) AS aov
FROM orders
GROUP BY YEAR(order_date)
ORDER BY 1;

-- What were the number of orders per month?
SELECT
	MONTH(order_date) AS month,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY 1
ORDER BY 2;

-- What were the growth rates for total sales, total orders, and aov per year?

WITH yearly_metrics AS (
    SELECT 
        YEAR(order_date) AS year,
        ROUND(SUM(sales)) AS total_sales,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(sales) / COUNT(DISTINCT order_id) AS aov
    FROM 
        orders
    GROUP BY 
        YEAR(order_date)
),
sales_growth AS (
    SELECT 
        a.year,
        a.total_sales,
        a.total_orders,
        a.aov,
        CASE 
            WHEN b.total_sales IS NOT NULL THEN 
                ROUND(((a.total_sales - b.total_sales) / b.total_sales) * 100,2)
            ELSE 
                NULL
        END AS sales_growth_rate,
        CASE
			WHEN b.total_orders IS NOT NULL THEN
				ROUND(((a.total_orders - b.total_orders) / b.total_orders) * 100,2)
			ELSE
				NULL
		END AS order_growth_rate,
        CASE
			WHEN b.aov IS NOT NULL THEN
				ROUND(((a.aov - b.aov) / b.aov) * 100,2)
			ELSE
				NULL
		END AS aov_growth_rate
    FROM 
        yearly_metrics a
    LEFT JOIN 
        yearly_metrics b
    ON 
        a.year = b.year + 1
)
SELECT 
    year, 
    total_sales,
    sales_growth_rate,
    total_orders,
    order_growth_rate,
    aov,
    aov_growth_rate
FROM 
    sales_growth
ORDER BY 
    year;

-- What were the states with the most orders?
SELECT
	state,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
JOIN location ON orders.postal_code = location.postal_code
GROUP BY state
ORDER BY 3 DESC;


-- PRODUCT PERFORMANCE

-- What were the categories with most sales?
SELECT
	category,
    subcategory,
    SUM(sales) AS total_sales
FROM orders
JOIN products ON orders.product_id = products.product_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- What were the categories with most orders?
SELECT
	category,
    subcategory,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
JOIN products ON orders.product_id = products.product_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- What were the categories with most profit?
SELECT
	category,
    subcategory,
    SUM(profit) AS total_profit
FROM orders
JOIN products ON orders.product_id = products.product_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- What were the top products in total sales?
SELECT
	product_name AS product,
    SUM(sales) AS total_sales
FROM orders
JOIN products on orders.product_id = products.product_id
GROUP BY product_name
ORDER BY 2 DESC;

-- What were the top products in total orders?
SELECT
	product_name AS product,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
JOIN products on orders.product_id = products.product_id
GROUP BY product_name
ORDER BY 2 DESC;

-- What were the top products in total profit?
SELECT
	product_name AS product,
    SUM(profit) AS total_profit
FROM orders
JOIN products on orders.product_id = products.product_id
GROUP BY product_name
ORDER BY 2 DESC;

-- What were the top 3 products in sales of last year and this year?
WITH yearly_product_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        product_name AS product,
        SUM(sales) AS total_sales
    FROM orders
    JOIN products ON orders.product_id = products.product_id
    WHERE YEAR(order_date) IN ('2022','2023') 
    GROUP BY 
        YEAR(order_date), product
),
ranked_products AS (
    SELECT 
        year,
        product,
        total_sales,
        RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS ranking
    FROM yearly_product_sales
)
SELECT 
    year,
    product,
    total_sales
FROM ranked_products
WHERE ranking <= 3
ORDER BY 
    year, ranking;
    

-- What were the top 3 products in profit of last year and this year?
WITH yearly_product_profit AS (
    SELECT 
        YEAR(order_date) AS year,
        product_name AS product,
        SUM(profit) AS total_profit
    FROM orders
    JOIN products ON orders.product_id = products.product_id
    WHERE YEAR(order_date) IN ('2022','2023') 
    GROUP BY 
        YEAR(order_date), product
),
ranked_products AS (
    SELECT 
        year,
        product,
        total_profit,
        RANK() OVER (PARTITION BY year ORDER BY total_profit DESC) AS ranking
    FROM yearly_product_profit
)
SELECT 
    year,
    product,
    total_profit
FROM ranked_products
WHERE ranking <= 3
ORDER BY 
    year, ranking;
    
-- What were the categories with the most sales in 2023?
SELECT
	category,
    subcategory,
    SUM(sales) AS total_sales
FROM orders
JOIN products ON orders.product_id = products.product_id
WHERE YEAR(order_date) = '2023'
GROUP BY 1,2
ORDER BY 3 DESC;

-- How many orders containing Phones were made per year?
SELECT 
	YEAR(order_date) AS year,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
JOIN products ON orders.product_id = products.product_id
WHERE subcategory = 'Phones'
GROUP BY 1
ORDER BY 1;

-- What were the products with the most sales in 2022 and 2023 in the Phones subcategory?
SELECT
	product_name AS product,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
JOIN products ON orders.product_id = products.product_id
WHERE subcategory = 'Phones' AND YEAR(order_date) IN ('2022','2023')
GROUP BY 1
ORDER BY 2 DESC;


-- CUSTOMER TRENDS

-- What were the number of customers per year
SELECT
	YEAR(order_date) AS YEAR,
    COUNT(DISTINCT orders.customer_id) AS customers
FROM orders
JOIN customers ON orders.customer_id = customers.customer_id
GROUP BY 1
ORDER BY 1;

-- What were the number of new and repeating customers per year?
WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(YEAR(order_date)) AS first_purchase_year
    FROM orders
    GROUP BY 1
),
yearly_customers AS (
    SELECT 
        YEAR(order_date) AS year,
        customer_id
    FROM orders
    GROUP BY 1,2
)
SELECT 
    yc.year,
    COUNT(CASE WHEN yc.year = fp.first_purchase_year THEN 1 END) AS new_customers,
    COUNT(CASE WHEN yc.year > fp.first_purchase_year THEN 1 END) AS repeated_customers
FROM yearly_customers yc
LEFT JOIN first_purchase fp ON yc.customer_id = fp.customer_id
GROUP BY yc.year
ORDER BY yc.year;

-- What  percentage of customers made more than one order per year?
WITH unique_orders AS (
    SELECT 
        customer_id,
        YEAR(order_date) AS year,
        order_id
    FROM 
        orders
    GROUP BY 
        customer_id, YEAR(order_date), order_id
),
customer_orders_per_year AS (
    SELECT 
        year,
        customer_id,
        COUNT(order_id) AS order_count
    FROM 
        unique_orders
    GROUP BY 
        year, customer_id
),
customer_summary AS (
    SELECT 
        year,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(CASE WHEN order_count > 1 THEN 1 END) AS multi_order_customers
    FROM 
        customer_orders_per_year
    GROUP BY 
        year
)
SELECT 
    year,
    total_customers,
    multi_order_customers,
    (multi_order_customers * 1.0 / total_customers) * 100 AS multi_order_rate
FROM 
    customer_summary
ORDER BY 
    year;

-- Which 5 products had the highest growth rate in sales from 2022 to 2023?
WITH yearly_sales AS (
    SELECT 
        product_id,
        YEAR(order_date) AS year,
        SUM(sales) AS total_sales
    FROM 
        orders
    WHERE 
        YEAR(order_date) IN (2022, 2023) 
    GROUP BY 
        product_id, YEAR(order_date)
),
sales_comparison AS (
    SELECT 
        current.product_id,
        COALESCE(current.total_sales, 0) AS sales_2023,
        COALESCE(previous.total_sales, 0) AS sales_2022,
        CASE 
            WHEN COALESCE(previous.total_sales, 0) > 0 THEN 
                ((COALESCE(current.total_sales, 0) - COALESCE(previous.total_sales, 0)) / COALESCE(previous.total_sales, 0)) * 100
            ELSE 
                NULL 
        END AS growth_rate
    FROM 
        (SELECT * FROM yearly_sales WHERE year = 2023) current
    LEFT JOIN 
        (SELECT * FROM yearly_sales WHERE year = 2022) previous
    ON 
        current.product_id = previous.product_id
),
ranked_products AS (
    SELECT 
        product_id,
        sales_2023,
        sales_2022,
        growth_rate,
        RANK() OVER (ORDER BY growth_rate DESC) AS ranking
    FROM 
        sales_comparison
)
SELECT 
    product_id,
    sales_2023,
    sales_2022,
    growth_rate
FROM 
    ranked_products
WHERE 
    ranking <= 5
ORDER BY 
    ranking;


WITH yearly_orders AS (
    SELECT 
        product_id,
        YEAR(order_date) AS year,
        COUNT(order_id) AS total_orders
    FROM 
        orders
    WHERE 
        YEAR(order_date) IN (2022, 2023) 
    GROUP BY 
        product_id, YEAR(order_date)
),
sales_comparison AS (

    SELECT 
        current.product_id,
        COALESCE(current.total_orders, 0) AS orders_2023,
        COALESCE(previous.total_orders, 0) AS orders_2022,
        CASE 
            WHEN COALESCE(previous.total_orders, 0) > 0 THEN 
                ((COALESCE(current.total_orders, 0) - COALESCE(previous.total_orders, 0)) / COALESCE(previous.total_orders, 0)) * 100
            ELSE 
                NULL 
        END AS growth_rate
    FROM 
        (SELECT * FROM yearly_orders WHERE year = 2023) current
    LEFT JOIN 
        (SELECT * FROM yearly_orders WHERE year = 2022) previous
    ON 
        current.product_id = previous.product_id
),
ranked_products AS (
    SELECT 
        product_id,
        orders_2023,
        orders_2022,
        growth_rate,
        RANK() OVER (ORDER BY growth_rate DESC) AS ranking
    FROM 
        sales_comparison
)
SELECT 
    product_id,
    orders_2023,
    orders_2022,
    growth_rate
FROM 
    ranked_products
WHERE 
    ranking <= 5
ORDER BY 
    ranking;


SELECT
	subcategory,
    category,
    COUNT(order_id)
FROM orders
JOIN products ON orders.product_id = products.product_id
WHERE MONTH(order_date) = 8
GROUP BY 1,2
ORDER BY 3 DESC;

SELECT
	subcategory,
    product_name,
    SUM(sales),
    COUNT(order_id),
    orders.product_id
FROM orders
JOIN products ON orders.product_id = products.product_id
WHERE subcategory = 'Phones'
GROUP BY 1,2,5
ORDER BY 3 DESC;

SELECT
	product_name,
    subcategory,
    COUNT(order_id)
FROM orders
JOIN products ON orders.product_id = products.product_id
WHERE MONTH(order_date) = 9
GROUP BY 1,2
ORDER BY 3 DESC
    