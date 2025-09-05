# TPI Case Study (MuMuPlayer Emulator Detection) - Project Memory

> **Purpose**: Long-term memory for TPI case study analyzing MuMuPlayer emulator fraud patterns and device fingerprinting analysis.

## 📋 Project Overview

**Start Date:** 2025-09-02
**Status:** Active
**Goal:** Analyze MuMuPlayer emulator fraud patterns where fraudsters bypass Chime virtual card number hiding using specific emulator configuration changes

### 🔗 Project Context & References
- **Reference Doc:** https://docs.google.com/presentation/d/1mX-1xkS7QkhFGPOizoX-K9aCWECwPBY5gA_WBQlil9c/edit?slide=id.g373c6209f40_0_111#slide=id.g373c6209f40_0_111
- **YouTube Tutorial:** https://youtu.be/qF_aDFsMdoY
- **Example User:** 86963958
- **User Risk Events:** https://penny.chime.com/member/86963958/risk-events
- **Focus:** MuMuPlayer Android emulator fraud analysis

### 🎯 Project Objectives

#### **Confirmed Emulator Case Study**
- **Target User**: 86963958 (confirmed MuMuPlayer emulator user)
- **Evidence**: YouTube video shows user demonstrating login via MuMuPlayer emulator
- **Detection Gap**: All logins marked as "normal mobile login" (emulator not detected)
- **Activity Pattern**: Only login on 7/17/2025, no other activities (funding/offloading)

#### **Critical Discovery - Network vs IP Mismatch**
- **Network Carrier**: FarEasTone (Taiwan carrier)
- **IP Country**: USA
- **IP Carrier**: American company
- **Signal**: Foreign network carrier + USA IP country = potential emulator indicator

#### **Analysis Scope & Goals**
- **Data Mining Target**: All July 2025 login data across company
- **Focus Population**: Users with foreign network carriers but USA IP country
- **Primary Goal**: Quantify volume of network/IP mismatches for emulator detection
- **Secondary Goal**: Identify patterns for case review and fraud prevention

#### **Data Infrastructure Created**
- **Login Success Table**: All logins with success/failure indicators
- **Network/IP Analysis Table**: Login requests with network carrier and IP country info
- **Mismatch Analysis**: Foreign network + USA IP breakdown for July 2025

#### **Key Research Questions**
1. How many users have foreign network carriers with USA IP country?
2. What is the volume of such mismatched logins in July 2025?
3. Can network/IP mismatch patterns identify emulator usage?
4. What other signals correlate with confirmed emulator cases?

#### **Expected Outcomes**
- **Quantified Risk**: Volume of potential emulator logins
- **Detection Method**: Network carrier vs IP country mismatch as fraud signal
- **Case Review Framework**: Systematic approach to identify emulator users
- **Prevention Strategy**: Enhanced detection for future emulator attempts

### 💡 Key Discoveries
- **Confirmed Emulator User:** User 86963958 confirmed using MuMuPlayer emulator (YouTube evidence)
- **Detection Gap:** Emulator logins marked as "normal mobile login" - current detection failing
- **Critical Signal:** Network carrier (FarEasTone/Taiwan) vs IP country (USA) mismatch
- **Activity Pattern:** User only logged in on 7/17/2025, no other activities (suspicious for fraud case)
- **Data Infrastructure:** Created comprehensive login analysis tables for July 2025
- **Research Direction:** Foreign network + USA IP pattern as emulator detection method
- **ChimeSign Database:** Located in `RISK.TEST.SESSION_REPLAY_DRIVER_TABLE.IDENTIFIER` column
- **User Identification:** Successfully identified via Penny internal tool using chimesign

### 🚨 Fraud Method Details
- **Emulator:** MuMuPlayer Android emulator on Windows
- **Target:** Bypass Chime's virtual card number hiding feature
- **Method:** Specific emulator configuration changes to reveal full card details
- **Device Spoofing:** Samsung Galaxy Note series (SM-N9*) device model simulation
- **Tutorial Language:** Hindi with account selling pitch

### 🔧 Technical Emulator Configuration
- **Performance:** Lowered from medium/high to "low"
- **Display:** Screen brightness 100%, max frame rate 240fps
- **Resolution Change:** 1080×1920 @ 320 DPI → 540×960 @ 240 DPI
- **Restart Required:** Configuration changes require emulator restart
- **Device Spoofing:** Samsung Galaxy Note series (SM-N9*) models
- **Anonymity Check:** Used whoer.net to verify spoofed Android device detection

### 🎯 User Identification Process
- **Tool Used:** Penny internal account management platform
- **Input:** Chimesign/chimetag value
- **Output:** Successfully identified user_id 86963958
- **Verification:** Confirmed user has risk events on Penny
- **Note:** ChimeTag is P2P username, chimesign is device identifier

## 🏗️ Technical Architecture

### Data Sources
- **User Activity Log:** `files/mumuplayer simulator case.xlsx` - User 86963958's activity history

