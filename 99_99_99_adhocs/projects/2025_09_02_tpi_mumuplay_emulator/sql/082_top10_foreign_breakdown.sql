-- Title: Top 10 + Other Foreign Carriers Breakdown
-- Intent: Analyze top 10 foreign countries + rest grouped as 'other foreign'
-- Inputs: RISK.TEST.all_logins_with_dwn
-- Output: Breakdown of foreign carriers with comprehensive metrics

-- Top 10 + Other Foreign Carriers Breakdown
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
    -- Active User Analysis
    COUNT(DISTINCT CASE WHEN user_status = 'active' THEN user_id END) as active_users,
    ROUND(COUNT(DISTINCT CASE WHEN user_status = 'active' THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) as active_user_percentage,
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
