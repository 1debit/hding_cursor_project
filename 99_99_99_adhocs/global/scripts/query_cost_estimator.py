#!/usr/bin/env python3
"""
Snowflake Query Cost Estimator
Analyze query patterns and estimate compute costs before execution.

Usage:
    python scripts/query_cost_estimator.py sql/query.sql
    python scripts/query_cost_estimator.py sql/query.sql --warehouse LARGE_WH
    echo "SELECT * FROM large_table" | python scripts/query_cost_estimator.py -
"""

import sys
import argparse
import re
from pathlib import Path
from typing import Dict, Any, List
from src.sf_client import get_connection

# Warehouse size to credits per hour mapping (approximate)
WAREHOUSE_CREDITS = {
    'X-SMALL': 1,
    'SMALL': 2,
    'MEDIUM': 4,
    'LARGE': 8,
    'X-LARGE': 16,
    '2X-LARGE': 32,
    '3X-LARGE': 64,
    '4X-LARGE': 128
}

class QueryCostEstimator:
    """Estimate Snowflake query costs and provide optimization recommendations."""
    
    def __init__(self, warehouse_size: str = 'MEDIUM'):
        self.warehouse_size = warehouse_size.upper()
        self.credits_per_hour = WAREHOUSE_CREDITS.get(self.warehouse_size, 4)
        
    def analyze_query(self, query: str) -> Dict[str, Any]:
        """
        Analyze query and provide cost estimation and recommendations.
        
        Args:
            query: SQL query to analyze
            
        Returns:
            Dictionary with analysis results
        """
        analysis = {
            'query_preview': query[:200] + ('...' if len(query) > 200 else ''),
            'warehouse_size': self.warehouse_size,
            'credits_per_hour': self.credits_per_hour,
            'risk_factors': [],
            'recommendations': [],
            'estimated_runtime_minutes': 0,
            'estimated_credits': 0,
            'complexity_score': 0
        }
        
        # Analyze query patterns
        query_lower = query.lower()
        
        # Risk factor detection
        if 'select *' in query_lower:
            analysis['risk_factors'].append("SELECT * detected - may scan unnecessary columns")
            analysis['recommendations'].append("Replace SELECT * with explicit column list")
            analysis['complexity_score'] += 2
            
        if 'cross join' in query_lower:
            analysis['risk_factors'].append("CROSS JOIN detected - potential cartesian product")
            analysis['recommendations'].append("Review CROSS JOIN necessity, consider proper JOIN conditions")
            analysis['complexity_score'] += 5
            
        if 'distinct' in query_lower and 'order by' in query_lower:
            analysis['risk_factors'].append("DISTINCT with ORDER BY - expensive sorting operation")
            analysis['recommendations'].append("Consider using QUALIFY with window functions instead")
            analysis['complexity_score'] += 3
            
        # Check for missing WHERE clauses on large table operations
        if re.search(r'from\s+\w+\.\w+\.\w+', query_lower) and 'where' not in query_lower:
            analysis['risk_factors'].append("No WHERE clause - full table scan likely")
            analysis['recommendations'].append("Add WHERE clause to filter data and improve performance")
            analysis['complexity_score'] += 4
            
        # Check for subqueries
        subquery_count = len(re.findall(r'\bselect\b', query_lower)) - 1
        if subquery_count > 0:
            analysis['risk_factors'].append(f"{subquery_count} subqueries detected")
            analysis['recommendations'].append("Consider converting subqueries to CTEs for better readability")
            analysis['complexity_score'] += subquery_count
            
        # Check for window functions
        if 'over(' in query_lower:
            window_count = len(re.findall(r'over\s*\(', query_lower))
            analysis['complexity_score'] += window_count * 2
            if window_count > 3:
                analysis['recommendations'].append("Multiple window functions - consider materialization")
                
        # Estimate runtime based on complexity
        base_runtime = 0.5  # Base 30 seconds
        complexity_multiplier = 1 + (analysis['complexity_score'] * 0.2)
        analysis['estimated_runtime_minutes'] = base_runtime * complexity_multiplier
        
        # Estimate credits (runtime in hours * credits per hour)
        runtime_hours = analysis['estimated_runtime_minutes'] / 60
        analysis['estimated_credits'] = runtime_hours * self.credits_per_hour
        
        # Cost recommendations
        if analysis['estimated_credits'] > 0.1:  # More than 0.1 credits
            analysis['recommendations'].append(f"High cost query (${analysis['estimated_credits']:.3f}) - consider optimization")
            
        if analysis['complexity_score'] > 10:
            analysis['recommendations'].append("High complexity - test on small dataset first")
            
        return analysis
        
    def get_table_stats(self, table_references: List[str]) -> Dict[str, Any]:
        """
        Get statistics for tables referenced in the query.
        
        Args:
            table_references: List of table names found in query
            
        Returns:
            Dictionary with table statistics
        """
        stats = {}
        
        try:
            conn = get_connection()
            cursor = conn.cursor()
            
            for table in table_references:
                # Parse table name (handle fully qualified names)
                parts = table.split('.')
                if len(parts) == 3:
                    database, schema, table_name = parts
                elif len(parts) == 2:
                    schema, table_name = parts
                    database = None
                else:
                    table_name = parts[0]
                    schema = database = None
                
                # Get table statistics
                stats_query = f"""
                SELECT 
                    table_name,
                    row_count,
                    bytes,
                    ROUND(bytes / (1024*1024*1024), 2) as size_gb
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE table_name = '{table_name.upper()}'
                """
                
                if schema:
                    stats_query += f" AND table_schema = '{schema.upper()}'"
                if database:
                    stats_query += f" AND table_catalog = '{database.upper()}'"
                    
                cursor.execute(stats_query)
                result = cursor.fetchone()
                
                if result:
                    stats[table] = {
                        'row_count': result[1] or 0,
                        'size_bytes': result[2] or 0,
                        'size_gb': result[3] or 0
                    }
                else:
                    stats[table] = {'row_count': 'Unknown', 'size_gb': 'Unknown'}
                    
        except Exception as e:
            print(f"Warning: Could not retrieve table statistics: {e}")
            
        finally:
            if 'conn' in locals():
                conn.close()
                
        return stats
        
    def extract_table_references(self, query: str) -> List[str]:
        """Extract table references from SQL query."""
        # Simple regex to find table references after FROM and JOIN
        pattern = r'(?:from|join)\s+([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)*)'
        matches = re.findall(pattern, query.lower())
        return list(set(matches))  # Remove duplicates

