-- Sales analysis queries (SQLite syntax; work in PostgreSQL/MySQL with small date-function changes)
-- Revenue = price * quantity * (1 - discount), excluding returned orders.

-- Q1. Headline KPIs
SELECT COUNT(*)                                                     AS orders,
       ROUND(SUM(CASE WHEN o.returned = 0 THEN p.price * o.quantity * (1 - o.discount_pct/100.0) END)) AS net_revenue,
       ROUND(AVG(CASE WHEN o.returned = 0 THEN p.price * o.quantity * (1 - o.discount_pct/100.0) END)) AS avg_order_value,
       ROUND(100.0 * SUM(o.returned) / COUNT(*), 1)                 AS return_rate_pct
FROM orders o JOIN products p USING (product_id);

-- Q2. Monthly revenue trend (returns excluded)
SELECT strftime('%Y-%m', order_date) AS month,
       ROUND(SUM(p.price * o.quantity * (1 - o.discount_pct/100.0))) AS revenue
FROM orders o JOIN products p USING (product_id)
WHERE o.returned = 0
GROUP BY month ORDER BY month;

-- Q3. Revenue and share by category
SELECT p.category,
       ROUND(SUM(p.price * o.quantity * (1 - o.discount_pct/100.0))) AS revenue,
       ROUND(100.0 * SUM(p.price * o.quantity * (1 - o.discount_pct/100.0))
             / SUM(SUM(p.price * o.quantity * (1 - o.discount_pct/100.0))) OVER (), 1) AS share_pct
FROM orders o JOIN products p USING (product_id)
WHERE o.returned = 0
GROUP BY p.category ORDER BY revenue DESC;

-- Q4. Channel performance
SELECT channel, COUNT(*) AS orders,
       ROUND(SUM(p.price * o.quantity * (1 - o.discount_pct/100.0))) AS revenue,
       ROUND(AVG(p.price * o.quantity * (1 - o.discount_pct/100.0))) AS avg_order_value
FROM orders o JOIN products p USING (product_id)
WHERE o.returned = 0
GROUP BY channel ORDER BY revenue DESC;

-- Q5. Top 3 products per month (window function)
WITH monthly AS (
  SELECT strftime('%Y-%m', order_date) AS month, p.product_name,
         SUM(p.price * o.quantity * (1 - o.discount_pct/100.0)) AS revenue
  FROM orders o JOIN products p USING (product_id)
  WHERE o.returned = 0
  GROUP BY month, p.product_name)
SELECT month, product_name, ROUND(revenue) AS revenue, rnk
FROM (SELECT *, RANK() OVER (PARTITION BY month ORDER BY revenue DESC) AS rnk FROM monthly)
WHERE rnk <= 3 ORDER BY month, rnk;

-- Q6. Revenue by city
SELECT c.city, COUNT(DISTINCT o.customer_id) AS customers,
       ROUND(SUM(p.price * o.quantity * (1 - o.discount_pct/100.0))) AS revenue
FROM orders o JOIN products p USING (product_id) JOIN customers c USING (customer_id)
WHERE o.returned = 0
GROUP BY c.city ORDER BY revenue DESC;

-- Q7. Repeat customers: how many customers ordered more than once
SELECT CASE WHEN n = 1 THEN '1 order' WHEN n BETWEEN 2 AND 3 THEN '2-3 orders' ELSE '4+ orders' END AS bucket,
       COUNT(*) AS customers
FROM (SELECT customer_id, COUNT(*) AS n FROM orders GROUP BY customer_id)
GROUP BY bucket ORDER BY MIN(n);

-- Q8. Return rate by product (quality check)
SELECT p.product_name, COUNT(*) AS orders,
       ROUND(100.0 * SUM(o.returned) / COUNT(*), 1) AS return_rate_pct
FROM orders o JOIN products p USING (product_id)
GROUP BY p.product_name ORDER BY return_rate_pct DESC;
