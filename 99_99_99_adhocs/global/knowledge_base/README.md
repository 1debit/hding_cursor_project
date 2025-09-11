# Snowflake Knowledge Base

Global Snowflake knowledge repository - reusable table references, query patterns, and business logic

## 🚀 **Quick Reference Guide**

### **Most Common Tables (Click to Jump)**
- **[Real-time Auth Events](table_reference.md#real-time-authorization-events)** (`rae`) - Card transactions
- **[Disputed Transactions](table_reference.md#disputed-transactions)** - Dispute records
- **[Member Details](table_reference.md#member-details)** - User information
- **[Card Auth Events](table_reference.md#card-auth-events-beth-table)** (`beth table`) - Policy decisions

### **Most Common Patterns (Click to Jump)**
- **[Transaction to Dispute Linking](query_patterns.md#transaction-to-dispute-linking-pattern)** - Link auths to disputes
- **[Dual Auth Settlement](query_patterns.md#dual-auth-settlement-pattern)** - Handle dual authorizations
- **[Dispute Rate Calculation](query_patterns.md#dispute-rate-calculation-pattern)** - Calculate dispute metrics
- **[User Activity Timeline](query_patterns.md#comprehensive-user-activity-timeline-pattern)** - Complete user history

### **Business Logic Quick Lookup**
- **[Dispute Management](business_logic.md#dispute-management)** - Dispute rates, unauthorized disputes
- **[Transaction Processing](business_logic.md#transaction-processing)** - Dual auth, cross-state analysis
- **[Risk Scoring](business_logic.md#risk-scoring-dsml-team)** - ATOM, FPF, SEP, SAD models
- **[Feature Naming](business_logic.md#feature-naming-convention)** - Standard feature naming patterns

## 📚 Knowledge Base Structure

```
global_snowflake_utils/knowledge_base/
├── table_reference.md             # Core table reference manual
├── query_patterns.md              # Common query patterns
├── business_logic.md              # Business logic explanations
├── QUICK_LOOKUP.md                # 🚀 Instant access to most common info
├── SEARCH_INDEX.md                # 🔍 Searchable index of all content
├── data_dictionary.md             # Data dictionary (future)
└── README.md                      # This file
```

## 🎯 Purpose

### Global Knowledge (stored here)
- **Core business tables** - Key tables used across all projects
- **Standard query patterns** - Reusable query logic and patterns
- **Data dictionary** - Field meanings, business rules, calculation logic
- **Best practices** - Performance optimization, data quality checks

### Project-Specific (stored in each project's sql/ folder)
- **Project analysis queries** - Analysis for specific business questions
- **Temporary exploration** - Data exploration and validation queries
- **Project reports** - Queries generating specific project results

## 📖 Usage

### Referencing global knowledge in projects
```bash
# Create symbolic link to global knowledge base
ln -sf ../global_snowflake_utils/knowledge_base knowledge_base

# Reference global knowledge in your SQL
-- In your project SQL comments
-- Reference: knowledge_base/query_patterns.md - User Metrics Pattern
-- Reference: knowledge_base/table_reference.md - USER_EVENTS table
```

### Learning and reference
1. **🚀 Quick Start**: Use `QUICK_LOOKUP.md` for instant access to most common tables and patterns
2. **🔍 Search**: Use `SEARCH_INDEX.md` to find specific tables, patterns, or concepts
3. **📊 Deep Dive**: Check `table_reference.md` for complete table documentation
4. **🔗 Patterns**: Reference `query_patterns.md` for reusable SQL patterns and examples
5. **📋 Business Rules**: Check `business_logic.md` for business rules and metric definitions
6. **Apply and improve** these patterns in your projects

## 🔄 Maintenance Principles

- **Continuous updates** - Add new important tables and patterns as discovered
- **Complete documentation** - Every table and query has clear business meaning
- **Version control** - Important changes are recorded and explained
- **Cross-project validation** - Ensure knowledge applies across multiple projects

---

This knowledge base serves as the **common reference library** for all Snowflake analysis projects, helping improve analysis efficiency and consistency.
