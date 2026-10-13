-- =====================================================
-- FILE: 07_create_subscriber_table.sql
-- DATABASE: company_replica
-- PURPOSE: Create EMPTY subscriber table
-- =====================================================

CREATE TABLE public.customers
(
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    city          VARCHAR(100),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Confirm subscriber table is empty
SELECT COUNT(*) AS subscriber_row_count
FROM public.customers;