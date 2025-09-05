# [Project Name] - Data Analysis Project

A Snowflake analytics project with clean separation between reusable utilities and project-specific analysis code.

## 🎯 Project Overview

**Status:** 🚧 In Development  
**Start Date:** [Date]  
**Goal:** [Brief description of project objectives]

### Objectives
- [ ] [Primary objective 1]
- [ ] [Primary objective 2]  
- [ ] [Primary objective 3]

## 📁 Project Structure (EXPLICIT: Global vs Project)

```
project_folder/
├── 🌐 GLOBAL UTILITIES (symlinked, shared across projects)
│   ├── utils/                   # Global utility modules
│   │   ├── sf_client.py        # → ../global_snowflake_utils/src/sf_client.py
│   │   └── sf_utils.py         # → ../global_snowflake_utils/src/sf_utils.py
│   └── global_scripts/          # Global utility scripts
│       ├── test_connection.py  # → ../global_snowflake_utils/scripts/test_connection.py
│       ├── run_sql.py          # → ../global_snowflake_utils/scripts/run_sql.py
│       ├── setup_check.py      # → ../global_snowflake_utils/scripts/setup_check.py
│       ├── profile_table.py    # → ../global_snowflake_utils/scripts/profile_table.py
│       ├── query_cost_estimator.py  # → ../global_snowflake_utils/scripts/query_cost_estimator.py
│       └── monitor_queries.py  # → ../global_snowflake_utils/scripts/monitor_queries.py
├── 🎯 PROJECT-SPECIFIC CODE
│   ├── project/                 # Project-specific Python modules
│   │   └── __init__.py         # Python package init (ready for your modules)
│   ├── scripts/                 # Project-specific scripts
│   │   └── [your scripts here] # Command-line tools for this project
│   ├── sql/                     # Project-specific SQL files
│   │   └── [your queries here] # Analysis queries with numeric prefixes
│   ├── docs/                    # Project documentation
│   │   └── memory.md           # Project memory and decisions
│   └── logs/                   # Daily progress logs
├── 📄 CONFIGURATION
│   ├── .gitignore              # Git ignore patterns
│   ├── requirements.txt        # Python dependencies
│   └── README.md              # This file
```

## 🚀 Getting Started

### 1. Initial Setup (Global Utilities)
```bash
# Test your Snowflake connection
python global_scripts/test_connection.py

# Verify setup is complete
python global_scripts/setup_check.py
```

### 2. Execute SQL Analysis (Global Tools)
```bash
# Run any SQL file using global script
python global_scripts/run_sql.py sql/your_analysis.sql

# Estimate costs before running expensive queries
python global_scripts/query_cost_estimator.py sql/expensive_query.sql

# Monitor recent query performance
python global_scripts/monitor_queries.py --hours 4

# Profile a table for data quality
python global_scripts/profile_table.py DATABASE.SCHEMA.TABLE_NAME
```

### 3. Project-Specific Development
```bash
# Create your analysis modules in project/
# Example: project/analysis.py, project/metrics.py

# Create your command-line scripts in scripts/
# Example: scripts/run_analysis.py, scripts/generate_report.py

# Create your SQL queries in sql/
# Example: sql/010_data_exploration.sql, sql/020_main_analysis.sql
```

### 📝 Where to Put Your Code

#### ✅ PROJECT-SPECIFIC CODE GOES HERE:
- **`project/`** - Your custom Python modules and classes
  - Example: `project/analysis.py`, `project/metrics.py`
- **`scripts/`** - Your project-specific command-line scripts  
  - Example: `scripts/run_analysis.py`, `scripts/generate_report.py`
- **`sql/`** - Your project-specific SQL queries and analysis
  - Example: `sql/010_data_exploration.sql`, `sql/020_main_analysis.sql`

#### 🌐 GLOBAL UTILITIES (DON'T MODIFY):
- **`utils/`** - Symlinked global utility modules (read-only)
- **`global_scripts/`** - Symlinked global scripts (read-only)

#### 📊 TYPICAL WORKFLOW:
1. Write SQL analysis in `sql/` folder (numeric prefixes: 010_, 020_, 030_)
2. Create Python analysis functions in `project/` folder  
3. Create command-line scripts in `scripts/` folder
4. Use global utilities from `utils/` and `global_scripts/` as needed

## 🔧 Environment Setup

Create a `.env` file with your Snowflake credentials:
```bash
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user@domain.com
SNOWFLAKE_ROLE=your_role
SNOWFLAKE_WAREHOUSE=your_warehouse
SNOWFLAKE_DATABASE=your_database
SNOWFLAKE_SCHEMA=your_schema
SNOWFLAKE_AUTHENTICATOR=externalbrowser
```

## 📊 SQL Development Guidelines

Following MDC (Modern Data Center) best practices:

### File Naming Convention
- Use numeric prefixes: `010_`, `020_`, `030_` (increments of 10)
- Descriptive names: `020_user_behavior_analysis.sql`
- Add `__v2` for revisions or date suffixes

### SQL Header Template
```sql
-- Title: <short description>
-- Intent: <what the query answers>
-- Inputs: <tables/views used>
-- Output: <fields and meaning>
-- Assumptions: <assumptions or limitations>
-- Validation: <how to verify correctness>
```

### Best Practices
- SQL keywords in **UPPERCASE**
- Identifiers in `snake_case`
- Use **fully qualified names** for shared objects
- Avoid `SELECT *` in production
- Use **CTEs** with clear comments
- Document timezone and metric definitions

## 🔗 Related Resources

- **[Global Utilities Documentation](../global_snowflake_utils/README.md)**: Comprehensive guide to shared utilities
- **[Project Memory](docs/memory.md)**: Project-specific documentation and decisions
- **[Daily Logs](logs/)**: Progress tracking and milestone documentation

## 📈 Project Status

✅ **Status**: Structure Complete - Ready for Knowledge Transfer

### Current Phase
- ✅ Project structure fully established with explicit global vs project separation
- ✅ Global utilities architecture implemented via symlinks
- ✅ Snowflake knowledge base foundation created
- ✅ English-only output policy established
- ✅ Clean project environment ready for development
- 🔄 **Awaiting comprehensive Snowflake knowledge document from user**

### Completed Restructuring (August 26, 2025)
1. ✅ Created `/global_snowflake_utils/` master utilities repository
2. ✅ Established explicit folder structure: `utils/`, `global_scripts/` (global) vs `project/`, `scripts/`, `sql/` (project-specific)
3. ✅ Built knowledge base framework: `table_reference.md`, `query_patterns.md`, `business_logic.md`
4. ✅ Implemented "start project" cleaning protocol
5. ✅ Connected all utilities via symlinks for shared access

### Next Steps (Ready to Execute)
1. **Receive comprehensive Snowflake knowledge document**
2. **Populate knowledge base** with table definitions, query patterns, business logic
3. **Database exploration** using global utilities to validate and learn
4. **Interactive Q&A** to clarify business rules and edge cases
5. **Begin project-specific analysis development**

---

> 📝 **Note**: This project uses the **global utilities** approach for Snowflake analytics. All core tools and utilities are shared via symlinks, while project-specific analysis code lives in dedicated folders for clean separation and maintainability.