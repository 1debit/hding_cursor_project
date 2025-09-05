-- Updated Taiwan Inactive User Status MOB Distribution
WITH taiwan_inactive_users AS (
    SELECT DISTINCT
        a.user_id,
        DATEDIFF('month', m.created_at, a._creation_timestamp) as mob_months
    FROM RISK.TEST.all_logins_with_dwn a
    INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
    WHERE a.country_code = 'TWN'
        AND m.status != 'active'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1
)
SELECT
    CASE
        WHEN mob_months = 0 THEN '0'
        WHEN mob_months BETWEEN 1 AND 3 THEN '1-3'
        WHEN mob_months BETWEEN 4 AND 6 THEN '4-6'
        WHEN mob_months BETWEEN 7 AND 12 THEN '7-12'
        WHEN mob_months > 12 THEN '12+'
        ELSE 'Unknown'
    END as mob_range,
    COUNT(*) as user_count
FROM taiwan_inactive_users
GROUP BY 1
ORDER BY
    CASE
        WHEN mob_range = '0' THEN 1
        WHEN mob_range = '1-3' THEN 2
        WHEN mob_range = '4-6' THEN 3
        WHEN mob_range = '7-12' THEN 4
        WHEN mob_range = '12+' THEN 5
        ELSE 6
    END;
