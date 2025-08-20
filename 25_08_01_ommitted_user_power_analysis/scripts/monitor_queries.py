#!/usr/bin/env python3
"""
Snowflake Query Monitor
Monitor running and recent queries, identify performance issues.

Usage:
    python scripts/monitor_queries.py
    python scripts/monitor_queries.py --running-only
    python scripts/monitor_queries.py --user my_username --hours 24
    python scripts/monitor_queries.py --expensive --min-credits 0.1
"""

import argparse
from datetime import datetime, timedelta
from typing import Dict, Any, List
import pandas as pd
from src.sf_utils import SnowflakeUtils

class QueryMonitor:
    """Monitor Snowflake queries and identify performance issues."""
    
    def __init__(self):
        self.utils = SnowflakeUtils()
        
    def get_recent_queries(self, hours: int = 4, user_name: str = None, 
                          running_only: bool = False, min_credits: float = 0) -> pd.DataFrame:
        """
        Get recent query history with filtering options.
        
        Args:
            hours: Hours to look back
            user_name: Filter by specific user
            running_only: Only show currently running queries
            min_credits: Minimum credits consumed filter
            
        Returns:
            DataFrame with query information
        """
        
        # Base query for query history
        query = f"""
        SELECT 
            query_id,
            query_text,
            user_name,
            role_name,
            warehouse_name,
            warehouse_size,
            execution_status,
            error_code,
            error_message,
            start_time,
            end_time,
            total_elapsed_time / 1000 as elapsed_seconds,
            queued_provisioning_time / 1000 as queue_seconds,
            compilation_time / 1000 as compile_seconds,
            execution_time / 1000 as execution_seconds,
            bytes_scanned,
            rows_produced,
            credits_used_cloud_services,
            warehouse_type,
            query_type,
            session_id
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD('hour', -{hours}, CURRENT_TIMESTAMP())
        """
        
        # Add filters
        if user_name:
            query += f" AND UPPER(user_name) = UPPER('{user_name}')"
            
        if running_only:
            query += " AND execution_status = 'RUNNING'"
            
        if min_credits > 0:
            query += f" AND credits_used_cloud_services >= {min_credits}"
        
        # Order by start time
        query += " ORDER BY start_time DESC LIMIT 100"
        
        return self.utils.query_to_df(query)
    
    def get_expensive_queries(self, hours: int = 24, min_credits: float = 0.01) -> pd.DataFrame:
        """Get queries that consumed significant credits."""
        
        query = f"""
        SELECT 
            query_id,
            LEFT(query_text, 100) as query_preview,
            user_name,
            warehouse_name,
            warehouse_size,
            start_time,
            total_elapsed_time / 1000 as elapsed_seconds,
            credits_used_cloud_services,
            bytes_scanned,
            rows_produced,
            ROUND(credits_used_cloud_services * 2, 4) as estimated_cost_usd
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD('hour', -{hours}, CURRENT_TIMESTAMP())
            AND credits_used_cloud_services >= {min_credits}
            AND execution_status = 'SUCCESS'
        ORDER BY credits_used_cloud_services DESC
        LIMIT 20
        """
        
        return self.utils.query_to_df(query)
    
    def get_slow_queries(self, hours: int = 24, min_seconds: int = 30) -> pd.DataFrame:
        """Get queries that took a long time to execute."""
        
        query = f"""
        SELECT 
            query_id,
            LEFT(query_text, 100) as query_preview,
            user_name,
            warehouse_name,
            warehouse_size,
            start_time,
            total_elapsed_time / 1000 as elapsed_seconds,
            queued_provisioning_time / 1000 as queue_seconds,
            execution_time / 1000 as execution_seconds,
            bytes_scanned,
            rows_produced
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD('hour', -{hours}, CURRENT_TIMESTAMP())
            AND total_elapsed_time >= {min_seconds * 1000}
            AND execution_status = 'SUCCESS'
        ORDER BY total_elapsed_time DESC
        LIMIT 20
        """
        
        return self.utils.query_to_df(query)
    
    def get_failed_queries(self, hours: int = 24) -> pd.DataFrame:
        """Get queries that failed with errors."""
        
        query = f"""
        SELECT 
            query_id,
            LEFT(query_text, 100) as query_preview,
            user_name,
            warehouse_name,
            start_time,
            error_code,
            error_message,
            total_elapsed_time / 1000 as elapsed_seconds
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD('hour', -{hours}, CURRENT_TIMESTAMP())
            AND execution_status = 'FAIL'
        ORDER BY start_time DESC
        LIMIT 20
        """
        
        return self.utils.query_to_df(query)
    
    def get_warehouse_utilization(self, hours: int = 24) -> pd.DataFrame:
        """Get warehouse utilization statistics."""
        
        query = f"""
        WITH warehouse_stats AS (
            SELECT 
                warehouse_name,
                warehouse_size,
                COUNT(*) as query_count,
                SUM(credits_used_cloud_services) as total_credits,
                AVG(total_elapsed_time / 1000) as avg_elapsed_seconds,
                SUM(bytes_scanned) as total_bytes_scanned,
                SUM(rows_produced) as total_rows_produced
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE start_time >= DATEADD('hour', -{hours}, CURRENT_TIMESTAMP())
                AND execution_status = 'SUCCESS'
            GROUP BY warehouse_name, warehouse_size
        )
        SELECT 
            warehouse_name,
            warehouse_size,
            query_count,
            ROUND(total_credits, 4) as total_credits,
            ROUND(total_credits * 2, 4) as estimated_cost_usd,
            ROUND(avg_elapsed_seconds, 1) as avg_elapsed_seconds,
            ROUND(total_bytes_scanned / (1024*1024*1024), 2) as total_gb_scanned,
            total_rows_produced
        FROM warehouse_stats
        ORDER BY total_credits DESC
        """
        
        return self.utils.query_to_df(query)
    
    def analyze_query_patterns(self, hours: int = 24) -> Dict[str, Any]:
        """Analyze query patterns and provide insights."""
        
        # Get basic statistics
        stats_query = f"""
        SELECT 
            COUNT(*) as total_queries,
            SUM(CASE WHEN execution_status = 'SUCCESS' THEN 1 ELSE 0 END) as successful_queries,
            SUM(CASE WHEN execution_status = 'FAIL' THEN 1 ELSE 0 END) as failed_queries,
            SUM(CASE WHEN execution_status = 'RUNNING' THEN 1 ELSE 0 END) as running_queries,
            AVG(total_elapsed_time / 1000) as avg_elapsed_seconds,
            SUM(credits_used_cloud_services) as total_credits,
            COUNT(DISTINCT user_name) as unique_users,
            COUNT(DISTINCT warehouse_name) as warehouses_used
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD('hour', -{hours}, CURRENT_TIMESTAMP())
        """
        
        stats_df = self.utils.query_to_df(stats_query)
        stats = stats_df.iloc[0].to_dict()
        
        # Calculate success rate
        stats['success_rate'] = (stats['successful_queries'] / stats['total_queries']) * 100 if stats['total_queries'] > 0 else 0
        stats['estimated_cost_usd'] = stats['total_credits'] * 2  # Assuming $2/credit
        
        return stats

