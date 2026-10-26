-- Run from the REPO ROOT (paths are data/*.csv):
--   mysql --local-infile=1 -u root -p < 02_load_mysql.sql
-- If blocked: SET GLOBAL local_infile = 1; (as admin)
USE india_food;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE 'data/customers.csv' INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(customer_id, customer_name, city, state, signup_date, @ref)
SET referred_by = NULLIF(@ref, '');

LOAD DATA LOCAL INFILE 'data/product.csv' INTO TABLE product
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(product_id, product_name, category, description, cost_inr, price_inr);

LOAD DATA LOCAL INFILE 'data/orders.csv' INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(order_id, customer_id, order_date, payment_method, tip_inr, @rt, @rv)
SET rating = NULLIF(@rt, ''), review_text = NULLIF(@rv, '');

LOAD DATA LOCAL INFILE 'data/order_item.csv' INTO TABLE order_item
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(order_item_id, order_id, product_id, quantity, unit_price_inr);

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'customers' t, COUNT(*) n FROM customers UNION ALL
SELECT 'product', COUNT(*) FROM product UNION ALL
SELECT 'orders', COUNT(*) FROM orders UNION ALL
SELECT 'order_item', COUNT(*) FROM order_item;
