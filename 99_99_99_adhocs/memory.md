# Global Memory & Standards

## Project Memory Structure & Standards

### File Locations
- **Global Memory**: `memory.md` (root level) - Cross-project knowledge and standards
- **Project Memory**: `projects/PROJECT_NAME/docs/memory.md` - Project-specific context and findings

### Content Structure
- **Global Memory**: Standards, best practices, reusable patterns, cross-project learnings
- **Project Memory**: Project objectives, key discoveries, technical decisions, useful queries, business impact

## Workspace Organization (Updated 2025-09-08)

### Root Folder Structure
- **`projects/`** - Individual project folders with date prefix (YYYY_MM_DD_description)
- **`global/`** - **PROTECTED** - All global resources, knowledge, and utilities
  - `global/knowledge_base/` - Business domain knowledge, table structures, query patterns
  - `global/shared/` - Cross-project utilities and scripts (symlinked to global)
- **`cloned/`** - **PROTECTED** - Reference repositories for learning (Adhoc_SQL, chime-tf, ml_workflows, Policy_Dev)
- **`logs/`** - Global session logs and progress tracking
- **`memory.md`** - Global memory for cross-project standards and learnings
- **`README.md`** - Comprehensive workspace documentation and folder purposes

### Memory File Clarification
- **Root `memory.md`**: Global standards, best practices, cross-project learnings, workflow protocols
- **Project `docs/memory.md`**: Project-specific context, objectives, discoveries, technical decisions
- **No duplication**: Each serves distinct purposes, both are essential

## SQL Query Optimization - Production Best Practices

### Dispute Rate Calculation Optimization (2025-01-15)
**Key Learnings from Production SQL Optimization:**
1. **Simplified Deduplication**: Use `QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id, authorization_code ORDER BY dispute_created_at DESC) = 1` instead of complex unique_transaction_id matching - authorization_code is more commonly available and reliable
2. **Streamlined Calculation**: Use single aggregation `sum(case when dd.user_id is not null then cnt.settled_amt*-1 else 0 end)/nullifzero(sum(cnt.settled_amt*-1))` instead of multiple CTEs - much faster and cleaner
3. **Amount Normalization**: Use `*-1` to convert negative settled amounts to positive for easier calculation
4. **NULLIFZERO()**: Use Snowflake's NULLIFZERO() function to prevent division by zero errors elegantly
5. **Direct Join Logic**: Link transactions to disputes via authorization_code rather than complex transaction ID matching
6. **Performance Focus**: Production SQL should prioritize clean, efficient code over over-engineering - fewer CTEs, direct aggregation, practical field usage

**Pattern**: Always prefer simple, readable solutions that use commonly available fields and single-step calculations over complex multi-CTE approaches.

## Knowledge Base Update Protocol

When user says "save to log" or new information is learned:
1. Update project memory with SQL/script file explanations
2. Update global knowledge base files (table_reference.md, query_patterns.md, business_logic.md)
3. Update quick lookup files (QUICK_LOOKUP.md, SEARCH_INDEX.md)
4. Clean up unnecessary files (experimental SQL, cache directories, temporary scripts)
5. Document new learnings in appropriate knowledge base sections

## MOB (Month on Book) Categorization Standards

**CRITICAL**: When analyzing MOB distributions, always use these categories:
- `0` (new users)
- `1-3` (1-3 months)
- `4-6` (4-6 months)
- `7-12` (7-12 months)
- `12+` (12+ months)

**NEVER exclude any users by default** - always include the 12+ category to capture all users. Missing categories can significantly distort percentage calculations and lead to incorrect conclusions in fraud analysis.

If unsure about categorization, ask the user for clarification.

## Key Project Takeaways for Future Analysis

### Data Completeness is Critical
- **Always verify data completeness** before drawing conclusions
- **Missing categories can completely distort findings** (e.g., excluding 12+ MOB users made new user percentages artificially inflated)
- **Ask clarifying questions** when data seems incomplete or suspicious

### Fraud Pattern Analysis Best Practices
- **Network carrier vs IP country mismatch** is a strong emulator indicator
- **New user concentration patterns** can reveal fraud (e.g., 67% new users vs 9% normal)
- **Cross-reference multiple data sources** (login data + device intelligence + user status)
- **Look for statistical anomalies** that don't match normal user behavior

### SQL Query Development Lessons
- **Test with small samples first** before running on large datasets
- **Always include comprehensive categories** in CASE statements
- **Validate data completeness** with MAX/MIN checks before analysis
- **Use CTEs for complex logic** to improve readability and debugging

