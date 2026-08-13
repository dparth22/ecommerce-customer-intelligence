-- 04_customer_analysis.sql
-- Customer-level analysis. Every customer in this dataset placed
-- exactly one order (checked in 01_data_cleaning.ipynb and
-- 02_data_quality.sql), so real retention, churn, or CLV analysis
-- isn't possible here — those all need multiple purchases per customer.
--
-- Instead this looks at what the data can actually support: segmenting
-- customers by how much they spent, where they're from, and how they paid.

-- 1. CUSTOMER SPEND TIERS
-- Buckets each customer's one order into a spend tier.
SELECT
    CASE
        WHEN (price + shipping_charges) < 50 THEN 'low (<$50)'
        WHEN (price + shipping_charges) < 150 THEN 'mid ($50-150)'
        WHEN (price + shipping_charges) < 400 THEN 'high ($150-400)'
        ELSE 'premium ($400+)'
    END AS spend_tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(price + shipping_charges), 2) AS avg_order_value
FROM orders
WHERE order_status = 'delivered'
GROUP BY spend_tier
ORDER BY avg_order_value;

-- 2. AVERAGE ORDER VALUE BY STATE
-- Shows which states have higher-spending customers on average,
-- not just more of them (total revenue by state is in 03_sales_analysis.sql).
SELECT
    customer_state,
    COUNT(*) AS customer_count,
    ROUND(AVG(price + shipping_charges), 2) AS avg_order_value
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_state
HAVING COUNT(*) >= 50  -- skip states with too few customers to be meaningful
ORDER BY avg_order_value DESC
LIMIT 10;

-- 3. PAYMENT INSTALLMENTS BY SPEND TIER
-- Checking if bigger spenders tend to pay in more installments.
SELECT
    CASE
        WHEN (price + shipping_charges) < 50 THEN 'low (<$50)'
        WHEN (price + shipping_charges) < 150 THEN 'mid ($50-150)'
        WHEN (price + shipping_charges) < 400 THEN 'high ($150-400)'
        ELSE 'premium ($400+)'
    END AS spend_tier,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM orders
WHERE order_status = 'delivered'
GROUP BY spend_tier
ORDER BY avg_installments;

-- 4. TOP CITIES BY CUSTOMER COUNT
SELECT
    customer_city,
    customer_state,
    COUNT(*) AS customer_count,
    ROUND(SUM(price + shipping_charges), 2) AS total_revenue
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_city, customer_state
ORDER BY customer_count DESC
LIMIT 15;

-- 5. TOP CATEGORY PER STATE (TOP 5 STATES)
-- Uses a window function to find the #1 category ordered in each state.
WITH state_category_counts AS (
    SELECT
        o.customer_state,
        p.product_category_name,
        COUNT(*) AS order_count,
        RANK() OVER (PARTITION BY o.customer_state ORDER BY COUNT(*) DESC) AS category_rank
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    WHERE o.order_status = 'delivered'
      AND o.customer_state IN ('SP', 'RJ', 'MG', 'RS', 'PR')  -- top 5 states by revenue
    GROUP BY o.customer_state, p.product_category_name
)
SELECT customer_state, product_category_name, order_count
FROM state_category_counts
WHERE category_rank = 1
ORDER BY order_count DESC;
