-- Title: USA vs Foreign Network Carrier Summary
-- Intent: Compare USA vs Foreign network carriers across all key metrics
-- Inputs: RISK.TEST.all_logins_with_dwn
-- Output: Summary table comparing USA vs Foreign network carriers

-- USA vs Foreign Network Carrier Summary
SELECT
    CASE
        WHEN country_code = 'USA' THEN 'USA Network Carrier'
        ELSE 'Foreign Network Carrier'
    END as network_carrier_type,
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
FROM RISK.TEST.all_logins_with_dwn
GROUP BY CASE
    WHEN country_code = 'USA' THEN 'USA Network Carrier'
    ELSE 'Foreign Network Carrier'
END
ORDER BY total_logins DESC;
