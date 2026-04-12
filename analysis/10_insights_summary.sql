-- INSIGHT 1: Olist has a severe customer retention problem
-- 96.95% of customers never return after their first purchase
-- SO WHAT: A loyalty program targeting repeat buyers could
-- unlock massive revenue — loyal buyers spend 3x more (R$421 vs R$138)

SELECT
    CASE
        WHEN order_count = 1 THEN 'one_time_buyer'
        WHEN order_count = 2 THEN 'repeat_buyer'
        ELSE 'loyal_buyer_3x_plus'
    END                                                AS segment,
    COUNT(*)                                           AS customers,
    ROUND(AVG(total_spent)::NUMERIC, 2)               AS avg_spend,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)       AS order_count,
        ROUND(SUM(oi.price)::NUMERIC, 2) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
) t
GROUP BY segment
ORDER BY customers DESC;
-- INSIGHT 2: November 2017 Black Friday generated R$1M in a single month
-- 52% MoM growth — single biggest revenue spike in 25 months
-- SO WHAT: Olist should prepare logistics 2 months ahead of Black Friday
-- Late delivery rate jumped to 14.31% that month — needs capacity planning

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
    ROUND((monthly_revenue - LAG(monthly_revenue)
           OVER (ORDER BY order_month)) * 100.0 /
           NULLIF(LAG(monthly_revenue)
           OVER (ORDER BY order_month), 0)::NUMERIC, 2) AS mom_growth_pct
FROM monthly
ORDER BY monthly_revenue DESC
LIMIT 5;
-- INSIGHT 3: SP accounts for 41% of orders and 60% of all sellers
-- Revenue is dangerously concentrated in one state
-- SO WHAT: Expanding seller base in RJ, MG, RS would reduce
-- concentration risk and improve delivery times for other regions

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)                   AS total_revenue,
    ROUND(COUNT(DISTINCT o.order_id) * 100.0 /
          SUM(COUNT(DISTINCT o.order_id)) OVER(), 2)   AS pct_of_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 5;
-- INSIGHT 4: Northeast states have worst delivery performance
-- AL: 23.93% late rate, avg 24 days delivery
-- SP delivers in 8 days — 3x faster than northeast states
-- SO WHAT: Opening fulfilment centres in Recife or Salvador
-- would dramatically improve service for 20M+ potential customers

SELECT
    c.customer_state,
    ROUND(AVG(EXTRACT(DAY FROM
          o.order_delivered_customer_date
        - o.order_purchase_timestamp))::NUMERIC, 2)    AS avg_delivery_days,
    ROUND(COUNT(CASE WHEN o.order_delivered_customer_date
               > o.order_estimated_delivery_date
               THEN 1 END) * 100.0 /
          COUNT(*)::NUMERIC, 2)                        AS late_pct,
    COUNT(*)                                           AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) > 200
ORDER BY late_pct DESC
LIMIT 8;
-- INSIGHT 5: Health & beauty is #1 category by orders in 17/27 states
-- R$1.25M revenue, lowest freight ratio (14.5%) — high margin category
-- SO WHAT: Prioritising health & beauty sellers and expanding
-- this category would maximise both revenue and margins

SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'uncategorized') AS category,
    COUNT(DISTINCT oi.order_id)                        AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2)                   AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                   AS avg_price,
    ROUND(SUM(oi.freight_value) * 100.0 /
          NULLIF(SUM(oi.price), 0)::NUMERIC, 2)        AS freight_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english,
                  p.product_category_name, 'uncategorized')
ORDER BY total_revenue DESC
LIMIT 5;
-- INSIGHT 6: Customers paying in 10 instalments spend 4x more
-- 1 instalment avg R$96 vs 10 instalments avg R$415
-- SO WHAT: Offering more instalment options and partnering
-- with more banks would unlock higher value purchases

