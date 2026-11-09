-- Staging table: one row per delivered order with delivery timing columns.
-- Only delivered orders with a recorded customer delivery date are kept.
-- Delay is measured in days: positive values mean the order arrived late.

DROP TABLE IF EXISTS stg_orders;

CREATE TABLE stg_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp AS purchase_ts,
    order_approved_at AS approved_ts,
    order_delivered_carrier_date AS carrier_ts,
    order_delivered_customer_date AS delivered_ts,
    order_estimated_delivery_date AS estimated_ts,
    ROUND(julianday(order_estimated_delivery_date)
          - julianday(order_purchase_timestamp), 2) AS estimated_delivery_days,
    ROUND(julianday(order_delivered_customer_date)
          - julianday(order_purchase_timestamp), 2) AS actual_delivery_days,
    ROUND(julianday(order_delivered_customer_date)
          - julianday(order_estimated_delivery_date), 2) AS delivery_delay_days,
    CASE
        WHEN julianday(order_delivered_customer_date)
             > julianday(order_estimated_delivery_date) THEN 1
        ELSE 0
    END AS is_late
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- Verification: row count and share of late orders.
SELECT
    COUNT(*) AS total_orders,
    SUM(is_late) AS late_orders,
    ROUND(100.0 * SUM(is_late) / COUNT(*), 2) AS late_percent
FROM stg_orders;