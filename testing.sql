-- =====================================================
-- FILE: insert_test_data.sql
-- DATABASE: company
-- PURPOSE: Final step - insert first replication test data
-- =====================================================

INSERT INTO public.customers
(
    customer_name,
    email,
    city
)
VALUES
(
    'Vignesh Kumar',
    'vignesh@example.com',
    'Chennai'
);

-- Verify publisher data
SELECT *
FROM public.customers;