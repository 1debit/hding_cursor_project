# 🔍 Knowledge Base Search Index

> **Searchable index of all tables, patterns, and concepts**

## 📊 **Table Search**

### By Schema
- **`risk.prod`**: `disputed_transactions`
- **`edw_db.core`**: `fct_realtime_auth_event`, `member_details`, `dim_card`, `ftr_transaction`, `fct_settled_transaction`
- **`edw_db.feature_store`**: `atom_user_sessions_v2`
- **`chime.decision_platform`**: `authn`, `card_auth_events`, `mobile_wallet_provisioning_and_card_tokenization`
- **`chime.finance`**: `members`
- **`segment.prod`**: `menu_button_tapped`, `login_success`
- **`streaming_platform.*`**: `realtimedecisioning_v1_risk_decision_log`, `dsml_events_predictions_segment_v2_atom_model_v3`
- **`postgres_db.p2p_service`**: `pay_friends`

### By Purpose
- **Transactions**: `fct_realtime_auth_event`, `ftr_transaction`, `fct_settled_transaction`
- **Disputes**: `disputed_transactions`
- **Users**: `member_details`, `members`, `atom_user_sessions_v2`
- **Cards**: `dim_card`, `mobile_wallet_provisioning_and_card_tokenization`
- **Risk**: `card_auth_events`, `realtimedecisioning_v1_risk_decision_log`
- **P2P**: `pay_friends`
- **Features**: `atom_user_sessions_v2`, `dsml_events_predictions_segment_v2_atom_model_v3`

### By Alias
- **`rae`**: `edw_db.core.fct_realtime_auth_event`
- **`beth table`**: `chime.decision_platform.card_auth_events`
- **`dt`**: `risk.prod.disputed_transactions`
- **`m`**: `edw_db.core.member_details`
- **`c`**: `edw_db.core.dim_card`

## 🔗 **Pattern Search**

### By Use Case
- **Dispute Analysis**: Transaction to Dispute Linking, Dispute Rate Calculation
- **Dual Auth**: Dual Auth Settlement Pattern
- **Cross-State**: Cross-State Transaction Analysis
- **User Activity**: Comprehensive User Activity Timeline
- **Policy Testing**: Risk Strategy Simulation
- **Data Quality**: Data Quality Checks, Result Validation

### By SQL Operation
- **JOINs**: Transaction to Dispute Linking, Dual Auth Settlement, Card Information Joining
- **Aggregations**: Dispute Rate Calculation, Cross-State Transaction Analysis
- **UNIONs**: Comprehensive User Activity Timeline
- **CTEs**: Risk Strategy Simulation, Transaction to Dispute Linking

## 📈 **Metric Search**

### By Category
- **Dispute Metrics**: Dispute Rate (7d), Dispute Rate (bps), Unauthorized Disputes
- **Transaction Metrics**: Cross-State Indicator, Transaction Volume, Average Transaction Size
- **User Metrics**: User Activity Count, Login Frequency, Device Changes
- **Risk Metrics**: ATOM Score, FPF Score, SEP Score, SAD Score

### By Calculation Type
- **Rates**: Dispute Rate, User Dispute Rate
- **Counts**: Transaction Count, Dispute Count, User Count
- **Sums**: Total Volume, Disputed Volume
- **Averages**: Average Transaction Size, Average Dispute Amount

## 🏷️ **Business Concept Search**

### By Domain
- **Dispute Management**: Dispute Rate Calculation, High-Risk Merchant Criteria, Unauthorized Disputes
- **Transaction Processing**: Dual Authorization, Cross-State Analysis, Merchant State Extraction
- **Risk Scoring**: ATOM, FPF, SEP, SAD models
- **Data Quality**: Merchant Name Standardization, Data Freshness Requirements
- **User Activity**: Comprehensive Activity Logging, Device Tracking, Login Analysis
- **Policy Development**: Driver Table Creation, Feature Assembly, Risk Strategy Simulation

### By Business Process
- **Fraud Detection**: Dispute Analysis, Cross-State Transactions, Risk Scoring
- **Policy Testing**: Shadow Mode, Simulation vs Production, Feature Validation
- **User Investigation**: Activity Timeline, Device Analysis, Login Patterns
- **Merchant Risk**: Dispute Rates, Transaction Patterns, Risk Assessment

## 🔍 **Field Search**

### By Table
- **`fct_realtime_auth_event`**: `user_id`, `auth_id`, `req_amt`, `final_amt`, `merchant_name`, `mcc_cd`, `card_network_cd`, `entry_type`, `original_auth_id`, `response_cd`
- **`disputed_transactions`**: `user_id`, `authorization_code`, `dispute_created_at`, `transaction_amount`, `reason`, `resolution_decision`, `dispute_type`
- **`member_details`**: `user_id`, `state_cd`, `enrollment_initiated_ts`
- **`card_auth_events`**: `user_id`, `auth_id`, `decision_id`, `policy_name`, `decision_outcome`, `policy_actions`, `is_shadow_mode`

### By Purpose
- **Identifiers**: `user_id`, `auth_id`, `device_id`, `decision_id`
- **Amounts**: `req_amt`, `final_amt`, `transaction_amount`, `settled_amt`
- **Timestamps**: `auth_event_created_ts`, `dispute_created_at`, `original_timestamp`, `session_timestamp`
- **Risk**: `risk_score`, `atom_score`, `policy_name`, `decision_outcome`
- **Location**: `state_cd`, `merchant_state`, `ip_country`, `network_carrier`

## ⚡ **Quick Actions**

### Common Queries
- **"How to link transactions to disputes?"** → Transaction to Dispute Linking Pattern
- **"What's the dispute rate formula?"** → Dispute Rate Calculation
- **"How to handle dual auths?"** → Dual Auth Settlement Pattern
- **"How to get user activity?"** → Comprehensive User Activity Timeline
- **"What's the beth table?"** → `chime.decision_platform.card_auth_events`

### Common Filters
- **"Successful transactions"** → `response_cd IN ('00','10') AND req_amt < 0 AND original_auth_id = '0'`
- **"Unauthorized disputes"** → `reason ILIKE 'unauth%'`
- **"Recent data"** → `auth_event_created_ts >= DATEADD(day, -30, CURRENT_DATE())`
- **"Non-shadow mode"** → `is_shadow_mode = false`

---

> 💡 **Search Tip:** Use Ctrl+F to search within this index for instant results!