SELECT
    payment_installments,
    COUNT(*)                                           AS total_orders,
    ROUND(AVG(payment_value)::NUMERIC, 2)             AS avg_order_value
FROM order_payments
WHERE payment_type = 'credit_card'
  AND payment_installments BETWEEN 1 AND 12
GROUP BY payment_installments
ORDER BY payment_installments;
-- INSIGHT 7: 18 platinum sellers generate 19% of total revenue
-- Top 40 sellers (platinum + gold) = 28% of platform revenue
-- SO WHAT: Protecting and growing these sellers is critical
-- Losing one platinum seller = losing ~R$150K average revenue

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
    ROUND(SUM(total_revenue)::NUMERIC, 2)             AS tier_revenue,
    ROUND(SUM(total_revenue) * 100.0 /
          SUM(SUM(total_revenue)) OVER()::NUMERIC, 2) AS pct_of_revenue
FROM seller_revenue
GROUP BY seller_tier
ORDER BY tier_revenue DESC;
-- INSIGHT 8: Olist estimates 23 days but delivers in 12 days on average
-- Delivering 11 days earlier than promised — a massive trust builder
-- SO WHAT: Tightening delivery estimates would set accurate expectations
-- and allow Olist to market its speed as a competitive advantage

SELECT
    ROUND(AVG(EXTRACT(DAY FROM
          order_delivered_customer_date
        - order_purchase_timestamp))::NUMERIC, 2)     AS actual_days,
    ROUND(AVG(EXTRACT(DAY FROM
          order_estimated_delivery_date
        - order_purchase_timestamp))::NUMERIC, 2)     AS estimated_days,
    ROUND(AVG(EXTRACT(DAY FROM
          order_estimated_delivery_date
        - order_delivered_customer_date))::NUMERIC, 2) AS days_saved,
    ROUND(COUNT(CASE WHEN order_delivered_customer_date
               <= order_estimated_delivery_date
               THEN 1 END) * 100.0 /
          COUNT(*)::NUMERIC, 2)                       AS on_time_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
-- INSIGHT 9: Several high-volume sellers have critically low ratings
-- Campinas seller: R$41K revenue but 2.71 rating (198 orders)
-- Santana de Parnaiba: 2.20 rating — worst rated high volume seller
-- SO WHAT: Implementing a seller quality score threshold
-- would protect brand reputation at the cost of minimal revenue

WITH seller_stats AS (
    SELECT
        oi.seller_id,
        s.seller_city,
        s.seller_state,
        ROUND(SUM(oi.price)::NUMERIC, 2)       AS total_revenue,
        COUNT(DISTINCT oi.order_id)             AS total_orders,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score
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
LIMIT 5;
-- INSIGHT 10: Champions (24.70% of customers) generate 48% of revenue
-- Average champion spends R$275 vs R$29 for lost customers
-- SO WHAT: A VIP program for champions with early access,
-- exclusive deals and dedicated support would protect R$6.5M revenue

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
        monetary,
        NTILE(4) OVER (ORDER BY last_order_date DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)        AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)         AS m_score
    FROM rfm_base
)
SELECT
    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN 'champions'
        WHEN (r_score + f_score + m_score) >= 8  THEN 'loyal_customers'
        WHEN (r_score + f_score + m_score) >= 6  THEN 'potential_loyalists'
        WHEN (r_score + f_score + m_score) >= 4  THEN 'at_risk'
        ELSE                                          'lost'
    END                                                AS rfm_segment,
    COUNT(*)                                           AS total_customers,
    ROUND(AVG(monetary)::NUMERIC, 2)                  AS avg_spend,
    ROUND(SUM(monetary)::NUMERIC, 2)                  AS total_revenue,
    ROUND(SUM(monetary) * 100.0 /
          SUM(SUM(monetary)) OVER()::NUMERIC, 2)      AS pct_of_revenue
FROM rfm_scores
GROUP BY rfm_segment
ORDER BY total_revenue DESC;