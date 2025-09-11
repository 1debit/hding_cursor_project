#!/usr/bin/env python3
"""
Run Taiwan sample cases query and export to Excel
"""

import sys
import os
from pathlib import Path
from datetime import datetime

# Add current directory to path for imports
sys.path.append(os.path.dirname(__file__))

from sf_client import get_connection, run_sql_file
import pandas as pd

def main():
    """Run Taiwan sample cases query and export to Excel"""

    # Paths
    sql_file = Path(__file__).parent.parent / "sql" / "096_taiwan_sample_50_cases.sql"
    output_file = Path(__file__).parent.parent / "outputs" / f"taiwan_sample_50_cases_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"

    print(f"Running SQL file: {sql_file}")
    print(f"Output file: {output_file}")

    try:
        # Run the SQL file
        df = run_sql_file(sql_file)

        if df is not None and not df.empty:
            print(f"Retrieved {len(df)} sample cases")
            print("\nSample data preview:")
            print(df.head(10))

            # Export to Excel
            output_file.parent.mkdir(parents=True, exist_ok=True)
            df.to_excel(output_file, index=False)
            print(f"\nData exported to: {output_file}")

            # Display summary statistics
            print("\nSummary Statistics:")
            print(f"Total cases: {len(df)}")
            print(f"Card activated: {df['card_activated'].value_counts().get('Y', 0)}")
            print(f"Payroll DD: {df['dder_payroll'].value_counts().get('Y', 0)}")
            print(f"Active users: {df['user_status'].value_counts().get('active', 0)}")
            print(f"Average MOB: {df['mob_as_of_today'].mean():.1f} months")

        else:
            print("No data returned from query")

    except Exception as e:
        print(f"Error: {e}")
        return False

    return True

if __name__ == "__main__":
    main()
