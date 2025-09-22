-- Title: Search for OTP and Eligible Related Tables
-- Intent: Search for tables with "otp" or "eligible" in the name across two schemas
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- Search segment.chime_prod for tables containing "otp"
-- ============================================================================

SHOW TABLES LIKE '%otp%' IN segment.chime_prod;

-- ============================================================================
-- Search streaming_platform.segment_and_hawker_production for tables containing "otp"
-- ============================================================================

SHOW TABLES LIKE '%otp%' IN streaming_platform.segment_and_hawker_production;

-- ============================================================================
-- Search for "eligible" patterns
-- ============================================================================

SHOW TABLES LIKE '%eligible%' IN segment.chime_prod;
SHOW TABLES LIKE '%eligible%' IN streaming_platform.segment_and_hawker_production;

-- ============================================================================
-- Search for uppercase versions
-- ============================================================================

SHOW TABLES LIKE '%OTP%' IN segment.chime_prod;
SHOW TABLES LIKE '%OTP%' IN streaming_platform.segment_and_hawker_production;

SHOW TABLES LIKE '%ELIGIBLE%' IN segment.chime_prod;
SHOW TABLES LIKE '%ELIGIBLE%' IN streaming_platform.segment_and_hawker_production;
