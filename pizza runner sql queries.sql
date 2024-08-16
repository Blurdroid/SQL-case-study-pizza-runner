-- pizza metrics

-- 1) how many pizzas were oredered?
SELECT COUNT(pizza_id) as pizza_count
FROM customer_orders;

-- 2 ) How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM customer_orders;

-- 3) How many successful orders were delivered by each runner?

SELECT 
    runner_id, 
    COUNT(order_id) AS order_count
FROM runner_orders_post
WHERE duration_mins IS NOT NULL
GROUP BY runner_id;

-- 4) How many of each type of pizza was delivered?

-- SELECT COUNT() 
-- FROM 
-- JOIN 
-- ON 
-- WHERE duration_mins IS NOT NULL
-- GROUP BY 


-- 5) how many vegeterian and meatlovers where ordered by each customer?

WITH pizza_vegetarian AS (
   SELECT customer_id, COUNT(pizza_id) AS pizza_count
   FROM customer_orders
   WHERE pizza_id = 2
   GROUP BY customer_id
),

pizza_meatlover AS (
   SELECT customer_id, COUNT(pizza_id) AS pizza_count
   FROM customer_orders
   WHERE pizza_id = 1
   GROUP BY customer_id
)

SELECT DISTINCT m.customer_id, 
       v.pizza_count AS total_vegetarian, 
       m.pizza_count AS total_meatlover
FROM pizza_vegetarian AS v
JOIN pizza_meatlover AS m, 
ON v.customer_id = m.customer_id;

-- 6) What was the maximum number of pizzas delivered in a single order?

SELECT order_id ,COUNT(pizza_id) AS maximum_order
FROM customer_orders
GROUP BY order_id
ORDER BY maximum_order DESC;

-- 7)  For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH pizza_changes_counter AS (
SELECT 
    co.customer_id,
    CASE 
        WHEN co.exclusions_cleaned LIKE '%' OR co.extras_cleaned LIKE '%' THEN 1
        ELSE 0
    END AS pizza_change_count, -- if it have a a value >> 1 then the customer made change
    CASE
        WHEN co.exclusions_cleaned IS NULL AND co.extras_cleaned IS NULL THEN 1
        WHEN co.exclusions_cleaned IS NULL AND co.extras_cleaned = 'NaN' THEN 1
        ELSE 0
    END AS pizza_no_change_count -- if one of these is null then there is no null
FROM cust_orders co
LEFT JOIN runner_orders_post ro 
    ON co.order_id = ro.order_id
WHERE ro.duration_mins IS NOT NULL
)
  
SELECT
    customer_id,
    SUM(pizza_change_count) AS total_pizzas_with_changes,
    SUM(pizza_no_change_count) AS total_pizzas_without_changes
FROM pizza_changes_counter
GROUP BY customer_id;

select * from cust_orders

-- 9)  What was the total volume of pizzas ordered for each hour of the day?

SELECT COUNT(pizza_id) AS order_count, HOUR(order_time) AS hour
FROM cust_orders 
GROUP BY hour;

-- 10) What was the volume of orders for each day of the week?

WITH orders_by_day AS (
SELECT
	COUNT(order_id) AS order_count,
	WEEKDAY(order_time) AS day
FROM cust_orders
GROUP BY day
ORDER BY day
)

SELECT	
	order_count,
    CASE 
	WHEN day = 0 THEN 'Monday'
		WHEN day = 1 THEN 'Tuesday'
	WHEN day = 2 THEN 'Wednesday'
	WHEN day = 3 THEN 'Thursday'
	WHEN day = 4 THEN 'Friday'
	WHEN day = 5 THEN 'Saturday'
	WHEN day = 6 THEN 'Sunday'
   END AS day
FROM orders_by_day;


-- B) runner and customer experience
-- 1) How many runner signed up for each 1 week period? (ie.week starts 2021-01-01)

SELECT COUNT(runner_id) AS total_runner,
       WEEK(registration_date) AS week
FROM runners
GROUP BY week;

-- 2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


SELECT
    r.runner_id,
    AVG(MINUTE(TIMEDIFF(r.pick_up_time, c.order_time))) AS time_mins
FROM cust_orders c
INNER JOIN runner_orders_post r
	ON c.order_id = r.order_id
GROUP BY r.runner_id;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- the data is limited 


-- 4. What was the average distance travelled for each customer?

SELECT
	c.customer_id,
    AVG(r.distance_km) AS avg_dist_km
FROM cust_orders c 
LEFT JOIN runner_orders_post r
	ON c.order_id = r.order_id
GROUP BY c.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration_mins) - MIN(duration_mins) AS delivery_time
FROM runner_orders_post;


-- 6)

SELECT runner_id,
       AVG(distance_km),
       AVG(duration_mins)
FROM runner_orders_post 
GROUP BY runner_id;

-- 7) 

WITH cancellation_counter AS (
SELECT
	runner_id,
    CASE
    	WHEN cancellation IS NULL OR cancellation = 'NaN' THEN 1
	ELSE 0
    END AS no_cancellation_count,
    CASE
    	WHEN cancellation IS NOT NULL OR cancellation != 'NaN' THEN 1
	ELSE 0
    END AS cancellation_count
FROM runner_orders_post
)

SELECT 
	runner_id,
    SUM(no_cancellation_count) / (SUM(no_cancellation_count) + SUM(cancellation_count))*100 AS delivery_success_percentage
FROM cancellation_counter
GROUP BY runner_id;
