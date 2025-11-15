-- ==========================================================
--  target e-commerce project
--  database & table creation script
--     this sql script creates the complete database schema 
--     for the target retail dataset, including all tables 
--     and relationships.
-- ==========================================================

-- 1. create database
create database if not exists target_clean;
use target_clean;

-- ==========================================================
-- 2. table: sellers
--    stores seller information such as city, state, and zip.
-- ==========================================================
create table if not exists sellers (
    seller_id varchar(50) primary key,
    seller_zip_code_prefix int not null,
    seller_city varchar(100),
    seller_state char(2)
);

-- ==========================================================
-- 3. table: products
--    contains product attributes and category information.
-- ==========================================================
create table if not exists products (
    product_id varchar(50) primary key,
    product_category varchar(100),
    product_name_length int,
    product_description_length int,
    product_photos_qty int,
    product_weight_g decimal(10,2),
    product_length_cm decimal(10,2),
    product_height_cm decimal(10,2),
    product_width_cm decimal(10,2)
);

-- ==========================================================
-- 4. table: geolocations
--    stores city, state, and coordinates for zip codes.
-- ==========================================================
create table if not exists geolocations (
    geolocation_zip_code_prefix int,
    geolocation_lat decimal(10,8),
    geolocation_lng decimal(10,8),
    geolocation_city varchar(100),
    geolocation_state char(2)
);

-- ==========================================================
-- 5. table: customers
--    contains customer identifiers and location info.
-- ==========================================================
create table if not exists customers (
    customer_id varchar(50) primary key,
    customer_unique_id varchar(50),
    customer_zip_code_prefix int,
    customer_city varchar(100),
    customer_state char(2)
);

-- ==========================================================
-- 6. table: orders
--    stores order lifecycle timestamps and status.
-- ==========================================================
create table if not exists orders (
    order_id varchar(50) primary key,
    customer_id varchar(50),
    order_status varchar(20),
    order_purchase_timestamp datetime,
    order_approved_at datetime,
    order_delivered_carrier_date datetime,
    order_delivered_customer_date datetime,
    order_estimated_delivery_date datetime,
    foreign key (customer_id) references customers(customer_id)
);

-- ==========================================================
-- 7. table: payments
--    stores payment methods, installments, and amount.
-- ==========================================================
create table if not exists payments (
    order_id varchar(50),
    payment_sequential int,
    payment_type varchar(50),
    payment_installments int,
    payment_value decimal(10,2),
    foreign key (order_id) references orders(order_id)
);

-- ==========================================================
-- 8. table: order_reviews
--    captures customer reviews and feedback.
-- ==========================================================
create table if not exists order_reviews (
    review_id varchar(50) primary key,
    order_id varchar(50),
    review_score int check (review_score between 1 and 5),
    review_comment_title varchar(255),
    review_creation_date datetime,
    review_answer_timestamp datetime,
    foreign key (order_id) references orders(order_id)
);

-- ==========================================================
-- 9. table: order_items
--    stores item-level order details, price, and freight.
-- ==========================================================
create table if not exists order_items (
    order_id varchar(50),
    order_item_id int,
    product_id varchar(50),
    seller_id varchar(50),
    shipping_limit_date datetime,
    price decimal(10,2),
    freight_value decimal(10,2),
    primary key (order_id, order_item_id),
    foreign key (order_id) references orders(order_id),
    foreign key (product_id) references products(product_id),
    foreign key (seller_id) references sellers(seller_id)
);
