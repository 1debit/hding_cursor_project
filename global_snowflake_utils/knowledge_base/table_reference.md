# Snowflake Core Table Reference

> Global table knowledge base - Complete reference for important business tables

## 📑 **Table of Contents**
- [Database Architecture](#-database-architecture-overview)
- [Core Business Tables](#-core-business-tables)
  - [Highest Frequency Tables](#-highest-frequency-tables)
  - [Common Business Tables](#-common-business-tables)
  - [Specialized Tables](#-specialized-tables)
- [Table Relationships](#-table-relationships)
- [Usage Best Practices](#-usage-best-practices)

## 🏗️ Database Architecture Overview

### Schema Structure
- **`risk.prod`** - Production risk and fraud data
- **`edw_db.core`** - Core enterprise data warehouse tables
- **`edw_db.feature_store`** - Feature families output (feature values)
- **`chime.decision_platform`** - Decision platform and real-time data (production)
- **`chime.finance`** - Finance and member data (production)
- **`segment.prod`** - Customer segmentation data
- **`streaming_platform.*`** - Real-time streaming data
- **`risk.test`** - Test schema (risk team can create adhoc tables here)

## 📊 Core Business Tables

### ⭐⭐⭐ Highest Frequency Tables

#### Real-time Authorization Events
- **Full Name:** `edw_db.core.fct_realtime_auth_event`
- **Common Aliases:** `rae`, `real time auth table`
- **Business Purpose:** Real-time card authorization events and transaction data
- **Core Fields:**
  - `user_id` - Member identifier
  - `auth_id` - Authorization transaction ID
  - `req_amt` - Requested amount (negative for purchases)
  - `final_amt` - Final authorized amount
  - `merchant_name` - Merchant name (raw format)
  - `mcc_cd` - Merchant category code
  - `card_network_cd` - Card network (Visa, Mastercard, Star)
  - `entry_type` - Transaction entry method (Contactless, Chip, etc.)
  - `original_auth_id` - Links to settlement for dual auths
  - `response_cd` - Authorization response code
- **Key Relationships:** Links to disputes via `auth_id`, joins to cards via `pan`
- **Data Characteristics:** Real-time updates, < 1 day latency
- **Common Filters:** `response_cd IN ('00','10')`, `req_amt < 0`, `original_auth_id = '0'`

#### Disputed Transactions
- **Full Name:** `risk.prod.disputed_transactions`
- **Business Purpose:** All dispute records with resolution information
- **Core Fields:**
  - `user_id` - Member identifier
  - `authorization_code` - Links to auth event
  - `dispute_created_at` - When dispute was filed
  - `transaction_amount` - Disputed amount (negative)
  - `reason` - Dispute reason (unauth%, error allegation, etc.)
  - `resolution_decision` - Approved/denied resolution
  - `dispute_type` - Credit, debit, general
- **Key Relationships:** Links to auth events via `authorization_code`
- **Data Characteristics:** Historical data, dispute window tracking
- **Common Filters:** `dispute_type IN ('credit','debit','general')`, `reason ILIKE 'unauth%'`

#### Member Details
- **Full Name:** `edw_db.core.member_details`
- **Business Purpose:** Core member demographic and account information
- **Core Fields:**
  - `user_id` - Member identifier
  - `state_cd` - Member state
  - `enrollment_initiated_ts` - When member started enrollment
- **Key Relationships:** Primary member dimension table
- **Data Characteristics:** Stable reference data

#### Finance Members
- **Full Name:** `chime.finance.members`
- **Business Purpose:** Primary user information table with user status
- **Core Fields:**
  - `id` - Member identifier (PRIMARY KEY, stored as integer, needs `::varchar` cast for joining)
  - `status` - User account status ('active', 'cancelled', 'needs_enrollment', 'failed_id', 'cancelled_no_refund', etc.)
  - Other user profile information
- **Key Relationships:** Primary user reference table
- **Data Characteristics:** No deduplication needed (id is primary key)
- **Important Notes:**
  - Use `WHERE status = 'active'` to filter for active users
  - **CRITICAL:** Join using `a.user_id = m.id::varchar` (cast id to varchar for joining)
  - The `id` field is stored as integer but needs varchar casting when joining with other tables that have `user_id` as varchar

### ⭐⭐ Common Business Tables

#### Card Information
- **Full Name:** `edw_db.core.dim_card`
- **Business Purpose:** Card details and metadata
- **Core Fields:**
  - `user_id` - Member identifier
  - `card_number` - Card number (use last 4 digits for joining)
  - `card_type` - debit_checking, secured_credit
  - `is_virtual` - Virtual card indicator
  - `activated_dt` - Card activation date
- **Important Notes:** Join using `RIGHT(pan, 4) = RIGHT(card_number, 4)`

#### Financial Transactions
- **Full Name:** `edw_db.core.ftr_transaction`
- **Business Purpose:** All financial transactions (P2P, deposits, transfers, fees)
- **Core Fields:**
  - `user_id` - Member identifier
  - `transaction_id` - Unique transaction identifier
  - `authorization_code` - Links to auth events
  - `transaction_timestamp` - When transaction occurred
  - `settled_amt` - Final settled amount
  - `transaction_cd` - Transaction type code (PMAP, ADER, ADFA, etc.)
  - `type` - Transaction category (Deposit, Payment, etc.)
  - `merchant_name` - Transaction counterparty
- **Important Notes:** Excludes purchases (use auth events for those)

#### Settled Transactions
- **Full Name:** `edw_db.core.fct_settled_transaction`
- **Business Purpose:** Final settled transaction data
- **Important Notes:** Used for spend analysis and merchant risk

#### Decision Platform Auth
- **Full Name:** `chime.decision_platform.authn`
- **Business Purpose:** Authentication events and outcomes
- **Important Notes:** Contains login attempt data and risk responses

#### Card Auth Events (Beth Table)
- **Full Name:** `chime.decision_platform.card_auth_events`
- **Common Aliases:** `beth table` (created by Beth), `card auth event table`
- **Business Purpose:** Card authorization events with policy decisions and risk scores
- **Core Fields:**
  - `user_id` - Member identifier
  - `auth_id` - Authorization transaction ID
  - `decision_id` - Decision platform decision ID
  - `policy_name` - Policy that was triggered
  - `decision_outcome` - Policy decision (allow, deny, step_up, etc.)
  - `policy_actions` - Actions taken by the policy
  - `is_shadow_mode` - Whether this was a shadow mode decision
  - `original_timestamp` - When the decision was made
- **Key Relationships:** Links to real-time auth events via `auth_id`
- **Data Characteristics:** Decision platform data, policy outcomes
- **Important Notes:** Contains policy decisions and risk model outputs

#### Mobile Wallet Provisioning
- **Full Name:** `chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization`
- **Business Purpose:** Card tokenization and mobile wallet provisioning events
- **Core Fields:**
  - `user_id` - Member identifier
  - `device_id` - Device identifier
  - `original_timestamp` - When provisioning occurred
  - `token_id` - Token identifier
  - `card_last_4` - Last 4 digits of card
  - `wallet_type` - Type of wallet (Apple Pay, Google Pay, etc.)
  - `processor` - Payment processor
  - `risk_score` - Risk assessment score
- **Important Notes:** Key for device fingerprinting and fraud detection

#### User Sessions
- **Full Name:** `edw_db.feature_store.atom_user_sessions_v2`
- **Business Purpose:** User login sessions with device and risk information
- **Core Fields:**
  - `user_id` - Member identifier
  - `device_id` - Device identifier
  - `session_timestamp` - When session started
  - `device_model` - Device model information
  - `network_carrier` - Mobile network carrier
  - `ip` - IP address
  - `platform` - Platform (iOS, Android, Web)
  - `locale` - User locale settings
  - `timezone` - User timezone
- **Important Notes:** Critical for login risk assessment and device tracking

#### P2P Service
- **Full Name:** `postgres_db.p2p_service.pay_friends`
- **Business Purpose:** P2P payment relationships and transactions
- **Core Fields:**
  - `sender_id` - Sender user ID
  - `receiver_id` - Receiver user ID
  - `amount` - Transfer amount
  - `created_at` - When transfer was created
  - `type_code` - Transfer type (to_member, to_nonmember, etc.)
- **Important Notes:** Links to financial transactions for P2P analysis

### ⭐ Specialized Tables

#### Risk Scores (DSML Team)
- **ATOM Score** - Authentication risk scoring
- **FPF Score** - First Party Fraud scoring
- **SEP Score** - Second Party Fraud scoring
- **SAD Score** - Synthetic Account Detection
- **Special Purpose:** ML model outputs for risk assessment

## 🔗 Table Relationships

### Core Relationship Patterns

#### Transaction to Dispute Linking
```sql
-- Standard pattern for linking transactions to disputes
FROM risk.test.spending_risk_master_driver_table a
LEFT JOIN risk.prod.disputed_transactions b
  ON (a.user_id = b.user_id
      AND (b.authorization_code = a.auth_id
           OR b.authorization_code = a.settled_auth_id))
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY a.user_id, a.auth_id
  ORDER BY b.dispute_created_at
) = 1
```

#### Dual Auth Pattern
```sql
-- Linking original auth to settlement
FROM edw_db.core.fct_realtime_auth_event rae
LEFT JOIN edw_db.core.fct_realtime_auth_event dual
  ON (rae.user_id = dual.user_id
      AND rae.auth_id = dual.original_auth_id)
```

#### Card Information Joining
```sql
-- Joining card details using PAN last 4 digits
LEFT JOIN edw_db.core.dim_card c
  ON (rae.user_id = c.user_id
      AND RIGHT(rae.pan, 4) = RIGHT(c.card_number, 4))
```

## 📋 Usage Best Practices

### Performance Optimization
- **Efficient Filtering:** Use `response_cd IN ('00','10')` for successful auths, `req_amt < 0` for purchases
- **JOIN Strategies:** Use `QUALIFY ROW_NUMBER()` for deduplication, join cards via last 4 digits
- **Partitioning Strategy:** Leverage date-based partitioning for time-series analysis

### Data Quality
- **Common Pitfalls:**
  - Merchant names need `UPPER()` standardization
  - Dual auths require linking original to settlement
  - Dispute amounts are negative values
- **Validation Methods:**
  - Case studies to validate feature correctness
  - Cross-reference dispute rates with known patterns
  - Verify data freshness (< 1 day latency for prod tables)

---

> 📝 **Update Notes:** This document is continuously updated as business evolves, ensuring information accuracy and completeness.
