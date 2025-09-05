# TPI Case Study: MuMuPlayer Emulator Detection

**Project ID:** 2025_09_02_tpi_mumuplay_emulator
**Start Date:** 2025-09-02
**Status:** Active
**Lead:** User-led analysis with AI assistance

## 🎯 Project Summary

This project analyzes a TPI (Third Party Integrator) case study focusing on MuMuPlayer emulator fraud patterns. The investigation centers on user 86963958, who was identified through Penny's internal account management system using chimesign/chimetag lookup.

### Key Objective
Analyze how fraudsters use MuMuPlayer Android emulator to bypass Chime's virtual card number hiding feature through specific emulator configuration changes.

## 🔍 Key Findings

### Emulator Fraud Method
- **Target:** Chime virtual card number hiding feature
- **Method:** MuMuPlayer emulator configuration changes
- **Device Spoofing:** Samsung Galaxy Note series (SM-N9*)
- **Configuration Changes:**
  - Performance: Medium/high → Low
  - Display: 100% brightness, 240fps max
  - Resolution: 1080×1920 @ 320 DPI → 540×960 @ 240 DPI

### Technical Discoveries
- **ChimeSign Location:** `RISK.TEST.SESSION_REPLAY_DRIVER_TABLE.IDENTIFIER`
- **User Identification:** Successfully mapped chimesign to user_id 86963958
- **Emulator Indicator:** Network carrier vs IP carrier mismatch
  - Network: FarEasTone (Taiwan)
  - IP: USA-based
  - **This mismatch is a strong emulator detection signal**

### Data Infrastructure Created
- `RISK.TEST.hding_a3id_login_with_outcome` - Login outcomes for July 2025
- `RISK.TEST.hding_a3id_login_info` - Detailed login information with carrier data
- `RISK.TEST.hding_network_carrier_country_mapping` - Carrier to country mapping

## 📊 Analysis Progress

### ✅ Completed
- [x] Project setup and context documentation
- [x] ChimeSign database location identification
- [x] User 86963958 identification via Penny
- [x] Login data table creation and structure
- [x] Network carrier analysis framework
- [x] Network carrier country mapping completion
- [x] Network vs IP carrier mismatch analysis
- [x] Emulator detection pattern identification
- [x] Darwinium device signal analysis
- [x] Comprehensive MOB distribution analysis
- [x] Data visualization and reporting

### 🔍 Key Discoveries
- **Network Carrier vs IP Mismatch**: Taiwan network carriers with USA IP addresses
- **MOB Pattern Analysis**: Taiwan users show 67.2% new accounts vs 9.1% for US users
- **Device Intelligence Mapping**: Low DWN data coverage for foreign carriers
- **User Status Patterns**: High inactive user rates for foreign network carriers

## 🗂️ Project Structure

```
projects/2025_09_02_tpi_mumuplay_emulator/
├── docs/
│   └── memory.md              # Detailed project memory and context
├── scripts/                   # Project-specific Python scripts
├── sql/                       # SQL analysis files
├── files/                     # Input files and data
├── outputs/                   # Results and deliverables
└── README.md                  # This file
```

## 🔗 Key Resources

- **Reference Documentation:** [Google Slides](https://docs.google.com/presentation/d/1mX-1xkS7QkhFGPOizoX-K9aCWECwPBY5gA_WBQlil9c/edit?slide=id.g373c6209f40_0_111#slide=id.g373c6209f40_0_111)
- **Tutorial Video:** [YouTube](https://youtu.be/qF_aDFsMdoY)
- **Target User Risk Events:** [Penny](https://penny.chime.com/member/86963958/risk-events)

## 📈 Business Impact

### Fraud Detection Innovation
- **New Indicator:** Network carrier vs IP carrier mismatch as emulator signal
- **Methodology:** Comprehensive login analysis framework for ongoing monitoring
- **Case Study Value:** Framework for future emulator detection projects

### Technical Infrastructure
- **Data Tables:** Reusable login analysis infrastructure
- **Mapping System:** Scalable network carrier country mapping
- **Detection Logic:** Emulator identification patterns

## 🚧 Current Challenges

1. **Country Mapping Scale:** 700+ network carriers need country code mapping
2. **Data Quality:** Some carriers have inconsistent naming conventions
3. **Automation:** Need efficient process for large-scale carrier mapping

## 📝 Session Log

### 2025-09-02
- Project initialization and context setup
- ChimeSign database location discovery
- User 86963958 identification via Penny
- Login data table creation
- Network carrier analysis framework setup
- Initial country mapping implementation

### 2025-09-05
- **MOB Distribution Analysis**: Completed comprehensive analysis comparing US vs Taiwan network carriers
- **Data Completeness Fix**: Resolved critical error where 12+ months users were excluded from analysis
- **Visualization Update**: Created final pie charts with proper categorization and descriptive titles
- **Key Learning**: Always include comprehensive MOB categories (0, 1-3, 4-6, 7-12, 12+) to avoid distorted percentages
- **Project Status**: Analysis phase complete, ready for leadership review

## 🎯 Final Results Summary

### Critical Findings
- **US Network Carrier**: 9.1% new users (0 months), 67.1% established users (12+ months) - **Normal healthy pattern**
- **Taiwan Network Carrier**: 67.2% new users (0 months), 12.9% established users (12+ months) - **Highly suspicious pattern**
- **Taiwan Inactive Users**: 79.4% new users (0 months) - **Extremely suspicious fraud indicator**

### Business Impact
This analysis provides strong evidence of emulator-based fraud patterns through network carrier vs IP country mismatches and abnormal new user concentration patterns.

---

*This project demonstrates the value of systematic emulator detection analysis and provides a foundation for future fraud prevention initiatives.*
