-- ==========================================================
--  target e-commerce project
--  relationship verification script
--  this script verifies that all primary keys and foreign
--  key relationships are correctly created in the database.
-- ==========================================================

use target_clean;

-- ==========================================================
-- 1. basic table checks
-- ==========================================================

-- view sample records
select * from customers limit 10;
select * from orders limit 10;

-- count total rows in key tables
select count(*) as total_customers from customers;
select count(*) as total_orders from orders;

-- ==========================================================
-- 2. verify primary keys
-- ==========================================================

-- each table must have a unique primary key
show keys from customers where key_name = 'primary';
show keys from orders where key_name = 'primary';
show keys from products where key_name = 'primary';
show keys from sellers where key_name = 'primary';
show keys from order_reviews where key_name = 'primary';
show keys from order_items where key_name = 'primary';

-- ==========================================================
-- 3. verify foreign keys
-- ==========================================================

-- check all foreign key constraints
select 
    table_name,
    constraint_name,
    referenced_table_name
from information_schema.key_column_usage
where table_schema = 'target_clean'
  and referenced_table_name is not null;
