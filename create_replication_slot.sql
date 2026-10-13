-- =====================================================
-- FILE: 06_create_replication_slot.sql
-- DATABASE: company
-- PURPOSE: Create replication slot manually
-- =====================================================

-- Required because publisher and subscriber databases
-- are on the same PostgreSQL server.
-- Do not use create_slot = true in CREATE SUBSCRIPTION.

SELECT pg_create_logical_replication_slot(
    'sales_subscription',
    'pgoutput'
);