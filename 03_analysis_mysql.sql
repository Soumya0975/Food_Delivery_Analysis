USE india_food;

-- 1. Top 10 products by revenue and gross margin
SELECT p.product_name, p.category,
       SUM(oi.quantity) AS units,
       SUM(oi.quantity*oi.unit_price_inr) AS revenue_inr,
       SUM(oi.quantity*(oi.unit_price_inr-p.cost_inr)) AS gross_margin_inr,
       ROUND(100*SUM(oi.quantity*(oi.unit_price_inr-p.cost_inr))/SUM(oi.quantity*oi.unit_price_inr),1) AS margin_pct
FROM order_item oi JOIN product p USING (product_id)
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue_inr DESC LIMIT 10;

-- 2. Monthly revenue with MoM growth (window function)
WITH m AS (
  SELECT DATE_FORMAT(o.order_date,'%Y-%m-01') AS month,
         SUM(oi.quantity*oi.unit_price_inr) AS revenue
  FROM orders o JOIN order_item oi USING (order_id) GROUP BY 1)
SELECT month, revenue,
       ROUND(100*(revenue-LAG(revenue) OVER (ORDER BY month))/LAG(revenue) OVER (ORDER BY month),1) AS mom_pct,
       ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),0) AS ma3
FROM m ORDER BY month;

-- 3. Repeat-customer percentage
SELECT ROUND(100*SUM(n>1)/COUNT(*),1) AS repeat_customer_pct
FROM (SELECT customer_id, COUNT(*) n FROM orders GROUP BY customer_id) t;

-- 4. Busiest week of month (day-of-month buckets)
SELECT CEIL(DAY(order_date)/7) AS week_of_month, COUNT(*) AS orders
FROM orders GROUP BY 1 ORDER BY 1;

-- 5. City-wise AOV, order count, avg rating
SELECT c.city, COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.quantity*oi.unit_price_inr)/COUNT(DISTINCT o.order_id),0) AS aov_inr,
       ROUND(AVG(o.rating),2) AS avg_rating
FROM customers c JOIN orders o USING (customer_id) JOIN order_item oi USING (order_id)
GROUP BY c.city ORDER BY orders DESC;

-- 6. Referral effectiveness: referred vs organic customers
SELECT (c.referred_by IS NOT NULL) AS referred, COUNT(DISTINCT c.customer_id) AS customers,
       ROUND(COUNT(o.order_id)/COUNT(DISTINCT c.customer_id),2) AS orders_per_customer
FROM customers c LEFT JOIN orders o USING (customer_id) GROUP BY 1;

-- 7. Rank products within category (top 3 each)
SELECT * FROM (
  SELECT p.category, p.product_name, SUM(oi.quantity) units,
         DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity) DESC) rnk
  FROM order_item oi JOIN product p USING (product_id) GROUP BY p.category, p.product_name) r
WHERE rnk <= 3 ORDER BY category, rnk;

-- 8. Cohort retention by signup month (months since signup)
SELECT DATE_FORMAT(c.signup_date,'%Y-%m') AS cohort,
       TIMESTAMPDIFF(MONTH, DATE_FORMAT(c.signup_date,'%Y-%m-01'), DATE_FORMAT(o.order_date,'%Y-%m-01')) AS month_n,
       COUNT(DISTINCT c.customer_id) AS active_customers
FROM customers c JOIN orders o USING (customer_id)
GROUP BY 1,2 ORDER BY 1,2;

-- 9. Payment-method mix and avg tip
SELECT payment_method, COUNT(*) orders, ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (),1) pct, ROUND(AVG(tip_inr),1) avg_tip
FROM orders GROUP BY payment_method ORDER BY orders DESC;

-- 10. Simple sentiment bucket from rating
SELECT CASE WHEN rating>=4 THEN 'Positive' WHEN rating=3 THEN 'Neutral' WHEN rating<=2 THEN 'Negative' ELSE 'Unrated' END AS sentiment,
       COUNT(*) orders, ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (),1) pct
FROM orders GROUP BY 1;
