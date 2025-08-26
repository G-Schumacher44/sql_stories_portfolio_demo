-- =================================================================
-- build_01_retention_views.sql
--
-- Description: Creates a series of views for customer retention analysis.
--              These views power the Story 02 dashboard.
--
-- Views Created:
-- - dash_retention_cohort_grid: Monthly retention grid by signup cohort.
-- - dash_retention_kpis_by_cohort: Core KPIs like conversion and time to second purchase.
-- - dash_retention_by_loyalty_tier: Retention and purchasing frequency by loyalty tier.
-- - dash_retention_clv_by_channel: Customer distribution by CLV bucket and signup channel.
-- =================================================================

-- Suppress "view already exists" errors
DROP VIEW IF EXISTS dash_retention_cohort_grid;
DROP VIEW IF EXISTS dash_retention_kpis_by_cohort;
DROP VIEW IF EXISTS dash_retention_by_loyalty_tier;
DROP VIEW IF EXISTS dash_retention_clv_by_channel;
DROP VIEW IF EXISTS dash_purchase_cohort_grid;


-- =================================================================
-- View 1: dash_retention_cohort_grid
-- Purpose: Classic cohort retention table showing the percentage of
--          active customers from a signup cohort over subsequent months.
-- =================================================================
CREATE VIEW dash_retention_cohort_grid AS
WITH customer_cohorts AS (
    -- Assign each customer to a monthly cohort based on signup date
    SELECT
        customer_id,
        strftime('%Y-%m', signup_date) AS cohort_month
    FROM customers
    WHERE signup_date IS NOT NULL -- Cleaning: Exclude records with no signup date
),
order_activity AS (
    -- Get the month of each order for each customer
    SELECT
        customer_id,
        strftime('%Y-%m', order_date) AS order_month
    FROM orders
    WHERE order_date IS NOT NULL -- Cleaning: Exclude records with no order date
    GROUP BY 1, 2 -- One record per customer per month of activity
),
cohort_activity AS (
    -- Join cohorts with their monthly activity and calculate months since signup
    SELECT
        c.cohort_month,
        (CAST(substr(o.order_month, 1, 4) AS INTEGER) - CAST(substr(c.cohort_month, 1, 4) AS INTEGER)) * 12 +
        (CAST(substr(o.order_month, 6, 2) AS INTEGER) - CAST(substr(c.cohort_month, 6, 2) AS INTEGER)) AS months_since_signup,
        c.customer_id
    FROM customer_cohorts c
    JOIN order_activity o ON c.customer_id = o.customer_id
),
monthly_active_customers AS (
    -- Count unique active customers for each cohort in each month since signup
    SELECT
        cohort_month,
        months_since_signup,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    GROUP BY 1, 2
),
cohort_size AS (
    -- Get the total number of customers in each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM customer_cohorts
    GROUP BY 1
)
-- Final calculation: retention rate
SELECT
    m.cohort_month,
    s.total_customers,
    m.months_since_signup,
    m.active_customers,
    CAST(m.active_customers AS REAL) / s.total_customers AS retention_rate
FROM monthly_active_customers m
JOIN cohort_size s ON m.cohort_month = s.cohort_month
WHERE m.months_since_signup >= 0
ORDER BY 1, 3;


-- =================================================================
-- View X: dash_purchase_cohort_grid
-- Purpose: Purchase-based cohort retention table showing the percentage
--          of first-time buyers active in subsequent months. This aligns
--          with standard retention definitions.
-- =================================================================
DROP VIEW IF EXISTS dash_purchase_cohort_grid;

CREATE VIEW dash_purchase_cohort_grid AS
WITH first_orders AS (
  SELECT
    o.customer_id,
    MIN(o.order_date) AS first_order_date,
    strftime('%Y-%m', MIN(o.order_date)) AS first_order_month
  FROM orders o
  WHERE o.order_date IS NOT NULL
  GROUP BY o.customer_id
),
order_activity AS (
  SELECT
    o.customer_id,
    strftime('%Y-%m', o.order_date) AS order_month
  FROM orders o
  WHERE o.order_date IS NOT NULL
  GROUP BY 1, 2
),
cohort_activity AS (
  SELECT
    f.first_order_month AS cohort_month,
    ((CAST(substr(a.order_month,1,4) AS INTEGER) - CAST(substr(f.first_order_month,1,4) AS INTEGER)) * 12) +
    (CAST(substr(a.order_month,6,2) AS INTEGER) - CAST(substr(f.first_order_month,6,2) AS INTEGER)) AS months_since_first_order,
    a.customer_id
  FROM first_orders f
  JOIN order_activity a ON a.customer_id = f.customer_id
  WHERE (
    ((CAST(substr(a.order_month,1,4) AS INTEGER) - CAST(substr(f.first_order_month,1,4) AS INTEGER)) * 12) +
    (CAST(substr(a.order_month,6,2) AS INTEGER) - CAST(substr(f.first_order_month,6,2) AS INTEGER))
  ) >= 0
),
monthly_active AS (
  SELECT
    cohort_month,
    months_since_first_order AS months_since,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM cohort_activity
  GROUP BY 1, 2
),
cohort_size AS (
  SELECT
    first_order_month AS cohort_month,
    COUNT(DISTINCT customer_id) AS purchasers_in_cohort
  FROM first_orders
  GROUP BY 1
)
SELECT
  m.cohort_month,
  s.purchasers_in_cohort,
  m.months_since,
  m.active_customers,
  1.0 * m.active_customers / s.purchasers_in_cohort AS retention_rate
