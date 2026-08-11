"""
inspect_data.py
----------------
Initial data exploration script for the E-Commerce Sales & Customer
Intelligence Analytics project.

Purpose: Before cleaning or modeling anything, we need to understand
what we're actually working with — shapes, keys, relationships, nulls,
duplicates, and logical inconsistencies. This script re-runs every
check we did manually during initial inspection, in one place.

Run this from inside the folder that contains the 5 CSV files
(e.g. the "train" folder), like:
    python3 inspect_data.py
"""

import pandas as pd

# -----------------------------------------------------------------------
# 1. LOAD ALL FILES
# -----------------------------------------------------------------------
# We load each CSV into its own DataFrame. pandas will guess data types
# automatically (int, float, string/object) based on the column contents.
customers = pd.read_csv('df_Customers.csv')
orders = pd.read_csv('df_Orders.csv')
order_items = pd.read_csv('df_OrderItems.csv')
products = pd.read_csv('df_Products.csv')
payments = pd.read_csv('df_Payments.csv')

# A dictionary makes it easy to loop over all 5 files instead of
# repeating the same code 5 times.
files = {
    'df_Customers.csv': customers,
    'df_Orders.csv': orders,
    'df_OrderItems.csv': order_items,
    'df_Payments.csv': payments,
    'df_Products.csv': products
}

# -----------------------------------------------------------------------
# 2. SHAPE & COLUMNS
# -----------------------------------------------------------------------
# .shape tells us (number of rows, number of columns).
# This is the very first thing to check for any new dataset — it tells
# you the scale of what you're working with, and whether row counts
# match up across related files (a big clue about how tables relate).
print("### SHAPE & COLUMNS ###")
for name, df in files.items():
    print('=====', name, '=====')
    print('Shape:', df.shape)
    print('Columns:', list(df.columns))
    print()

# -----------------------------------------------------------------------
# 3. UNIQUENESS CHECK
# -----------------------------------------------------------------------
# .nunique() counts DISTINCT values in a column.
# Why this matters: a "primary key" (like customer_id or order_id)
# should normally be unique in its own table. If nunique() equals the
# row count, that column truly identifies each row. If it's smaller,
# that column repeats across multiple rows (a sign it's a "foreign key"
# or that the table isn't deduplicated).
print("### UNIQUENESS CHECK ###")
print('Unique customer_id in Customers:', customers['customer_id'].nunique())
print('Unique order_id in Orders:', orders['order_id'].nunique())
print('Unique order_id in OrderItems:', order_items['order_id'].nunique())
print('Unique product_id in Products:', products['product_id'].nunique())
print('Unique order_id in Payments:', payments['order_id'].nunique())
print()

# -----------------------------------------------------------------------
# 4. ALIGNMENT CHECK
# -----------------------------------------------------------------------
# This checks whether row N in one file always matches row N in another
# file (i.e., they're already lined up by POSITION, not just by shared
# key values). We compare column-by-column with == and then .all() to
# confirm EVERY row matches, not just most of them.
# Why this matters: if files are positionally aligned, that tells us
# they were likely split from one original wide table, rather than
# being independently-keyed relational tables that need real joins.
print("### ALIGNMENT CHECK ###")
print('Orders vs OrderItems aligned:', (orders['order_id'] == order_items['order_id']).all())
print('Orders vs Payments aligned:', (orders['order_id'] == payments['order_id']).all())
print('Orders vs Customers aligned:', (orders['customer_id'] == customers['customer_id']).all())
print()

# Check that every product_id referenced in OrderItems actually exists
# in the Products file (a "referential integrity" check — makes sure
# joins won't silently drop or lose data).
missing_products = set(order_items['product_id']) - set(products['product_id'])
print('Product IDs in OrderItems missing from Products:', len(missing_products))

# .duplicated() flags rows that are exact repeats of an earlier row.
# Here we check duplicates on product_id specifically to see if the
# same product appears multiple times (expected if Products isn't a
# deduplicated lookup table, but repeats once per order).
print('Duplicate product_id rows in Products:', products['product_id'].duplicated().sum())
print()

# -----------------------------------------------------------------------
# 5. DATA QUALITY: TYPES, NULLS, DUPLICATE ROWS
# -----------------------------------------------------------------------
# .dtypes shows the data type pandas assigned each column (helps catch
# issues like dates being read as plain text instead of datetime).
#
# .isnull().sum() counts missing (NaN) values per column — critical for
# deciding how to handle gaps before analysis or modeling.
#
# .duplicated().sum() counts fully duplicate ROWS (every column matches
# another row exactly) — different from the product_id duplicate check
# above, which only looked at one column.
print("### DATA QUALITY ###")
for name, df in files.items():
    print('=====', name, '=====')
    print(df.dtypes)
    print()
    print('Null counts:')
    print(df.isnull().sum())
    print()
    print('Fully duplicate rows:', df.duplicated().sum())
    print()

# -----------------------------------------------------------------------
# 6. ORDER STATUS BREAKDOWN
# -----------------------------------------------------------------------
# .value_counts() counts how many rows fall into each category of a
# column. Useful for understanding the distribution of a categorical
# field, and for sanity-checking nulls against logical expectations
# (e.g., a "canceled" order SHOULD be missing a delivery timestamp).
print("### ORDER STATUS BREAKDOWN ###")
print(orders['order_status'].value_counts())
print()

# Filter to only rows where delivered_timestamp is null, then check
# what order_status those rows have. This tells us WHY the nulls exist
# — are they logically expected, or a real data quality issue?
null_delivered = orders[orders['order_delivered_timestamp'].isnull()]
print('Status breakdown for orders missing delivered_timestamp:')
print(null_delivered['order_status'].value_counts())
print()

# -----------------------------------------------------------------------
# 7. ANOMALIES: LOGICALLY INCONSISTENT ROWS
# -----------------------------------------------------------------------
# Boolean filtering: orders[condition] returns only rows where the
# condition is True. Combining two conditions with & (and) lets us
# isolate rows that break expected logic.

# Case 1: status says "delivered" but there's no delivery timestamp.
# This is a real inconsistency worth flagging — a delivered order
# should always have a delivery date.
case1 = orders[(orders['order_status'] == 'delivered') & (orders['order_delivered_timestamp'].isnull())]
print("### ANOMALIES ###")
print('Delivered but missing delivered_timestamp:')
print(case1[['order_id', 'order_status', 'order_purchase_timestamp',
             'order_approved_at', 'order_delivered_timestamp',
             'order_estimated_delivery_date']])
print()

# Case 2: status says "canceled" but there IS a delivery timestamp.
# Also logically odd — how was something delivered AND canceled?
case2 = orders[(orders['order_status'] == 'canceled') & (orders['order_delivered_timestamp'].notnull())]
print('Canceled but HAS delivered_timestamp:')
print(case2[['order_id', 'order_status', 'order_purchase_timestamp',
             'order_approved_at', 'order_delivered_timestamp',
             'order_estimated_delivery_date']])