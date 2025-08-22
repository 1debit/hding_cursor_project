-- Title: Extract Session Replay P2P Transfer Cases
-- Intent: Identify P2P transfers initiated via session replay attacks over past 2 months
-- Inputs: STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE
-- Output: Table with device_id, user_id, timestamp, and parsed JSON fields for flagged sessions
-- Assumptions: 
--   - Session replay identified by replay_count > 1 AND INVALID_NONCE signals
--   - Only P2P transfer step_name events considered
--   - Past 2 months = 60 days from current date
-- Validation: Check row counts, verify JSON parsing, confirm time window coverage

-- Create table for session replay P2P cases
CREATE OR REPLACE TABLE RISK.TEST.session_replay_p2p_cases AS
WITH darwinium_events AS (
    SELECT 
        t._DEVICE_ID,
        t._USER_ID,
        t._CREATION_TIMESTAMP,
        TRY_PARSE_JSON(t.body) AS body_json,
        t.body AS raw_body
    FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE t
    WHERE 1=1
        AND t.name = 'VENDOR_DARWINIUM'
        AND t._CREATION_TIMESTAMP >= DATEADD(day, -60, CURRENT_DATE())
        AND t._CREATION_TIMESTAMP < CURRENT_DATE()
        AND TRY_PARSE_JSON(t.body) IS NOT NULL
),
session_replay_filtered AS (
    SELECT 
        _DEVICE_ID,
        _USER_ID,
        _CREATION_TIMESTAMP,
        body_json,
        raw_body,
        body_json:step_name::VARCHAR AS step_name,
        body_json:identifier::VARCHAR AS identifier,
        body_json:profiling:replay_count::INTEGER AS replay_count,
        body_json:profiling:secure_id:signals::VARCHAR AS secure_id_signals
    FROM darwinium_events
    WHERE 1=1
        AND body_json:profiling:replay_count::INTEGER > 1
        AND body_json:profiling:secure_id:signals::VARCHAR LIKE '%INVALID_NONCE%'
        AND body_json:step_name::VARCHAR = 'p2p_transfer'
)
SELECT 
    _DEVICE_ID AS device_id,
    _USER_ID AS user_id,
    _CREATION_TIMESTAMP AS creation_timestamp_utc,
    step_name,
    identifier,
    replay_count,
    secure_id_signals,
    body_json,
    raw_body,
    CURRENT_TIMESTAMP() AS extracted_at_utc
FROM session_replay_filtered
ORDER BY _CREATION_TIMESTAMP DESC;

-- Validation queries
SELECT 'Row count check' AS validation_step, COUNT(*) AS total_rows 
FROM RISK.TEST.session_replay_p2p_cases;

SELECT 'Date range check' AS validation_step, 
       MIN(creation_timestamp_utc) AS earliest_record,
       MAX(creation_timestamp_utc) AS latest_record,
       DATEDIFF(day, MIN(creation_timestamp_utc), MAX(creation_timestamp_utc)) AS date_span_days
FROM RISK.TEST.session_replay_p2p_cases;

SELECT 'Unique users check' AS validation_step, 
       COUNT(DISTINCT user_id) AS unique_users,
       COUNT(DISTINCT device_id) AS unique_devices
FROM RISK.TEST.session_replay_p2p_cases;

-- Create driver table with fraud labels for accuracy evaluation
CREATE OR REPLACE TABLE RISK.TEST.hding_dwn_p2p_session_replay_driver AS (
WITH parsed AS (
    SELECT *
    FROM RISK.TEST.session_replay_p2p_cases a
), 
t2 AS (
    -- DWN with p2p decision platform data
    SELECT  
        p.*,
        r.decision_id,
        r.sender_user_id,
        r.original_timestamp,
        r.transfer_amount,
        CASE 
            WHEN decision_outcome = 'deny' THEN 'deny' 
            WHEN decision_outcome = 'step_up_otp' THEN 'OTP' 
            ELSE 'allow' 
        END AS dec_plat_decision
    FROM parsed p
    JOIN CHIME.DECISION_PLATFORM.pay_friends r 
        ON (p.DEVICE_ID = r.sender_device_id 
            AND p.user_id = r.sender_user_id 
            AND r.event_name IN ('pay_anyone_v3','pay_friends_v3'))
        AND DATE_TRUNC(MINUTE, p.CREATION_TIMESTAMP_UTC) = DATE_TRUNC(MINUTE, r.original_timestamp)
        AND CONVERT_TIMEZONE('America/Los_Angeles', r.original_timestamp) 
            BETWEEN p.CREATION_TIMESTAMP_UTC AND DATEADD(minute, 1, p.CREATION_TIMESTAMP_UTC)
        AND r.original_timestamp::DATE BETWEEN '2025-05-21' AND CURRENT_DATE()
        AND is_shadow_mode = 'false'
    WHERE 1=1
        AND identifier IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY identifier ORDER BY r.original_timestamp) = 1
)
-- Append final dispute info for fraud labeling
SELECT 
    a.*,
    c.email_hash,
    CASE WHEN b.user_id IS NOT NULL THEN 1 ELSE 0 END AS fraud_dispute_ind
FROM t2 a
LEFT JOIN RISK.PROD.all_disputable_transactions b 
    ON (a.sender_user_id = b.user_id 
        AND b.transaction_timestamp::DATE BETWEEN '2025-05-21' AND CURRENT_DATE()
        AND b.dispute_created_at IS NOT NULL
        AND b.transaction_code IN ('ADM', 'ADPF', 'ADTS', 'ADTU', 'ADpb') 
        AND a.original_timestamp BETWEEN DATEADD(minute, -30, b.transaction_timestamp) 
                                     AND DATEADD(minute, 10, b.transaction_timestamp)
        AND a.transfer_amount = b.transaction_amount * -1
        AND a.dec_plat_decision <> 'deny')
LEFT JOIN EDW_PII_DB.CORE.dim_user_pii c 
    ON (a.sender_user_id = c.user_id)
QUALIFY ROW_NUMBER() OVER (PARTITION BY a.identifier ORDER BY b.transaction_timestamp) = 1
);

-- Validation queries for driver table
SELECT 'Driver table row count' AS validation_step, COUNT(*) AS total_rows 
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver;

SELECT 'Fraud label distribution' AS validation_step, 
       fraud_dispute_ind,
       COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY fraud_dispute_ind
ORDER BY fraud_dispute_ind;

SELECT 'Decision platform distribution' AS validation_step,
       dec_plat_decision,
       COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM RISK.TEST.hding_dwn_p2p_session_replay_driver
GROUP BY dec_plat_decision
ORDER BY dec_plat_decision;
