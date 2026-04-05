WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT oi.order_id)      AS total_orders,
        COUNT(oi.order_item_id)          AS items_sold,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price,
        ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight
    FROM order_items oi
    JOIN sellers s ON oi.seller_id = s.seller_id
    GROUP BY oi.seller_id, s.seller_city, s.seller_state
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    seller_id,
    seller_city,
    seller_state,
    total_orders,
    items_sold,
    total_revenue,
    avg_item_price,
    total_freight
FROM seller_metrics
ORDER BY revenue_rank
LIMIT 10;
WITH seller_reviews AS (
    SELECT
        oi.seller_id,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
        COUNT(DISTINCT r.review_id)             AS total_reviews,
        COUNT(DISTINCT oi.order_id)             AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2)        AS total_revenue
    FROM order_items oi
    JOIN order_reviews r ON oi.order_id = r.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    GROUP BY oi.seller_id
    HAVING COUNT(DISTINCT oi.order_id) >= 50
)
SELECT
    RANK() OVER (ORDER BY avg_review_score DESC) AS review_rank,
    seller_id,
    avg_review_score,
    total_reviews,
    total_orders,
    total_revenue
FROM seller_reviews
ORDER BY review_rank
LIMIT 10;
WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        COUNT(DISTINCT oi.order_id)       AS total_orders
    FROM order_items oi
    GROUP BY oi.seller_id
)
SELECT
    CASE
        WHEN total_revenue >= 100000 THEN 'platinum'
        WHEN total_revenue >= 50000  THEN 'gold'
        WHEN total_revenue >= 10000  THEN 'silver'
        ELSE                              'bronze'
    END                                                AS seller_tier,
    COUNT(*)                                           AS total_sellers,
    ROUND(AVG(total_revenue)::NUMERIC, 2)             AS avg_revenue,
    ROUND(SUM(total_revenue)::NUMERIC, 2)             AS tier_total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_sellers
FROM seller_revenue
GROUP BY seller_tier
ORDER BY avg_revenue DESC;
WITH seller_stats AS (
    SELECT
        oi.seller_id,
        s.seller_city,
        s.seller_state,
        ROUND(SUM(oi.price)::NUMERIC, 2)        AS total_revenue,
        COUNT(DISTINCT oi.order_id)              AS total_orders,
        ROUND(AVG(r.review_score)::NUMERIC, 2)  AS avg_review_score
    FROM order_items oi
    JOIN sellers s ON oi.seller_id = s.seller_id
    JOIN order_reviews r ON oi.order_id = r.order_id
    GROUP BY oi.seller_id, s.seller_city, s.seller_state
    HAVING COUNT(DISTINCT oi.order_id) >= 100
)
SELECT
    seller_id,
    seller_city,
    seller_state,
    total_revenue,
    total_orders,
    avg_review_score
FROM seller_stats
WHERE avg_review_score < 3.5
ORDER BY total_revenue DESC
LIMIT 10;
SELECT
    s.seller_state,
    COUNT(DISTINCT oi.seller_id)             AS total_sellers,
    COUNT(DISTINCT oi.order_id)              AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)         AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)         AS avg_item_price
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;