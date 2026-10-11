-- ============================================================
-- REPORTING VIEWS (consumed by Power BI)
-- Run after 03_gold_layer.sql. Each view is dropped and recreated so
-- column changes never fail; refresh Power BI afterwards.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS reports;

-- ============================================================
-- VIEW 1: DISCOUNT IMPACT ON PROFIT
-- ============================================================

DROP VIEW IF EXISTS reports.vw_discount_impact;

CREATE VIEW reports.vw_discount_impact AS
SELECT
    f.fact_id,
    f.order_id,
    f.customer_id,
    f.product_id,
    f.location_id,
    f.shipping_id,
    f.order_date_id,
    p.category_name,
    p.department_name,
    CASE
        WHEN f.order_item_discount_rate = 0 THEN '0% - No discount'
        WHEN f.order_item_discount_rate <= 0.05 THEN '1% - 5%'
        WHEN f.order_item_discount_rate <= 0.10 THEN '6% - 10%'
        WHEN f.order_item_discount_rate <= 0.20 THEN '11% - 20%'
        WHEN f.order_item_discount_rate <= 0.30 THEN '21% - 30%'
        ELSE 'Above 30%'
    END AS discount_band,
    CASE
        WHEN f.order_item_discount_rate = 0 THEN 1
        WHEN f.order_item_discount_rate <= 0.05 THEN 2
        WHEN f.order_item_discount_rate <= 0.10 THEN 3
        WHEN f.order_item_discount_rate <= 0.20 THEN 4
        WHEN f.order_item_discount_rate <= 0.30 THEN 5
        ELSE 6
    END AS discount_band_sort,
    f.order_item_discount_rate,
    f.order_item_discount,
    f.sales,
    f.benefit_per_order,
    f.order_item_profit_ratio
FROM gold.fact_order_items f
JOIN gold.dim_product p ON p.product_id = f.product_id;

-- ============================================================
-- VIEW 2: PROFIT MARGIN BY PRODUCT CATEGORY
-- ============================================================

DROP VIEW IF EXISTS reports.vw_profit_by_category;

CREATE VIEW reports.vw_profit_by_category AS
SELECT
    f.fact_id,
    f.order_id,
    f.customer_id,
    f.product_id,
    f.location_id,
    f.shipping_id,
    f.order_date_id,
    p.category_name,
    p.department_name,
    p.product_name,
    f.sales,
    f.benefit_per_order,
    f.order_item_profit_ratio,
    f.order_item_quantity
FROM gold.fact_order_items f
JOIN gold.dim_product p ON p.product_id = f.product_id;

-- ============================================================
-- VIEW 3: PROFIT MARGIN BY MARKET & REGION
-- ============================================================

DROP VIEW IF EXISTS reports.vw_profit_by_region;

CREATE VIEW reports.vw_profit_by_region AS
SELECT
    f.fact_id,
    f.order_id,
    f.customer_id,
    f.product_id,
    f.location_id,
    f.shipping_id,
    f.order_date_id,
    l.market,
    l.order_region,
    l.order_country,
    l.order_state,
    l.order_city,
    l.latitude,
    l.longitude,
    f.sales,
    f.benefit_per_order,
    f.order_item_profit_ratio,
    f.order_item_quantity
FROM gold.fact_order_items f
JOIN gold.dim_location l ON l.location_id = f.location_id;

-- ============================================================
-- VIEW 4: HIGH SALES VS HIGH PROFIT CUSTOMERS
-- customer_tier is based on each customer's lifetime totals (window
-- sums over customer_id), not on the single order line, and uses the
-- same thresholds and labels as query 4 in 05_analytical_queries.sql.
-- It does not change with Power BI date slicers.
-- ============================================================

DROP VIEW IF EXISTS reports.vw_customer_segments;

CREATE VIEW reports.vw_customer_segments AS
SELECT
    f.fact_id,
    f.order_id,
    f.customer_id,
    f.product_id,
    f.location_id,
    f.shipping_id,
    f.order_date_id,
    CONCAT_WS(' ', c.customer_fname, c.customer_lname) AS customer_name,
    c.customer_segment,
    c.customer_country,
    c.customer_city,
    f.sales,
    f.benefit_per_order,
    f.order_item_profit_ratio,
    f.order_item_discount,
    f.order_item_quantity,
    CASE
        WHEN SUM(f.sales) OVER (PARTITION BY f.customer_id) >= 1000
         AND SUM(f.benefit_per_order) OVER (PARTITION BY f.customer_id) >= 100
            THEN 'High sales & high profit'
        WHEN SUM(f.sales) OVER (PARTITION BY f.customer_id) >= 1000
            THEN 'High sales & low profit'
        WHEN SUM(f.benefit_per_order) OVER (PARTITION BY f.customer_id) >= 100
            THEN 'Low sales & high profit'
        ELSE 'Low sales & low profit'
    END AS customer_tier
FROM gold.fact_order_items f
JOIN gold.dim_customer c ON c.customer_id = f.customer_id;