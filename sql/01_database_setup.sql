-- 01_database_setup.sql
-- Sets up the core schema for the E-Commerce Sales & Customer Intelligence project.
--
-- The source data wasn't a true relational schema — it was one denormalized
-- order table split into 5 CSVs by column group, with the only real lookup
-- table being products (since product_id repeats across orders). Instead of
-- just loading the 5 raw files as-is, this recreates a proper, intentional
-- structure: one fact table (orders) holding everything about each order,
-- and one dimension table (products) holding deduplicated product info.

-- Dropping tables first so this script can be re-run cleanly during
-- development without manually cleaning up each time.
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;

-- products: one row per unique product, matches the deduplicated
-- products_train_unique table built in the Python cleaning step.
CREATE TABLE products (
    product_id             VARCHAR(50) PRIMARY KEY,
    product_category_name  VARCHAR(100),
    product_weight_g       NUMERIC,
    product_length_cm      NUMERIC,
    product_height_cm      NUMERIC,
    product_width_cm       NUMERIC
);

-- orders: the main fact table, one row per order — matches the
-- master_cleaned.csv output from the Python cleaning notebook.
-- product_id is a foreign key back to products, keeping this
-- relationally sound even though the source data wasn't.
CREATE TABLE orders (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_timestamp      TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP,
    product_id                     VARCHAR(50) REFERENCES products(product_id),
    seller_id                      VARCHAR(50),
    price                          NUMERIC,
    shipping_charges                NUMERIC,
    payment_sequential             INT,
    payment_type                   VARCHAR(30),
    payment_installments           INT,
    payment_value                  NUMERIC,
    customer_zip_code_prefix       INT,
    customer_city                  VARCHAR(100),
    customer_state                 VARCHAR(10)
);

-- quick sanity check after creation — both tables should exist with 0 rows
-- until the data load step (02) populates them.
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders;
