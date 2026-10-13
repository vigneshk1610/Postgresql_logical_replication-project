-- =====================================================
-- FILE: 01_server_configuration.sql
-- DATABASE: postgres
-- PURPOSE: Enable logical replication
-- =====================================================

-- Records row-level changes needed by logical replication.
-- Default is replica, which is enough for recovery and
-- physical replication but not logical replication.
ALTER SYSTEM SET wal_level = 'logical';

-- Maximum number of WAL sender processes.
-- Each subscriber needs one WAL sender.
ALTER SYSTEM SET max_wal_senders = 10;

-- Maximum number of replication slots.
-- A replication slot tracks subscriber progress.
ALTER SYSTEM SET max_replication_slots = 10;

-- Verify after PostgreSQL restart
SHOW wal_level;
SHOW max_wal_senders;
SHOW max_replication_slots;