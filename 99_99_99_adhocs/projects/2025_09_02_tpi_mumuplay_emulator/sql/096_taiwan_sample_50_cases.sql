-- Title: Taiwan Network Carrier Sample Cases (50 Users)
-- Intent: Generate sample of Taiwan network carrier users with comprehensive user profile data
-- Inputs: RISK.TEST.all_logins_with_dwn (Taiwan network carrier data)
-- Output: 50 sample cases with user profile, MOB, card activation, payroll DD, and status
-- Author: Data Team
-- Created: 2025-09-08

-- Create sample table with 50 Taiwan network carrier users
CREATE OR REPLACE TABLE RISK.TEST.taiwan_sample_50_cases AS
WITH taiwan_users AS (
    SELECT DISTINCT
        l.user_id,
        m.enrollment_initiated_ts AS account_creation_date,
        DATEDIFF('month', m.enrollment_initiated_ts, CURRENT_DATE()) AS mob_as_of_today,
        l._creation_timestamp AS login_date,
        CASE WHEN l.user_has_activated_physical_card = 'true' THEN 'Yes' ELSE 'No' END AS card_activated,
        CASE WHEN l.user_is_payroll_dd = 'true' THEN 'Yes' ELSE 'No' END AS dder_payroll,
        l.user_status
    FROM RISK.TEST.all_logins_with_dwn l
    JOIN edw_db.core.member_details m ON l.user_id = m.user_id
    WHERE l.network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'T Star')
        AND l.user_status = 'active'
        AND l._creation_timestamp >= '2024-01-01'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY l.user_id ORDER BY l._creation_timestamp DESC) = 1
)
SELECT *
FROM taiwan_users
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
