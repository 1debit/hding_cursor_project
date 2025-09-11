#!/usr/bin/env python3
"""Simple Excel analysis without openpyxl dependency."""

import pandas as pd
import sys
import os

def main():
    # Try different methods to read the Excel file
    excel_file = '/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/projects/2025_09_10_atom_policy_inventory/files/Atom Score Policy Inventory(for 2025Q3 atom hard retrain).xlsx'

    print("Attempting to read Excel file...")

    # Method 1: Try with xlrd engine
    try:
        df = pd.read_excel(excel_file, engine='xlrd')
        print("Successfully loaded with xlrd engine")
    except Exception as e1:
        print(f"xlrd failed: {e1}")

        # Method 2: Try with openpyxl but handle the error
        try:
            import openpyxl
            df = pd.read_excel(excel_file, engine='openpyxl')
            print("Successfully loaded with openpyxl engine")
        except Exception as e2:
            print(f"openpyxl failed: {e2}")

            # Method 3: Try to convert to CSV first
            try:
                print("Trying to convert Excel to CSV...")
                import subprocess
                csv_file = excel_file.replace('.xlsx', '.csv')
                subprocess.run(['python', '-c', f'''
import pandas as pd
df = pd.read_excel("{excel_file}")
df.to_csv("{csv_file}", index=False)
print("Converted to CSV successfully")
'''], check=True)

                df = pd.read_csv(csv_file)
                print("Successfully loaded converted CSV")
            except Exception as e3:
                print(f"All methods failed: {e3}")
                return

    print(f"Loaded {len(df)} rows")
    print(f"Columns: {list(df.columns)}")

    # Show first few rows to understand the structure
    print("\nFirst 3 rows:")
    print(df.head(3).to_string())

    # Check if policy_criteria column exists
    if 'policy_criteria' in df.columns:
        print(f"\nFound policy_criteria column with {df['policy_criteria'].notna().sum()} non-null values")

        # Show sample policy criteria
        print("\nSample policy_criteria:")
        for i, criteria in enumerate(df['policy_criteria'].dropna().head(3)):
            print(f"\nPolicy {i+1}:")
            print(str(criteria)[:200] + "..." if len(str(criteria)) > 200 else str(criteria))
    else:
        print("policy_criteria column not found. Available columns:")
        for col in df.columns:
            print(f"  - {col}")

if __name__ == "__main__":
    main()
