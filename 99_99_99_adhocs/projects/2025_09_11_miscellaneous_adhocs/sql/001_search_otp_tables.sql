-- Title: Search for OTP Related Tables
-- Intent: Find tables containing "otp" in segment.chime_prod and streaming_platform.segment_and_hawker_production
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- Search in segment.chime_prod schema
-- ============================================================================

SELECT 
    'segment.chime_prod' as schema_name,
    table_name,
    table_type,
    created as table_created,
    last_altered,
    row_count,
    bytes
FROM segment.chime_prod.information_schema.tables
WHERE LOWER(table_name) LIKE '%otp%'
ORDER BY table_name;

-- ============================================================================
-- Search in streaming_platform.segment_and_hawker_production schema
-- ============================================================================

SELECT 
    'streaming_platform.segment_and_hawker_production' as schema_name,
    table_name,
    table_type,
    created as table_created,
    last_altered,
    row_count,
    bytes
FROM streaming_platform.segment_and_hawker_production.information_schema.tables
WHERE LOWER(table_name) LIKE '%otp%'
ORDER BY table_name;

-- ============================================================================
-- Also search for related authentication/verification tables
-- ============================================================================

-- Search for verification, auth, sms related tables in segment.chime_prod
SELECT 
    'segment.chime_prod - auth related' as search_type,
    table_name,
    table_type
FROM segment.chime_prod.information_schema.tables
WHERE LOWER(table_name) LIKE '%verification%'
   OR LOWER(table_name) LIKE '%auth%'
   OR LOWER(table_name) LIKE '%sms%'
   OR LOWER(table_name) LIKE '%code%'
ORDER BY table_name;

-- Search for verification, auth, sms related tables in streaming_platform
SELECT 
    'streaming_platform - auth related' as search_type,
    table_name,
    table_type
FROM streaming_platform.segment_and_hawker_production.information_schema.tables
WHERE LOWER(table_name) LIKE '%verification%'
   OR LOWER(table_name) LIKE '%auth%'
   OR LOWER(table_name) LIKE '%sms%'
   OR LOWER(table_name) LIKE '%code%'
ORDER BY table_name;
