-- Title: Foreign Network Carrier Countries with USA IP Analysis
-- Intent: Analyze foreign network carrier countries (NOT USA) when IP country is USA
-- Inputs: RISK.TEST.hding_a3id_login_info_enriched, chime.finance.members, risk.test.hding_a3id_login_with_outcome
-- Output: Foreign network carrier countries with login counts, distinct users, active users, and percentages
-- Assumptions: July 2025 data, successful logins only, IP country = USA, foreign network carriers only
-- Research: country_code uses 3-character codes (USA, TWN, UNK, etc.)

-- Main analysis: Foreign network carrier countries with USA IP
SELECT
    a.country_code as network_carrier_country,
    COUNT(*) as total_logins,
    COUNT(DISTINCT a.user_id) as distinct_users,
    COUNT(DISTINCT CASE WHEN c.status = 'active' THEN a.user_id END) as distinct_active_users,
    ROUND(
        COUNT(DISTINCT CASE WHEN c.status = 'active' THEN a.user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT a.user_id), 0), 2
    ) as active_user_percentage
FROM RISK.TEST.hding_a3id_login_info_enriched a
INNER JOIN risk.test.hding_a3id_login_with_outcome b
    ON (a.a3id = b.account_access_attempt_id)
LEFT JOIN chime.finance.members c
    ON (a.user_id = c.id::varchar)
WHERE 1=1
    AND a.ip_country = 'USA'                      -- USA IP country only
    AND b.reconciled_outcome = 'login_successful' -- Successful logins only
    AND a.country_code IS NOT NULL                -- Must have network carrier country code
    AND a.country_code != 'USA'                   -- Exclude USA network carriers (foreign only)
    AND a.country_name != 'Unknown'               -- Exclude unknown countries
GROUP BY a.country_code
ORDER BY distinct_users DESC;

-- Summary: Total foreign carriers with USA IP
SELECT
    'Summary' as analysis_type,
    COUNT(DISTINCT a.country_code) as total_foreign_countries,
    COUNT(*) as total_logins,
    COUNT(DISTINCT a.user_id) as total_distinct_users,
    COUNT(DISTINCT CASE WHEN c.status = 'active' THEN a.user_id END) as total_active_users,
    ROUND(
        COUNT(DISTINCT CASE WHEN c.status = 'active' THEN a.user_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT a.user_id), 0), 2
    ) as overall_active_percentage
FROM RISK.TEST.hding_a3id_login_info_enriched a
INNER JOIN risk.test.hding_a3id_login_with_outcome b
    ON (a.a3id = b.account_access_attempt_id)
LEFT JOIN chime.finance.members c
    ON (a.user_id = c.id::varchar)
WHERE 1=1
    AND a.ip_country = 'USA'
    AND b.reconciled_outcome = 'login_successful'
    AND a.country_code IS NOT NULL
    AND a.country_code != 'USA'
    AND a.country_name != 'Unknown';
