-- Title: Export Taiwan Sample Cases
-- Intent: Query the Taiwan sample cases for Excel export
-- Output: 50 Taiwan network carrier sample cases with user profile data

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
