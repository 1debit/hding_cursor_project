# Cursor Data Analyst (Snowflake) — Best Practice Starter

A comprehensive, production-ready starter kit for Snowflake data analysis with Cursor AI. This kit implements **MDC (Modern Data Center)** best practices for SQL development, cost optimization, and security.

## 🚀 Features

### 🔧 Core Infrastructure
- **Secure connection management** with password or private key authentication
- **Environment-based configuration** with proper secrets handling
- **Comprehensive error handling** and logging throughout

### 📊 Data Analysis Tools
- **Table profiling**: Comprehensive data quality analysis and statistics
- **Query cost estimation**: Predict Snowflake costs before execution
- **Performance monitoring**: Track query performance and warehouse utilization
- **Data validation utilities**: Built-in data quality checks and validation

### 🎯 MDC Best Practices
- **Standardized SQL style**: UPPERCASE keywords, snake_case identifiers
- **Safety-first approach**: No destructive operations without confirmation
- **Cost optimization**: Warehouse sizing guidelines and query analysis
- **Documentation standards**: Required headers for all SQL files

### 🛡️ Security & Governance
- **Proper gitignore patterns** for secrets and sensitive data
- **Role-based access patterns** and least privilege principles
- **Audit trail support** with query tagging and monitoring
- **Environment separation** (DEV/TEST/PROD) guidelines

## 📁 Project Structure

```
!!cursor-analyst-snowflake-starter/
├── .cursor/rules/           # Cursor AI workspace rules (MDC standards)
├── src/                     # Reusable Python utilities
│   ├── sf_client.py        # Snowflake connection management
│   └── sf_utils.py         # Data analysis and profiling utilities
├── scripts/                 # Command-line tools
│   ├── test_connection.py  # Test Snowflake connectivity
│   ├── run_sql.py          # Execute SQL files
│   ├── profile_table.py    # Generate table profiles
│   ├── query_cost_estimator.py  # Estimate query costs
│   ├── monitor_queries.py  # Monitor query performance
│   └── setup_check.py      # Verify setup completion
├── sql/                     # SQL files (versioned with numeric prefixes)
├── docs/                    # Project documentation and memory
├── .env.example            # Environment configuration template
├── .gitignore              # Git ignore patterns for security
└── requirements.txt        # Python dependencies
```

## ⚡ Quick Setup

### 1. Environment Setup
```bash
# Clone or copy this starter kit
cd !!cursor-analyst-snowflake-starter

# Create virtual environment
python -m venv .venv
source ./.venv/bin/activate   # macOS/Linux
# .\.venv\Scripts\Activate.ps1   # Windows (PowerShell)

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Snowflake Connection
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your Snowflake credentials
# Required: SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_ROLE, etc.
```

### 3. Verify Setup
```bash
# Run comprehensive setup verification
python scripts/setup_check.py

# Test Snowflake connection
python scripts/test_connection.py

# Run demo SQL
python scripts/run_sql.py sql/010_create_demo_table.sql
```

## 🛠️ Usage Examples

### Table Profiling
```bash
# Generate comprehensive table profile
python scripts/profile_table.py ANALYTICS.PUBLIC.SALES

# Large table with custom sample size
python scripts/profile_table.py ANALYTICS.PUBLIC.SALES --sample-size 10000

# Save profile to JSON
python scripts/profile_table.py ANALYTICS.PUBLIC.SALES --output profile_report.json
```

### Query Cost Estimation
```bash
# Estimate costs for a query file
python scripts/query_cost_estimator.py sql/monthly_report.sql

# Estimate for different warehouse size
python scripts/query_cost_estimator.py sql/monthly_report.sql --warehouse LARGE

# Estimate from stdin
echo "SELECT * FROM large_table" | python scripts/query_cost_estimator.py -
```

