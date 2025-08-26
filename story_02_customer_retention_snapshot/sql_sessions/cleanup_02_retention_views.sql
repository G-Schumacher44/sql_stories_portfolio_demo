-- =================================================================
-- cleanup_02_retention_views.sql
--
-- Description: Drops all views created by the Story 02 build script.
--              This is run after the data has been uploaded to prevent
--              clutter in the database.
-- =================================================================

DROP VIEW IF EXISTS dash_retention_cohort_grid;
DROP VIEW IF EXISTS dash_retention_kpis_by_cohort;
DROP VIEW IF EXISTS dash_retention_by_loyalty_tier;
DROP VIEW IF EXISTS dash_retention_clv_by_channel;