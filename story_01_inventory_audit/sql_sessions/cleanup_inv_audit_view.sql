-- ================================
-- Story 01: Inventory Audit Cleanup
-- Source DB: ecom_retailer.db
-- File: story_01_inventory_accuracy/sql_sessions/scenario_01_cleanup_inv_audit_view.sql
-- Drops the view created for the audit.
-- ================================
DROP VIEW IF EXISTS inventory_audit;