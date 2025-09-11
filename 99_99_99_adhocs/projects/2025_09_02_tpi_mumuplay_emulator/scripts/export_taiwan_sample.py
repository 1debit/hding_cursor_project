#!/usr/bin/env python3
"""
Export Taiwan sample cases to Excel
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'global_snowflake_utils', 'src'))

from sf_client import get_connection
import pandas as pd
from pathlib import Path
from datetime import datetime

def main():
    """Export Taiwan sample cases to Excel"""

    print("Connecting to Snowflake...")
    conn = get_connection()

    try:
        # Query the sample data
        query = """
        SELECT
            user_id,
            account_creation_date,
            mob_as_of_today,
            login_date,
            card_activated,
            dder_payroll,
            user_status
        FROM RISK.TEST.taiwan_sample_50_cases
        ORDER BY mob_as_of_today DESC, user_id
        """

        print("Fetching Taiwan sample data...")
        df = pd.read_sql(query, conn)

        print(f"Retrieved {len(df)} sample cases")
        print("\nSample data preview:")
        print(df.head(10))

        # Export to Excel
        output_file = Path(__file__).parent.parent / "outputs" / f"taiwan_sample_50_cases_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
        output_file.parent.mkdir(parents=True, exist_ok=True)

        df.to_excel(output_file, index=False)
        print(f"\n✅ Data exported to: {output_file}")

        # Display summary statistics
        print("\n📊 Summary Statistics:")
        print(f"Total cases: {len(df)}")
        print(f"Card activated: {df['card_activated'].value_counts().get('Y', 0)}")
        print(f"Payroll DD: {df['dder_payroll'].value_counts().get('Y', 0)}")
        print(f"Active users: {df['user_status'].value_counts().get('active', 0)}")
        print(f"Average MOB: {df['mob_as_of_today'].mean():.1f} months")

        # Status breakdown
        print(f"\n👥 User Status Breakdown:")
        status_counts = df['user_status'].value_counts()
        for status, count in status_counts.items():
            print(f"  {status}: {count}")

        # MOB distribution
        print(f"\n📈 MOB Distribution:")
        mob_ranges = pd.cut(df['mob_as_of_today'], bins=[0, 3, 6, 12, float('inf')],
                           labels=['0-3 months', '4-6 months', '7-12 months', '12+ months'],
                           right=True, include_lowest=True)
        mob_counts = mob_ranges.value_counts().sort_index()
        for mob_range, count in mob_counts.items():
            print(f"  {mob_range}: {count}")

    except Exception as e:
        print(f"Error: {e}")
        return False
    finally:
        conn.close()

    return True

if __name__ == "__main__":
    main()
