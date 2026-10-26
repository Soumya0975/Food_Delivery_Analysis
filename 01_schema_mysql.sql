-- MySQL 8.0+ | InnoDB | utf8mb4
CREATE DATABASE IF NOT EXISTS india_food CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE india_food;

DROP TABLE IF EXISTS order_item, orders, product, customers;

CREATE TABLE customers (
  customer_id   INT UNSIGNED PRIMARY KEY,
  customer_name VARCHAR(80)  NOT NULL,
  city          VARCHAR(40)  NOT NULL,
  state         VARCHAR(40)  NOT NULL,
  signup_date   DATE         NOT NULL,
  referred_by   INT UNSIGNED NULL,
  CONSTRAINT fk_cust_ref FOREIGN KEY (referred_by) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

CREATE TABLE product (
  product_id   INT UNSIGNED PRIMARY KEY,
  product_name VARCHAR(80)   NOT NULL,
  category     VARCHAR(40)   NOT NULL,
  description  TEXT,
  cost_inr     DECIMAL(8,2)  NOT NULL,
  price_inr    DECIMAL(8,2)  NOT NULL,
  CONSTRAINT chk_price CHECK (price_inr >= cost_inr)
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id       INT UNSIGNED PRIMARY KEY,
  customer_id    INT UNSIGNED NOT NULL,
  order_date     DATE         NOT NULL,
  payment_method VARCHAR(20)  NOT NULL,
  tip_inr        DECIMAL(8,2) DEFAULT 0,
  rating         TINYINT UNSIGNED NULL,
  review_text    TEXT NULL,
  CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  INDEX idx_orders_customer (customer_id),
  INDEX idx_orders_date (order_date)
) ENGINE=InnoDB;

CREATE TABLE order_item (
  order_item_id  INT UNSIGNED PRIMARY KEY,
  order_id       INT UNSIGNED NOT NULL,
  product_id     INT UNSIGNED NOT NULL,
  quantity       TINYINT UNSIGNED NOT NULL,
  unit_price_inr DECIMAL(8,2) NOT NULL,
  CONSTRAINT chk_qty CHECK (quantity > 0),
  CONSTRAINT fk_item_ord  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  CONSTRAINT fk_item_prod FOREIGN KEY (product_id) REFERENCES product(product_id),
  INDEX idx_item_order (order_id),
  INDEX idx_item_product (product_id)
) ENGINE=InnoDB;
