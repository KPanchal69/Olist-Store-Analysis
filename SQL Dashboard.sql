create database project2;
use project2;

create table olist_orders_dataset(
order_id char(32) primary key,
customer_id char(32),
order_status varchar(20),
order_purchase_timestamp datetime null,
order_approved_at datetime null,
order_delivered_carrier_date datetime null,
order_delivered_customer_date datetime null,
order_estimated_delivery_date datetime null
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/olist_orders_dataset (1).csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
order_id,
customer_id,
order_status,
@order_purchase_timestamp,
@order_approved_at,
@order_delivered_carrier_date,
@order_delivered_customer_date,
@order_estimated_delivery_date
)
set
order_purchase_timestamp=nullif(@order_purchase_timestamp,''),
order_approved_at=nullif(@order_approved_at,''),
order_delivered_carrier_date=nullif(@order_delivered_carrier_date,''),
order_delivered_customer_date=nullif(@order_delivered_customer_date,''),
order_estimated_delivery_date=nullif(@order_estimated_delivery_date,'');

select * from olist_orders_dataset;

create table olist_customers_dataset(
customer_id char(32) primary key,
customer_unique_id char(32),
customer_zip_code_prefix int,
customer_city varchar(50),
customer_state varchar(5)
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/olist_customers_dataset (1).csv'
into table olist_customers_dataset
fields terminated by ','
optionally enclosed by '"'
lines terminated by "\r\n"
ignore 1 rows;

select * from olist_customers_dataset;

create table olist_order_payments_dataset(
order_id char(32),
payment_sequential int,
payment_type varchar(50),
payment_installments int,
payment_value decimal(10,2));

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/olist_order_payments_dataset (1).csv'
into table olist_order_payments_dataset
fields terminated by ','
optionally enclosed by '"'
lines terminated by "\r\n"
ignore 1 rows;

select * from olist_order_payments_dataset;

create table olist_order_reviews_dataset(
review_id char(32),
order_id char(32),
review_score int,
review_comment_title varchar(50),
review_comment_message varchar(5000),
review_creation_date datetime,
review_answer_timestamp datetime);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/olist_order_reviews_dataset (1).csv'
into table olist_order_reviews_dataset
fields terminated by ','
optionally enclosed by '"'
lines terminated by "\r\n"
ignore 1 rows;

select * from olist_order_reviews_dataset;

create table olist_order_items_dataset(
order_id char(32),
order_item_id int,
product_id char(32),
seller_id char(32),
shipping_limit_date datetime,
price decimal(10,2),
freight_value decimal(10,2));

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/olist_order_items_dataset (1).csv'
into table olist_order_items_dataset
fields terminated by ','
optionally enclosed by '"'
lines terminated by "\r\n"
ignore 1 rows;

select * from olist_order_items_dataset;

create table olist_products_dataset(
product_id char(32),
product_category_name varchar(50),
product_name_lenght int,
product_description_lenght int,
product_photos_qty int,
product_weight_g int,
product_length_cm int,
product_height_cm int,
product_width_cm int);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/olist_products_dataset (1).csv'
into table olist_products_dataset
fields terminated by ','
optionally enclosed by '"'
lines terminated by "\r\n"
ignore 1 rows
(
product_id,
product_category_name,
product_name_lenght,
product_description_lenght,
@product_photos_qty,
product_weight_g,
product_length_cm,
product_height_cm,
product_width_cm
)
set
product_photos_qty=nullif(@product_photos_qty,'');

select * from olist_products_dataset;

create table product_category_name_translation(
product_category_name varchar(300),
product_category_name_english varchar(300));

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/product_category_name_translation (1).csv'
into table product_category_name_translation
fields terminated by ','
optionally enclosed by '"'
lines terminated by "\r\n"
ignore 1 rows;

select * from product_category_name_translation;

#Q1. Weekday Vs Weekend Payment Statistics

select
	case
		when dayofweek(order_purchase_timestamp) in (1,7)
        then 'Weekend'
        else 'weekday'
	end as  day_type,
    
    sum(op.payment_value) as total_payment,
    avg(op.payment_value) as avg_payment
    
from olist_orders_dataset o
join olist_order_payments_dataset op
on o.order_id = op.order_id

group by day_type;

#Q2. Number of Orders with Review Score 5 and Credit Card Payment

select count(distinct o.order_id) as total_orders
from olist_orders_dataset o
join olist_order_reviews_dataset r
on o.order_id = r.order_id
join olist_order_payments_dataset op
on o.order_id = op.order_id
where r.review_score = 5
and op.payment_type = "credit_card";

#Q3. Average Delivery Days for pet_shop

select avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)) as avg_delivery_days

from olist_orders_dataset o
join olist_order_items_dataset oi
on o.order_id = oi.order_id
join olist_products_dataset p
on oi.product_id = p.product_id
where p.product_category_name = 'pet_shop';

#Q4. Average Price and Payment Values for São Paulo Customers

select
	avg(oi.price) as avg_price,
    avg(op.payment_value) as avg_payment
from olist_customers_dataset c
join olist_orders_dataset o
on c.customer_id = o.customer_id
join olist_order_items_dataset oi
on o.order_id = oi.order_id
join olist_order_payments_dataset op
on o.order_id = op.order_id
where c.customer_city = 'sao paulo';

#Q5. Relationship Between Shipping Days vs Review Scores

select
	r.review_score,
    avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)) as avg_shipping_days
from olist_orders_dataset o
join olist_order_reviews_dataset r
on o.order_id = r.order_id
where o.order_delivered_customer_date is not null
group by r.review_score
order by r.review_score;

	
#Olist DashBoard 

#Total Orders

create view kpi_total_orders as
select count(distinct order_id) as total_orders
from olist_orders_dataset;

#Total Revenue

create view kpi_total_revenue as
select sum(payment_value) as total_revenue
from olist_order_payments_dataset;

#Average Order Value (AOV)

create view kpi_avg_order_value as
select avg(payment_value) as avg_order_value
from olist_order_payments_dataset;

#Average Review Score

create view kpi_avg_review_score as
select avg(review_score) as avg_review_score
from olist_order_reviews_dataset;

#Average Delivery Days

create view kpi_avg_delivery_days as
select avg(datediff(order_delivered_customer_date, order_purchase_timestamp)) as avg_delivery_days
from olist_orders_dataset
where order_delivered_customer_date is not null;

SELECT * FROM kpi_total_orders;
SELECT * FROM kpi_total_revenue;
SELECT * FROM kpi_avg_order_value;
SELECT * FROM kpi_avg_review_score;
SELECT * FROM kpi_avg_delivery_days;