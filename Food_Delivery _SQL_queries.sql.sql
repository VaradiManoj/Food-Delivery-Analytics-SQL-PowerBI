/* ============================================================
   Food Delivery Analytics - Business Question Queries
   Tables: customers, restaurants, orders, deliveries, riders
   ============================================================ */

--Total number of customers.

---approach 1---
SELECT count(customer_id) as total_customers
from customers

---approach 2---
SELECT count(*) as total_customers
from customers

--Total number of restaurants.

select count(*) as restaurant_count from restaurants

--Total number of orders.

select count(order_id) as  total_orders from orders

--Customers who have placed at least one order.

select c.customer_id,c.customer_name 
from customers as c join orders as o
on c.customer_id=o.customer_id 

--Top customers who order the most.

select top 10 c.customer_id,c.customer_name,count(o.order_id) as total_orders
from customers as c join orders as o
on c.customer_id=o.customer_id
group by c.customer_id,c.customer_name
order by total_orders desc


--Most ordered item.

select order_item,count(order_item) as total_order_count
from orders
group by order_item
order by total_order_count desc

--Most chosen restaurant and items they provide.

---approach 1--- (raw list, one row per order item)
select r.restaurant_name, o.order_item 
from restaurants as r join orders as o
on r.restaurant_id=o.restaurant_id

---approach 2--- (all items per restaurant combined into one string)
select r.restaurant_name, string_agg(o.order_item , ' ,')as items_list
from restaurants as r join orders as o
on r.restaurant_id=o.restaurant_id
group by r.restaurant_name

---approach 3--- (ranked by item count, most chosen first)
select r.restaurant_name, count(o.order_item) as total_items_count
from restaurants as r join orders as o
on r.restaurant_id=o.restaurant_id
group by r.restaurant_name
order by total_items_count desc

--Restaurants that have no orders

select r.restaurant_name from 
restaurants as r left join orders as o
on r.restaurant_id = o.restaurant_id
where o.restaurant_id is NULL

--Least selling item.

with Item_sales
as (select order_item,count(*) as item_sales_count
    from orders
	group by order_item)
select * from
        (select *,order_item as least_selling_items,ROW_NUMBER() OVER(order by item_sales_count asc) as rnk
         from Item_sales) as r
		 where rnk<=3

--Monthly restaurant growth with Revenue.

with monthly_sales
as
   (select r.restaurant_id,r.restaurant_name,year(o.order_date) as year,month(o.order_date) as monthno, format(o.order_date,'MMM') as month,sum(o.total_amount) as total_amount
	from restaurants as r join orders as o
	on r.restaurant_id = o.restaurant_id
	group by r.restaurant_id,r.restaurant_name,year(o.order_date),month(o.order_date), format(o.order_date,'MMM')
	)

select r.restaurant_name,
	   m.year,
	   m.month,
	   m.total_amount,
	   LAG(m.total_amount) OVER(partition by r.restaurant_name 
	                            order by m.year,m.monthno asc) as previous_month_growth,
	   m.total_amount-LAG(m.total_amount) OVER(partition by r.restaurant_name 
											   order by m.year,m.monthno asc) as monthly_growth
from restaurants as r join monthly_sales as m
on r.restaurant_id=m.restaurant_id

--Monthly restaurant growth with orders

with sales_orders
as(select r.restaurant_id,
	      r.restaurant_name,
		  year(o.order_date) as Year,
		  month(o.order_date) as monthno,
		  Format(o.order_date,'MMM') as month,
		  count(o.order_id) as total_orders
	from restaurants as r join orders as o
	on r.restaurant_id = o.restaurant_id
	group by r.restaurant_id,
	         r.restaurant_name,
			 year(o.order_date),
		     month(o.order_date),
		     Format(o.order_date,'MMM')
			 )

	select r.restaurant_name,
	       s.year,
		   s.month,
		   s.total_orders,
		   LAG(s.total_orders) over(partition by r.restaurant_name order by s.year,s.monthno) as Previous_month_orders,
		   s.total_orders-LAG(s.total_orders) over(partition by r.restaurant_name order by s.year,s.monthno) as monthly_growth
	from restaurants as r join sales_orders  as s
	on r.restaurant_id = s.restaurant_id

--Orders/items not delivered.

select o.order_item
from orders as o join deliveries as d
on o.order_id = d.order_id
where d.delivery_status = 'Not Delivered'


--Delivery time and fastest delivered items.

