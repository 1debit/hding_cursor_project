#!/usr/bin/env python3
"""Export login authentication method analysis to Excel for detailed review."""

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
    
    # Execute query
    query = """
    select 
    case when (variant_key='control' or (variant_key='treatment' and num_of_eligible=1)) then '1. password only'
           when num_of_eligible=3 then '3. all 3 options'
           when ml_eligible=1 then '2.1 ml + pwd'
           when otp_eligible=1 then '2.2 otp + pwd'
           else  '99. others' end as eligibility_category
    , case when last_pw_attempt_outcome is null and final_session_event ilike 'otp%' then '1.otp'
           when last_pw_attempt_outcome is null and final_session_event ilike 'magic%' then '2.magiclink'
           when last_pw_attempt_outcome is null and final_session_event='username_auth_initiated' then '4.abandoned'
           when last_pw_attempt_outcome is not null then '3.pw'
           else '99.others' end as auth_method_used 
    , count(*) as total_attempts
    , count(*)/sum(count(*)) over () as perc_of_total
    , sum(case when reconciled_outcome='login_successful' then 1 else 0 end) as successful_logins
    , sum(case when reconciled_outcome='login_successful' then 1 else 0 end)/count(*) as success_rate
        from risk.test.hding_personal_login_eligibility_driver
        where variant_key='treatment' 
        group by all
        order by 1 desc, 2, 3
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    
    # Create DataFrame
    columns = [desc[0] for desc in cursor.description]
    df = pd.DataFrame(results, columns=columns)
    
    # Convert decimal columns to float and format percentages
    df['PERC_OF_TOTAL'] = df['PERC_OF_TOTAL'].astype(float) * 100
    df['SUCCESS_RATE'] = df['SUCCESS_RATE'].astype(float) * 100
    df['PERC_OF_TOTAL'] = df['PERC_OF_TOTAL'].round(2)
    df['SUCCESS_RATE'] = df['SUCCESS_RATE'].round(2)
    
    # Export to Excel
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f'/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/temp_sql/login_auth_analysis_{timestamp}.xlsx'
    
    with pd.ExcelWriter(filename, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name='Login_Analysis', index=False)
    
    print(f"Results exported to: {filename}")
    print(f"\nSummary:")
    print(f"Total rows: {len(df)}")
    print(f"Total attempts analyzed: {df['TOTAL_ATTEMPTS'].sum():,}")
    
    # Print summary by eligibility category
    print(f"\n--- Summary by Eligibility Category ---")
    category_summary = df.groupby('ELIGIBILITY_CATEGORY').agg({
        'TOTAL_ATTEMPTS': 'sum',
        'SUCCESSFUL_LOGINS': 'sum'
    }).reset_index()
    category_summary['SUCCESS_RATE'] = (category_summary['SUCCESSFUL_LOGINS'] / category_summary['TOTAL_ATTEMPTS'] * 100).round(2)
    
    for _, row in category_summary.iterrows():
        print(f"{row['ELIGIBILITY_CATEGORY']}: {row['TOTAL_ATTEMPTS']:,} attempts, {row['SUCCESS_RATE']:.1f}% success rate")
    
    # Print top results
    print(f"\n--- Top 10 Results ---")
    for _, row in df.head(10).iterrows():
        print(f"{row['ELIGIBILITY_CATEGORY']} | {row['AUTH_METHOD_USED']}: {row['TOTAL_ATTEMPTS']:,} attempts ({row['PERC_OF_TOTAL']:.1f}%), {row['SUCCESS_RATE']:.1f}% success rate")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
