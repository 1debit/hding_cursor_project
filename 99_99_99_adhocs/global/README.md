
# Global Snowflake Utilities

This directory contains reusable Snowflake utilities and scripts that can be shared across multiple projects.

## Structure

```
global_snowflake_utils/
├── src/                          # Core utility modules
│   ├── sf_client.py             # Snowflake connection client
│   └── sf_utils.py              # Advanced Snowflake operations
├── scripts/                      # Utility scripts
│   ├── test_connection.py       # Test Snowflake connection
│   ├── setup_check.py           # Verify setup and configuration
│   ├── run_sql.py               # Execute SQL files
│   ├── monitor_queries.py       # Query monitoring and performance
│   ├── query_cost_estimator.py  # Query cost estimation
│   └── profile_table.py         # Table profiling and data quality
├── docs/                        # Documentation
├── requirements.txt             # Python dependencies
└── README.md                    # This file
```

## Usage

### Setting up a new project

1. Copy the `src/` directory to your new project
2. Copy the specific scripts you need from `scripts/`
3. Copy `requirements.txt` and install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

### Core Components

#### sf_client.py
- Provides `get_connection()` for standard Snowflake connections
- Supports external browser authentication (SSO/OKTA)
- Uses environment variables for configuration

#### sf_utils.py
- `SnowflakeUtils` class with advanced operations
- Table profiling, data quality checks, lineage analysis
- Query execution with pandas integration

### Utility Scripts

#### test_connection.py
Test your Snowflake connection:
```bash
python scripts/test_connection.py
```

#### setup_check.py
Verify project setup and configuration:
```bash
python scripts/setup_check.py
python scripts/setup_check.py --skip-connection
```

#### run_sql.py
Execute SQL files:
```bash
python scripts/run_sql.py sql/my_query.sql
```

#### monitor_queries.py
Monitor query performance:
```bash
python scripts/monitor_queries.py
python scripts/monitor_queries.py --expensive --hours 24
python scripts/monitor_queries.py --slow --min-credits 0.1
```

#### query_cost_estimator.py
Estimate query costs:
```bash
python scripts/query_cost_estimator.py sql/expensive_query.sql
python scripts/query_cost_estimator.py sql/query.sql --warehouse LARGE
```

#### profile_table.py
Profile table data quality:
```bash
python scripts/profile_table.py DATABASE.SCHEMA.TABLE_NAME
python scripts/profile_table.py DATABASE.SCHEMA.TABLE_NAME --sample-size 10000
```

## Environment Setup

Create a `.env` file in your project with:
```bash
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user@domain.com
SNOWFLAKE_ROLE=your_role
SNOWFLAKE_WAREHOUSE=your_warehouse
SNOWFLAKE_DATABASE=your_database
SNOWFLAKE_SCHEMA=your_schema
SNOWFLAKE_AUTHENTICATOR=externalbrowser
```

## Dependencies

- snowflake-connector-python
- snowflake-sqlalchemy
- pandas
- python-dotenv
- cryptography
- matplotlib (for visualization scripts)

## Best Practices

1. Always use environment variables for credentials
2. Test connection before running complex queries
3. Use cost estimation for expensive operations
4. Profile tables before analysis
5. Monitor query performance regularly
