#!/usr/bin/env python3
"""
Network Carrier Country Research Script
Fetches all distinct carriers from database and identifies unmapped ones
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'utils'))

from sf_client import get_connection
import pandas as pd

def get_all_carriers():
    """Get all distinct network carriers from the database"""
    conn = get_connection()
    cursor = conn.cursor()
    
    query = """
    SELECT DISTINCT 
        network_carrier, 
        COUNT(*) as login_count
    FROM risk.test.hding_a3id_login_info 
    WHERE network_carrier IS NOT NULL 
        AND TRIM(network_carrier) != '' 
        AND network_carrier != '--' 
        AND network_carrier != 'unknown'
    GROUP BY network_carrier 
    ORDER BY login_count DESC
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    
    df = pd.DataFrame(results, columns=['network_carrier', 'login_count'])
    return df

def get_mapped_carriers():
    """Get carriers that are already mapped"""
    conn = get_connection()
    cursor = conn.cursor()
    
    query = "SELECT network_carrier FROM risk.test.hding_network_carrier_country_mapping"
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    
    mapped = set([row[0] for row in results])
    return mapped

def main():
    print("🔍 Fetching all network carriers from database...")
    all_carriers_df = get_all_carriers()
    print(f"📊 Found {len(all_carriers_df)} distinct carriers")
    
    print("\n🔍 Getting already mapped carriers...")
    mapped_carriers = get_mapped_carriers()
    print(f"📋 Already mapped: {len(mapped_carriers)} carriers")
    
    # Find unmapped carriers
    unmapped = all_carriers_df[~all_carriers_df['network_carrier'].isin(mapped_carriers)]
    
    print(f"\n❓ Unmapped carriers: {len(unmapped)}")
    print("\nTop 20 unmapped carriers by login count:")
    print(unmapped.head(20).to_string(index=False))
    
    if len(unmapped) > 0:
        print(f"\n📝 Total unmapped carriers: {len(unmapped)}")
        print("These need manual research for country mapping.")
        
        # Save unmapped carriers to file for manual research
        unmapped.to_csv('unmapped_carriers.csv', index=False)
        print("💾 Saved unmapped carriers to 'unmapped_carriers.csv'")
    
    print(f"\n✅ Summary:")
    print(f"   Total carriers: {len(all_carriers_df)}")
    print(f"   Already mapped: {len(mapped_carriers)}")
    print(f"   Need mapping: {len(unmapped)}")

if __name__ == "__main__":
    main()
