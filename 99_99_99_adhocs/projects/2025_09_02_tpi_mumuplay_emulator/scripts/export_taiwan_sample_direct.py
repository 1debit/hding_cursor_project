#!/opt/homebrew/bin/python3
"""
Export Taiwan Network Carrier Sample Cases to Excel - Direct Snowflake Connector
Uses direct snowflake.connector for better compatibility
"""

import sys
import os
import pandas as pd
import snowflake.connector
from datetime import datetime
from pathlib import Path

def export_taiwan_sample():
    """Export Taiwan sample cases to Excel with proper formatting"""
    
    # SQL query to get the sample data
    query = """
    SELECT
        user_id,
        account_creation_date,
        mob_as_of_today,
        login_date,
        card_activated,
        dder_payroll,
        user_status
    FROM RISK.TEST.taiwan_sample_50_cases
    ORDER BY mob_as_of_today DESC, user_id;
    """
    
    try:
        # Connect to Snowflake using direct connector
        conn = snowflake.connector.connect(
            user='HAO.DING@CHIME.COM',
            account='CHIME',
            warehouse='RISK_WH',
            role='SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA',
            authenticator='externalbrowser'
        )
        
        # Execute query
        cursor = conn.cursor()
        cursor.execute(query)
        
        # Get column names
        columns = [desc[0] for desc in cursor.description]
        
        # Fetch all results
        results = cursor.fetchall()
        
        # Create DataFrame
        df = pd.DataFrame(results, columns=columns)
        
        # Format datetime columns (remove timezone for Excel compatibility)
        if 'account_creation_date' in df.columns:
            df['account_creation_date'] = pd.to_datetime(df['account_creation_date']).dt.tz_localize(None)
        if 'login_date' in df.columns:
            df['login_date'] = pd.to_datetime(df['login_date']).dt.tz_localize(None)
        
        # Generate output filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = f"/Users/hao.ding/Documents/GitHub/hding_cursor_project/99_99_99_adhocs/projects/2025_09_02_tpi_mumuplay_emulator/outputs/taiwan_sample_50_cases_{timestamp}.xlsx"
        
        # Create outputs directory if it doesn't exist
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        # Export to Excel
        with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='Taiwan_Sample_Cases', index=False)
            
            # Get the workbook and worksheet
            workbook = writer.book
            worksheet = writer.sheets['Taiwan_Sample_Cases']
            
            # Auto-adjust column widths
            for column in worksheet.columns:
                max_length = 0
                column_letter = column[0].column_letter
                for cell in column:
                    try:
                        if len(str(cell.value)) > max_length:
                            max_length = len(str(cell.value))
                    except:
                        pass
                adjusted_width = min(max_length + 2, 50)
                worksheet.column_dimensions[column_letter].width = adjusted_width
        
        print(f"✅ Successfully exported {len(df)} Taiwan sample cases to:")
        print(f"   {output_file}")
        
        # Display summary statistics
        print(f"\n📊 Sample Summary:")
        print(f"   Total users: {len(df)}")
        print(f"   MOB range: {df['mob_as_of_today'].min()} - {df['mob_as_of_today'].max()} months")
        print(f"   Card activated: {df['card_activated'].value_counts().get('Yes', 0)} users")
        print(f"   Payroll DD: {df['dder_payroll'].value_counts().get('Yes', 0)} users")
        print(f"   Active status: {df['user_status'].value_counts().get('active', 0)} users")
        
        # Close connections
        cursor.close()
        conn.close()
        
        return output_file
        
    except Exception as e:
        print(f"❌ Error exporting Taiwan sample data: {str(e)}")
        return None

if __name__ == "__main__":
    export_taiwan_sample()
