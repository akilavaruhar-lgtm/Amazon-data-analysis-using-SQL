--Create Tables--

-- customers table
CREATE TABLE amazon_brazil.customers (
    customer_id VARCHAR(150) PRIMARY KEY,
    customer_unique_id VARCHAR(150),
    customer_zip_code_prefix INTEGER
);

-- orders table
CREATE TABLE amazon_brazil.orders (
    order_id VARCHAR(150) PRIMARY KEY,
    customer_id VARCHAR(150),
    order_status VARCHAR(150),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES amazon_brazil.customers(customer_id)
);


-- payments table
CREATE TABLE amazon_brazil.payments (
    order_id VARCHAR(150),
    payment_sequential INTEGER,
    payment_type VARCHAR(150),
    payment_installments INTEGER,
    payment_value INTEGER,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES amazon_brazil.orders(order_id)
);

-- seller table
CREATE TABLE amazon_brazil.seller (
    seller_id VARCHAR(150) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(150),
    seller_state VARCHAR(150)
);


-- product table
CREATE TABLE amazon_brazil.product (
    product_id VARCHAR(150) PRIMARY KEY,
    product_category_name VARCHAR(150),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- order_items table
CREATE TABLE amazon_brazil.order_items (
    order_id VARCHAR(150),
    order_item_id INTEGER,
    product_id VARCHAR(150),
    seller_id VARCHAR(150),
    shipping_limit_date TIMESTAMP,
    price INTEGER,
    freight_value INTEGER,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES amazon_brazil.orders(order_id),
    FOREIGN KEY (product_id) REFERENCES amazon_brazil.product(product_id),
    FOREIGN KEY (seller_id) REFERENCES amazon_brazil.seller(seller_id)
);


--Analysis 1 --
--Q1. Rounding Average Payment Values--
SELECT payment_type,ROUND(AVG(payment_value)) AS rounded_avg_payment FROM amazon_brazil.payments GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;
--Q2. Percentage of Total Orders by Payment Type--
SELECT payment_type,ROUND(COUNT(DISTINCT order_id) * 100.0 / (SELECT COUNT(DISTINCT order_id) FROM amazon_brazil.payments), 1) AS percentage_orders
FROM amazon_brazil.payments GROUP BY payment_type ORDER BY percentage_orders DESC;
--Q3. Find Products Priced Between 100 and 500 BRL & Smart in name--
SELECT DISTINCT oi.product_id, price FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id
WHERE p.product_category_name LIKE '%smart%' AND oi.price BETWEEN 100 AND 500 ORDER BY oi.price DESC;
--Q4. Determine the Top 3 Months with the Highest Total Sales--
SELECT EXTRACT(MONTH FROM order_purchase_timestamp) AS month, ROUND(SUM(oi.price)) AS total_sales FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id GROUP BY month ORDER BY total_sales DESC LIMIT 3;
--Q5. Product Categories With Significant Price Variation--
SELECT distinct product_category_name, MAX(price) - MIN(price) AS price_difference FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id
GROUP BY product_category_name HAVING MAX(price) - MIN(price) > 500 ORDER BY price_difference DESC;
--Q6. Payment Types with the Most Consistent Transaction Amounts--
SELECT payment_type, STDDEV(payment_value) AS std_deviation FROM amazon_brazil.payments GROUP BY payment_type ORDER BY std_deviation ASC;
--Q7. Identify Products with Missing or Incomplete Product Category Names--
SELECT product_id, product_category_name FROM amazon_brazil.product WHERE product_category_name IS NULL OR LENGTH(product_category_name) = 1;

--Analysis 2--
--Q1. Identify Popular Payment Types by Order Value Segments--
SELECT CASE WHEN payment_value < 200 THEN 'Low (<200 BRL)' WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium (200-1000 BRL)'
ELSE 'High (>1000 BRL)' END AS order_value_segment, payment_type, COUNT(*) AS count FROM amazon_brazil.payments GROUP BY order_value_segment, payment_type
ORDER BY count DESC;
--Q2. Price Range and Average Price by Product Category--
SELECT product_category_name, MIN(price) AS min_price, MAX(price) AS max_price, AVG(price) AS avg_price
FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id GROUP BY product_category_name
ORDER BY avg_price DESC;
--Q3. Identify Customers with Multiple Orders--
SELECT customer_unique_id,COUNT(order_id) AS total_orders FROM amazon_brazil.orders o JOIN amazon_brazil.customers c ON o.customer_id = c.customer_id
GROUP BY customer_unique_id HAVING COUNT(order_id) > 1 ORDER BY total_orders DESC;
--Q4. Categorize Customers Based on Purchase History--
WITH CustomerOrderCounts AS (SELECT customer_id, COUNT(order_id) AS total_orders FROM amazon_brazil.orders GROUP BY customer_id)
SELECT customer_id, CASE WHEN total_orders = 1 THEN 'New'WHEN total_orders BETWEEN 2 AND 4 THEN 'Returning'ELSE 'Loyal'
END AS customer_type FROM CustomerOrderCounts ORDER BY customer_id;
--Q5. Categorize Customers Based on Purchase History--
SELECT p.product_category_name, SUM(oi.price) AS total_revenue FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_category_name ORDER BY total_revenue DESC LIMIT 5;

--Analysis 3--
--Q1. Total Sales for Each Season--
SELECT season, SUM(price) AS total_sales FROM (SELECT oi.price,CASE WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3, 4, 5) THEN 'Spring'
WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6, 7, 8) THEN 'Summer' WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9, 10, 11) THEN 'Autumn'
ELSE 'Winter'END AS season FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id) AS season_sales GROUP BY season
ORDER BY season;
--Q2. Products With Sales Quantity Above The Overall Average--
SELECT product_id, total_quantity_sold FROM (SELECT product_id, COUNT(order_item_id) AS total_quantity_sold FROM amazon_brazil.order_items
GROUP BY product_id) AS product_sales WHERE total_quantity_sold > (SELECT AVG(total_quantity_sold) FROM (SELECT COUNT(order_item_id) AS total_quantity_sold
FROM amazon_brazil.order_items GROUP BY product_id) AS avg_sales);
--Q3. Monthly Revenue Trends--
SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,SUM(oi.price) AS total_revenue FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018 GROUP BY month
ORDER BY month;
--Q4. Customers into segments based on purchase frequency --
WITH CustomerSegmentation AS (SELECT customer_id, COUNT(order_id) AS order_count, CASE WHEN COUNT(order_id) <= 2 THEN 'Occasional'
WHEN COUNT(order_id) BETWEEN 3 AND 5 THEN 'Regular'ELSE 'Loyal' END AS customer_type FROM amazon_brazil.orders
GROUP BY customer_id) SELECT customer_type, COUNT(*) AS count FROM CustomerSegmentation GROUP BY customer_type ORDER BY count DESC;
--Q5. Top 20 customers by average order value --
WITH CustomerOrderValue AS (SELECT customer_id, AVG(price) AS avg_order_value FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id
GROUP BY customer_id)SELECT customer_id,avg_order_value,RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank FROM CustomerOrderValue ORDER BY avg_order_value DESC
LIMIT 20;
--Q6. Compute cumulative sales month by month for each product--
WITH MonthlySales AS (SELECT product_id,TO_CHAR(DATE_TRUNC('month', o.order_purchase_timestamp), 'YYYY-MM') AS sale_month, 
SUM(oi.price) AS monthly_sales FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id GROUP BY product_id, sale_month)
SELECT product_id, sale_month,monthly_sales, SUM(monthly_sales) OVER (PARTITION BY product_id ORDER BY sale_month) AS total_sales FROM MonthlySales
ORDER BY product_id, sale_month;
--Q7. Total monthly sales for each payment method and calculate the month-over-month growth rate for 2018 --
WITH MonthlyPaymentSales AS (SELECT p.payment_type,TO_CHAR(DATE_TRUNC('month', o.order_purchase_timestamp), 'YYYY-MM') AS sale_month, 
SUM(oi.price) AS monthly_total FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id JOIN amazon_brazil.payments p ON o.order_id = p.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018 GROUP BY p.payment_type, sale_month)SELECT payment_type, sale_month, monthly_total,
ROUND(((monthly_total - LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month)) / LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month)) * 100, 2) AS monthly_change
FROM MonthlyPaymentSales ORDER BY payment_type, sale_month;











