-- Title: FarEasTone + USA IP 6-Month Historical Analysis
-- Intent: Extract all FarEasTone network carrier users with USA IP from past 6 months for fraud investigation
-- Inputs: chime.decision_platform.authn, STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG
-- Output: Active users with no card activation and no payroll DD (high fraud risk indicators)
-- Background: Previous sample showed ~95% bad account rate, expanding to full 6-month analysis
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- STEP 1: Create 6-month login outcome table
-- ============================================================================

CREATE OR REPLACE TABLE risk.test.hding_a3id_login_with_outcome_6months AS (
    SELECT
        account_access_attempt_id,
        reconciled_outcome,
        decision_id,
        user_id
    FROM chime.decision_platform.authn
    WHERE is_shadow_mode = false
        AND original_timestamp::date BETWEEN '2025-03-22' AND '2025-09-22'
        AND reconciled_outcome = 'login_successful'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_access_attempt_id ORDER BY original_timestamp DESC) = 1
);

-- ============================================================================
-- STEP 2: Create FarEasTone + USA IP login information table
-- ============================================================================

CREATE OR REPLACE TABLE risk.test.hding_fareastone_usa_logins AS (
    SELECT
        _creation_timestamp,
        request:atom_event:platform::varchar as platform,
        request:atom_event:network_carrier::varchar as network_carrier,
        request:atom_event:nu_risk_response:ip_country::varchar as ip_country,
        request:atom_event:account_access_attempt_id::varchar as a3id,
        decision_log.user_id
    FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG decision_log
    INNER JOIN risk.test.hding_a3id_login_with_outcome_6months b
        ON (decision_log.user_id = b.user_id AND decision_log.decision_id = b.decision_id)
    WHERE decision_log._creation_timestamp::date BETWEEN '2025-03-22' AND '2025-09-22'
        AND decision_log.event_name = 'atom_event'
        AND decision_log.labels:service_names != 'shadow'
        AND request:atom_event:nu_risk_response:ip_country::varchar = 'USA'
        AND request:atom_event:network_carrier::varchar = 'FarEasTone'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a3id ORDER BY _creation_timestamp) = 1
);

-- ============================================================================
-- STEP 3: Final active users table with fraud risk filters
-- ============================================================================

CREATE OR REPLACE TABLE risk.test.fareastone_usa_active_users AS (
    SELECT
        l.user_id,
        l._creation_timestamp as first_taiwan_login_time,
        m.status as user_status,
        c.user_has_activated_physical_card,
        c.user_is_payroll_dd,
        DATEDIFF('month', m.created_at, l._creation_timestamp) as mob_at_login_time
    FROM risk.test.hding_fareastone_usa_logins l
    LEFT JOIN chime.finance.members m ON l.user_id = m.id::varchar
    LEFT JOIN (
        SELECT * FROM chime.decision_platform.base_user_fields
        QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY NULL) = 1
    ) c ON l.user_id = c.user_id
    WHERE m.status = 'active'
        AND c.user_has_activated_physical_card = false
        AND c.user_is_payroll_dd = false
    QUALIFY ROW_NUMBER() OVER (PARTITION BY l.user_id ORDER BY l._creation_timestamp) = 1
);

-- ============================================================================
-- STEP 4: Summary statistics and validation
-- ============================================================================

-- Count summary
SELECT
    'Summary Statistics' as analysis_type,
    COUNT(*) as total_active_users,
    MIN(first_taiwan_login_time) as earliest_login,
    MAX(first_taiwan_login_time) as latest_login,
    COUNT(DISTINCT DATE_TRUNC('month', first_taiwan_login_time)) as months_covered
FROM risk.test.fareastone_usa_active_users;

-- Monthly distribution
SELECT
    DATE_TRUNC('month', first_taiwan_login_time) as login_month,
    COUNT(*) as user_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM risk.test.fareastone_usa_active_users
GROUP BY 1
ORDER BY 1;

-- Validation: Check for any users with card activation or payroll DD (should be 0)
SELECT
    'Validation Check' as check_type,
    SUM(CASE WHEN user_has_activated_physical_card = true THEN 1 ELSE 0 END) as users_with_card,
    SUM(CASE WHEN user_is_payroll_dd = true THEN 1 ELSE 0 END) as users_with_payroll_dd,
    COUNT(*) as total_users
FROM risk.test.fareastone_usa_active_users;

-- Final output for fraud investigators
SELECT
    user_id,
    first_taiwan_login_time,
    user_status,
    user_has_activated_physical_card,
    user_is_payroll_dd,
    mob_at_login_time
FROM risk.test.fareastone_usa_active_users
ORDER BY first_taiwan_login_time DESC;
