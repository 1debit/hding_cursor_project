-- Systematic exploration of transaction tables
-- Created in organized temp_sql directory

-- First, let's see all tables in edw_db.core to understand what's available
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'CORE'
  AND table_catalog = 'EDW_DB'
  AND table_name ILIKE '%TRANSACTION%'
ORDER BY table_name;

-- Look for settled transaction table specifically
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'CORE'
  AND table_catalog = 'EDW_DB'
  AND table_name ILIKE '%SETTLED%'
ORDER BY table_name;
