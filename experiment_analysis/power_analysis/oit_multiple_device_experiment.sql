create or replace table risk.test.oit_multiple_device_experiment as 


with t2 as (with t1 as (select * FROM chime.decision_platform.execute_transfer_event 
    where 1=1
    and is_shadow_mode = false
    and transfer_type = 'instant_outbound_transfer'
   and experiment_name = 'oit_mutiple_device_experiment'
   and policy_name in ('iot_multiple_devices_otp', 'iot_multiple_devices')
qualify row_number() over (partition by decision_id  order by (select null))=1)


select a.* ,
su._creation_timestamp as step_up_creation_timestamp,
su.stepped_up_status,
b.TRANSACTION_ID,
b.transaction_timestamp,
b.processor,
b.card_id,
b.SETTLED_AMT,
b.AUTHORIZATION_CODE,
b.EXTERNAL_TRANSACTION_ID,
b.PROGRAM_BANK,
g.dispute_created_at,
g.user_dispute_claim_id,
f.reason,
case when f.unique_transaction_id is not null then 1 else 0 end as dispute_ind,
case when f.unique_transaction_id is not null and f.reason ilike 'unauth%' then 1 else 0 end as dispute_unauth_ind,
case when f.unique_transaction_id is not null and f.resolution_code is null then 1 else 0 end as dispute_pending_ind,
case when f.unique_transaction_id is not null and f.reason ilike 'unauth%' and (f.resolution = 'Pending Resolution' or f.resolution is null) then 1 else 0 end as dispute_unauth_pending_ind,   
case when f.resolution_code ilike 'approve%' then 1 else 0 end as dispute_aprv_ind,
case when f.resolution_code ilike 'approve%' and f.reason ilike 'unauth%' then 1 else 0 end as dispute_unauth_aprv_ind,
g.amount_cred,
g.cred_date,
g.amount_rev,
g.rev_date,
g.amount_final_cred,
g.final_cred_date,
g.amount_final_rev,
from t1 a 
left join (SELECT
                     user_id,
                     decision_id,
                     _creation_timestamp,
                     step_up_status as stepped_up_status
                     FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.STEP_UPS_EVENTS_V1_STATUS_CHANGE
                     WHERE challenge_type = 'STEP_UP_CHALLENGE_TYPE_OTP'
                    AND event_name in ('execute_transfer_event')
                    AND sub_event_name = 'instant_outbound_transfer'
                    qualify ROW_NUMBER() OVER (partition by decision_id  order by _context['additional_context']['creation_timestamp'] desc)  = 1) as su on a.decision_id = su.decision_id

            
left join (select 
      a.* , 
      b.ml_prediction_model_score as ATOM_v3_score_,
      case when c.correlation_id_2 is null then a.correlation_id when c.correlation_id_2 is not null then c.correlation_id_2 end as merchant_number
      from t1 a
      left join (
            select user_id, correlation_id, ML_PREDICTION_MODEL, ml_prediction_model_score 
            from chime.decision_platform.execute_transfer_event
            where is_shadow_mode = true
            and  transfer_type = 'instant_outbound_transfer'
            and ml_prediction_model = 'atom_v3')b on b.correlation_id = a.correlation_id and a.user_id = b.user_id
      left join (select 
                    a.original_timestamp, a.user_id, a.decision_id,  b.id as step_up_id, b.STEP_UP_STATUS, b.CHALLENGE_TYPE, b.CHALLENGE_VENDOR, a.correlation_id as                            corrrelation_id_1, c.correlation_id as correlation_id_2, d.merchant_number, d.external_transaction_id, d.authorization_code, d.settled_amt,                                 d.reversal_amt, d.reversal_timestamp, d.reversal_transaction_id,
                    from chime.decision_platform.execute_transfer_event a
                    left join 
                        (select * FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.STEP_UPS_EVENTS_V1_STATUS_CHANGE
                          WHERE challenge_type = 'STEP_UP_CHALLENGE_TYPE_OTP'
                        AND STEP_UP_STATUS = 'STEP_UP_STATUS_CHALLENGE_AUTHENTICATED'
                        AND event_name in ('execute_transfer_event')
                         AND sub_event_name = 'instant_outbound_transfer') b on b.user_id = a.user_id and a.decision_id = b.decision_id   
                        LEFT JOIN 
                         (
                    SELECT *, risk_context:challenge_type::varchar as challenge_type, risk_context:step_up_id::varchar as step_up_id 
                    FROM postgres_db.money_transfer_service.transfers
                    WHERE type = 'instant_outbound_transfer') c on c.step_up_id = b.id
                    LEFT JOIN 
                    (select * from (select a.*, b.settled_amt as reversal_amt, b.transaction_timestamp as reversal_timestamp, b.transaction_id as reversal_transaction_id
                    from edw_db.core.ftr_transaction a
                    left join 
                    (select * from edw_db.core.ftr_transaction
                    where transaction_cd = 'ADIP'
                   ) b on b.user_id = a.user_id and a.MERCHANT_NUMBER = b.MERCHANT_NUMBER
                     and a.transaction_cd = 'ADbz') where transaction_cd in ('ADIP','ADbz')) d on d.merchant_number = c.correlation_id and d.user_id = a.user_id
                    where a.is_shadow_mode = False
                    and  a.transfer_type = 'instant_outbound_transfer'
                    and (corrrelation_id_1 != CORRELATION_ID_2 and CORRELATION_ID_2 is not null)
                    qualify ROW_NUMBER() OVER (PARTITION BY a.decision_id ORDER BY a.original_timestamp DESC) = 1) c on c.user_id = a.user_id and c.decision_id =       
     a.decision_id
     where a.is_shadow_mode = false
     and a.transfer_type = 'instant_outbound_transfer')  c on c.user_id = a.user_id and c.decision_id =       
     a.decision_id

left join (select * from edw_db.core.ftr_transaction where transaction_cd = 'ADbz' and transaction_timestamp::date >='2025-03-26') b on b.user_id = a.user_id and b.merchant_number = c.merchant_number

left join risk.prod.all_disputable_transactions g
  ON b.user_id = a.user_id and g.unique_transaction_id =  b.transaction_id and g.TRANSACTION_TIMESTAMP::date  >='2025-03-26'
left join  risk.prod.disputed_transactions f on a.user_id = f.user_id and f.unique_transaction_id =  b.transaction_id and f.transaction_timestamp::date  >='2025-03-26'
qualify ROW_NUMBER() OVER (PARTITION BY a.decision_id ORDER BY a.original_timestamp DESC) = 1)



