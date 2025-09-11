-- Test real fraud detection patterns using the business logic I learned

-- 1. Test transaction classification patterns (from the DDL views)
SELECT 
    transaction_cd,
    CASE 
        WHEN transaction_cd IN ('ISA', 'VSA', 'SDA', 'ISC', 'VSC', 'SDC') THEN 'Debit_Purchase'
        WHEN transaction_cd IN ('VSW', 'MPW', 'SDW', 'MPM', 'MPR') THEN 'ATM_Withdrawal' 
        WHEN transaction_cd = 'ADPF' THEN 'Pay_Anyone'
        WHEN transaction_cd = 'ADS' THEN 'ACH_Transfer'
        ELSE 'Other'
    END as transaction_type,
    COUNT(*) as txn_count,
    SUM(ABS(settled_amt)) as total_amount
FROM edw_db.core.fct_settled_transaction 
WHERE transaction_timestamp >= CURRENT_DATE - 7
GROUP BY 1, 2
ORDER BY txn_count DESC
LIMIT 10;
