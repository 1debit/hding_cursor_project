create or replace table rest.test.dispute_rate_automation as 
WITH pay_anyone AS (
  SELECT distinct 
    pa.*,
    mmv.finplat_transaction_id,
    mmv.galileo_external_transaction_id,
    coalesce(galileo_txns.transaction_id,finplat_txns.transaction_id) as transaction_id
  from postgres_db.p2p_service.pay_friends pa
  join analytics.move_money_reconciliation.mts_transfers_to_processor_transactions_materialized_view mmv
      on pa.mts_sending_transfer_id = mmv.transfer_id
  left join (select processor, external_transaction_id, utm_id, transaction_id from edw_db.core.ftr_transaction
        where transaction_cd in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb')) galileo_txns 
      on  (galileo_txns.processor = 'galileo' and mmv.galileo_external_transaction_id = galileo_txns.external_transaction_id) 
  left join (select processor, external_transaction_id, utm_id, transaction_id from edw_db.core.ftr_transaction
        where transaction_cd in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb')) finplat_txns 
      on (finplat_txns.processor = 'finplat' and mmv.finplat_transaction_id = finplat_txns.utm_id)
  WHERE       
    pa.status = 'succeeded'  
    AND 
    pa.type_code = 'to_nonmember'
)
, instant_p2p AS 
  (select 
  a.*,AUTHORIZATION_CODE  
  from  postgres_db.p2p_service.pay_friends a 
  left join edw_db.core.ftr_transaction  c on a.sender_id=c.user_id and c.settled_amt*-1=a.amount and (a.SENDER_ADJUSTMENT_ID::varchar = c.MERCHANT_NUMBER::varchar or substr(a.sending_transaction_id,2)::varchar=c.AUTHORIZATION_CODE::varchar) 
  where 
  FUNDING_SOURCE_TYPE='linked_card' 
  and a.status='succeeded' 
  and a.created_at::date >= '2019-01-01' ) 
,base_dispute_table as 
  ( SELECT 
  a.USER_ID
  ,UNIQUE_TRANSACTION_ID
  ,TRANSACTION_TIMESTAMP
  ,POST_DATE ,TRANSACTION_CODE
  ,TRANSACTION_AMOUNT
  ,UNIQUE_PROGRAM_ID
  ,a.USER_DISPUTE_CLAIM_ID 
  ,a.DISPUTE_CREATED_AT
  ,RESOLUTION_DATE
  ,100*year(post_date) + month(post_date) as txn_mth
  ,case when (transaction_code in ('ISA', 'ISC', 'ISJ', 'ISL', 'ISM', 'ISR', 'ISZ', 'VSA', 'VSC', 'VSJ', 'VSL', 'VSM', 'VSR', 'VSZ','SDA', 'SDC', 'SDL', 'SDM', 'SDR', 'SDV', 'SDZ', 'PLM', 'PLA', 'PRA', 'SSA', 'SSC', 'SSZ','SSL','SSM') 
        and a.program_type = 'credit')  then 'Credit Purchase'  
        when transaction_code in ('ISA', 'ISC', 'ISJ', 'ISL', 'ISM', 'ISR', 'ISZ', 'VSA', 'VSC', 'VSJ', 'VSL', 'VSM', 'VSR', 'VSZ', 'SDA', 'SDC', 'SDL', 'SDM', 'SDR', 'SDV', 'SDZ', 'PLM', 'PLA', 'PRA', 'SSA', 'SSC', 'SSZ','SSL','SSM') then 'Debit Purchase' 
        WHEN TRANSACTION_CODE in ('ADS') THEN 'ACH Transfer'
        WHEN transaction_code in ('ADbz') THEN 'Instant Transfer'  
        WHEN TRANSACTION_CODE in ('ADbc', 'ADcn') then 'ACH Debit' 
        when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') AND ip.authorization_code IS NOT NULL THEN 'Instant P2P' 
        when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') AND pa.transaction_id IS NOT NULL THEN 'PAY Anyone'  
        when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') then 'PF Outgoing' 
        when transaction_code in ('VSW','MPW','MPM', 'MPR','PLW','PLJ','PLR','PRW', 'SDW','FE0012','FE0013','FE0014') then 'ATM Withdrawals' 
  else 'Other' end as transaction_type 
  FROM  
  risk.prod.all_disputable_transactions a 
  LEFT JOIN pay_anyone pa ON pa.transaction_id = a.unique_transaction_id AND pa.sender_id = a.user_id 
  LEFT JOIN instant_p2p ip ON ip.authorization_code = a.AUTHORIZATION_CODE AND ip.sender_id = a.user_id 
  where  a.post_date >= '2019-01-01' and transaction_type != 'Other') 
, base as ( 
  select  
  post_date
  , transaction_type
  , sum(-transaction_amount) as txn_amt
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID IS NOT null) then (-TRANSACTION_AMOUNT) end ), 0) 
  ,sum(-transaction_amount)) as latest_dispute_rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 3) AND (datediff(day,post_date,current_date())>=3)) then (-TRANSACTION_AMOUNT) end ), 0) 
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=3) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_3D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 7) AND (datediff(day,post_date,current_date())>=7)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=7) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_7D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 14) AND (datediff(day,post_date,current_date())>=14)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=14) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_14D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 30) AND (datediff(day,post_date,current_date())>=30)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=30) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_30D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 45) AND (datediff(day,post_date,current_date())>=45)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=45) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_45D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 60) AND (datediff(day,post_date,current_date())>=60)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=60) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_60D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 90) AND (datediff(day,post_date,current_date())>=90)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=90) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_90D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 120) AND (datediff(day,post_date,current_date())>=120)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=120) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_120D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 150) AND (datediff(day,post_date,current_date())>=150)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=150) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_150D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 180) AND (datediff(day,post_date,current_date())>=180)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=180) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_180D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 210) AND (datediff(day,post_date,current_date())>=210)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=210) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_210D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 240) AND (datediff(day,post_date,current_date())>=240)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=240) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_240D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 270) AND (datediff(day,post_date,current_date())>=270)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=270) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_270D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 300) AND (datediff(day,post_date,current_date())>=300)) then (-TRANSACTION_AMOUNT) end ), 0) 
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=300) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_300D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 330) AND (datediff(day,post_date,current_date())>=330)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=330) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_330D_Dispute_Rate
  , div0(COALESCE(SUM(case when (USER_DISPUTE_CLAIM_ID is not null and (datediff(day,post_date,dispute_created_at) <= 365) AND (datediff(day,post_date,current_date())>=365)) then (-TRANSACTION_AMOUNT) end ), 0)
  , COALESCE(SUM(case when (datediff(day,post_date,current_date())>=365) then (-TRANSACTION_AMOUNT) end ), 0)) AS seasoned_365D_Dispute_Rate 
  from base_dispute_table  
  where post_date::date >= '2019-01-01' 
  and post_date::date <= current_date() 
  and transaction_type != 'Other' 
  group by 1,2 
  order by 1,2) 