### Query Monitoring
```bash
# Monitor recent queries
python scripts/monitor_queries.py

# Show expensive queries only
python scripts/monitor_queries.py --expensive --min-credits 0.1

# Show warehouse utilization
python scripts/monitor_queries.py --warehouse-stats
```

### Python Utilities
```python
from src.sf_utils import SnowflakeUtils, quick_profile, quick_query

# Quick data exploration
df = quick_query("SELECT * FROM my_table LIMIT 100")

# Comprehensive table profiling
profile = quick_profile("ANALYTICS.PUBLIC.SALES")

# Advanced data analysis
utils = SnowflakeUtils()
duplicates = utils.find_duplicates("ANALYTICS.PUBLIC.ORDERS", ["customer_id", "order_date"])
comparison = utils.compare_tables("table_v1", "table_v2", "id")
```

## 📚 Best Practices Integration

### SQL Development with Cursor
1. **Ask Cursor to generate queries** following MDC standards
2. **Use proper SQL headers** (automatically enforced by rules)
3. **Always estimate costs** before running expensive queries
4. **Profile tables** before writing complex joins

### Cost Optimization
- Use **XS/S warehouses** for exploration and development
- **Estimate query costs** before execution with large datasets
- **Monitor query performance** regularly to identify optimization opportunities
- **Use QUALIFY** instead of DISTINCT with window functions

### Security & Governance
- **Never commit** `.env` files or credentials
- **Use private key authentication** for production environments
- **Tag all queries** with appropriate QUERY_TAG for tracking
- **Follow environment separation** practices (DEV/TEST/PROD)

## 🔧 Configuration Options

### Environment Variables (.env)
```bash
# Connection Settings
SNOWFLAKE_ACCOUNT=your_account.region.snowflakecomputing.com
SNOWFLAKE_USER=your_username
SNOWFLAKE_ROLE=ANALYST_ROLE
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=ANALYTICS
SNOWFLAKE_SCHEMA=PUBLIC

# Authentication (choose one)
SNOWFLAKE_PASSWORD=your_password
# OR
SNOWFLAKE_PRIVATE_KEY_PATH=~/.ssh/snowflake_rsa_key.p8
SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=your_passphrase

# Optional Settings
QUERY_TAG=cursor-analyst-starter
```

### Warehouse Sizing Guidelines
- **X-SMALL/SMALL**: Development, exploration, small datasets (< 1GB)
- **MEDIUM**: Regular reporting, moderate ETL (1-10GB)
- **LARGE+**: Heavy ETL, large aggregations, production workloads (> 10GB)

## 📖 Documentation

- **[Project Memory](docs/memory.md)**: Comprehensive project documentation, metrics definitions, and best practices
- **[MDC Rules](.cursor/rules/snowflake_mdc.md)**: Detailed Snowflake development standards and guidelines
- **[SQL Examples](sql/)**: Sample SQL files following best practices

## 🚨 Troubleshooting

### Common Issues
1. **Connection failures**: Check `.env` configuration and network connectivity
2. **Import errors**: Ensure virtual environment is activated and dependencies installed
3. **Permission errors**: Verify Snowflake role has necessary privileges
4. **High query costs**: Use cost estimator before running expensive operations

### Getting Help
```bash
# Verify complete setup
python scripts/setup_check.py

# Test connection with detailed output
python scripts/test_connection.py

# Check for any configuration issues
python scripts/setup_check.py --skip-connection
```

## 🎯 Next Steps

1. **Customize** `docs/memory.md` with your project-specific information
2. **Configure** your Snowflake connection in `.env`
3. **Start developing** by asking Cursor to generate SQL following MDC rules
4. **Monitor costs** regularly using the provided monitoring tools
5. **Scale up** by copying this template for new projects

---

> 💡 **Pro Tip**: This starter kit is designed as a **template repository**. For each new project, copy this folder and customize the configuration files (`docs/memory.md`, `.env`, `.cursor/rules/`) to match your specific requirements.
