-- Get all fields in the transaction table to understand complete structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'CORE' 
  AND table_catalog = 'EDW_DB'
  AND table_name = 'FCT_SETTLED_TRANSACTION'
ORDER BY ordinal_position;
