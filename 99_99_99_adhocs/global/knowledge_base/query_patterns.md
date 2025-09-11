# Snowflake Common Query Patterns

> Global query pattern library - Reusable SQL query logic and best practices

## 📑 **Table of Contents**
- [Enterprise Case Review Patterns](#-enterprise-case-review-patterns)
  - [Comprehensive User Activity Timeline](#comprehensive-user-activity-timeline)
  - [Policy Development Feature Engineering Pattern](#policy-development-feature-engineering-pattern)
- [ML Feature Family Patterns](#-ml-feature-family-patterns)
  - [Standard Feature Family Structure](#standard-feature-family-structure)
  - [Deduplication Pattern](#deduplication-pattern)
  - [P2P Transaction Pattern](#p2p-transaction-pattern)
  - [Transaction Classification Pattern](#transaction-classification-pattern)
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

### 🏦 **Enterprise Case Review Patterns**

#### **Comprehensive User Activity Timeline**

The `case_pull_acct_history_v2.sql` pattern demonstrates enterprise-grade user activity logging with 15+ event types in a single unified timeline:

```sql
-- Standard pattern for comprehensive user activity logging
WITH user_info AS (
    SELECT DISTINCT id::VARCHAR AS user_id
    FROM CHIME.FINANCE.members
    WHERE id = 49127109
)

-- Tokenization/Provisioning Events
SELECT
    user_id,
    CONVERT_TIMEZONE('America/Los_Angeles', original_timestamp) AS timestamp,
    device_id::VARCHAR AS id,
    'token/provisioning event' AS type,
    CONCAT_WS('|',
        'Token_id: ' || IFNULL(token_id, 'n/a'),
        'Card_last_4: ' || IFNULL(card_last_4, 'n/a'),
        'Wallet_type: ' || IFNULL(wallet_type, 'n/a'),
        'Processor: ' || IFNULL(processor, 'n/a')
    ) AS description,
    risk_score::VARCHAR AS vrs,
    policy_name AS rules_denied,
    CASE WHEN disputed_transaction_id IS NOT NULL THEN 'yes' ELSE 'no' END AS is_disputed
FROM chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization
WHERE is_shadow_mode = FALSE AND user_id IN (SELECT * FROM user_info)

UNION ALL

-- Card Authorization History with Risk Context
SELECT
    rta.user_id,
    CONVERT_TIMEZONE('America/Los_Angeles', rta.trans_ts) AS timestamp,
    rta.auth_id::VARCHAR AS id,
    rta.auth_event_merchant_name_raw AS merchant_name,
    CASE
        WHEN rta.MCC_CD IN ('6010', '6011') THEN 'Withdrawal'
        WHEN rta.mti_cd IN ('0400', '0420') THEN 'Mrch_Credit'
        ELSE 'Purchase'
    END AS type,
    -- Rich transaction context
    CONCAT(
        'Card Transaction: ', rta.entry_type,
        '; MCC_CD: ', rta.mcc_cd,
        '; Avail_Fund: ', rta.available_funds,
        '; Pin Code: ', rta.pin_result_cd,
        '; cashback: ', rta.cashback_amt,
        '; Eci: ', CASE
            WHEN rta.ecommerce LIKE '%05%' THEN '05'
            WHEN rta.ecommerce LIKE '%03%' THEN '03'
            WHEN rta.ecommerce LIKE '%07%' THEN '07'
            ELSE 'n/a'
        END,
        '; Token_id: ', COALESCE(auth_token_id.token_id::VARCHAR, 'n/a')
    ) AS description,
    CASE WHEN rta.response_cd IN ('00', '10') THEN 'Approved' ELSE 'Declined' END AS decision,
    rta.risk_score::VARCHAR AS vrs,
    -- Complex rule evaluation logic
    CASE
        WHEN rta.response_cd IN ('59') THEN
            rta2.policy_name || ' -' || (
                CASE
                    WHEN o.decision_id IS NULL THEN rta2.decision_outcome
                    WHEN o.is_suppressed = TRUE THEN 'suppressed'
                    WHEN o.response_signal IS NULL THEN 'no response'
                    ELSE o.response_signal
                END
            )
        WHEN rta.response_cd IN ('00', '10') THEN
            rta2.policy_name || ' -' || rta2.decision_outcome
        ELSE 'n/a'
    END AS rules_denied,
    CASE WHEN d.authorization_code IS NOT NULL THEN 'yes' ELSE 'no' END AS is_disputed
FROM edw_db.core.fct_realtime_auth_event rta
LEFT JOIN risk.prod.disputed_transactions d
    ON (d.authorization_code = rta.auth_id AND d.user_id = rta.user_id)
LEFT JOIN chime.decision_platform.card_auth_events rta2
    ON (rta.user_id = rta2.user_id AND rta.auth_id = rta2.auth_id
        AND rta2.is_shadow_mode = 'false' AND policy_result = 'criteria_met')
LEFT JOIN chime.decision_platform.fraud_override_service o
    ON (rta.user_id = o.user_id AND rta.auth_id = o.realtime_auth_id)
WHERE rta.user_id IN (SELECT * FROM user_info)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY rta.user_id, rta.auth_event_id
    ORDER BY o.response_received_at
) = 1

-- Additional UNION ALL sections for:
-- - Login events (success/failed) with ATOM scores
-- - Dispute filing events with intake channel classification
-- - PII change events (phone/email updates)
-- - App interaction events
-- - Card replacement events
-- - Biometric session events
-- - PIN change events
-- - Virtual card view events

ORDER BY timestamp;
```

**Key Pattern Elements:**
- **Unified Timeline**: 15+ event types in single query using UNION ALL
- **Rich Context**: CONCAT_WS for structured descriptions with business logic
- **Risk Integration**: ML scores (ATOM v2/v3, Prism alerts), policy decisions
- **Time Standardization**: CONVERT_TIMEZONE for consistent timestamps
- **Deduplication**: ROW_NUMBER() QUALIFY for handling multiple matches
- **Business Logic**: Complex CASE statements for transaction categorization

#### **Policy Development Feature Engineering Pattern**

Advanced feature engineering for fraud detection policies using time-windowed aggregations:

```sql
-- Multi-window feature engineering pattern
WITH base_transactions AS (
    SELECT
        auth_id,
        user_id,
        auth_event_created_ts AS snapshot_timestamp,
        req_amt,
        final_amt,
        risk_score,
        entry_type,
        mcc_cd,
        merchant_state,
        dispute_unauth_ind
    FROM risk.test.contactless_driver_base
    WHERE entry_type LIKE '%Contactless%'
      AND response_cd IN ('00', '10')
      AND req_amt < 0
),

-- Multi-timeframe usage analysis
usage_features AS (
    SELECT
        a.auth_id,
        -- 7-day window
        COUNT(DISTINCT device_id) AS nunique__device_ids_p7d,
        COUNT(DISTINCT ip) AS nunique__ips_p7d,
        COUNT(DISTINCT network_carrier) AS nunique__network_carriers_p7d,
        COUNT(DISTINCT timezone) AS nunique__timezones_p7d,

        -- International carrier detection
        COUNT(DISTINCT CASE
            WHEN LOWER(network_carrier) NOT IN (
                't-mobile', 'at&t', 'verizon', 'sprint'
            ) THEN network_carrier
        END) AS nunique__intnl_network_carrier_p7d,

        -- 2-hour window (recent activity)
        COUNT(DISTINCT CASE
            WHEN b.session_timestamp >= DATEADD(hour, -2, a.snapshot_timestamp)
            THEN device_id
        END) AS nunique__device_ids_p2h,
        COUNT(DISTINCT CASE
            WHEN b.session_timestamp >= DATEADD(hour, -2, a.snapshot_timestamp)
            THEN network_carrier
        END) AS nunique__network_carriers_p2h
    FROM base_transactions a
    LEFT JOIN edw_db.feature_store.atom_app_events_v2 b
        ON (a.user_id = b.user_id
            AND b.session_timestamp BETWEEN DATEADD(day, -7, a.snapshot_timestamp)
                                         AND a.snapshot_timestamp)
    GROUP BY a.auth_id
),

-- ATOM score aggregation
atom_features AS (
    SELECT
        a.auth_id,
        MAX(CASE
            WHEN b.session_timestamp >= DATEADD(day, -1, a.snapshot_timestamp)
            THEN score
        END) AS max_atom_score_p1d,
        MAX(CASE
            WHEN b.session_timestamp >= DATEADD(hour, -2, a.snapshot_timestamp)
            THEN score
        END) AS max_atom_score_p2h
    FROM base_transactions a
    LEFT JOIN ml.model_inference.ato_login_alerts b
        ON (a.user_id = b.user_id
            AND b.session_timestamp BETWEEN DATEADD(day, -30, a.snapshot_timestamp)
                                         AND a.snapshot_timestamp
            AND score <> 0)
    GROUP BY a.auth_id
),

-- PII change tracking
pii_features AS (
    SELECT
        a.auth_id,
        COUNT(DISTINCT CASE
            WHEN b.event_ts >= DATEADD(day, -7, a.snapshot_timestamp)
                 AND event = 'phone_update'
            THEN event_ts
        END) AS count__phone_change_p7d,
        COUNT(DISTINCT CASE
            WHEN b.event_ts >= DATEADD(day, -7, a.snapshot_timestamp)
                 AND event = 'email_update'
            THEN event_ts
        END) AS count__email_change_p7d
    FROM base_transactions a
    LEFT JOIN segment.chime_prod.pii_updates b
        ON (a.user_id = b.user_id
            AND b.event_ts BETWEEN DATEADD(day, -30, a.snapshot_timestamp)
                               AND a.snapshot_timestamp)
    GROUP BY a.auth_id
)

-- Policy rule evaluation
SELECT
    CASE
        WHEN count__phone_change_p7d = 0
             AND req_amt <= -50
             AND max_atom_score_p1d >= 0.35
             AND nunique__device_ids_p2h >= 2
        THEN 'Policy 1: High ATOM + Multi Device'

        WHEN count__phone_change_p7d > 0
             AND req_amt <= -200
             AND max_atom_score_p1d >= 0.4
             AND (nunique__timezones_p2h >= 2
                  OR nunique__network_carriers_p2h >= 2
                  OR nunique__intnl_network_carrier_p7d >= 1)
        THEN 'Policy 2: PII Change + Geography Anomaly'

        ELSE 'No Policy Triggered'
    END AS policy_decision,

    COUNT(*) AS cnt_txn,
    AVG(dispute_unauth_ind) AS dispute_unauth_rate,
    SUM(final_amt) AS sum_txn
FROM base_transactions a
LEFT JOIN usage_features u ON (a.auth_id = u.auth_id)
LEFT JOIN atom_features atom ON (a.auth_id = atom.auth_id)
LEFT JOIN pii_features pii ON (a.auth_id = pii.auth_id)
GROUP BY policy_decision
ORDER BY dispute_unauth_rate DESC;
```

**Key Pattern Elements:**
- **Multi-Window Analysis**: p1d, p2d, p7d, p30d lookback windows
- **Feature Engineering**: Complex aggregations with conditional logic
- **ML Integration**: ATOM scores, risk models, behavioral analytics
- **Policy Simulation**: Rule-based classification with business logic
- **Performance Optimization**: Efficient CTEs with targeted JOINs

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

**Optimized Production Pattern** (Recommended):
```sql
-- Calculate dollar-wise unauthorized dispute rate with simplified logic
WITH enrolled_users AS (
    SELECT user_id, enrollment_initiated_ts
    FROM edw_db.core.member_details
    WHERE DATE(enrollment_initiated_ts) = '2025-01-01'
    LIMIT 100
),

card_not_present_txns AS (
    SELECT t.user_id, t.transaction_id, t.settled_amt, t.authorization_code
    FROM edw_db.core.ftr_transaction t
    JOIN enrolled_users eu ON t.user_id = eu.user_id
    WHERE t.processor = 'galileo'
        AND t.transaction_timestamp >= '2025-01-01'
        AND t.transaction_timestamp < '2025-04-01'
        AND t.entry_type = 'Card Not Present'
),

dispute_data AS (
    SELECT dt.user_id, dt.authorization_code, dt.dispute_created_at, dt.reason
    FROM risk.prod.disputed_transactions dt
    JOIN enrolled_users eu ON dt.user_id = eu.user_id
    WHERE dt.dispute_created_at >= '2025-01-01'
        AND dt.reason ILIKE 'unauth%'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY dt.user_id, dt.authorization_code
        ORDER BY dt.dispute_created_at DESC
    ) = 1  -- Simplified deduplication
)

-- Single aggregation with NULLIFZERO for clean calculation
SELECT
    sum(case when dd.user_id is not null then cnt.settled_amt*-1 else 0 end) /
    nullifzero(sum(cnt.settled_amt*-1)) as rate_dispute
FROM enrolled_users eu
LEFT JOIN card_not_present_txns cnt ON eu.user_id = cnt.user_id
LEFT JOIN dispute_data dd ON eu.user_id = dd.user_id
    AND cnt.authorization_code = dd.authorization_code;
```

**Key Optimization Principles:**
- **Simplified Deduplication**: Use `authorization_code` instead of complex `unique_transaction_id` matching
- **Single Aggregation**: Calculate dispute rate in one step instead of multiple CTEs
- **Amount Normalization**: Use `*-1` to convert negative settled amounts to positive
- **NULLIFZERO()**: Prevent division by zero errors elegantly
- **Direct Joins**: Link via `authorization_code` for reliable transaction-dispute matching

**Legacy Pattern** (for reference):
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

## 🏭 **Chime Production SQL Patterns**

### **Production Task Structure Patterns**

#### **CREATE OR REPLACE TABLE Pattern**
```sql
-- Standard pattern for scheduled data refreshes
CREATE OR REPLACE TABLE analytics.test.table_name AS
WITH base_data AS (
    SELECT
        user_id,
        transaction_timestamp,
        amount,
        -- Business logic calculations
        CASE WHEN condition THEN 'value' ELSE 'other' END AS status_flag
    FROM source_table
    WHERE date_filter >= CURRENT_DATE - INTERVAL '30 days'
),
final_metrics AS (
    SELECT
        user_id,
        SUM(amount) AS total_amount,
        COUNT(*) AS transaction_count,
        CURRENT_TIMESTAMP() AS updated_at
    FROM base_data
    GROUP BY user_id
)
SELECT * FROM final_metrics;
```

#### **INSERT OVERWRITE Pattern**
```sql
-- Pattern for incremental table updates
INSERT OVERWRITE INTO analytics.test.target_table
SELECT
    column1,
    column2,
    -- Only new/changed records
    CURRENT_DATE AS processing_date
FROM source_table
WHERE last_modified >= CURRENT_DATE;
```

#### **TRANSIENT TABLE Pattern**
```sql
-- Pattern for temporary analytical tables
CREATE OR REPLACE TRANSIENT TABLE analytics.test.temp_analysis AS
SELECT
    analysis_columns,
    intermediate_calculations
FROM complex_joins
WHERE analysis_conditions;
```

### **Advanced SQL Patterns from Production**

#### **Time Window Analysis Pattern**
```sql
-- Standard time-based analysis with multiple windows
WITH time_windows AS (
    SELECT
        user_id,
        event_timestamp,
        -- Multiple time calculations
        DATE_TRUNC('day', event_timestamp) AS day_key,
        DATE_TRUNC('month', event_timestamp) AS month_key,
        DATEDIFF('day', first_event_date, event_timestamp) AS days_since_first,
        DATEADD('day', 30, event_timestamp) AS window_end_date
    FROM events_table
),
windowed_metrics AS (
    SELECT
        user_id,
        day_key,
        -- Window functions for velocity tracking
        COUNT(*) OVER (
            PARTITION BY user_id
            ORDER BY event_timestamp
            RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
        ) AS rolling_7d_count,
        LAG(event_timestamp, 1) OVER (
            PARTITION BY user_id
            ORDER BY event_timestamp
        ) AS prev_event_timestamp
    FROM time_windows
)
SELECT * FROM windowed_metrics;
```

#### **Risk Scoring Pattern**
```sql
-- Production risk assessment pattern
WITH risk_signals AS (
    SELECT
        user_id,
        -- Risk indicators with safe division
        DIV0(dispute_count, total_transactions) AS dispute_rate,
        -- Complex conditional logic
        IFF(velocity_score > 0.8, 'HIGH_RISK',
            IFF(velocity_score > 0.5, 'MEDIUM_RISK', 'LOW_RISK')) AS risk_tier,
        -- Boolean flags for decision logic
        CASE
            WHEN account_age_days < 30 AND transaction_amount > 1000 THEN 1
            WHEN device_fingerprint IN (SELECT device_id FROM bad_devices) THEN 1
            ELSE 0
        END AS synthetic_flag
    FROM user_metrics
),
final_scoring AS (
    SELECT
        user_id,
        risk_tier,
        -- Composite risk score
        (dispute_rate * 0.4 + velocity_score * 0.3 + synthetic_flag * 0.3) AS composite_score,
        -- Decision logic
        CASE
            WHEN composite_score > 0.7 THEN 'BLOCK'
            WHEN composite_score > 0.4 THEN 'REVIEW'
            ELSE 'APPROVE'
        END AS decision
    FROM risk_signals
)
SELECT * FROM final_scoring;
```

#### **Funnel Analysis Pattern**
```sql
-- Multi-step conversion funnel analysis
WITH funnel_steps AS (
    SELECT
        user_id,
        enrollment_date,
        -- Step completion flags
        MAX(CASE WHEN step = 'phone_verify' THEN 1 ELSE 0 END) AS phone_completed,
        MAX(CASE WHEN step = 'kyc_pass' THEN 1 ELSE 0 END) AS kyc_completed,
        MAX(CASE WHEN step = 'first_deposit' THEN 1 ELSE 0 END) AS deposit_completed,
        -- Time to completion tracking
        MIN(CASE WHEN step = 'phone_verify' THEN step_timestamp END) AS phone_completion_time,
        MIN(CASE WHEN step = 'kyc_pass' THEN step_timestamp END) AS kyc_completion_time
    FROM user_journey_events
    GROUP BY user_id, enrollment_date
),
funnel_metrics AS (
    SELECT
        enrollment_date,
        COUNT(*) AS total_users,
        SUM(phone_completed) AS phone_completions,
        SUM(kyc_completed) AS kyc_completions,
        SUM(deposit_completed) AS deposit_completions,
        -- Conversion rates
        DIV0(SUM(phone_completed), COUNT(*)) AS phone_conversion_rate,
        DIV0(SUM(kyc_completed), SUM(phone_completed)) AS kyc_conversion_rate,
        -- Time to convert metrics
        AVG(DATEDIFF('hour', enrollment_date, phone_completion_time)) AS avg_hours_to_phone
    FROM funnel_steps
    GROUP BY enrollment_date
)
SELECT * FROM funnel_metrics;
```

#### **Cohort Analysis Pattern**
```sql
-- User cohort retention analysis
WITH user_cohorts AS (
    SELECT
        user_id,
        DATE_TRUNC('month', enrollment_date) AS cohort_month,
        enrollment_date
    FROM users
),
activity_periods AS (
    SELECT
        user_id,
        DATE_TRUNC('month', activity_date) AS activity_month
    FROM user_activities
),
cohort_activity AS (
    SELECT
        uc.cohort_month,
        uc.user_id,
        ap.activity_month,
        DATEDIFF('month', uc.cohort_month, ap.activity_month) AS months_since_enrollment
    FROM user_cohorts uc
    LEFT JOIN activity_periods ap ON uc.user_id = ap.user_id
),
cohort_retention AS (
    SELECT
        cohort_month,
        months_since_enrollment,
        COUNT(DISTINCT user_id) AS active_users,
        -- Retention rate calculation
        DIV0(COUNT(DISTINCT user_id),
             FIRST_VALUE(COUNT(DISTINCT user_id)) OVER (
                 PARTITION BY cohort_month
                 ORDER BY months_since_enrollment
             )) AS retention_rate
    FROM cohort_activity
    WHERE activity_month IS NOT NULL
    GROUP BY cohort_month, months_since_enrollment
)
SELECT * FROM cohort_retention;
```

#### **Duplicate Detection Pattern**
```sql
-- Complex duplicate user detection with graph traversal
WITH duplicate_links AS (
    SELECT
        a.user_id AS user_a,
        b.user_id AS user_b,
        -- Multiple matching criteria
        CASE
            WHEN a.ssn_hash = b.ssn_hash THEN 'SSN_MATCH'
            WHEN a.phone_hash = b.phone_hash THEN 'PHONE_MATCH'
            WHEN a.device_id = b.device_id THEN 'DEVICE_MATCH'
            WHEN a.address_hash = b.address_hash THEN 'ADDRESS_MATCH'
        END AS link_type
    FROM users a
    JOIN users b ON a.user_id < b.user_id  -- Avoid self-joins and duplicates
    WHERE (
        a.ssn_hash = b.ssn_hash OR
        a.phone_hash = b.phone_hash OR
        a.device_id = b.device_id OR
        a.address_hash = b.address_hash
    )
),
duplicate_graphs AS (
    SELECT
        user_a,
        user_b,
        link_type,
        -- Graph traversal for connected components
        ROW_NUMBER() OVER (ORDER BY user_a, user_b) AS edge_id
    FROM duplicate_links
),
connected_users AS (
    -- Recursive CTE for finding all connected users
    WITH RECURSIVE user_connections AS (
        SELECT user_a AS user_id, user_a AS root_user, 1 AS depth
        FROM duplicate_graphs
        UNION ALL
        SELECT dg.user_b, uc.root_user, uc.depth + 1
        FROM duplicate_graphs dg
        JOIN user_connections uc ON dg.user_a = uc.user_id
        WHERE uc.depth < 10  -- Prevent infinite recursion
    )
    SELECT user_id, root_user FROM user_connections
)
SELECT * FROM connected_users;
```

#### **JSON Parsing Pattern**
```sql
-- Complex JSON parsing for external API responses
WITH parsed_responses AS (
    SELECT
        user_id,
        vendor_response,
        -- Extract nested JSON values
        vendor_response:kyc:fieldValidations:state::FLOAT AS state_score,
        vendor_response:kyc:fieldValidations:zip::FLOAT AS zip_score,
        vendor_response:alertList:matches[0]:datasetName::STRING AS dataset_name_1,
        vendor_response:alertList:matches[1]:datasetName::STRING AS dataset_name_2,
        -- Array parsing with error handling
        TRY_PARSE_JSON(vendor_response:riskIndicators)::ARRAY AS risk_indicators_array
    FROM kyc_vendor_inquiries
),
risk_indicator_flags AS (
    SELECT
        user_id,
        -- Check for specific risk codes in array
        CASE WHEN ARRAY_CONTAINS('R111'::VARIANT, risk_indicators_array) THEN 1 ELSE 0 END AS r111_flag,
        CASE WHEN ARRAY_CONTAINS('I911'::VARIANT, risk_indicators_array) THEN 1 ELSE 0 END AS i911_flag,
        -- State/ZIP validation
        CASE WHEN state_score = 0.01 AND zip_score = 0.01 THEN 1 ELSE 0 END AS state_zip_mismatch
    FROM parsed_responses
)
SELECT * FROM risk_indicator_flags;
```

### **Performance Optimization Patterns**

#### **QUALIFY for Window Function Filtering**
```sql
-- Use QUALIFY instead of subqueries for better performance
SELECT
    user_id,
    transaction_timestamp,
    amount,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY transaction_timestamp DESC) AS rn
FROM transactions
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY transaction_timestamp DESC) = 1;
```

#### **Early Filtering Pattern**
```sql
-- Push filters down early in CTEs
WITH filtered_base AS (
    SELECT *
    FROM large_table
    WHERE date_column >= CURRENT_DATE - 30  -- Filter early
      AND status = 'active'
      AND amount > 0
),
processed_data AS (
    SELECT
        user_id,
        SUM(amount) AS total_amount
    FROM filtered_base  -- Work with smaller dataset
    GROUP BY user_id
)
SELECT * FROM processed_data;
```

## 🤖 ML Feature Family Patterns

### Standard Feature Family Structure
```sql
-- Template for all feature families
WITH source_[table_name]__with_window AS (
    SELECT
        entity_id,                              -- Primary entity (user_id, device_id, etc.)
        event_timestamp::TIMESTAMP_LTZ,         -- Event time
        CURRENT_TIMESTAMP() AS snapshot_timestamp, -- Snapshot time
        -- Additional fields for feature calculation
    FROM source_table
    WHERE filtering_conditions
),

tr_feature_family AS (
    SELECT
        entity_id,
        snapshot_timestamp,
        MAX(event_timestamp) AS last__event_timestamp,
        -- Aggregated features with standard naming
        COUNT(DISTINCT field) AS count__field_name,
        SUM(amount) AS sum__amount_field,
        AVG(amount) AS avg__amount_field,
        MIN(event_timestamp) AS first__timestamp_field,
        MAX(event_timestamp) AS last__timestamp_field,
        -- Static features
        ANY_VALUE(static_field) AS na__static_field,
        -- Boolean indicators
        IFF(condition, TRUE, FALSE) AS is__condition_name
    FROM source_[table_name]__with_window
    GROUP BY entity_id, snapshot_timestamp
)
SELECT * FROM tr_feature_family;
```

### Deduplication Pattern
```sql
-- Standard deduplication for latest record per entity
SELECT
    entity_id,
    latest_value,
    event_timestamp AS last__event_timestamp
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY entity_id, snapshot_timestamp
                             ORDER BY event_timestamp DESC) AS row_number
    FROM source_table
)
WHERE row_number = 1;
```

### P2P Transaction Pattern
```sql
-- P2P sends with member-to-member vs member-to-guest distinction
WITH p2p_data AS (
    SELECT
        sender_id AS user_id,
        receiver_id,
        receiver_identifier as guest_id,
        type_code,  -- 'to_member' or 'to_nonmember'
        status,     -- 'succeeded', 'declined', etc.
        amount,
        CASE WHEN last_error ilike '%sender_insufficient_funds%' THEN 1 ELSE 0 END AS nsf_error
    FROM postgres_db.p2p_service.pay_friends
    WHERE type_code IN ('to_member', 'to_nonmember')
)
SELECT
    user_id,
    -- M2M (member-to-member) features
    COUNT(DISTINCT CASE WHEN type_code = 'to_member' THEN receiver_id END) AS count__m2m_recipients,
    SUM(CASE WHEN type_code = 'to_member' THEN amount ELSE 0 END) AS sum__m2m_sent_amt,
    -- M2G (member-to-guest) features
    COUNT(DISTINCT CASE WHEN type_code = 'to_nonmember' THEN guest_id END) AS count__m2g_recipients,
    SUM(CASE WHEN type_code = 'to_nonmember' THEN amount ELSE 0 END) AS sum__m2g_sent_amt
FROM p2p_data
GROUP BY user_id;
```

### Transaction Classification Pattern
```sql
-- Visa transaction code classification
SELECT
    user_id,
    transaction_id,
    CASE
        WHEN transaction_cd IN ('VSW','MPW','MPM','MPR','PLW','PLR','PRW','SDW')
        THEN 'ATM_WITHDRAWAL'
        WHEN transaction_cd IN ('ISA','ISC','ISJ','ISL','ISM','ISR','ISZ','VSA',
                               'VSC','VSJ','VSL','VSM','VSR','VSZ','SDA','SDC',
                               'SDL','SDM','SDR','SDV','SDZ','PLM','PLA','PRA')
        THEN 'PURCHASE'
        ELSE 'OTHER'
    END AS transaction_type,
    settled_amt * -1 as amount  -- Convert to positive for spend
FROM edw_db.core.fct_settled_transaction
WHERE settled_amt < 0;  -- Negative amounts are debits/spends
```

## 📋 Pattern Usage Guide

### When to Use Which Pattern
- **Feature Engineering:** Use ML Feature Family patterns for creating reusable, standardized features
- **Data Deduplication:** Use ROW_NUMBER() pattern when you need latest record per entity
- **P2P Analysis:** Use P2P pattern to distinguish between member-to-member vs member-to-guest transactions
- **Transaction Analysis:** Use transaction classification for spend behavior analysis

### Pattern Combination Strategies
- **Complex Feature Engineering:** Combine multiple feature family patterns for comprehensive user profiling
- **Performance Trade-offs:** Use appropriate filtering and indexing for large-scale feature computation

---

> 📝 **Update Principle:** Add new efficient query patterns as discovered, ensuring the pattern library remains practical and advanced.
