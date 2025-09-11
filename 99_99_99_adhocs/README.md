# Adhoc Analysis Workspace

> **Purpose**: Centralized workspace for multiple adhoc data analysis projects with shared knowledge base and utilities.

## 📁 Folder Structure & Purpose

### Core Analysis Folders
- **`projects/`** - Individual project folders with date prefix (YYYY_MM_DD_description)
  - Each project contains: `docs/memory.md`, `sql/`, `scripts/`, `files/`, `outputs/`
  - Example: `projects/2025_09_02_tpi_mumuplay_emulator/`

### Global Resources
- **`global/`** - **PROTECTED** - All global resources, knowledge, and utilities
  - `knowledge_base/` - Business domain knowledge, table structures, query patterns
    - `table_reference.md` - Core tables and field definitions
    - `query_patterns.md` - Reusable SQL patterns and examples
    - `business_logic.md` - Business rules and calculations
    - `QUICK_LOOKUP.md` - Fast reference for common queries
    - `SEARCH_INDEX.md` - Comprehensive search index
  - `shared/` - Cross-project utilities and scripts
    - `scripts/` - Reusable Python scripts (symlinked to global)
    - `utils/` - Utility modules (symlinked to global)
  - `README.md` - Global resources overview and usage guide

### Cloned Repositories
- **`cloned/`** - **PROTECTED** - Reference repositories for learning
  - `Adhoc_SQL/` - Historical SQL queries and patterns
  - `chime-tf/` - Infrastructure as code and table definitions
  - `ml_workflows/` - Feature library and ML workflows
  - `Policy_Dev/` - Risk strategy simulation and policy development

### Configuration & Logs
- **`.cursor/`** - **PROTECTED** - AI assistant rules and configurations
- **`logs/`** - Global session logs and progress tracking
- **`memory.md`** - Global memory for cross-project standards and learnings

## 🛡️ Protection Protocol

### CRITICAL: Essential Folders
**NEVER DELETE OR MODIFY WITHOUT EXPLICIT PERMISSION:**
- `knowledge_base/` - Contains months of accumulated business knowledge
- `projects/` - Contains all project work and analysis
- `shared/` - Contains reusable utilities and scripts
- `cloned/` - Contains reference repositories
- `.cursor/` - Contains AI assistant rules

### File Operations Safety
- **NEVER use `git reset --hard`** without explicit user permission
- **ALWAYS backup important files** before destructive operations
- **Ask user before any git reset operations**
- **Use non-destructive methods** when possible

## 🚀 Project Workflow

### Starting a New Project
1. Create project folder: `projects/YYYY_MM_DD_project_name/`
2. Set up standard structure: `docs/`, `sql/`, `scripts/`, `files/`, `outputs/`
3. Initialize `docs/memory.md` with project context
4. Update global `memory.md` with new learnings

### Working on Existing Project
1. Navigate to project directory: `cd projects/PROJECT_NAME`
2. Review project memory and current status
3. Ask clarifying questions about objectives
4. Continuously update knowledge base with new learnings

### Knowledge Base Updates
When user says "save to log" or new information is learned:
1. Update project memory with SQL/script file explanations
2. Update global knowledge base files
3. Update quick lookup files
4. Clean up unnecessary files
5. Document new learnings in appropriate sections

## 📊 Current Projects

### Active Projects
- **2025_09_02_tpi_mumuplay_emulator** - TPI case study analyzing MuMuPlayer emulator fraud patterns

### Project Templates
- Each project follows standard structure with numbered SQL files (010_, 020_, etc.)
- Comprehensive documentation in `docs/memory.md`
- Clear separation of SQL, scripts, files, and outputs
- README.md for project summary and status

## 🔧 Technical Standards

### SQL Development
- Use numeric prefixes (010_, 020_, 030_) for logical flow
- Follow MDC standards: UPPERCASE keywords, snake_case identifiers
- Include complete file headers with Intent/Inputs/Outputs/Assumptions/Validation
- Use fully qualified table names (DATABASE.SCHEMA.TABLE)

### Python Analysis
- Store business logic in `project/` modules
- Store command-line scripts in `scripts/`
- Use global utilities from `shared/` and `utils/`
- Follow Black formatting and type hints

### Documentation
- Document all assumptions and limitations
- Validate data quality before analysis
- Use clear variable definitions and business logic
- Provide verification steps for key metrics

## 📚 Knowledge Base Contents

### Table Reference
- Core Chime tables with schemas and relationships
- Field definitions and data types
- Common aliases and usage patterns
- SQL examples for each table

### Query Patterns
- Reusable SQL patterns for common analysis tasks
- Performance optimization techniques
- Data quality validation patterns
- Business logic implementations

### Business Logic
- Risk scoring models and calculations
- Dispute rate logic and thresholds
- Feature engineering patterns
- Data validation rules

## 🎯 Best Practices

### Data Analysis Workflow
1. **Understand**: Clarify business question and success metrics
2. **Explore**: Check data completeness and quality first
3. **Prepare**: Clean data, handle missing values, create derived features
4. **Analyze**: Apply statistical methods with proper categorization
5. **Validate**: Cross-check findings, test with sample data
6. **Communicate**: Create clear visualizations with descriptive titles

### Error Prevention
- Test with small samples before full analysis
- Validate data completeness with MAX/MIN checks
- Explicit column listing to avoid conflicts
- Safe JSON parsing with TRY_PARSE_JSON
- Comprehensive categories in CASE statements
- Backup before destructive operations

### MOB Categorization Standards
**CRITICAL**: Always use these categories for MOB analysis:
- `0` (new users)
- `1-3` (1-3 months)
- `4-6` (4-6 months)
- `7-12` (7-12 months)
- `12+` (12+ months)

**NEVER exclude any users by default** - always include the 12+ category to capture all users.

## 🔄 Maintenance

### Regular Updates
- Update knowledge base with new learnings
- Clean up temporary files and cache directories
- Maintain project documentation
- Archive completed projects

### Backup Strategy
- All essential folders are protected
- Git history preserved for recovery
- Knowledge base is sacred and irreplaceable
- User data is precious - treat as irreplaceable

---

**Last Updated**: 2025-09-08
**Status**: Active workspace with comprehensive knowledge base and project management system
