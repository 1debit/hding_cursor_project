-- Title: Simple OTP Table Name Search
-- Intent: Search for tables with "otp" in the name across two schemas
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
-- Also search for related patterns (case insensitive)
-- ============================================================================

-- Search for OTP (uppercase)
SHOW TABLES LIKE '%OTP%' IN segment.chime_prod;
SHOW TABLES LIKE '%OTP%' IN streaming_platform.segment_and_hawker_production;

-- Search for verification patterns
SHOW TABLES LIKE '%verification%' IN segment.chime_prod;
SHOW TABLES LIKE '%verification%' IN streaming_platform.segment_and_hawker_production;