select  *, 
  div0(seasoned_7D_Dispute_Rate,seasoned_3D_Dispute_Rate) as roll_rate_3D_7D,
  div0(seasoned_14D_Dispute_Rate,seasoned_7D_Dispute_Rate) as roll_rate_7D_14D, 
  div0(seasoned_30D_Dispute_Rate,seasoned_14D_Dispute_Rate) as roll_rate_14D_30D, 
  div0(seasoned_45D_Dispute_Rate,seasoned_30D_Dispute_Rate) as roll_rate_30D_45D,
  div0(seasoned_60D_Dispute_Rate,seasoned_45D_Dispute_Rate) as roll_rate_45D_60D, 
  div0(seasoned_90D_Dispute_Rate,seasoned_60D_Dispute_Rate) as roll_rate_60D_90D, 
  div0(seasoned_120D_Dispute_Rate,seasoned_90D_Dispute_Rate) as roll_rate_90D_120D, 
  div0(seasoned_150D_Dispute_Rate,seasoned_120D_Dispute_Rate) as roll_rate_120D_150D, 
  div0(seasoned_180D_Dispute_Rate,seasoned_150D_Dispute_Rate) as roll_rate_150D_180D, 
  div0(seasoned_210D_Dispute_Rate,seasoned_180D_Dispute_Rate) as roll_rate_180D_210D, 
  div0(seasoned_240D_Dispute_Rate,seasoned_210D_Dispute_Rate) as roll_rate_210D_240D, 
  div0(seasoned_270D_Dispute_Rate,seasoned_240D_Dispute_Rate) as roll_rate_240D_270D, 
  div0(seasoned_300D_Dispute_Rate,seasoned_270D_Dispute_Rate) as roll_rate_270D_300D, 
  div0(seasoned_330D_Dispute_Rate,seasoned_300D_Dispute_Rate) as roll_rate_300D_330D, 
  div0(seasoned_365D_Dispute_Rate,seasoned_330D_Dispute_Rate) as roll_rate_330D_365D 
from  
  base
