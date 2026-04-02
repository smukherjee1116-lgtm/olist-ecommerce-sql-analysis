WITH customer_order_count AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_spent,
        MIN(o.order_purchase_timestamp) AS first_order,
        MAX(o.order_purchase_timestamp) AS last_order
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'one_time_buyer'
        WHEN total_orders = 2 THEN 'repeat_buyer_2x'
        WHEN total_orders >= 3 THEN 'loyal_buyer_3x_plus'
    END                                                AS buyer_segment,
    COUNT(*)                                           AS total_customers,
    ROUND(AVG(total_spent)::NUMERIC, 2)               AS avg_lifetime_spend,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers
FROM customer_order_count
GROUP BY buyer_segment
ORDER BY total_customers DESC;
SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id)           AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(oi.price)::NUMERIC, 2)     AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)     AS avg_item_price
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_city, c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;
WITH customer_ltv AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)       AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS lifetime_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN lifetime_value < 100  THEN 'under_R$100'
        WHEN lifetime_value < 300  THEN 'R$100-300'
        WHEN lifetime_value < 500  THEN 'R$300-500'
        WHEN lifetime_value < 1000 THEN 'R$500-1000'
        ELSE 'over_R$1000'
    END                                                AS ltv_bucket,
    COUNT(*)                                           AS total_customers,
    ROUND(AVG(lifetime_value)::NUMERIC, 2)            AS avg_ltv,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers
FROM customer_ltv
GROUP BY ltv_bucket
ORDER BY avg_ltv;
WITH first_orders AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    DATE_TRUNC('month', first_order_date) AS acquisition_month,
    COUNT(*)                              AS new_customers
FROM first_orders
GROUP BY DATE_TRUNC('month', first_order_date)
ORDER BY acquisition_month;
WITH customer_ltv AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        COUNT(DISTINCT o.order_id)       AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS lifetime_value,
        MIN(o.order_purchase_timestamp)  AS first_order,
        MAX(o.order_purchase_timestamp)  AS last_order
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id, c.customer_city, c.customer_state
)
SELECT
    customer_unique_id,
    customer_city,
    customer_state,
    total_orders,
    lifetime_value,
    first_order,
    last_order
FROM customer_ltv
ORDER BY lifetime_value DESC
LIMIT 10;