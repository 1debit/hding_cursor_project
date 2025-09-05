# Business Logic & Data Definitions

> Authoritative definitions for core business concepts and calculation logic

## 📑 **Table of Contents**
- [Core Business Concepts](#-core-business-concepts)
  - [Dispute Management](#dispute-management)
  - [Transaction Processing](#transaction-processing)
  - [Risk Scoring (DSML Team)](#risk-scoring-dsml-team)
  - [Data Quality Standards](#data-quality-standards)
  - [User Activity Analysis](#user-activity-analysis)
  - [Policy Development Patterns](#policy-development-patterns)
- [Core Metric Definitions](#-core-metric-definitions)
- [Business Process Logic](#-business-process-logic)
- [Calculation Standards](#-calculation-standards)
- [Special Case Handling](#-special-case-handling)
- [Validation Standards](#-validation-standards)

## 🎯 Core Business Concepts

### Dispute Management

#### Dispute Rate Calculation
- **Definition:** Percentage of transactions that result in disputes within a specified time window
- **dispute_ind_7d:** Binary indicator (0/1) for disputes filed within 7 days of transaction
- **7-day dispute rate:** Aggregate dispute_ind_7d to get rate (SUM(dispute_ind_7d) / COUNT(*))
- **Unauthorized dispute rate:** Unauthorized disputes / Total transactions (more fraud-focused)
- **Basis points:** (Disputed amount / Total volume) * 10,000
- **Business Rules:**
  - Focus on unauthorized disputes for fraud detection
  - Minimum transaction thresholds for statistical significance
  - Different time windows (7d, 30d, 180d) for different use cases

#### High-Risk Merchant Criteria
- **Small merchants:** Dispute rate ≥ 500 bps AND < 5,000 users
- **Large merchants:** Dispute rate ≥ 1,000 bps OR user dispute rate ≥ 10%
- **Emerging risk:** >$500 disputed in 30 days (excluding known low-risk large merchants)
- **Business Rules:**
  - Exclude known low-risk large merchants (>2,000 users, <500 bps, <5% user rate)
  - Update daily to catch newly emerging risky merchants

### Transaction Processing

#### Dual Authorization Pattern
- **Definition:** Two-step authorization process where original auth links to settlement
- **Business Rules:**
  - Original auth has `original_auth_id = '0'`
  - Settlement auth has `original_auth_id` pointing to original auth's `auth_id`
  - Use `settled_auth_id` for dispute linking
  - Settlement can take days to complete

#### Cross-State Transaction Analysis
- **Definition:** Transactions where user state differs from merchant state
- **User state:** From `member_details.state_cd`
- **Merchant state:** Extracted from merchant name (position varies by card network)
  - **Mastercard:** `TRIM(SUBSTR(merchant_name, 38))` - Extract from position 38
  - **Visa:** `TRIM(SUBSTR(merchant_name, 37, 2))` - Extract 2 characters from position 37
- **Cross-state indicator:** `CASE WHEN user_state <> merchant_state THEN 1 ELSE 0 END`
- **Business Rules:** Higher risk indicator for fraud detection

### Risk Scoring (DSML Team)

#### ATOM Score
- **Definition:** Authentication risk scoring model
- **Business Rules:** Trained by DSML team, used for login risk assessment
- **Usage Context:** Real-time authentication decisions

#### FPF Score (First Party Fraud)
- **Definition:** First party fraud risk scoring
- **Business Rules:** Identifies customers committing fraud against their own accounts
- **Usage Context:** Account monitoring, risk management

#### SEP Score (Second Party Fraud)
- **Definition:** Second party fraud risk scoring
- **Business Rules:** Identifies fraud involving multiple parties
- **Usage Context:** Complex fraud detection, network analysis

#### SAD Score (Synthetic Account Detection)
- **Definition:** Synthetic account detection risk scoring
- **Business Rules:** [To be documented when taught]
- **Usage Context:** [To be documented when taught]

### Data Quality Standards

#### Merchant Name Standardization
- **Definition:** Consistent formatting of merchant names across systems
- **Business Rules:**
  - Use `UPPER(merchant_name)` for standardization
  - Sometimes not standardized depending on use case
  - Assume data quality is good for most analyses
- **Usage Context:** Merchant matching, risk analysis, reporting

#### Data Freshness Requirements
- **Definition:** Maximum acceptable latency for production data
- **Business Rules:**
  - Production tables: < 1 day latency
  - Feature store: Scheduled updates (varies by feature)
  - Test tables: May have different refresh patterns
- **Usage Context:** Data validation, analysis planning, SLA monitoring

### User Activity Analysis

#### Comprehensive Activity Logging
- **Definition:** Complete timeline of user activities across all touchpoints
- **Data Sources:**
  - **Tokenization Events:** `chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization`
  - **Financial Transactions:** `edw_db.core.ftr_transaction` (P2P, deposits, transfers)
  - **Card Authorizations:** `edw_db.core.fct_realtime_auth_event`
  - **Login Events:** `edw_db.feature_store.atom_user_sessions_v2`
  - **Dispute Events:** `risk.prod.disputed_transactions`
  - **PII Changes:** `analytics.looker.versions_pivot`
  - **App Activity:** `segment.chime_prod.menu_button_tapped`
- **Business Rules:**
  - Use `UNION ALL` to combine different activity types
  - Standardize timestamp format with `CONVERT_TIMEZONE('America/Los_Angeles', timestamp)`
  - Include risk scores (ATOMv2, ATOMV3) for login events
  - Track device information and network carriers for fraud detection
- **Usage Context:** Case reviews, fraud investigation, user behavior analysis

#### Risk Strategy Simulation
- **Definition:** Framework for testing risk policies before production deployment
- **Components:**
  - **Simulation Data:** Historical transactions with feature engineering
  - **Production Data:** Shadow mode decision logs
  - **Reconciliation:** Compare simulation vs production outcomes
- **Business Rules:**
  - Use shadow mode (`labels:service_names = 'shadow'`) for testing
  - Compare feature values between simulation and production
  - Track policy trigger rates and false positive/negative rates
  - Validate feature consistency across environments
- **Usage Context:** Policy development, risk model validation, A/B testing

### Policy Development Patterns

#### Driver Table Creation
- **Definition:** Base tables for policy development with enriched features
- **Structure:**
  - Start with `edw_db.core.fct_realtime_auth_event` as base
  - Add dispute indicators and loss calculations
  - Include user demographics and account information
  - Join with card details and member information
- **Business Rules:**
  - Filter for successful auths: `response_cd IN ('00','10')`
  - Exclude dual auths: `original_auth_id = '0'`
  - Handle dispute linking via both original and settled auth IDs
  - Use `QUALIFY ROW_NUMBER()` for deduplication
- **Usage Context:** Risk policy development, feature engineering, model training

#### Feature Assembly Framework
- **Definition:** Systematic approach to adding features to driver tables
- **Process:**
  1. Create base driver table with core transaction data
  2. Add dispute indicators and loss calculations
  3. Append feature store features using standardized naming
  4. Validate feature consistency and completeness
- **Business Rules:**
  - Use consistent feature naming conventions
  - Validate feature freshness and availability
  - Handle missing features gracefully with `ZEROIFNULL()`
  - Document feature sources and calculation methods
- **Usage Context:** Model development, policy testing, feature engineering

#### Feature Naming Convention
- **Definition:** Standardized naming pattern for feature store features
- **Pattern:** `AGGREGATION_KEY__FEATURE_PURPOSE__LOOKBACK_WINDOW__VERSION___AGGREGATION_METHOD__FIELD`
- **Example:** `MERCHANT_NAME_USER_ID__DISPUTES__7D__390D__V1___COUNT__TXN`
  - `MERCHANT_NAME_USER_ID` - Aggregation key (merchant_name + user_id)
  - `DISPUTES` - Feature purpose (dispute-related features)
  - `7D__390D` - Lookback data windows (7 days to 390 days)
  - `V1` - Feature version
  - `COUNT__TXN` - Aggregation method and field (count of transactions)
- **Business Rules:**
  - Features stored in `edw_db.feature_store` schema
  - Use `ZEROIFNULL()` when joining features to handle missing values
  - Feature freshness varies by feature family and lookback window
- **Usage Context:** Feature engineering, model development, policy testing

### Data Enrichment and Mapping

#### Network Carrier Mapping Methodology
- **Definition:** Comprehensive process for mapping network carriers to countries for fraud detection
- **Superior 4-Step Workflow:**
  1. **Extract distinct carriers:** `SELECT DISTINCT network_carrier FROM table WHERE conditions`
  2. **AI Research:** Use ChatGPT-5 with specific prompt for country code research
  3. **Get comprehensive CSV:** 315+ carriers with 3-character country codes
  4. **Create enriched table:** Apply mapping to source data
- **Performance Results:**
  - **Coverage:** 68.44% (vs 30.70% manual approach) - **+37.74 percentage points improvement**
  - **Carriers:** 315 comprehensive international mappings
  - **Country Codes:** 3-character format (USA, TWN, UNK, etc.)
- **Business Rules:**
  - Always use 3-character country codes (not 2-character)
  - Leave empty values unmapped (don't default to "Unknown")
  - Use AI research for comprehensive coverage vs manual mapping
  - Apply globally to any carrier mapping project
- **Usage Context:** Emulator detection, geographic fraud analysis, device intelligence

#### Emulator Detection via Network Analysis
- **Definition:** Identifying fraudulent devices by analyzing network carrier vs IP carrier mismatches
- **Detection Method:** Network carrier country ≠ IP carrier country
- **Business Rules:**
  - Network carrier from device signals (mobile network operator)
  - IP carrier from geolocation services (IP-based detection)
  - Mismatch indicates potential device spoofing or emulator usage
  - Focus on significant patterns (≥10 logins) for statistical relevance
- **Usage Context:** TPI case studies, device fraud detection, emulator identification

## 📊 Core Metric Definitions

### User Metrics

#### [Metric Name 1]
- **Definition:** [Precise business definition]
- **Calculation Formula:** [Specific calculation method]
- **Business Meaning:** [What business condition this metric reflects]
- **Use Cases:** [When to use this metric]
- **Considerations:** [Important points for calculation and interpretation]

#### [Metric Name 2]
- **Definition:** [Precise business definition]
- **Calculation Formula:** [Specific calculation method]
- **Business Meaning:** [What business condition this metric reflects]

### Business Metrics

#### [Business Metric 1]
- **Definition:** [Precise business definition]
- **Calculation Logic:** [Detailed calculation steps]
- **Data Sources:** [Tables and fields used]
- **Update Frequency:** [Metric update time cycle]

## 🔄 Business Process Logic

### [Important Business Process 1]
1. **Trigger Conditions:** [Conditions that start the process]
2. **Key Steps:** [Important stages in the process]
3. **Result States:** [State changes after process completion]
4. **Data Impact:** [Impact on related data tables]

### [Important Business Process 2]
1. **Trigger Conditions:** [Conditions that start the process]
2. **Key Steps:** [Important stages in the process]
3. **Result States:** [State changes after process completion]

## 📋 Calculation Standards

### Time Calculation Standards
- **Timezone Handling:** [Standard methods for timezone conversion]
- **Business Day Definition:** [Standards for determining business days and holidays]
- **Time Range:** [Include/exclude rules for start and end times]

### Amount Calculation Standards
- **Currency Handling:** [Methods for handling multiple currencies]
- **Precision Requirements:** [Precision standards for amount calculations]
- **Rounding Rules:** [Standard methods for amount rounding]

## ⚠️ Special Case Handling

### Data Exception Handling
- **Missing Data:** [How to handle NULL values and missing data]
- **Outliers:** [Methods for identifying and handling anomalous data]
- **Duplicate Data:** [Strategies for handling duplicate records]

### Edge Cases
- **[Edge Case 1]:** [Specific situation and handling method]
- **[Edge Case 2]:** [Specific situation and handling method]

## 🔍 Validation Standards

### Data Consistency Validation
- **Cross-Validation:** [Consistency checks between different data sources]
- **Logic Validation:** [Correctness checks for business logic]
- **Time Consistency:** [Validation methods for time-related calculations]

### Result Reasonableness Checks
- **Magnitude Checks:** [Reasonableness assessment of result magnitudes]
- **Trend Checks:** [Reasonableness analysis of result trends]
- **Comparison Validation:** [Comparison with historical data or benchmarks]

---

> 📝 **Maintenance Notes:** When business logic changes, this document must be updated immediately to ensure all analysis projects use consistent business definitions.
