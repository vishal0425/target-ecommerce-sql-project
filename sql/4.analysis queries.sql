use target_clean;

-- ##########################################################
-- 1. customer analysis
-- ##########################################################

-- 1.1 total number of unique customers
select count(distinct customer_id) as total_customers
from customers;

-- 1.2 top 5 states with highest number of customers
select 
    customer_state, 
    count(*) as customer_count
from customers
group by customer_state
order by customer_count desc
limit 5;

-- 1.3 customer retention rate
select 
    round(
        (select count(*) 
         from (
            select customer_id 
            from orders 
            group by customer_id 
            having count(order_id) > 1
         ) as retained_customers) 
        /
        (select count(distinct customer_id) from customers) * 100, 2
    ) as retention_rate_percent;

-- 1.4 customers who gave 1-star review more than twice
select 
    o.customer_id
from orders o
join order_reviews r on o.order_id = r.order_id
where r.review_score = 1
group by o.customer_id
having count(r.review_id) > 2;

-- ##########################################################
-- 2. order & delivery analysis
-- ##########################################################

-- 2.1 delivered vs canceled orders
select 
    order_status, 
    count(*) as total_orders
from orders
where order_status in ('delivered', 'canceled')
group by order_status;

-- 2.2 average delivery time
select 
    round(avg(datediff(order_delivered_customer_date, order_purchase_timestamp)), 2) 
        as avg_delivery_days
from orders
where order_status = 'delivered'
  and order_delivered_customer_date is not null
  and order_purchase_timestamp is not null;

-- 2.3 top 5 fastest delivery cities
select 
    c.customer_city,
    round(avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2) 
        as avg_delivery_days
from orders o
join customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
  and o.order_purchase_timestamp is not null
group by c.customer_city
order by avg_delivery_days asc
limit 5;

-- 2.4 percentage of late deliveries
select 
    round(
        (select count(*) from orders 
         where order_delivered_customer_date > order_estimated_delivery_date)
        /
        (select count(*) from orders where order_status = 'delivered') * 100, 
        2
    ) as late_delivery_percent;

-- 2.5 month with maximum orders
select 
    month(order_purchase_timestamp) as order_month,
    count(*) as total_orders
from orders
group by month(order_purchase_timestamp)
order by total_orders desc;

-- ##########################################################
-- 3. product & category analysis
-- ##########################################################

-- 3.1 top 10 most sold product categories
select 
    p.product_category,
    count(*) as total_sold
from order_items oi
join products p on oi.product_id = p.product_id
group by p.product_category
order by total_sold desc
limit 10;

-- 3.2 average product attributes per category
select 
    product_category,
    round(avg(product_weight_g), 2) as avg_weight_g,
    round(avg(product_length_cm), 2) as avg_length_cm,
    round(avg(product_height_cm), 2) as avg_height_cm
from products
group by product_category;

-- 3.3 highest freight-to-price ratio
select 
    oi.product_id,
    round(sum(oi.freight_value) / nullif(sum(oi.price), 0), 2) as freight_to_price_ratio
from order_items oi
group by oi.product_id
having sum(oi.price) > 0
order by freight_to_price_ratio desc
limit 10;

-- 3.4 top 3 products by revenue per category
select 
    product_category,
    product_id,
    total_revenue
from (
    select 
        p.product_category,
        oi.product_id,
        sum(oi.price) as total_revenue,
        rank() over (partition by p.product_category order by sum(oi.price) desc) 
            as revenue_rank
    from order_items oi
    join products p on oi.product_id = p.product_id
    group by p.product_category, oi.product_id
) ranked_products
where revenue_rank <= 3;

-- ##########################################################
-- 4. payment & revenue analysis
-- ##########################################################

-- 4.1 most common payment type
select 
    payment_type,
    count(*) as total_payments
from payments
group by payment_type
order by total_payments desc
limit 1;

-- 4.2 revenue by payment type
select 
    payment_type,
    round(sum(payment_value), 2) as total_revenue
from payments
group by payment_type
order by total_revenue desc;

-- 4.3 average installments for credit cards
select 
    round(avg(payment_installments), 2) as avg_installments
from payments
where payment_type = 'credit_card';

