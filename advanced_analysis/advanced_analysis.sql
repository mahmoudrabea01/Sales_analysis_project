-- advanced analysis

-- === change over the time (trend analysis)
select 
	year(order_date) as year ,
	MONTH(order_date) as month ,
	sum(sales) as total_sales ,
	avg(sales) as average_sales ,
	count(customer_key) as number_of_customers ,
	sum(quantity) as quntity
from gold.fact_sales 
where year(order_date) is not null
group by year(order_date) , MONTH(order_date)
order by year(order_date) , MONTH(order_date) ;

-- or
select 
	datetrunc(month , order_date) as month ,
	sum(sales) as total_sales ,
	avg(sales) as average_sales ,
	count(customer_key) as number_of_customers ,
	sum(quantity) as quntity
from gold.fact_sales 
where year(order_date) is not null
group by datetrunc(month , order_date)
order by datetrunc(month , order_date) ;

-- ===========================

-- cumulative analysis 

-- running total & moving average for each year
with cte_cumu_sales as(
select 
	datetrunc(month , order_date) as month ,
	sum(sales) as total_sales ,
	avg(price) as average_price ,
	count(customer_key) as number_of_customers ,
	sum(quantity) as quntity
from gold.fact_sales 
where year(order_date) is not null
group by datetrunc(month , order_date)
)
select
	month ,
	total_sales ,
	sum(total_sales) over(partition by datetrunc(year , month) order by month) as running_total ,
	average_price ,
	avg(average_price) over(partition by datetrunc(year , month) order by month) as moving_average_price
from cte_cumu_sales ;

-- ==== preformance analysis

-- compare the sales with the average and previous year sales
with cte_pre as(
select
		year(order_date) as year ,
		p.product_name ,
		sum(s.sales) as sales
from gold.fact_sales as s
LEFT join gold.dim_products as p
on s.product_key = p.product_key
group by year(order_date) ,p.product_name
)
select year ,
	product_name ,
	sales ,
	avg(sales) over(partition by product_name ) as avg_sales ,
	sales - avg(sales) over(partition by product_name) as preformance_by_average ,
	case when  sales - avg(sales) over(partition by product_name) > 0 then 'above_avg'
		when sales - avg(sales) over(partition by product_name) < 0 then 'below_avg'
		else 'like_avg' end as preformance_indictor,
	lag(sales) over(partition by product_name order by year) as previous_year ,
	-- yoy analysis
	sales - lag(sales) over(partition by product_name order by year) as preformance_by_previous_year ,
	case when sales - lag(sales) over(partition by product_name order by year) > 0 then 'increase'
		when sales - lag(sales) over(partition by product_name order by year) < 0 then 'decrease'
		else 'no change' end as YoY_analysis
from cte_pre
where year is not null ;

-- ==========

-- part-to-whole analysis

-- which category contribute the most to the total sales
with cte_ptw as(
select 
	p.category, 
	sum(sales) as sales
from gold.fact_sales s
left join gold.dim_products p
on s.product_key = p.product_key
group by p.category 
)
select 
	category ,
	sales ,
	sum(sales) over() as total_sales,
	round((cast(sales as float) / sum(sales) over()) * 100 , 2) as categories_percentage
from cte_ptw

--=============

-- === data segmentation

-- segment the product to the cost and calc how many prd in each segment
with cte_seg as (
select
	product_key ,
	product_name ,
	product_cost ,
	case when product_cost <= 550 then 'good_cost'
		when product_cost > 550 and product_cost <= 1100 then 'low_cost'
		when product_cost > 1100 and product_cost <= 1600 then 'high_cost'
		else 'bad_cost' end as cost_segment
from  gold.dim_products 
)
select cost_segment ,
	count(product_name) as num_prd
from cte_seg
group by cost_segment

---
-- segment the customers based in thair hist and spending 
-- vip : more than 12 month and spent more  than 5000
-- regular : more than 12 month and spent less than 5000
-- new :  less than 12 month
-- count the number of customers for each group
with cte_cust_sp as (
select 
	c.customer_key ,
	sum(s.sales) sales ,
	min(s.order_date) min_date ,
	max(s.order_date) max_date ,
	DATEDIFF(month ,min(s.order_date) , max(s.order_date)) as lifspan
from gold.fact_sales s
left join gold.dim_customers c
on s.customer_key = c.customer_key
group by c.customer_key 
)
select
	customers_categories ,
	count(*) as total_customers
from
(select 
	customer_key ,
	sales ,
	lifspan ,
	case when lifspan >= 12 and sales < 5000 then 'regular'
		when lifspan >= 12 and sales > 5000 then 'vip'
		else 'new' end as customers_categories
from cte_cust_sp ) s
group by customers_categories ;
