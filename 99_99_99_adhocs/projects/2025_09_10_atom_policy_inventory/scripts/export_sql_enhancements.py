#!/usr/bin/env python3
"""Export SQL enhancements to Excel for manual merging."""

import sys
import os
sys.path.append('/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/global/src')

import snowflake.connector
import pandas as pd
from datetime import datetime

def main():
    # Connect to Snowflake
    conn = snowflake.connector.connect(
        user='HAO.DING@CHIME.COM',
        account='CHIME',
        authenticator='externalbrowser',
        warehouse='RISK_WH',
        role='SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA'
    )
    
    cursor = conn.cursor()
    
    # Execute SQL query to get enhanced data
    print("Executing SQL query for enhanced policy data...")
    query = """
    WITH base_policies AS (
        SELECT 
            policy_name,
            policy_created_at,
            policy_outcome,
            policy_created_by,
            policy_criteria,
            policy_status,
            event_name,
            DATEDIFF('day', policy_created_at, CURRENT_DATE()) as days_since_creation
        FROM chime.decision_platform.policies
        WHERE 1=1
            AND event_name = 'atom_event'
            AND policy_status = 'active'
    ),
    
    enhanced_policies AS (
        SELECT 
            *,
            -- 1. Check if ATOM v3 is used in policy criteria
            CASE 
                WHEN policy_criteria ILIKE '%atom_v3%' THEN 'Y'
                ELSE 'N'
            END as is_atom_used,
            
            -- 2. Extract session_event value from policy criteria
            CASE 
                WHEN policy_criteria ILIKE '%SESSION_EVENT_USERNAME_AUTH_INITIATED%' THEN 'SESSION_EVENT_USERNAME_AUTH_INITIATED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED%' THEN 'SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_PASSWORD_AUTH_FAILED%' THEN 'SESSION_EVENT_PASSWORD_AUTH_FAILED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_OTP_AUTH_SUCCEEDED%' THEN 'SESSION_EVENT_OTP_AUTH_SUCCEEDED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_OTP_AUTH_FAILED%' THEN 'SESSION_EVENT_OTP_AUTH_FAILED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_MAGIC_LINK_AUTH_SUCCEEDED%' THEN 'SESSION_EVENT_MAGIC_LINK_AUTH_SUCCEEDED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_MAGIC_LINK_AUTH_FAILED%' THEN 'SESSION_EVENT_MAGIC_LINK_AUTH_FAILED'
                WHEN policy_criteria ILIKE '%SESSION_EVENT_%' THEN 'OTHER_SESSION_EVENT'
                ELSE 'NO_SESSION_EVENT'
            END as session_event,
            
            -- 3. High-level policy summary based on criteria patterns
            CASE 
                -- Network carrier based policies
                WHEN policy_criteria ILIKE '%network_carrier%' AND policy_criteria ILIKE '%timezone%' AND policy_criteria ILIKE '%nunique__timezones%' 
                    THEN 'Detects foreign network carriers with multi-timezone travel patterns (potential emulator/VPN usage)'
                
                -- ATOM score threshold policies
                WHEN policy_criteria ILIKE '%atom_v3%' AND (policy_criteria ILIKE '%>%' OR policy_criteria ILIKE '%<%')
                    THEN 'ATOM v3 risk score threshold-based policy'
                
                -- Device intelligence policies
                WHEN policy_criteria ILIKE '%device%' AND policy_criteria ILIKE '%fingerprint%'
                    THEN 'Device fingerprinting and intelligence-based detection'
                
                -- IP geolocation policies
                WHEN policy_criteria ILIKE '%ip_country%' AND policy_criteria ILIKE '%network_carrier%'
                    THEN 'IP country vs network carrier mismatch detection'
                
                -- Velocity-based policies
                WHEN policy_criteria ILIKE '%velocity%' OR policy_criteria ILIKE '%frequency%'
                    THEN 'User behavior velocity and frequency analysis'
                
                -- Time-based policies
                WHEN policy_criteria ILIKE '%time%' AND (policy_criteria ILIKE '%hour%' OR policy_criteria ILIKE '%day%')
                    THEN 'Time-based access pattern analysis'
                
                -- Feature store policies
                WHEN policy_criteria ILIKE '%feature_store%'
                    THEN 'ML feature store-based risk assessment'
                
                -- Platform-specific policies
                WHEN policy_criteria ILIKE '%platform%' AND (policy_criteria ILIKE '%ios%' OR policy_criteria ILIKE '%android%')
                    THEN 'Platform-specific (iOS/Android) risk detection'
                
                -- Session event policies
                WHEN policy_criteria ILIKE '%SESSION_EVENT_%'
                    THEN 'Login session event-based risk detection'
                
                -- Complex multi-condition policies
                WHEN policy_criteria ILIKE '%AND%' AND policy_criteria ILIKE '%OR%'
                    THEN 'Complex multi-condition risk assessment policy'
                
                -- Simple threshold policies
                WHEN policy_criteria ILIKE '%>%' OR policy_criteria ILIKE '%<%' OR policy_criteria ILIKE '%=%'
                    THEN 'Threshold-based risk scoring policy'
                
                ELSE 'General risk assessment policy'
            END as policy_summary
            
        FROM base_policies
    )
    
    SELECT 
        policy_name,
        is_atom_used,
        session_event,
        policy_summary,
        policy_outcome,
        policy_created_at,
        policy_created_by
    FROM enhanced_policies
    ORDER BY policy_name
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    df_sql = pd.DataFrame(results, columns=columns)
    print(f"Retrieved {len(df_sql)} rows from SQL query")
    
    # Export SQL enhancements to Excel
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f'/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/projects/2025_09_10_atom_policy_inventory/outputs/SQL_Enhancements_{timestamp}.xlsx'
    
    print(f"Exporting SQL enhancements to: {output_file}")
    df_sql.to_excel(output_file, index=False, engine='openpyxl')
    
    print(f"\n=== SQL Enhancement Summary ===")
    print(f"Total policies: {len(df_sql)}")
    print(f"Policies using ATOM v3: {len(df_sql[df_sql['is_atom_used'] == 'Y'])}")
    print(f"Policies with session events: {len(df_sql[df_sql['session_event'] != 'NO_SESSION_EVENT'])}")
    print(f"Unique policy summaries: {df_sql['policy_summary'].nunique()}")
    
    # Show sample of data
    print(f"\n=== Sample Data ===")
    print(df_sql[['policy_name', 'is_atom_used', 'session_event', 'policy_summary']].head(10).to_string(index=False))
    
    print(f"\n=== Next Steps ===")
    print(f"1. Open the original Excel file: Atom Score Policy Inventory(for 2025Q3 atom hard retrain).xlsx")
    print(f"2. Open the SQL enhancements file: {output_file}")
    print(f"3. Copy the 3 new columns (is_atom_used, session_event, policy_summary) from SQL file to original Excel file")
    print(f"4. Match by policy_name column")
    
    cursor.close()
    conn.close()
    print(f"\nSQL enhancements exported successfully!")

if __name__ == "__main__":
    main()
