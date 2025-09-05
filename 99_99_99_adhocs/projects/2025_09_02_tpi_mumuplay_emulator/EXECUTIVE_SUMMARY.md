# TPI MuMuPlayer Emulator Detection Analysis
## Executive Summary for Leadership Review

**Project Date**: September 2, 2025
**Analyst**: Data Team
**Objective**: Detect and quantify emulator-based fraud using network carrier vs IP country mismatch patterns

---

## 🎯 **Project Overview**

### **Initial Discovery**
- **Target Case**: User 86963958 (confirmed MuMuPlayer emulator user)
- **Key Finding**: Network carrier = Taiwan (FarEasTone) + IP country = USA
- **Hypothesis**: Network/IP country mismatch indicates emulator usage

### **Analysis Scope**
- **Data Period**: July 2025 login data
- **Focus**: All foreign network carriers with USA IP country
- **Methodology**: Network carrier country mapping + user status analysis + device intelligence correlation

---

## 🚨 **Critical Findings**

### **1. Taiwan Network Carrier Anomaly**
- **Volume**: 21,602 logins (93.3% of all foreign network carrier logins)
- **Active Rate**: Only **33.04%** (vs 44-94% for other countries)
- **User Status Breakdown**:
  - **43.22%** cancelled_no_refund (7,803 users)
  - **22.97%** suspended (4,146 users)
  - **0.77%** cancelled (139 users)
  - **33.04%** active (5,965 users)

### **2. Device Intelligence Gap**
- **DWN Coverage**: Only **10.64%** of Taiwan logins have Darwinium data
- **Other Countries**: 47-89% DWN coverage (normal pattern)
- **Implication**: Taiwan emulator logins bypass device intelligence systems

### **3. Fraud Signal Validation**
- **Network/IP Mismatch**: Strong predictor of account closure/suspension
- **Low Active Rate**: 33% vs 44-94% for legitimate international users
- **Device Intelligence Bypass**: 89.36% of Taiwan logins lack DWN data

---

## 🔍 **Exploratory Analysis Findings**

### **Pattern Discovery**
- **18,053 Taiwan users** with USA IP pattern identified
- **12,088 users (66.19%)** already flagged as problematic by existing risk systems
- **19,304 logins (89.36%)** bypass device intelligence systems

### **Signal Validation**
- **Network carrier vs IP country mismatch** shows strong correlation with fraud indicators
- **Taiwan + USA IP** pattern consistently associated with account issues
- **Low DWN coverage** suggests emulator logins avoid device intelligence

### **Research Insights**
- **Geographic inconsistency** as potential fraud signal
- **Device intelligence gaps** in current detection coverage
- **User behavior patterns** differ significantly between legitimate and suspicious users

---

## 🔧 **Technical Implementation**

### **Data Infrastructure Created**
1. **Base Login Tables**: All July 2025 login data with outcomes
2. **Network Carrier Mapping**: 315 carriers mapped to countries
3. **Enriched Analysis Table**: `RISK.TEST.hding_a3id_login_info_enriched`
4. **DWN Integration**: Device intelligence correlation analysis

### **Key Metrics Developed**
- **Active User Rate**: By network carrier country
- **DWN Coverage Rate**: Device intelligence mapping percentage
- **User Status Distribution**: Account closure/suspension patterns

---

## 🔍 **Research Conclusions**

### **Key Discoveries**
- **Network/IP mismatch** shows strong correlation with existing fraud flags
- **Taiwan + USA IP** pattern consistently associated with account issues
- **Device intelligence gaps** identified in current detection coverage

### **Pattern Validation**
- **Signal Strength**: 66.19% of Taiwan users already flagged by existing risk systems
- **Geographic Inconsistency**: Network carrier vs IP country mismatch as potential fraud signal
- **Coverage Analysis**: 89.36% of suspicious logins bypass device intelligence

---

## 📋 **Next Research Steps**

1. **Expand Analysis** to other suspicious country combinations
2. **Deep Dive** into DWN data for available Taiwan cases
3. **Historical Analysis** to validate pattern consistency over time
4. **Cross-Reference** with other fraud detection signals

**This exploratory analysis identifies promising patterns for further investigation in emulator-based fraud detection.** 🔍
