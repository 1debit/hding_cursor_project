-- Title: Update FarEasTone Active Users Table with MOB Column
-- Intent: Recreate only the final active users table with MOB (Months on Book) added
-- Note: Avoiding recreation of hding_fareastone_usa_logins (takes very long time)
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- Recreate final active users table with MOB column
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
-- Summary statistics with MOB analysis
-- ============================================================================

-- Count summary with MOB statistics
SELECT
    'Summary Statistics with MOB' as analysis_type,
    COUNT(*) as total_active_users,
    MIN(first_taiwan_login_time) as earliest_login,
    MAX(first_taiwan_login_time) as latest_login,
    MIN(mob_at_login_time) as min_mob,
    MAX(mob_at_login_time) as max_mob,
    ROUND(AVG(mob_at_login_time), 2) as avg_mob
FROM risk.test.fareastone_usa_active_users;

-- MOB distribution
SELECT
    CASE
        WHEN mob_at_login_time = 0 THEN '0 months (New users)'
        WHEN mob_at_login_time BETWEEN 1 AND 3 THEN '1-3 months'
        WHEN mob_at_login_time BETWEEN 4 AND 6 THEN '4-6 months'
        WHEN mob_at_login_time BETWEEN 7 AND 12 THEN '7-12 months'
        WHEN mob_at_login_time > 12 THEN '12+ months'
        ELSE 'Unknown'
    END as mob_category,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM risk.test.fareastone_usa_active_users
GROUP BY 1
ORDER BY MIN(mob_at_login_time);

-- Final output for fraud investigators (with MOB)
SELECT
    user_id,
    first_taiwan_login_time,
    user_status,
    user_has_activated_physical_card,
    user_is_payroll_dd,
    mob_at_login_time
FROM risk.test.fareastone_usa_active_users
ORDER BY first_taiwan_login_time DESC
LIMIT 10;
