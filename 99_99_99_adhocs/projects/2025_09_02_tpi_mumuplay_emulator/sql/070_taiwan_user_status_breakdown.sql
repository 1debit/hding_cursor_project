-- Title: Taiwan Network Carrier User Status Breakdown
-- Intent: Analyze the status breakdown of Taiwan network carrier users with USA IP
-- Inputs: RISK.TEST.hding_a3id_login_info_enriched, chime.finance.members, risk.test.hding_a3id_login_with_outcome
-- Output: Detailed status breakdown for Taiwan users to understand inactive user patterns
-- Assumptions: July 2025 data, successful logins only, Taiwan network carriers with USA IP

-- Taiwan user status breakdown
SELECT
    c.status as user_status,
    COUNT(DISTINCT a.user_id) as distinct_users,
    ROUND(COUNT(DISTINCT a.user_id) * 100.0 / SUM(COUNT(DISTINCT a.user_id)) OVER(), 2) as percentage_of_total
FROM RISK.TEST.hding_a3id_login_info_enriched a
INNER JOIN risk.test.hding_a3id_login_with_outcome b
    ON (a.a3id = b.account_access_attempt_id)
LEFT JOIN chime.finance.members c
    ON (a.user_id = c.id::varchar)
WHERE 1=1
    AND a.ip_country = 'USA'
    AND b.reconciled_outcome = 'login_successful'
    AND a.country_code = 'TWN'
    AND a.country_name != 'Unknown'
GROUP BY c.status
ORDER BY distinct_users DESC;

-- Additional analysis: Taiwan users by status with login counts
SELECT
    c.status as user_status,
    COUNT(DISTINCT a.user_id) as distinct_users,
    COUNT(*) as total_logins,
    ROUND(AVG(COUNT(*)) OVER (PARTITION BY c.status), 2) as avg_logins_per_user,
    ROUND(COUNT(DISTINCT a.user_id) * 100.0 / SUM(COUNT(DISTINCT a.user_id)) OVER(), 2) as percentage_of_total
FROM RISK.TEST.hding_a3id_login_info_enriched a
INNER JOIN risk.test.hding_a3id_login_with_outcome b
    ON (a.a3id = b.account_access_attempt_id)
LEFT JOIN chime.finance.members c
    ON (a.user_id = c.id::varchar)
WHERE 1=1
    AND a.ip_country = 'USA'
    AND b.reconciled_outcome = 'login_successful'
    AND a.country_code = 'TWN'
    AND a.country_name != 'Unknown'
GROUP BY c.status
ORDER BY distinct_users DESC;
