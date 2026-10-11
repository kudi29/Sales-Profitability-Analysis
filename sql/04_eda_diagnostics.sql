-- ============================================================
-- EDA & DIAGNOSTICS
-- Run after 03_gold_layer.sql. Each block says what a healthy
-- result looks like.
-- ============================================================

-- ============================================================
-- 1. ROW COUNTS ACROSS ALL LAYERS
--    (all three counts should be equal)
-- ============================================================

SELECT 
	'bronze' AS layer, 
	COUNT(*) AS row_count 
FROM bronze."supplychaindataset"
UNION ALL
SELECT 
	'silver', 
	COUNT(*) 
FROM silver."supplychaindataset"
UNION ALL
SELECT 
	'fact_order_items', 
	COUNT(*) 
FROM gold.fact_order_items;

-- ============================================================
-- 1b. DUPLICATE ORDER LINES
--    (should return 0 rows -- each order_item_id appears once)
-- ============================================================

SELECT 
	order_item_id, 
	COUNT(*) AS occurrences
FROM silver.supplychaindataset
GROUP BY order_item_id
HAVING COUNT(*) > 1;

-- ============================================================
-- 2. CHECK FOR NULLS IN FACT TABLE FK COLUMNS
--    (every count should be 0 -- a non-zero count means that
--     dimension join in 03_gold_layer.sql did not match)
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_date_id IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE shipping_date_id IS NULL) AS null_shipping_date,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product,
    COUNT(*) FILTER (WHERE location_id IS NULL) AS null_location,
    COUNT(*) FILTER (WHERE shipping_id IS NULL) AS null_shipping
FROM gold.fact_order_items;

-- ============================================================
-- 3. DIMENSION TABLE ROW COUNTS
--    (dim_date holds every calendar day in the range, so it is
--     larger than the number of distinct order dates)
-- ============================================================

SELECT 
	'dim_date' AS dimension, 
	COUNT(*) AS row_count 
FROM gold.dim_date
UNION ALL
SELECT 
	'dim_customer', 
	COUNT(*) 
FROM gold.dim_customer
UNION ALL
SELECT 
	'dim_product', 
	COUNT(*) 
FROM gold.dim_product
UNION ALL
SELECT 
	'dim_location', 
	COUNT(*) 
FROM gold.dim_location
UNION ALL
SELECT 
	'dim_shipping', 
	COUNT(*) 
FROM gold.dim_shipping;

-- ============================================================
-- 4. VERIFY dim_location IS UNIQUE
--    (should return 0 rows -- no market/region/country/state/city
--     combination should map to more than one location_id)
-- ============================================================

SELECT 
	market, 
	order_region, 
	order_country, 
	order_state, 
	order_city,
    COUNT(*) AS location_id_count
FROM gold.dim_location
GROUP BY market, order_region, order_country, order_state, order_city
HAVING COUNT(*) > 1;

-- ============================================================
-- 5. VERIFY dim_date IS A CONTINUOUS CALENDAR
-- ============================================================

-- 5a. days_in_table should equal days_expected (no gaps)
SELECT
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date,
    COUNT(*) AS days_in_table,
    (MAX(full_date) - MIN(full_date) + 1) AS days_expected
FROM gold.dim_date;

-- 5b. every order_date and shipping_date in silver has a dim_date row
--     (should return 0 rows)
SELECT x.d AS missing_date
FROM (
    SELECT order_date AS d FROM silver.supplychaindataset
    UNION
    SELECT shipping_date FROM silver.supplychaindataset
) x
LEFT JOIN gold.dim_date dd ON dd.full_date = x.d
WHERE x.d IS NOT NULL
  AND dd.date_id IS NULL;

-- ============================================================
-- 6. VERIFY payment_type CORRUPTION FIX
--    (should show DEBIT, TRANSFER, CASH, PAYMENT -- no "Unknow"
--     bucket unless it existed as a genuinely distinct value
--     in bronze)
-- ============================================================

SELECT 
	payment_type, 
	COUNT(*) AS order_line_count
FROM gold.fact_order_items
GROUP BY payment_type
ORDER BY order_line_count DESC;

