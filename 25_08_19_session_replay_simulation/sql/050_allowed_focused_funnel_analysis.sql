-- Title: Session Replay Analysis - Allowed Cases Funnel with Fraud Focus
-- Intent: Analyze only allowed P2P cases to understand fraud patterns within approved transactions
-- Inputs: RISK.TEST.hding_dwn_p2p_session_replay_driver
-- Output: Funnel analysis from allowed cases to disputed cases with precision/recall optimization
-- Assumptions: Focus only on dec_plat_decision = 'allow' since other decisions are already handled
-- Validation: Compare allowed+fraud vs allowed+non-fraud patterns for rule optimization

-- 1. Overall funnel overview - allowed vs not allowed
SELECT 
    'Decision Platform Funnel Overview' AS analysis_type,
    dec_plat_decision,
    COUNT(*) AS total_cases,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total_cases,
    SUM(transfer_amount) AS total_amount,
    ROUND(SUM(transfer_amount) * 100.0 / SUM(SUM(transfer_amount)) OVER (), 2) AS pct_of_total_amount,
    COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS fraud_cases,
    SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY dec_plat_decision
ORDER BY total_cases DESC;

-- 2. Allowed cases funnel - focus on the main population
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Allowed Cases Funnel Analysis' AS analysis_type,
    'All Allowed Cases' AS category,
    COUNT(*) AS total_allowed_cases,
    SUM(transfer_amount) AS total_allowed_amount,
    COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS disputed_cases,
    SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS disputed_amount,
    ROUND(COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS dispute_rate_pct,
    ROUND(SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) * 100.0 / SUM(transfer_amount), 4) AS disputed_amount_rate_pct
FROM allowed_cases;

-- 3. Weekly allowed funnel trends
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Weekly Allowed Funnel Trends' AS analysis_type,
    TRUNC(original_timestamp::DATE, 'week') AS week_,
    COUNT(*) AS allowed_cases,
    SUM(transfer_amount) AS allowed_amount,
    COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS disputed_cases,
    SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS disputed_amount,
    ROUND(COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) * 100.0 / COUNT(*), 4) AS dispute_rate_pct,
    ROUND(SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) * 100.0 / SUM(transfer_amount), 4) AS disputed_amount_rate_pct
FROM allowed_cases
GROUP BY week_
ORDER BY week_;

-- 4. Allowed fraud vs non-fraud characteristics comparison
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Allowed Cases Characteristics' AS analysis_type,
    CASE WHEN fraud_dispute_ind = 1 THEN 'Allowed + Disputed (Fraud)' ELSE 'Allowed + Not Disputed' END AS case_type,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transfer_amount), 2) AS median_transfer_amount,
    ROUND(AVG(replay_count), 2) AS avg_replay_count,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY replay_count), 2) AS median_replay_count,
    ROUND(AVG(body_json:step_number::INTEGER), 2) AS avg_step_number,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY body_json:step_number::INTEGER), 2) AS median_step_number,
    ROUND(AVG(body_json:duration::FLOAT), 2) AS avg_duration_ms,
    ROUND(AVG(body_json:time_since_last_step::FLOAT), 2) AS avg_time_since_last_step_ms
FROM allowed_cases
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind DESC;

