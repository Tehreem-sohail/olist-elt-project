-- Sanity checks on the raw Olist tables.
-- Each row of the result is one check: a name and its value.

SELECT 'orders_total_rows' AS check_name, COUNT(*) AS value
FROM olist_orders_dataset

UNION ALL
SELECT 'orders_distinct_order_id', COUNT(DISTINCT order_id)
FROM olist_orders_dataset

UNION ALL
SELECT 'orders_with_status_delivered', COUNT(*)
FROM olist_orders_dataset
WHERE order_status = 'delivered'

UNION ALL
SELECT 'delivered_orders_missing_delivery_date', COUNT(*)
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL

UNION ALL
SELECT 'delivered_before_purchase', COUNT(*)
FROM olist_orders_dataset
WHERE order_delivered_customer_date < order_purchase_timestamp

UNION ALL
SELECT 'customers_total_rows', COUNT(*)
FROM olist_customers_dataset

UNION ALL
SELECT 'customers_distinct_customer_id', COUNT(DISTINCT customer_id)
FROM olist_customers_dataset

UNION ALL
SELECT 'customers_distinct_customer_unique_id', COUNT(DISTINCT customer_unique_id)
FROM olist_customers_dataset

UNION ALL
SELECT 'order_items_total_rows', COUNT(*)
FROM olist_order_items_dataset

UNION ALL
SELECT 'order_items_distinct_order_id', COUNT(DISTINCT order_id)
FROM olist_order_items_dataset

UNION ALL
SELECT 'reviews_total_rows', COUNT(*)
FROM olist_order_reviews_dataset

UNION ALL
SELECT 'reviews_distinct_order_id', COUNT(DISTINCT order_id)
FROM olist_order_reviews_dataset

UNION ALL
SELECT 'orders_without_items', COUNT(*)
FROM olist_orders_dataset
WHERE order_id NOT IN (SELECT order_id FROM olist_order_items_dataset)

UNION ALL
SELECT 'orders_without_reviews', COUNT(*)
FROM olist_orders_dataset
WHERE order_id NOT IN (SELECT order_id FROM olist_order_reviews_dataset);