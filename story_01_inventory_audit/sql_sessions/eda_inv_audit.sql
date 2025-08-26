-- ================================
-- Story 01: Inventory Audit EDA
-- Source DB: ecom_retailer.db
-- File: story_01_inventory_accuracy/sql_sessions/scenario_01_inv_audit_eda.sql
-- Explores inventory_audit view
-- ================================

-- Title: Row Count Sanity Check
-- sanity check
SELECT COUNT(*) AS n_rows FROM inventory_audit;

-- Title: Invalid or Impossible Values
-- impossible/odd states
SELECT
  SUM(CASE WHEN inventory_quantity IS NULL OR inventory_quantity < 0 THEN 1 ELSE 0 END) AS bad_inv_qty,
  SUM(CASE WHEN total_sold        < 0 THEN 1 ELSE 0 END) AS bad_sold,
  SUM(CASE WHEN total_returned    < 0 THEN 1 ELSE 0 END) AS bad_returned
FROM inventory_audit;

-- Title: Missing Metadata Check
-- Missing Category/Product Name counts
SELECT
  SUM(CASE WHEN category IS NULL OR TRIM(category) = '' THEN 1 ELSE 0 END) AS missing_category_count,
  SUM(CASE WHEN product_name IS NULL OR TRIM(product_name) = '' THEN 1 ELSE 0 END) AS missing_name_count
FROM inventory_audit;

-- Title: Extreme Return Rate (>100%)
-- Extreme Return Rates
SELECT
  COUNT(*) AS over_100pct_returns
FROM inventory_audit
WHERE return_rate > 1.0;

-- Title: Quick Sample of Inventory Audit
-- quick look 
SELECT * FROM inventory_audit
ORDER BY inv_attention_flag DESC, oversold_flag DESC, total_sold DESC
LIMIT 5;

-- Title: Category-Level Rollup
-- example: category rollup (optional next step)
SELECT
  category,
  SUM(total_sold)                AS cat_sold,
  SUM(total_returned)            AS cat_returned,
  SUM(net_units_sold)            AS cat_net_units,
  AVG(inventory_utilization_ratio) AS avg_util_ratio
FROM inventory_audit
GROUP BY category
ORDER BY avg_util_ratio DESC;

-- Title: Oversold Products Count
-- products overselling inventory (aligned to view flag) and total units oversold
SELECT
  COUNT(*) AS oversold_count,
  SUM(MAX(0, total_sold - inventory_quantity)) AS total_units_oversold
FROM inventory_audit
WHERE oversold_flag = 1;

-- Title: Distribution of Inventory Utilization
--- distribution of inv. utilization rario
SELECT
  CASE
    WHEN inventory_utilization_ratio < 0.1  THEN '0–10%'
    WHEN inventory_utilization_ratio < 0.2  THEN '10–20%'
    WHEN inventory_utilization_ratio < 0.3  THEN '20–30%'
    WHEN inventory_utilization_ratio < 0.4  THEN '30–40%'
    WHEN inventory_utilization_ratio < 0.5  THEN '40–50%'
    WHEN inventory_utilization_ratio < 0.6  THEN '50–60%'
    WHEN inventory_utilization_ratio < 0.7  THEN '60–70%'
    WHEN inventory_utilization_ratio < 0.8  THEN '70–80%'
    WHEN inventory_utilization_ratio < 0.9  THEN '80–90%'
    WHEN inventory_utilization_ratio < 1.0  THEN '90–100%'
    ELSE '100%+'
  END AS util_bin_label,
  COUNT(*) AS n_products
FROM inventory_audit
GROUP BY util_bin_label
ORDER BY
    CASE util_bin_label
      WHEN '0–10%' THEN 1
      WHEN '10–20%' THEN 2
      WHEN '20–30%' THEN 3
      WHEN '30–40%' THEN 4
      WHEN '40–50%' THEN 5
      WHEN '50–60%' THEN 6
      WHEN '60–70%' THEN 7
      WHEN '70–80%' THEN 8
      WHEN '80–90%' THEN 9
      WHEN '90–100%' THEN 10
      WHEN '100%+'   THEN 11
    END;