-- 5. Transfer amount distribution for allowed cases only
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
amount_ranges AS (
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
    FROM allowed_cases
    GROUP BY fraud_dispute_ind, amount_range
)
SELECT 
    'Allowed Transfer Amount Analysis' AS analysis_type,
    CASE WHEN fraud_dispute_ind = 1 THEN 'Disputed' ELSE 'Not Disputed' END AS case_type,
    amount_range,
    case_count,
    total_amount,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_dispute_group,
    ROUND(total_amount * 100.0 / SUM(total_amount) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_amount_within_dispute_group
FROM amount_ranges
ORDER BY fraud_dispute_ind DESC, 
         CASE amount_range 
             WHEN '$1-10' THEN 1 WHEN '$11-25' THEN 2 WHEN '$26-50' THEN 3 
             WHEN '$51-100' THEN 4 WHEN '$101-250' THEN 5 WHEN '$251-500' THEN 6 
             WHEN '$501-1000' THEN 7 ELSE 8 END;

-- 6. Replay count patterns for allowed cases
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Allowed Replay Count Patterns' AS analysis_type,
    CASE WHEN fraud_dispute_ind = 1 THEN 'Disputed' ELSE 'Not Disputed' END AS case_type,
    replay_count,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_dispute_group
FROM allowed_cases
GROUP BY fraud_dispute_ind, replay_count
HAVING case_count >= 5 OR fraud_dispute_ind = 1  -- Show all disputed cases or significant patterns
ORDER BY fraud_dispute_ind DESC, replay_count;

-- 7. Step number analysis for allowed cases
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
step_analysis AS (
    SELECT 
        fraud_dispute_ind,
        body_json:step_number::INTEGER AS step_number,
        COUNT(*) AS case_count,
        ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
        ROUND(AVG(replay_count), 2) AS avg_replay_count
    FROM allowed_cases
    WHERE body_json:step_number::INTEGER IS NOT NULL
    GROUP BY fraud_dispute_ind, step_number
)
SELECT 
    'Allowed Step Number Patterns' AS analysis_type,
    CASE WHEN fraud_dispute_ind = 1 THEN 'Disputed' ELSE 'Not Disputed' END AS case_type,
    step_number,
    case_count,
    avg_transfer_amount,
    avg_replay_count,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_dispute_group
FROM step_analysis
WHERE case_count >= 3 OR fraud_dispute_ind = 1
ORDER BY fraud_dispute_ind DESC, step_number;

-- 8. Secure ID signals for allowed cases
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
)
SELECT 
    'Allowed Secure ID Signal Patterns' AS analysis_type,
    CASE WHEN fraud_dispute_ind = 1 THEN 'Disputed' ELSE 'Not Disputed' END AS case_type,
    secure_id_signals,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(AVG(replay_count), 2) AS avg_replay_count,
    ROUND(case_count * 100.0 / SUM(case_count) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_dispute_group
FROM allowed_cases
GROUP BY fraud_dispute_ind, secure_id_signals
HAVING case_count >= 2 OR fraud_dispute_ind = 1
ORDER BY fraud_dispute_ind DESC, case_count DESC;

-- 9. High precision rule candidates for allowed cases only
WITH allowed_cases AS (
    SELECT *
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE dec_plat_decision = 'allow'
),
rule_candidates AS (
    SELECT 
        'Allowed Cases High-Precision Rules' AS rule_category,
        CASE 
            WHEN replay_count >= 15 AND transfer_amount >= 200 THEN 'Very High Replay + Medium Amount'
            WHEN replay_count >= 10 AND secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' THEN 'High Replay + Missing Key'
            WHEN replay_count >= 8 AND transfer_amount >= 500 THEN 'High Replay + High Amount'
            WHEN body_json:step_number::INTEGER >= 10 AND transfer_amount >= 100 THEN 'High Steps + Medium Amount'
            WHEN secure_id_signals LIKE '%MISSING_PUBLIC_KEY%' AND transfer_amount >= 200 THEN 'Missing Key + Medium Amount'
            WHEN replay_count >= 12 THEN 'Very High Replay Only'
            WHEN body_json:step_number::INTEGER >= 15 THEN 'Very High Steps Only'
            ELSE 'Current Rule (Replay>1 + Invalid Nonce)'
        END AS proposed_rule,
        COUNT(*) AS total_flagged,
        COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) AS fraud_cases_caught,
        ROUND(COUNT(CASE WHEN fraud_dispute_ind = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS precision_rate,
        SUM(transfer_amount) AS total_amount_flagged,
        SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS fraud_amount_caught,
        ROUND(SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) * 100.0 / SUM(transfer_amount), 2) AS fraud_amount_rate
    FROM allowed_cases
    GROUP BY proposed_rule
)
SELECT *
FROM rule_candidates
WHERE total_flagged > 0
ORDER BY precision_rate DESC, fraud_cases_caught DESC;
