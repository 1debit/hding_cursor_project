#!/usr/bin/env python3
"""Generate side-by-side pie charts comparing Taiwan vs US network carrier ATOM scores."""

import sys
import os
sys.path.append('/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/global/src')

import snowflake.connector
import pandas as pd
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
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

    # Execute the comparison query
    query = """
    WITH successful_logins AS (
        SELECT
            a.user_id,
            a.network_carrier,
            a.atom_v3,
            a.platform,
            a.ip_country,
            a._creation_timestamp,
            b.reconciled_outcome
        FROM RISK.TEST.hding_a3id_login_info a
        INNER JOIN RISK.TEST.hding_a3id_login_with_outcome b
            ON (a.a3id = b.account_access_attempt_id)
        WHERE a.atom_v3 IS NOT NULL
          AND a.network_carrier IS NOT NULL
          AND b.reconciled_outcome = 'login_successful'
    ),

    carrier_classification AS (
        SELECT
            user_id,
            network_carrier,
            atom_v3,
            platform,
            ip_country,
            _creation_timestamp,
            CASE
                WHEN network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'Taiwan Star')
                    OR network_carrier LIKE '%Taiwan%'
                    OR network_carrier LIKE '%FET%'
                    OR UPPER(network_carrier) LIKE '%SAFETYNET%'
                THEN 'Taiwan'
                WHEN network_carrier IN ('Verizon', 'AT&T', 'T-Mobile', 'Sprint', 'T-Mobile US', 'AT&T Mobility')
                    OR network_carrier LIKE '%Verizon%'
                    OR network_carrier LIKE '%AT&T%'
                    OR network_carrier LIKE '%T-Mobile%'
                    OR network_carrier LIKE '%Sprint%'
                THEN 'US'
                ELSE 'Other'
            END as carrier_country,

            CASE
                WHEN atom_v3 < 0.1 THEN '<0.1'
                WHEN atom_v3 >= 0.1 AND atom_v3 < 0.5 THEN '0.1-0.5'
                WHEN atom_v3 >= 0.5 AND atom_v3 < 0.8 THEN '0.5-0.8'
                WHEN atom_v3 >= 0.8 THEN '>0.8'
            END as atom_category
        FROM successful_logins
    )

    SELECT
        carrier_country,
        atom_category,
        COUNT(*) as login_count,
        COUNT(DISTINCT user_id) as unique_users
    FROM carrier_classification
    WHERE carrier_country IN ('Taiwan', 'US')
    GROUP BY carrier_country, atom_category
    ORDER BY carrier_country,
        CASE
            WHEN atom_category = '<0.1' THEN 1
            WHEN atom_category = '0.1-0.5' THEN 2
            WHEN atom_category = '0.5-0.8' THEN 3
            WHEN atom_category = '>0.8' THEN 4
        END
    """

    cursor.execute(query)
    results = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    df = pd.DataFrame(results, columns=columns)

    # Pivot data for easier plotting
    pivot_df = df.pivot(index='ATOM_CATEGORY', columns='CARRIER_COUNTRY', values='LOGIN_COUNT').fillna(0)

    # Calculate percentages
    taiwan_total = pivot_df['Taiwan'].sum()
    us_total = pivot_df['US'].sum()

    taiwan_percentages = (pivot_df['Taiwan'] / taiwan_total * 100).round(1)
    us_percentages = (pivot_df['US'] / us_total * 100).round(1)

    # Set up the plot
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8))

    # Define colors for consistency
    colors = ['#2E8B57', '#FFD700', '#FF6347', '#8B0000']  # Green, Gold, Tomato, Dark Red

    # Taiwan pie chart
    taiwan_data = pivot_df['Taiwan']
    taiwan_labels = [f'{cat}\n{val:,} ({pct}%)'
                    for cat, val, pct in zip(taiwan_data.index, taiwan_data.values, taiwan_percentages.values)]

    wedges1, texts1, autotexts1 = ax1.pie(taiwan_data.values,
                                          labels=taiwan_labels,
                                          colors=colors,
                                          autopct='',
                                          startangle=90,
                                          textprops={'fontsize': 10})

    ax1.set_title(f'Taiwan Network Carriers\nTotal: {taiwan_total:,} successful logins',
                  fontsize=14, fontweight='bold', pad=20)

    # US pie chart
    us_data = pivot_df['US']
    us_labels = [f'{cat}\n{val:,} ({pct}%)'
                for cat, val, pct in zip(us_data.index, us_data.values, us_percentages.values)]

    wedges2, texts2, autotexts2 = ax2.pie(us_data.values,
                                          labels=us_labels,
                                          colors=colors,
                                          autopct='',
                                          startangle=90,
                                          textprops={'fontsize': 10})

    ax2.set_title(f'US Network Carriers\nTotal: {us_total:,} successful logins',
                  fontsize=14, fontweight='bold', pad=20)

    # Add overall title
    fig.suptitle('ATOM Score Distribution Comparison: Taiwan vs US Network Carriers\n(Successful Logins Only)',
                 fontsize=16, fontweight='bold', y=0.95)

    # Add legend
    legend_labels = ['<0.1 (Very Low Risk)', '0.1-0.5 (Low-Medium Risk)',
                     '0.5-0.8 (High Risk)', '>0.8 (Very High Risk)']
    fig.legend(legend_labels, loc='lower center', ncol=4, fontsize=12, bbox_to_anchor=(0.5, 0.02))

    # Adjust layout
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.15, top=0.85)

    # Save the plot
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f'/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/temp_sql/taiwan_us_atom_comparison_{timestamp}.png'
    plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()

    # Print summary statistics
    print(f"Charts saved to: {filename}")
    print(f"\n=== Taiwan vs US Network Carrier ATOM Score Comparison ===")
    print(f"Analysis Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    print(f"\n--- Taiwan Network Carriers ---")
    print(f"Total successful logins: {taiwan_total:,}")
    for category in pivot_df.index:
        count = int(pivot_df.loc[category, 'Taiwan'])
        pct = taiwan_percentages[category]
        print(f"  {category}: {count:,} logins ({pct}%)")

    print(f"\n--- US Network Carriers ---")
    print(f"Total successful logins: {us_total:,}")
    for category in pivot_df.index:
        count = int(pivot_df.loc[category, 'US'])
        pct = us_percentages[category]
        print(f"  {category}: {count:,} logins ({pct}%)")

    # Calculate risk comparison
    taiwan_high_risk = (pivot_df.loc['0.5-0.8', 'Taiwan'] + pivot_df.loc['>0.8', 'Taiwan']) / taiwan_total * 100
    us_high_risk = (pivot_df.loc['0.5-0.8', 'US'] + pivot_df.loc['>0.8', 'US']) / us_total * 100

    print(f"\n=== Key Insights ===")
    print(f"High Risk (≥0.5) Comparison:")
    print(f"  Taiwan: {taiwan_high_risk:.1f}% of logins")
    print(f"  US: {us_high_risk:.1f}% of logins")
    print(f"  Risk Ratio: {taiwan_high_risk/us_high_risk:.1f}x higher in Taiwan carriers")

    # Very high risk comparison
    taiwan_very_high = pivot_df.loc['>0.8', 'Taiwan'] / taiwan_total * 100
    us_very_high = pivot_df.loc['>0.8', 'US'] / us_total * 100

    print(f"\nVery High Risk (>0.8) Comparison:")
    print(f"  Taiwan: {taiwan_very_high:.1f}% of logins")
    print(f"  US: {us_very_high:.1f}% of logins")
    if us_very_high > 0:
        print(f"  Risk Ratio: {taiwan_very_high/us_very_high:.1f}x higher in Taiwan carriers")
    else:
        print(f"  Taiwan carriers have {taiwan_very_high:.1f}% very high risk vs 0% for US")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
