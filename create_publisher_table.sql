-- =====================================================
-- FILE: 04_create_publisher_table.sql
-- DATABASE: company
-- PURPOSE: Create EMPTY publisher table
-- =====================================================

CREATE TABLE public.customers
(
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    city          VARCHAR(100),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

GRANT USAGE ON SCHEMA public TO replicator;

GRANT SELECT ON TABLE public.customers TO replicator;

-- Confirm table is empty before replication setup
SELECT COUNT(*) AS publisher_row_count
FROM public.customers;