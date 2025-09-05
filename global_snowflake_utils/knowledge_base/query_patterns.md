# Snowflake Common Query Patterns

> Global query pattern library - Reusable SQL query logic and best practices

## 📑 **Table of Contents**
- [Data Extraction Patterns](#-data-extraction-patterns)
  - [Transaction to Dispute Linking](#transaction-to-dispute-linking-pattern)
  - [Dual Auth Settlement](#dual-auth-settlement-pattern)
- [Metric Calculation Patterns](#-metric-calculation-patterns)
  - [Dispute Rate Calculation](#dispute-rate-calculation)
  - [Cross-State Transaction Analysis](#cross-state-transaction-analysis)
- [Data Validation Patterns](#-data-validation-patterns)
- [Performance Optimization Patterns](#-performance-optimization-patterns)
- [User Activity Analysis Patterns](#-user-activity-analysis-patterns)
  - [Comprehensive User Activity Timeline](#comprehensive-user-activity-timeline)
  - [Risk Strategy Simulation](#risk-strategy-simulation-pattern)
- [Pattern Usage Guide](#-pattern-usage-guide)

## 🎯 Query Pattern Categories

### 📊 Data Extraction Patterns

#### Transaction to Dispute Linking Pattern
```sql
-- Standard pattern for linking transactions to disputes
WITH transaction_disputes AS (
    SELECT
        a.user_id,
        a.auth_id,
        a.merchant_name,
        a.final_amt,
        a.snapshot_timestamp,
        CASE WHEN b.user_id IS NOT NULL THEN 1 ELSE 0 END AS dispute_ind,
        b.reason,
        b.dispute_created_at,
        DATEDIFF(day, a.snapshot_timestamp, b.dispute_created_at) AS days_to_dispute
    FROM risk.test.spending_risk_master_driver_table a
    LEFT JOIN risk.prod.disputed_transactions b
      ON (a.user_id = b.user_id
          AND (b.authorization_code = a.auth_id
               OR b.authorization_code = a.settled_auth_id))
    QUALIFY ROW_NUMBER() OVER (
      PARTITION BY a.user_id, a.auth_id
      ORDER BY b.dispute_created_at
    ) = 1
)
SELECT * FROM transaction_disputes;
```

#### Dual Auth Settlement Pattern
```sql
-- Linking original authorization to settlement for dual auths
SELECT
    rae.user_id,
    rae.auth_id AS original_auth_id,
    rae.final_amt AS original_amount,
    dual.auth_id AS settled_auth_id,
    dual.final_amt AS settled_amount,
    dual.auth_event_created_ts AS settled_timestamp
FROM edw_db.core.fct_realtime_auth_event rae
LEFT JOIN edw_db.core.fct_realtime_auth_event dual
  ON (rae.user_id = dual.user_id
      AND rae.auth_id = dual.original_auth_id)
WHERE rae.original_auth_id = '0'  -- Original auth only
  AND rae.response_cd IN ('00', '10')  -- Successful auths
  AND rae.req_amt < 0;  -- Purchase transactions
```

### 📈 Metric Calculation Patterns

#### Dispute Rate Calculation
```sql
-- Calculate 7-day unauthorized dispute rate by merchant
SELECT
    merchant_name,
    COUNT(*) AS total_transactions,
    SUM(final_amt) AS total_volume,
    SUM(CASE WHEN reason ILIKE 'unauth%' THEN dispute_ind_7d ELSE 0 END) AS unauthorized_disputes,
    SUM(CASE WHEN reason ILIKE 'unauth%' THEN dispute_ind_7d * final_amt ELSE 0 END) AS disputed_volume,
    SUM(CASE WHEN reason ILIKE 'unauth%' THEN dispute_ind_7d * final_amt ELSE 0 END) * 10000 / SUM(final_amt) AS dispute_rate_bps,
    SUM(CASE WHEN reason ILIKE 'unauth%' THEN dispute_ind_7d ELSE 0 END) / COUNT(*) AS dispute_rate_ratio
FROM risk.test.spending_risk_master_driver_table
WHERE snapshot_timestamp >= DATEADD(day, -180, CURRENT_DATE())
GROUP BY merchant_name
HAVING COUNT(*) >= 50  -- Minimum transaction threshold
ORDER BY dispute_rate_bps DESC;
```

#### Cross-State Transaction Analysis
```sql
-- Analyze transactions across different states
SELECT
    user_state,
    merchant_state,
    CASE WHEN user_state <> merchant_state THEN 1 ELSE 0 END AS cross_state_ind,
    COUNT(*) AS transaction_count,
    SUM(final_amt) AS total_volume,
    AVG(final_amt) AS avg_transaction_size
FROM (
    SELECT
        rae.user_id,
        rae.final_amt,
        m.state_cd AS user_state,
        CASE
            WHEN rae.card_network_cd = 'Mastercard' THEN TRIM(SUBSTR(rae.auth_event_merchant_name_raw, 38))
            WHEN rae.card_network_cd = 'Visa' THEN TRIM(SUBSTR(rae.auth_event_merchant_name_raw, 37, 2))
            ELSE NULL
        END AS merchant_state
    FROM edw_db.core.fct_realtime_auth_event rae
    LEFT JOIN edw_db.core.member_details m ON rae.user_id = m.user_id
    WHERE rae.auth_event_created_ts >= DATEADD(day, -30, CURRENT_DATE())
      AND rae.response_cd IN ('00', '10')
      AND rae.req_amt < 0
) t
GROUP BY user_state, merchant_state, cross_state_ind
ORDER BY transaction_count DESC;
```

### 🔍 Data Validation Patterns

#### Data Quality Checks
```sql
-- Standard data quality validation queries
-- [To be filled with specific validation logic]
```

#### Result Validation Pattern
```sql
-- Analysis result verification and cross-checking
-- [To be filled with specific validation methods]
```

## ⚡ Performance Optimization Patterns

### Efficient Filtering Strategies
- **Time Filter Optimization:** [Specific optimization methods]
- **User Filter Optimization:** [Specific optimization methods]
- **Business Filter Optimization:** [Specific optimization methods]

### JOIN Optimization Strategies
- **Table Join Order:** [Best join strategies]
- **Index Utilization:** [How to effectively use indexes]

## 🏗️ User Activity Analysis Patterns

### Comprehensive User Activity Timeline
```sql
-- Complete user activity log from multiple data sources
WITH user_info AS (
    SELECT DISTINCT id::varchar AS user_id
    FROM CHIME.FINANCE.members
    WHERE id = 49127109  -- Replace with target user_id
)

-- Tokenization/Provisioning Events
SELECT DISTINCT
    original_timestamp AS timestamp,
    user_id::varchar AS user_id,
    device_id::varchar AS id,
    'token/provisioning event' AS type,
    CONCAT_WS('|',
        'Token_id: ' || IFNULL(token_id, 'n/a'),
        'Card_last_4: ' || IFNULL(card_last_4, 'n/a'),
        'Wallet_type: ' || IFNULL(wallet_type, 'n/a')
    ) AS description,
    risk_score::varchar AS vrs,
    policy_name AS rules_denied,
    0 AS amt
FROM chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization
WHERE is_shadow_mode = false
  AND user_id IN (SELECT * FROM user_info)
  AND device_id IS NOT NULL

UNION ALL

-- Card Authorization Events
SELECT
    rta.user_id,
    CONVERT_TIMEZONE('America/Los_Angeles', rta.trans_ts) AS timestamp,
    rta.auth_id::varchar AS id,
    rta.auth_event_merchant_name_raw AS merchant_name,
    CASE
        WHEN rta.MCC_CD IN ('6010','6011') THEN 'Withdrawal'
        WHEN rta.mti_cd IN ('0400','0420') THEN 'Mrch_Credit'
        ELSE 'Purchase'
    END AS type,
    CONCAT('Card Transaction: ', rta.entry_type, '; MCC_CD: ', rta.mcc_cd) AS description,
    CASE
        WHEN dc.is_virtual = true THEN dc.CARD_TYPE || '(t) ' || RIGHT(rta.PAN, 4)
        ELSE dc.CARD_TYPE || ' ' || RIGHT(rta.PAN, 4)
    END AS card_type,
    CASE WHEN rta.response_cd IN ('00','10') THEN 'Approved' ELSE 'Declined' END AS decision,
    rta.risk_score::varchar AS vrs,
    rta.req_amt AS amt
FROM edw_db.core.fct_realtime_auth_event rta
LEFT JOIN EDW_DB.CORE.DIM_CARD dc ON rta.USER_ID = dc.USER_ID AND RIGHT(rta.PAN, 4) = RIGHT(dc.CARD_NUMBER, 4)
WHERE rta.original_auth_id::varchar = '0'
  AND (rta.final_amt >= 0 OR rta.mti_cd IN ('0400','0420'))
  AND rta.user_id IN (SELECT * FROM user_info)

UNION ALL

-- Login Events
SELECT
    ls.user_id,
    CONVERT_TIMEZONE('America/Los_Angeles', ls.session_timestamp) AS timestamp,
    ls.device_id::varchar AS id,
    'n/a' AS merchant_name,
    'login' AS type,
    CONCAT(
        'ATOMv2 score:', IFNULL(atomv2.score, 0),
        '; ATOMV3 score:', IFNULL(atomv3.score, 0),
        '; DEVICE:', ls.device_model,
        '; CARRIER:', ls.network_carrier
    ) AS description,
    'n/a' AS card_type,
    'n/a' AS decision,
    'n/a' AS vrs,
    0 AS amt
FROM edw_db.feature_store.atom_user_sessions_v2 ls
LEFT JOIN ml.model_inference.ato_login_alerts atomv2
    ON ls.user_id::varchar = atomv2.user_id::varchar
    AND ls.device_id = atomv2.device_id
    AND atomv2.score <> 0
LEFT JOIN streaming_platform.segment_and_hawker_production.dsml_events_predictions_segment_v2_atom_model_v3 atomv3
    ON ls.user_id::varchar = atomv3._user_id::varchar
    AND ls.device_id = atomv3.device_id
    AND atomv3.score <> 0
WHERE ls.user_id IN (SELECT * FROM user_info)

ORDER BY timestamp;
```

### Risk Strategy Simulation Pattern
```sql
-- Policy validation and simulation framework
WITH simu AS (
    -- Simulation data from historical transactions
    SELECT DISTINCT
        a.user_id::varchar AS user_id,
        a.auth_id,
        a.snapshot_timestamp,
        a.req_amt,
        a.risk_score,
        -- Simulation features
        ZEROIFNULL(MERCHANT_NAME_USER_ID__DISPUTES__7D__390D__V1___COUNT__TXN) AS mrch_txn_hist,
        user_id__pii_update__0s__7d__v1___count__phone_change_by_user,
        USER_ID__ATOM_SCORE__0S__3D__V2___MAX__ATOM_SCORE
    FROM risk.test.hding_contactless_202302_vali a
    LEFT JOIN risk.test.hding_contactless_vali_feature_set b
        ON (a.user_id::varchar = b.user_id::varchar AND a.auth_id = b.auth_id)
    WHERE ZEROIFNULL(MERCHANT_NAME_USER_ID__DISPUTES__7D__390D__V1___COUNT__TXN) = 0
      AND user_id__pii_update__0s__7d__v1___count__phone_change_by_user >= 1
      AND USER_ID__ATOM_SCORE__0S__3D__V2___MAX__ATOM_SCORE >= 0.5
      AND req_amt > 100
),
prod AS (
    -- Production data from shadow mode
    SELECT
        a.user_id,
        timestamp AS ts,
        decision_id,
        request:card_auth_event:id::varchar AS auth_id,
        request:card_auth_event:merchant:descriptor AS merchant_name,
        request:card_auth_event:risk_score AS risk_score_prod
    FROM streaming_platform.segment_and_hawker_production.realtimedecisioning_v1_risk_decision_log a
    WHERE timestamp::date >= '2023-03-08'
      AND event_name = 'card_auth_event'
      AND labels:service_names = 'shadow'
      AND decision:policy_outcomes:hb_contactless_ato_v1:met = true
)
SELECT
    CASE
        WHEN simu.user_id IS NULL THEN 'prod only'
        WHEN prod.user_id IS NULL THEN 'simu only'
        ELSE 'both'
    END AS recon_cat,
    simu.*,
    prod.*
FROM simu
FULL OUTER JOIN prod ON (simu.user_id::varchar = prod.user_id::varchar AND simu.auth_id = prod.auth_id)
ORDER BY simu.user_id, simu.auth_id;
```

### Network Carrier Mapping Pattern
```sql
-- Superior 4-step network carrier mapping workflow
-- Step 1: Extract distinct carriers for AI research
SELECT DISTINCT
    network_carrier,
    COUNT(*) as record_count
FROM risk.test.hding_a3id_login_info
WHERE network_carrier IS NOT NULL
    AND TRIM(network_carrier) != ''
    AND network_carrier != '--'
    AND network_carrier != 'unknown'
GROUP BY network_carrier
ORDER BY record_count DESC;

-- Step 2: Apply comprehensive mapping from CSV research
CREATE OR REPLACE TABLE risk.test.network_carrier_country_mapping AS (
    SELECT
        carrier_name,
        country_code,
        country_name,
        region,
        'mapped' as mapping_status
    FROM VALUES
        ('T-Mobile', 'USA', 'United States', 'North America'),
        ('FarEasTone', 'TWN', 'Taiwan', 'Asia'),
        ('Verizon', 'USA', 'United States', 'North America')
        -- ... 315 total carriers from AI research
    AS t(carrier_name, country_code, country_name, region)
);

-- Step 3: Create enriched login data with country mapping
CREATE OR REPLACE TABLE risk.test.hding_a3id_login_info_enriched AS (
    SELECT
        l.*,
        m.country_code as network_carrier_country,
        m.country_name as network_carrier_country_name,
        m.region as network_carrier_region,
        CASE
            WHEN m.country_code IS NOT NULL THEN 'mapped'
            WHEN l.network_carrier IS NULL OR TRIM(l.network_carrier) = '' THEN 'empty'
            ELSE 'unmapped'
        END as mapping_status
    FROM risk.test.hding_a3id_login_info l
    LEFT JOIN risk.test.network_carrier_country_mapping m
        ON UPPER(TRIM(l.network_carrier)) = UPPER(TRIM(m.carrier_name))
);

-- Step 4: Network vs IP carrier mismatch analysis (emulator detection)
SELECT
    network_carrier,
    network_carrier_country,
    ip_carrier,
    ip_country,
    CASE
        WHEN network_carrier_country != ip_country
             AND network_carrier_country IS NOT NULL
             AND ip_country IS NOT NULL
        THEN 1 ELSE 0
    END as country_mismatch_ind,
    COUNT(*) as login_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT device_id) as unique_devices
FROM risk.test.hding_a3id_login_info_enriched
WHERE network_carrier IS NOT NULL
    AND TRIM(network_carrier) != ''
GROUP BY 1,2,3,4,5
HAVING login_count >= 10  -- Focus on significant patterns
ORDER BY country_mismatch_ind DESC, login_count DESC;
```

## 📋 Pattern Usage Guide

### When to Use Which Pattern
- **Scenario 1:** [Recommended patterns and reasons]
- **Scenario 2:** [Recommended patterns and reasons]

### Pattern Combination Strategies
- **Complex Analysis:** [How to combine multiple patterns]
- **Performance Trade-offs:** [Performance considerations for different patterns]

---

> 📝 **Update Principle:** Add new efficient query patterns as discovered, ensuring the pattern library remains practical and advanced.
