# Project Memory (One-Pager)

> Purpose: Long-term memory for this project. Combine goals, context, definitions, and key decisions.

## 1. Project Overview
- **Goal:** Provide a robust, scalable foundation for Snowflake data analysis with Cursor AI
- **Scope:** Data exploration, analysis, profiling, and SQL development for Snowflake environments
- **Stakeholders:** Data analysts, data engineers, business intelligence teams

## 2. Context & Background
- Standardized starter kit for Snowflake development with Cursor AI
- Implements MDC (Modern Data Center) best practices for SQL development
- Focuses on cost optimization, security, and performance monitoring
- Supports both development and production workflows

## 3. Key Metrics & Definitions (Glossary)
- `monthly_active_users`: unique users with >=1 session in last 30 days (exclude test accounts)
- `net_revenue`: gross sales – refunds (excludes tax and shipping)
- `churn_rate`: percentage of customers who stopped purchasing in the last 90 days
- `avg_order_value`: total revenue / total orders for given time period
- `customer_lifetime_value`: predicted total revenue from customer over relationship
- `conversion_rate`: (completed purchases / website sessions) * 100

## 4. Data Contracts (Tables)
| Object (DB.SCHEMA.TABLE) | Owner/Team | SLA | Columns | Notes |
|--------------------------|------------|-----|---------|-------|
| ANALYTICS.PUBLIC.demo_sales | Data Team | D+1 | id INT, amount NUMBER(10,2), city STRING, order_ts TIMESTAMP_NTZ, created_ts TIMESTAMP_NTZ | Demo table for testing |
| ANALYTICS.PUBLIC.customers | Data Team | D+1 | customer_id, email, created_ts, updated_ts, status | Customer master data |
| ANALYTICS.PUBLIC.orders | Data Team | D+1 | order_id, customer_id, amount, status, order_ts | Order transactions |
| ANALYTICS.PUBLIC.order_items | Data Team | D+1 | order_id, product_id, quantity, unit_price | Order line items |

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

## 11. Known Issues / Decisions
- **2024-01-15**: Implemented MDC best practices for SQL style and safety
- **2024-01-15**: Added comprehensive data profiling and cost monitoring tools
- **2024-01-15**: Established query header format for better documentation
- **Cost optimization**: Always provide preview queries for operations on large tables
- **Performance**: Use QUALIFY instead of DISTINCT with window functions where possible

## 12. Emergency Procedures
- **Runaway queries**: Use `SYSTEM$CANCEL_QUERY()` or warehouse suspension
- **High costs**: Monitor via `monitor_queries.py`, set up cost alerts
- **Data quality issues**: Document in this section, implement validation checks
- **Schema changes**: Always test in DEV, provide rollback strategy

## 13. Contact Information
- **Data Team Lead**: [Your Name] - [email]
- **Snowflake Admin**: [Admin Name] - [email]  
- **Escalation**: [Manager Name] - [email]