--deduping denied transfers by same user/amount within 1 minute
--, T3 as (
select * from (WITH deny_with_flags AS (
  SELECT 
    a.*,
    ROW_NUMBER() OVER (
      PARTITION BY a.user_id
      ORDER BY a.original_timestamp
    ) AS rn,
    COUNT(b.user_id) OVER (
      PARTITION BY a.user_id, a.original_timestamp, a.transfer_amount
    ) AS duplicate_flag
  FROM t2 a
  LEFT JOIN t2 b
    ON a.user_id = b.user_id
    AND a.decision_outcome = 'deny'
    AND b.decision_outcome = 'deny'
    AND a.original_timestamp > b.original_timestamp
    AND a.original_timestamp <= b.original_timestamp + INTERVAL '5 minutes'
    AND ABS(a.transfer_amount - b.transfer_amount) <= 1
),
final_deny AS (
  SELECT
    -- Only original columns (106 total)
    ORIGINAL_TIMESTAMP, USER_ID, USER_STATUS, USER_STATUS_REASON, USER_ENROLLED_AT,
    USER_HAS_ACTIVATED_PHYSICAL_CARD, USER_IS_PAYROLL_DD, USER_LAST_DEVICE_ID,
    USER_REFERRED_BY, USER_REFERRED_BY_STATUS, USER_REFERRED_BY_STATUS_REASON,
    USER_REFERRED_BY_ENROLLED_AT, EVENT_NAME, SUB_EVENT_NAME, DECISION_ID,
    IS_SHADOW_MODE, DECISION_OUTCOME, POLICY_RESULT, POLICY_NAME, POLICY_ACTIONS,
    TRANSFER_AMOUNT, INSTANT_TRANSFER_ID, TRANSFER_REQUEST_ID, CORRELATION_ID,
    AGENT_ID, AGENT_EMAIL, AGENT_ROLES, TRANSFER_TYPE, TRANSFER_TYPE_CODE,
    TRANSFER_SOURCE, TRANSFER_DESTINATION, TRANSFER_DESCRIPTION, TRANSACTION_CODE,
    DEVICE_ID, DEVICE_MANUFACTURER, DEVICE_MODEL, DEVICE_OS_NAME, DEVICE_OS_VERSION,
    IP_ADDRESS, DEVICE_NETWORK_CARRIER, DEVICE_TIMEZONE, USER_LOCALE,
    REQUEST_ORIGIN_PLATFORM, REMOTE_CONTROLLED_APPS, SESSION_ID, ANALYTICS_SESSION_ID,
    APP_VERSION, HAS_LINKED_PLAID_ACCOUNT, ECI_INDICATOR, EXTERNAL_CARD_ID,
    EXTERNAL_CARD_BIN, EXTERNAL_CARD_LAST_FOUR, EXTERNAL_CARD_NETWORK,
    EXTERNAL_CARD_AVS_CODE, LAST_EXTERNAL_CARD_CREATED_AT, LAST_EXTERNAL_CARD_LINKED_AT,
    DAILY_LIMIT, DAILY_LIMIT_ACCRUAL, MONTHLY_LIMIT, MONTHLY_LIMIT_ACCRUAL,
    LIFETIME_LIMIT, LIFETIME_LIMIT_ACCRUAL, CHALLENGE_TYPE, STEP_UP_STATUS,
    EXPERIMENT_NAME, EXPERIMENT_VARIANT, ML_INFERENCE_MODEL, ML_INFERENCE_MODEL_VERSION,
    ML_INFERENCE_MODEL_SCORE, ML_INFERENCE_MODEL_VARIANT, ML_INFERENCE_MODEL_PERCENTILE,
    ML_INFERENCE_MODEL_PRECISION, ML_INFERENCE_MODEL_RECALL, ML_PREDICTION_MODEL,
    ML_PREDICTION_MODEL_VERSION, ML_PREDICTION_MODEL_SCORE, ML_PREDICTION_MODEL_TS,
    NAMED_LIST, NAMED_LIST_RESULT, EPOCH_TS, STEP_UP_CREATION_TIMESTAMP,
    STEPPED_UP_STATUS, TRANSACTION_ID, TRANSACTION_TIMESTAMP, PROCESSOR, CARD_ID,
    SETTLED_AMT, AUTHORIZATION_CODE, EXTERNAL_TRANSACTION_ID, PROGRAM_BANK,
    DISPUTE_CREATED_AT, USER_DISPUTE_CLAIM_ID, REASON, DISPUTE_IND, DISPUTE_UNAUTH_IND,
    DISPUTE_PENDING_IND, DISPUTE_UNAUTH_PENDING_IND, DISPUTE_APRV_IND,
    DISPUTE_UNAUTH_APRV_IND, AMOUNT_CRED, CRED_DATE, AMOUNT_REV, REV_DATE,
    AMOUNT_FINAL_CRED, FINAL_CRED_DATE, AMOUNT_FINAL_REV
  FROM deny_with_flags
  WHERE decision_outcome != 'deny' OR duplicate_flag = 0
),
non_deny_clean AS (
  SELECT
    ORIGINAL_TIMESTAMP, USER_ID, USER_STATUS, USER_STATUS_REASON, USER_ENROLLED_AT,
    USER_HAS_ACTIVATED_PHYSICAL_CARD, USER_IS_PAYROLL_DD, USER_LAST_DEVICE_ID,
    USER_REFERRED_BY, USER_REFERRED_BY_STATUS, USER_REFERRED_BY_STATUS_REASON,
    USER_REFERRED_BY_ENROLLED_AT, EVENT_NAME, SUB_EVENT_NAME, DECISION_ID,
    IS_SHADOW_MODE, DECISION_OUTCOME, POLICY_RESULT, POLICY_NAME, POLICY_ACTIONS,
    TRANSFER_AMOUNT, INSTANT_TRANSFER_ID, TRANSFER_REQUEST_ID, CORRELATION_ID,
    AGENT_ID, AGENT_EMAIL, AGENT_ROLES, TRANSFER_TYPE, TRANSFER_TYPE_CODE,
    TRANSFER_SOURCE, TRANSFER_DESTINATION, TRANSFER_DESCRIPTION, TRANSACTION_CODE,
    DEVICE_ID, DEVICE_MANUFACTURER, DEVICE_MODEL, DEVICE_OS_NAME, DEVICE_OS_VERSION,
    IP_ADDRESS, DEVICE_NETWORK_CARRIER, DEVICE_TIMEZONE, USER_LOCALE,
    REQUEST_ORIGIN_PLATFORM, REMOTE_CONTROLLED_APPS, SESSION_ID, ANALYTICS_SESSION_ID,
    APP_VERSION, HAS_LINKED_PLAID_ACCOUNT, ECI_INDICATOR, EXTERNAL_CARD_ID,
    EXTERNAL_CARD_BIN, EXTERNAL_CARD_LAST_FOUR, EXTERNAL_CARD_NETWORK,
    EXTERNAL_CARD_AVS_CODE, LAST_EXTERNAL_CARD_CREATED_AT, LAST_EXTERNAL_CARD_LINKED_AT,
    DAILY_LIMIT, DAILY_LIMIT_ACCRUAL, MONTHLY_LIMIT, MONTHLY_LIMIT_ACCRUAL,
    LIFETIME_LIMIT, LIFETIME_LIMIT_ACCRUAL, CHALLENGE_TYPE, STEP_UP_STATUS,
    EXPERIMENT_NAME, EXPERIMENT_VARIANT, ML_INFERENCE_MODEL, ML_INFERENCE_MODEL_VERSION,
    ML_INFERENCE_MODEL_SCORE, ML_INFERENCE_MODEL_VARIANT, ML_INFERENCE_MODEL_PERCENTILE,
    ML_INFERENCE_MODEL_PRECISION, ML_INFERENCE_MODEL_RECALL, ML_PREDICTION_MODEL,
    ML_PREDICTION_MODEL_VERSION, ML_PREDICTION_MODEL_SCORE, ML_PREDICTION_MODEL_TS,
    NAMED_LIST, NAMED_LIST_RESULT, EPOCH_TS, STEP_UP_CREATION_TIMESTAMP,
    STEPPED_UP_STATUS, TRANSACTION_ID, TRANSACTION_TIMESTAMP, PROCESSOR, CARD_ID,
    SETTLED_AMT, AUTHORIZATION_CODE, EXTERNAL_TRANSACTION_ID, PROGRAM_BANK,
    DISPUTE_CREATED_AT, USER_DISPUTE_CLAIM_ID, REASON, DISPUTE_IND, DISPUTE_UNAUTH_IND,
    DISPUTE_PENDING_IND, DISPUTE_UNAUTH_PENDING_IND, DISPUTE_APRV_IND,
    DISPUTE_UNAUTH_APRV_IND, AMOUNT_CRED, CRED_DATE, AMOUNT_REV, REV_DATE,
    AMOUNT_FINAL_CRED, FINAL_CRED_DATE, AMOUNT_FINAL_REV
  FROM t2
  WHERE decision_outcome != 'deny'
)

SELECT * FROM final_deny
UNION ALL
SELECT * FROM non_deny_clean

)
qualify ROW_NUMBER() OVER (PARTITION BY decision_id ORDER BY original_timestamp DESC) = 1
