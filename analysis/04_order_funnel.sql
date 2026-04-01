WITH order_revenue AS (
    SELECT
        o.order_id,
        o.order_status,
        COALESCE(SUM(oi.price), 0) AS order_value
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_status
)
SELECT
    order_status,
    COUNT(*)                                            AS total_orders,
    ROUND(SUM(order_value)::NUMERIC, 2)                AS total_revenue,
    ROUND(AVG(order_value)::NUMERIC, 2)                AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_orders
FROM order_revenue
GROUP BY order_status
ORDER BY total_orders DESC;
SELECT
    TO_CHAR(order_purchase_timestamp, 'Day')           AS day_of_week,
    EXTRACT(DOW FROM order_purchase_timestamp)         AS day_number,
    COUNT(*)                                           AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_orders
FROM orders
GROUP BY day_of_week, day_number
ORDER BY day_number;
SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp)        AS order_hour,
    COUNT(*)                                           AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category,
    COUNT(DISTINCT oi.order_id)                     AS total_orders,
    COUNT(oi.order_item_id)                         AS items_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2)                AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                AS avg_item_price,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2)        AS total_freight,
    ROUND(SUM(oi.freight_value) * 100.0 /
          NULLIF(SUM(oi.price), 0)::NUMERIC, 2)     AS freight_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized')
ORDER BY total_revenue DESC
LIMIT 15;
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category,
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'canceled'
                   THEN o.order_id END)                 AS cancelled_orders,
    ROUND(COUNT(DISTINCT CASE WHEN o.order_status = 'canceled'
                   THEN o.order_id END) * 100.0 /
          NULLIF(COUNT(DISTINCT o.order_id), 0)::NUMERIC, 2) AS cancel_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized')
HAVING COUNT(DISTINCT o.order_id) > 50
ORDER BY cancel_rate_pct DESC
LIMIT 10;