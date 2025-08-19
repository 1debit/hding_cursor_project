create or replace table rest.test.dispute_kpi_data as 
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
  (select a.*,AUTHORIZATION_CODE  
  from  postgres_db.p2p_service.pay_friends a 
  left join edw_db.core.ftr_transaction  c on a.sender_id=c.user_id and c.settled_amt*-1=a.amount and (a.SENDER_ADJUSTMENT_ID::varchar = c.MERCHANT_NUMBER::varchar or substr(a.sending_transaction_id,2)::varchar=c.AUTHORIZATION_CODE::varchar) 
  where FUNDING_SOURCE_TYPE='linked_card' and a.status='succeeded' and a.created_at::date >= '2019-01-01' ) 
SELECT 
  a.USER_ID
  ,UNIQUE_TRANSACTION_ID
  ,TRANSACTION_TIMESTAMP
  ,POST_DATE ,TRANSACTION_CODE
  ,TRANSACTION_AMOUNT ,UNIQUE_PROGRAM_ID
  ,a.USER_DISPUTE_CLAIM_ID
  ,a.DISPUTE_CREATED_AT
  ,RESOLUTION_DATE
  ,100*year(post_date) + month(post_date) as txn_mth
  ,case when (transaction_code in ('ISA', 'ISC', 'ISJ', 'ISL', 'ISM', 'ISR', 'ISZ', 'VSA', 'VSC', 'VSJ', 'VSL', 'VSM', 'VSR', 'VSZ','SDA', 'SDC', 'SDL', 'SDM', 'SDR', 'SDV', 'SDZ', 'PLM', 'PLA', 'PRA', 'SSA', 'SSC', 'SSZ','SSL','SSM') 
        and a.program_type = 'credit')  then 'Credit Purchase'  
        when transaction_code in ('ISA', 'ISC', 'ISJ', 'ISL', 'ISM', 'ISR', 'ISZ', 'VSA', 'VSC', 'VSJ', 'VSL', 'VSM', 'VSR', 'VSZ','SDA', 'SDC', 'SDL', 'SDM', 'SDR', 'SDV', 'SDZ', 'PLM', 'PLA', 'PRA', 'SSA', 'SSC', 'SSZ','SSL','SSM') then 'Debit Purchase'  
        WHEN TRANSACTION_CODE in ('ADS') THEN 'ACH Transfer'   
        WHEN transaction_code in ('ADbz') THEN 'Instant Transfer'  
        WHEN TRANSACTION_CODE in ('ADbc', 'ADcn') then 'ACH Debit'  
        when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') 
        AND ip.authorization_code IS NOT NULL THEN 'Instant P2P'  
        when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') AND pa.transaction_id IS NOT NULL THEN 'PAY Anyone'  
        when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') then 'PF Outgoing'  
        when transaction_code in ('VSW','MPW','MPM', 'MPR','PLW','PLJ','PLR','PRW', 'SDW','FE0012','FE0013','FE0014') then 'ATM Withdrawals' 
  else 'Other' end as transaction_type
  ,amount_cred
  ,amount_rev
  ,amount_final_cred
  ,amount_final_rev 
  FROM 
  risk.prod.all_disputable_transactions a 
  LEFT JOIN pay_anyone pa ON pa.transaction_id = a.unique_transaction_id AND pa.sender_id = a.user_id 
  LEFT JOIN instant_p2p ip ON ip.authorization_code = a.AUTHORIZATION_CODE AND ip.sender_id = a.user_id
  where  a.post_date >= '2019-01-01' and transaction_type != 'Other'
