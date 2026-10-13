-- =====================================================
-- PURPOSE: Create subscription using manually created slot
-- =====================================================

CREATE SUBSCRIPTION sales_subscription
CONNECTION
'host=127.0.0.1 port=5432 dbname=company user=replicator password=YOUR_REPLICATION_PASSWORD'
PUBLICATION sales_publication
WITH
(
    slot_name = 'sales_subscription',
    copy_data = true,
    create_slot = false,
    enabled = true
);