-- Title: Oversold Products Detail
-- inspect oversold products with units oversold and $ at risk
SELECT
  product_id,
  product_name,
  category,
  inventory_quantity,
  total_sold,
  total_returned,
  net_units_sold,
  (total_sold - inventory_quantity) AS units_oversold,
  inventory_utilization_ratio,
  ROUND((gross_sales_amount / NULLIF(total_sold, 0)) * MAX(0, total_sold - inventory_quantity), 2) AS est_revenue_at_risk
FROM inventory_audit
WHERE oversold_flag = 1
ORDER BY units_oversold DESC, est_revenue_at_risk DESC;

-- Title: Products Under 30% Utilization Count
-- products selling less than 30% of inventory

SELECT COUNT(*) AS under_30pct_util_count
FROM inventory_audit
WHERE inventory_utilization_ratio < 0.30;

-- Title: Under-Utilized Inventory Summary (Global)
-- Summary of SKUs with utilization <30%, total catalog size, and estimated capital tied up in unsold stock
-- Assumptions:
--   * Under-utilized = inventory_utilization_ratio < 0.30
--   * Remaining stock approximated as (inventory_quantity - net_units_sold), floored at 0
--   * Avg unit price approximated as (gross_sales_amount / total_sold)
--   * Estimated capital tied up = remaining_stock * avg_unit_price
SELECT
  SUM(CASE WHEN inventory_utilization_ratio < 0.30 THEN 1 ELSE 0 END) AS under_utilized_skus,
  COUNT(*) AS total_skus,
  ROUND(100.0 * SUM(CASE WHEN inventory_utilization_ratio < 0.30 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS pct_under_utilized,
  ROUND(SUM(
    CASE
      WHEN (inventory_quantity - net_units_sold) > 0 AND total_sold > 0 THEN
        (inventory_quantity - net_units_sold) * (gross_sales_amount * 1.0 / total_sold)
      ELSE 0
    END
  ), 2) AS est_capital_tied_up
FROM inventory_audit;

-- Title: Products Under 30% Utilization Detail
SELECT
  product_id,
  product_name,
  category,
  inventory_quantity,
  total_sold,
  total_returned,
  net_units_sold,
  inventory_utilization_ratio
FROM inventory_audit
WHERE inventory_utilization_ratio < 0.30
ORDER BY inventory_utilization_ratio ASC;  

-- Title: Products Between 30–100% Utilization Count
--- products selling between 30% and under 100% of count
SELECT COUNT(*) AS sales_abv_30pct_under_count
FROM inventory_audit
WHERE inventory_utilization_ratio BETWEEN 0.29 AND 0.99;

-- Title: Products Between 30–100% Utilization Detail
SELECT
  product_id,
  product_name,
  category,
  inventory_quantity,
  total_sold,
  total_returned,
  net_units_sold,
  inventory_utilization_ratio
FROM inventory_audit
WHERE inventory_utilization_ratio BETWEEN 0.29 AND 0.99
ORDER BY inventory_utilization_ratio DESC;

-- Title: Oversold Products Ranked by Return Rate
--- Oversold Products by Rate
SELECT
    product_id,
    product_name,
    category,
    inventory_quantity,
    total_sold,
    total_returned,
    net_units_sold,
    inventory_utilization_ratio,
    return_rate,
    inv_attention_flag,
    oversold_flag
FROM inventory_audit
Where oversold_flag = 1.0 
AND inv_attention_flag = 1.0
ORDER BY return_rate DESC, inventory_utilization_ratio DESC;

-- Title: Flagged Products Count Summary
-- counts of oversold and inventory attention flagged items
SELECT
  SUM(CASE WHEN oversold_flag = 1 THEN 1 ELSE 0 END) AS oversold_flagged_count,
  SUM(CASE WHEN inv_attention_flag = 1 THEN 1 ELSE 0 END) AS inv_attention_flagged_count
FROM inventory_audit;

-- Title: Tiered Attention Summary
-- counts of products by inv_attention_tier (Tier 0..3)
SELECT
  inv_attention_tier,
  COUNT(*) AS n_products,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM inventory_audit), 1) AS pct_of_catalog
