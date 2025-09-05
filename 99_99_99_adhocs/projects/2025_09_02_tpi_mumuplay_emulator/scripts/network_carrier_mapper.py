#!/usr/bin/env python3
"""
Network Carrier Country Mapper
Purpose: Map network carriers to country codes for emulator detection analysis
"""

import sys
import os
sys.path.append('../global_snowflake_utils')

from src.sf_client import get_connection
import pandas as pd
import requests
from typing import Dict, List, Tuple
import time

def get_all_carriers() -> pd.DataFrame:
    """Get all distinct network carriers from the database"""
    conn = get_connection()
    
    query = """
    SELECT DISTINCT network_carrier, COUNT(*) as login_count
    FROM risk.test.hding_a3id_login_info
    WHERE network_carrier IS NOT NULL 
        AND TRIM(network_carrier) != ''
        AND network_carrier != '--'
        AND network_carrier != 'unknown'
    GROUP BY network_carrier
    ORDER BY login_count DESC
    """
    
    # Use cursor instead of pandas for better compatibility
    cursor = conn.cursor()
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Convert to DataFrame
    df = pd.DataFrame(results, columns=['network_carrier', 'login_count'])
    return df

def research_carrier_country(carrier: str) -> str:
    """Research carrier country using web search"""
    try:
        # Known mappings for major carriers
        known_mappings = {
            # US Carriers
            'Verizon': 'USA', 'T-Mobile': 'USA', 'AT&T': 'USA', 'cricket': 'USA',
            'Metro by T-Mobile': 'USA', 'Sprint': 'USA', 'Boost Mobile': 'USA',
            'Virgin Mobile': 'USA', 'TracFone': 'USA', 'Mint Mobile': 'USA',
            'US Cellular': 'USA', 'Cricket Wireless': 'USA',
            
            # Taiwan Carriers
            'FarEasTone': 'TWN', 'Chunghwa Telecom': 'TWN', 'Taiwan Mobile': 'TWN',
            
            # Indonesia Carriers
            'Telkomsel': 'IDN', 'Indosat': 'IDN', 'XL Axiata': 'IDN',
            
            # China Carriers
            'China Mobile': 'CHN', 'China Telecom': 'CHN', 'China Unicom': 'CHN',
            
            # Other Major Carriers
            'Vodafone': 'GBR', 'Orange': 'FRA', 'Telstra': 'AUS',
            'Bell': 'CAN', 'Rogers': 'CAN', 'TELUS': 'CAN',
            'SoftBank': 'JPN', 'NTT DoCoMo': 'JPN', 'KDDI': 'JPN',
            'SK Telecom': 'KOR', 'KT': 'KOR', 'LG U+': 'KOR',
            'Singtel': 'SGP', 'StarHub': 'SGP', 'M1': 'SGP'
        }
        
        # Check if we already know this carrier
        if carrier in known_mappings:
            return known_mappings[carrier]
        
        # For unknown carriers, try to infer from patterns
        carrier_lower = carrier.lower()
        
        # Pattern matching for common cases
        if any(pattern in carrier_lower for pattern in ['verizon', 'att', 't-mobile', 'sprint', 'cricket']):
            return 'USA'
        elif any(pattern in carrier_lower for pattern in ['china', 'mobile', 'telecom', 'unicom']):
            return 'CHN'
        elif any(pattern in carrier_lower for pattern in ['vodafone', 'orange', 'ee', 'three']):
            return 'GBR'
        elif any(pattern in carrier_lower for pattern in ['telstra', 'optus']):
            return 'AUS'
        elif any(pattern in carrier_lower for pattern in ['bell', 'rogers', 'telus']):
            return 'CAN'
        elif any(pattern in carrier_lower for pattern in ['softbank', 'ntt', 'kddi']):
            return 'JPN'
        elif any(pattern in carrier_lower for pattern in ['sk', 'kt', 'lg']):
            return 'KOR'
        elif any(pattern in carrier_lower for pattern in ['singtel', 'starhub', 'm1']):
            return 'SGP'
        else:
            return 'UNK'  # Unknown
            
    except Exception as e:
        print(f"Error researching {carrier}: {e}")
        return 'UNK'

def create_mapping_table(carriers_df: pd.DataFrame) -> pd.DataFrame:
    """Create mapping table for carriers to countries"""
    mappings = []
    
    print(f"Processing {len(carriers_df)} carriers...")
    
    for idx, row in carriers_df.iterrows():
        carrier = row['network_carrier']
        login_count = row['login_count']
        
        # Only process carriers with significant volume (>= 1000 logins)
        if login_count >= 1000:
            country = research_carrier_country(carrier)
            mappings.append({
                'network_carrier': carrier,
                'country_code': country,
                'login_count': login_count
            })
            print(f"  {carrier} -> {country} ({login_count} logins)")
        
        # Add delay to avoid overwhelming
        if idx % 10 == 0:
            time.sleep(0.1)
    
    return pd.DataFrame(mappings)

def update_database_mapping(mapping_df: pd.DataFrame):
    """Update the database with the mapping"""
    conn = get_connection()
    cursor = conn.cursor()
    
    # Clear existing mapping table
    cursor.execute("DELETE FROM risk.test.hding_network_carrier_country_mapping")
    
    # Insert new mappings
    for _, row in mapping_df.iterrows():
        query = """
        INSERT INTO risk.test.hding_network_carrier_country_mapping 
        (network_carrier, country_code) 
        VALUES (%s, %s)
        """
        cursor.execute(query, (row['network_carrier'], row['country_code']))
    
    conn.commit()
    cursor.close()
    conn.close()
    print(f"Updated database with {len(mapping_df)} carrier mappings")

def main():
    """Main function to process network carriers"""
    print("🚀 Starting Network Carrier Country Mapping...")
    
    # Get all carriers
    print("📊 Fetching carriers from database...")
    carriers_df = get_all_carriers()
    print(f"Found {len(carriers_df)} distinct carriers")
    
    # Create mappings
    print("🔍 Creating country mappings...")
    mapping_df = create_mapping_table(carriers_df)
    
    # Update database
    print("💾 Updating database...")
    update_database_mapping(mapping_df)
    
    print("✅ Network carrier mapping completed!")
    print(f"📈 Mapped {len(mapping_df)} carriers covering {mapping_df['login_count'].sum():,} logins")

if __name__ == "__main__":
    main()
