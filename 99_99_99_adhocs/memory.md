# Global Memory & Standards

## Project Memory Structure & Standards

### File Locations
- **Global Memory**: `memory.md` (root level) - Cross-project knowledge and standards
- **Project Memory**: `projects/PROJECT_NAME/docs/memory.md` - Project-specific context and findings

### Content Structure
- **Global Memory**: Standards, best practices, reusable patterns, cross-project learnings
- **Project Memory**: Project objectives, key discoveries, technical decisions, useful queries, business impact

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

### CRITICAL: Git Operations Safety
- **NEVER use `git reset --hard`** without explicit user permission - this DESTROYS files permanently
- **ALWAYS backup important files** before any destructive git operations
- **Ask user before any git reset operations** - even if trying to fix push issues
- **Use `git reset --soft` or `git checkout`** instead of hard resets when possible
- **If files are lost, immediately check `git reflog`** to find recovery commit
- **User's data is PRECIOUS** - treat every file as irreplaceable until confirmed otherwise

## Project Workflow Protocol

When starting work on a specific project:
1. Change to project directory: `cd projects/PROJECT_NAME`
2. Provide project summary and current status
3. Ask clarifying questions about objectives
4. Continuously update root knowledge base with new learnings
5. Follow the established file structure and naming conventions
