-- Taiwan Network Carrier MOB Distribution (All Users)
WITH taiwan_users AS (
    SELECT DISTINCT
        a.user_id,
        DATEDIFF('month', m.created_at, a._creation_timestamp) as mob_months
    FROM RISK.TEST.all_logins_with_dwn a
    INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
    WHERE a.country_code = 'TWN'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1
)
SELECT
    CASE
        WHEN mob_months = 0 THEN '0 months'
        WHEN mob_months = 1 THEN '1 month'
        WHEN mob_months = 2 THEN '2 months'
        WHEN mob_months BETWEEN 3 AND 6 THEN '3-6 months'
        WHEN mob_months BETWEEN 7 AND 12 THEN '7-12 months'
        WHEN mob_months BETWEEN 13 AND 24 THEN '13-24 months'
        WHEN mob_months > 24 THEN '25+ months'
        ELSE 'Unknown'
    END as mob_range,
    COUNT(*) as user_count
FROM taiwan_users
GROUP BY 1
ORDER BY
    CASE
        WHEN mob_range = '0 months' THEN 1
        WHEN mob_range = '1 month' THEN 2
        WHEN mob_range = '2 months' THEN 3
        WHEN mob_range = '3-6 months' THEN 4
        WHEN mob_range = '7-12 months' THEN 5
        WHEN mob_range = '13-24 months' THEN 6
        WHEN mob_range = '25+ months' THEN 7
        ELSE 8
    END;