FROM monthly_active m
JOIN cohort_size s USING (cohort_month)
ORDER BY 1, 3;


-- =================================================================
-- View 2: dash_retention_kpis_by_cohort
-- Purpose: Calculates key performance indicators for each signup cohort,
--          focusing on the critical first-to-second purchase journey.
-- =================================================================
CREATE VIEW dash_retention_kpis_by_cohort AS
WITH ranked_orders AS (
    -- Rank orders for each customer to identify 1st, 2nd, etc.
    SELECT
        customer_id,
        order_date,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as order_rank
    FROM orders
    WHERE order_date IS NOT NULL -- Cleaning: Exclude records with no order date
),
customer_purchase_funnel AS (
    -- Pivot to get first and second purchase dates for each customer
    SELECT
        customer_id,
        MIN(CASE WHEN order_rank = 1 THEN order_date END) as first_purchase_date,
        MIN(CASE WHEN order_rank = 2 THEN order_date END) as second_purchase_date
    FROM ranked_orders
    GROUP BY 1
),
cohort_kpis AS (
    -- Join with customer data and calculate KPIs
    SELECT
        strftime('%Y-%m', c.signup_date) AS cohort_month,
        c.customer_id,
        f.first_purchase_date,
        f.second_purchase_date,
        CASE WHEN f.second_purchase_date IS NOT NULL THEN 1 ELSE 0 END AS is_repeat_customer,
        julianday(f.second_purchase_date) - julianday(f.first_purchase_date) AS days_to_second_purchase
    FROM customers c
    LEFT JOIN customer_purchase_funnel f ON c.customer_id = f.customer_id
)
-- Aggregate KPIs by cohort
SELECT
    cohort_month,
    COUNT(customer_id) AS total_customers,
    COUNT(first_purchase_date) AS total_purchasers,
    SUM(is_repeat_customer) AS repeat_purchasers,
    CAST(SUM(is_repeat_customer) AS REAL) / COUNT(first_purchase_date) AS first_to_second_conversion,
    AVG(days_to_second_purchase) AS avg_days_to_second_purchase
FROM cohort_kpis
GROUP BY 1
ORDER BY 1;


-- =================================================================
-- View 3: dash_retention_by_loyalty_tier
-- Purpose: Segments retention and purchase frequency by customer loyalty tier
--          to identify high-value behavioral patterns.
-- =================================================================
CREATE VIEW dash_retention_by_loyalty_tier AS
WITH ranked_orders AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date, 1) OVER (PARTITION BY customer_id ORDER BY order_date) as prev_order_date,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as order_rank
    FROM orders
    WHERE order_date IS NOT NULL -- Cleaning: Exclude records with no order date
),
per_customer AS (
    SELECT
        c.customer_id,
        COALESCE(UPPER(c.loyalty_tier), 'NONE') as loyalty_tier,
        MAX(r.order_rank) as total_orders,
        AVG(julianday(r.order_date) - julianday(r.prev_order_date)) as avg_days_between_orders
    FROM customers c
    LEFT JOIN ranked_orders r ON r.customer_id = c.customer_id
    GROUP BY 1, 2
)
-- Aggregate by loyalty tier over ALL customers (including zero-order)
SELECT
    loyalty_tier,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN COALESCE(total_orders, 0) >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
    1.0 * SUM(CASE WHEN COALESCE(total_orders, 0) >= 2 THEN 1 ELSE 0 END) / COUNT(*) AS repeat_customer_rate_overall,
    AVG(avg_days_between_orders) AS avg_days_between_orders,
    AVG(COALESCE(total_orders, 0)) AS avg_lifetime_orders
FROM per_customer
GROUP BY 1
ORDER BY 1;


-- =================================================================
-- View 4: dash_retention_clv_by_channel
-- Purpose: Provides a simple breakdown of customer value (CLV bucket)
--          by the channel through which they were acquired.
-- =================================================================
CREATE VIEW dash_retention_clv_by_channel AS
SELECT
    -- Cleaning: Standardize channel and bucket names, and handle NULLs
    COALESCE(UPPER(signup_channel), 'UNKNOWN') AS signup_channel,
    COALESCE(UPPER(clv_bucket), 'UNKNOWN') AS clv_bucket,
    COUNT(customer_id) AS number_of_customers
FROM customers
GROUP BY 1, 2
ORDER BY 1, 2;