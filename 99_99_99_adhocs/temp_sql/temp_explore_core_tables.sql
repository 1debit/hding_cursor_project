ui-- Explore core user/member dimension tables
SHOW TABLES IN edw_db.core;

-- Let's also explore the structure of key tables
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'CORE'
  AND database_name = 'EDW_DB'
  AND (table_name LIKE '%DIM_USER%'
       OR table_name LIKE '%DIM_MEMBER%'
       OR table_name LIKE '%FCT_SETTLED%'
       OR table_name LIKE '%FCT_TRANSACTION%')
ORDER BY table_name;
