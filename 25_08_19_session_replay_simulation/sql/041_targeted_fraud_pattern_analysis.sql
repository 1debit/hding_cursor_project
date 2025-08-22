-- Title: Targeted Fraud Pattern Analysis and JSON Structure Exploration
-- Intent: Deep dive into fraud vs non-fraud patterns and explore actual JSON structure
-- Inputs: RISK.TEST.hding_dwn_p2p_session_replay_driver
-- Output: Fraud case characteristics, JSON structure exploration, discriminative patterns
-- Assumptions: Need to understand actual JSON structure and find distinguishing features
-- Validation: Compare patterns between fraud and non-fraud cases

-- 1. Sample fraud cases for detailed inspection
SELECT 'Fraud Cases Sample' AS analysis_type,
       decision_id,
       sender_user_id,
       transfer_amount,
       replay_count,
       dec_plat_decision,
       original_timestamp,
       secure_id_signals,
       LEFT(raw_body, 500) AS raw_body_preview
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE fraud_dispute_ind = 1
ORDER BY transfer_amount DESC
LIMIT 10;

-- 2. Explore actual JSON structure by examining non-null fields
SELECT 'JSON Structure Exploration' AS analysis_type,
       COUNT(*) AS total_cases,
       COUNT(CASE WHEN body_json IS NOT NULL THEN 1 END) AS non_null_body_json,
       COUNT(CASE WHEN body_json:profiling IS NOT NULL THEN 1 END) AS has_profiling,
       COUNT(CASE WHEN body_json:step_name IS NOT NULL THEN 1 END) AS has_step_name,
       COUNT(CASE WHEN body_json:identifier IS NOT NULL THEN 1 END) AS has_identifier,
       COUNT(CASE WHEN body_json:timestamp IS NOT NULL THEN 1 END) AS has_timestamp,
       COUNT(CASE WHEN body_json:device_id IS NOT NULL THEN 1 END) AS has_device_id,
       COUNT(CASE WHEN body_json:user_id IS NOT NULL THEN 1 END) AS has_user_id
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver;

-- 3. Top-level JSON keys exploration
SELECT 'Top Level JSON Keys' AS analysis_type,
       fraud_dispute_ind,
       OBJECT_KEYS(body_json) AS json_keys,
       COUNT(*) AS case_count
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE body_json IS NOT NULL
GROUP BY fraud_dispute_ind, json_keys
HAVING case_count >= 5
ORDER BY fraud_dispute_ind, case_count DESC;

-- 4. Replay count detailed analysis for fraud vs non-fraud
WITH replay_analysis AS (
    SELECT 
        fraud_dispute_ind,
        replay_count,
        COUNT(*) AS case_count,
        ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transfer_amount), 2) AS median_transfer_amount
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    GROUP BY fraud_dispute_ind, replay_count
)
SELECT 
    'Replay Count by Fraud Status' AS analysis_type,
    fraud_dispute_ind,
    replay_count,
    case_count,
    avg_transfer_amount,
    median_transfer_amount,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_fraud_group
FROM replay_analysis
WHERE fraud_dispute_ind = 1 OR case_count >= 100  -- Show all fraud cases or significant non-fraud patterns
ORDER BY fraud_dispute_ind, replay_count;

-- 5. Transfer amount range analysis
WITH amount_ranges AS (
    SELECT 
        fraud_dispute_ind,
        CASE 
            WHEN transfer_amount <= 10 THEN '$1-10'
            WHEN transfer_amount <= 25 THEN '$11-25'
            WHEN transfer_amount <= 50 THEN '$26-50'
            WHEN transfer_amount <= 100 THEN '$51-100'
            WHEN transfer_amount <= 250 THEN '$101-250'
            WHEN transfer_amount <= 500 THEN '$251-500'
            WHEN transfer_amount <= 1000 THEN '$501-1000'
            ELSE '$1000+'
        END AS amount_range,
        COUNT(*) AS case_count,
        SUM(transfer_amount) AS total_amount
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    GROUP BY fraud_dispute_ind, amount_range
)
SELECT 
    'Transfer Amount Range Analysis' AS analysis_type,
    fraud_dispute_ind,
    amount_range,
    case_count,
    total_amount,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_fraud_group,
    ROUND(total_amount * 100.0 / SUM(total_amount) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_amount_within_fraud_group
FROM amount_ranges
ORDER BY fraud_dispute_ind, 
         CASE amount_range 
             WHEN '$1-10' THEN 1 
             WHEN '$11-25' THEN 2 
             WHEN '$26-50' THEN 3 
             WHEN '$51-100' THEN 4 
             WHEN '$101-250' THEN 5 
             WHEN '$251-500' THEN 6 
             WHEN '$501-1000' THEN 7 
             ELSE 8 
         END;

-- 6. Decision platform decision analysis for fraud cases
SELECT 
    'Decision Platform Analysis for Fraud' AS analysis_type,
    dec_plat_decision,
    COUNT(*) AS fraud_case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_fraud_amount,
    ROUND(AVG(replay_count), 2) AS avg_replay_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct_of_fraud_cases
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE fraud_dispute_ind = 1
GROUP BY dec_plat_decision
ORDER BY fraud_case_count DESC;

-- 7. Time-based analysis for fraud cases
SELECT 
    'Time Pattern Analysis for Fraud' AS analysis_type,
    DATE_TRUNC('hour', original_timestamp) AS hour_of_day,
    COUNT(*) AS fraud_case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_fraud_amount
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE fraud_dispute_ind = 1
GROUP BY hour_of_day
ORDER BY fraud_case_count DESC
LIMIT 10;

-- 8. Look for patterns in secure_id_signals for fraud cases
SELECT 
    'Secure ID Signals for Fraud Cases' AS analysis_type,
    secure_id_signals,
    COUNT(*) AS fraud_case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_fraud_amount,
    ROUND(AVG(replay_count), 2) AS avg_replay_count
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE fraud_dispute_ind = 1
GROUP BY secure_id_signals
ORDER BY fraud_case_count DESC;
