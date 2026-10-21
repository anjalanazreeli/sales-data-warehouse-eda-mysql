/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

-- Drop and recreate the 'DataWarehouseAnalytics' database


-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;

USE DataWarehouseAnalytics;

-- Create Schemas

CREATE SCHEMA gold;


CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number varchar(50),
	first_name varchar(50),
	last_name varchar(50),
	country varchar(50),
	marital_status varchar(50),
	gender varchar(50),
	birthdate date,
	create_date date
);


CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number varchar(50) ,
	product_name varchar(50) ,
	category_id varchar(50) ,
	category varchar(50) ,
	subcategory varchar(50) ,
	maintenance varchar(50) ,
	cost int,
	product_line varchar(50),
	start_date date 
);


CREATE TABLE gold.fact_sales(
	order_number varchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);

TRUNCATE TABLE gold.dim_customers;


LOAD DATA LOCAL INFILE '/Users/mac/Desktop/dim_customers.csv'
INTO TABLE gold.dim_customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_key, customer_id, customer_number, first_name, last_name, country, marital_status, gender, birthdate, create_date);


TRUNCATE TABLE gold.dim_products;

LOAD DATA LOCAL INFILE '/Users/mac/Desktop/dim_products.csv'
INTO TABLE gold.dim_products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_key, product_id, product_number, product_name, category_id, category, subcategory, maintenance, cost, product_line, start_date);



TRUNCATE TABLE gold.fact_sales;


LOAD DATA LOCAL INFILE '/Users/mac/Desktop/fact_sales.csv'
INTO TABLE gold.fact_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_number, product_key, customer_key, order_date, shipping_date, due_date, sales_amount, quantity, price);


-- Explore All Objects in the Database

SELECT * FROM INFORMATION_SCHEMA.TABLES;




-- Explore All Columns in the Database

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';




-- Explore All Countries our customers come from.

SELECT DISTINCT country FROM gold.dim_customers;




-- Explore All Categories "The major Divisions"

SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3;




-- Find the date of the first and last order
-- How many years of sales are available

SELECT
    MIN(STR_TO_DATE(order_date, '%Y-%m-%d')) AS first_order_date,
    MAX(STR_TO_DATE(order_date, '%Y-%m-%d')) AS last_order_date,
    TIMESTAMPDIFF(
        YEAR,
        MIN(STR_TO_DATE(order_date, '%Y-%m-%d')),
        MAX(STR_TO_DATE(order_date, '%Y-%m-%d'))
    ) AS order_range_years
FROM gold.fact_sales
WHERE STR_TO_DATE(order_date, '%Y-%m-%d') IS NOT NULL;





-- Find the youngest and the oldest customer

SELECT 
MIN(birthdate) AS oldest_birthdate,
TIMESTAMPDIFF(YEAR, MIN(birthdate), CURDATE()) AS oldest_age,
MAX(birthdate) AS youngest_birthdate,
TIMESTAMPDIFF(YEAR, MAX(birthdate), CURDATE()) AS youngest_age
FROM gold.dim_customers
WHERE birthdate IS NOT NULL
	AND CAST(birthdate AS CHAR) NOT LIKE '0000-00-00%';
    
    
    
    
	

-- Find the total sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;



-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales;



-- Find the average selling price
SELECT AVG(price) AS avg_price FROM gold.fact_sales;



-- Find the Total number of Orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales;
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales;



-- Find the total number of products
SELECT COUNT(product_key) AS total_products FROM gold.dim_products;
SELECT COUNT(DISTINCT product_key) AS total_products FROM gold.dim_products;
SELECT COUNT(product_name) AS total_products FROM gold.dim_products;
SELECT COUNT(DISTINCT product_name) AS total_products FROM gold.dim_products;




-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;



-- Find the total number of customers that place order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;




-- Generate a Report that shows all key metrics of the business

SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) AS avg_price FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders', COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products', COUNT(product_name) AS total_products FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers', COUNT(customer_key) AS total_customers FROM gold.dim_customers;





-- Find total customers by countries
SELECT
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;



-- Find total customers by gender
SELECT
gender,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;



-- Find total products by category
SELECT
category,
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;



-- What is the average costs in each category?
SELECT
category,
AVG(cost) AS avg_costs
FROM gold.dim_products
GROUP BY category
ORDER BY avg_costs DESC;




-- What is the total revenue generated for each category?
SELECT 
p.category,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;




-- What is the total revenue generated by each customer?
SELECT 
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC;




-- What is the distribution of sold items across countries?
SELECT 
c.country,
SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;





-- Which 5 products generate the highest revenue?
SELECT 
p.product_name,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;




-- What are the 5 worst-performing products in terms of sales?
SELECT
p.product_name,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue 
LIMIT 5;




-- By Ranking the products using window functions
SELECT * 
FROM (
	SELECT
	p.product_name,
	SUM(f.sales_amount) total_revenue,
	ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.product_name) t
WHERE rank_products <= 5;



-- Find the Top-10 customers who have generated the highest revenue
SELECT 
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC LIMIT 10;




-- The 3 customers with the fewest orders placed
SELECT 
c.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_orders LIMIT 3;

