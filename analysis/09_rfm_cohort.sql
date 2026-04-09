WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)          AS last_order_date,
        COUNT(DISTINCT o.order_id)               AS frequency,
        ROUND(SUM(oi.price)::NUMERIC, 2)         AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        last_order_date,
        frequency,
        monetary,
        EXTRACT(DAY FROM
            (SELECT MAX(order_purchase_timestamp) FROM orders)
            - last_order_date)                   AS recency_days,
        NTILE(4) OVER (ORDER BY last_order_date DESC)  AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)         AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)          AS m_score
    FROM rfm_base
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN 'champions'
        WHEN (r_score + f_score + m_score) >= 8  THEN 'loyal_customers'
        WHEN (r_score + f_score + m_score) >= 6  THEN 'potential_loyalists'
        WHEN (r_score + f_score + m_score) >= 4  THEN 'at_risk'
        ELSE                                          'lost'
    END                                          AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total DESC
LIMIT 20;
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)         AS last_order_date,
        COUNT(DISTINCT o.order_id)              AS frequency,
        ROUND(SUM(oi.price)::NUMERIC, 2)        AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('cancelled', 'unavailable')
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY last_order_date DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)        AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)         AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        customer_unique_id,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN (r_score + f_score + m_score) >= 10 THEN 'champions'
            WHEN (r_score + f_score + m_score) >= 8  THEN 'loyal_customers'
            WHEN (r_score + f_score + m_score) >= 6  THEN 'potential_loyalists'
            WHEN (r_score + f_score + m_score) >= 4  THEN 'at_risk'
            ELSE                                          'lost'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    rfm_segment,
    COUNT(*)                                           AS total_customers,
    ROUND(AVG(frequency)::NUMERIC, 2)                 AS avg_orders,
    ROUND(AVG(monetary)::NUMERIC, 2)                  AS avg_spend,
    ROUND(SUM(monetary)::NUMERIC, 2)                  AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY avg_spend DESC;
WITH customer_cohorts AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
),
cohort_data AS (
    SELECT
        co.cohort_month,
        EXTRACT(MONTH FROM AGE(ord.order_month, co.cohort_month)) +
        EXTRACT(YEAR FROM AGE(ord.order_month, co.cohort_month)) * 12
                                                        AS month_number,
        COUNT(DISTINCT ord.customer_unique_id)          AS customers
    FROM customer_cohorts co
    JOIN customer_orders ord ON co.customer_unique_id = ord.customer_unique_id
    GROUP BY co.cohort_month, month_number
)
SELECT
    cohort_month,
    month_number,
    customers,
    FIRST_VALUE(customers) OVER (
        PARTITION BY cohort_month
        ORDER BY month_number
    )                                                   AS cohort_size,
    ROUND(customers * 100.0 / FIRST_VALUE(customers) OVER (
        PARTITION BY cohort_month
        ORDER BY month_number
    )::NUMERIC, 2)                                      AS retention_pct
FROM cohort_data
WHERE month_number <= 6
ORDER BY cohort_month, month_number;