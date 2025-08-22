# Project Memory (One-Pager)

> Purpose: Long-term memory for this project. Combine goals, context, definitions, and key decisions.

## 🤖 AI ASSISTANT CRITICAL RULES

### 🚨 NEVER MAKE DATE ERRORS 🚨
When user says "save to log":
1. **MANDATORY**: Run `date +%Y-%m-%d` command FIRST
2. **MANDATORY**: Use exact output for filename
3. **MANDATORY**: Use same date in content
4. **FORBIDDEN**: Assuming, guessing, or copying old dates

### Examples of FORBIDDEN behavior:
- ❌ Using "2025-01-15" when actual date is "2025-08-21"
- ❌ Copy/pasting dates from old files
- ❌ Making up dates

---

## 1. Project Overview
in this project, I would start with contact data(phone + chat) in which it include the contain raw text:
phone transcript for phone and text conversation for chat, user_id and contact time;

I will firstly select a focal period: 2024.11.01 - 2025.04.30;
use text mining: SQL ilike or snowflake chatgpt function to only select those who claim to be scammed/suffered from scam contacts;
dedup by user_id and select the earlest one over the focal period;
then analyze several metric over 0-34(M0) and 35-68(M1) period:
    - for example for DDer(direct depositor)
        - I would start the selected users above, calculate # of M0 DDer
        - and then calculate out of M0 DDer, how many are not DDer any longer in M1
        - use the delta to quantify churned customer volume;

    - Similarly for funding user rate and purchase user rate
        - out of all funders in M0, how many are not funder any longer in M1 and the delta is funder churn # 

In the end, I wanna summarize, how many users were selected initially(reported being scam victim to us),
and out of which, how many are M0 DDer, funder, and purchaser, and then DDer/Funder/Purchase churn # finally;


## 5. Naming Conventions
- **Tables/views/columns**: `snake_case` (e.g., `customer_orders`, `order_total_amount`)
- **Time columns**: `_dt` (date), `_ts` (timestamp), `_ym` (year-month), `_yw` (year-week)
- **Temporary objects**: `exp_*` (experimental), `_stg` (staging), `_tmp` (temporary)
- **Metrics/KPIs**: `metric_name` (e.g., `monthly_revenue`, `customer_count`)
- **Fully qualified names**: `DATABASE.SCHEMA.OBJECT` for all shared objects

## 6. Warehouse & Cost Management
- **XS/S warehouses**: Exploration, ad-hoc queries, development (<1GB data)
- **M warehouses**: Regular reporting, moderate ETL (1-10GB data)
- **L+ warehouses**: Heavy ETL, large aggregations (>10GB data)
- **Default QUERY_TAG**: `cursor-analyst-starter`
- **Cost thresholds**: Alert on queries >0.1 credits, review queries >0.5 credits
- **Auto-suspend**: 1-2 minutes for cost efficiency

## 7. Validation Checklist
- [ ] Row counts match expectations (validate against source systems)
- [ ] Primary key uniqueness (no duplicate IDs)
- [ ] Null handling consistent (document NULL business rules)
- [ ] Time window aligns with definition (timezone, date boundaries)
- [ ] Cross-check against control data (finance totals, known benchmarks)
- [ ] Data freshness within SLA (check latest record timestamps)
- [ ] Column data types appropriate (avoid SELECT * conversions)

## 8. Security & Governance
- **Authentication**: Prefer private key over password for production
- **Access control**: Role-based access, least privilege principle
- **Data classification**: PII handling, data retention policies
- **Audit trail**: All queries logged with QUERY_TAG for tracking
- **Environment separation**: DEV/TEST/PROD with separate warehouses and databases

## 9. Development Workflow
1. **Planning**: Document intent, inputs, outputs, assumptions in SQL headers
2. **Development**: Test on small datasets, use preview queries for large operations
3. **Validation**: Run data quality checks, verify against business logic
4. **Documentation**: Update memory.md with new metrics or data contracts
5. **Deployment**: Use version control, peer review for schema changes

## 10. Available Tools & Scripts
- `scripts/test_connection.py`: Test Snowflake connectivity
- `scripts/run_sql.py`: Execute SQL files with statement splitting
- `scripts/profile_table.py`: Generate comprehensive table profiles
- `scripts/query_cost_estimator.py`: Estimate query costs before execution
- `scripts/monitor_queries.py`: Monitor query performance and costs
- `src/sf_utils.py`: Utility functions for data analysis and profiling

## 11. Project Logging System

### 🚨 MANDATORY LOGGING PROTOCOL 🚨
**STEP 1**: Execute `date +%Y-%m-%d` command FIRST
**STEP 2**: Use EXACT output for log filename: `logs/YYYY-MM-DD.md`
**STEP 3**: Use same date in content headers
**STEP 4**: NEVER assume, guess, or use hypothetical dates

### Details:
- **When to log**: User says "save to log" → follow MANDATORY PROTOCOL above
- **Content**: Timestamps, progress, discoveries, issues solved, URLs, next steps
- **AI continuity**: Read latest log files when revisiting project to understand background
- **Keep it simple**: Everything in one daily file - no complex subfolders

### ⚠️ CRITICAL ERRORS TO AVOID:
- ❌ Using wrong dates (e.g., "2025-01-15" when it's "2025-08-21")
- ❌ Assuming dates without checking
- ❌ Copy/pasting old dates

## 12. Known Issues / Decisions
- **2025-08-21**: Implemented Snowflake Cortex AI analysis with claude-3-5-sonnet for scam victim identification
- **2025-08-21**: Resolved GROUP BY compilation errors by using step-by-step CTEs instead of complex window functions
- **2025-08-21**: Optimized performance with Q1 2025 focus (60% data reduction) and combined user-level AI processing
- **2025-08-21**: CRITICAL LOG FIX - Always use actual current date for log files (was incorrectly using 2025-01-15)
- **2025-08-19**: Added simple daily logging system (logs/YYYY-MM-DD.md format)
- **Cost optimization**: Always provide preview queries for operations on large tables
- **Performance**: Use QUALIFY instead of DISTINCT with window functions where possible

## 13. Emergency Procedures
- **Runaway queries**: Use `SYSTEM$CANCEL_QUERY()` or warehouse suspension
- **High costs**: Monitor via `monitor_queries.py`, set up cost alerts
- **Data quality issues**: Document in this section, implement validation checks
- **Schema changes**: Always test in DEV, provide rollback strategy

## 14. Contact Information
- **Data Team Lead**: [Your Name] - [email]
- **Snowflake Admin**: [Admin Name] - [email]  
- **Escalation**: [Manager Name] - [email]

