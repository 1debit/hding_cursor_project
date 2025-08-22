"""
Snowflake Utility Functions for Data Analysis and Profiling
Enhanced utilities for common Snowflake operations and data exploration.
"""

import pandas as pd
from typing import Dict, List, Optional, Tuple, Any
from src.sf_client import get_connection
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SnowflakeUtils:
    """Utility class for common Snowflake operations and data profiling."""
    
    def __init__(self, session_params: Optional[Dict[str, Any]] = None):
        """Initialize with optional session parameters."""
        self.session_params = session_params or {}
        
    def query_to_df(self, query: str, limit: Optional[int] = None) -> pd.DataFrame:
        """
        Execute query and return results as pandas DataFrame.
        
        Args:
            query: SQL query to execute
            limit: Optional row limit for large result sets
            
        Returns:
            pandas.DataFrame with query results
        """
        if limit:
            query = f"SELECT * FROM ({query}) LIMIT {limit}"
            
        conn = get_connection(self.session_params)
        try:
            logger.info(f"Executing query (limit={limit}): {query[:100]}...")
            df = pd.read_sql(query, conn)
            logger.info(f"Retrieved {len(df)} rows, {len(df.columns)} columns")
            return df
        finally:
            conn.close()
    
    def profile_table(self, table_name: str, sample_size: int = 1000) -> Dict[str, Any]:
        """
        Generate comprehensive data profile for a table.
        
        Args:
            table_name: Fully qualified table name (DB.SCHEMA.TABLE)
            sample_size: Number of rows to sample for detailed analysis
            
        Returns:
            Dictionary with profiling results
        """
        logger.info(f"Profiling table: {table_name}")
        
        # Get table metadata
        meta_query = f"""
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default,
            comment
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE table_name = SPLIT_PART('{table_name}', '.', 3)
            AND table_schema = SPLIT_PART('{table_name}', '.', 2)
            AND table_catalog = SPLIT_PART('{table_name}', '.', 1)
        ORDER BY ordinal_position
        """
        
        # Get basic statistics
        stats_query = f"""
        SELECT 
            COUNT(*) as total_rows,
            COUNT(DISTINCT *) as unique_rows,
            (COUNT(*) - COUNT(DISTINCT *)) as duplicate_rows
        FROM {table_name}
        """
        
        # Get column statistics for sample
        sample_query = f"""
        WITH sample_data AS (
            SELECT * FROM {table_name} SAMPLE({sample_size} ROWS)
        )
        SELECT * FROM sample_data
        """
        
        conn = get_connection(self.session_params)
        try:
            # Execute profiling queries
            metadata_df = pd.read_sql(meta_query, conn)
            stats_df = pd.read_sql(stats_query, conn)
            sample_df = pd.read_sql(sample_query, conn)
            
            # Generate column-level profiles
            column_profiles = {}
            for col in sample_df.columns:
                col_data = sample_df[col]
                profile = {
                    'data_type': str(col_data.dtype),
                    'null_count': col_data.isnull().sum(),
                    'null_percentage': (col_data.isnull().sum() / len(col_data)) * 100,
                    'unique_count': col_data.nunique(),
                    'sample_values': col_data.dropna().unique()[:5].tolist()
                }
                
                # Add numeric statistics if applicable
                if pd.api.types.is_numeric_dtype(col_data):
                    profile.update({
                        'min': col_data.min(),
                        'max': col_data.max(),
                        'mean': col_data.mean(),
                        'median': col_data.median(),
                        'std': col_data.std()
                    })
                
                column_profiles[col] = profile
            
            return {
                'table_name': table_name,
                'total_rows': stats_df['TOTAL_ROWS'].iloc[0],
                'unique_rows': stats_df['UNIQUE_ROWS'].iloc[0],
                'duplicate_rows': stats_df['DUPLICATE_ROWS'].iloc[0],
                'column_count': len(metadata_df),
                'sample_size': len(sample_df),
                'metadata': metadata_df.to_dict('records'),
                'column_profiles': column_profiles
            }
            
        finally:
            conn.close()
    
    def check_data_quality(self, table_name: str) -> Dict[str, Any]:
        """
        Run data quality checks on a table.
        
        Args:
            table_name: Fully qualified table name
            
        Returns:
            Dictionary with data quality results
        """
        logger.info(f"Running data quality checks on: {table_name}")
        
        quality_query = f"""
        WITH base_stats AS (
            SELECT 
                COUNT(*) as total_rows,
                COUNT(DISTINCT *) as unique_rows
            FROM {table_name}
        ),
        column_nulls AS (
            SELECT 
                column_name,
                SUM(CASE WHEN column_value IS NULL THEN 1 ELSE 0 END) as null_count
            FROM (
                SELECT * FROM {table_name} SAMPLE(10000 ROWS)
            ) 
            UNPIVOT(column_value FOR column_name IN ({self._get_columns_for_unpivot(table_name)}))
            GROUP BY column_name
        )
        SELECT 
            bs.total_rows,
            bs.unique_rows,
            (bs.total_rows - bs.unique_rows) as duplicate_rows,
            ROUND((bs.unique_rows::FLOAT / bs.total_rows) * 100, 2) as uniqueness_percentage
        FROM base_stats bs
        """
        
        return self.query_to_df(quality_query).to_dict('records')[0]
    
    def find_duplicates(self, table_name: str, key_columns: List[str], limit: int = 100) -> pd.DataFrame:
        """
        Find duplicate records based on specified key columns.
        
        Args:
            table_name: Fully qualified table name
            key_columns: List of column names to check for duplicates
            limit: Maximum number of duplicate groups to return
            
        Returns:
            DataFrame with duplicate records
        """
        key_cols_str = ', '.join(key_columns)
        
        duplicate_query = f"""
        WITH duplicates AS (
            SELECT 
                {key_cols_str},
                COUNT(*) as duplicate_count,
                LISTAGG(DISTINCT _row_id, ', ') WITHIN GROUP (ORDER BY _row_id) as row_ids
            FROM (
                SELECT *, ROW_NUMBER() OVER (ORDER BY 1) as _row_id
                FROM {table_name}
            )
            GROUP BY {key_cols_str}
            HAVING COUNT(*) > 1
            ORDER BY duplicate_count DESC
            LIMIT {limit}
        )
        SELECT * FROM duplicates
        """
        
        return self.query_to_df(duplicate_query)
    
    def compare_tables(self, table1: str, table2: str, key_column: str) -> Dict[str, Any]:
        """
        Compare two tables and identify differences.
        
        Args:
            table1: First table name
            table2: Second table name  
            key_column: Column to use for joining/comparison
            
        Returns:
            Dictionary with comparison results
        """
        logger.info(f"Comparing tables: {table1} vs {table2}")
        
        comparison_query = f"""
        WITH t1_counts AS (
            SELECT COUNT(*) as count_t1 FROM {table1}
        ),
        t2_counts AS (
            SELECT COUNT(*) as count_t2 FROM {table2}
        ),
        common_keys AS (
            SELECT COUNT(*) as common_count
            FROM {table1} t1
            INNER JOIN {table2} t2 ON t1.{key_column} = t2.{key_column}
        ),
        only_in_t1 AS (
            SELECT COUNT(*) as only_t1_count
            FROM {table1} t1
            LEFT JOIN {table2} t2 ON t1.{key_column} = t2.{key_column}
            WHERE t2.{key_column} IS NULL
        ),
        only_in_t2 AS (
            SELECT COUNT(*) as only_t2_count
            FROM {table2} t2
            LEFT JOIN {table1} t1 ON t2.{key_column} = t1.{key_column}
            WHERE t1.{key_column} IS NULL
        )
        SELECT 
            t1.count_t1,
            t2.count_t2,
            c.common_count,
            o1.only_t1_count,
            o2.only_t2_count
        FROM t1_counts t1
        CROSS JOIN t2_counts t2
        CROSS JOIN common_keys c
        CROSS JOIN only_in_t1 o1
        CROSS JOIN only_in_t2 o2
        """
        
        return self.query_to_df(comparison_query).to_dict('records')[0]
    
    def get_table_lineage(self, table_name: str) -> pd.DataFrame:
        """
        Get table lineage information from Snowflake's metadata.
        
        Args:
            table_name: Fully qualified table name
            
        Returns:
            DataFrame with lineage information
        """
        lineage_query = f"""
        SELECT 
            query_id,
            query_text,
            user_name,
            role_name,
            warehouse_name,
            start_time,
            end_time,
            total_elapsed_time,
            rows_produced,
            bytes_scanned
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE query_text ILIKE '%{table_name}%'
            AND query_type IN ('CREATE_TABLE', 'CREATE_VIEW', 'INSERT', 'UPDATE', 'DELETE')
            AND start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
        ORDER BY start_time DESC
        LIMIT 50
        """
        
        return self.query_to_df(lineage_query)
    
    def _get_columns_for_unpivot(self, table_name: str) -> str:
        """Helper method to get column list for unpivot operations."""
        # This is a simplified version - in practice you'd query INFORMATION_SCHEMA
        # to get the actual column names
        return "*"  # Placeholder - would need actual implementation
    
    def export_to_csv(self, query: str, filename: str, limit: Optional[int] = None) -> str:
        """
        Execute query and export results to CSV file.
        
        Args:
            query: SQL query to execute
            filename: Output CSV filename
            limit: Optional row limit
            
        Returns:
            Path to created CSV file
        """
        df = self.query_to_df(query, limit)
        output_path = f"exports/{filename}"
        df.to_csv(output_path, index=False)
        logger.info(f"Exported {len(df)} rows to {output_path}")
        return output_path

# Convenience functions for common operations
def quick_profile(table_name: str, sample_size: int = 1000) -> Dict[str, Any]:
    """Quick table profiling function."""
    utils = SnowflakeUtils()
    return utils.profile_table(table_name, sample_size)

def quick_query(query: str, limit: Optional[int] = 100) -> pd.DataFrame:
    """Quick query execution function."""
    utils = SnowflakeUtils()
    return utils.query_to_df(query, limit)
