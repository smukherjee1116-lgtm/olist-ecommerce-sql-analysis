SELECT
    COUNT(*)                                                AS total_delivered,
    ROUND(AVG(EXTRACT(DAY FROM
          order_delivered_customer_date
        - order_purchase_timestamp))::NUMERIC, 2)          AS avg_delivery_days,
    ROUND(AVG(EXTRACT(DAY FROM
          order_estimated_delivery_date
        - order_purchase_timestamp))::NUMERIC, 2)          AS avg_estimated_days,
    ROUND(AVG(EXTRACT(DAY FROM
          order_estimated_delivery_date
        - order_delivered_customer_date))::NUMERIC, 2)     AS avg_days_early_late,
    COUNT(CASE WHEN order_delivered_customer_date
               <= order_estimated_delivery_date
               THEN 1 END)                                 AS on_time_orders,
    COUNT(CASE WHEN order_delivered_customer_date
               > order_estimated_delivery_date
               THEN 1 END)                                 AS late_orders,
    ROUND(COUNT(CASE WHEN order_delivered_customer_date
               > order_estimated_delivery_date
               THEN 1 END) * 100.0 / COUNT(*)::NUMERIC, 2) AS late_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
WITH state_delivery AS (
    SELECT
        c.customer_state,
        COUNT(*)                                        AS total_orders,
        ROUND(AVG(EXTRACT(DAY FROM
              o.order_delivered_customer_date
            - o.order_purchase_timestamp))::NUMERIC, 2) AS avg_delivery_days,
        ROUND(AVG(EXTRACT(DAY FROM
              o.order_estimated_delivery_date
            - o.order_delivered_customer_date))::NUMERIC, 2) AS avg_days_early_late,
        COUNT(CASE WHEN o.order_delivered_customer_date
                   > o.order_estimated_delivery_date
                   THEN 1 END)                          AS late_orders,
        ROUND(COUNT(CASE WHEN o.order_delivered_customer_date
                   > o.order_estimated_delivery_date
                   THEN 1 END) * 100.0 /
              COUNT(*)::NUMERIC, 2)                     AS late_pct
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    total_orders,
    avg_delivery_days,
    avg_days_early_late,
    late_orders,
    late_pct,
    RANK() OVER (ORDER BY late_pct DESC) AS worst_rank
FROM state_delivery
ORDER BY late_pct DESC;
WITH monthly_delivery AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
        ROUND(AVG(EXTRACT(DAY FROM
              o.order_delivered_customer_date
            - o.order_purchase_timestamp))::NUMERIC, 2)  AS avg_delivery_days,
        ROUND(AVG(EXTRACT(DAY FROM
              o.order_estimated_delivery_date
            - o.order_delivered_customer_date))::NUMERIC, 2) AS avg_days_early,
        COUNT(*)                                          AS total_orders,
        ROUND(COUNT(CASE WHEN o.order_delivered_customer_date
                   > o.order_estimated_delivery_date
                   THEN 1 END) * 100.0 /
              COUNT(*)::NUMERIC, 2)                       AS late_pct
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    order_month,
    avg_delivery_days,
    avg_days_early,
    total_orders,
    late_pct
FROM monthly_delivery
ORDER BY order_month;
SELECT
    c.customer_state,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2)            AS avg_freight,
    ROUND(AVG(EXTRACT(DAY FROM
          o.order_delivered_customer_date
        - o.order_purchase_timestamp))::NUMERIC, 2)     AS avg_delivery_days,
    ROUND(AVG(oi.freight_value) /
          NULLIF(AVG(EXTRACT(DAY FROM
          o.order_delivered_customer_date
        - o.order_purchase_timestamp)), 0)::NUMERIC, 2) AS freight_per_day,
    COUNT(DISTINCT o.order_id)                          AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_freight DESC;
SELECT
    s.seller_state,
    c.customer_state,
    COUNT(DISTINCT o.order_id)                           AS total_orders,
    ROUND(AVG(EXTRACT(DAY FROM
          o.order_delivered_customer_date
        - o.order_purchase_timestamp))::NUMERIC, 2)     AS avg_delivery_days,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2)            AS avg_freight,
    ROUND(COUNT(CASE WHEN o.order_delivered_customer_date
               > o.order_estimated_delivery_date
               THEN 1 END) * 100.0 /
          COUNT(*)::NUMERIC, 2)                         AS late_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY avg_delivery_days DESC
LIMIT 15;