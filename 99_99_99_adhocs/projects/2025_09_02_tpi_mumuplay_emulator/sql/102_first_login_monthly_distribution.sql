-- Title: FarEasTone Active Users - First Login Monthly Distribution
-- Intent: Analyze distribution of users by their first Taiwan login month
-- Author: Data Team
-- Created: 2025-09-22

-- ============================================================================
-- Monthly distribution by first login time
-- ============================================================================

SELECT
    DATE_TRUNC('month', first_taiwan_login_time) as login_month,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    -- Cumulative count
    SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC('month', first_taiwan_login_time)) as cumulative_users,
    ROUND(SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC('month', first_taiwan_login_time)) * 100.0 / SUM(COUNT(*)) OVER (), 2) as cumulative_percentage
FROM risk.test.fareastone_usa_active_users
GROUP BY DATE_TRUNC('month', first_taiwan_login_time)
ORDER BY login_month;

-- ============================================================================
-- Monthly distribution with MOB breakdown
-- ============================================================================

SELECT
    DATE_TRUNC('month', first_taiwan_login_time) as login_month,
    COUNT(*) as total_users,
    -- MOB breakdown
    SUM(CASE WHEN mob_at_login_time = 0 THEN 1 ELSE 0 END) as new_users_0_months,
    SUM(CASE WHEN mob_at_login_time BETWEEN 1 AND 3 THEN 1 ELSE 0 END) as users_1_3_months,
    SUM(CASE WHEN mob_at_login_time BETWEEN 4 AND 12 THEN 1 ELSE 0 END) as users_4_12_months,
    SUM(CASE WHEN mob_at_login_time > 12 THEN 1 ELSE 0 END) as users_12plus_months,
    -- Percentages
    ROUND(SUM(CASE WHEN mob_at_login_time = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pct_new_users
FROM risk.test.fareastone_usa_active_users
GROUP BY DATE_TRUNC('month', first_taiwan_login_time)
ORDER BY login_month;

-- ============================================================================
-- Weekly trend for recent months (last 3 months)
-- ============================================================================

SELECT
    DATE_TRUNC('week', first_taiwan_login_time) as login_week,
    COUNT(*) as user_count,
    ROUND(AVG(mob_at_login_time), 2) as avg_mob,
    SUM(CASE WHEN mob_at_login_time = 0 THEN 1 ELSE 0 END) as new_users_count,
    ROUND(SUM(CASE WHEN mob_at_login_time = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pct_new_users
FROM risk.test.fareastone_usa_active_users
WHERE first_taiwan_login_time >= DATEADD('month', -3, CURRENT_DATE())
GROUP BY DATE_TRUNC('week', first_taiwan_login_time)
ORDER BY login_week DESC;
