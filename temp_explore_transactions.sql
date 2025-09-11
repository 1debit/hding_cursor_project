-- Explore transaction tables that I saw in the production patterns

-- Look for settled transaction table (this is key for fraud analysis)
SHOW TABLES IN edw_db.core;

-- Let's specifically look for transaction-related tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'CORE' 
  AND table_catalog = 'EDW_DB'
  AND table_name ILIKE '%TRANSACTION%'
ORDER BY table_name;
