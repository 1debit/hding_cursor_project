-- Title: Comprehensive Network Carrier + Darwinium Device Intelligence Analysis
-- Intent: Join ALL network carrier logins (USA + Foreign) with DWN device intelligence data to analyze emulator indicators
-- Inputs: RISK.TEST.hding_a3id_login_info_enriched, STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE
-- Output: All logins enriched with DWN device intelligence data for comprehensive fraud detection analysis
-- Assumptions: July 2025 data, successful logins only, all network carriers with USA IP


-- ============================================================================
-- COMPREHENSIVE ANALYSIS: ALL NETWORK CARRIER COUNTRIES + DWN
-- ============================================================================

-- Step 1: Create comprehensive DWN device intelligence data for all login events
CREATE OR REPLACE TABLE RISK.TEST.all_dwn_login_events AS
SELECT
    t.body as body_,
    t._device_id,
    t._user_id,
    TRY_PARSE_JSON(t.body):step_name::varchar as event_name,
    t._creation_timestamp as dwn_timestamp
FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE t
WHERE 1=1
    AND t.name = 'VENDOR_DARWINIUM'
    AND t._creation_timestamp::date BETWEEN '2025-07-01' AND '2025-07-31'
    AND TRY_PARSE_JSON(t.body):step_name::varchar = 'login';

-- Step 2: Join ALL network carrier logins (USA + Foreign) with DWN data, card activation, and payroll DD
CREATE OR REPLACE TABLE RISK.TEST.all_logins_with_dwn AS
SELECT
    a.*,
    d.body_ as dwn_body,
    d.event_name as dwn_event_name,
    d.dwn_timestamp,
    CASE WHEN d._device_id IS NOT NULL THEN 1 ELSE 0 END as has_dwn_data,
    c.user_has_activated_physical_card,
    c.user_is_payroll_dd,
    m.status as user_status
FROM RISK.TEST.hding_a3id_login_info_enriched a
INNER JOIN risk.test.hding_a3id_login_with_outcome b
    ON (a.a3id = b.account_access_attempt_id)
LEFT JOIN RISK.TEST.all_dwn_login_events d
    ON (a.device_id = d._device_id
        AND a._creation_timestamp::date = d.dwn_timestamp::date)
LEFT JOIN (
    SELECT
        user_id,
        user_has_activated_physical_card,
        user_is_payroll_dd
    FROM chime.decision_platform.base_user_fields
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY NULL) = 1
) c ON (a.user_id = c.user_id)
LEFT JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
WHERE 1=1
    AND a.ip_country = 'USA'
    AND b.reconciled_outcome = 'login_successful'
    AND a.country_code IS NOT NULL
    AND a.country_name != 'Unknown'
QUALIFY ROW_NUMBER() OVER (PARTITION BY a.a3id ORDER BY d.dwn_timestamp DESC) = 1;

-- Step 3: DWN mapping coverage analysis by country
SELECT
    country_code as network_carrier_country,
    country_name as network_carrier_country_name,
    COUNT(*) as total_logins,
    SUM(has_dwn_data) as logins_with_dwn_data,
    ROUND(SUM(has_dwn_data) * 100.0 / COUNT(*), 2) as dwn_mapping_percentage,
    COUNT(DISTINCT user_id) as total_users,
    COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) as users_with_dwn_data,
    ROUND(COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as user_dwn_mapping_percentage
FROM RISK.TEST.all_logins_with_dwn
GROUP BY country_code, country_name
ORDER BY total_logins DESC;

-- Step 4: Summary statistics for all countries
SELECT
    'All Countries Summary' as analysis_type,
    COUNT(DISTINCT country_code) as total_countries,
    COUNT(*) as total_logins,
    SUM(has_dwn_data) as total_logins_with_dwn,
    ROUND(SUM(has_dwn_data) * 100.0 / COUNT(*), 2) as overall_dwn_mapping_percentage,
    COUNT(DISTINCT user_id) as total_users,
    COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) as total_users_with_dwn,
    ROUND(COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as overall_user_dwn_mapping_percentage
FROM RISK.TEST.all_logins_with_dwn;

-- ============================================================================
-- COMPREHENSIVE ANALYSIS: DWN + CARD + PAYROLL DD
-- ============================================================================

-- Step 5: Comprehensive analysis by country (DWN + Card + Payroll DD)
SELECT
    country_code as network_carrier_country,
    country_name as network_carrier_country_name,
    COUNT(*) as total_logins,
    COUNT(DISTINCT user_id) as total_users,
    -- DWN Analysis
    SUM(has_dwn_data) as dwn_logins,
    ROUND(SUM(has_dwn_data) * 100.0 / COUNT(*), 2) as dwn_logins_percentage,
    COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) as dwn_users,
    ROUND(COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as dwn_users_percentage,
    -- Card Activation Analysis
    COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) as card_activated_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as card_activated_percentage,
    -- Payroll DD Analysis
    COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) as payroll_dder_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as payroll_dder_percentage
