-- EDA for my project

-- explore the entities of the database
select * from INFORMATION_SCHEMA.TABLES

-- explore the fields
select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME in ('dim_customers' ,'dim_products','fact_sales')

-- === dimensions exploration===

-- explore the dim columns in the customers table
select top 3 * from gold.dim_customers ;

select distinct country from gold.dim_customers ; -- the USA & UK in upper cases & germany aren't cap
select distinct marital_status from gold.dim_customers ; -- no issues
select distinct country from gold.dim_customers ;

-- ==========================

-- explore dim products 
select top 3 * from gold.dim_products ;

select distinct maintenance from gold.dim_products ;

select distinct category , sub_category , product_number from gold.dim_products ;

select distinct product_line from gold.dim_products ;

-- ============

-- explore categorical cols. in fact_sales
select top 3 * from gold.fact_sales ; --  there is no cat. in the fact table

-- === explore the dates

select 
min(order_date) as min_order_date ,
max(order_date) as max_order_date ,
min(ship_date) as min_ship_date ,
max(ship_date) as max_ship_date ,
min(delivered_date) as min_delivered_date ,
max(delivered_date) as max_delivered_date 
from gold.fact_sales ;

-- =====================
select 
min(birthdate) as min_birthdate_date ,
max(birthdate) as max_birthdate_date 
from gold.dim_customers ;

--=== measure exploration (high level of agg.)
select sum(sales) as sum_sales from gold.fact_sales ;
select avg(sales) as avg_sales from gold.fact_sales ;
select sum(quantity) as how_many_items from gold.fact_sales ;
	
select count(order_number) from gold.fact_sales ;
select count( distinct order_number) from gold.fact_sales ;

select count(product_key)  from gold.dim_products ;
select count(distinct product_key)  from gold.dim_products ;

select count(customer_key)  from gold.dim_customers ;

select count(distinct customer_key)  from gold.fact_sales ;

-- generate a report of all agg.
select 'total sales',sum(sales) as measure_value from gold.fact_sales 
union all
select 'average sales' ,avg(sales) as measure_value from gold.fact_sales 
union all
select 'total quantity' , sum(quantity) as measure_value from gold.fact_sales 
union all
select 'number of items sold in orders' , count(order_number) as measure_value  from gold.fact_sales 
union all
select 'number of orders' , count( distinct order_number) as measure_value  from gold.fact_sales 
union all
select 'number of products' , count(product_key) as measure_value from gold.dim_products 
-- union all
--select '' , count(distinct product_key) as measure_value from gold.dim_products ;
union all
select 'number of customers in the database' , count(customer_key) as measure_value from gold.dim_customers 
union all
select 'number of customers who pleaced orders' , count(distinct customer_key) as measure_value from gold.fact_sales ;

--=== magnitude analysis

-- total number of customers by country??
select country ,
count(*)
from gold.dim_customers
group by country ; -- note here i aggregate with custmers entity because all the customers in the database made an order
					-- but this can cause a problem in the future (It will create a gost customers (alot of customers with a little sales)
					-- so the best practice is to get it from the fact_orders
select c.country,
	count(distinct o.customer_key) as numer_of_customers
from gold.fact_sales as o
	inner join gold.dim_customers as c
		on o.customer_key = c.customer_key
group by c.country 
	order by numer_of_customers desc;

-----
-- total product by category
select  category,
	count(product_key) as number_of_products
from gold.dim_products
	group by category
	order by number_of_products desc ;

-- the average cost for each category
select  category,
	avg(product_cost) as average_cost
from gold.dim_products
	group by category
	order by average_cost desc ;

-- the total sales for each cat.
select p.category ,
	sum(s.sales) as total_sales 
from gold.fact_sales as s
	left join
gold.dim_products as p
	on s.product_key = p.product_key
group by category
order by total_sales desc ;

-- the total sales for each customer

select s.customer_key ,
	c.first_name + ' ' + c.last_name as customer_name  ,
	sum(s.sales) as total_sales 
from gold.fact_sales as s
	left join
gold.dim_customers c
	on s.customer_key = c .customer_key
group by s.customer_key , c.first_name + ' ' + c.last_name
order by total_sales desc ;

-----
-- the distribution of sold items for each country
select c.country ,
	sum(s.quantity) as total_sold_items 
from gold.fact_sales as s
	left join
gold.dim_customers c
	on s.customer_key = c .customer_key
group by c.country
order by total_sold_items desc ;

-- =====ranking analysis
-- the top 5 products by sales
select top 5 p.product_name ,
	sum(s.sales) as total_sales
from gold.fact_sales as s
left join gold.dim_products as p
on s.product_key = p.product_key
group by p.product_name
order by total_sales desc ;

-- the bottom 5 products by sales
select top 5 p.product_name ,
	sum(s.sales) as total_sales
from gold.fact_sales as s
left join gold.dim_products as p
on s.product_key = p.product_key
group by p.product_name
order by total_sales  ;

