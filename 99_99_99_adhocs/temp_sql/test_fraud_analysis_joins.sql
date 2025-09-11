-- Test real fraud analysis join pattern: User -> Account -> Transaction -> ATOM Score

WITH user_transactions AS (
    SELECT 
        a.user_id,
        a.account_id,
        t.transaction_id,
        t.transaction_ts,
        t.processor
    FROM edw_db.core.dim_account a
    INNER JOIN edw_db.core.fct_settled_transaction t 
        ON a.account_id = t.account_id
    WHERE a.user_id = '31584310'  -- Using a user_id I saw in ATOM data
      AND t.transaction_ts >= '2021-12-09'::date
    LIMIT 5
),

user_atom_scores AS (
    SELECT 
        user_id,
        session_timestamp,
        device_id,
        ip,
        -- The risk score is typically the last column
        ROUND(CAST(SPLIT_PART(OBJECT_CONSTRUCT(*), ',', -2) AS FLOAT), 6) as atom_score_approx
    FROM ml.model_inference.atom_v2_batch_predictions 
    WHERE user_id = '31584310'
      AND session_timestamp >= '2021-12-09'::date
    LIMIT 3
)

-- Join transactions with ATOM scores to see fraud detection pattern
SELECT 
    ut.user_id,
    ut.account_id,
    ut.transaction_id,
    ut.transaction_ts,
    uas.session_timestamp,
    uas.device_id,
    uas.ip,
    uas.atom_score_approx
FROM user_transactions ut
LEFT JOIN user_atom_scores uas 
    ON ut.user_id = uas.user_id
    AND DATE(ut.transaction_ts) = DATE(uas.session_timestamp);
