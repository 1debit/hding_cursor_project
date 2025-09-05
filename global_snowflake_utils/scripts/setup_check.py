#!/usr/bin/env python3
"""
Setup Verification Script
Verify that the Snowflake starter kit is properly configured and ready to use.

Usage:
    python scripts/setup_check.py
    python scripts/setup_check.py --skip-connection
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List, Tuple

def check_file_exists(filepath: str, description: str) -> Tuple[bool, str]:
    """Check if a file exists and return status."""
    if Path(filepath).exists():
        return True, f"✅ {description}: Found"
    else:
        return False, f"❌ {description}: Missing ({filepath})"

def check_env_file() -> Tuple[bool, str]:
    """Check if .env file exists and has required variables."""
    env_path = Path('.env')
    if not env_path.exists():
        return False, "❌ .env file: Missing (copy .env.example and configure)"
    
    # Read .env and check for required variables
    env_content = env_path.read_text()
    required_vars = [
        'SNOWFLAKE_ACCOUNT',
        'SNOWFLAKE_USER', 
        'SNOWFLAKE_ROLE',
        'SNOWFLAKE_WAREHOUSE',
        'SNOWFLAKE_DATABASE',
        'SNOWFLAKE_SCHEMA'
    ]
    
    missing_vars = []
    for var in required_vars:
        if f"{var}=" not in env_content or f"{var}=your_" in env_content:
            missing_vars.append(var)
    
    if missing_vars:
        return False, f"❌ .env configuration: Missing/incomplete variables: {', '.join(missing_vars)}"
    
    return True, "✅ .env file: Configured"

def check_python_packages() -> Tuple[bool, str]:
    """Check if required Python packages are installed."""
    try:
        import snowflake.connector
        import pandas
        import dotenv
        import cryptography
        return True, "✅ Python packages: All required packages installed"
    except ImportError as e:
        return False, f"❌ Python packages: Missing - {e}. Run: pip install -r requirements.txt"

def check_directory_structure() -> List[Tuple[bool, str]]:
    """Check if all required directories and files exist."""
    checks = []
    
    # Core directories
    dirs_to_check = [
        ('.cursor/rules', 'Cursor rules directory'),
        ('src', 'Source code directory'),
        ('scripts', 'Scripts directory'),
        ('sql', 'SQL files directory'),
        ('docs', 'Documentation directory')
    ]
    
    for dir_path, description in dirs_to_check:
        checks.append(check_file_exists(dir_path, description))
    
    # Core files
    files_to_check = [
        ('.env.example', 'Environment template'),
        ('.gitignore', 'Git ignore file'),
        ('.cursorignore', 'Cursor ignore file'),
        ('requirements.txt', 'Python requirements'),
        ('src/sf_client.py', 'Snowflake client'),
        ('src/sf_utils.py', 'Snowflake utilities'),
        ('scripts/test_connection.py', 'Connection test script'),
        ('scripts/run_sql.py', 'SQL execution script'),
        ('scripts/profile_table.py', 'Table profiling script'),
        ('scripts/query_cost_estimator.py', 'Cost estimation script'),
        ('scripts/monitor_queries.py', 'Query monitoring script'),
        ('docs/memory.md', 'Project memory document'),
        ('.cursor/rules/snowflake_mdc.md', 'MDC rules')
    ]
    
    for file_path, description in files_to_check:
        checks.append(check_file_exists(file_path, description))
    
    return checks

def test_snowflake_connection() -> Tuple[bool, str]:
    """Test Snowflake connection."""
    try:
        from src.sf_client import get_connection
        
        # Try to connect
        conn = get_connection()
        cursor = conn.cursor()
        
        # Test simple query
        cursor.execute("SELECT CURRENT_ACCOUNT(), CURRENT_USER(), CURRENT_ROLE()")
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        return True, f"✅ Snowflake connection: Success ({result[0]}, {result[1]}, {result[2]})"
        
    except Exception as e:
        return False, f"❌ Snowflake connection: Failed - {str(e)[:100]}..."

def check_sql_demo() -> Tuple[bool, str]:
    """Check if demo SQL follows proper format."""
    demo_path = Path('sql/010_create_demo_table.sql')
    if not demo_path.exists():
        return False, "❌ Demo SQL: File missing"
    
    content = demo_path.read_text()
    
    # Check for required header elements
    required_elements = ['-- Title:', '-- Intent:', '-- Inputs:', '-- Output:', '-- Assumptions:', '-- Validation:']
    missing_elements = [elem for elem in required_elements if elem not in content]
    
    if missing_elements:
        return False, f"❌ Demo SQL: Missing header elements: {', '.join(missing_elements)}"
    
    return True, "✅ Demo SQL: Properly formatted with required headers"

def main():
    parser = argparse.ArgumentParser(description='Verify Snowflake starter kit setup')
    parser.add_argument('--skip-connection', action='store_true', 
                       help='Skip Snowflake connection test')
    
    args = parser.parse_args()
    
    print("🔍 Snowflake Starter Kit Setup Verification")
    print("=" * 50)
    
    all_passed = True
    
    # Check directory structure
    print("\n📁 Directory Structure & Files:")
    structure_checks = check_directory_structure()
    for passed, message in structure_checks:
        print(f"   {message}")
        if not passed:
            all_passed = False
    
    # Check environment file
    print(f"\n🔧 Configuration:")
    env_passed, env_message = check_env_file()
    print(f"   {env_message}")
    if not env_passed:
        all_passed = False
    
    # Check Python packages
    packages_passed, packages_message = check_python_packages()
    print(f"   {packages_message}")
    if not packages_passed:
        all_passed = False
    
    # Check SQL demo format
    sql_passed, sql_message = check_sql_demo()
    print(f"   {sql_message}")
    if not sql_passed:
        all_passed = False
    
    # Test Snowflake connection (optional)
    if not args.skip_connection and env_passed and packages_passed:
        print(f"\n🔌 Connectivity:")
        conn_passed, conn_message = test_snowflake_connection()
        print(f"   {conn_message}")
        if not conn_passed:
            all_passed = False
    elif args.skip_connection:
        print(f"\n🔌 Connectivity:")
        print(f"   ⏭️  Snowflake connection: Skipped")
    
    # Summary
    print(f"\n📊 Setup Status:")
    if all_passed:
        print("   ✅ All checks passed! Your Snowflake starter kit is ready to use.")
        print("\n🚀 Next Steps:")
        print("   1. Test connection: python scripts/test_connection.py")
        print("   2. Run demo SQL: python scripts/run_sql.py sql/010_create_demo_table.sql")
        print("   3. Profile a table: python scripts/profile_table.py DEMO_SALES")
        print("   4. Start developing: Ask Cursor to generate SQL queries following MDC rules")
        sys.exit(0)
    else:
        print("   ❌ Some checks failed. Please address the issues above before proceeding.")
        print("\n🛠️  Quick Fixes:")
        if not env_passed:
            print("   • Copy .env.example to .env and configure your Snowflake credentials")
        if not packages_passed:
            print("   • Run: pip install -r requirements.txt")
        sys.exit(1)

if __name__ == "__main__":
    main()
