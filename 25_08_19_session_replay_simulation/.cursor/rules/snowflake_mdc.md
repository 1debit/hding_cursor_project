# Snowflake MDC (Modern Data Center) Rules

## SQL Style Guidelines

### Naming Conventions
- **SQL keywords**: Always **UPPERCASE** (`SELECT`, `FROM`, `WHERE`, `JOIN`)
- **Identifiers**: Use `snake_case` for tables, columns, views, functions
- **Fully qualified names**: Use `DATABASE.SCHEMA.OBJECT` format for shared objects
- **Time columns**: Suffix with `_dt` (date), `_ts` (timestamp), `_ym` (year-month), `_yw` (year-week)
- **Temporary objects**: Prefix `exp_` for experimental, suffix `_stg` for staging, `_tmp` for temporary

### Query Structure
- **No `SELECT *`** in production queries - always use explicit column lists
- Use **Common Table Expressions (CTEs)** with descriptive names and comments
- Push down filters as early as possible in query execution
- Use `QUALIFY` for window function filtering instead of subqueries

### Comments and Documentation
```sql
-- Clear intention comment before complex logic
WITH monthly_sales AS (
    -- Calculate monthly aggregates excluding refunded orders
    SELECT 
        DATE_TRUNC('month', order_ts) AS order_month,
        SUM(amount) AS gross_sales,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM ANALYTICS.PUBLIC.orders 
    WHERE status != 'refunded'
        AND order_ts >= DATEADD('year', -2, CURRENT_DATE())
    GROUP BY 1
)
```

## Safety and Governance

### Data Protection
- **NO destructive DML** (`DELETE`, `UPDATE`, `TRUNCATE`) in production schemas without explicit confirmation
- **Always test** on small datasets or dev schemas first
- Use **transactions** for multi-statement operations that must succeed/fail together
- Provide **rollback strategies** for schema changes

### Idempotent Operations
- Prefer `CREATE OR ALTER` for evolving objects
- Use `CREATE OR REPLACE` only when safe (e.g., views, temporary tables)
- Include existence checks: `DROP TABLE IF EXISTS temp_table`

### Query Safety Patterns
```sql
-- Preview pattern: Always provide limited version first
-- PREVIEW: Last 30 days only
SELECT TOP 100 * 
FROM large_table 
WHERE created_ts >= DATEADD('day', -30, CURRENT_DATE());

-- FULL QUERY: Remove TOP and date filter for production
```

## Performance Optimization

### Warehouse Management
- **XS/S warehouses**: Exploration, ad-hoc analysis (< 1GB data)
- **M+ warehouses**: Heavy ETL, large aggregations (> 1GB data)
- **Auto-suspend**: Set to 1-2 minutes for cost efficiency
- **Multi-cluster**: Only for concurrent workloads

### Query Optimization
- Use `LIMIT` for exploration queries
- Leverage clustering keys for large tables (> 1TB)
- Use `DISTINCT` sparingly - often indicates design issues
- Partition elimination with proper date filtering

### Cost Awareness
```sql
-- Set query tag for cost tracking
ALTER SESSION SET QUERY_TAG = 'monthly-reporting-automation';

-- Estimate before running expensive queries
SELECT 
    COUNT(*) as estimated_rows,
    COUNT(*) * 0.00032 as estimated_credits -- rough estimate
FROM large_fact_table 
WHERE partition_date >= '2024-01-01';
```

## Development Workflow

### File Organization
- Save all SQL files under `sql/` directory
- Use numeric prefixes: `010_`, `020_`, `030_` (increment by 10s)
- Descriptive names: `020_monthly_sales_report.sql`
- Version revisions: `020_monthly_sales_report__v2.sql`

### Required File Headers
```sql
-- Title: Monthly Sales Performance Report
-- Intent: Calculate monthly sales metrics with YoY comparison
-- Inputs: ANALYTICS.PUBLIC.orders, ANALYTICS.PUBLIC.customers  
-- Output: monthly_sales_summary (15 columns, ~24 rows per year)
-- Assumptions: Orders table complete after T+1 day, excludes refunds
-- Validation: Row count = months in date range, revenue matches finance totals
-- Author: Data Team
-- Created: 2024-01-15
-- Modified: 2024-01-20 (added customer segmentation)

-- Warehouse: Use MEDIUM_WH for full historical analysis
-- Query tag: monthly-reporting
```

### Validation Requirements
Every query should include verification steps:
- **Row count checks**: Expected vs actual record counts
- **Uniqueness tests**: Primary key constraints validation  
- **Null handling**: Explicit handling of NULL values
- **Cross-validation**: Compare against known control datasets
- **Time bounds**: Verify date ranges align with requirements

## Environment-Specific Practices

### Development
- Use `DEV_` prefixed warehouses and databases
- Include `_tmp` or `_dev` in temporary object names
- Test with small data samples using `SAMPLE(1000 ROWS)`

### Production
- Require code review for schema changes
- Use automated deployment scripts
- Monitor query performance and costs
- Set up alerting for long-running or expensive queries

### Documentation Standards
- Update `docs/memory.md` for any new metrics or business logic
- Document data lineage for complex transformations
- Maintain data dictionary for key business terms
- Record known data quality issues and workarounds