FROM inventory_audit
GROUP BY inv_attention_tier
ORDER BY
  CASE inv_attention_tier
    WHEN 'Tier 3 – High Attention' THEN 1
    WHEN 'Tier 2 – Moderate Attention' THEN 2
    WHEN 'Tier 1 – Low Attention' THEN 3
    WHEN 'Tier 0 – Healthy' THEN 4
  END;

-- Title: Attention Score Distribution (Binned)
-- bucket the inv_attention_score into deciles for shape of risk score
SELECT
  CASE
    WHEN inv_attention_score < 0.10 THEN '0.00–0.09'
    WHEN inv_attention_score < 0.20 THEN '0.10–0.19'
    WHEN inv_attention_score < 0.30 THEN '0.20–0.29'
    WHEN inv_attention_score < 0.40 THEN '0.30–0.39'
    WHEN inv_attention_score < 0.50 THEN '0.40–0.49'
    WHEN inv_attention_score < 0.60 THEN '0.50–0.59'
    WHEN inv_attention_score < 0.70 THEN '0.60–0.69'
    WHEN inv_attention_score < 0.80 THEN '0.70–0.79'
    WHEN inv_attention_score < 0.90 THEN '0.80–0.89'
    ELSE '0.90–1.00'
  END AS score_bin,
  COUNT(*) AS n_products
FROM inventory_audit
GROUP BY score_bin
ORDER BY score_bin;

-- Title: Top 15 High Attention SKUs
-- highest composite inv_attention_score first
SELECT
  product_id,
  product_name,
  category,
  total_sold,
  total_returned,
  return_rate,
  inventory_utilization_ratio,
  inv_attention_score,
  inv_attention_tier
FROM inventory_audit
ORDER BY inv_attention_score DESC, return_rate DESC
LIMIT 15;

-- Title: Legacy Flag vs Tier Cross-Tab
-- compare old binary flag with new tiering for sanity
SELECT
  inv_attention_tier,
  SUM(CASE WHEN inv_attention_flag = 1 THEN 1 ELSE 0 END) AS legacy_flagged,
  COUNT(*) AS tier_count,
  ROUND(100.0 * SUM(CASE WHEN inv_attention_flag = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 1) AS pct_legacy_flag_in_tier
FROM inventory_audit
GROUP BY inv_attention_tier
ORDER BY
  CASE inv_attention_tier
    WHEN 'Tier 3 – High Attention' THEN 1
    WHEN 'Tier 2 – Moderate Attention' THEN 2
    WHEN 'Tier 1 – Low Attention' THEN 3
    WHEN 'Tier 0 – Healthy' THEN 4
  END;

-- Title: Category Rollup by Tier
-- category-level view showing distribution of tiers
SELECT
  category,
  inv_attention_tier,
  COUNT(*) AS n_products,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY category), 1) AS pct_within_category
FROM inventory_audit
GROUP BY category, inv_attention_tier
ORDER BY category,
  CASE inv_attention_tier
    WHEN 'Tier 3 – High Attention' THEN 1
    WHEN 'Tier 2 – Moderate Attention' THEN 2
    WHEN 'Tier 1 – Low Attention' THEN 3
    WHEN 'Tier 0 – Healthy' THEN 4
  END;

-- Title: Volume Band Sensitivity
-- ensure score gives low-volume SKUs a chance to surface without flooding
SELECT
  CASE
    WHEN total_sold IS NULL THEN 'Unknown'
    WHEN total_sold < 50 THEN '<50'
    WHEN total_sold BETWEEN 50 AND 200 THEN '50–200'
    ELSE '>200'
  END AS volume_band,
  inv_attention_tier,
  COUNT(*) AS n_products,
  ROUND(AVG(inv_attention_score), 3) AS avg_score
