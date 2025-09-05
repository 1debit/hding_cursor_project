#!/usr/bin/env python3
"""
Simple script to get network carriers from database
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'global_snowflake_utils', 'src'))

from sf_client import get_connection
import pandas as pd

def main():
    conn = get_connection()
    
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
    LIMIT 30
    """
    
    df = pd.read_sql(query, conn)
    print('Top 30 network carriers by login count:')
    print(df.to_string(index=False))
    
    conn.close()

if __name__ == "__main__":
    main()
