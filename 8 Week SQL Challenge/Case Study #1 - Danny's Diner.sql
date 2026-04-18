/* Case Study Questions */
-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
  customer_id
  , SUM(price) AS total_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT 
  customer_id
  , COUNT(DISTINCT order_date) AS total_visited
FROM dannys_diner.sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_order AS ( 
  SELECT 
    customer_id
    , MIN(order_date) AS first_date_order
  FROM dannys_diner.sales
  GROUP BY customer_id
 )
SELECT 
  first_order.customer_id
  , product_name
FROM first_order
JOIN dannys_diner.sales
  ON first_order.customer_id = sales.customer_id
  AND first_date_order = order_date
JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id;

-- SELECT 
--   sales.customer_id,
--   sales.order_date,
--   menu.product_name
-- FROM dannys_diner.sales
-- JOIN dannys_diner.menu
--   ON sales.product_id = menu.product_id
-- JOIN (
--   SELECT 
--     customer_id,
--     MIN(order_date) AS first_order_date
--   FROM dannys_diner.sales
--   GROUP BY customer_id
-- ) AS first_order
--   ON sales.customer_id = first_order.customer_id
--  AND sales.order_date = first_order.first_order_date
-- ORDER BY sales.customer_id, menu.product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1
  product_name
  , COUNT(*) AS purchase_count
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY purchase_count DESC;

-- WITH item_counts AS (
--   SELECT
--     m.product_name,
--     COUNT(*) AS purchase_count
--   FROM dannys_diner.sales AS s
--   JOIN dannys_diner.menu AS m
--     ON s.product_id = m.product_id
--   GROUP BY m.product_name
-- )
-- SELECT product_name, purchase_count
-- FROM item_counts
-- WHERE purchase_count = (
--   SELECT MAX(purchase_count)
--   FROM item_counts
-- );

-- 5. Which item was the most popular for each customer?
WITH number_order AS (
  SELECT
    customer_id
    , product_name
    , COUNT(*) AS order_count
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
  GROUP BY customer_id, product_name
), 
rank_order AS (
  SELECT 
  customer_id
  , product_name
  , order_count
  , RANK() OVER(PARTITION BY customer_id ORDER BY order_count DESC) AS rank_item
FROM number_order
)
SELECT 
  customer_id
  , product_name
  , order_count
  , rank_item
FROM rank_order
WHERE rank_item = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH member_sales AS (
  SELECT 
    sales.customer_id
    , product_name
    , join_date
    , order_date
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
  JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
  WHERE order_date >= join_date
),
first_member_purchase AS (
  SELECT 
    customer_id
    , MIN(order_date) AS first_order
  FROM member_sales
  GROUP BY customer_id
)
SELECT 
    member_sales.customer_id
    , product_name
    , first_order
    , join_date
FROM first_member_purchase
JOIN member_sales
  ON first_member_purchase.customer_id = member_sales.customer_id
  AND first_order = order_date
ORDER BY member_sales.customer_id, product_name;

-- 7. Which item was purchased just before the customer became a member?
WITH sales_before_membership AS(
  SELECT 
    sales.customer_id
    , product_name
    , join_date
    , order_date
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
  JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
  WHERE order_date < join_date
),
last_pre_member_purchase AS (
  SELECT 
    customer_id
    , MAX(order_date) last_order_date
  FROM sales_before_membership
  GROUP BY customer_id
)
SELECT
  sales_before_membership.customer_id
  , product_name
  , join_date
  , last_order_date
FROM sales_before_membership
JOIN last_pre_member_purchase
  ON sales_before_membership.customer_id = last_pre_member_purchase.customer_id
  AND last_order_date = order_date
ORDER BY sales_before_membership.customer_id, product_name;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
  sales.customer_id,
  COUNT(*) AS total_items,
  SUM(price) AS amount_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
JOIN dannys_diner.members
  ON sales.customer_id = members.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- WITH sales_before_member AS (
--   SELECT *
--   FROM dannys_diner.sales
--   JOIN dannys_diner.menu
--     ON sales.product_id = menu.product_id
--   JOIN dannys_diner.members
--     ON sales.customer_id = members.customer_id
--   WHERE order_date < join_date
-- )
-- SELECT
--   customer_id,
--   COUNT(*) AS total_items,
--   SUM(price) AS amount_spent
-- FROM sales_before_member
-- GROUP BY customer_id
-- ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
  sales.customer_id,
  SUM(
    CASE
      WHEN product_name = 'sushi' THEN price * 20
      ELSE price * 10
    END
  ) AS total_points
FROM dannys_diner.sales 
JOIN dannys_diner.menu 
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
  sales.customer_id,
  SUM(
    CASE
      WHEN order_date >= join_date AND order_date < DATEADD(day, 7, join_date) THEN price * 20
      WHEN product_name = 'sushi' THEN price * 20
      ELSE price * 10
    END
  ) AS total_points
FROM dannys_diner.sales 
JOIN dannys_diner.menu 
  ON sales.product_id = menu.product_id
JOIN dannys_diner.members
  ON sales.customer_id = members.customer_id
WHERE MONTH(order_date) = 1
GROUP BY sales.customer_id
ORDER BY sales.customer_id;
