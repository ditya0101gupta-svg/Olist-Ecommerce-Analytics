## 1. Calculate first 3 business KPIs

USE olist_ecommerce;
SELECT
    ROUND(SUM(payment_value), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        SUM(payment_value) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM olist_order_payments_dataset;



## 2. Monthly Revenue Trend Analysis

USE olist_ecommerce;
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.order_payment), 2) AS monthly_revenue
FROM olist_orders_dataset AS o
INNER JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment
    FROM olist_order_payments_dataset
    GROUP BY order_id
) AS p
    ON o.order_id = p.order_id
GROUP BY
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY
    order_month;
    
    
    
## 3. Find the highest and lowest revenue months

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.order_payment), 2) AS monthly_revenue
FROM olist_orders_dataset AS o
INNER JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment
    FROM olist_order_payments_dataset
    GROUP BY order_id
) AS p
    ON o.order_id = p.order_id
GROUP BY
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY
    monthly_revenue DESC;
    
-- Business insight: November 2017 generated the highest recorded monthly payment value, approximately R$1.19 million, with 7,544 orders.
-- This may reflect seasonal shopping activity, but we would need further analysis to establish the cause.

DESCRIBE product_category_name_translation;

ALTER TABLE product_category_name_translation
RENAME COLUMN `ï»¿product_category_name`
TO product_category_name;



## 4. Top 10 Product Categories by Sales

USE olist_ecommerce;
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM olist_order_items_dataset AS oi

INNER JOIN olist_products_dataset AS p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name

GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY total_sales DESC
LIMIT 10;



## 5. Customer Analysis by State

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.order_payment), 2) AS total_revenue
FROM olist_customers_dataset AS c

INNER JOIN olist_orders_dataset AS o
    ON c.customer_id = o.customer_id

INNER JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment
    FROM olist_order_payments_dataset
    GROUP BY order_id
) AS p
    ON o.order_id = p.order_id

GROUP BY c.customer_state
ORDER BY total_revenue DESC;



## 6. Analyze your Top 5 States

-- Rank	 |  State	             |  Customers	| Revenue (R$)
-- 1	 | São Paulo (SP)	     |  40,301	    | 5,998,226.96
-- 2	 | Rio de Janeiro (RJ)	 |  12,384	    | 2,144,379.69
-- 3	 | Minas Gerais (MG)	 |  11,259	    | 1,872,257.26
-- 4	 | Rio Grande do Sul (RS)| 	5,277	    | 890,898.54
-- 5	 | Paraná (PR)	         |  4,882	    | 811,156.38
-- Business insight: São Paulo is the largest market, generating approximately 37.5% of total recorded payment value. 
-- This suggests that customer demand is concentrated in São Paulo.



## 7. Analyze Order Status

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_orders_dataset),
        2
    ) AS percentage_of_orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;

-- Delivered orders:- 97.02% , 96,478 orders
-- Canceled orders:- 0.63% , 625 orders
-- Business insight: Approximately 97% of recorded orders have a delivered status. This is a strong historical completion rate,
-- although the dataset also contains orders that were still in progress when the data was captured.
 
 
 
 ## 8. On-Time vs Late Delivery Analysis
 
 SELECT
    CASE
        WHEN DATE(order_delivered_customer_date)
             <= DATE(order_estimated_delivery_date)
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM olist_orders_dataset
            WHERE order_status = 'delivered'
              AND order_delivered_customer_date IS NOT NULL
              AND order_delivered_customer_date <> ''
              AND order_estimated_delivery_date IS NOT NULL
        ),
        2
    ) AS percentage

FROM olist_orders_dataset

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> ''
  AND order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_status
ORDER BY total_orders DESC;

-- On-time delivery rate:- 93.23% , 89,936 orders
-- Late delivery rate:- 6.77% , 6,534 orders
-- Business insight: Approximately 93 out of every 100 delivered orders arrived on or before their estimated delivery date.
-- Eight delivered orders were excluded because they lacked usable delivery dates.



## 9. Average Delivery Time Analysis

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                HOUR,
                order_purchase_timestamp,
                order_delivered_customer_date
            )
        ) / 24,
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                HOUR,
                order_purchase_timestamp,
                order_estimated_delivery_date
            )
        ) / 24,
        2
    ) AS avg_estimated_days

FROM olist_orders_dataset

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> ''
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
  
-- Average actual delivery:- 12.54 days
-- Average estimated delivery:- 23.72 days
-- Difference between averages:- 11.18 days
-- Actual deliveries averaged 11.18 days less than the estimated delivery window.
-- Business insight: On average, customers received their orders considerably earlier than the estimated delivery date.
-- This supports the 93.23% on-time delivery rate we calculated earlier.



## 10. Customer Satisfaction Analysis

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_order_reviews_dataset),
        2
    ) AS percentage_of_reviews
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score DESC;

