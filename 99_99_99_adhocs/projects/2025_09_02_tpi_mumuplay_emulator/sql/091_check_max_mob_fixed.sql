-- Check maximum MOB in the data
WITH us_mob AS (
    SELECT DISTINCT
        DATEDIFF('month', m.created_at, a._creation_timestamp) as mob_months
    FROM RISK.TEST.all_logins_with_dwn a
    INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
    WHERE a.country_code = 'USA'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1
),
taiwan_mob AS (
    SELECT DISTINCT
        DATEDIFF('month', m.created_at, a._creation_timestamp) as mob_months
    FROM RISK.TEST.all_logins_with_dwn a
    INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
    WHERE a.country_code = 'TWN'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1
)
SELECT 
    'US Network Carrier' as group_name,
    MIN(mob_months) as min_mob,
    MAX(mob_months) as max_mob,
    AVG(mob_months) as avg_mob
FROM us_mob

UNION ALL

SELECT 
    'Taiwan Network Carrier' as group_name,
    MIN(mob_months) as min_mob,
    MAX(mob_months) as max_mob,
    AVG(mob_months) as avg_mob
FROM taiwan_mob;
