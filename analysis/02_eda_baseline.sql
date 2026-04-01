-- High level summary of the entire business
SELECT
    COUNT(DISTINCT o.order_id)                    AS total_orders,
    COUNT(DISTINCT o.customer_id)                 AS total_customers,
    COUNT(DISTINCT oi.seller_id)                  AS total_sellers,
    COUNT(DISTINCT oi.product_id)                 AS total_products,
    ROUND(SUM(oi.price)::NUMERIC, 2)              AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)              AS avg_item_price,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2)      AS total_freight,
    ROUND(AVG(op.payment_value)::NUMERIC, 2)      AS avg_order_value
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_payments op ON o.order_id = op.order_id;
SELECT
    order_status,
    COUNT(*)                                           AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)  AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY order_month;
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;