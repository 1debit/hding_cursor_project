-- Title: DWN Profiling Deep Dive and Fraud Detection Recommendations
-- Intent: Extract profiling characteristics and create actionable recommendations for improving precision
-- Inputs: RISK.TEST.hding_dwn_p2p_session_replay_driver
-- Output: Profiling comparison, replay patterns, and recommended rule improvements
-- Assumptions: Profiling data contains device and behavioral characteristics
-- Validation: Compare discriminative features between fraud and non-fraud cases

-- 1. Replay count patterns specifically for fraud cases (missed in previous analysis)
SELECT 
    'Fraud Replay Count Patterns' AS analysis_type,
    fraud_dispute_ind,
    replay_count,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_group
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE fraud_dispute_ind = 1 OR (fraud_dispute_ind = 0 AND replay_count >= 8)  -- All fraud + high replay non-fraud
GROUP BY fraud_dispute_ind, replay_count
ORDER BY fraud_dispute_ind, replay_count;

-- 2. Device signature and profiling characteristics
SELECT 
    'Device Signature Analysis' AS analysis_type,
    fraud_dispute_ind,
    COUNT(*) AS total_cases,
    COUNT(DISTINCT body_json:device_signature::VARCHAR) AS unique_device_signatures,
    ROUND(COUNT(DISTINCT body_json:device_signature::VARCHAR) * 1.0 / COUNT(*), 3) AS device_signature_uniqueness_ratio,
    ROUND(AVG(body_json:duration::FLOAT), 2) AS avg_duration_ms,
    ROUND(AVG(body_json:time_since_last_step::FLOAT), 2) AS avg_time_since_last_step_ms,
    COUNT(CASE WHEN body_json:profiling:replay_count::INTEGER > 10 THEN 1 END) AS very_high_replay_count,
    COUNT(CASE WHEN body_json:profiling:replay_count::INTEGER BETWEEN 5 AND 10 THEN 1 END) AS high_replay_count,
    COUNT(CASE WHEN body_json:profiling:replay_count::INTEGER BETWEEN 2 AND 4 THEN 1 END) AS medium_replay_count
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind;

-- 3. Profiling error signals and patterns
SELECT 
    'Profiling Error Patterns' AS analysis_type,
    fraud_dispute_ind,
    body_json:profiling:errors::VARCHAR AS profiling_errors,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(AVG(replay_count), 2) AS avg_replay_count
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE body_json:profiling:errors IS NOT NULL
GROUP BY fraud_dispute_ind, profiling_errors
HAVING case_count >= 3
ORDER BY fraud_dispute_ind, case_count DESC;

-- 4. Request characteristics comparison
WITH request_analysis AS (
    SELECT 
        fraud_dispute_ind,
        body_json:request:request_type::VARCHAR AS request_type,
        body_json:request:identifier::VARCHAR AS request_identifier,
        body_json:step_number::INTEGER AS step_number,
        body_json:primary_session_tie::VARCHAR AS primary_session_tie,
        replay_count,
        transfer_amount
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
)
SELECT 
    'Request Characteristics' AS analysis_type,
    fraud_dispute_ind,
    request_type,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(AVG(replay_count), 2) AS avg_replay_count,
    ROUND(AVG(step_number), 2) AS avg_step_number,
    COUNT(DISTINCT primary_session_tie) AS unique_session_ties
FROM request_analysis
WHERE request_type IS NOT NULL
GROUP BY fraud_dispute_ind, request_type
HAVING case_count >= 10
ORDER BY fraud_dispute_ind, case_count DESC;

-- 5. Combined risk scoring patterns
WITH risk_patterns AS (
    SELECT 
        fraud_dispute_ind,
        CASE 
            WHEN replay_count >= 15 THEN 'Very High Replay (15+)'
            WHEN replay_count >= 10 THEN 'High Replay (10-14)'
            WHEN replay_count >= 5 THEN 'Medium Replay (5-9)'
            ELSE 'Low Replay (2-4)'
        END AS replay_category,
        CASE 
            WHEN transfer_amount >= 500 THEN 'High Amount ($500+)'
            WHEN transfer_amount >= 100 THEN 'Medium Amount ($100-499)'
            WHEN transfer_amount >= 50 THEN 'Low-Medium Amount ($50-99)'
            ELSE 'Low Amount (<$50)'
        END AS amount_category,
        CASE 
            WHEN secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' THEN 'Missing Key Signals'
            WHEN secure_id_signals LIKE '%EXISTING_KEY%' THEN 'Existing Key Signals'
            ELSE 'Other Signals'
        END AS signal_category,
        COUNT(*) AS case_count
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    GROUP BY fraud_dispute_ind, replay_category, amount_category, signal_category
)
SELECT 
    'Combined Risk Pattern Analysis' AS analysis_type,
    fraud_dispute_ind,
    replay_category,
    amount_category,
    signal_category,
    case_count,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_fraud_group
FROM risk_patterns
WHERE case_count >= 2
ORDER BY fraud_dispute_ind, case_count DESC;

-- 6. High-precision rule recommendations
WITH high_precision_candidates AS (
    SELECT 
        'Potential High-Precision Rules' AS rule_type,
        CASE 
            WHEN replay_count >= 15 AND transfer_amount >= 200 THEN 'Very High Replay + High Amount'
            WHEN replay_count >= 10 AND secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' THEN 'High Replay + Missing Key'
            WHEN replay_count >= 8 AND transfer_amount >= 500 THEN 'High Replay + Very High Amount'
            WHEN secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' AND transfer_amount >= 300 THEN 'Missing Key + High Amount'
            ELSE 'Current Rule (Replay>1 + Invalid Nonce)'
        END AS proposed_rule,
        COUNT(*) AS total_flagged,
        COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS fraud_cases,
        ROUND(COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS precision_rate,
        SUM(transfer_amount) AS total_amount_flagged,
        SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    GROUP BY proposed_rule
)
SELECT *
FROM high_precision_candidates
WHERE total_flagged > 0
ORDER BY precision_rate DESC, fraud_cases DESC;
