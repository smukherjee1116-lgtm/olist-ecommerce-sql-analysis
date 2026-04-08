WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
        COUNT(DISTINCT oi.order_id)       AS total_orders
    FROM order_items oi
    JOIN sellers s ON oi.seller_id = s.seller_id
    GROUP BY oi.seller_id, s.seller_state
)
SELECT
    seller_id,
    seller_state,
    total_revenue,
    total_orders,
    RANK()       OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS dense_rank,
    NTILE(4)     OVER (ORDER BY total_revenue DESC) AS revenue_quartile,
    ROUND(SUM(total_revenue) OVER ()::NUMERIC, 2)   AS platform_total,
    ROUND(total_revenue * 100.0 /
          SUM(total_revenue) OVER ()::NUMERIC, 2)   AS pct_of_platform
FROM seller_revenue
ORDER BY revenue_rank
LIMIT 20;
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        ROUND(SUM(oi.price)::NUMERIC, 2)                AS monthly_revenue,
        COUNT(DISTINCT o.order_id)                       AS total_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    order_month,
    monthly_revenue,
    total_orders,
    LAG(monthly_revenue) OVER (ORDER BY order_month)  AS prev_month_revenue,
    ROUND((monthly_revenue - LAG(monthly_revenue)
           OVER (ORDER BY order_month))::NUMERIC, 2)  AS mom_change,
    ROUND((monthly_revenue - LAG(monthly_revenue)
           OVER (ORDER BY order_month)) * 100.0 /
           NULLIF(LAG(monthly_revenue)
           OVER (ORDER BY order_month), 0)::NUMERIC, 2) AS mom_growth_pct,
    ROUND(AVG(monthly_revenue)
          OVER (ORDER BY order_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::NUMERIC, 2) AS rolling_3m_avg
FROM monthly
ORDER BY order_month;
SELECT *
FROM (
    WITH state_category_revenue AS (
        SELECT
            c.customer_state,
            COALESCE(t.product_category_name_english,
                     p.product_category_name, 'uncategorized') AS category,
            ROUND(SUM(oi.price)::NUMERIC, 2)                   AS total_revenue
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN products p ON oi.product_id = p.product_id
        LEFT JOIN product_category_name_translation t
               ON p.product_category_name = t.product_category_name
        GROUP BY c.customer_state,
                 COALESCE(t.product_category_name_english,
                          p.product_category_name, 'uncategorized')
    )
    SELECT
        customer_state,
        category,
        total_revenue,
        RANK() OVER (PARTITION BY customer_state
                     ORDER BY total_revenue DESC) AS rank_within_state
    FROM state_category_revenue
) ranked
WHERE rank_within_state <= 3
ORDER BY customer_state, rank_within_state;
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS order_value,
        LEAD(o.order_purchase_timestamp)
            OVER (PARTITION BY c.customer_unique_id
                  ORDER BY o.order_purchase_timestamp) AS next_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id,
             o.order_purchase_timestamp,
             o.order_id
)
SELECT
    customer_unique_id,
    order_purchase_timestamp,
    order_value,
    next_order_date,
    EXTRACT(DAY FROM next_order_date - order_purchase_timestamp) AS days_to_next_order
FROM customer_orders
WHERE next_order_date IS NOT NULL
ORDER BY days_to_next_order
LIMIT 15;
WITH order_values AS (
    SELECT
        o.order_id,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY o.order_id
),
deciled AS (
    SELECT
        order_id,
        order_value,
        NTILE(10) OVER (ORDER BY order_value) AS decile
    FROM order_values
)
SELECT
    decile,
    COUNT(*)                             AS total_orders,
    ROUND(MIN(order_value)::NUMERIC, 2) AS min_value,
    ROUND(MAX(order_value)::NUMERIC, 2) AS max_value,
    ROUND(AVG(order_value)::NUMERIC, 2) AS avg_value
FROM deciled
GROUP BY decile
ORDER BY decile;