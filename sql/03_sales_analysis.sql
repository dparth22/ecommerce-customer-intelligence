-- 03_sales_analysis.sql
-- Core sales analysis: revenue, trends, category performance, payments,
-- and delivery timing. These queries also double as the source data
-- for the Power BI dashboard later.
--
-- Revenue = price + shipping_charges (the full amount the customer paid).
-- Most queries filter to order_status = 'delivered' only, since
-- canceled/unavailable orders didn't generate real revenue even though
-- a price is recorded for them.

-- 1. OVERALL REVENUE SUMMARY
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(price + shipping_charges), 2) AS total_revenue,
    ROUND(AVG(price + shipping_charges), 2) AS avg_order_value
FROM orders
WHERE order_status = 'delivered';

-- 2. MONTHLY REVENUE TREND
-- Using purchase date, not delivery date, since it's always populated
-- and marks when the sale actually happened.
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS order_count,
    ROUND(SUM(price + shipping_charges), 2) AS revenue
FROM orders
WHERE order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- 3. REVENUE BY PRODUCT CATEGORY (TOP 15)
SELECT
    p.product_category_name,
    COUNT(*) AS order_count,
    ROUND(SUM(o.price + o.shipping_charges), 2) AS revenue,
    ROUND(AVG(o.price), 2) AS avg_price
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 15;

-- 4. PAYMENT TYPE BREAKDOWN
SELECT
    payment_type,
    COUNT(*) AS order_count,
    ROUND(AVG(payment_installments), 1) AS avg_installments,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM orders
WHERE order_status = 'delivered'
GROUP BY payment_type
ORDER BY order_count DESC;

-- 5. AVERAGE DELIVERY TIME (DAYS FROM PURCHASE TO DELIVERY)
-- Skips the few rows with a null delivered_timestamp (see 02_data_quality.sql).
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_timestamp - order_purchase_timestamp)) / 86400), 1) AS avg_delivery_days,
    ROUND(MIN(EXTRACT(EPOCH FROM (order_delivered_timestamp - order_purchase_timestamp)) / 86400), 1) AS min_delivery_days,
    ROUND(MAX(EXTRACT(EPOCH FROM (order_delivered_timestamp - order_purchase_timestamp)) / 86400), 1) AS max_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL;

-- 6. ON-TIME VS LATE DELIVERY RATE
-- Compares actual delivery date to the estimate shown at purchase.
SELECT
    CASE
        WHEN order_delivered_timestamp <= order_estimated_delivery_date THEN 'on_time'
        ELSE 'late'
    END AS delivery_status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL
GROUP BY delivery_status;

-- 7. TOP 10 STATES BY REVENUE
SELECT
    customer_state,
    COUNT(*) AS order_count,
    ROUND(SUM(price + shipping_charges), 2) AS revenue
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY revenue DESC
LIMIT 10;