def format_monitor_output(queries_df: pd.DataFrame, title: str) -> str:
    """Format monitoring results for console output."""
    output = [f"\n📊 {title}"]
    output.append("=" * 60)
    
    if queries_df.empty:
        output.append("No queries found matching criteria.")
        return '\n'.join(output)
    
    for _, row in queries_df.head(10).iterrows():  # Show top 10
        output.append(f"\n🔍 Query ID: {row.get('query_id', 'N/A')[:8]}...")
        
        if 'query_preview' in row:
            output.append(f"   Query: {row['query_preview']}...")
        elif 'query_text' in row:
            preview = str(row['query_text'])[:80] + ('...' if len(str(row['query_text'])) > 80 else '')
            output.append(f"   Query: {preview}")
            
        output.append(f"   User: {row.get('user_name', 'N/A')}")
        output.append(f"   Warehouse: {row.get('warehouse_name', 'N/A')} ({row.get('warehouse_size', 'N/A')})")
        
        if 'start_time' in row:
            output.append(f"   Started: {row['start_time']}")
        
        if 'elapsed_seconds' in row:
            output.append(f"   Duration: {row['elapsed_seconds']:.1f}s")
            
        if 'credits_used_cloud_services' in row and pd.notna(row['credits_used_cloud_services']):
            output.append(f"   Credits: {row['credits_used_cloud_services']:.4f}")
            
        if 'error_message' in row and pd.notna(row['error_message']):
            error_msg = str(row['error_message'])[:100] + ('...' if len(str(row['error_message'])) > 100 else '')
            output.append(f"   Error: {error_msg}")
    
    if len(queries_df) > 10:
        output.append(f"\n... and {len(queries_df) - 10} more queries")
    
    return '\n'.join(output)

