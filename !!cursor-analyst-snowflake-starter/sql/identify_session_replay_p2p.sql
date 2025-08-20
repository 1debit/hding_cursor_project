/*
    Session Replay Detection Query for P2P Sessions
    
    Purpose: Identify all P2P sessions that meet the DWN session replay identification criteria
    
    DWN Session Replay Detection Criteria:
    - profiling.replay_count > 1 
    - has(profiling.secure_id.signals, "INVALID_NONCE")
    
    This query will help validate that all confirmed session replay bad sessions (p2psession)
    indeed meet these detection conditions.
*/

-- Identify P2P sessions with session replay detection criteria
WITH session_replay_candidates AS (
    SELECT 
        session_id,
        user_id,
        device_id,
        timestamp,
        profiling.replay_count as replay_count,
        profiling.secure_id.signals as secure_id_signals,
        -- Check if INVALID_NONCE signal exists
        CASE 
            WHEN has(profiling.secure_id.signals, 'INVALID_NONCE') THEN 'YES'
            ELSE 'NO'
        END as has_invalid_nonce,
        -- Determine if session meets replay criteria
        CASE 
            WHEN profiling.replay_count > 1 
                 AND has(profiling.secure_id.signals, 'INVALID_NONCE') 
            THEN 'CONFIRMED_REPLAY'
            WHEN profiling.replay_count > 1 
                 AND NOT has(profiling.secure_id.signals, 'INVALID_NONCE')
            THEN 'HIGH_REPLAY_COUNT_NO_INVALID_NONCE'
            WHEN profiling.replay_count <= 1 
                 AND has(profiling.secure_id.signals, 'INVALID_NONCE')
            THEN 'LOW_REPLAY_COUNT_WITH_INVALID_NONCE'
            ELSE 'NORMAL_SESSION'
        END as session_classification,
        -- Additional profiling data for analysis
        profiling.session_duration,
        profiling.device_fingerprint,
        profiling.geo_location,
        profiling.user_agent
    FROM your_darwinium_table  -- Replace with actual table name
    WHERE 1=1
        AND session_type = 'p2p'  -- Focus on P2P sessions
        AND timestamp >= CURRENT_DATE - INTERVAL '30 days'  -- Adjust timeframe as needed
        AND (profiling.replay_count > 1 
             OR has(profiling.secure_id.signals, 'INVALID_NONCE'))
)

-- Main analysis query
SELECT 
    session_classification,
    COUNT(*) as session_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT device_id) as unique_devices,
    AVG(replay_count) as avg_replay_count,
    MAX(replay_count) as max_replay_count,
    -- Percentage breakdown
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage_of_total
FROM session_replay_candidates
GROUP BY session_classification
ORDER BY session_count DESC;

-- Detailed view of confirmed replay sessions
SELECT 
    'CONFIRMED_REPLAY_SESSIONS' as analysis_type,
    session_id,
    user_id,
    device_id,
    timestamp,
    replay_count,
    has_invalid_nonce,
    session_duration,
    device_fingerprint,
    geo_location,
    user_agent
FROM session_replay_candidates
WHERE session_classification = 'CONFIRMED_REPLAY'
ORDER BY timestamp DESC, replay_count DESC;

-- Summary statistics for validation
SELECT 
    'VALIDATION_SUMMARY' as summary_type,
    COUNT(*) as total_p2p_sessions_analyzed,
    SUM(CASE WHEN session_classification = 'CONFIRMED_REPLAY' THEN 1 ELSE 0 END) as confirmed_replay_sessions,
    SUM(CASE WHEN session_classification = 'HIGH_REPLAY_COUNT_NO_INVALID_NONCE' THEN 1 ELSE 0 END) as high_replay_no_invalid_nonce,
    SUM(CASE WHEN session_classification = 'LOW_REPLAY_COUNT_WITH_INVALID_NONCE' THEN 1 ELSE 0 END) as low_replay_with_invalid_nonce,
    SUM(CASE WHEN session_classification = 'NORMAL_SESSION' THEN 1 ELSE 0 END) as normal_sessions,
    -- Validation metrics
    ROUND(
        SUM(CASE WHEN session_classification = 'CONFIRMED_REPLAY' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN profiling.replay_count > 1 THEN 1 ELSE 0 END), 0), 2
    ) as detection_coverage_percentage
FROM session_replay_candidates;

/*
    Expected Results Analysis:
    
    1. CONFIRMED_REPLAY: Sessions that meet both criteria
       - These should align with your known bad sessions (p2psession)
       
    2. HIGH_REPLAY_COUNT_NO_INVALID_NONCE: Sessions with high replay count but no INVALID_NONCE
       - These might indicate false negatives or different attack patterns
       
    3. LOW_REPLAY_COUNT_WITH_INVALID_NONCE: Sessions with INVALID_NONCE but low replay count
       - These might indicate false positives or edge cases
       
    Validation Goal: Ensure all known bad sessions appear in CONFIRMED_REPLAY category
*/
