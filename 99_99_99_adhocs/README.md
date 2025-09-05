# 99_99_99_adhocs - Multi-Project Adhoc Analysis Workspace

> **Purpose**: Centralized workspace for multiple adhoc data analysis projects with shared resources and project-specific organization.

## 🏗️ Folder Structure

```
99_99_99_adhocs/
├── .cursor/                    # Cursor AI rules and configurations
├── .vscode/                    # VS Code/Cursor IDE settings
├── knowledge_base/             # Global data knowledge and table references
├── shared/                     # All shared resources and utilities
│   ├── scripts/                # Executable Python scripts (symlinked)
│   └── utils/                  # Python utility modules (symlinked)
├── logs/                       # Global logs and session records
├── projects/                   # Individual project folders
│   └── YYYY_MM_DD_project_name/
│       ├── docs/               # Project-specific documentation
│       │   └── memory.md       # Project memory and context
│       ├── scripts/            # Project-specific Python scripts
│       ├── sql/                # Project-specific SQL files
│       ├── files/              # Project input files and data
│       ├── outputs/            # Project results and deliverables
│       └── README.md           # Project summary and log
└── README.md                   # This file
```

## 🚀 Getting Started

### Starting a New Project
1. Say: **"start a new project: [project_name]"**
2. The AI will create: `projects/YYYY_MM_DD_project_name/` with standard structure
3. Project folder includes: `docs/memory.md`, `scripts/`, `sql/`, `files/`, `outputs/`, `README.md`

### Navigation Guidelines
- **Global Resources**: Use `knowledge_base/`, `shared/scripts/`, `shared/utils/` for shared knowledge
- **Project-Specific**: All project work goes in `projects/[project_name]/`
- **Cross-Project**: Use `shared/` for all shared utilities and resources
- **Logging**: Use `logs/` for global session logs, project logs in `projects/[name]/README.md`

## 📚 Global Resources

### Knowledge Base (`knowledge_base/`)
- `table_reference.md` - Core tables and field definitions
- `query_patterns.md` - Reusable SQL patterns and examples
- `business_logic.md` - Business rules and calculation methods

### Shared Resources (`shared/`)
- **`scripts/`** - Executable Python scripts
  - `run_sql.py` - Execute SQL files
  - `monitor_queries.py` - Query monitoring utilities
  - `profile_table.py` - Table profiling tools
  - `test_connection.py` - Database connection testing
- **`utils/`** - Python utility modules
  - `sf_client.py` - Snowflake client utilities
  - `sf_utils.py` - Snowflake helper functions

## 🎯 Project Workflow

1. **Project Initialization**: AI creates project folder with standard structure
2. **Context Setup**: Document project goals, data sources, and key findings in `docs/memory.md`
3. **Analysis**: Use project-specific `sql/` and `scripts/` folders
4. **Documentation**: Update `README.md` with progress and findings
5. **Completion**: Archive results in `outputs/` and update project summary

## 🔧 Configuration

- **Cursor Rules**: `.cursor/rules/` contains AI behavior guidelines
- **IDE Settings**: `.vscode/settings.json` contains editor and terminal configurations
- **Environment**: PYTHONPATH and other environment variables configured for seamless execution

## 📝 Best Practices

- **Naming**: Use descriptive project names with date prefix
- **Documentation**: Always update `docs/memory.md` with key discoveries
- **SQL Files**: Use numeric prefixes (010_, 020_, 030_) for execution order
- **Logging**: Document progress in project `README.md` for easy backtracking
- **Sharing**: Use `shared/` directory for all cross-project knowledge and utilities

## 🎯 Current Projects

- **2025_09_02_tpi_mumuplay_emulator** - TPI case study analyzing MuMuPlayer emulator fraud patterns
  - **Status**: Active - project properly organized with complete file structure
  - **Key Finding**: Network carrier vs IP carrier mismatch as emulator indicator
  - **Next Steps**: Complete network carrier country mapping (700+ carriers)

---

*This workspace is designed for efficient adhoc analysis with proper organization and knowledge retention across multiple projects.*
