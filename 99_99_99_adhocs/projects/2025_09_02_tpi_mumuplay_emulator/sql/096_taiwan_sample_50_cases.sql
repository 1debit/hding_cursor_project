-- Title: Taiwan Network Carrier Sample Cases (50 Users)
-- Intent: Generate sample of Taiwan network carrier users with comprehensive user profile data
-- Inputs: RISK.TEST.all_logins_with_dwn (Taiwan network carrier data)
-- Output: 50 sample cases with user profile, MOB, card activation, payroll DD, and status
-- Author: Data Team
-- Created: 2025-09-08

-- Create sample table with 50 Taiwan network carrier users
CREATE OR REPLACE TABLE RISK.TEST.taiwan_sample_50_cases AS
SELECT
    a.user_id,
    m.created_at as account_creation_date,
    DATEDIFF(month, m.created_at, CURRENT_DATE()) as mob_as_of_today,
    a._creation_timestamp as login_date,
    CASE WHEN c.user_has_activated_physical_card = true THEN 'Y' ELSE 'N' END as card_activated,
    CASE WHEN c.user_is_payroll_dd = true THEN 'Y' ELSE 'N' END as dder_payroll,
    m.status as user_status
FROM RISK.TEST.all_logins_with_dwn a
LEFT JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
LEFT JOIN (
    SELECT
        user_id,
        user_has_activated_physical_card,
        user_is_payroll_dd
    FROM chime.decision_platform.base_user_fields
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY NULL) = 1
) c ON (a.user_id = c.user_id)
WHERE 1=1
    AND a.country_code = 'TWN'  -- Taiwan network carrier
    AND a.ip_country = 'USA'    -- USA IP address
    AND a.mapping_status = 'Mapped'
    AND a.country_name != 'Unknown'
    AND m.created_at IS NOT NULL  -- Ensure we have account creation date
    AND m.status = 'active'  -- Active users only
ORDER BY RANDOM()  -- Random sampling
LIMIT 50;

-- Display the sample results
SELECT
    user_id,
    account_creation_date,
    mob_as_of_today,
    login_date,
    card_activated,
    dder_payroll,
    user_status
FROM RISK.TEST.taiwan_sample_50_cases
ORDER BY mob_as_of_today DESC, user_id;
