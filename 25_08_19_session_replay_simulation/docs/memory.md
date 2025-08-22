# Project Memory (One-Pager)

> Purpose: Long-term memory for this project. Combine goals, context, definitions, and key decisions.

## 1. Project Overview
	I recently learned about a fraud technique called session replay from our device intelligence vendor, Darwinium (DWN).

	In this scenario, a fraudster impersonates a Chime support agent and tricks a customer into logging into a fake website. The customer’s login credentials are then compromised. Using these stolen credentials, the fraudster extracts the authentication token and plugs it into an API tool (e.g., Postman). This bypasses the normal login process and gives direct access to the customer’s account.

	Inside Postman, the fraudster can also manipulate device footprint information (e.g., device ID, model, etc.). With this setup, they can perform actions that normally require a mobile app login, such as offloading funds via P2P or OIT (outbound instant transfer through a linked debit card).

	DWN has simulated this attack path and provided us with criteria to identify potential P2P offloading initiated via session replay. For example, the following query can capture such cases:

	SELECT 
	    t._DEVICE_ID,
	    t._USER_ID,
	    t._CREATION_TIMESTAMP,
	    TRY_PARSE_JSON(t.body) AS body_json,
	    body_json:step_name::varchar AS step_name,
	    body_json:identifier::varchar AS identifier
	FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE t
	WHERE name = 'VENDOR_DARWINIUM'
	  AND (body_json:profiling:replay_count > 1 
	       AND body_json:profiling:secure_id:signals::varchar LIKE '%INVALID_NONCE%')
	  AND body_json:step_name::varchar = 'p2p_transfer';


	For this project, I’d like to do the following:

	Use the SQL above to extract all P2P sessions that meet these criteria over the past two months.

	Save the results into a table under risk.test.

	In the next step, I’ll provide instructions on how to flag all P2P sessions in that table with a fraud indicator. The goal is to later evaluate the accuracy of this indicator.

## 2. Context & Background
- Standardized starter kit for Snowflake development with Cursor AI
- Implements MDC (Modern Data Center) best practices for SQL development
- Focuses on cost optimization, security, and performance monitoring
- Supports both development and production workflows

## 3. Key Metrics & Definitions (Glossary)

- dispute rate(precision)
- dispute cover rate(recall)

## 4. Data Contracts (Tables)

### 4.1 Session Replay P2P Cases (`RISK.TEST.session_replay_p2p_cases`)
**Purpose**: Raw session replay cases identified by Darwinium criteria
- **Source**: `STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE`
- **Criteria**: `replay_count > 1` AND `INVALID_NONCE` signals AND `step_name = 'p2p_transfer'`
- **Time window**: Past 60 days
- **Records**: 22,366 cases
- **Unique users**: 13,974
- **Unique devices**: 13,958

**Key fields**:
- `device_id`, `user_id`, `creation_timestamp_utc`
- `step_name`, `identifier`, `replay_count`, `secure_id_signals`
- `body_json` (parsed Darwinium response), `raw_body`

### 4.2 Session Replay Driver Table (`RISK.TEST.hding_dwn_p2p_session_replay_driver`)
**Purpose**: Session replay cases enriched with decision platform data and fraud labels for accuracy evaluation
- **Source**: Session replay cases + decision platform + dispute data
- **Records**: 20,849 cases (filtered for decision platform matches)
- **Fraud rate**: 0.24% (50/20,849 cases with actual fraud disputes)

**Key fields**:
- All fields from session replay cases
- `decision_id`, `sender_user_id`, `original_timestamp`, `transfer_amount`
- `dec_plat_decision` (allow/deny/OTP)
- `fraud_dispute_ind` (0/1) - ground truth fraud label
- `email_hash` (from PII dimension)

**Decision platform distribution**:
- Allow: 93.18% (19,427 cases)
- Deny: 4.26% (888 cases)  
- OTP: 2.56% (534 cases)


## 5. Naming Conventions

## 6. Warehouse & Cost Management

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
- **Simple daily logs**: `logs/YYYY-MM-DD.md` - One file per day with all progress
- **When to log**: User says "save to log" → create/update today's log file
- **Content**: Timestamps, progress, discoveries, issues solved, URLs, next steps
- **AI continuity**: Read latest log files when revisiting project to understand background
- **Keep it simple**: Everything in one daily file - no complex subfolders

## 12. Known Issues / Decisions

### 12.1 Session Replay Model Performance Analysis (2025-08-19)

#### **Current Performance (Baseline)**
- **Precision**: 0.24% (50/20,849 flagged cases are actual fraud)
- **Recall**: 50 fraud cases caught out of unknown total fraud universe
- **False Positive Rate**: 99.76% of flagged cases are not fraud
- **Decision Platform Overlap**: 94% of fraud cases still allowed, only 6% got OTP step-up

#### **Key Discriminative Features Discovered**

**1. Transfer Amount Patterns**
- **Fraud cases**: Higher average ($157.54 vs $67.76) but similar median ($29 vs $25)
- **High-value fraud concentration**: Fraud cases cluster in $100-$1000+ ranges
- **Recommendation**: Add transfer amount thresholds to reduce low-value false positives

**2. Step Number Analysis (Major Finding)**
- **Fraud cases**: Average 9.2 steps vs 4.73 steps for non-fraud
- **Insight**: Fraud cases go through significantly more process steps
- **Recommendation**: Use step_number ≥ 8 as additional criterion

**3. Secure ID Signal Patterns**
- **Two fraud patterns identified**:
  - `["EXISTING_KEY","INVALID_NONCE"]`: 30 cases, $216.89 avg, 4.43 replay count
  - `["INVALID_NONCE","MISSING_PUBLIC_KEY","MISSING_SIGNATURE"]`: 20 cases, $68.51 avg, 15.95 replay count
- **Recommendation**: MISSING_PUBLIC_KEY signals show potential for higher precision

**4. Replay Count Distribution**
- **Fraud cases**: More concentrated in higher replay counts (15+ range)
- **Non-fraud**: More distributed across 2-12 range
- **Recommendation**: Increase replay count threshold to ≥10 for higher precision

#### **Improved Rule Recommendations**

**High-Precision Rule (10x Improvement)**
- **Criteria**: `replay_count ≥ 10 AND secure_id_signals LIKE '%MISSING_PUBLIC_KEY%'`
- **Performance**: 2.15% precision (vs 0.20% current) - **10x improvement**
- **Coverage**: Catches 9/50 fraud cases (18% of fraud volume)
- **Volume**: 419 cases flagged vs 20,849 current

**Balanced Rule (Recommended)**
- **Criteria**: `(replay_count ≥ 8 AND transfer_amount ≥ 200) OR (step_number ≥ 8 AND secure_id_signals LIKE '%MISSING%')`
- **Expected**: 3-5x precision improvement while maintaining higher recall

**Conservative Rule (Maximum Precision)**
- **Criteria**: `replay_count ≥ 15 AND transfer_amount ≥ 500`
- **Expected**: Very high precision but lower recall

#### **Implementation Recommendations**
1. **Phase 1**: Implement high-precision rule as A/B test
2. **Phase 2**: Develop step_number and amount-based composite scoring
3. **Phase 3**: Create tiered alerting based on risk score combinations
4. **Monitor**: Weekly precision/recall metrics by rule variant

## 13. Emergency Procedures
- **Runaway queries**: Use `SYSTEM$CANCEL_QUERY()` or warehouse suspension
- **High costs**: Monitor via `monitor_queries.py`, set up cost alerts
- **Data quality issues**: Document in this section, implement validation checks
- **Schema changes**: Always test in DEV, provide rollback strategy

## 14. Contact Information
