-- Title: Fraud Rate Analysis and DWN Signal Deep Dive
-- Intent: Analyze fraud rates by week, transfer amounts, and identify DWN JSON variables that separate fraud vs non-fraud
-- Inputs: RISK.TEST.hding_dwn_p2p_session_replay_driver
-- Output: Weekly fraud rates, transfer amount analysis, and DWN signal comparison between fraud/non-fraud cases
-- Assumptions: fraud_dispute_ind=1 indicates confirmed fraud, JSON body contains additional DWN signals
-- Validation: Check fraud rate trends, compare signal distributions, identify discriminative features

-- 1. Weekly fraud rate analysis (count and amount based)
SELECT 
    TRUNC(original_timestamp::DATE, 'week') AS week_,
    COUNT(DISTINCT decision_id) AS cnt_p2p_dwn_session_replay,
    COUNT(DISTINCT CASE WHEN fraud_dispute_ind = 1 THEN decision_id END) AS cnt_fraud_p2p_dwn_session_replay,
    cnt_fraud_p2p_dwn_session_replay / cnt_p2p_dwn_session_replay AS rate_fraud_cnt,
    SUM(transfer_amount) AS sum_p2p_dwn_session_replay,
    SUM(CASE WHEN fraud_dispute_ind = 1 THEN transfer_amount ELSE 0 END) AS sum_fraud_p2p_dwn_session_replay,
    sum_fraud_p2p_dwn_session_replay / sum_p2p_dwn_session_replay AS rate_fraud_sum
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE 1=1
GROUP BY ALL
ORDER BY week_;

-- 2. Transfer amount distribution analysis
SELECT 
    'Transfer Amount Analysis' AS analysis_type,
    fraud_dispute_ind,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(MEDIAN(transfer_amount), 2) AS median_transfer_amount,
    ROUND(MIN(transfer_amount), 2) AS min_transfer_amount,
    ROUND(MAX(transfer_amount), 2) AS max_transfer_amount,
    ROUND(STDDEV(transfer_amount), 2) AS stddev_transfer_amount
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind;

-- 3. Transfer amount quartile analysis by fraud indicator
SELECT 
    'Transfer Amount Quartiles' AS analysis_type,
    fraud_dispute_ind,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY transfer_amount), 2) AS q1_transfer_amount,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY transfer_amount), 2) AS q2_median_transfer_amount,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY transfer_amount), 2) AS q3_transfer_amount,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY transfer_amount), 2) AS p90_transfer_amount,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY transfer_amount), 2) AS p95_transfer_amount
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind;

-- 4. DWN JSON body signal analysis - Extract key fields for comparison
WITH dwn_signals AS (
    SELECT 
        fraud_dispute_ind,
        decision_id,
        transfer_amount,
        replay_count,
        secure_id_signals,
        -- Extract additional signals from JSON body
        body_json:profiling:replay_count::INTEGER AS json_replay_count,
        body_json:profiling:secure_id:signals::VARCHAR AS json_secure_id_signals,
        body_json:profiling:device_id::VARCHAR AS json_device_id,
        body_json:profiling:user_agent::VARCHAR AS json_user_agent,
        body_json:profiling:screen_resolution::VARCHAR AS json_screen_resolution,
        body_json:profiling:timezone::VARCHAR AS json_timezone,
        body_json:profiling:language::VARCHAR AS json_language,
        body_json:profiling:platform::VARCHAR AS json_platform,
        body_json:profiling:webgl_vendor::VARCHAR AS json_webgl_vendor,
        body_json:profiling:webgl_renderer::VARCHAR AS json_webgl_renderer,
        body_json:profiling:canvas_fingerprint::VARCHAR AS json_canvas_fingerprint,
        body_json:profiling:audio_fingerprint::VARCHAR AS json_audio_fingerprint,
        body_json:profiling:fonts::VARCHAR AS json_fonts,
        body_json:profiling:plugins::VARCHAR AS json_plugins,
        body_json:profiling:device_memory::INTEGER AS json_device_memory,
        body_json:profiling:hardware_concurrency::INTEGER AS json_hardware_concurrency,
        body_json:profiling:connection_type::VARCHAR AS json_connection_type,
        body_json:profiling:battery_level::FLOAT AS json_battery_level,
        body_json:profiling:charging::BOOLEAN AS json_charging,
        -- Risk scores or additional metrics
        body_json:risk_score::FLOAT AS json_risk_score,
        body_json:confidence_score::FLOAT AS json_confidence_score,
        body_json:profiling:inconsistency_count::INTEGER AS json_inconsistency_count,
        body_json:profiling:anomaly_flags::VARCHAR AS json_anomaly_flags
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
)
SELECT 
    'Basic Signal Comparison' AS analysis_category,
    fraud_dispute_ind,
    COUNT(*) AS total_cases,
    ROUND(AVG(replay_count), 2) AS avg_replay_count,
    ROUND(AVG(json_replay_count), 2) AS avg_json_replay_count,
    COUNT(DISTINCT json_device_id) AS unique_device_ids,
    COUNT(DISTINCT json_platform) AS unique_platforms,
    COUNT(DISTINCT json_timezone) AS unique_timezones,
    ROUND(AVG(json_device_memory), 2) AS avg_device_memory,
    ROUND(AVG(json_hardware_concurrency), 2) AS avg_hardware_concurrency,
    ROUND(AVG(json_risk_score), 2) AS avg_risk_score,
    ROUND(AVG(json_confidence_score), 2) AS avg_confidence_score,
    ROUND(AVG(json_inconsistency_count), 2) AS avg_inconsistency_count
