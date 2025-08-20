#!/usr/bin/env python3
"""
Table Profiling Script for Snowflake
Generate comprehensive data profile for any Snowflake table.

Usage:
    python scripts/profile_table.py DATABASE.SCHEMA.TABLE_NAME
    python scripts/profile_table.py DATABASE.SCHEMA.TABLE_NAME --sample-size 5000
    python scripts/profile_table.py DATABASE.SCHEMA.TABLE_NAME --output profile_report.json
"""

import sys
import json
import argparse
from pathlib import Path
from src.sf_utils import SnowflakeUtils

def format_profile_output(profile: dict) -> str:
    """Format profile results for readable console output."""
    output = []
    
    # Table overview
    output.append(f"\n📊 TABLE PROFILE: {profile['table_name']}")
    output.append("=" * 60)
    output.append(f"Total Rows: {profile['total_rows']:,}")
    output.append(f"Unique Rows: {profile['unique_rows']:,}")
    output.append(f"Duplicate Rows: {profile['duplicate_rows']:,}")
    output.append(f"Columns: {profile['column_count']}")
    output.append(f"Sample Size: {profile['sample_size']:,}")
    
    # Column details
    output.append(f"\n📋 COLUMN ANALYSIS:")
    output.append("-" * 60)
    
    for col_name, col_profile in profile['column_profiles'].items():
        output.append(f"\n🔹 {col_name.upper()}")
        output.append(f"   Type: {col_profile['data_type']}")
        output.append(f"   Nulls: {col_profile['null_count']} ({col_profile['null_percentage']:.1f}%)")
        output.append(f"   Unique Values: {col_profile['unique_count']}")
        
        if col_profile.get('min') is not None:
            output.append(f"   Range: {col_profile['min']} - {col_profile['max']}")
            output.append(f"   Mean: {col_profile['mean']:.2f}")
            output.append(f"   Median: {col_profile['median']:.2f}")
        
        if col_profile['sample_values']:
            sample_str = ', '.join(str(v) for v in col_profile['sample_values'][:3])
            output.append(f"   Sample Values: {sample_str}...")
    
    # Data quality assessment
    output.append(f"\n🎯 DATA QUALITY ASSESSMENT:")
    output.append("-" * 60)
    
    uniqueness_pct = (profile['unique_rows'] / profile['total_rows']) * 100
    if uniqueness_pct == 100:
        output.append("✅ No duplicate rows detected")
    elif uniqueness_pct > 95:
        output.append("⚠️  Low duplicate rate (< 5%)")
    else:
        output.append("🚨 High duplicate rate (> 5%)")
    
    # Null analysis
    high_null_cols = [
        col for col, details in profile['column_profiles'].items()
        if details['null_percentage'] > 20
    ]
    
    if high_null_cols:
        output.append(f"⚠️  High null columns (>20%): {', '.join(high_null_cols)}")
    else:
        output.append("✅ No columns with excessive nulls")
    
    return '\n'.join(output)

def main():
    parser = argparse.ArgumentParser(
        description='Profile a Snowflake table and analyze data quality',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/profile_table.py ANALYTICS.PUBLIC.SALES
  python scripts/profile_table.py ANALYTICS.PUBLIC.SALES --sample-size 10000
  python scripts/profile_table.py ANALYTICS.PUBLIC.SALES --output profile.json
        """
    )
    
    parser.add_argument(
        'table_name',
        help='Fully qualified table name (DATABASE.SCHEMA.TABLE)'
    )
    
    parser.add_argument(
        '--sample-size',
        type=int,
        default=1000,
        help='Number of rows to sample for detailed analysis (default: 1000)'
    )
    
    parser.add_argument(
        '--output',
        help='Save detailed profile to JSON file'
    )
    
    parser.add_argument(
        '--quiet',
        action='store_true',
        help='Suppress console output (useful when saving to file)'
    )
    
    args = parser.parse_args()
    
    try:
        print(f"🔍 Profiling table: {args.table_name}")
        print(f"📊 Sample size: {args.sample_size:,} rows")
        
        utils = SnowflakeUtils()
        profile = utils.profile_table(args.table_name, args.sample_size)
        
        # Save to file if requested
        if args.output:
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_path, 'w') as f:
                json.dump(profile, f, indent=2, default=str)
            
            print(f"💾 Profile saved to: {output_path}")
        
        # Display results unless quiet mode
        if not args.quiet:
            print(format_profile_output(profile))
        
        print(f"\n✅ Profiling completed successfully!")
        
    except Exception as e:
        print(f"❌ Error profiling table: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