select o.order_item,d.delivery_time,ROW_NUMBER() OVER(order by d.delivery_time asc) as Fast_deliveries
from orders as o join deliveries as d
on o.order_id=d.order_id
where delivery_time is not null

--Daily sales amount by item.

select order_item,
       order_date,
	   datename(dw,order_date) as day,
	   sum(total_amount) as sale_amount_by_item
from orders
group by order_item,
         order_date,
         datename(dw,order_date)

order by order_date
 
--City-wise orders.

select r.city,count(o.order_id) as number_of_orders
from restaurants as r join Orders as o
on r.restaurant_id = o.restaurant_id
group by r.city

--Peak order timings.

select DATEPART(HOUR, order_time) as order_hour,
       count(order_id) as no_of_orders
from orders
group by DATEPART(HOUR, order_time)
order by no_of_orders desc

--Riders with most deliveries.

select r.rider_name,count(d.delivery_id) as Most_deliverie
from riders as r join deliveries as d
on r.rider_id = d.rider_id
where d.delivery_status= 'delivered'
group by r.rider_name
order by Most_deliverie desc


--Riders with Not deliveries.
select r.rider_name,count(d.delivery_id) as Most_deliverie
from riders as r join deliveries as d
on r.rider_id = d.rider_id
where d.delivery_status= 'Not delivered'
group by r.rider_name
order by Most_deliverie desc

--Total revenue.

select sum(total_amount) as Total_revenue
from orders 

--Restaurant-wise Total revenue.

select r.restaurant_name,sum(o.total_amount) as total_revenue
from restaurants as r join orders as o
on r.restaurant_id = o.restaurant_id
group by r.restaurant_name

--Average order value.

select CAST(avg(total_amount) as decimal(10,2)) as 
Average_order_value
from orders

--Order status distribution (Completed, Cancelled, Pending).

select order_status,count(order_id) as Total_orders
from orders
group by order_status


--Monthly order trend.

select year(order_date) as year,
	   month(order_date) as monthno,
	   format(order_date,'MMM') as month,
	   count(order_id) as monthly_trend
 from orders
       group by year(order_date),
	            month(order_date),
				format(order_date,'MMM')
	   order by year,
	            monthno

--Restaurant-wise revenue (with restaurant_id included).

select r.restaurant_id,
       r.restaurant_name,
	   sum(o.total_amount) as total_revenue
from restaurants as r join orders as o
on r.restaurant_id = o.restaurant_id
group by r.restaurant_id,
         r.restaurant_name

--Customer-wise total spending.
select c.customer_name,
       sum(o.total_amount) as total_spending_amount
from customers as c join orders as o
on c.customer_id = o.customer_id
group by c.customer_name

--Repeat customers (customers with more than one order).

select c.customer_id,
       c.customer_name,
       count(o.order_id) as morethan_one_orders
from customers as c join orders as o
    on c.customer_id = o.customer_id
  group by c.customer_id,
           c.customer_name
  HAVING count(o.order_id) >1


--Average delivery time by restaurant.

select r.restaurant_name,
	   AVG(CASE when
	            DATEDIFF(MINUTE,o.order_time,d.delivery_time) <0 
			THEN 
			    DATEDIFF(MINUTE,o.order_time,d.delivery_time) + 1440
		    ELSE DATEDIFF(MINUTE,o.order_time,d.delivery_time)
			END) as Average_delivery_time 
 from restaurants as r join orders as o
       on r.restaurant_id = o.restaurant_id
                       join deliveries as d
       on o.order_id = d.order_id
group by r.restaurant_name


--Orders by day of the week.

select DATENAME(DW,order_date) as Day_of_the_week,
       count(order_id) as total_orders
from orders
group by DATENAME(DW,order_date),
         DATEPART(DW,order_date)
order by DATEPART(DW,order_date)

--Top 5 restaurants by revenue.

with ranked_restaurants
as (select r.restaurant_name,
		   ROW_NUMBER() OVER(order by sum(o.total_amount) desc) as rnk
	from restaurants as r join orders as o
	on r.restaurant_id = o.restaurant_id
	group by r.restaurant_name) 

select * from ranked_restaurants
where rnk <=5


--Top 5 cities by revenue.

with ranked_cities
as (select r.city,
		   ROW_NUMBER() OVER(order by sum(o.total_amount) desc) as rnk
	from restaurants as r join orders as o
	on r.restaurant_id = o.restaurant_id
	group by r.city) 

select * from ranked_cities
where rnk <=5
