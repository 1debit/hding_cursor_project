# Business Logic & Data Definitions

> Authoritative definitions for core business concepts and calculation logic

## 📑 **Table of Contents**
- [Chime Production Business Logic](#-chime-production-business-logic)
  - [Account Lifecycle Management](#account-lifecycle-management)
  - [Risk & Fraud Detection Logic](#risk--fraud-detection-logic)
  - [Transaction Classification](#transaction-classification)
  - [KYC & Identity Verification](#kyc--identity-verification)
  - [User Engagement & Growth Metrics](#user-engagement--growth-metrics)
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

## 🏭 **Chime Production Business Logic**

### **📋 Comprehensive Dispute Processing Architecture**

#### **Core Dispute Data Sources:**
- **Legacy System**: `fivetran.mysql_rds_disputes.*` (user_dispute_claims, user_dispute_claim_transactions)
- **Inspector Integration**: `fivetran.inspector_public.*` (claims, disputes, transactions, source_transactions, users)
- **Admin Comments**: `postgres_db.penny.notes` (admin adjustment comments with regex parsing)
- **Alert Transactions**: `mysql_db.chime_prod.alert_transaction_events` (dispute credit processing)

#### **Dispute Processing Workflow:**
1. **Dispute Creation**: Users file disputes through legacy system or Inspector
2. **Transaction Linking**: Authorization code matching across multiple systems
3. **Adjustment Processing**: Multiple adjustment types (PVC, PVCR, Final, Chargebacks)
4. **Resolution Tracking**: Resolution codes, decisions, and timestamps
5. **Serial Disputer Detection**: Pattern analysis for repeat offenders

#### **Key Dispute Views:**
- **`disputed_transactions_view.sql`** (241 lines): Master dispute view combining legacy + Inspector data
- **`serial_disputer_view.sql`** (196 lines): Serial disputer detection with risk scoring
- **`adjustments_alert_txns_view.sql`** (120 lines): Alert transaction adjustments
- **`adjustments_inspector_view.sql`** (164 lines): Inspector adjustment processing
- **`adjustments_admin_comments_view.sql`** (133 lines): Admin comment parsing for adjustments

#### **Dispute Resolution Codes:**
- **'300'**: Approved dispute
- **'301'**: Denied dispute
- **'302'**: Pending resolution
- **'321'**: Force post
- **'approve'**: Inspector approval

#### **Adjustment Types (Transaction Codes):**
- **ADtc**: Provisional Credit (TC)
- **ADfd**: Final Dispute (FD)
- **ADh/ADH**: Chargeback (Visa/Mastercard)
- **ADdh**: Debit Hold
- **ADj**: Adjustment
- **ADk**: Key adjustment
- **ADse**: Special Event
- **ADsc**: Special Case
- **ADbc**: ACH Credit (BC)
- **ADcn**: ACH Credit (CN)

#### **Serial Disputer Detection Logic:**
- **SD Flag**: `num_denied_claims_last_90d >= 2 AND num_disputes_last_90d >= 5`
- **UI Risk Flag**: Multi-state transactions with high frequency
- **Dispute vs Deposit Ratio**: Disputes > 50% of deposits in last 30 days
- **Force Post Tracking**: Number of force-posted disputes

#### **Transaction Linking Patterns:**
- **Authorization Code Matching**: Primary linking method
- **UTM ID Matching**: Secondary linking for Inspector disputes
- **Transaction ID Truncation**: Right-side truncation for legacy matching
- **Multiple Auth Codes**: Support for auth_code1 through auth_code5

#### **Admin Comment Parsing:**
- **Regex Extraction**: `regexp_replace(trim(comment_parts.value), '[^0-9]+', ' ')`
- **Type Classification**: Parse `type=tc`, `type=fd`, `type=h`, etc.
- **Amount Extraction**: `try_to_double(value)` for adjustment amounts
- **Comment Splitting**: Lateral flatten for multiple comments per record

### **📋 Data Repository Analysis Summary**

**Files Analyzed from `cloned/data_repo/database/snowflake/`:**

#### **Risk.Prod DDL Views (5 files read from 46 total):**
1. **`disputed_transactions.sql`** (197 lines)
   - **Learned**: Complex dispute processing with legacy_claim_id CTE, Inspector integration via fivetran.inspector_public.*, resolution codes ('300','301','302','321','approve')

2. **`all_disputable_transactions_summary_monthly.sql`** (114 lines)
   - **Learned**: Transaction classification logic (ISA/VSA/SDA for purchases, VSW/MPW/SDW for ATM, ADPF for Pay Anyone), seasoning windows (7d-180d)

3. **`suspected_ato_transactions_view.sql`** (443 lines)
   - **Learned**: Comprehensive ATO detection with Castle success events, device scoring ≤0.5, 24/48/72hr time windows, disposition taxonomy

4. **`all_disputable_transactions_summary_weekly.sql`** (115 lines)
   - **Learned**: Weekly aggregation version with identical transaction classification and seasoning logic

5. **`dispute_credits_view.sql`** (105 lines)
   - **Learned**: Dispute credit processing from alert_transaction_events, regex parsing, otype categories ('tc','fd')

#### **ML.Fraud DDL Views (1 file read from 16 total):**
6. **`dispute_model_v_16_manual_review_decisions.sql`** (5 lines)
   - **Learned**: Simple manual review decision tracking from Google Sheets integration

#### **Analytics.Looker DDL Views (1 file read from 90 total):**
7. **`dispute_credits_view.sql`** (105 lines)
   - **Learned**: Alert transaction event processing with regex-based transaction ID extraction

#### **Analytics.Looker DDL Views (3 files read from 90 total):**
8. **`ach_details.sql`** (35 lines)
   - **Learned**: ACH transaction parsing with substring operations, transaction codes ('PMDK','PMDD','PMCN'), Galileo processor filtering

9. **`compliance_reporting_view.sql`** (361 lines)
   - **Learned**: Complex compliance workflow tracking with SLA calculations, working days/hours computation, multi-step approval processes, Bancorp/Stride level reviews

10. **`dispute_credits_view.sql`** (105 lines) - *Already counted above*

#### **ML.Fraud DDL Views (2 additional files read from 16 total):**
11. **`nik_labels_n01.sql`** (24 lines)
    - **Learned**: ML training data creation with 'bad' users (dispute velocity) vs 'good' users (payroll DD), hash-based sampling, dispute reason filtering

12. **`nik_third_party_fraud_n01.sql`** (35 lines)
    - **Learned**: Third-party fraud labeling with synthetic account detection, ID theft patterns, altered documents, enrollment date filtering, email domain exclusions

#### **Chime.Finance DDL Views (5 files read from 66 total):**
13. **`account_balance_by_bank_view.sql`** (170 lines)
    - **Learned**: Complex balance aggregation by bank (Bancorp vs Stride) and account type (checking/savings/SDA/SCA), streaming platform integration with SpotMe line of credit, JSON parsing for balance units/nanos

14. **`acquisition_spend_aggregates_view.sql`** (22 lines)
    - **Learned**: Marketing spend aggregation by campaign, publisher, traffic source, enrollment channel with CPE (Cost Per Enrollment) metrics

15. **`auto_savings_transactions_view.sql`** (77 lines)
    - **Learned**: Auto-savings transaction classification (SWIP, round-up, round-up bonus, savings transfer/withdrawal), 10% payroll deduction logic, first funding amount tracking

16. **`cards_shipped_view.sql`** (59 lines)
    - **Learned**: Card shipping tracking with vendor identification (Fiserv vs Valid), enrollment date calculation, shipping-to-enrollment time gaps, card numbering sequence

17. **`checkbook_checks_view.sql`** (20 lines)
    - **Learned**: Bill payment system integration with user billers, account number hashing for security, address and payment status tracking

**Total: 17 files read from 430+ SQL files (4.0% coverage)**

### **Financial Business Logic Patterns**

#### **Bank Partnership Architecture**
- **Bancorp Bank**: Primary banking partner for account services
- **Stride Bank**: Secondary banking partner for account services
- **Account Types**: checking, savings, security_deposit (SDA), secured_credit (SCA)
- **Balance Tracking**: Current balance vs available balance by bank and account type

#### **Auto-Savings Features**
- **SWIP (Save When I'm Paid)**: 10% automatic deduction from payroll deposits
- **Round-Up**: Round up purchases to nearest dollar for savings
- **Round-Up Bonus**: Additional bonus on round-up transactions
- **Savings Transfer**: Manual transfers to savings account
- **Savings Withdrawal**: Withdrawals from savings account
- **Transaction Codes**: 'PMMS' (savings transfer), 'PMRU' (round-up), 'PMRF' (round-up bonus), 'ADMS' (savings withdrawal)

#### **Card Management**
- **Vendors**: Fiserv (product_ids: 6216, 6222, 6287) vs Valid for card production
- **Card Types**: Type '3' for standard cards
- **Shipping Tracking**: Integration with Segment for card shipped events
- **Enrollment Integration**: Card shipping relative to account enrollment dates

#### **Marketing & Acquisition**
- **CPE (Cost Per Enrollment)**: Primary acquisition metric
- **Campaign Tracking**: Publisher, traffic source, enrollment channel attribution
- **Spend Aggregation**: Total spend, clicks, impressions by campaign dimensions

#### **Bill Payment System**
- **User Billers**: Biller management with account number hashing
- **Payment Processing**: User biller payments with memo and status tracking
- **Address Management**: Full address information for biller payments

### **Account Lifecycle Management**

#### **Account Status Definitions**
- **`active`** - Normal operational account
- **`suspended`** - Temporarily restricted, can be reactivated
- **`cancelled`** - Permanently closed by user request
- **`cancelled_no_refund`** - Permanently closed, no refund issued

#### **Account Deactivation Reasons**
```sql
-- Account closure categorization logic
CASE
    WHEN deactivation_reason LIKE '%synth%' OR deactivation_reason LIKE '%id_theft%'
        OR deactivation_reason IN (
            'tainted_phone_number', 'duplicate_account', 'chime_for_altered_documents',
            'chime_for_duplicate_account', 'tainted_email', 'chime_for_prohibited_kyc_flag',
            'tainted_address'
        )
    THEN 'SYNTHETIC_FRAUD'
    WHEN deactivation_reason IN (
        'member', 'chime_for_deceased_member', 'incarcerated_member',
        'suspicious_account_access', 'chime_for_duplicate_ssn',
        'bancorp_for_bankruptcy', 'third_party_bankruptcy'
    )
    THEN 'LEGITIMATE_CLOSURE'
    ELSE 'FRAUD_SUSPECTED'
END AS closure_category
```

### **Risk & Fraud Detection Logic**

#### **Dispute Resolution Codes**
- **'300', '301', '302', '321'** - Various dispute resolution outcomes
- **'approve'** - Dispute approved in favor of member
- **Chargeback flow**: Inspector → Chargeback → Resolution

#### **ML Model Scoring (0-1 scale, higher = riskier)**
- **ATOM Score** - Account Takeover Model for login risk
- **FPF Score** - First Party Fraud detection
- **SAD Score** - Synthetic Account Detection
- **PVC Score** - Payment Verification Check

### **Transaction Classification**

#### **Visa Network Transaction Codes**
- **ATM Withdrawals**: VSW, MPW, MPM
- **Purchases**: ISA, VSA, SDA
- **P2P Transactions**: ADM, ADPF, ADTS, ADTU
- **Chargebacks**: ADpb

#### **P2P Transaction Types**
- **m2m** (member-to-member) - Both sender and recipient are Chime members
- **m2g** (member-to-guest) - Chime member sends to non-member (requires debit card)

### **KYC & Identity Verification**

#### **KYC Decision Logic**
```sql
-- Socure risk code evaluation
CASE
    WHEN UPPER(raw_response) LIKE '%R111%' OR UPPER(raw_response) LIKE '%I911%'
        OR UPPER(raw_response) LIKE '%R963%' OR UPPER(raw_response) LIKE '%R972%'
        OR UPPER(raw_response) LIKE '%R973%' OR UPPER(raw_response) LIKE '%R932%'
        OR UPPER(raw_response) LIKE '%I904%' OR UPPER(raw_response) LIKE '%R913%'
    THEN 'FAIL'
    WHEN (raw_response:kyc:fieldValidations:state = 0.01
          AND raw_response:kyc:fieldValidations:zip = 0.01)
        OR UPPER(raw_response) LIKE '%I907%'
    THEN 'PASS'
    ELSE 'REFER'
END AS kyc_decision
```

#### **ECBSV (Enhanced Consumer Bank Verification Service)**
- **Explicit ECBSV** - Direct bank account verification
- **Implicit ECBSV** - Inferred from risk indicators (I998, I999, R998, R999 flags)

### **User Engagement & Growth Metrics**

#### **Direct Deposit Conversion**
```sql
-- Standard DD conversion tracking
WITH dd_timeline AS (
    SELECT
        user_id,
        enrollment_date,
        first_dd_date,
        DATEDIFF('day', enrollment_date, first_dd_date) AS days_to_dd
    FROM user_metrics
)
SELECT
    enrollment_date,
    COUNT(*) AS enrolled_users,
    COUNT(CASE WHEN days_to_dd <= 14 THEN 1 END) AS dd_14d_count,
    COUNT(CASE WHEN days_to_dd <= 30 THEN 1 END) AS dd_30d_count,
    DIV0(COUNT(CASE WHEN days_to_dd <= 14 THEN 1 END), COUNT(*)) AS dd_14d_rate,
    DIV0(COUNT(CASE WHEN days_to_dd <= 30 THEN 1 END), COUNT(*)) AS dd_30d_rate
FROM dd_timeline
GROUP BY enrollment_date;
```

#### **User Activity Classification**
```sql
-- Active user definitions
CASE
    WHEN is_l30_current_dd = TRUE THEN 'active_current_dder'
    WHEN is_l30_active_spend = TRUE THEN 'active_not_current_dder'
    ELSE 'not_active'
END AS user_activity_status
```

#### **Referral Program Logic**
- **C1** - Referring user (existing member)
- **C2** - Referred user (new member)
- **Referral funnel**: Invite sent → Enrollment → DD conversion → Activation

#### **Enrollment Channel Attribution**
- **'Referral'** - User-to-user referrals
- **'Pay Anyone'** - P2P-driven enrollment
- **'Organic'** - Direct signups
- **'Marketing'** - Paid acquisition channels

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
