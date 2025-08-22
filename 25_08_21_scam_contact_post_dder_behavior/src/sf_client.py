import os
import pandas as pd
from typing import Optional, Dict, Any
from pathlib import Path
from sqlalchemy import create_engine
from snowflake.sqlalchemy import URL

# Load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # Fallback if dotenv not available
    pass

def _env(name: str, default: Optional[str] = None) -> Optional[str]:
    return os.getenv(name, default)

def get_connection(session_params: Optional[Dict[str, Any]] = None):
    """
    Create Snowflake connection using SQLAlchemy with external browser authentication.
    This matches the Chime standard connection pattern with SSO/OKTA authentication.
    """
    
    # Get connection parameters from environment
    account = _env("SNOWFLAKE_ACCOUNT", "CHIME")
    user = _env("SNOWFLAKE_USER", "HAO.DING@CHIME.COM")
    role = _env("SNOWFLAKE_ROLE", "SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA")
    warehouse = _env("SNOWFLAKE_WAREHOUSE", "RISK_WH")
    database = _env("SNOWFLAKE_DATABASE", "RISK")
    schema = _env("SNOWFLAKE_SCHEMA", "TEST")
    authenticator = _env("SNOWFLAKE_AUTHENTICATOR", "externalbrowser")
    
    # Create Snowflake SQLAlchemy URL
    url = URL(
        user=user,
        authenticator=authenticator,
        account=account,
        warehouse=warehouse,
        role=role,
        database=database,
        schema=schema
    )
    
    # Create SQLAlchemy engine and connection
    engine = create_engine(url)
    connection = engine.connect()
    
    return connection

def get_pandas_connection():
    """
    Get connection specifically optimized for pandas operations.
    Returns the SQLAlchemy engine for use with pd.read_sql().
    """
    account = _env("SNOWFLAKE_ACCOUNT", "CHIME")
    user = _env("SNOWFLAKE_USER", "HAO.DING@CHIME.COM")
    role = _env("SNOWFLAKE_ROLE", "SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA")
    warehouse = _env("SNOWFLAKE_WAREHOUSE", "RISK_WH")
    authenticator = _env("SNOWFLAKE_AUTHENTICATOR", "externalbrowser")
    
    url = URL(
        user=user,
        authenticator=authenticator,
        account=account,
        warehouse=warehouse,
        role=role
    )
    
    return create_engine(url)

def execute_query(query: str, database: str = None, schema: str = None) -> pd.DataFrame:
    """
    Execute a query and return results as a pandas DataFrame.
    
    Args:
        query: SQL query to execute
        database: Optional database override
        schema: Optional schema override
    
    Returns:
        pandas.DataFrame with query results
    """
    engine = get_pandas_connection()
    
    try:
        # Use pandas read_sql directly with the engine
        return pd.read_sql(query, engine)
    except Exception as e:
        # If that fails, try with a connection
        with engine.connect() as conn:
            return pd.read_sql(query, conn)
