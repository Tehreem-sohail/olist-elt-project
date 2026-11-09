-- Staging tables with one row per order.
--   stg_order_items:   item and cost totals per order.
--   stg_order_reviews: the latest review per order.

DROP TABLE IF EXISTS stg_order_items;

CREATE TABLE stg_order_items AS
SELECT
    order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT product_id) AS distinct_product_count,
    COUNT(DISTINCT seller_id) AS seller_count,
    ROUND(SUM(CAST(price AS REAL)), 2) AS total_price,
    ROUND(SUM(CAST(freight_value AS REAL)), 2) AS total_freight,
    ROUND(
        SUM(CAST(freight_value AS REAL)) / NULLIF(SUM(CAST(price AS REAL)), 0),
        4
    ) AS freight_to_price_ratio
FROM olist_order_items_dataset
GROUP BY order_id;

CREATE INDEX idx_stg_order_items_order_id ON stg_order_items (order_id);

DROP TABLE IF EXISTS stg_order_reviews;

CREATE TABLE stg_order_reviews AS
SELECT
    order_id,
    review_id,
    CAST(review_score AS INTEGER) AS review_score,
    review_creation_date AS review_created_ts,
    review_answer_timestamp AS review_answered_ts
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_answer_timestamp DESC,
                     review_creation_date DESC,
                     review_id DESC
        ) AS review_rank
    FROM olist_order_reviews_dataset
)
WHERE review_rank = 1;

CREATE INDEX idx_stg_order_reviews_order_id ON stg_order_reviews (order_id);

-- Verification: each staging table must have exactly one row per order.
SELECT
    'stg_order_items' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM stg_order_items

UNION ALL
SELECT
    'stg_order_reviews',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM stg_order_reviews;