#!/usr/bin/env python3
"""
Simple export script using direct snowflake.connector
"""

import snowflake.connector
import pandas as pd
from pathlib import Path
from datetime import datetime
import os

def main():
    """Export Taiwan sample cases to Excel using direct connector"""

    try:
        # Connection parameters (using Chime defaults)
        conn_params = {
            'user': 'HAO.DING@CHIME.COM',
            'account': 'CHIME',
            'authenticator': 'externalbrowser',
            'warehouse': 'RISK_WH',
            'database': 'RISK',
            'schema': 'TEST',
            'role': 'SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA'
        }

        print("🔗 Connecting to Snowflake...")
        conn = snowflake.connector.connect(**conn_params)
        cursor = conn.cursor()

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

        print("📊 Fetching Taiwan sample data...")
        cursor.execute(query)

        # Fetch all results
        results = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]

        # Create DataFrame
        df = pd.DataFrame(results, columns=columns)

        # Fix timezone issues for Excel export
        for col in df.columns:
            if df[col].dtype == 'datetime64[ns, America/Los_Angeles]' or 'datetime' in str(df[col].dtype):
                df[col] = pd.to_datetime(df[col]).dt.tz_localize(None)

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

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"❌ Error: {e}")
        return False

    return True

if __name__ == "__main__":
    main()
