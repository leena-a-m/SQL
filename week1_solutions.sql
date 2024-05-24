/* --------------------
   WEEK1: Danny's Diner
   --------------------*/

-- Question 1: What is the total amount each customer spent at the restaurant?
SELECT
  	customer_id,
   SUM(price) AS sales_sum
FROM week1.sales AS sales
LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- Question 2: How many days has each customer visited the restaurant?
WITH visits_per_day AS (
   SELECT
      customer_id,
      COUNT(order_date) orders_per_day
   FROM week1.sales AS sales
   GROUP BY customer_id, order_date
   )
SELECT 
   customer_id, 
   COUNT(orders_per_day) AS visit_days 
FROM visits_per_day
GROUP BY customer_id;

-- Question 3: What was the first item from the menu purchased by each customer?
WITH first_items AS (
   SELECT
      sales.customer_id,
      menu.product_name,
      ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS rank
   FROM week1.sales AS sales
   LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
   QUALIFY rank = 1
   ORDER BY
      sales.customer_id
   )
SELECT
   customer_id, 
   product_name
FROM first_items;

-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
   menu.product_name,
   COUNT(sales.product_id) AS sales_total
FROM week1.sales AS sales
LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
GROUP BY sales.product_id, menu.product_name
ORDER BY sales_total DESC
LIMIT 1;

-- Question 5: Which item was the most popular for each customer?
WITH total_sales AS (
   SELECT
      sales.customer_id,
      menu.product_name,
      COUNT(sales.product_id) as total_sales,
      RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id)) AS rank
   FROM week1.sales AS sales
   LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
   GROUP BY sales.customer_id, menu.product_name
   QUALIFY rank = 1
   ORDER BY
      sales.customer_id
   )
SELECT customer_id, product_name FROM total_sales;

-- Question 6: Which item was purchased first by the customer after they became a member?
WITH first_product AS (
   SELECT
      sales.customer_id,
      menu.product_name,
      ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS rank
   FROM 
      week1.sales AS sales
   LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
   LEFT JOIN week1.members as members ON sales.customer_id = members.customer_id
   WHERE sales.order_date >= members.join_date
   QUALIFY rank = 1
   )
SELECT customer_id, product_name FROM first_product;

-- 7. Which item was purchased just before the customer became a member?
WITH rank_and_order AS (
   SELECT
      sales.customer_id AS customer_id,
      menu.product_name AS product_name,
      RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS rank,
      ROW_NUMBER() OVER(PARTITION BY sales.customer_id, sales.order_date) AS order_number_per_day
   FROM 
      week1.sales AS sales
   LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
   LEFT JOIN week1.members as members ON sales.customer_id = members.customer_id
   WHERE sales.order_date < members.join_date
   QUALIFY rank = 1
   )
SELECT
   base_table.customer_id,
   base_table.product_name
FROM rank_and_order AS base_table
JOIN (
   SELECT customer_id, MAX(order_number_per_day) last_order_of_day
   FROM rank_and_order
   GROUP BY customer_id) AS table_last_orders
ON base_table.order_number_per_day = last_order_of_day AND
   base_table.customer_id = table_last_orders.customer_id
ORDER BY base_table.customer_id;

-- Question 8: What is the total items and amount spent for each member before they became a member?

SELECT
   sales.customer_id AS customer_id,
   COUNT(sales.product_id) AS total_items,
   SUM(menu.price) AS amount_spent
FROM 
   week1.sales AS sales
LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
LEFT JOIN week1.members as members ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;

-- Question 9:  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
   sales.customer_id AS customer_id,
   SUM(
   CASE
      WHEN menu.product_name = "sushi"
         THEN 20*menu.price
      ELSE 10*menu.price
   END
   ) AS points_total
FROM week1.sales AS sales
LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
   sales.customer_id AS customer_id,
   SUM(
   CASE
      WHEN sales.order_date BETWEEN members.join_date AND DATE_ADD(members.join_date, INTERVAL 7 DAY)
         THEN 20*menu.price
      WHEN menu.product_name = "sushi"
         THEN 20*menu.price
      ELSE 10*menu.price
   END
   ) AS points_total
FROM week1.sales AS sales
LEFT JOIN week1.menu AS menu ON sales.product_id = menu.product_id
LEFT JOIN week1.members as members ON sales.customer_id = members.customer_id
WHERE sales.order_date < "2021-02-01"
GROUP BY customer_id
HAVING customer_id ="A" OR customer_id = "B";

