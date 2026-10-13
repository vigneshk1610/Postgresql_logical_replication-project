-- =====================================================
-- PURPOSE: Verify replication is ready before data insert
-- =====================================================

-- Run in company (publisher)
SELECT
    application_name,
    client_addr,
    state,
    sent_lsn,
    replay_lsn
FROM pg_stat_replication;

SELECT
    slot_name,
    slot_type,
    plugin,
    active,
    restart_lsn
FROM pg_replication_slots;

-- Run in company_replica (subscriber)
SELECT
    subname,
    enabled,
    pid,
    received_lsn,
    latest_end_lsn
FROM pg_stat_subscription;

SELECT
    srrelid::regclass AS table_name,
    srsubstate
FROM pg_subscription_rel;