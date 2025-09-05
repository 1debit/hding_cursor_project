# Shared Resources Directory

This directory contains all cross-project shared resources and utilities.

## Purpose
- Centralize all shared resources in one location
- Provide both executable scripts and importable utility modules
- Maintain shared templates and configurations

## Structure
```
shared/
├── scripts/                    # Executable Python scripts (symlinked)
│   ├── run_sql.py             # Execute SQL files
│   ├── monitor_queries.py     # Query monitoring utilities
│   ├── profile_table.py       # Table profiling tools
│   ├── query_cost_estimator.py # Query cost estimation
│   ├── setup_check.py         # Environment setup verification
│   └── test_connection.py     # Database connection testing
└── utils/                      # Python utility modules (symlinked)
    ├── sf_client.py           # Snowflake client utilities
    └── sf_utils.py            # Snowflake helper functions
```

## Usage

### Executable Scripts (`shared/scripts/`)
- Run directly from command line
- Example: `python shared/scripts/run_sql.py my_query.sql`

### Utility Modules (`shared/utils/`)
- Import in Python code
- Example: `from shared.utils import sf_client`

## Relationship to Global Resources
- **`knowledge_base/`** - Global data knowledge and table references
- **`shared/`** - This directory for all shared utilities and resources
- **`.cursor/rules/`** - AI behavior rules and coding standards

## Benefits
- **Simplified Structure**: One location for all shared resources
- **Clear Separation**: Scripts vs modules clearly organized
- **Easy Access**: All shared functionality in `shared/` directory
- **Consistent Naming**: Clear distinction between executable and importable code

---

*This directory provides comprehensive shared functionality across all adhoc analysis projects.*
