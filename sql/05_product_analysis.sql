-- 05_product_analysis.sql
-- Product-level analysis: best and worst performing products, pricing
-- spread within categories, and shipping cost patterns.

-- 1. TOP 10 PRODUCTS BY REVENUE
SELECT
    o.product_id,
    p.product_category_name,
    COUNT(*) AS times_ordered,
    ROUND(SUM(o.price + o.shipping_charges), 2) AS revenue,
    ROUND(AVG(o.price), 2) AS avg_price
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY o.product_id, p.product_category_name
ORDER BY revenue DESC
LIMIT 10;

-- 2. PRICE RANGE BY CATEGORY (TOP 15 CATEGORIES BY ORDER COUNT)
-- Shows how much price varies within each category — a category with
-- a huge min-max spread might mean it covers very different kinds of
-- products lumped under one label.
SELECT
    p.product_category_name,
    COUNT(*) AS order_count,
    ROUND(MIN(o.price), 2) AS min_price,
    ROUND(MAX(o.price), 2) AS max_price,
    ROUND(AVG(o.price), 2) AS avg_price
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY order_count DESC
LIMIT 15;

-- 3. SHIPPING COST AS A PERCENT OF PRICE, BY CATEGORY
-- Categories where shipping is a big chunk of the total cost might be
-- heavier or bulkier items — worth knowing for both business and
-- product-dimension reasons.
SELECT
    p.product_category_name,
    ROUND(AVG(o.shipping_charges), 2) AS avg_shipping,
    ROUND(AVG(o.price), 2) AS avg_price,
    ROUND(100.0 * AVG(o.shipping_charges) / NULLIF(AVG(o.price), 0), 1) AS shipping_pct_of_price
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
HAVING COUNT(*) >= 50  -- skip categories with too few orders to be meaningful
ORDER BY shipping_pct_of_price DESC
LIMIT 15;

-- 4. PRODUCT WEIGHT VS SHIPPING COST
-- Simple check on whether heavier products actually cost more to ship,
-- using weight buckets since exact weight-to-shipping correlation is
-- easier to read this way than as a scatter of exact numbers.
SELECT
    CASE
        WHEN p.product_weight_g < 500 THEN 'under 500g'
        WHEN p.product_weight_g < 2000 THEN '500g-2kg'
        WHEN p.product_weight_g < 5000 THEN '2kg-5kg'
        ELSE 'over 5kg'
    END AS weight_bucket,
    COUNT(*) AS order_count,
    ROUND(AVG(o.shipping_charges), 2) AS avg_shipping_cost
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY weight_bucket
ORDER BY avg_shipping_cost;

-- 5. BOTTOM 10 CATEGORIES BY ORDER COUNT
-- The least-ordered categories — useful context alongside the top
-- categories already covered in 03_sales_analysis.sql.
SELECT
    p.product_category_name,
    COUNT(*) AS order_count,
    ROUND(SUM(o.price + o.shipping_charges), 2) AS revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY order_count ASC
LIMIT 10;
