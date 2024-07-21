create database pizzahut;
 

select* from pizzas;
select* from pizza_types;
select * from orders;
select * from order_details;

drop table orders;

--Basic
--1. Retrieve the total number of orders placed.

Select count(order_id) as total_ordres from orders;

--2. Calculate the total revenue generated from pizza sales.

SELECT ROUND(SUM(p.price * od.quantity),2) as Total_Revenue
FROM pizzas as p
JOIN order_details as od
ON p.pizza_id = od.pizza_id;

--3. Identify the highest-priced pizza.

SELECT TOP 1 name, price
FROM pizza_types AS pt
JOIN pizzas AS p
ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC ;

--4. Identify the most common pizza size ordered.

Select 
	p.size, 
	count(od.order_details_id) AS order_count
FROM 
	order_details AS od
		JOIN	
			pizzas AS p
	ON od.pizza_id =  p.pizza_id
GROUP BY p.size
ORDER BY order_count DESC;

--5.List the top 5 most ordered pizza types along with their quantities.

Select 
Top 5 pizza_types.name, SUM(order_details.quantity) As quantity
FROM 
pizza_types JOIN pizzas 
ON pizza_types.pizza_type_id =  pizzas.pizza_type_id
JOIN order_details 
ON order_details.pizza_id =  pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC;

--Intermediate:
-- 6 Join the necessary tables to find the total quantity of each pizza category ordered.

Select pizza_types.category, SUM(order_details.quantity) As quantity
FROM pizza_types JOIN pizzas 
ON pizza_types.pizza_type_id =  pizzas.pizza_type_id
JOIN order_details 
ON order_details.pizza_id =  pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY quantity DESC;

--7. Determine the distribution of orders by hour of the day.

Select  DATEPART(HOUR, time) AS hour, count(order_id) AS order_count
from orders
GROUP BY DATEPART(HOUR, time)
ORDER BY hour ASC;

--8.Join relevant tables to find the category-wise distribution of pizzas.

SELECT category, count(name) from pizza_types
GROUP BY category;

--9. Group the orders by date and calculate the average number of pizzas ordered per day.

Select AVG(quantity) from
(Select orders.date, SUM(order_details.quantity) AS quantity
FROM orders JOIN  order_details
ON orders.order_id = order_details.order_id
Group By orders.date ) AS order_quantity;

--10.Determine the top 3 most ordered pizza types based on revenue.

SELECT  TOP 3 pizza_types.name, 
ROUND(SUM(pizzas.price * order_details.quantity),2) as Total_Revenue
FROM pizzas 
JOIN pizza_types  
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details 
ON pizzas .pizza_id = order_details .pizza_id
GROUP BY pizza_types.name
ORDER BY Total_Revenue DESC;

--Advanced:
--11. Calculate the percentage contribution of each pizza type to total revenue.

--Calculate the total revenue for each pizza type.
--Calculate the overall total revenue.
--Compute the percentage contribution of each pizza type to the total revenue.

SELECT pizza_types.category,
ROUND(SUM(order_details.quantity * pizzas.price)/(SELECT 
ROUND(SUM(order_details.quantity * pizzas.price),
2)AS Total_sales
FROM 
 order_details  
 JOIN
pizzas ON pizzas.pizza_id = order_details.pizza_id)* 100, 0) as Revenue
from pizza_types JOIN pizzas
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details
ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category
ORDER BY Revenue DESC;

--12. Analyze the cumulative revenue generated over time.

SELECT date, revenue,
        SUM(revenue) OVER (ORDER BY date) AS cumulative_revenue
		FROM
    (SELECT orders.date,
        ROUND(SUM(order_details.quantity * pizzas.price),2) AS revenue
    FROM 
        order_details
    JOIN 
        pizzas ON order_details.pizza_id = pizzas.pizza_id
	JOIN 
		orders ON orders.order_id = order_details.order_id
    GROUP BY orders.date) AS sales;

-----------------------------------------------------------------------------------------	 
	                          --OR--
-----------------------------------------------------------------------------------------

WITH RevenueByDate AS (
    SELECT date,
         ROUND(SUM(order_details.quantity * pizzas.price),2) AS revenue
    FROM order_details
    JOIN 
        pizzas ON order_details.pizza_id = pizzas.pizza_id
	JOIN 
		orders ON orders.order_id = order_details.order_id
    GROUP BY orders.date
),
CumulativeRevenue AS (
    SELECT date, revenue,
        SUM(revenue) OVER (ORDER BY date) AS cumulative_revenue
    FROM 
        RevenueByDate
)
SELECT date, revenue, cumulative_revenue
FROM CumulativeRevenue
ORDER BY date;

--13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.


SELECT name, revenue from
(SELECT category, name , revenue,
Rank() OVER(PARTITION BY category order by revenue DESC) AS rn 
FROM
(
SELECT category, name,
SUM((order_details.quantity )* pizzas.price) AS revenue
FROM pizzas 
JOIN pizza_types  
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details 
ON pizzas .pizza_id = order_details .pizza_id 
GROUP BY category, name
) AS a) as b
Where rn <= 1;




----------------------------------------------
With RevenueCTE
AS
(
SELECT category, name,
SUM((order_details.quantity )* pizzas.price) AS revenue
FROM pizzas 
JOIN pizza_types  
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details 
ON pizzas .pizza_id = order_details .pizza_id 
GROUP BY category, name
)
-- CTE to rank the pizzas within each category by revenue
RankedCTE AS (
    SELECT category,  name, revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM  RevenueCTE
)
-- Final selection to get the top pizza per category
SELECT name, revenue
FROM RankedCTE
WHERE rn = 1;