FROM RISK.TEST.all_logins_with_dwn
GROUP BY country_code, country_name
ORDER BY total_logins DESC;

-- Step 6: Overall summary statistics
SELECT
    'All Countries Comprehensive Summary' as analysis_type,
    COUNT(DISTINCT country_code) as total_countries,
    COUNT(*) as total_logins,
    COUNT(DISTINCT user_id) as total_users,
    -- DWN Summary
    SUM(has_dwn_data) as total_dwn_logins,
    ROUND(SUM(has_dwn_data) * 100.0 / COUNT(*), 2) as overall_dwn_logins_percentage,
    COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) as total_dwn_users,
    ROUND(COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as overall_dwn_users_percentage,
    -- Card Summary
    COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) as total_card_activated_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as overall_card_activated_percentage,
    -- Payroll Summary
    COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) as total_payroll_dder_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as overall_payroll_dder_percentage
FROM RISK.TEST.all_logins_with_dwn;

-- ============================================================================
-- ADDITIONAL SUMMARY TABLES
-- ============================================================================

-- Step 7: USA vs Foreign Network Carrier Summary
SELECT
    CASE
        WHEN country_code = 'USA' THEN 'USA Network Carrier'
        ELSE 'Foreign Network Carrier'
    END as network_carrier_type,
    COUNT(*) as total_logins,
    COUNT(DISTINCT user_id) as total_users,
    -- DWN Analysis
    SUM(has_dwn_data) as dwn_logins,
    ROUND(SUM(has_dwn_data) * 100.0 / COUNT(*), 2) as dwn_logins_percentage,
    COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) as dwn_users,
    ROUND(COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as dwn_users_percentage,
    -- Card Activation Analysis
    COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) as card_activated_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as card_activated_percentage,
    -- Payroll DD Analysis
    COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) as payroll_dder_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as payroll_dder_percentage
FROM RISK.TEST.all_logins_with_dwn
GROUP BY CASE
    WHEN country_code = 'USA' THEN 'USA Network Carrier'
    ELSE 'Foreign Network Carrier'
END
ORDER BY total_logins DESC;

-- Step 8: Top 10 + Other Foreign Carriers Breakdown
WITH top_10_foreign AS (
    SELECT
        country_code,
        country_name,
        COUNT(*) as login_count
    FROM RISK.TEST.all_logins_with_dwn
    WHERE country_code != 'USA'
    GROUP BY country_code, country_name
    ORDER BY login_count DESC
    LIMIT 10
),
all_foreign AS (
    SELECT
        country_code,
        country_name,
        COUNT(*) as login_count
    FROM RISK.TEST.all_logins_with_dwn
    WHERE country_code != 'USA'
    GROUP BY country_code, country_name
)
SELECT
    CASE
        WHEN t10.country_code IS NOT NULL THEN t10.country_code
        ELSE 'OTHER_FOREIGN'
    END as network_carrier_country,
    CASE
        WHEN t10.country_name IS NOT NULL THEN t10.country_name
        ELSE 'Other Foreign Countries'
    END as network_carrier_country_name,
    COUNT(*) as total_logins,
    COUNT(DISTINCT user_id) as total_users,
    -- DWN Analysis
    SUM(has_dwn_data) as dwn_logins,
    ROUND(SUM(has_dwn_data) * 100.0 / COUNT(*), 2) as dwn_logins_percentage,
    COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) as dwn_users,
    ROUND(COUNT(DISTINCT CASE WHEN has_dwn_data = 1 THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as dwn_users_percentage,
    -- Card Activation Analysis
    COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) as card_activated_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_has_activated_physical_card = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as card_activated_percentage,
    -- Payroll DD Analysis
    COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) as payroll_dder_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_is_payroll_dd = true THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as payroll_dder_percentage
FROM RISK.TEST.all_logins_with_dwn a
LEFT JOIN top_10_foreign t10 ON (a.country_code = t10.country_code)
WHERE a.country_code != 'USA'
GROUP BY
    CASE
        WHEN t10.country_code IS NOT NULL THEN t10.country_code
        ELSE 'OTHER_FOREIGN'
    END,
    CASE
        WHEN t10.country_name IS NOT NULL THEN t10.country_name
        ELSE 'Other Foreign Countries'
    END
ORDER BY total_logins DESC;
