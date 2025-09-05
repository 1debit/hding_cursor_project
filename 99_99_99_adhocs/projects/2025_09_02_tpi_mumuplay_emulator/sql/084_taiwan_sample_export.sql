-- Title: Taiwan Network Carrier Active Users Sample Export
-- Intent: Export complete sample of Taiwan users for analysis
-- Inputs: RISK.TEST.all_logins_with_dwn, chime.finance.members
-- Output: Complete sample data for Taiwan users

-- Taiwan Active Low MOB Users Complete Sample
SELECT
    a.user_id,
    a.network_carrier,
    a.country_name as network_carrier_country,
    a.ip_country,
    a.platform,
    a._creation_timestamp as login_timestamp,
    -- MOB Calculation (Month on Book)
    DATEDIFF('month', m.created_at, a._creation_timestamp) as month_on_book,
    -- User Status
    m.status as user_status,
    -- Card Activation Indicator
    CASE
        WHEN c.user_has_activated_physical_card = true THEN 'Yes'
        WHEN c.user_has_activated_physical_card = false THEN 'No'
        ELSE 'Unknown'
    END as card_activated_indicator,
    -- Payroll DD Indicator
    CASE
        WHEN c.user_is_payroll_dd = true THEN 'Yes'
        WHEN c.user_is_payroll_dd = false THEN 'No'
        ELSE 'Unknown'
    END as payroll_dder_indicator,
    -- DWN Data Availability
    CASE
        WHEN a.has_dwn_data = 1 THEN 'Yes'
        ELSE 'No'
    END as has_dwn_data_indicator,
    -- Additional Risk Indicators
    a.atom_v3 as risk_score,
    a.session_event as auth_method
FROM RISK.TEST.all_logins_with_dwn a
INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
LEFT JOIN (
    SELECT
        user_id,
        user_has_activated_physical_card,
        user_is_payroll_dd
    FROM chime.decision_platform.base_user_fields
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY NULL) = 1
) c ON (a.user_id = c.user_id)
WHERE 1=1
    AND a.country_code = 'TWN'
    AND a.country_name = 'Taiwan'
    AND m.status = 'active'
    AND DATEDIFF('month', m.created_at, a._creation_timestamp) < 3
QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1
ORDER BY a._creation_timestamp DESC
LIMIT 100;