def main():
    parser = argparse.ArgumentParser(
        description='Monitor Snowflake queries and identify performance issues',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--hours',
        type=int,
        default=4,
        help='Hours to look back (default: 4)'
    )
    
    parser.add_argument(
        '--user',
        help='Filter by specific user name'
    )
    
    parser.add_argument(
        '--running-only',
        action='store_true',
        help='Show only currently running queries'
    )
    
    parser.add_argument(
        '--expensive',
        action='store_true',
        help='Show expensive queries (high credit usage)'
    )
    
    parser.add_argument(
        '--slow',
        action='store_true',
        help='Show slow queries (long execution time)'
    )
    
    parser.add_argument(
        '--failed',
        action='store_true',
        help='Show failed queries only'
    )
    
    parser.add_argument(
        '--warehouse-stats',
        action='store_true',
        help='Show warehouse utilization statistics'
    )
    
    parser.add_argument(
        '--min-credits',
        type=float,
        default=0.001,
        help='Minimum credits for expensive query filter (default: 0.001)'
    )
    
    args = parser.parse_args()
    
    try:
        monitor = QueryMonitor()
        
        print(f"🔍 Monitoring Snowflake queries (last {args.hours} hours)")
        
        # Show summary statistics
        stats = monitor.analyze_query_patterns(args.hours)
        print(f"\n📈 SUMMARY STATISTICS")
        print("=" * 40)
        print(f"Total Queries: {stats['total_queries']}")
        print(f"Success Rate: {stats['success_rate']:.1f}%")
        print(f"Total Credits: {stats['total_credits']:.4f}")
        print(f"Estimated Cost: ${stats['estimated_cost_usd']:.4f}")
        print(f"Avg Duration: {stats['avg_elapsed_seconds']:.1f}s")
        print(f"Active Users: {stats['unique_users']}")
        print(f"Warehouses Used: {stats['warehouses_used']}")
        
        # Show specific query types based on flags
        if args.expensive or not any([args.running_only, args.slow, args.failed, args.warehouse_stats]):
            expensive_df = monitor.get_expensive_queries(args.hours, args.min_credits)
            print(format_monitor_output(expensive_df, f"EXPENSIVE QUERIES (>{args.min_credits} credits)"))
            
        if args.slow:
            slow_df = monitor.get_slow_queries(args.hours, 30)
            print(format_monitor_output(slow_df, "SLOW QUERIES (>30 seconds)"))
            
        if args.failed:
            failed_df = monitor.get_failed_queries(args.hours)
            print(format_monitor_output(failed_df, "FAILED QUERIES"))
            
        if args.running_only:
            running_df = monitor.get_recent_queries(args.hours, args.user, running_only=True)
            print(format_monitor_output(running_df, "CURRENTLY RUNNING QUERIES"))
            
        if args.warehouse_stats:
            warehouse_df = monitor.get_warehouse_utilization(args.hours)
            print(format_monitor_output(warehouse_df, "WAREHOUSE UTILIZATION"))
            
        # Show recent queries if no specific filter
        if not any([args.expensive, args.slow, args.failed, args.running_only, args.warehouse_stats]):
            recent_df = monitor.get_recent_queries(args.hours, args.user, min_credits=args.min_credits)
            print(format_monitor_output(recent_df, "RECENT QUERIES"))
            
    except Exception as e:
        print(f"❌ Error monitoring queries: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
