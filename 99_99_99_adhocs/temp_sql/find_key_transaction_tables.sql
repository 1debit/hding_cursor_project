-- Find key transaction and user tables systematically

-- Look for all transaction-related tables
SELECT table_name, row_count, bytes
FROM information_schema.tables
WHERE table_schema = 'CORE'
  AND table_catalog = 'EDW_DB'
  AND (table_name ILIKE '%TRANSACTION%' OR table_name ILIKE '%TXN%')
ORDER BY row_count DESC;

-- Look for user/member tables
SELECT table_name, row_count, bytes
FROM information_schema.tables
WHERE table_schema = 'CORE'
  AND table_catalog = 'EDW_DB'
  AND (table_name ILIKE '%USER%' OR table_name ILIKE '%MEMBER%')
ORDER BY row_count DESC;
