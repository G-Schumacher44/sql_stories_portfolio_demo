

-- =========================================================
-- File: eda_inv_audit_viz.sql
-- Purpose: Plot-ready aggregations for Scenario 01 visuals
-- Source: inventory_audit (view built by build_inventory_audit_view.sql)
-- Notes:
--   * These queries are read-only and return tidy tables ready for plotting
--   * Use pandas.read_sql_query(...) in your notebook to create visuals
-- =========================================================

-- ---------------------------------------------------------
-- 1) Utilization Distribution (Histogram bins 0–100)
--    Shows how SKUs are distributed by utilization percentage
-- ---------------------------------------------------------
-- Columns: utilization_pct_bin (INTEGER 0–100), n_skus (INT)
SELECT 
  CAST(ROUND(inventory_utilization_ratio * 100.0, 0) AS INTEGER) AS utilization_pct_bin,
  COUNT(*) AS n_skus
FROM inventory_audit
GROUP BY utilization_pct_bin
ORDER BY utilization_pct_bin;


-- ---------------------------------------------------------
-- 2) Category × Attention Tier Breakdown (Stacked Bar input)
--    Count of SKUs by category and attention tier
-- ---------------------------------------------------------
-- Columns: category (TEXT), inv_attention_tier (TEXT), n_skus (INT), pct_within_category (REAL %)
WITH base AS (
  SELECT category, inv_attention_tier, COUNT(*) AS n_skus
  FROM inventory_audit
  GROUP BY category, inv_attention_tier
),
cat_totals AS (
  SELECT category, SUM(n_skus) AS cat_total
  FROM base
  GROUP BY category
)
SELECT 
  b.category,
  b.inv_attention_tier,
  b.n_skus,
  ROUND(100.0 * b.n_skus / NULLIF(ct.cat_total, 0), 1) AS pct_within_category
FROM base b
JOIN cat_totals ct USING(category)
ORDER BY b.category, b.inv_attention_tier;


-- ---------------------------------------------------------
-- 3) Excess Stock Value by Category (Capital tie-up)
--    Dollar value of remaining stock approximated at avg unit price
-- ---------------------------------------------------------
-- Assumptions:
--   * excess_units = MAX(inventory_quantity - net_units_sold, 0)
--   * avg_unit_price ≈ gross_sales_amount / total_sold (guarded by NULLIF)
--   * excess_value = excess_units * avg_unit_price
-- Columns: category (TEXT), excess_stock_value (REAL), 
--          savings_10pct (REAL), savings_20pct (REAL), savings_30pct (REAL)
WITH cat_excess AS (
  SELECT 
    category,
    SUM(CASE 
          WHEN (inventory_quantity - net_units_sold) > 0 
          THEN (inventory_quantity - net_units_sold) * (gross_sales_amount * 1.0 / NULLIF(total_sold, 0))
          ELSE 0 
        END) AS excess_stock_value
  FROM inventory_audit
  GROUP BY category
)
SELECT 
  category,
  ROUND(excess_stock_value, 2) AS excess_stock_value,
  ROUND(excess_stock_value * 0.10, 2) AS savings_10pct,
  ROUND(excess_stock_value * 0.20, 2) AS savings_20pct,
  ROUND(excess_stock_value * 0.30, 2) AS savings_30pct
FROM cat_excess
ORDER BY excess_stock_value DESC;


-- ---------------------------------------------------------
-- 4) KPI Helpers (single-row selects)
-- ---------------------------------------------------------
-- 4a) Simple Average Utilization across catalog
SELECT ROUND(AVG(inventory_utilization_ratio) * 100.0, 1) AS avg_utilization_pct
FROM inventory_audit;

-- 4b) Weighted Average Utilization by inventory quantity
SELECT 
  ROUND(
    SUM((net_units_sold) * 1.0) / NULLIF(SUM(inventory_quantity), 0) * 100.0, 1
  ) AS weighted_utilization_pct
FROM inventory_audit;

-- 4c) Total Excess Value (for quick reference)
WITH total_excess AS (
  SELECT 
    SUM(CASE 
          WHEN (inventory_quantity - net_units_sold) > 0 
          THEN (inventory_quantity - net_units_sold) * (gross_sales_amount * 1.0 / NULLIF(total_sold, 0))
          ELSE 0 
        END) AS total_excess_value
  FROM inventory_audit
)
SELECT 
  ROUND(total_excess_value, 2)                          AS total_excess_value,
  ROUND(total_excess_value * 0.10, 2)                   AS savings_10pct,
  ROUND(total_excess_value * 0.20, 2)                   AS savings_20pct,
  ROUND(total_excess_value * 0.30, 2)                   AS savings_30pct,
  ROUND(total_excess_value * 0.25, 2)                   AS holding_cost_at_25pct,
  ROUND(total_excess_value * 0.25 * 0.20, 2)            AS holding_savings_if_20pct_reduction
FROM total_excess;

-- End of file