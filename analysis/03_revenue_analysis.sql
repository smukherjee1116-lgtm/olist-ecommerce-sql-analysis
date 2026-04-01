WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        ROUND(SUM(oi.price)::NUMERIC, 2)                AS monthly_gmv,
        COUNT(DISTINCT o.order_id)                       AS total_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    order_month,
    monthly_gmv,
    total_orders,
    ROUND(SUM(monthly_gmv) OVER (ORDER BY order_month)::NUMERIC, 2) AS running_total_gmv,
    ROUND(AVG(monthly_gmv) OVER (
        ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )::NUMERIC, 2)                                                    AS rolling_3m_avg
FROM monthly_revenue
ORDER BY order_month;
WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM o.order_purchase_timestamp)  AS order_year,
        ROUND(SUM(oi.price)::NUMERIC, 2)               AS annual_revenue,
        COUNT(DISTINCT o.order_id)                     AS total_orders,
        ROUND(AVG(oi.price)::NUMERIC, 2)               AS avg_item_price
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY EXTRACT(YEAR FROM o.order_purchase_timestamp)
)
SELECT
    order_year,
    annual_revenue,
    total_orders,
    avg_item_price,
    ROUND(
        (annual_revenue - LAG(annual_revenue) OVER (ORDER BY order_year))
        * 100.0 / LAG(annual_revenue) OVER (ORDER BY order_year)
    , 2) AS yoy_growth_pct
FROM yearly
ORDER BY order_year;
SELECT
    payment_type,
    COUNT(*)                                            AS total_transactions,
    ROUND(SUM(payment_value)::NUMERIC, 2)              AS total_value,
    ROUND(AVG(payment_value)::NUMERIC, 2)              AS avg_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_transactions
FROM order_payments
GROUP BY payment_type
ORDER BY total_transactions DESC;
SELECT
    payment_installments,
    COUNT(*) AS total_orders,
    ROUND(AVG(payment_value)::NUMERIC, 2) AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_orders
FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;