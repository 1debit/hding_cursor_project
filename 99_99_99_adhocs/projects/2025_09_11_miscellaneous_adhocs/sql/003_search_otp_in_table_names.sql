-- Title: Search for OTP in Table Names
-- Intent: Filter table names containing "otp", "verification", "sms", "auth" patterns
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- Search for OTP related patterns in segment.chime_prod
-- ============================================================================

SELECT 
    'segment.chime_prod' as schema_name,
    "name" as table_name,
    "rows" as row_count,
    "bytes" as table_size_bytes
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-2)))  -- Reference the segment.chime_prod SHOW TABLES result
WHERE LOWER("name") LIKE '%otp%'
   OR LOWER("name") LIKE '%verification%'
   OR LOWER("name") LIKE '%sms%'
   OR LOWER("name") LIKE '%auth%'
   OR LOWER("name") LIKE '%code%'
   OR LOWER("name") LIKE '%verify%'
ORDER BY "name";

-- Let's also run the SHOW TABLES again and then search
SHOW TABLES IN segment.chime_prod;

-- Search results from the above query
SELECT 
    'segment.chime_prod - OTP related' as search_category,
    "name" as table_name,
    "rows" as row_count
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE LOWER("name") LIKE '%otp%'
   OR LOWER("name") LIKE '%verification%'
   OR LOWER("name") LIKE '%sms%'
   OR LOWER("name") LIKE '%auth%'
   OR LOWER("name") LIKE '%code%'
   OR LOWER("name") LIKE '%verify%'
ORDER BY "name";

-- ============================================================================
-- Search for OTP related patterns in streaming_platform
-- ============================================================================

SHOW TABLES IN streaming_platform.segment_and_hawker_production;

-- Search results from the above query
SELECT 
    'streaming_platform - OTP related' as search_category,
    "name" as table_name,
    "rows" as row_count
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE LOWER("name") LIKE '%otp%'
   OR LOWER("name") LIKE '%verification%'
   OR LOWER("name") LIKE '%sms%'
   OR LOWER("name") LIKE '%auth%'
   OR LOWER("name") LIKE '%code%'
   OR LOWER("name") LIKE '%verify%'
ORDER BY "name";
