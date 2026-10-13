-- =====================================================
-- FILE: 05_create_publication.sql
-- DATABASE: company
-- PURPOSE: Publish customers table changes
-- =====================================================

CREATE PUBLICATION sales_publication
FOR TABLE public.customers
WITH
(
    publish = 'insert, update, delete, truncate'
);