from sqlalchemy import create_engine, text
from snowflake.sqlalchemy import URL
import os

def main():
    try:
        print("🔍 Testing Snowflake Connection...")
        print("🌐 Opening browser for SSO authentication...")
        
        # Create connection using your preferred method
        url = URL(
            user=os.getenv('SNOWFLAKE_USER', 'HAO.DING@CHIME.COM'),
            authenticator=os.getenv('SNOWFLAKE_AUTHENTICATOR', 'externalbrowser'),
            account=os.getenv('SNOWFLAKE_ACCOUNT', 'CHIME'),
            warehouse=os.getenv('SNOWFLAKE_WAREHOUSE', 'RISK_WH'),
            role=os.getenv('SNOWFLAKE_ROLE', 'SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA'),
            database=os.getenv('SNOWFLAKE_DATABASE', 'RISK'),
            schema=os.getenv('SNOWFLAKE_SCHEMA', 'TEST')
        )
        
        engine = create_engine(url)
        
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    CURRENT_ACCOUNT() as account,
                    CURRENT_USER() as user,
                    CURRENT_ROLE() as role,
                    CURRENT_WAREHOUSE() as warehouse,
                    CURRENT_DATABASE() as database,
                    CURRENT_SCHEMA() as schema,
                    CURRENT_TIMESTAMP() as connected_at
            """))
            
            row = result.fetchone()
            
            print("\n✅ CONNECTION SUCCESSFUL!")
            print("=" * 50)
            print(f"🏛️  Account: {row[0]}")
            print(f"👤 User: {row[1]}")
            print(f"🎭 Role: {row[2]}")
            print(f"🏭 Warehouse: {row[3]}")
            print(f"🗄️  Database: {row[4]}")
            print(f"📁 Schema: {row[5]}")
            print(f"🕐 Connected at: {row[6]}")
            print("\n🎯 Ready for RISK analytics with Cursor AI!")
            
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("💡 Make sure you complete the browser authentication when prompted")

if __name__ == "__main__":
    main()
