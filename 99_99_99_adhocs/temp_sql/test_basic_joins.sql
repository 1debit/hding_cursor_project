-- Test basic join patterns between core tables

-- Join accounts to transactions to understand the relationship
SELECT
    a.account_id,
    a.user_id,
    a.account_type,
    a.status as account_status,
    t.transaction_id,
    t.amount,
    t.transaction_ts
FROM edw_db.core.dim_account a
LEFT JOIN edw_db.core.fct_settled_transaction t
    ON a.account_id = t.account_id
WHERE a.account_id = '7936445'  -- Using an account_id I saw in the transaction sample
LIMIT 5;