-- Business insight: 77.07% of reviews are positive (4 or 5 stars), while 14.69% are negative (1 or 2 stars).
-- This indicates generally favorable customer feedback, although the number of 1-star reviews deserves further investigation.



## 11. Average Customer Rating

SELECT
    COUNT(*) AS total_reviews,

    ROUND(AVG(review_score), 2)
        AS average_rating,

    SUM(CASE
        WHEN review_score >= 4 THEN 1
        ELSE 0
    END) AS positive_reviews,

    ROUND(
        SUM(CASE
            WHEN review_score >= 4 THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS positive_review_percentage

FROM olist_order_reviews_dataset;

-- Average customer rating:- 4.09 / 5
-- Positive review rate:- 77.07%
-- Total reviews:- 99,223
-- Positive reviews:- 76,469
-- Business insight: Customers gave an average rating of 4.09 out of 5, with more than three-quarters of reviews rated 4 or 5 stars.



## 12. Does Late Delivery Affect Customer Ratings?

WITH order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM olist_order_reviews_dataset
    GROUP BY order_id
)

SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date)
             <= DATE(o.order_estimated_delivery_date)
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS reviewed_orders,
    
    ROUND(AVG(r.review_score), 2) AS avg_rating,

    ROUND(
        SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS positive_review_percentage

FROM olist_orders_dataset AS o

INNER JOIN order_reviews AS r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date <> ''
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_status
ORDER BY avg_rating DESC;

-- Business insights
--  Customers receiving orders on time gave an average rating of 4.29, compared with 2.27 for late deliveries.
--  On-time orders had a 2.02-point higher average rating.
--  Positive reviews were 55.90 percentage points higher for on-time deliveries.
-- Business recommendation: Improving delivery reliability could help increase customer satisfaction.
-- These results show a strong association, although they don't prove causation.



## 13. Analyze Payment Methods

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    ROUND(
        SUM(payment_value) * 100.0 /
        (SELECT SUM(payment_value)
         FROM olist_order_payments_dataset),
        2
    ) AS revenue_percentage

FROM olist_order_payments_dataset

GROUP BY payment_type

ORDER BY total_revenue DESC;

-- Business insight: Credit cards account for 78.34% of recorded payment revenue, making them the dominant payment method.
--  Boleto is the second-largest contributor at 17.92%.
-- This suggests that credit card payment reliability is particularly important for the business.



## 14. Seller Performance Analysis

SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.price), 2) AS avg_item_price

FROM olist_order_items_dataset AS oi

GROUP BY oi.seller_id

ORDER BY total_sales DESC

LIMIT 10;

-- Business insight: The highest-revenue seller is not necessarily the seller with the most orders.
-- Some sellers generate high revenue through higher-priced products, while others rely on greater sales volume.



## 15. Analyze Seller Performance by State

SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS total_sellers,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS total_sales

FROM olist_order_items_dataset AS oi

INNER JOIN olist_sellers_dataset AS s
    ON oi.seller_id = s.seller_id

GROUP BY s.seller_state

ORDER BY total_sales DESC;

-- Business insight: São Paulo dominates seller activity, with substantially more sellers and product sales than any other state.
-- This indicates a strong concentration of marketplace supply in São Paulo.



## 16. Freight Cost Analysis

SELECT
    c.customer_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_per_item,
    ROUND(
        SUM(oi.freight_value) /
        COUNT(DISTINCT oi.order_id),
        2
    ) AS avg_freight_per_order

FROM olist_order_items_dataset AS oi

INNER JOIN olist_orders_dataset AS o
    ON oi.order_id = o.order_id

INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state

ORDER BY avg_freight_per_order DESC;

-- Business insight: Roraima has the highest average freight cost per order, while Paraíba is close behind.
-- Shipping costs vary considerably by state, suggesting opportunities to investigate delivery distances, carrier pricing, and logistics efficiency.



## 17. Freight Cost as a Percentage of Product Sales

SELECT
    c.customer_state,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    ROUND(SUM(oi.price), 2) AS product_sales,

    ROUND(SUM(oi.freight_value), 2) AS total_freight,

    ROUND(
        SUM(oi.freight_value) * 100.0 /
        NULLIF(SUM(oi.price), 0),
        2
    ) AS freight_to_sales_percentage

FROM olist_order_items_dataset AS oi

INNER JOIN olist_orders_dataset AS o
    ON oi.order_id = o.order_id

INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state

ORDER BY freight_to_sales_percentage DESC;

-- Business insight: Roraima has the highest freight-to-sales ratio at 28.55%. This means customers incurred approximately R$28.55 in freight charges
-- for every R$100 in product sales in that state.
-- Roraima has only 46 orders in this dataset, so its percentage should be interpreted cautiously.