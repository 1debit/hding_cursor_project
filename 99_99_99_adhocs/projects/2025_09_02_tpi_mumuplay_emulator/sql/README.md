# SQL Files Overview - TPI MuMuPlayer Emulator Detection

This directory contains SQL files organized by logical project flow for the TPI MuMuPlayer Emulator Detection project.

## 📋 **Project Flow & File Organization**

### **Phase 1: Case Review & Base Data Creation**
- **`010_case_review_and_base_data.sql`**: Initial case review of user 86963958, creates base login tables (`hding_a3id_login_with_outcome`, `hding_a3id_login_info`) for July 2025 data

### **Phase 2: Network Carrier Country Mapping**
- **`020_network_carrier_country_mapping.sql`**: Applies comprehensive carrier mapping from CSV research (315 carriers, 68.44% coverage)
- **`030_network_carrier_data_preparation.sql`**: Network carrier analysis and data preparation for country mapping
- **`040_final_enriched_table_creation.sql`**: Creates final enriched table `RISK.TEST.hding_a3id_login_info_enriched` with country mappings and validation

### **Phase 3: Foreign Network Carrier Analysis**
- **`050_taiwan_network_usa_ip_analysis.sql`**: Analyzes Taiwan network + USA IP + low MOB users (found 5 users with 0 months on book)
- **`060_foreign_network_carriers_active_user_analysis.sql`**: Comprehensive analysis of all foreign network carriers with USA IP, showing Taiwan has only 33.04% active rate vs 44-94% for other countries
- **`070_taiwan_user_status_breakdown.sql`**: Detailed breakdown of Taiwan user statuses (43.22% cancelled_no_refund, 22.97% suspended)

### **Phase 4: Device Intelligence Integration**
- **`080_darwinium_device_intelligence_analysis.sql`**: DWN device intelligence analysis showing Taiwan has only 10.64% DWN coverage vs 47-89% for other countries, confirming emulator bypass

## 🔄 **Execution Workflow**

### **Complete Analysis Pipeline**
1. **Run `010_case_review_and_base_data.sql`** → Creates base login tables
2. **Run `020_network_carrier_country_mapping.sql`** → Creates carrier mapping table
3. **Run `030_network_carrier_data_preparation.sql`** → Prepares data for mapping
4. **Run `040_final_enriched_table_creation.sql`** → Creates final enriched table
5. **Run `050_taiwan_network_usa_ip_analysis.sql`** → Analyzes Taiwan-specific patterns
6. **Run `060_foreign_network_carriers_active_user_analysis.sql`** → Compares all foreign countries
7. **Run `070_taiwan_user_status_breakdown.sql`** → Details Taiwan user status distribution
8. **Run `080_darwinium_device_intelligence_analysis.sql`** → Integrates device intelligence data

## 📊 **Key Findings Summary**

### **Taiwan Network Carrier Anomaly**
- **Volume**: 21,602 logins (93.3% of all foreign network carrier logins)
- **Active Rate**: Only 33.04% (vs 44-94% for other countries)
- **User Status**: 66.19% cancelled/suspended (high fraud indicator)
- **DWN Coverage**: Only 10.64% (vs 47-89% for other countries)

### **Business Impact**
- **18,053 Taiwan users** with USA IP pattern identified
- **Network/IP mismatch** validated as strong fraud signal
- **Device intelligence bypass** confirmed for emulator logins

## 📁 **Supporting Data Files**
- **`files/Carrier_Mapping__Alpha-3_.csv`**: Comprehensive carrier mapping (315 carriers) from AI research
- **`files/mumuplayer simulator case.xlsx`**: User 86963958's activity history
- **`files/20250902_Case_Review.xlsx`**: Case review data for user 86963958
