-- ================================
-- Story 01: Inventory Audit View
-- Source DB: ecom_retailer.db
-- File: story_01_inventory_accuracy/sql_sessions/build_inventory_audit_view.sql
-- Creates or replaces view: inventory_audit
-- ================================

DROP VIEW IF EXISTS inventory_audit;

CREATE VIEW inventory_audit AS
WITH
params AS (
  SELECT
    100  AS min_sold,               -- Lowered for wider applicability on smaller datasets
    6  AS min_nonrestock_units,   -- Lowered for wider applicability
    0.50 AS min_nonrestock_share,   -- Lowered to 50%
    12   AS min_total_returns       -- Lowered for wider applicability
),
-- 0) normalize return reasons once
reasons_norm AS (
  SELECT r.return_id, LOWER(TRIM(r.reason)) AS reason_norm
  FROM returns r
),

-- 1) row-level normalization (and guard against header-like rows)
sales_norm AS (
  SELECT oi.product_id, oi.quantity, oi.unit_price
  FROM order_items oi
  WHERE oi.product_id IS NOT NULL
    AND oi.product_id <> 'product_id'
),

returns_items_norm AS (
  SELECT ri.return_id, ri.product_id, ri.quantity_returned, ri.unit_price
  FROM return_items ri
  WHERE ri.product_id IS NOT NULL
    AND ri.product_id <> 'product_id'
),

returns_norm AS (
  SELECT rin.product_id, rin.quantity_returned, rin.unit_price, rn.reason_norm
  FROM returns_items_norm AS rin
  JOIN reasons_norm rn ON rin.return_id = rn.return_id
),

-- 2) Returns Summary by Product
returns_summary AS (
  SELECT 
    product_id,
    SUM(quantity_returned)                              AS total_qty_returned,
    SUM(quantity_returned * unit_price)                 AS total_refunded,
    SUM(CASE WHEN reason_norm IN ('changed mind','no longer needed','wrong item','found better price')
             THEN quantity_returned ELSE 0 END)         AS restockable_qty,
    SUM(CASE WHEN reason_norm NOT IN ('changed mind','no longer needed','wrong item','found better price')
             THEN quantity_returned ELSE 0 END)         AS nonrestockable_qty
  FROM returns_norm
  GROUP BY product_id
),

-- 3) Sales Summary by Product
sales_summary AS (
  SELECT product_id,
         SUM(quantity)                  AS total_qty_sold, 
         SUM(quantity * unit_price)     AS total_revenue
  FROM sales_norm
  GROUP BY product_id
),

-- 4) Clean product_catalog (remove header-like or bogus row 1)
pc_clean AS (
  SELECT
    product_id,
    -- normalize product_name: trim spaces, collapse multiples, lower case
    LOWER(
      REPLACE(REPLACE(REPLACE(TRIM(product_name), '  ', ' '), '  ', ' '), '  ', ' ')
    ) AS product_name,
    -- normalize category: trim spaces, collapse multiples, lower case
    LOWER(
      REPLACE(REPLACE(REPLACE(TRIM(category), '  ', ' '), '  ', ' '), '  ', ' ')
    ) AS category,
    inventory_quantity
  FROM product_catalog
  WHERE product_id IS NOT NULL
    AND LOWER(TRIM(product_id)) <> 'product_id'
    AND NOT (
      COALESCE(inventory_quantity, 0) = 0
      AND (product_name IS NULL OR TRIM(product_name) = '' OR LOWER(TRIM(product_name)) = 'product_name')
      AND (category IS NULL OR TRIM(category) = '' OR LOWER(TRIM(category)) = 'category')
    )
),

