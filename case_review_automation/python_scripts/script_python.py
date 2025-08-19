%env GITHUB_TOKEN= #!! replace with yours!!

## execution
import pandas as pd
from pathlib import Path
#print(str(Path.home())+'/Downloads/')
import os
from sqlalchemy import create_engine
from snowflake.sqlalchemy import URL
from github import Github

#snowflake connection
url = URL(
    user='HEMALI.SHAH@CHIME.COM', # !! check snowflake console for user in case sometimes it changes btw HAO.DING and work email
    authenticator='externalbrowser',
    account='chime',
    warehouse='RISK_WH',
    role='REST_ROLE' 
    )
connection = create_engine(url).connect()

#connect github and pull sql
g = Github('XXXX')   # ## insert your github tokn here instead of XXXX

#repo = g.get_user().get_repo("Adhoc_SQL")
repo = g.get_organization('1debit').get_repo('Adhoc_SQL')
sql = repo.get_contents("case review/weekly_top_10_cases.sql").decoded_content.decode("utf-8")

#run sql with snowflake connection
df = pd.read_sql(sql.replace('%','%%'), connection) # python will misinterpret % if without replacement

# generate top 10 list for next sql
top_disp_lst = df.user_id.astype(int).unique().tolist()
top_disp_str = ','.join(['\''+str(u)+'\'' for u in top_disp_lst])
print("top 10(auto) :",top_disp_str)


top_disp_lst = [43461694]
top_disp_str = ','.join(['\''+str(u)+'\'' for u in top_disp_lst])
print("top 10(final):",top_disp_str)

# run case review sql for top 10 disputers
sql = repo.get_contents("case review/case_pull_acct_history.sql").decoded_content.decode("utf-8", "strict")  
df = pd.read_sql(sql.replace('%','%%').replace('select * from user_info',top_disp_str), connection) # python will misinterpret % if without replacement
df['timestamp']=df['timestamp'].apply(lambda x: x.replace(tzinfo=None)) #remove timezone before exporting to excel

print('>>>> done with SQL!')

## output
import xlsxwriter
from datetime import date

# for output file name
td = date.today().strftime('%Y%m%d')

# output column 
cols=['timestamp', 'merchant_name', 'type', 'amt', 'description', 
      'card_type','decision', 'decline_resp_cd', 'vrs', 'rules_denied' ,'3DS_IND_RULES',
      'is_disputed','id']

# initiate xlsxwritter obj
writer = pd.ExcelWriter('/Users/hemali.shah/Documents/'+td+'_Case_Review_updated.xlsx', engine='xlsxwriter', datetime_format='YYY-MM-DD HH:MM:SS')

# output each uid in worksheet with formattings and freezed top row
for uid in top_disp_lst:
    df_user=df.loc[df['user_id'].astype(int)==int(str(uid).replace('\'','')),cols].reset_index(drop=True)
    df_user.to_excel(writer, sheet_name=str(uid), index=False)
    workbook  = writer.book
    worksheet = writer.sheets[str(uid)]

    # format 1: deposit - green bg
    fmt_deposit = workbook.add_format({'bg_color': '#A9DFBF'})
    for r in df_user[df_user['type']=='Deposit'].index:
        worksheet.set_row(r+1, None, fmt_deposit)

    # format 2: disputed auth - orange bg
    fmt_disp_auth = workbook.add_format({'bg_color': '#F8C471'})
    for r in df_user[df_user['is_disputed']=='yes'].index:
        worksheet.set_row(r+1, None, fmt_disp_auth)

    # format 3: disputed claim - red bg
    fmt_disp_clm = workbook.add_format({'bg_color': '#F1948A'})
    for r in df_user[df_user['type']=='dispute'].index:
        worksheet.set_row(r+1, None, fmt_disp_clm)
        
    # format 4: pii change - pink
    fmt_disp_auth = workbook.add_format({'bg_color': '#FEBDD7'})
    for r in df_user[df_user.type.str.strip().isin(['email change','phone change','address change'])].index:
        worksheet.set_row(r+1, None, fmt_disp_auth)
    
    # format 5: login - blue
    fmt_disp_auth = workbook.add_format({'bg_color': '#E3F6FE'})
    for r in df_user[df_user['type']=='login'].index:
        worksheet.set_row(r+1, None, fmt_disp_auth)
    
    # format 6: login failed - purple
    fmt_disp_auth = workbook.add_format({'bg_color': '#F4EEFC'})
    for r in df_user[df_user['type']=='login failed'].index:
        worksheet.set_row(r+1, None, fmt_disp_auth)
        
#     #format 7: biometric login - yellow
#     fmt_biometric_login = workbook.add_format({'bg_color': '#F4D03F'})
#     for r in df_user[df_user['type']=='BIOMETRICS'].index:
#          worksheet.set_row(r+1, None, fmt_biometric_login)

    worksheet.freeze_panes(1, 0) 
    
writer.save()
print('>>>> done with output!')