FROM dwn_signals
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind;

-- 5. Secure ID signals analysis
WITH signal_analysis AS (
    SELECT 
        fraud_dispute_ind,
        secure_id_signals,
        CASE 
            WHEN secure_id_signals LIKE '%INVALID_NONCE%' THEN 1 ELSE 0 
        END AS has_invalid_nonce,
        CASE 
            WHEN secure_id_signals LIKE '%SUSPICIOUS_BEHAVIOR%' THEN 1 ELSE 0 
        END AS has_suspicious_behavior,
        CASE 
            WHEN secure_id_signals LIKE '%DEVICE_MISMATCH%' THEN 1 ELSE 0 
        END AS has_device_mismatch,
        CASE 
            WHEN secure_id_signals LIKE '%UNUSUAL_ACTIVITY%' THEN 1 ELSE 0 
        END AS has_unusual_activity,
        CASE 
            WHEN secure_id_signals LIKE '%HIGH_RISK%' THEN 1 ELSE 0 
        END AS has_high_risk,
        LENGTH(secure_id_signals) AS signal_length,
        (LENGTH(secure_id_signals) - LENGTH(REPLACE(secure_id_signals, ',', ''))) + 1 AS signal_count
    FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
    WHERE secure_id_signals IS NOT NULL
)
SELECT 
    'Secure ID Signal Analysis' AS analysis_category,
    fraud_dispute_ind,
    COUNT(*) AS total_cases,
    ROUND(AVG(has_invalid_nonce), 3) AS pct_invalid_nonce,
    ROUND(AVG(has_suspicious_behavior), 3) AS pct_suspicious_behavior,
    ROUND(AVG(has_device_mismatch), 3) AS pct_device_mismatch,
    ROUND(AVG(has_unusual_activity), 3) AS pct_unusual_activity,
    ROUND(AVG(has_high_risk), 3) AS pct_high_risk,
    ROUND(AVG(signal_length), 2) AS avg_signal_length,
    ROUND(AVG(signal_count), 2) AS avg_signal_count
FROM signal_analysis
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind;

-- 6. Platform and device characteristics
SELECT 
    'Platform Analysis' AS analysis_category,
    fraud_dispute_ind,
    body_json:profiling:platform::VARCHAR AS platform,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_fraud_group
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
WHERE body_json:profiling:platform::VARCHAR IS NOT NULL
GROUP BY fraud_dispute_ind, platform
HAVING case_count >= 10  -- Filter for meaningful sample sizes
ORDER BY fraud_dispute_ind, case_count DESC;

-- 7. Replay count distribution analysis
SELECT 
    'Replay Count Distribution' AS analysis_category,
    fraud_dispute_ind,
    replay_count,
    COUNT(*) AS case_count,
    ROUND(AVG(transfer_amount), 2) AS avg_transfer_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY fraud_dispute_ind), 2) AS pct_within_fraud_group
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY fraud_dispute_ind, replay_count
ORDER BY fraud_dispute_ind, replay_count;
