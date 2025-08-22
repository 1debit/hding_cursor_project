-- Title: Step Number Deep Dive and Precise Rule Performance Metrics
-- Intent: Understand what step_number represents and calculate exact precision/recall for allowed cases only
-- Inputs: RISK.TEST.hding_dwn_p2p_session_replay_driver (allowed cases only)
-- Output: Step number explanation and detailed rule performance metrics for allowed population
-- Assumptions: Focus only on allowed cases for precision/recall calculations
-- Validation: Verify step number patterns and rule performance metrics

-- 1. Step number field exploration - what does it represent?
WITH allowed_cases AS (
    SELECT 
        fraud_dispute_ind,
        replay_count,
        transfer_amount,
        body_json:step_number::INTEGER AS step_number,
        body_json:step_name::VARCHAR AS step_name
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Step Number Field Analysis' AS analysis_type,
    step_number,
    step_name,
    COUNT(*) AS case_count,
    COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS fraud_cases,
    ROUND(AVG(replay_count), 2) AS avg_replay_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount
FROM allowed_cases
WHERE step_number IS NOT NULL
GROUP BY step_number, step_name
ORDER BY step_number, case_count DESC;

-- 2. Sample raw JSON to understand step_number context
WITH sample_data AS (
    SELECT 
        fraud_dispute_ind,
        body_json:step_number::INTEGER AS step_number,
        body_json:step_name::VARCHAR AS step_name,
        body_json:identifier::VARCHAR AS identifier,
        LEFT(raw_body, 200) AS json_sample
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow' 
        AND body_json:step_number IS NOT NULL
)
SELECT 
    'Step Number JSON Context' AS analysis_type,
    fraud_dispute_ind,
    step_number,
    step_name,
    identifier,
    json_sample
FROM sample_data
ORDER BY step_number DESC, fraud_dispute_ind DESC
LIMIT 20;

-- 3. Allowed population baseline for precision/recall calculations
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Allowed Population Baseline' AS metric_type,
    COUNT(*) AS total_allowed_cases,
    COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS total_allowed_fraud_cases,
    ROUND(COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS baseline_fraud_rate_pct
FROM allowed_cases;

-- 4. Rule 1: High Replay + Missing Key - Detailed metrics
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
rule1_results AS (
    SELECT 
        CASE WHEN replay_count >= 10 AND secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' THEN 1 ELSE 0 END AS flagged_by_rule1,
        fraud_dispute_ind,
        transfer_amount
    FROM allowed_cases
)
SELECT 
    'Rule 1: High Replay + Missing Key' AS rule_name,
    SUM(flagged_by_rule1) AS total_flagged,
    SUM(CASE WHEN flagged_by_rule1 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) AS fraud_caught,
    SUM(CASE WHEN flagged_by_rule1 = 1 AND fraud_dispute_ind = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(SUM(CASE WHEN flagged_by_rule1 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(flagged_by_rule1), 2) AS precision_pct,
    ROUND(SUM(CASE WHEN flagged_by_rule1 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fraud_dispute_ind), 2) AS recall_pct,
    SUM(CASE WHEN flagged_by_rule1 = 1 THEN transfer_amount ELSE 0 END) AS total_amount_flagged,
    SUM(CASE WHEN flagged_by_rule1 = 1 AND fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
FROM rule1_results;

-- 5. Rule 2: Step Number + Replay Count - Detailed metrics
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
rule2_results AS (
    SELECT 
        CASE WHEN body_json:step_number::INTEGER >= 8 AND replay_count >= 8 THEN 1 ELSE 0 END AS flagged_by_rule2,
        fraud_dispute_ind,
        transfer_amount
    FROM allowed_cases
)
SELECT 
    'Rule 2: Step Number >= 8 + Replay >= 8' AS rule_name,
    SUM(flagged_by_rule2) AS total_flagged,
    SUM(CASE WHEN flagged_by_rule2 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) AS fraud_caught,
    SUM(CASE WHEN flagged_by_rule2 = 1 AND fraud_dispute_ind = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(SUM(CASE WHEN flagged_by_rule2 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(flagged_by_rule2), 2) AS precision_pct,
    ROUND(SUM(CASE WHEN flagged_by_rule2 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fraud_dispute_ind), 2) AS recall_pct,
    SUM(CASE WHEN flagged_by_rule2 = 1 THEN transfer_amount ELSE 0 END) AS total_amount_flagged,
    SUM(CASE WHEN flagged_by_rule2 = 1 AND fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
FROM rule2_results;

-- 6. Rule 3: Missing Key + Amount - Detailed metrics
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
rule3_results AS (
    SELECT 
        CASE WHEN secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' AND transfer_amount >= 100 THEN 1 ELSE 0 END AS flagged_by_rule3,
        fraud_dispute_ind,
        transfer_amount
    FROM allowed_cases
)
SELECT 
    'Rule 3: Missing Key + Amount >= $100' AS rule_name,
    SUM(flagged_by_rule3) AS total_flagged,
    SUM(CASE WHEN flagged_by_rule3 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) AS fraud_caught,
    SUM(CASE WHEN flagged_by_rule3 = 1 AND fraud_dispute_ind = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(SUM(CASE WHEN flagged_by_rule3 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(flagged_by_rule3), 2) AS precision_pct,
    ROUND(SUM(CASE WHEN flagged_by_rule3 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fraud_dispute_ind), 2) AS recall_pct,
    SUM(CASE WHEN flagged_by_rule3 = 1 THEN transfer_amount ELSE 0 END) AS total_amount_flagged,
    SUM(CASE WHEN flagged_by_rule3 = 1 AND fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
FROM rule3_results;

-- 7. Rule 4: Conservative High-Precision - Detailed metrics
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
rule4_results AS (
    SELECT 
        CASE WHEN body_json:step_number::INTEGER >= 12 AND replay_count >= 8 AND transfer_amount >= 100 THEN 1 ELSE 0 END AS flagged_by_rule4,
        fraud_dispute_ind,
        transfer_amount
    FROM allowed_cases
)
SELECT 
    'Rule 4: Conservative (Step>=12 + Replay>=8 + Amount>=100)' AS rule_name,
    SUM(flagged_by_rule4) AS total_flagged,
    SUM(CASE WHEN flagged_by_rule4 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) AS fraud_caught,
    SUM(CASE WHEN flagged_by_rule4 = 1 AND fraud_dispute_ind = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(SUM(CASE WHEN flagged_by_rule4 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(flagged_by_rule4), 2) AS precision_pct,
    ROUND(SUM(CASE WHEN flagged_by_rule4 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fraud_dispute_ind), 2) AS recall_pct,
    SUM(CASE WHEN flagged_by_rule4 = 1 THEN transfer_amount ELSE 0 END) AS total_amount_flagged,
    SUM(CASE WHEN flagged_by_rule4 = 1 AND fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
FROM rule4_results;

-- 8. Rule 5: Balanced Multi-Signal - Detailed metrics
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
rule5_results AS (
    SELECT 
        CASE WHEN (replay_count >= 8 AND body_json:step_number::INTEGER >= 8) 
                  OR (secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' AND transfer_amount >= 100) THEN 1 ELSE 0 END AS flagged_by_rule5,
        fraud_dispute_ind,
        transfer_amount
    FROM allowed_cases
)
SELECT 
    'Rule 5: Balanced Multi-Signal' AS rule_name,
    SUM(flagged_by_rule5) AS total_flagged,
    SUM(CASE WHEN flagged_by_rule5 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) AS fraud_caught,
    SUM(CASE WHEN flagged_by_rule5 = 1 AND fraud_dispute_ind = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(SUM(CASE WHEN flagged_by_rule5 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(flagged_by_rule5), 2) AS precision_pct,
    ROUND(SUM(CASE WHEN flagged_by_rule5 = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fraud_dispute_ind), 2) AS recall_pct,
    SUM(CASE WHEN flagged_by_rule5 = 1 THEN transfer_amount ELSE 0 END) AS total_amount_flagged,
    SUM(CASE WHEN flagged_by_rule5 = 1 AND fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
FROM rule5_results;

-- 9. Current rule performance for comparison (allowed cases only)
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
current_rule_results AS (
    SELECT 
        CASE WHEN replay_count > 1 AND secure_id_signals LIKE '%INVALID_NONCE%' THEN 1 ELSE 0 END AS flagged_by_current,
        fraud_dispute_ind,
        transfer_amount
    FROM allowed_cases
)
SELECT 
    'Current Rule: Replay > 1 + Invalid Nonce (Allowed Only)' AS rule_name,
    SUM(flagged_by_current) AS total_flagged,
    SUM(CASE WHEN flagged_by_current = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) AS fraud_caught,
    SUM(CASE WHEN flagged_by_current = 1 AND fraud_dispute_ind = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(SUM(CASE WHEN flagged_by_current = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(flagged_by_current), 2) AS precision_pct,
    ROUND(SUM(CASE WHEN flagged_by_current = 1 AND fraud_dispute_ind = 1 THEN 1 ELSE 0 END) * 100.0 / SUM(fraud_dispute_ind), 2) AS recall_pct,
    SUM(CASE WHEN flagged_by_current = 1 THEN transfer_amount ELSE 0 END) AS total_amount_flagged,
    SUM(CASE WHEN flagged_by_current = 1 AND fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught
FROM current_rule_results;