- **Login Data:** STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG

### Key Tables & Fields
```sql
-- Confirmed emulator user login analysis (7/17/2025)
SELECT
    _CREATION_TIMESTAMP,
    request:atom_event:platform::varchar as platform,
    externally_loaded:computed:atom_v3_score:float_value::float as atom_v3,
    externally_loaded:prediction_store:data_prediction_store_atom_v3_prediction_score_device_id_input_event_device_id_user_id_input_event_user_id:float_value::float as atom_v3_stored,
    request:atom_event:session_event::varchar as session_event,
    request:atom_event:account_access_attempt_id::varchar as a3id,
    event_name,
    decision_id,
    user_id,
    request,
    externally_loaded,
    device_id
FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG decision_log
WHERE decision_log._creation_timestamp::date = '2025-07-17'
    AND user_id = '86963958'
    AND decision_log.event_name = 'atom_event'
    AND decision_log.labels:service_names != 'shadow'
ORDER BY _creation_timestamp;

-- Network carrier vs IP country mismatch analysis
SELECT
    network_carrier,
    network_carrier_country,
    ip_carrier,
    ip_country,
    COUNT(*) as login_count,
    COUNT(DISTINCT user_id) as unique_users
FROM RISK.TEST.hding_a3id_login_info
WHERE network_carrier_country != ip_country
    AND network_carrier_country IS NOT NULL
    AND ip_country IS NOT NULL
GROUP BY 1,2,3,4
ORDER BY login_count DESC;
```

### Analysis Approach
1. **Phase 1:** Analyze confirmed emulator user (86963958) login patterns and signals
2. **Phase 2:** Identify network carrier vs IP country mismatch patterns
3. **Phase 3:** Quantify volume of foreign network + USA IP mismatches in July 2025
4. **Phase 4:** Develop emulator detection methodology based on network/IP analysis
5. **Phase 5:** Create case review framework for systematic emulator identification

## 🔧 **Key SQL Files & Scripts**

### **Essential SQL Files (5 files)**
- **`000_input.sql`**: Main input queries creating base tables (`hding_a3id_login_with_outcome`, `hding_a3id_login_info`) and initial network carrier analysis for July 2025
- **`580_apply_carrier_mapping_from_csv.sql`**: Applies comprehensive carrier mapping from CSV research (315 carriers, 68.44% coverage) - synced from session replay project
- **`590_network_carrier_mapping.sql`**: Network carrier analysis and data preparation for country mapping - synced from session replay project
- **`591_final_carrier_mapping_with_validation.sql`**: Creates final enriched table `hding_a3id_login_info_enriched` with country mappings and validation - synced from session replay project
- **`600_twn_network_usa_ip_low_mob_users.sql`**: Analyzes Taiwan network + USA IP + low MOB users (found 5 users with 0 months on book)

### **Workflow for Final Table Creation**
1. **Run `000_input.sql`** → Creates base login tables
2. **Run `580_apply_carrier_mapping_from_csv.sql`** → Creates carrier mapping table
3. **Run `590_network_carrier_mapping.sql`** → Prepares data for mapping
4. **Run `591_final_carrier_mapping_with_validation.sql`** → Creates final enriched table
5. **Run `600_twn_network_usa_ip_low_mob_users.sql`** → Analyzes emulator patterns

### **Key Data Files**
- **`files/Carrier_Mapping__Alpha-3_.csv`**: Comprehensive carrier mapping (315 carriers) from AI research
- **`files/mumuplayer simulator case.xlsx`**: User 86963958's activity history
- **`files/20250902_Case_Review.xlsx`**: Case review data for user 86963958

## 📈 **Updated Key Findings**

### **Network Carrier Analysis Results**
- **Taiwan Carrier Volume**: 31,374 Taiwan carrier records with 20,047 unique users in July 2025
- **Network Mapping Coverage**: 68.44% coverage achieved with 315 comprehensive carrier mappings
- **Primary Taiwan Carrier**: FarEasTone is the main Taiwan carrier in the data

### **Emulator Detection Results**
- **Low MOB Users Found**: 5 users with Taiwan network + USA IP + 0 months on book (brand new accounts)
- **Emulator Pattern Confirmed**: FarEasTone (Taiwan) + USA IP + new accounts = strong emulator indicators
- **User Examples**: 87678343, 87677593, 87732159, 87731317, 87730623 (all 0 months on book)

### **Technical Achievements**
- **Final Table Created**: `RISK.TEST.hding_a3id_login_info_enriched` with comprehensive country mappings
- **SQL Cleanup**: Reduced from 73 files to 5 essential files for clear workflow
- **Documentation**: Complete workflow and file purpose documentation added

### **Business Impact**
- **Detection Method**: Network carrier vs IP country mismatch as validated emulator signal
- **Case Review Framework**: Systematic approach to identify emulator users established
- **Prevention Strategy**: Enhanced detection methodology for future emulator attempts