def format_analysis_output(analysis: Dict[str, Any], table_stats: Dict[str, Any] = None) -> str:
    """Format analysis results for console output."""
    output = []
    
    # Header
    output.append("\n💰 SNOWFLAKE QUERY COST ANALYSIS")
    output.append("=" * 50)
    
    # Query preview
    output.append(f"\n📝 Query Preview:")
    output.append(f"   {analysis['query_preview']}")
    
    # Cost estimation
    output.append(f"\n💸 Cost Estimation:")
    output.append(f"   Warehouse: {analysis['warehouse_size']} ({analysis['credits_per_hour']} credits/hour)")
    output.append(f"   Estimated Runtime: {analysis['estimated_runtime_minutes']:.1f} minutes")
    output.append(f"   Estimated Credits: {analysis['estimated_credits']:.4f}")
    output.append(f"   Estimated Cost: ${analysis['estimated_credits'] * 2:.4f}")  # Assuming $2/credit
    
    # Complexity analysis
    output.append(f"\n🔍 Complexity Analysis:")
    output.append(f"   Complexity Score: {analysis['complexity_score']}/20")
    
    if analysis['complexity_score'] <= 5:
        output.append("   ✅ Low complexity - should run quickly")
    elif analysis['complexity_score'] <= 10:
        output.append("   ⚠️  Medium complexity - monitor performance")
    else:
        output.append("   🚨 High complexity - test carefully")
    
    # Risk factors
    if analysis['risk_factors']:
        output.append(f"\n⚠️  Risk Factors:")
        for risk in analysis['risk_factors']:
            output.append(f"   • {risk}")
    else:
        output.append(f"\n✅ No major risk factors detected")
    
    # Recommendations
    if analysis['recommendations']:
        output.append(f"\n💡 Recommendations:")
        for rec in analysis['recommendations']:
            output.append(f"   • {rec}")
    
    # Table statistics
    if table_stats:
        output.append(f"\n📊 Referenced Tables:")
        for table, stats in table_stats.items():
            if isinstance(stats.get('row_count'), int):
                output.append(f"   • {table}: {stats['row_count']:,} rows, {stats['size_gb']} GB")
            else:
                output.append(f"   • {table}: Stats unavailable")
    
    return '\n'.join(output)

def main():
    parser = argparse.ArgumentParser(
        description='Estimate Snowflake query costs and analyze performance risks',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'query_file',
        help='SQL file to analyze (use "-" for stdin)'
    )
    
    parser.add_argument(
        '--warehouse',
        default='MEDIUM',
        help='Warehouse size for cost calculation (default: MEDIUM)'
    )
    
    parser.add_argument(
        '--no-table-stats',
        action='store_true',
        help='Skip table statistics lookup'
    )
    
    args = parser.parse_args()
    
    try:
        # Read query
        if args.query_file == '-':
            query = sys.stdin.read()
        else:
            query_path = Path(args.query_file)
            query = query_path.read_text(encoding='utf-8')
        
        if not query.strip():
            print("❌ No query provided")
            sys.exit(1)
        
        # Analyze query
        estimator = QueryCostEstimator(args.warehouse)
        analysis = estimator.analyze_query(query)
        
        # Get table statistics unless disabled
        table_stats = None
        if not args.no_table_stats:
            table_refs = estimator.extract_table_references(query)
            if table_refs:
                table_stats = estimator.get_table_stats(table_refs)
        
        # Display results
        print(format_analysis_output(analysis, table_stats))
        
        # Exit with warning code if high cost/complexity
        if analysis['estimated_credits'] > 0.5 or analysis['complexity_score'] > 15:
            print(f"\n⚠️  High cost/complexity query - proceed with caution!")
            sys.exit(2)
        
    except Exception as e:
        print(f"❌ Error analyzing query: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
