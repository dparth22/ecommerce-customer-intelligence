# Data Dictionary — E-Commerce Sales & Customer Intelligence Analytics

## Source
Kaggle: [E-Commerce Order Dataset](https://www.kaggle.com/datasets/bytadit/ecommerce-order-dataset)
No original documentation was provided with this dataset. All column meanings,
relationships, and data quality notes below were determined through direct
inspection (see `python/01_data_cleaning.ipynb` and `inspect_data.py`).

## Dataset Structure — Important Note
The dataset ships as 5 CSV files (`df_Customers`, `df_Orders`, `df_OrderItems`,
`df_Payments`, `df_Products`), each provided in both a `train/` and `test/`
folder. Initial inspection revealed:

- `Customers`, `Orders`, `OrderItems`, and `Payments` are **row-aligned by
  position** (verified via `order_id` / `customer_id` equality across files) —
  they behave as one denormalized table split by column group, **not**
  independently-keyed relational tables.
- `Products` is the only true lookup-style table: it contains 27,451 unique
  `product_id` values across 89,316 rows, meaning product attribute rows
  repeat once per order that included that product.
- **Every customer in this dataset placed exactly one order** (89,316 unique
  customers = 89,316 orders, 1:1). There is no repeat-purchase behavior
  captured in this data. This has direct implications for analyses like
  churn or CLV — see `ml/model_results.md` for how this was handled.

---

## df_Customers.csv
Row count: 89,316 | Grain: one row per customer (= one row per order, see note above)

| Column | Type | Description | Notes |
|---|---|---|---|
| customer_id | string | Unique identifier for the customer | Primary key. 0 nulls. |
| customer_zip_code_prefix | int | First digits of customer's postal code | 0 nulls. |
| customer_city | string | Customer's city | 0 nulls. |
| customer_state | string | Customer's state (Brazilian state abbreviation) | 0 nulls. |

---

## df_Orders.csv
Row count: 89,316 | Grain: one row per order

| Column | Type | Description | Notes |
|---|---|---|---|
| order_id | string | Unique identifier for the order | Primary key. 0 nulls. |
| customer_id | string | Foreign key to df_Customers | 0 nulls. |
| order_status | string | Current status of the order | Values: delivered (87,428), shipped (936), canceled (409), processing (273), invoiced (266), unavailable (2), approved (2). |
| order_purchase_timestamp | string (datetime) | When the order was placed | 0 nulls. Should be parsed to datetime before analysis. |
| order_approved_at | string (datetime) | When payment/order was approved | 9 nulls — orders not yet approved. |
| order_delivered_timestamp | string (datetime) | When the order was delivered to the customer | 1,889 nulls. Mostly expected (non-delivered statuses), but see Known Data Quality Issues below. |
| order_estimated_delivery_date | string (datetime) | Estimated delivery date shown to customer at purchase | 0 nulls. |

---

## df_OrderItems.csv
Row count: 89,316 | Grain: one row per order (row-aligned with df_Orders)

| Column | Type | Description | Notes |
|---|---|---|---|
| order_id | string | Foreign key to df_Orders | 0 nulls. |
| product_id | string | Foreign key to df_Products | 0 nulls. All values exist in df_Products (0 orphaned references). |
| seller_id | string | Identifier for the seller who fulfilled the item | 0 nulls. |
| price | float | Item price | 0 nulls. |
| shipping_charges | float | Shipping cost for the item | 0 nulls. |

---

## df_Payments.csv
Row count: 89,316 | Grain: one row per order (row-aligned with df_Orders)

| Column | Type | Description | Notes |
|---|---|---|---|
| order_id | string | Foreign key to df_Orders | 0 nulls. |
| payment_sequential | int | Sequence number of payment (for orders paid in multiple transactions) | 0 nulls. |
| payment_type | string | Method of payment (e.g. credit_card, boleto, voucher) | 0 nulls. |
| payment_installments | int | Number of installments chosen | 0 nulls. |
| payment_value | float | Total value of the payment | 0 nulls. |

---

## df_Products.csv
Row count: 89,316 (27,451 unique products) | Grain: one row per order-item's product (repeats per reorder)

| Column | Type | Description | Notes |
|---|---|---|---|
| product_id | string | Unique identifier for the product | Not unique in this file (repeats when reordered). 0 nulls. |
| product_category_name | string | Product category | 308 nulls. |
| product_weight_g | float | Product weight in grams | 15 nulls. |
| product_length_cm | float | Product length in cm | 15 nulls. |
| product_height_cm | float | Product height in cm | 15 nulls. |
| product_width_cm | float | Product width in cm | 15 nulls. |

---

## Known Data Quality Issues

| Issue | Rows affected | Decision |
|---|---|---|
| `order_status = delivered` but `order_delivered_timestamp` is null | 6 / 89,316 (0.007%) | Kept as-is. Likely a data entry gap, not a logic error (all other fields look valid). Downstream delivery-time calculations will naturally return null for these rows. |
| `order_status = canceled` but `order_delivered_timestamp` is populated (and occurs after approval) | 5 / 89,316 (0.006%) | Kept as-is. Likely represents a post-delivery cancellation/return rather than a data error. Flagged for awareness in analysis, not excluded. |
| `product_category_name` missing | 308 / 89,316 (0.3%) | To be handled in cleaning step — candidate for an "Unknown" category label rather than row deletion. |
| Product dimension fields missing (weight/length/height/width) | 15 / 89,316 (0.02%) | To be handled in cleaning step — negligible volume, likely safe to drop or impute. |
| No repeat customers (1 order per customer) | Entire dataset | Reframes "customer intelligence" scope away from retention/churn/CLV (which require multiple purchases per customer) toward segmentation, geography, and single-order value patterns. See `ml/model_results.md`. |

---

*Last updated: initial data inspection phase. This document will be revised after the cleaning step in `python/01_data_cleaning.ipynb` to reflect final imputation/handling decisions.*
