-- Title: Taiwan vs US Network Carrier ATOM Score Comparison (Successful Logins Only)
-- Intent: Compare ATOM score distributions between Taiwan and US network carriers for successful logins
-- Inputs: RISK.TEST.hding_a3id_login_info, RISK.TEST.hding_a3id_login_with_outcome
-- Output: ATOM score distribution comparison with categories: <0.1, 0.1-0.5, 0.5-0.8, >0.8

WITH successful_logins AS (
    -- Join login info with successful outcomes only
    SELECT
        a.user_id,
        a.network_carrier,
        a.atom_v3,
        a.platform,
        a.ip_country,
        a._creation_timestamp,
        b.reconciled_outcome
    FROM RISK.TEST.hding_a3id_login_info a
    INNER JOIN RISK.TEST.hding_a3id_login_with_outcome b
        ON (a.a3id = b.account_access_attempt_id)
    WHERE a.atom_v3 IS NOT NULL
      AND a.network_carrier IS NOT NULL
      AND b.reconciled_outcome = 'login_successful'
),

carrier_classification AS (
    SELECT
        user_id,
        network_carrier,
        atom_v3,
        platform,
        ip_country,
        _creation_timestamp,
        -- Classify carriers as Taiwan or US
        CASE
            WHEN network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'Taiwan Star')
                OR network_carrier LIKE '%Taiwan%'
                OR network_carrier LIKE '%FET%'
                OR UPPER(network_carrier) LIKE '%SAFETYNET%'
            THEN 'Taiwan'
            WHEN network_carrier IN ('Verizon', 'AT&T', 'T-Mobile', 'Sprint', 'T-Mobile US', 'AT&T Mobility')
                OR network_carrier LIKE '%Verizon%'
                OR network_carrier LIKE '%AT&T%'
                OR network_carrier LIKE '%T-Mobile%'
                OR network_carrier LIKE '%Sprint%'
            THEN 'US'
            ELSE 'Other'
        END as carrier_country,

        -- ATOM score categories
        CASE
            WHEN atom_v3 < 0.1 THEN '<0.1 (Very Low)'
            WHEN atom_v3 >= 0.1 AND atom_v3 < 0.5 THEN '0.1-0.5 (Low-Medium)'
            WHEN atom_v3 >= 0.5 AND atom_v3 < 0.8 THEN '0.5-0.8 (High)'
            WHEN atom_v3 >= 0.8 THEN '>0.8 (Very High)'
        END as atom_category
    FROM successful_logins
),

taiwan_us_comparison AS (
    SELECT
        carrier_country,
        atom_category,
        COUNT(*) as login_count,
        COUNT(DISTINCT user_id) as unique_users,
        ROUND(AVG(atom_v3), 4) as avg_atom_score_in_category
    FROM carrier_classification
    WHERE carrier_country IN ('Taiwan', 'US')
    GROUP BY carrier_country, atom_category
),

summary_stats AS (
    SELECT
        carrier_country,
        COUNT(*) as total_logins,
        COUNT(DISTINCT user_id) as total_unique_users,
        ROUND(AVG(atom_v3), 4) as overall_avg_atom,
        ROUND(MEDIAN(atom_v3), 4) as overall_median_atom,
        ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY atom_v3), 4) as p75_atom,
        ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY atom_v3), 4) as p90_atom,
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY atom_v3), 4) as p95_atom
    FROM carrier_classification
    WHERE carrier_country IN ('Taiwan', 'US')
    GROUP BY carrier_country
)

-- Main comparison results
SELECT
    'COMPARISON' as result_type,
    t.carrier_country,
    t.atom_category,
    t.login_count,
    t.unique_users,
    t.avg_atom_score_in_category,
    ROUND(t.login_count * 100.0 / s.total_logins, 2) as percentage_of_carrier_logins,
    s.total_logins,
    s.total_unique_users,
    s.overall_avg_atom,
    s.overall_median_atom,
    s.p75_atom,
    s.p90_atom,
    s.p95_atom
FROM taiwan_us_comparison t
JOIN summary_stats s ON t.carrier_country = s.carrier_country

UNION ALL

-- Add summary row for context
SELECT
    'SUMMARY' as result_type,
    carrier_country,
    'TOTAL' as atom_category,
    total_logins as login_count,
    total_unique_users as unique_users,
    overall_avg_atom as avg_atom_score_in_category,
    100.00 as percentage_of_carrier_logins,
    total_logins,
    total_unique_users,
    overall_avg_atom,
    overall_median_atom,
    p75_atom,
    p90_atom,
    p95_atom
FROM summary_stats

ORDER BY
    result_type DESC,
    CASE WHEN carrier_country = 'Taiwan' THEN 1 ELSE 2 END,
    CASE
        WHEN atom_category = '<0.1 (Very Low)' THEN 1
        WHEN atom_category = '0.1-0.5 (Low-Medium)' THEN 2
        WHEN atom_category = '0.5-0.8 (High)' THEN 3
        WHEN atom_category = '>0.8 (Very High)' THEN 4
        ELSE 5
    END;
