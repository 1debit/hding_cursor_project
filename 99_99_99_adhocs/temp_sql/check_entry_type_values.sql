-- Check unique values in entry_type column from ftr_transaction
SELECT
    entry_type,
    COUNT(*) as count
FROM edw_db.core.ftr_transaction
WHERE transaction_timestamp >= CURRENT_DATE() - 1  -- Last 1 day
GROUP BY entry_type
ORDER BY count DESC;
