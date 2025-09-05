-- Check maximum MOB in the data
SELECT 
    'US Network Carrier' as group_name,
    MIN(DATEDIFF('month', m.created_at, a._creation_timestamp)) as min_mob,
    MAX(DATEDIFF('month', m.created_at, a._creation_timestamp)) as max_mob,
    AVG(DATEDIFF('month', m.created_at, a._creation_timestamp)) as avg_mob
FROM RISK.TEST.all_logins_with_dwn a
INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
WHERE a.country_code = 'USA'
QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1

UNION ALL

SELECT 
    'Taiwan Network Carrier' as group_name,
    MIN(DATEDIFF('month', m.created_at, a._creation_timestamp)) as min_mob,
    MAX(DATEDIFF('month', m.created_at, a._creation_timestamp)) as max_mob,
    AVG(DATEDIFF('month', m.created_at, a._creation_timestamp)) as avg_mob
FROM RISK.TEST.all_logins_with_dwn a
INNER JOIN chime.finance.members m ON (a.user_id = m.id::varchar)
WHERE a.country_code = 'TWN'
QUALIFY ROW_NUMBER() OVER (PARTITION BY a.user_id ORDER BY a._creation_timestamp DESC) = 1;
