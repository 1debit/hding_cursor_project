# Project Memory

> Purpose: Long-term memory for this project. Combine goals, context, definitions, and key decisions.

## 🎯 Project Overview

**Project Name:** [Your Project Name Here]
**Start Date:** [Date]
**Goal:** [Brief description of what this project aims to accomplish]

## 📊 Project Objectives

### Primary Goals
- [ ] [Primary objective 1]
- [ ] [Primary objective 2]
- [ ] [Primary objective 3]

### Success Metrics
- **Metric 1:** [Definition and target]
- **Metric 2:** [Definition and target]
- **Metric 3:** [Definition and target]

## 🏗️ Technical Architecture

### Data Sources
- **Source 1:** [Database.Schema.Table - Purpose]
- **Source 2:** [Database.Schema.Table - Purpose]

### Key Tables & Fields
```sql
-- Primary data source
DATABASE.SCHEMA.TABLE_NAME
├── field_1          -- Description
├── field_2          -- Description
└── field_3          -- Description
```

### Analysis Approach
1. **Phase 1:** [Description]
2. **Phase 2:** [Description]
3. **Phase 3:** [Description]

## 🔍 Key Definitions

### Business Metrics
- **[Metric Name]:** [Definition, calculation, business meaning]
- **[Metric Name]:** [Definition, calculation, business meaning]

### Time Periods
- **Analysis Window:** [Time range being analyzed]
- **Baseline Period:** [Reference period for comparison]
- **Cohort Definition:** [How users/events are grouped]

## 📝 Key Decisions & Assumptions

### Technical Decisions
- **[Decision 1]:** [Rationale and impact]
- **[Decision 2]:** [Rationale and impact]

### Business Assumptions
- **[Assumption 1]:** [Description and validation approach]
- **[Assumption 2]:** [Description and validation approach]

## 🚧 Development Progress

### Completed
- [ ] [Task 1 - Date completed]
- [ ] [Task 2 - Date completed]

### In Progress
- [ ] [Current task]

### Planned
- [ ] [Future task 1]
- [ ] [Future task 2]

## 📈 Key Findings (Update as you discover)

### Insights
- **[Finding 1]:** [Description and implications]
- **[Finding 2]:** [Description and implications]

### Validation Results
- **Data Quality:** [Assessment of data quality issues]
- **Methodology:** [Validation of analytical approach]

## 🎯 Business Impact

### Quantified Results
- **[Impact 1]:** [Quantified business impact]
- **[Impact 2]:** [Quantified business impact]

### Strategic Implications
- **[Implication 1]:** [Strategic meaning and recommendations]
- **[Implication 2]:** [Strategic meaning and recommendations]

## 📚 References & Resources

### Documentation
- [Internal documentation links]
- [External references]

### Related Projects
- [Previous/related analysis projects]
- [Dependencies or follow-up projects]

---

## 🤖 AI ASSISTANT CRITICAL RULES

### SQL Development
- Always use numeric prefixes (010_, 020_, 030_) for SQL files
- Follow MDC standards: UPPERCASE keywords, snake_case identifiers
- Include complete file headers with Intent/Inputs/Outputs/Assumptions/Validation
- Use fully qualified table names (DATABASE.SCHEMA.TABLE)

### Analysis Standards  
- Document all assumptions and limitations
- Validate data quality before analysis
- Use clear variable definitions and business logic
- Provide verification steps for key metrics

### Code Organization
- **`project/`** - Custom Python modules and business logic
- **`scripts/`** - Command-line executables and entry points  
- **`sql/`** - Project-specific SQL analysis files
- **`utils/` & `global_scripts/`** - Global utilities (don't modify)

### Project Memory Updates
- Update this document as decisions are made
- Document key findings and methodology choices
- Track business impact and strategic implications
- Maintain clear definitions throughout the project