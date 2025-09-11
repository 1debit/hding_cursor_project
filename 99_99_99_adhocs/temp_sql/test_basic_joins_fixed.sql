-- Test basic join patterns with correct field names

-- First check the exact field names in dim_account
DESCRIBE TABLE edw_db.core.dim_account;

-- Then do a simple join test
SELECT
    a.account_id,
    a.user_id,
    a.account_type,
    t.transaction_id,
    t.amount
FROM edw_db.core.dim_account a
LEFT JOIN edw_db.core.fct_settled_transaction t
    ON a.account_id = t.account_id
WHERE a.account_id = '7936445'
LIMIT 3;
