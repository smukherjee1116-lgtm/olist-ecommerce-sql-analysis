SELECT 'orphan_orders'       AS check_name, COUNT(*) AS issue_count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'orphan_order_items', COUNT(*)
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'orphan_item_products', COUNT(*)
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'orphan_item_sellers', COUNT(*)
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT 'orphan_payments', COUNT(*)
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'orphan_reviews', COUNT(*)
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
SELECT 'customers' AS table_name, 'customer_id' AS column_name, 
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_count FROM customers
UNION ALL
SELECT 'customers', 'customer_city',
    COUNT(*) FILTER (WHERE customer_city IS NULL) FROM customers
UNION ALL
SELECT 'customers', 'customer_state',
    COUNT(*) FILTER (WHERE customer_state IS NULL) FROM customers
UNION ALL
SELECT 'orders', 'customer_id',
    COUNT(*) FILTER (WHERE customer_id IS NULL) FROM orders
UNION ALL
SELECT 'orders', 'order_status',
    COUNT(*) FILTER (WHERE order_status IS NULL) FROM orders
UNION ALL
SELECT 'orders', 'order_approved_at',
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) FROM orders
UNION ALL
SELECT 'orders', 'order_delivered_carrier_date',
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) FROM orders
UNION ALL
SELECT 'orders', 'order_delivered_customer_date',
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) FROM orders
UNION ALL
SELECT 'order_items', 'price',
    COUNT(*) FILTER (WHERE price IS NULL) FROM order_items
UNION ALL
SELECT 'order_items', 'freight_value',
    COUNT(*) FILTER (WHERE freight_value IS NULL) FROM order_items
UNION ALL
SELECT 'products', 'product_category_name',
    COUNT(*) FILTER (WHERE product_category_name IS NULL) FROM products
UNION ALL
SELECT 'products', 'product_weight_g',
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) FROM products
UNION ALL
SELECT 'order_reviews', 'review_score',
    COUNT(*) FILTER (WHERE review_score IS NULL) FROM order_reviews
UNION ALL
SELECT 'order_reviews', 'review_comment_message',
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) FROM order_reviews
ORDER BY null_count DESC;
SELECT review_id, COUNT(*) AS duplicate_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 10;
SELECT review_score, COUNT(*) AS count
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;
SELECT 
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order,
    COUNT(DISTINCT DATE_TRUNC('month', order_purchase_timestamp)) AS total_months
FROM orders;