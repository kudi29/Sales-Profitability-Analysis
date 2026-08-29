-- ============================================================
-- 1. ROW COUNTS ACROSS ALL LAYERS
-- ============================================================

SELECT 'bronze' AS layer, COUNT(*) AS row_count FROM bronze."supplychaindataset"
UNION ALL
SELECT 'silver', COUNT(*) FROM silver."supplychaindataset"
UNION ALL
SELECT 'fact_order_items', COUNT(*) FROM gold.fact_order_items;

-- ============================================================
-- 2. CHECK FOR NULLS IN FACT TABLE FK COLUMNS
--    (shipping_date_id and location_id should now be 0 --
--     if either is > 0, the corresponding fix did not take)
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
-- ============================================================

SELECT 'dim_date' AS dimension, COUNT(*) AS row_count FROM gold.dim_date
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM gold.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM gold.dim_product
UNION ALL
SELECT 'dim_location', COUNT(*) FROM gold.dim_location
UNION ALL
SELECT 'dim_shipping', COUNT(*) FROM gold.dim_shipping;

-- ============================================================
-- 4. VERIFY dim_location DEDUP FIX
--    (should return 0 rows -- no city/region/country/state
--     combination should map to more than one location_id)
-- ============================================================

SELECT market, order_region, order_country, order_state, order_city,
       COUNT(*) AS location_id_count
FROM gold.dim_location
GROUP BY market, order_region, order_country, order_state, order_city
HAVING COUNT(*) > 1;

-- ============================================================
-- 5. VERIFY dim_date UNION FIX
--    (should return 0 rows -- every shipping_date in silver
--     should now have a matching row in dim_date)
-- ============================================================

SELECT DISTINCT s.shipping_date
FROM silver.supplychaindataset s
LEFT JOIN gold.dim_date d ON d.full_date = s.shipping_date
WHERE s.shipping_date IS NOT NULL
  AND d.date_id IS NULL;

-- ============================================================
-- 6. VERIFY payment_type CORRUPTION FIX
--    (should show DEBIT, TRANSFER, CASH, PAYMENT -- no "Unknow" bucket
--     unless it existed as a genuinely distinct value in bronze)
-- ============================================================

SELECT payment_type, COUNT(*) AS order_count
FROM gold.fact_order_items
GROUP BY payment_type
ORDER BY order_count DESC;

-- ============================================================
-- 7. DATE RANGE OF THE DATA
-- ============================================================

SELECT
    MIN(full_date) AS earliest_date,
    MAX(full_date) AS latest_date
FROM gold.dim_date;

-- ============================================================
-- 8. SALES & PROFIT SANITY CHECK
-- ============================================================

SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(benefit_per_order), 2) AS total_profit,
    ROUND(AVG(order_item_discount), 2) AS avg_discount,
    ROUND(AVG(order_item_profit_ratio) * 100, 2) AS avg_profit_margin_pct,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers
FROM gold.fact_order_items;

-- ============================================================
-- 9. SALES BY ORDER STATUS
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(sales), 2) AS total_sales
FROM gold.fact_order_items
GROUP BY order_status
ORDER BY order_count DESC;

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
