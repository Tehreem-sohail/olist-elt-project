-- Final analytics table: one row per delivered order.
-- Combines delivery timing, item costs, review score and customer location.
-- Only orders that have both items and a review are kept.
--
-- Columns known at purchase time (usable as model features):
--   estimated_delivery_days, item_count, distinct_product_count, seller_count,
--   total_price, total_freight, freight_to_price_ratio, customer_state,
--   purchase_month, purchase_weekday, purchase_hour.
-- Columns known only after delivery (analysis only, not model features):
--   actual_delivery_days, delivery_delay_days, review_score.

DROP TABLE IF EXISTS analytics_orders;

CREATE TABLE analytics_orders AS
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.purchase_ts,
    CAST(strftime('%m', o.purchase_ts) AS INTEGER) AS purchase_month,
    CAST(strftime('%w', o.purchase_ts) AS INTEGER) AS purchase_weekday,
    CAST(strftime('%H', o.purchase_ts) AS INTEGER) AS purchase_hour,
    o.estimated_delivery_days,
    i.item_count,
    i.distinct_product_count,
    i.seller_count,
    i.total_price,
    i.total_freight,
    i.freight_to_price_ratio,
    o.actual_delivery_days,
    o.delivery_delay_days,
    o.is_late,
    r.review_score
FROM stg_orders AS o
INNER JOIN stg_order_items AS i ON i.order_id = o.order_id
INNER JOIN stg_order_reviews AS r ON r.order_id = o.order_id
INNER JOIN olist_customers_dataset AS c ON c.customer_id = o.customer_id;

CREATE INDEX idx_analytics_orders_order_id ON analytics_orders (order_id);

-- Verification 1: row count, uniqueness and missing values.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS missing_review_score,
    SUM(CASE WHEN total_price IS NULL THEN 1 ELSE 0 END) AS missing_total_price,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS missing_state
FROM analytics_orders;

-- Verification 2: average review score for on-time versus late orders.
SELECT
    is_late,
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM analytics_orders
GROUP BY is_late
ORDER BY is_late;