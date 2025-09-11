#!/usr/bin/env python3
"""
Export Taiwan sample cases to Excel using the working sf_client
"""

import sys
import os
from pathlib import Path
from datetime import datetime

# Add the working sf_client to path
sys.path.append(str(Path(__file__).parent.parent.parent.parent / "global_snowflake_utils" / "src"))

from sf_utils import SnowflakeUtils
import pandas as pd

def main():
    """Export Taiwan sample cases to Excel"""

    try:
        # Initialize Snowflake utils
        sf_utils = SnowflakeUtils()

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

        print("🔗 Connecting to Snowflake and fetching Taiwan sample data...")
        df = sf_utils.query_to_df(query)

        print(f"✅ Retrieved {len(df)} sample cases")

        # Export to Excel
        output_file = Path(__file__).parent.parent / "outputs" / f"taiwan_sample_50_cases_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
        output_file.parent.mkdir(parents=True, exist_ok=True)

        df.to_excel(output_file, index=False)
        print(f"📁 Data exported to: {output_file}")

        # Display sample data
        print(f"\n📋 Sample Data Preview:")
        print(df.head(10).to_string())

        # Display summary statistics
        print(f"\n📈 Summary Statistics:")
        print(f"Total cases: {len(df)}")
        print(f"Card activated: {df['card_activated'].value_counts().get('Y', 0)} users")
        print(f"Payroll DD: {df['dder_payroll'].value_counts().get('Y', 0)} users")
        print(f"Active users: {df['user_status'].value_counts().get('active', 0)} users")
        print(f"Average MOB: {df['mob_as_of_today'].mean():.1f} months")

        # Status breakdown
        print(f"\n👥 User Status Breakdown:")
        status_counts = df['user_status'].value_counts()
        for status, count in status_counts.items():
            pct = (count / len(df)) * 100
            print(f"  {status}: {count} ({pct:.1f}%)")

        print(f"\n🎉 Export completed successfully!")

    except Exception as e:
        print(f"❌ Error: {e}")
        return False

    return True

if __name__ == "__main__":
    main()