-- 4.4 top 5 highest-value orders
select 
    p.order_id,
    p.payment_type,
    p.payment_value,
    o.customer_id,
    o.order_status
from payments p
join orders o on p.order_id = o.order_id
order by p.payment_value desc
limit 5;

-- ##########################################################
-- 5. review analysis
-- ##########################################################

-- 5.1 average review score per category
select 
    p.product_category, 
    round(avg(r.review_score), 2) as avg_review_score
from order_reviews r
join orders o on r.order_id = o.order_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
group by p.product_category
order by avg_review_score desc;

-- 5.2 sellers with more than 3 low reviews (<3)
select 
    s.seller_id,
    count(*) as low_score_count
from order_reviews r
join orders o on r.order_id = o.order_id
join order_items oi on o.order_id = oi.order_id
join sellers s on oi.seller_id = s.seller_id
where r.review_score < 3
group by s.seller_id
having count(*) >= 3
order by low_score_count desc;

-- 5.3 correlation between delivery time and review score
select 
    round(avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2) 
        as avg_delivery_days,
    round(avg(r.review_score), 2) as avg_review_score
from orders o
join order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
  and o.order_purchase_timestamp is not null;

-- 5.4 review score distribution by state
select 
    c.customer_state,
    r.review_score,
    count(*) as review_count
from order_reviews r
join orders o on r.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
group by c.customer_state, r.review_score
order by c.customer_state, r.review_score;

-- ##########################################################
-- 6. seller & location analysis
-- ##########################################################

-- 6.1 sellers per state
select 
    g.geolocation_state as seller_state,
    count(distinct s.seller_id) as seller_count
from sellers s
join geolocation g on s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
group by g.geolocation_state
order by seller_count desc;

-- 6.2 top sellers by revenue
select 
    s.seller_id,
    round(sum(oi.price), 2) as total_revenue
from order_items oi
join sellers s on oi.seller_id = s.seller_id
group by s.seller_id
order by total_revenue desc
limit 10;

-- 6.3 top 5 cities with highest seller density
select 
    g.geolocation_city as seller_city,
    count(distinct s.seller_id) as seller_count
from sellers s
join geolocation g on s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
group by g.geolocation_city
order by seller_count desc
limit 5;

-- 6.4 local transactions (customer & seller in same zip)
select 
    o.order_id,
    c.customer_id,
    s.seller_id,
    c.customer_zip_code_prefix,
    s.seller_zip_code_prefix
from orders o
join customers c on o.customer_id = c.customer_id
join order_items oi on o.order_id = oi.order_id
join sellers s on oi.seller_id = s.seller_id
where c.customer_zip_code_prefix = s.seller_zip_code_prefix;

-- ##########################################################
-- 7. advanced analytics
-- ##########################################################

-- 7.1 monthly revenue growth
select 
    date_format(o.order_purchase_timestamp, '%y-%m') as month,
    round(sum(oi.price), 2) as monthly_revenue
from orders o
join order_items oi on o.order_id = oi.order_id
group by date_format(o.order_purchase_timestamp, '%y-%m')
order by month;

-- 7.2 purchase frequency: one-time vs repeat
select 
    case 
        when order_count = 1 then 'one-time'
        else 'repeat'
    end as purchase_type,
    count(*) as customer_count
from (
    select 
        customer_id, 
        count(order_id) as order_count
    from orders
    group by customer_id
) as customer_orders
group by purchase_type;

-- 7.3 revenue contribution percentage per category
select 
    p.product_category,
    round(
        sum(oi.price) / (select sum(price) from order_items) * 100, 2
    ) as revenue_percent
from order_items oi
join products p on oi.product_id = p.product_id
group by p.product_category
order by revenue_percent desc;

-- 7.4 top 3 sellers in each state by revenue
select 
    seller_state,
    seller_id,
    total_revenue
from (
    select 
        g.geolocation_state as seller_state,
        s.seller_id,
        sum(oi.price) as total_revenue,
        rank() over (
            partition by g.geolocation_state 
            order by sum(oi.price) desc
        ) as revenue_rank
    from order_items oi
    join sellers s on oi.seller_id = s.seller_id
    join geolocation g on s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
    group by g.geolocation_state, s.seller_id
) ranked_sellers
where revenue_rank <= 3;