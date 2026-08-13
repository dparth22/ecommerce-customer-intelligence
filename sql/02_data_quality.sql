-- 02_data_quality.sql
-- Reproduces the key data quality checks originally done in Python
-- (python/01_data_cleaning.ipynb) directly in SQL, plus documents the
-- known anomalies found in the source data. This is meant to show the
-- same investigation can be done at the database level, not just in
-- pandas, and to serve as a reference for anyone querying this data
-- later.

-- 1. NULL COUNTS ACROSS KEY COLUMNS
-- Confirms the same null pattern found during cleaning: 9 missing
-- order_approved_at, 1889 missing order_delivered_timestamp, and
-- everything else clean (since nulls in product fields were already
-- resolved in Python before loading into products).
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_timestamp IS NULL) AS null_delivered_timestamp
FROM orders;

-- 2. ORDER STATUS BREAKDOWN
-- Same distribution check as the Python inspection step — useful to
-- keep here since any future SQL analysis will reference these statuses.
SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 3. ANOMALY: "delivered" status but missing delivered_timestamp
-- Found 6 of these during Python inspection. Kept in the dataset rather
-- than dropped, since every other field on these rows looks valid —
-- most likely just a missing data entry, not a real logic error.
SELECT order_id, order_status, order_purchase_timestamp,
       order_approved_at, order_delivered_timestamp,
       order_estimated_delivery_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_timestamp IS NULL;

-- 4. ANOMALY: "canceled" status but HAS a delivered_timestamp
-- Found 5 of these. Likely represents a post-delivery cancellation or
-- return rather than a data error, since the delivered_timestamp in
-- each case comes after order_approved_at, which is logically
-- consistent with an order actually being delivered before it was
-- canceled.
SELECT order_id, order_status, order_purchase_timestamp,
       order_approved_at, order_delivered_timestamp,
       order_estimated_delivery_date
FROM orders
WHERE order_status = 'canceled'
  AND order_delivered_timestamp IS NOT NULL;

-- 5. REFERENTIAL INTEGRITY CHECK
-- Confirms every product_id in orders actually exists in products —
-- should return 0 rows, since this was already verified in Python
-- and enforced by the foreign key constraint at load time.
SELECT o.order_id, o.product_id
FROM orders o
LEFT JOIN products p ON o.product_id = p.product_id
WHERE p.product_id IS NULL;
