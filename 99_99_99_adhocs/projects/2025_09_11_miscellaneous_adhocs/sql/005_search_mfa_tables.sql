-- Title: Search for MFA Related Tables
-- Intent: Search for tables with "mfa" in the name across two schemas
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- Search segment.chime_prod for tables containing "mfa"
-- ============================================================================

SHOW TABLES LIKE '%mfa%' IN segment.chime_prod;

-- ============================================================================
-- Search streaming_platform.segment_and_hawker_production for tables containing "mfa"
-- ============================================================================

SHOW TABLES LIKE '%mfa%' IN streaming_platform.segment_and_hawker_production;

-- ============================================================================
-- Also search for MFA (uppercase) and related patterns
-- ============================================================================

-- Search for MFA (uppercase)
SHOW TABLES LIKE '%MFA%' IN segment.chime_prod;
SHOW TABLES LIKE '%MFA%' IN streaming_platform.segment_and_hawker_production;

-- Search for related 2FA patterns
SHOW TABLES LIKE '%2fa%' IN segment.chime_prod;
SHOW TABLES LIKE '%2fa%' IN streaming_platform.segment_and_hawker_production;

-- Search for multi factor patterns
SHOW TABLES LIKE '%multi%factor%' IN segment.chime_prod;
SHOW TABLES LIKE '%multi%factor%' IN streaming_platform.segment_and_hawker_production;
