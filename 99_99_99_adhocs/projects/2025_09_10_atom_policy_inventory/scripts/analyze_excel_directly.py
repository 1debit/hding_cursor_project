#!/opt/homebrew/bin/python3
"""Analyze Excel file directly and add the 3 new columns based on policy_criteria."""

import pandas as pd
import re
from datetime import datetime

def main():
    # Load existing Excel file
    excel_file = '/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/projects/2025_09_10_atom_policy_inventory/files/Atom Score Policy Inventory(for 2025Q3 atom hard retrain).xlsx'

    print("Loading existing Excel file...")
    try:
        df = pd.read_excel(excel_file)
    except Exception as e:
        print(f"Error loading Excel file: {e}")
        print("Trying to read as CSV...")
        # If Excel fails, try to read as CSV
        df = pd.read_csv(excel_file.replace('.xlsx', '.csv'))

    print(f"Loaded {len(df)} rows from Excel file")
    print(f"Excel columns: {list(df.columns)}")

    # Add the 3 new columns based on policy_criteria
    print("Adding new columns based on policy_criteria...")

    # 1. is_atom_used column
    df['is_atom_used'] = df['POLICY_CRITERIA'].str.contains('atom_v3', case=False, na=False).map({True: 'Y', False: 'N'})

    # 2. session_event column
    def extract_session_event(criteria):
        if pd.isna(criteria):
            return 'NO_SESSION_EVENT'

        criteria_str = str(criteria).upper()

        if 'SESSION_EVENT_USERNAME_AUTH_INITIATED' in criteria_str:
            return 'SESSION_EVENT_USERNAME_AUTH_INITIATED'
        elif 'SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED' in criteria_str:
            return 'SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED'
        elif 'SESSION_EVENT_PASSWORD_AUTH_FAILED' in criteria_str:
            return 'SESSION_EVENT_PASSWORD_AUTH_FAILED'
        elif 'SESSION_EVENT_OTP_AUTH_SUCCEEDED' in criteria_str:
            return 'SESSION_EVENT_OTP_AUTH_SUCCEEDED'
        elif 'SESSION_EVENT_OTP_AUTH_FAILED' in criteria_str:
            return 'SESSION_EVENT_OTP_AUTH_FAILED'
        elif 'SESSION_EVENT_MAGIC_LINK_AUTH_SUCCEEDED' in criteria_str:
            return 'SESSION_EVENT_MAGIC_LINK_AUTH_SUCCEEDED'
        elif 'SESSION_EVENT_MAGIC_LINK_AUTH_FAILED' in criteria_str:
            return 'SESSION_EVENT_MAGIC_LINK_AUTH_FAILED'
        elif 'SESSION_EVENT_' in criteria_str:
            return 'OTHER_SESSION_EVENT'
        else:
            return 'NO_SESSION_EVENT'

    df['session_event'] = df['POLICY_CRITERIA'].apply(extract_session_event)

    # 3. policy_summary column
    def generate_policy_summary(criteria):
        if pd.isna(criteria):
            return 'N/A'

        criteria_str = str(criteria).upper()

        # Network carrier based policies
        if ('NETWORK_CARRIER' in criteria_str and 'TIMEZONE' in criteria_str and 'NUNIQUE__TIMEZONES' in criteria_str):
            return 'Detects foreign network carriers with multi-timezone travel patterns (potential emulator/VPN usage)'

        # ATOM score threshold policies
        elif ('ATOM_V3' in criteria_str and ('>' in criteria_str or '<' in criteria_str)):
            return 'ATOM v3 risk score threshold-based policy'

        # Device intelligence policies
        elif ('DEVICE' in criteria_str and 'FINGERPRINT' in criteria_str):
            return 'Device fingerprinting and intelligence-based detection'

        # IP geolocation policies
        elif ('IP_COUNTRY' in criteria_str and 'NETWORK_CARRIER' in criteria_str):
            return 'IP country vs network carrier mismatch detection'

        # Velocity-based policies
        elif ('VELOCITY' in criteria_str or 'FREQUENCY' in criteria_str):
            return 'User behavior velocity and frequency analysis'

        # Time-based policies
        elif ('TIME' in criteria_str and ('HOUR' in criteria_str or 'DAY' in criteria_str)):
            return 'Time-based access pattern analysis'

        # Feature store policies
        elif 'FEATURE_STORE' in criteria_str:
            return 'ML feature store-based risk assessment'

        # Platform-specific policies
        elif ('PLATFORM' in criteria_str and ('IOS' in criteria_str or 'ANDROID' in criteria_str)):
            return 'Platform-specific (iOS/Android) risk detection'

        # Session event policies
        elif 'SESSION_EVENT_' in criteria_str:
            return 'Login session event-based risk detection'

        # Complex multi-condition policies
        elif ('AND' in criteria_str and 'OR' in criteria_str):
            return 'Complex multi-condition risk assessment policy'

        # Simple threshold policies
        elif ('>' in criteria_str or '<' in criteria_str or '=' in criteria_str):
            return 'Threshold-based risk scoring policy'

        else:
            return 'General risk assessment policy'

    df['policy_summary'] = df['POLICY_CRITERIA'].apply(generate_policy_summary)

    # Export enhanced Excel file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f'/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/projects/2025_09_10_atom_policy_inventory/outputs/Atom_Score_Policy_Inventory_Enhanced_{timestamp}.xlsx'

    print(f"Exporting enhanced Excel file to: {output_file}")
    df.to_excel(output_file, index=False)

    print(f"\n=== Enhancement Summary ===")
    print(f"Original rows: {len(df)}")
    print(f"New columns added: is_atom_used, session_event, policy_summary")

    # Show statistics
    print(f"\n=== Column Statistics ===")
    print(f"Policies using ATOM v3: {df['is_atom_used'].value_counts().get('Y', 0)}")
    print(f"Policies with session events: {len(df[df['session_event'] != 'NO_SESSION_EVENT'])}")
    print(f"Unique policy summaries: {df['policy_summary'].nunique()}")

    # Show sample of new columns
    print(f"\n=== Sample of New Columns ===")
    sample_cols = ['POLICY_NAME', 'is_atom_used', 'session_event', 'policy_summary']
    if 'POLICY_NAME' in df.columns:
        print(df[sample_cols].head(10).to_string(index=False))
    else:
        print("Available columns:", list(df.columns))
        print(df[['is_atom_used', 'session_event', 'policy_summary']].head(10).to_string(index=False))

    print(f"\nEnhanced Excel file saved successfully!")

if __name__ == "__main__":
    main()