FROM inventory_audit
GROUP BY volume_band, inv_attention_tier
ORDER BY
  CASE volume_band WHEN 'Unknown' THEN 0 WHEN '<50' THEN 1 WHEN '50–200' THEN 2 ELSE 3 END,
  CASE inv_attention_tier
    WHEN 'Tier 3 – High Attention' THEN 1
    WHEN 'Tier 2 – Moderate Attention' THEN 2
    WHEN 'Tier 1 – Low Attention' THEN 3
    WHEN 'Tier 0 – Healthy' THEN 4
  END;

-- Title: Low-Volume Guardrail Check
-- small-n items with very high score (potential false positives)
SELECT
  product_id,
  product_name,
  category,
  total_sold,
  total_returned,
  return_rate,
  inv_attention_score,
  inv_attention_tier
FROM inventory_audit
WHERE total_sold < 25 AND inv_attention_score >= 0.80
ORDER BY inv_attention_score DESC;

-- Title: Oversold Financial Impact (Aggregate)
-- estimated revenue at risk = avg unit price * units oversold
SELECT
  SUM(MAX(0, total_sold - inventory_quantity)) AS total_units_oversold,
  ROUND(SUM((gross_sales_amount / NULLIF(total_sold, 0)) * MAX(0, total_sold - inventory_quantity)), 2) AS est_total_revenue_at_risk
FROM inventory_audit
WHERE oversold_flag = 1;

-- Title: Attention Flag Financial Impact by Tier
-- estimate nonrestockable loss dollars by tier (pro-rata from refunds)
SELECT
  inv_attention_tier,
  COUNT(*) AS n_products,
  ROUND(SUM(gross_refunded_amount), 2) AS refunded_dollars,
  ROUND(SUM(
    CASE WHEN total_returned > 0 THEN gross_refunded_amount * (nonrestockable_qty * 1.0 / total_returned)
         ELSE 0 END
  ), 2) AS est_nonrestockable_loss
FROM inventory_audit
GROUP BY inv_attention_tier
ORDER BY
  CASE inv_attention_tier
    WHEN 'Tier 3 – High Attention' THEN 1
    WHEN 'Tier 2 – Moderate Attention' THEN 2
    WHEN 'Tier 1 – Low Attention' THEN 3
    WHEN 'Tier 0 – Healthy' THEN 4
  END;

-- Weighted Average Utilization by Inventory Quantity
SELECT 
    ROUND(
        SUM((total_sold - total_returned) * 1.0) / 
        NULLIF(SUM(inventory_quantity),0) * 100, 1
    ) AS weighted_utilization_pct
FROM inventory_audit;

-- Title: Excess Stock Value by Category
-- Calculates the value of inventory not yet sold (excess stock) per category
-- and provides a base figure for cost-savings scenarios.

SELECT
    category,
    SUM(CASE 
          WHEN (inventory_quantity - net_units_sold) > 0 
          THEN (inventory_quantity - net_units_sold) * (gross_sales_amount * 1.0 / NULLIF(total_sold, 0))
          ELSE 0 
        END) AS excess_stock_value,
    ROUND(SUM(CASE 
          WHEN (inventory_quantity - net_units_sold) > 0 
          THEN (inventory_quantity - net_units_sold) * (gross_sales_amount * 1.0 / NULLIF(total_sold, 0))
          ELSE 0 
        END), 2) AS excess_stock_value_rounded
FROM inventory_audit
GROUP BY category
ORDER BY excess_stock_value DESC;

-- Return rate by category
SELECT
    category,
    ROUND(SUM(total_returned) * 1.0 / NULLIF(SUM(total_sold),0), 3) AS return_rate
FROM inventory_audit
GROUP BY category
ORDER BY return_rate DESC;