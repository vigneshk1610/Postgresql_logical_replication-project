-- =====================================================
-- FILE: 03_create_replication_user.sql
-- DATABASE: postgres
-- PURPOSE: Create replication user
-- =====================================================

CREATE ROLE replicator
WITH LOGIN REPLICATION PASSWORD 'YOUR_REPLICATION_PASSWORD';

GRANT CONNECT ON DATABASE company TO replicator;