-- 5) KPI View Body (base metrics)
audit_base AS (
  SELECT
    pc.product_id,
    pc.product_name,
    pc.category,
    pc.inventory_quantity,

    COALESCE(s.total_qty_sold, 0)                                     AS total_sold,
    COALESCE(r.total_qty_returned, 0)                                 AS total_returned,
    COALESCE(s.total_qty_sold, 0) - COALESCE(r.total_qty_returned, 0) AS net_units_sold,

    CASE
      WHEN pc.inventory_quantity > 0
        THEN 1.0 * (COALESCE(s.total_qty_sold, 0) - COALESCE(r.total_qty_returned, 0))
               / pc.inventory_quantity
      ELSE NULL
    END                                                               AS inventory_utilization_ratio,

    COALESCE(s.total_revenue, 0)                                      AS gross_sales_amount,
    COALESCE(r.total_refunded, 0)                                     AS gross_refunded_amount,
    COALESCE(r.restockable_qty, 0)                                    AS restockable_qty,
    COALESCE(r.nonrestockable_qty, 0)                                 AS nonrestockable_qty,

    CASE
      WHEN COALESCE(r.total_qty_returned,0) = 0 THEN NULL
      ELSE 1.0 * COALESCE(r.nonrestockable_qty,0) / COALESCE(r.total_qty_returned,0)
    END                                                               AS nonrestock_rate,

    CASE
      WHEN COALESCE(s.total_qty_sold,0) > COALESCE(pc.inventory_quantity,0) THEN 1
      ELSE 0
    END                                                               AS oversold_flag,

    CASE
      WHEN COALESCE(s.total_qty_sold,0) >= (SELECT min_sold FROM params)
       AND COALESCE(r.total_qty_returned,0) >= (SELECT min_total_returns FROM params)
       AND COALESCE(r.nonrestockable_qty,0) >= (SELECT min_nonrestock_units FROM params)
       AND (
         CASE WHEN COALESCE(r.total_qty_returned,0)=0 THEN 0
              ELSE 1.0 * COALESCE(r.nonrestockable_qty,0) / COALESCE(r.total_qty_returned,0)
         END
       ) >= (SELECT min_nonrestock_share FROM params)
      THEN 1 ELSE 0
    END                                                               AS inv_attention_flag,

    -- Return rate by SKU (% of sold units that were returned)
    CASE
      WHEN COALESCE(s.total_qty_sold, 0) = 0 THEN NULL
      ELSE 1.0 * COALESCE(r.total_qty_returned, 0) / COALESCE(s.total_qty_sold, 0)
    END AS return_rate

  FROM pc_clean pc
  LEFT JOIN sales_summary  s USING (product_id)
  LEFT JOIN returns_summary r USING (product_id)
),

-- 6) Weighted score & tiering (volume-aware)
scored AS (
  SELECT
    *,
    -- volume factor: give more weight to low-volume SKUs so small-denominator issues surface
    CASE
      WHEN total_sold IS NULL THEN 0.5
      WHEN total_sold < 50 THEN 1.0
      WHEN total_sold BETWEEN 50 AND 200 THEN 0.6
      ELSE 0.3
    END AS volume_factor,

    -- binary signals for readability
    CASE WHEN inventory_utilization_ratio IS NOT NULL AND inventory_utilization_ratio < 0.30 THEN 1 ELSE 0 END AS sig_low_util,
    CASE WHEN return_rate IS NOT NULL AND return_rate >= 0.30 THEN 1 ELSE 0 END AS sig_high_return_rate,

    -- weighted composite (0..1)
    (
      0.45 * (CASE WHEN inventory_utilization_ratio IS NOT NULL AND inventory_utilization_ratio < 0.30 THEN 1 ELSE 0 END) +
      0.35 * (CASE WHEN return_rate IS NOT NULL AND return_rate >= 0.30 THEN 1 ELSE 0 END) +
      0.20 * (
        CASE
          WHEN total_sold IS NULL THEN 0.5
          WHEN total_sold < 50 THEN 1.0
          WHEN total_sold BETWEEN 50 AND 200 THEN 0.6
          ELSE 0.3
        END
      )
    ) AS inv_attention_score
  FROM audit_base
)

SELECT
  product_id,
  product_name,
  category,
  inventory_quantity,
  total_sold,
  total_returned,
  net_units_sold,
  inventory_utilization_ratio,
  gross_sales_amount,
  gross_refunded_amount,
  restockable_qty,
  nonrestockable_qty,
  nonrestock_rate,
  oversold_flag,
  inv_attention_flag,
  return_rate,
  inv_attention_score,
  CASE
    WHEN inv_attention_score >= 0.80 THEN 'Tier 3 – High Attention'
    WHEN inv_attention_score >= 0.50 THEN 'Tier 2 – Moderate Attention'
    WHEN inv_attention_score >= 0.20 THEN 'Tier 1 – Low Attention'
    ELSE 'Tier 0 – Healthy'
  END AS inv_attention_tier
FROM scored;
