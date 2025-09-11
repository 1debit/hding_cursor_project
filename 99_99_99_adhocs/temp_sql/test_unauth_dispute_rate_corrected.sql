-- Sample 100 users enrolled on 2025-01-01 and calculate their first 3 months
-- card not present transaction unauthorized dispute rate

WITH enrolled_users AS (
    -- Get 100 users enrolled on 2025-01-01
    SELECT
        user_id,
        enrollment_initiated_ts
    FROM edw_db.core.member_details
    WHERE DATE(enrollment_initiated_ts) = '2025-01-01'
    LIMIT 100
),

card_not_present_txns AS (
    -- Get card not present transactions using ftr_transaction with card_not_present field
    SELECT
        t.user_id,
        t.transaction_id,
        t.transaction_timestamp,
        t.settled_amt,
        t.authorization_code,
        t.merchant_name
    FROM edw_db.core.ftr_transaction t
    JOIN enrolled_users eu ON t.user_id = eu.user_id
    WHERE t.processor = 'galileo'
        AND t.transaction_timestamp >= '2025-01-01'
        AND t.transaction_timestamp < '2025-04-01'
        AND t.entry_type = 'Card Not Present'  -- Card not present
),

dispute_data AS (
    -- Get unauthorized disputes with deduplication
    SELECT
        dt.user_id,
        dt.unique_transaction_id,
        dt.dispute_created_at,
        dt.reason,
        dt.resolution_decision
    FROM risk.prod.disputed_transactions dt
    JOIN enrolled_users eu ON dt.user_id = eu.user_id
    WHERE dt.dispute_created_at >= '2025-01-01'
        AND dt.reason ILIKE 'unauth%'  -- Unauthorized disputes
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY dt.user_id, dt.unique_transaction_id
        ORDER BY dt.dispute_created_at DESC
    ) = 1  -- Deduplication
),

user_metrics AS (
    -- Calculate metrics per user (dollar-wise dispute rate)
    SELECT
        eu.user_id,
        COUNT(DISTINCT cnt.transaction_id) as total_card_not_present_txns,
        COALESCE(SUM(cnt.settled_amt), 0) as total_card_not_present_amt,
        COUNT(DISTINCT dd.unique_transaction_id) as unauth_disputes,
        COALESCE(SUM(CASE WHEN dd.unique_transaction_id IS NOT NULL THEN cnt.settled_amt ELSE 0 END), 0) as disputed_amt,
        CASE
            WHEN COALESCE(SUM(cnt.settled_amt), 0) > 0
            THEN COALESCE(SUM(CASE WHEN dd.unique_transaction_id IS NOT NULL THEN cnt.settled_amt ELSE 0 END), 0) / COALESCE(SUM(cnt.settled_amt), 0)
            ELSE 0
        END as unauth_dispute_rate_dollar
    FROM enrolled_users eu
    LEFT JOIN card_not_present_txns cnt ON eu.user_id = cnt.user_id
    LEFT JOIN dispute_data dd ON eu.user_id = dd.user_id
        AND cnt.transaction_id = dd.unique_transaction_id
    GROUP BY eu.user_id
)

-- Final results - user-level aggregation
SELECT
    COUNT(*) as total_users_sampled,
    SUM(total_card_not_present_txns) as total_card_not_present_transactions,
    SUM(total_card_not_present_amt) as total_card_not_present_dollars,
    SUM(unauth_disputes) as total_unauth_disputes,
    SUM(disputed_amt) as total_disputed_dollars,
    AVG(unauth_dispute_rate_dollar) as avg_unauth_dispute_rate_dollar,
    MIN(unauth_dispute_rate_dollar) as min_unauth_dispute_rate_dollar,
    MAX(unauth_dispute_rate_dollar) as max_unauth_dispute_rate_dollar,
    -- Overall dollar-wise dispute rate
    CASE
        WHEN SUM(total_card_not_present_amt) > 0
        THEN SUM(disputed_amt) / SUM(total_card_not_present_amt)
        ELSE 0
    END as overall_dispute_rate_dollar
FROM user_metrics;
