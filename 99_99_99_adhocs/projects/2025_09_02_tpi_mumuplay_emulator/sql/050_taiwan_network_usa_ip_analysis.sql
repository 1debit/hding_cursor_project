-- Title: Taiwan Network Carrier + USA IP + Low Month on Book Users
-- Intent: Find users with Taiwan network carriers, USA IP country, and <3 months on book at login time
-- Inputs: RISK.TEST.hding_a3id_login_info_enriched, chime.finance.members, risk.test.hding_a3id_login_with_outcome
-- Output: 20 user_ids with Taiwan network, USA IP, and <3 months on book
-- Assumptions: Using mapped country codes, July 2025 data only, successful logins only
-- Validation: Check that MOB calculation matches 000_input.sql methodology

SELECT
    a.user_id,
    a._creation_timestamp as login_timestamp,
    c.created_at as account_creation_date,
    DATEDIFF(month, c.created_at, a._creation_timestamp) as months_on_book,
    a.network_carrier,
    a.network_carrier_country,
    a.ip_carrier,
    a.ip_country,
    a.platform,
    a.atom_v3
FROM RISK.TEST.hding_a3id_login_info_enriched a
INNER JOIN risk.test.hding_a3id_login_with_outcome b
    ON (a.a3id = b.account_access_attempt_id)
LEFT JOIN chime.finance.members c
    ON (a.user_id = c.id::varchar)
WHERE 1=1
    AND a.country_code = 'TWN'                    -- Taiwan network carrier
    AND a.mapping_status = 'Mapped'               -- Only mapped carriers
    AND a.ip_country = 'USA'                      -- USA IP country
    AND b.reconciled_outcome = 'login_successful' -- Successful logins only
    AND c.created_at IS NOT NULL                  -- Must have account creation date
    AND DATEDIFF(month, c.created_at, a._creation_timestamp) < 3  -- Less than 3 months on book
ORDER BY months_on_book ASC, a._creation_timestamp DESC
LIMIT 20;
