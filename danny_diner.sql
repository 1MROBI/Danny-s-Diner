



/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) 'total_spend'
FROM sales,menu
WHERE sales.product_id = menu.product_id
GROUP BY customer_id;
-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) 'total_days'
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH cte_table AS (
SELECT customer_id,order_date,menu.product_name, ROW_NUMBER() OVER(PARTITION BY customer_id) 'ranks'
FROM sales,menu
WHERE sales.product_id = menu.product_id
ORDER BY customer_id,order_date )

SELECT customer_id,order_date,product_name FROM cte_table WHERE ranks = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name ,COUNT(customer_id) 'total_orders'
FROM sales s, menu m 
WHERE s.product_id = m.product_id
GROUP BY m.product_name 
ORDER BY total_orders DESC 
LIMIT 1  ;


-- 5. Which item was the most popular for each customer?
WITH cte_table AS(
SELECT m.product_name,s.customer_id,COUNT(order_date) 'count', ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(order_date) DESC) 'rnk'
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name,s.customer_id
ORDER BY s.customer_id ,rnk)
SELECT customer_id, product_name
FROM cte_table
WHERE rnk = 1;


-- 6. Which item was purchased first by the customer after they became a member?
WITH cte_table AS(
SELECT s.customer_id,
m.product_name,
s.order_date,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) 'rnk'
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
INNER JOIN members mem
ON s.customer_id = mem.customer_id
WHERE s.order_date >= join_date
ORDER BY s.customer_id,s.order_date ASC)

SELECT customer_id,product_name,order_date
FROM cte_table
WHERE rnk = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH cte_table AS
(SELECT s.customer_id,m.product_name,order_date,DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) 'rnk'
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
INNER JOIN members mem ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date)

SELECT customer_id, product_name
FROM cte_table
WHERE rnk = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) 'total_items', SUM(m.price) 'total_spend'
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date
group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_table AS (
SELECT s.customer_id,m.product_name ,m.price,
CASE 
WHEN m.product_name = 'sushi' THEN m.price*10*2
ELSE m.price*10
END AS 'points'
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
)

SELECT customer_id, SUM(points) 'total_points'
FROM cte_table
GROUP by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte_table AS 
(
SELECT s.customer_id, 
CASE 
WHEN s.order_date BETWEEN mem.join_date AND (mem.join_date + INTERVAL 6 DAY) THEN m.price*10*2
WHEN m.product_name = 'sushi' THEN m.price*10*2
ELSE m.price*10
END AS 'points'
FROM sales s 
INNER JOIN menu m
ON s.product_id = m.product_id
INNER JOIN members mem
ON s.customer_id= mem.customer_id
WHERE s.order_date <= '2021-01-31'
)
SELECT customer_id, SUM(points) 'Total_points'
FROM cte_table
GROUP BY customer_id



-- BONUS QUESTION 
-- Q1 Join All The Things

SELECT sales.customer_id,sales.order_date,menu.product_name,menu.price, 
CASE 
WHEN members.customer_id = sales.customer_id AND sales.order_date>=members.join_date THEN 'Y'
ELSE 'N'
END AS 'member'
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id

-- Q2 Rank All The Things

WITH cte_table AS (
SELECT sales.customer_id,sales.order_date,menu.product_name,menu.price, 
CASE 
WHEN members.customer_id = sales.customer_id AND sales.order_date>=members.join_date THEN 'Y'
ELSE 'N'
END AS 'member'
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id )

SELECT *,
CASE 
WHEN member = 'N' THEN NULL
ELSE DENSE_RANK() OVER (PARTITION BY customer_id,member ORDER BY order_date) 
END AS 'rnk'
FROM cte_table
------------------------------------------------------------------------------------------------------------------------------------
USE danny_dinner
SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales

