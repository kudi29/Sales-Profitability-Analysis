-- ============================================================
-- DIMENSION TABLES
-- ============================================================

-- dim_date  (FIX: build from union of order_date + shipping_date so
-- shipping_date_id never fails to match)
DROP TABLE IF EXISTS gold.dim_date;
CREATE TABLE gold.dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name  TEXT,
    week INTEGER,
    day INTEGER,
    day_name TEXT
);

INSERT INTO gold.dim_date (full_date, year, quarter, month, month_name, week, day, day_name)
SELECT
    full_date,
    EXTRACT(YEAR FROM full_date)::INTEGER,
    EXTRACT(QUARTER FROM full_date)::INTEGER,
    EXTRACT(MONTH FROM full_date)::INTEGER,
    TRIM(TO_CHAR(full_date, 'Month')),
    EXTRACT(WEEK FROM full_date)::INTEGER,
    EXTRACT(DAY FROM full_date)::INTEGER,
    TRIM(TO_CHAR(full_date, 'Day'))
FROM (
    SELECT order_date AS full_date FROM silver.supplychaindataset WHERE order_date IS NOT NULL
    UNION
    SELECT shipping_date AS full_date FROM silver.supplychaindataset WHERE shipping_date IS NOT NULL
) all_dates
ORDER BY full_date;

-- ============================================================
-- dim_customer  (unchanged)
DROP TABLE IF EXISTS gold.dim_customer;
CREATE TABLE gold.dim_customer (
    customer_id INTEGER PRIMARY KEY,
    customer_fname TEXT,
    customer_lname TEXT,
    customer_segment TEXT,
    customer_city TEXT,
    customer_state TEXT,
    customer_country TEXT,
    customer_street TEXT,
    customer_zipcode TEXT
);

INSERT INTO gold.dim_customer (
    customer_id, customer_fname, customer_lname, customer_segment,
    customer_city, customer_state, customer_country, customer_street, customer_zipcode
)
SELECT DISTINCT ON (customer_id)
    customer_id, customer_fname, customer_lname, customer_segment,
    customer_city, customer_state, customer_country, customer_street, customer_zipcode
FROM silver.supplychaindataset
WHERE customer_id IS NOT NULL
ORDER BY customer_id;

-- ============================================================
-- dim_product  (unchanged)
DROP TABLE IF EXISTS gold.dim_product;
CREATE TABLE gold.dim_product (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT,
    product_price NUMERIC(10, 2),
    product_status  INTEGER,
    category_id INTEGER,
    category_name TEXT,
    product_category_id INTEGER,
    department_id INTEGER,
    department_name TEXT
);

INSERT INTO gold.dim_product (
    product_id, product_name, product_price, product_status,
    category_id, category_name, product_category_id,
    department_id, department_name
)
SELECT DISTINCT ON (product_card_id)
    product_card_id, product_name, product_price, product_status,
    category_id, category_name, product_category_id,
    department_id, department_name
FROM silver.supplychaindataset
WHERE product_card_id IS NOT NULL
ORDER BY product_card_id;

-- ============================================================
-- dim_location  (FIX: dedupe on business key only, not lat/long,
-- so each city maps to exactly one location_id)
DROP TABLE IF EXISTS gold.dim_location;
CREATE TABLE gold.dim_location (
    location_id SERIAL PRIMARY KEY,
    market TEXT,
    order_region TEXT,
    order_country TEXT,
    order_state  TEXT,
    order_city TEXT,
    latitude NUMERIC(18, 10),
    longitude NUMERIC(18, 10)
);

INSERT INTO gold.dim_location (
    market, order_region, order_country, order_state, order_city, latitude, longitude
)
SELECT DISTINCT ON (market, order_region, order_country, order_state, order_city)
    market, order_region, order_country, order_state, order_city, latitude, longitude
FROM silver.supplychaindataset
WHERE order_city IS NOT NULL
ORDER BY market, order_region, order_country, order_state, order_city;

-- ============================================================
-- dim_shipping  (unchanged here; see note on modeling smell above —
-- out of scope for the 3-page report, so not fixed in this pass)
DROP TABLE IF EXISTS gold.dim_shipping;
CREATE TABLE gold.dim_shipping (
    shipping_id SERIAL PRIMARY KEY,
    shipping_mode TEXT,
    delivery_status TEXT,
    late_delivery_risk INTEGER,
    days_for_shipping_real INTEGER,
    days_for_shipment_scheduled INTEGER
);

INSERT INTO gold.dim_shipping (
    shipping_mode, delivery_status, late_delivery_risk,
    days_for_shipping_real, days_for_shipment_scheduled
)
SELECT DISTINCT
    shipping_mode, delivery_status, late_delivery_risk,
    days_for_shipping_real, days_for_shipment_scheduled
FROM silver.supplychaindataset
WHERE shipping_mode IS NOT NULL;

-- ============================================================
-- POPULATE FK COLUMNS IN SILVER  (FIX: this entire block now runs
-- BEFORE the fact table is built, not after)
-- ============================================================

ALTER TABLE silver.supplychaindataset
    ADD COLUMN IF NOT EXISTS location_id INTEGER,
    ADD COLUMN IF NOT EXISTS shipping_id INTEGER,
    ADD COLUMN IF NOT EXISTS order_date_id INTEGER,
    ADD COLUMN IF NOT EXISTS shipping_date_id INTEGER;

-- Populate location_id
UPDATE silver.supplychaindataset s
SET location_id = l.location_id
FROM gold.dim_location l
WHERE l.order_city = s.order_city
  AND l.order_country = s.order_country
  AND l.order_region  = s.order_region;

-- Populate shipping_id
UPDATE silver.supplychaindataset s
SET shipping_id = sh.shipping_id
FROM gold.dim_shipping sh
WHERE sh.shipping_mode = s.shipping_mode
  AND sh.delivery_status = s.delivery_status
  AND sh.days_for_shipping_real = s.days_for_shipping_real
  AND sh.days_for_shipment_scheduled = s.days_for_shipment_scheduled;

-- Populate order_date_id
UPDATE silver.supplychaindataset s
SET order_date_id = d.date_id
FROM gold.dim_date d
WHERE d.full_date = s.order_date;

-- Populate shipping_date_id
UPDATE silver.supplychaindataset s
SET shipping_date_id = d.date_id
FROM gold.dim_date d
WHERE d.full_date = s.shipping_date;

-- ============================================================
-- FACT TABLE  (now built AFTER silver's FK columns are populated)
-- ============================================================

DROP TABLE IF EXISTS gold.fact_order_items;

CREATE TABLE gold.fact_order_items (
    fact_id SERIAL PRIMARY KEY,
    order_item_id INTEGER,
    order_id INTEGER,
    order_date_id INTEGER REFERENCES gold.dim_date(date_id),
    shipping_date_id INTEGER REFERENCES gold.dim_date(date_id),
    customer_id INTEGER REFERENCES gold.dim_customer(customer_id),
    product_id INTEGER REFERENCES gold.dim_product(product_id),
    location_id INTEGER REFERENCES gold.dim_location(location_id),
    shipping_id INTEGER REFERENCES gold.dim_shipping(shipping_id),
    order_item_quantity INTEGER,
    order_item_discount NUMERIC(10, 2),
    order_item_discount_rate NUMERIC(10, 4),
    order_item_product_price NUMERIC(10, 2),
    order_item_profit_ratio NUMERIC(10, 4),
    order_item_total NUMERIC(10, 2),
    order_profit_per_order NUMERIC(10, 2),
    sales NUMERIC(10, 2),
    benefit_per_order NUMERIC(10, 2),
    sales_per_customer NUMERIC(10, 2),
    order_status TEXT,
    payment_type TEXT
);

INSERT INTO gold.fact_order_items (
    order_item_id, order_id,
    order_date_id, shipping_date_id,
    customer_id, product_id, location_id, shipping_id,
    order_item_quantity, order_item_discount, order_item_discount_rate,
    order_item_product_price, order_item_profit_ratio,
    order_item_total, order_profit_per_order,
    sales, benefit_per_order, sales_per_customer,
    order_status, payment_type
)
SELECT
    order_item_id, order_id,
    order_date_id, shipping_date_id,
    customer_id, product_card_id, location_id, shipping_id,
    order_item_quantity, order_item_discount, order_item_discount_rate,
    order_item_product_price, order_item_profit_ratio,
    order_item_total, order_profit_per_order,
    sales, benefit_per_order, sales_per_customer,
    order_status, payment_type
FROM silver.supplychaindataset;
