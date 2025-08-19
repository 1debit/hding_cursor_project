create or replace table rest.test.dispute_approval_table_1 as  
with pay_anyone AS (
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
,instant_p2p AS (
  select 
      a.*,AUTHORIZATION_CODE  
  from  
      postgres_db.p2p_service.pay_friends a 
  left join 
      edw_db.core.ftr_transaction c 
  on 
      a.sender_id=c.user_id 
      and c.settled_amt*-1=a.amount 
      and (a.SENDER_ADJUSTMENT_ID::varchar = c.MERCHANT_NUMBER::varchar or substr(a.sending_transaction_id,2)::varchar=c.AUTHORIZATION_CODE::varchar) 
  where 
      FUNDING_SOURCE_TYPE='linked_card' 
  and 
      a.status='succeeded' 
  and 
      a.created_at::date >= '2019-01-01' ) 
,distinct_date as (
  select 
      distinct datediff(day,'2023-01-01',d.date_cd) as date_diff 
  from 
      edw_db.core.dim_date d 
  where 
      date_cd >= '2023-01-01' 
  and 
      date_cd < current_date()) 
,base as ( 
  select  
      date_trunc('month',post_date)::date as txn_mth
      ,case 
          when (transaction_code in ('ISA', 'ISC', 'ISJ', 'ISL', 'ISM', 'ISR', 'ISZ', 'VSA', 'VSC', 'VSJ', 'VSL', 'VSM', 'VSR', 'VSZ','SDA', 'SDC', 'SDL', 'SDM', 'SDR', 'SDV', 'SDZ', 'PLM', 'PLA', 'PRA', 'SSA', 'SSC', 'SSZ','SSL','SSM') 
              and adt.program_type = 'credit')  then 'Credit Purchase'  
          when transaction_code in ('ISA', 'ISC', 'ISJ', 'ISL', 'ISM', 'ISR', 'ISZ', 'VSA', 'VSC', 'VSJ', 'VSL', 'VSM', 'VSR', 'VSZ','SDA', 'SDC', 'SDL', 'SDM', 'SDR', 'SDV', 'SDZ', 'PLM', 'PLA', 'PRA', 'SSA', 'SSC', 'SSZ','SSL','SSM') then 'Debit Purchase'
          when TRANSACTION_CODE in ('ADS') then 'ACH Transfer'
          when transaction_code in ('ADbz') then 'Instant Transfer'  
          when TRANSACTION_CODE in ('ADbc', 'ADcn') then 'ACH Debit'  
          when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') and ip.authorization_code IS NOT NULL THEN 'Instant P2P'
          when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') and pa.transaction_id IS NOT NULL THEN 'PAY Anyone' 
          when transaction_code in ('ADM', 'ADPF', 'ADTS', 'ADTU','ADpb') then 'PF Outgoing'   
          when transaction_code in ('VSW','MPW','MPM', 'MPR','PLW','PLJ','PLR','PRW', 'SDW','FE0012','FE0013','FE0014') then 'ATM Withdrawals' 
      else 'Other' end as transaction_type
      ,post_date
      ,dispute_created_at
      ,final_cred_date
      ,final_rev_date
      ,-adt.transaction_amount as dispute_volume
      ,amount_final_cred as fc
      ,adt.amount_final_rev as fc_rev 
    from  
      risk.prod.all_disputable_transactions adt 
    left join 
      instant_p2p ip on ip.authorization_code = adt.AUTHORIZATION_CODE and ip.sender_id = adt.user_id 
    left join pay_anyone pa on pa.transaction_id = adt.unique_transaction_id and pa.sender_id = adt.user_id 
  where  
    adt.post_date >= '2023-01-01' 
    and dispute_created_at >= '2023-01-01' ) 
select 
  *, 
  DIV0((coalesce(fc,0)+coalesce(fc_rev,0)),dispute_volume) as net_fc_rate 
from 
  (select 
      d.transaction_type
      ,d.txn_mth
      ,a.date_diff
      ,sum(coalesce(fc,0)) over (partition by d.transaction_type,d.txn_mth order by a.date_diff) as fc
      ,sum(coalesce(fc_rev,0)) over (partition by d.transaction_type,d.txn_mth order by a.date_diff) as fc_rev
      ,sum(coalesce(dispute_volume,0)) over (partition by d.transaction_type,d.txn_mth order by a.date_diff) as dispute_volume 
  from distinct_date a 
  left join  
     (select  txn_mth::varchar as txn_mth, transaction_type, datediff(day,date_trunc('month',post_date),dispute_created_at) as date_diff, sum(dispute_volume) dispute_volume from base group by 1,2,3 ) d 
      on 
        a.date_diff = d.date_diff 
  left join  
     (select txn_mth::varchar as txn_mth, transaction_type, datediff(day,date_trunc('month',post_date),final_cred_date) as date_diff, sum(fc) fc from base group by 1,2,3 ) fc 
      on 
        d.txn_mth = fc.txn_mth and d.transaction_type = fc.transaction_type and d.date_diff = fc.date_diff 
  left join  
     (select txn_mth::varchar as txn_mth, transaction_type, datediff(day,date_trunc('month',post_date),final_rev_date) as date_diff, sum(fc_rev) fc_rev from base group by 1,2,3 ) fv 
      on 
        d.txn_mth = fv.txn_mth and d.transaction_type = fv.transaction_type and d.date_diff = fv.date_diff ) i 
where 
  date_diff>5