### Data Quality and Validation
- **Check for case sensitivity** in string matching (`'Mapped'` vs `'mapped'`)
- **Verify column existence** before referencing (e.g., `a.continent` didn't exist)
- **Test joins with sample data** before full table operations
- **Always include data quality checks** in analysis workflows

### CRITICAL: Git Operations Safety & Data Protection
- **NEVER use `git reset --hard`** without explicit user permission - this DESTROYS files permanently
- **ALWAYS backup important files** before any destructive git operations
- **Ask user before any git reset operations** - even if trying to fix push issues
- **Use `git reset --soft` or `git checkout`** instead of hard resets when possible
- **If files are lost, immediately check `git reflog`** to find recovery commit
- **User's data is PRECIOUS** - treat every file as irreplaceable until confirmed otherwise

### CRITICAL: Core Folder Protection Protocol
**NEVER DELETE OR MODIFY THESE CORE FOLDERS WITHOUT EXPLICIT PERMISSION:**
- `global/` - Contains all global resources, knowledge base, and shared utilities
- `projects/` - Contains all project work and analysis
- `.cursor/` - Contains AI assistant rules and configurations
- `cloned/` - Contains reference repositories

**Before ANY operation that might affect these folders:**
1. **Ask explicit permission** from user
2. **Create backup** if operation is risky
3. **Use non-destructive methods** when possible
4. **Test on small scope** before applying broadly

**Knowledge Base is SACRED** - it contains months of accumulated business knowledge that cannot be easily recreated

### CRITICAL: Project Directory Context Protocol
**ALWAYS remember directory context when working on projects:**
- **Project-specific files** are under `projects/PROJECT_NAME/`
- **When in project directory**: Use relative paths like `docs/memory.md`, `sql/file.sql`, `scripts/script.py`
- **When in workspace root**: Use full paths like `projects/PROJECT_NAME/docs/memory.md`
- **Global files** (like root `memory.md`) are accessed from workspace root
- **Project memory** is at `projects/PROJECT_NAME/docs/memory.md`
- **This prevents confusion and "file not found" errors**

## TPI MuMuPlayer Emulator Project: Complete Lessons Learned

### Project Overview
**Project**: TPI Case Study - MuMuPlayer Emulator Detection (2025-09-02)
**Objective**: Analyze emulator fraud patterns through network carrier vs IP country mismatches
**Key User**: 86963958 (identified via Penny chimesign lookup)
**Critical Discovery**: Taiwan network carriers with USA IP addresses = strong emulator indicator

### Major Challenges & Solutions

#### 1. **Data Completeness Crisis**
- **Problem**: MOB analysis excluded 12+ months users, causing 3x inflation in new user percentages
- **Impact**: US 0 months showed 27.6% (wrong) vs 9.1% (correct)
- **Solution**: Always include comprehensive categories (0, 1-3, 4-6, 7-12, 12+)
- **Learning**: Missing categories can completely distort findings - validate data completeness first

#### 2. **Network Carrier Mapping Complexity**
- **Problem**: 700+ network carriers needed country code mapping
- **Failed Approaches**:
  - Limited SQL CASE statements (too few carriers)
  - Python web scraping script (connection issues)
- **Successful Solution**: AI-assisted research + manual CSV mapping (315 carriers)
- **Learning**: For large-scale mapping, combine AI research with manual validation

#### 3. **SQL Query Development Issues**
- **Problem**: Multiple SQL statements in single API call errors
- **Solution**: Split into separate files, test individually
- **Problem**: Column conflicts (`a.*` vs explicit columns)
- **Solution**: Always explicitly list columns to avoid conflicts
- **Problem**: JSON parsing errors in Snowflake
- **Solution**: Use `TRY_PARSE_JSON()` for safe JSON handling

#### 4. **Git Operations Disaster**
- **Problem**: Used `git reset --hard` without permission, destroyed project files
- **Recovery**: Used `git reflog` to find files in commit `1e6ab90`, restored with `git checkout`
- **Learning**: NEVER use destructive git operations without explicit user permission

#### 5. **GitHub Push Failures**
- **Problem**: Large files (2.1MB Excel) causing push failures
- **Solution**: Updated .gitignore to allow files up to 1GB, excluded problematic large files
- **Learning**: Check file sizes before pushing, use .gitignore strategically

### Technical Discoveries & New Knowledge

#### **Snowflake Table Structures Learned**
- `chime.finance.members`: Primary user table, `id` field needs `::varchar` casting for joins
- `chime.decision_platform.base_user_fields`: User-level card activation and payroll DD indicators
- `STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE`: Darwinium device intelligence
- `chime.decision_platform.authn`: Login authentication events with outcomes

#### **SQL Patterns Mastered**
- **JSON Parsing**: `TRY_PARSE_JSON(body):step_name::varchar` for safe JSON access
- **MOB Calculation**: `DATEDIFF(month, account_creation_date, login_date)`
- **User Status Joins**: `m.id::varchar` for chime.finance.members joins
- **Deduplication**: `QUALIFY ROW_NUMBER() OVER (PARTITION BY key ORDER BY timestamp DESC) = 1`

#### **Fraud Detection Patterns**
- **Network vs IP Mismatch**: Taiwan network + USA IP = emulator indicator
- **MOB Patterns**: 67% new users (Taiwan) vs 9% (US) = suspicious
- **Device Intelligence**: Low DWN coverage for foreign carriers = risk signal
- **User Status**: High inactive rates for foreign carriers = fraud indicator

### Workflow Improvements

#### **Project Organization**
- **File Structure**: Clear separation of SQL, scripts, files, outputs, docs
- **Naming Convention**: Numbered SQL files (010_, 020_, etc.) for logical flow
- **Documentation**: README.md for project summary, memory.md for detailed context
- **Cleanup Protocol**: Remove temporary files, keep only essential deliverables

#### **Data Analysis Process**
1. **Understand**: Clarify business question and success metrics
2. **Explore**: Check data completeness and quality first
3. **Prepare**: Clean data, handle missing values, create derived features
4. **Analyze**: Apply statistical methods with proper categorization
5. **Validate**: Cross-check findings, test with sample data
6. **Communicate**: Create clear visualizations with descriptive titles

#### **Error Prevention Strategies**
- **Test with small samples** before full analysis
- **Validate data completeness** with MAX/MIN checks
- **Explicit column listing** to avoid conflicts
- **Safe JSON parsing** with TRY_PARSE_JSON
- **Comprehensive categories** in CASE statements
- **Backup before destructive operations**

### Business Impact Achieved
- **Detection Method**: Network carrier vs IP country mismatch validated as emulator signal
- **Case Review Framework**: Systematic approach for identifying emulator users
- **Prevention Strategy**: Enhanced detection methodology for future fraud attempts
- **Data Infrastructure**: Reusable login analysis framework for ongoing monitoring

### Key Metrics Discovered
- **US Network Carrier**: 9.1% new users, 67.1% established (healthy pattern)
- **Taiwan Network Carrier**: 67.2% new users, 12.9% established (suspicious pattern)
- **Taiwan Inactive Users**: 79.4% new users (extremely suspicious)
- **DWN Coverage**: Low mapping rates for foreign carriers (risk indicator)

### Future Project Standards
- **Always validate data completeness** before analysis
- **Use comprehensive categorization** (never exclude categories by default)
- **Test with small samples** before full operations
- **Ask permission** before any destructive operations
- **Document everything** in project memory for future reference
- **Create reusable patterns** for common analysis tasks

## Project Workflow Protocol

When starting work on a specific project:
1. Change to project directory: `cd projects/PROJECT_NAME`
2. Provide project summary and current status
3. Ask clarifying questions about objectives
4. Continuously update root knowledge base with new learnings
5. Follow the established file structure and naming conventions

## Knowledge Base Management & Recovery (2025-09-08)

### Knowledge Base Structure
- **Location**: `global/knowledge_base/` (consolidated from scattered locations)
- **Core Files**:
  - `table_reference.md` - Snowflake table definitions and relationships
  - `query_patterns.md` - Reusable SQL patterns and best practices
  - `business_logic.md` - Business rules, calculations, and definitions
  - `QUICK_LOOKUP.md` - Fast access to most common information
  - `SEARCH_INDEX.md` - Comprehensive searchable index
  - `README.md` - Knowledge base overview and usage guide

### Recovery Process Lessons
- **Git History Recovery**: Used `git reflog` to find lost files in commit `1e6ab90`
- **File Restoration**: `git checkout <commit_hash> -- <file_path>` to restore specific files
- **Cleanup Strategy**: Remove non-recovered files, rename recovered files to proper names
- **Validation**: Always verify file completeness before cleanup operations

### Knowledge Base Protection Rules
- **NEVER delete** knowledge base files without explicit user permission
- **Always backup** before any cleanup operations
- **Preserve recovered files** - they contain comprehensive accumulated knowledge
- **Clean naming**: Remove "_recovered" suffixes after verification
- **Maintain structure**: Keep all core files (table_reference, query_patterns, business_logic, etc.)

### File Management Best Practices
- **Recovery First**: Always attempt recovery before recreation
- **User Teaching**: Knowledge base built through user teaching - cannot be recreated independently
- **Comprehensive Content**: Recovered files contain more complete information than original versions
- **Systematic Cleanup**: Remove duplicates, rename properly, maintain clean structure

### Critical Learning: Knowledge Base is Sacred
The knowledge base represents months of accumulated business domain knowledge, table relationships, and proven query patterns. It cannot be easily recreated and must be protected at all costs. When files are lost, recovery from git history is the preferred approach over recreation.

## Shared Utilities Recovery & Management (2025-09-08)

### Broken Symlinks Diagnosis & Resolution
- **Problem**: `global/shared/` folder contained broken symlinks pointing to missing `global_snowflake_utils` folder
- **Symptoms**:
  - `ModuleNotFoundError: No module named 'src'` when importing
  - `No such file or directory` when accessing symlinked files
  - Scripts failing with connection errors
- **Root Cause**: Missing `global_snowflake_utils` folder that symlinks were pointing to

### Recovery Process from GitHub Repository
1. **Locate Source Repository**: Found working files at https://github.com/1debit/hding_cursor_project/tree/a1cf9ecbc37e4d59e5209d3fec1af9a790e63032/global_snowflake_utils
2. **Clone Repository**: `git clone https://github.com/1debit/hding_cursor_project.git temp_repo`
3. **Checkout Specific Commit**: `git checkout a1cf9ecbc37e4d59e5209d3fec1af9a790e63032`
4. **Copy Missing Folder**: `cp -r global_snowflake_utils ../`
5. **Fix Symlink Paths**: Update relative paths from `../global_snowflake_utils/` to `../../../global_snowflake_utils/`
6. **Test Functionality**: Verify scripts work from correct directory context

### Snowflake Connection Patterns Learned
- **Working Pattern**: Run scripts from `global_snowflake_utils/` directory for proper import paths
- **Authentication**: Uses `externalbrowser` authentication with Chime SSO/OKTA integration
- **Connection Hierarchy**:
  - `sf_client.py`: Core connection with SQLAlchemy engine
  - `sf_utils.py`: Higher-level utilities with `SnowflakeUtils` class
  - `run_sql.py`: Command-line SQL execution script
- **Pandas Integration Issue**: SQLAlchemy version compatibility issues with `pd.read_sql()`
- **Workaround**: Use direct `snowflake.connector` for reliable pandas DataFrame creation

### Excel Export Best Practices
- **Timezone Handling**: Remove timezone info before Excel export using `dt.tz_localize(None)`
- **Direct Connector Approach**: Use `snowflake.connector.connect()` directly for pandas operations
- **Data Type Conversion**: Handle datetime columns explicitly to prevent Excel compatibility issues

### Working Script Pattern
```python
import snowflake.connector
import pandas as pd

# Direct connection with Chime defaults
conn_params = {
    'user': 'HAO.DING@CHIME.COM',
    'account': 'CHIME',
    'authenticator': 'externalbrowser',
    'warehouse': 'RISK_WH',
    'database': 'RISK',
    'schema': 'TEST',
    'role': 'SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA'
}

conn = snowflake.connector.connect(**conn_params)
cursor = conn.cursor()
cursor.execute(query)
results = cursor.fetchall()
columns = [desc[0] for desc in cursor.description]
df = pd.DataFrame(results, columns=columns)

# Fix timezone for Excel
for col in df.columns:
    if 'datetime' in str(df[col].dtype):
        df[col] = pd.to_datetime(df[col]).dt.tz_localize(None)

df.to_excel(output_file, index=False)
```

### Directory Context Importance
- **Critical Rule**: Scripts must be run from correct directory for imports to work
- **Working Directory**: `global_snowflake_utils/` for Snowflake utilities
- **Import Path**: Scripts expect `src/` subdirectory for imports
- **Absolute Paths**: Use absolute paths when running scripts from different directories

### Shared Folder Structure Validation
- **Expected Structure**: As documented in `global/shared/README.md`
- **Actual vs Expected**: Verify symlinks point to existing files
- **Testing Method**: `head -5 global/shared/utils/sf_client.py` should show actual code, not errors
- **Recovery Protocol**: Clone from GitHub repository when local files missing
