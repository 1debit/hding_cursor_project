#!/usr/bin/env python3
"""Export Taiwan network carrier ATOM score distribution analysis to Excel."""

import sys
import os
sys.path.append('/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/global/src')

import snowflake.connector
import pandas as pd
import numpy as np
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
    
    # Main distribution query
    main_query = """
    WITH taiwan_logins AS (
        SELECT 
            a.user_id,
            a.network_carrier,
            a.atom_v3,
            a.platform,
            a.session_event,
            a._creation_timestamp as login_timestamp,
            a.ip_country
        FROM RISK.TEST.hding_a3id_login_info a
        WHERE a.network_carrier IS NOT NULL
          AND a.atom_v3 IS NOT NULL
          AND (a.network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'Taiwan Star')
               OR a.network_carrier LIKE '%Taiwan%'
               OR a.network_carrier LIKE '%FET%'
               OR UPPER(a.network_carrier) LIKE '%SAFETYNET%')
    )
    
    SELECT
        network_carrier,
        COUNT(*) as total_logins,
        COUNT(DISTINCT user_id) as unique_users,
        
        -- ATOM Score Statistics
        ROUND(AVG(atom_v3), 4) as avg_atom_score,
        ROUND(MEDIAN(atom_v3), 4) as median_atom_score,
        ROUND(MIN(atom_v3), 4) as min_atom_score,
        ROUND(MAX(atom_v3), 4) as max_atom_score,
        ROUND(STDDEV(atom_v3), 4) as stddev_atom_score,
        
        -- Percentiles
        ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY atom_v3), 4) as p25_atom_score,
        ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY atom_v3), 4) as p75_atom_score,
        ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY atom_v3), 4) as p90_atom_score,
        ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY atom_v3), 4) as p95_atom_score,
        ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY atom_v3), 4) as p99_atom_score,
        
        -- Risk Categories (counts)
        SUM(CASE WHEN atom_v3 <= 0.1 THEN 1 ELSE 0 END) as very_low_risk_count,
        SUM(CASE WHEN atom_v3 > 0.1 AND atom_v3 <= 0.3 THEN 1 ELSE 0 END) as low_risk_count,
        SUM(CASE WHEN atom_v3 > 0.3 AND atom_v3 <= 0.5 THEN 1 ELSE 0 END) as medium_risk_count,
        SUM(CASE WHEN atom_v3 > 0.5 AND atom_v3 <= 0.7 THEN 1 ELSE 0 END) as high_risk_count,
        SUM(CASE WHEN atom_v3 > 0.7 THEN 1 ELSE 0 END) as very_high_risk_count,
        
        -- Platform breakdown
        COUNT(CASE WHEN platform = 'ios' THEN 1 END) as ios_logins,
        COUNT(CASE WHEN platform = 'android' THEN 1 END) as android_logins,
        
        -- IP Country patterns
        COUNT(CASE WHEN ip_country = 'TWN' THEN 1 END) as twn_ip_logins,
        COUNT(CASE WHEN ip_country = 'USA' THEN 1 END) as usa_ip_logins,
        COUNT(CASE WHEN ip_country NOT IN ('TWN', 'USA') AND ip_country IS NOT NULL THEN 1 END) as other_ip_logins
        
    FROM taiwan_logins
    GROUP BY network_carrier
    ORDER BY total_logins DESC
    """
    
    cursor.execute(main_query)
    results = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    df_main = pd.DataFrame(results, columns=columns)
    
    # Calculate percentages
    df_main['very_low_risk_pct'] = (df_main['VERY_LOW_RISK_COUNT'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    df_main['low_risk_pct'] = (df_main['LOW_RISK_COUNT'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    df_main['medium_risk_pct'] = (df_main['MEDIUM_RISK_COUNT'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    df_main['high_risk_pct'] = (df_main['HIGH_RISK_COUNT'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    df_main['very_high_risk_pct'] = (df_main['VERY_HIGH_RISK_COUNT'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    
    df_main['ios_pct'] = (df_main['IOS_LOGINS'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    df_main['android_pct'] = (df_main['ANDROID_LOGINS'] / df_main['TOTAL_LOGINS'] * 100).round(2)
    
    # Detailed score distribution query
    distribution_query = """
    WITH taiwan_logins AS (
        SELECT 
            a.network_carrier,
            a.atom_v3,
            CASE 
                WHEN atom_v3 <= 0.05 THEN '0.00-0.05'
                WHEN atom_v3 <= 0.10 THEN '0.05-0.10'
                WHEN atom_v3 <= 0.20 THEN '0.10-0.20'
                WHEN atom_v3 <= 0.30 THEN '0.20-0.30'
                WHEN atom_v3 <= 0.40 THEN '0.30-0.40'
                WHEN atom_v3 <= 0.50 THEN '0.40-0.50'
                WHEN atom_v3 <= 0.60 THEN '0.50-0.60'
                WHEN atom_v3 <= 0.70 THEN '0.60-0.70'
                WHEN atom_v3 <= 0.80 THEN '0.70-0.80'
                WHEN atom_v3 <= 0.90 THEN '0.80-0.90'
                ELSE '0.90-1.00'
            END as score_bucket
        FROM RISK.TEST.hding_a3id_login_info a
        WHERE a.network_carrier IS NOT NULL
          AND a.atom_v3 IS NOT NULL
          AND (a.network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'Taiwan Star')
               OR a.network_carrier LIKE '%Taiwan%'
               OR a.network_carrier LIKE '%FET%'
               OR UPPER(a.network_carrier) LIKE '%SAFETYNET%')
    )
    
    SELECT
        network_carrier,
        score_bucket,
        COUNT(*) as login_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY network_carrier), 2) as percentage
    FROM taiwan_logins
    GROUP BY network_carrier, score_bucket
    ORDER BY network_carrier, score_bucket
    """
    
    cursor.execute(distribution_query)
    dist_results = cursor.fetchall()
    dist_columns = [desc[0] for desc in cursor.description]
    df_distribution = pd.DataFrame(dist_results, columns=dist_columns)
    
    # Export to Excel
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f'/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/temp_sql/taiwan_atom_distribution_{timestamp}.xlsx'
    
    with pd.ExcelWriter(filename, engine='openpyxl') as writer:
        df_main.to_excel(writer, sheet_name='Summary_Statistics', index=False)
        df_distribution.to_excel(writer, sheet_name='Score_Distribution', index=False)
    
    print(f"Results exported to: {filename}")
    print(f"\n=== Taiwan Network Carrier ATOM Score Analysis ===")
    print(f"Total carriers analyzed: {len(df_main)}")
    print(f"Total logins: {df_main['TOTAL_LOGINS'].sum():,}")
    print(f"Total unique users: {df_main['UNIQUE_USERS'].sum():,}")
    
    print(f"\n--- ATOM Score Statistics by Carrier ---")
    for _, row in df_main.iterrows():
        print(f"\n{row['NETWORK_CARRIER']}:")
        print(f"  Logins: {row['TOTAL_LOGINS']:,} | Users: {row['UNIQUE_USERS']:,}")
        print(f"  ATOM Score - Avg: {row['AVG_ATOM_SCORE']:.4f} | Median: {row['MEDIAN_ATOM_SCORE']:.4f}")
        print(f"  Percentiles - P75: {row['P75_ATOM_SCORE']:.4f} | P90: {row['P90_ATOM_SCORE']:.4f} | P95: {row['P95_ATOM_SCORE']:.4f}")
        print(f"  Risk Distribution - Very Low: {row['very_low_risk_pct']:.1f}% | Low: {row['low_risk_pct']:.1f}% | Medium: {row['medium_risk_pct']:.1f}% | High: {row['high_risk_pct']:.1f}% | Very High: {row['very_high_risk_pct']:.1f}%")
        print(f"  Platform - iOS: {row['ios_pct']:.1f}% | Android: {row['android_pct']:.1f}%")
        print(f"  IP Country - TWN: {row['TWN_IP_LOGINS']:,} | USA: {row['USA_IP_LOGINS']:,} | Other: {row['OTHER_IP_LOGINS']:,}")
    
    # Highlight key findings
    print(f"\n=== Key Findings ===")
    fareastone_data = df_main[df_main['NETWORK_CARRIER'] == 'FarEasTone'].iloc[0] if len(df_main[df_main['NETWORK_CARRIER'] == 'FarEasTone']) > 0 else None
    if fareastone_data is not None:
        print(f"FarEasTone (Primary Taiwan Carrier):")
        print(f"  - {fareastone_data['TOTAL_LOGINS']:,} logins from {fareastone_data['UNIQUE_USERS']:,} users")
        print(f"  - Average ATOM score: {fareastone_data['AVG_ATOM_SCORE']:.4f}")
        print(f"  - High/Very High Risk: {fareastone_data['high_risk_pct'] + fareastone_data['very_high_risk_pct']:.1f}%")
        print(f"  - USA IP usage: {fareastone_data['USA_IP_LOGINS']:,} logins ({fareastone_data['USA_IP_LOGINS']/fareastone_data['TOTAL_LOGINS']*100:.1f}%)")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