-- ============================================================
-- 7. DATE RANGE OF THE DATA
-- ============================================================

-- 7a. Overall ranges. Shipping dates run later than order dates, so
--     the dim_date range is wider than the order range.
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    MIN(shipping_date) AS first_shipping_date,
    MAX(shipping_date) AS last_shipping_date
FROM silver.supplychaindataset;

-- 7b. Days with orders per year -- confirms which year is partial
--     (the README states 2018 is limited to a few weeks).
SELECT
    EXTRACT(YEAR FROM order_date)::INTEGER AS order_year,
    COUNT(DISTINCT order_date) AS days_with_orders,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM silver.supplychaindataset
GROUP BY 1
ORDER BY 1;

-- ============================================================
-- 8. SALES & PROFIT SANITY CHECK
-- ============================================================

-- 8a. Totals. overall_profit_margin_pct (profit / sales) is the
--     definition Power BI uses; avg_line_profit_margin_pct is the
--     unweighted mean of each line's margin and will differ.
SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(benefit_per_order), 2) AS total_profit,
    ROUND(SUM(benefit_per_order) / NULLIF(SUM(sales), 0) * 100, 2) AS overall_profit_margin_pct,
    ROUND(AVG(order_item_discount), 2) AS avg_discount,
    ROUND(AVG(order_item_profit_ratio) * 100, 2) AS avg_line_profit_margin_pct,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers
FROM gold.fact_order_items;

-- 8b. By order year -- use this to reconcile the Power BI KPI cards.
SELECT
    d.year,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit,
    ROUND(SUM(f.benefit_per_order) / NULLIF(SUM(f.sales), 0) * 100, 2) AS overall_profit_margin_pct,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.customer_id) AS total_customers
FROM gold.fact_order_items f
JOIN gold.dim_date d ON d.date_id = f.order_date_id
GROUP BY d.year
ORDER BY d.year;

-- 8c. Silver vs gold reconciliation (each pair should match)
SELECT
    (SELECT ROUND(SUM(sales), 2) FROM silver.supplychaindataset) AS silver_sales,
    (SELECT ROUND(SUM(sales), 2) FROM gold.fact_order_items) AS gold_sales,
    (SELECT ROUND(SUM(benefit_per_order), 2) FROM silver.supplychaindataset) AS silver_profit,
    (SELECT ROUND(SUM(benefit_per_order), 2) FROM gold.fact_order_items) AS gold_profit;

-- ============================================================
-- 9. SALES BY ORDER STATUS
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_line_count,
    ROUND(SUM(sales), 2) AS total_sales
FROM gold.fact_order_items
GROUP BY order_status
ORDER BY order_line_count DESC;

-- ============================================================
-- 10. TOP 10 PRODUCTS BY REVENUE
-- ============================================================

SELECT
    p.product_name,
    p.category_name,
    COUNT(*) AS times_ordered,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit
FROM gold.fact_order_items f
JOIN gold.dim_product p ON p.product_id = f.product_id
GROUP BY p.product_name, p.category_name
ORDER BY total_sales DESC
LIMIT 10;

-- ============================================================
-- 11. SALES BY MARKET & REGION
-- ============================================================

SELECT
    l.market,
    l.order_region,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit
FROM gold.fact_order_items f
JOIN gold.dim_location l ON l.location_id = f.location_id
GROUP BY l.market, l.order_region
ORDER BY total_sales DESC;

-- ============================================================
-- 12. LATE DELIVERY RATE BY SHIPPING MODE
--     (counted per order line)
-- ============================================================

SELECT
    sh.shipping_mode,
    COUNT(*) AS total_shipments,
    SUM(sh.late_delivery_risk) AS late_deliveries,
    ROUND(SUM(sh.late_delivery_risk)::NUMERIC /
          COUNT(*) * 100, 2) AS late_delivery_pct
FROM gold.fact_order_items f
JOIN gold.dim_shipping sh ON sh.shipping_id = f.shipping_id
GROUP BY sh.shipping_mode
ORDER BY late_delivery_pct DESC;