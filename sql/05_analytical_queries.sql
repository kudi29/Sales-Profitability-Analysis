-- ============================================================
-- ANALYTICAL QUERIES
-- Margin note: overall_profit_margin_pct = SUM(profit) / SUM(sales),
-- the same definition Power BI uses. avg_line_profit_margin_pct is
-- the unweighted mean of each order line's margin and will differ.
-- ============================================================

-- ============================================================
-- 1. DISCOUNT IMPACT ON PROFIT
--    (band definitions must match reports.vw_discount_impact in
--     06_reports_views.sql)
-- ============================================================

SELECT
    CASE
        WHEN order_item_discount_rate = 0 THEN '0% - No discount'
        WHEN order_item_discount_rate <= 0.05 THEN '1% - 5%'
        WHEN order_item_discount_rate <= 0.10 THEN '6% - 10%'
        WHEN order_item_discount_rate <= 0.20 THEN '11% - 20%'
        WHEN order_item_discount_rate <= 0.30 THEN '21% - 30%'
        ELSE 'Above 30%'
    END AS discount_band,
    COUNT(*) AS order_line_count,
    COUNT(DISTINCT order_id) AS orders_in_band,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(benefit_per_order), 2) AS total_profit,
    ROUND(SUM(benefit_per_order) /
          NULLIF(SUM(sales), 0) * 100, 2) AS overall_profit_margin_pct,
    ROUND(AVG(order_item_profit_ratio) * 100, 2) AS avg_line_profit_margin_pct,
    ROUND(AVG(order_item_discount), 2) AS avg_discount_amount
FROM gold.fact_order_items
GROUP BY discount_band
ORDER BY MIN(order_item_discount_rate);  

-- ============================================================
-- 2. PROFIT MARGIN BY PRODUCT CATEGORY
-- ============================================================

SELECT
    p.category_name,
    p.department_name,
    COUNT(*) AS order_line_count,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit,
    ROUND(AVG(f.order_item_profit_ratio) * 100, 2) AS avg_line_profit_margin_pct,
    ROUND(SUM(f.benefit_per_order) /
          NULLIF(SUM(f.sales), 0) * 100, 2) AS overall_profit_margin_pct
FROM gold.fact_order_items f
JOIN gold.dim_product p ON p.product_id = f.product_id
GROUP BY p.category_name, p.department_name
ORDER BY overall_profit_margin_pct DESC;

-- ============================================================
-- 3. PROFIT MARGIN BY MARKET & REGION
-- ============================================================

SELECT
    l.market,
    l.order_region,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit,
    ROUND(AVG(f.order_item_profit_ratio) * 100, 2) AS avg_line_profit_margin_pct,
    ROUND(SUM(f.benefit_per_order) /
          NULLIF(SUM(f.sales), 0) * 100, 2) AS overall_profit_margin_pct,
    ROUND(SUM(f.sales) /
          NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_order_value
FROM gold.fact_order_items f
JOIN gold.dim_location l ON l.location_id = f.location_id
GROUP BY l.market, l.order_region
ORDER BY total_profit DESC;

-- ============================================================
-- 4. HIGH SALES VS HIGH PROFIT CUSTOMERS
--    Tiers use each customer's lifetime totals. The thresholds
--    ($1,000 sales, $100 profit) are illustrative -- adjust them to
--    the dataset. Same tier definition as vw_customer_segments.
-- ============================================================

-- 4a. How many customers fall in each tier
WITH customer_totals AS (
    SELECT
        c.customer_id,
        SUM(f.sales) AS total_sales,
        SUM(f.benefit_per_order) AS total_profit
    FROM gold.fact_order_items f
    JOIN gold.dim_customer c ON c.customer_id = f.customer_id
    GROUP BY c.customer_id
),
tiered AS (
    SELECT
        *,
        CASE
            WHEN total_sales >= 1000 AND total_profit >= 100 THEN 'High sales & high profit'
            WHEN total_sales >= 1000 AND total_profit < 100  THEN 'High sales & low profit'
            WHEN total_sales < 1000  AND total_profit >= 100 THEN 'Low sales & high profit'
            ELSE 'Low sales & low profit'
        END AS customer_tier
    FROM customer_totals
)
SELECT
    customer_tier,
    COUNT(*) AS customers,
    ROUND(SUM(total_sales), 2) AS total_sales,
    ROUND(SUM(total_profit), 2) AS total_profit,
    ROUND(SUM(total_profit) / NULLIF(SUM(total_sales), 0) * 100, 2) AS overall_profit_margin_pct
FROM tiered
GROUP BY customer_tier
ORDER BY total_sales DESC;

-- 4b. The 50 biggest customers that earn the least profit
WITH customer_totals AS (
    SELECT
        c.customer_id,
        CONCAT_WS(' ', c.customer_fname, c.customer_lname) AS customer_name,
        c.customer_segment,
        c.customer_country,
        COUNT(DISTINCT f.order_id) AS total_orders,
        SUM(f.sales) AS total_sales,
        SUM(f.benefit_per_order) AS total_profit
    FROM gold.fact_order_items f
    JOIN gold.dim_customer c ON c.customer_id = f.customer_id
    GROUP BY c.customer_id, c.customer_fname, c.customer_lname,
             c.customer_segment, c.customer_country
)
SELECT
    customer_id,
    customer_name,
    customer_segment,
    customer_country,
    total_orders,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit,
    ROUND(total_profit / NULLIF(total_sales, 0) * 100, 2) AS overall_profit_margin_pct,
    ROUND(total_sales / NULLIF(total_orders, 0), 2) AS avg_order_value
FROM customer_totals
WHERE total_sales >= 1000
  AND total_profit < 100
ORDER BY total_sales DESC
LIMIT 50;