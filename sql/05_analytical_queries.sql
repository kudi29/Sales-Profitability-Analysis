--===============================Analytical queries=========================================

-- ============================================================
-- 1. DISCOUNT IMPACT ON PROFIT
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
    COUNT(*) AS order_count,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(benefit_per_order), 2) AS total_profit,
    ROUND(AVG(order_item_profit_ratio) * 100, 2) AS avg_profit_margin_pct,
    ROUND(AVG(order_item_discount), 2) AS avg_discount_amount
FROM gold.fact_order_items
GROUP BY discount_band
ORDER BY avg_profit_margin_pct DESC;

-- ============================================================
-- 2. PROFIT MARGIN BY PRODUCT CATEGORY
-- ============================================================

SELECT
    p.category_name,
    p.department_name,
    COUNT(*) AS order_count,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit,
    ROUND(AVG(f.order_item_profit_ratio) * 100, 2) AS avg_profit_margin_pct,
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
    ROUND(AVG(f.order_item_profit_ratio) * 100, 2) AS avg_profit_margin_pct,
    ROUND(SUM(f.benefit_per_order) /
          NULLIF(SUM(f.sales), 0) * 100, 2) AS overall_profit_margin_pct,
    ROUND(SUM(f.sales) /
          NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_order_value
FROM gold.fact_order_items f
JOIN gold.dim_location l ON l.location_id = f.location_id
GROUP BY l.market, l.order_region
ORDER BY total_profit DESC;

-- ============================================================
-- 4. HIGH VOLUME VS HIGH PROFIT CUSTOMERS
-- ============================================================

SELECT
    c.customer_id,
    c.customer_fname || ' ' || c.customer_lname  AS customer_name,
    c.customer_segment,
    c.customer_country,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.benefit_per_order), 2) AS total_profit,
    ROUND(AVG(f.order_item_profit_ratio) * 100, 2) AS avg_profit_margin_pct,
    ROUND(SUM(f.sales) /
          NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_order_value,
    CASE
        WHEN SUM(f.sales) >= 1000
         AND SUM(f.benefit_per_order) >= 100 THEN 'High value & high profit'
        WHEN SUM(f.sales) >= 1000
         AND SUM(f.benefit_per_order) < 100 THEN 'High volume low profit'
        WHEN SUM(f.sales) < 1000
         AND SUM(f.benefit_per_order) >= 100 THEN 'Low volume high profit'
        ELSE 'Low value & low profit'
    END AS customer_tier
FROM gold.fact_order_items f
JOIN gold.dim_customer c ON c.customer_id = f.customer_id
GROUP BY c.customer_id, c.customer_fname, c.customer_lname,
         c.customer_segment, c.customer_country
ORDER BY total_profit DESC
LIMIT 50;
