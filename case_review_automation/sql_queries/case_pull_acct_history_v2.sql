with user_info as(select distinct id::varchar as user_id from CHIME.FINANCE.members where id=22166720)
, t1 as(
 -- tokenization driver
    select distinct
    original_timestamp as timestamp
    ,user_id::varchar as user_id
    ,device_id::varchar as id
    ,pan_source
    ,response_cd
    ,'n/a' as merchant_name
    ,'token/provisioning event' as type
    ,'n/a' as card_type
    ,'n/a' as decision
    ,'n/a' as decline_resp_cd
    ,risk_score::varchar as vrs
    ,concat_ws('|',ifnull(device_name,''),ifnull(device_type,''),ifnull(device_score,''),ifnull(device_ip,''),ifnull(phone_number_last_4,'')) as device_info
    ,policy_name as rules_denied
    ,'n/a' as "3DS_IND_RULES"
    ,0 as amt
    ,'n/a' as is_disputed
    from chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization
    where 1=1
    and is_shadow_mode=false  
    and user_id IN (select * from user_info)
    and device_id is not null
)
	
/*pulling FTP txn: transfer deposite credit_adj etc*/
select
t.user_id,
convert_timezone('America/Los_Angeles',t.transaction_timestamp) as timestamp,
t.authorization_code::varchar as id,
case when t.user_id=pf.sender_id and t.transaction_cd != 'ADbz' then 'p2p sender' 
     when t.user_id=pf.receiver_id and t.transaction_cd != 'ADbz' then 'p2p receiver'
     when length(transaction_details_2)>0 then transaction_details_2 
     when deposit_type_cd='Cash Deposit' then deposit_type_cd
     when deposit_type_cd='Deposit' then description
     else coalesce(case when length(t.merchant_name)=0 then cast(null as varchar) end, t.description) 
     end as merchant_name,

t.type,
concat(
    case 
        when t.user_id=pf.sender_id and pf.type_code='to_member' and t.transaction_cd != 'ADbz' then 'to member(' || pf.receiver_id || '); '
        when t.user_id=pf.sender_id and pf.type_code='to_nonmember' and t.transaction_cd != 'ADbz' then 'to nonmember; '
        when t.user_id=pf.receiver_id and pf.type_code='to_member' and t.transaction_cd != 'ADbz' then 'from member(' || pf.sender_id || '); '
        when t.user_id=pf.receiver_id and pf.type_code='from_nonmember_to_member' and t.transaction_cd != 'ADbz' then 'from nonmember; '
        when t.transaction_cd = 'ADbz' then concat(
            coalesce(t.description, ''),
            '; External Card: ', coalesce(bw.last_four, ''),
            '; ATOM Score: ', coalesce(bw.atom_v3_score_::varchar, ''),
            '; Card Link Tenure: ', coalesce(bw.card_link_tenure_days::varchar, ''),
            '; Visa ANI: ', coalesce(bw.external_card_ani_result, ''),
            '; Remote Apps: ', coalesce(bw.remote_controlled_apps, '')
        )
        else t.description 
    end,
    '; Tran_cd: ', coalesce(t.transaction_cd, ''),
    '; Prism Score: ', coalesce(prs.score::varchar, '0'),
    '; dd_type: ', coalesce(t.dd_type, ''),
    '-', coalesce(t.transaction_details_2, '')
) as description,
       
case when t.unique_program_id IN (512,609,660,2247,2457) and t.card_id<>0 then 'checking '||right(dc.CARD_NUMBER,4)
    when t.unique_program_id IN (600,278,1014,2248,2458) then 'CB'
    when t.unique_program_id IN (512,609,660,2247,2457) and t.card_id=0 then 'savings'
    else t.unique_program_id::varchar end as card_type,
case when t.transaction_cd is not null then 'Approved' end as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
case when t.transaction_cd = 'ADbz' and bw.policy_name is not null then bw.policy_name||' -'||bw.decision_outcome else 'n/a' end as  rules_denied,
'n/a' as "3DS_IND_RULES",
t.settled_amt as amt,
case when d.authorization_code is not null then 'yes' else 'no' end as is_disputed
from edw_db.core.ftr_transaction t
left join postgres_db.p2p_service.pay_friends pf on ((t.user_id=pf.sender_id or t.user_id=pf.receiver_id) and abs(t.settled_amt)=abs(pf.amount) and pf.created_at between dateadd(hour,-1,t.transaction_timestamp) and t.transaction_timestamp)
left join ml.model_inference.prism_alerts_v2 prs on (prs.pay_friend_id = pf.ID)
left join risk.prod.disputed_transactions d on t.authorization_code=d.authorization_code and t.user_id=d.user_id
left join EDW_DB.CORE.DIM_CARD as dc on to_char(t.CARD_ID)=dc.CARD_ID and dc.USER_ID=t.USER_ID
left join risk.test.bwhite_OIT_txn_overview bw on bw.transaction_id = t.transaction_id and bw.user_id = t.user_id

where 1=1
and description NOT IN ('Savings Round-Up Transfer','Savings Round-Up Transfer from Checking','API Cardholder Balance Adjustments','Savings Round-Up Transfer Bonus',
'International Cash Withdrawal Fee', 'Domestic Cash Withdrawal Fee - ATM','Savings Interest', 'Payment from the Secured Credit Funding Account to the Secured Credit Card')
and t.type<>'Purchase' /*non purchase only: fee deposit transfer credit adj etc*/
and MCC_CD not in ('6010','6011') /*Financial Institutions – Manual/auto Cash Disbursements*/
and t.user_id in (select * from user_info)
qualify row_number() over (partition by t.user_id, t.authorization_code order by pf.created_at desc)=1


UNION ALL



/*including MyPay Payment, Repayment, Adjustments*/


select 
t.user_id,
convert_timezone('America/Los_Angeles',t.transaction_timestamp) as timestamp,
t.authorization_code::varchar as id,
case when transaction_cd= 'PMAP' then 'MyPay Advance'
     when transaction_cd = 'ADER' then 'MyPay Repayment'
     when transaction_cd = 'ADFA' then 'MyPay Reversal'
     end as merchant_name,

case when transaction_cd= 'PMAP' then 'Deposit'
     when transaction_cd = 'ADER' then 'Payment'
     when transaction_cd = 'ADFA' then 'Credit / Adjustment'
     end as type,

concat(
case when transaction_cd= 'PMAP' then 'Deposit'
     when transaction_cd = 'ADER' then 'Payment'
     when transaction_cd = 'ADFA' then 'Credit / Adjustment' end,'; Tran_cd: ',t.transaction_cd,'; Prism Score: ', ifnull(prs.score,0)||'; dd_type: ', ifnull(t.dd_type,';') ,'-', ifnull(t.description,';')) as description,

     case when t.unique_program_id IN (512,609,660,2247,2457) and t.card_id<>0 then 'checking '||right(dc.CARD_NUMBER,4)
    when t.unique_program_id IN (600,278,1014,2248,2458) then 'CB'
    when t.unique_program_id IN (512,609,660,2247,2457) and t.card_id=0 then 'savings'
    else t.unique_program_id::varchar end as card_type,

    case when t.transaction_cd is not null then 'Approved' end as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
'n/a' rules_denied,
'n/a' as "3DS_IND_RULES",
t.settled_amt as amt,
case when d.external_transaction_id is not null then 'yes' else 'no' end as is_disputed
from edw_db.core.ftr_transaction t
left join postgres_db.p2p_service.pay_friends pf on ((t.user_id=pf.sender_id or t.user_id=pf.receiver_id) and abs(t.settled_amt)=abs(pf.amount) and pf.created_at between dateadd(hour,-1,t.transaction_timestamp) and t.transaction_timestamp)
left join ml.model_inference.prism_alerts_v2 prs on (prs.pay_friend_id = pf.ID)
left join (select  g.external_transaction_id, c.member_ext_id 
            from fivetran.inspector_public.disputes a
            left join fivetran.inspector_public.transactions b
             on a.id = b.dispute_id
            left join fivetran.inspector_public.source_transactions c
             on b.source_transaction_id = c.id
            left join postgres_db.payday_service.pay_advances d
             on c.transaction_ext_id = d.idempotency_key
            left join postgres_db.money_transfer_service.transfers e
             on d.idempotency_key = e.uuid
            left join postgres_db.money_transfer_service.transactions f
             on e.id = f.transfer_id
            left join edw_db.core.ftr_transaction g
             on f.external_transaction_id = g.external_transaction_id
            where a.dispute_type = 'my_pay'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY c.MEMBER_EXT_ID ORDER BY g.EXTERNAL_TRANSACTION_ID) = 1) d on d.member_ext_id = t.user_id and d.external_transaction_id = t.external_transaction_id
left join EDW_DB.CORE.DIM_CARD as dc on to_char(t.CARD_ID)=dc.CARD_ID and dc.USER_ID=t.USER_ID
where 1=1
and transaction_cd in ('PMAP','ADER','ADFA')
and t.user_id IN (select * from user_info)



UNION ALL


/* including failed OIT attempts*/
select
user_id ,
convert_timezone('America/Los_Angeles',creation_timestamp) as  timestamp,
id,
'Instant Outbound Transfer'as merchant_name,
'Transfer' as type,
 concat('Network; ',network_code, ' Limits; ' ,Monthly_limit_remaining,' Issuer; ',issuer, ' Last Four;',last_four) as description,
 'n/a' as card_type,
'Declined' as decision,
error_reason as decline_resp_cd,
'n/a' as vrs,
case when policy_name is not null then  policy_name||' -'||decision_outcome else 'n/a' end as  rules_denied,
'n/a' as "3DS_IND_RULES",
total_amount as amt,
'n/a' as is_disputed
from (with transfer as (select
    _user_id as user_id,
    id,
    _creation_timestamp as creation_timestamp,
    galileo_transaction_id,
    issuer,
    amount,
    fee_amount,
    total_amount,
    Limits:monthly_limit:maximum as Monthly_limit_maximum,
    Limits:monthly_limit:remaining as Monthly_limit_remaining,
    Limits:transaction_limit as limit_txn,
    'Failed' as transfer_outcome,
    last_four,
    ERROR_REASON,
    network_code
    from STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.MOVEMONEY_HAWKER_V1_INSTANT_OUTBOUND_TRANSFER_FAILED ) 

    
    Select a.*,
    c.TRANSFER_ID, 
    c.CORRELATION_ID as status_correlation_id,
    l.policy_name, 
    l.decision_outcome
    from transfer a
    left join (select b.external_id as _user_id, a.* from postgres_db.mms.outbound_transfers a
                left join postgres_db.mms.users b on a.user_id = b.id ) b on b._user_id = a.user_id and a.id::varchar = b.id::varchar
    --where creation_timestamp::date >= '2024-12-01'
    left join (select * from  POSTGRES_DB.MMS.MTS_TRANSFERS
        where transferable_type = 'OutboundTransfer') c on c.transferable_id::varchar = a.id::varchar 
    left join (WITH ranked_policy_actions AS (
             SELECT *,
                ROW_NUMBER() OVER (
                PARTITION BY decision_id
                ORDER BY 
                CASE
                    WHEN policy_actions ILIKE '%deny%' THEN 1
                    WHEN policy_actions ILIKE '%step_up_otp%' THEN 2
                    WHEN policy_actions ILIKE '%allow%' THEN 3
                    ELSE 4
                    END
                ) AS rn
            FROM chime.decision_platform.execute_transfer_event 
            WHERE is_shadow_mode = false
            AND transfer_type = 'instant_outbound_transfer'
            )

        SELECT *
        FROM ranked_policy_actions
        WHERE rn = 1) l on l.correlation_id = c.correlation_id and l.user_id = a.user_id
    where a.id <>'')
where user_id in (select * from user_info)
and id <> ''




UNION ALL


/* including card link attempts*/

select 
user_id,
convert_timezone('America/Los_Angeles',timestamp) as timestamp,
id,
EVENT as merchant_name,
'Card Add' as type,
 concat('Event; ', event, ' Bin; ',bin, ' Last Four;',last_four) as description,
 'n/a' as card_type,
case when error is not null then 'Declined' when error is null then 'Approved'  end as decision,
error as decline_resp_cd,
'n/a' as vrs,
case when policy_name is not null then  policy_name  end as rules_denied,
'n/a' as "3DS_IND_RULES",
0 as amt,
'n/a' as is_disputed
from (with link_fails as (select user_id , event , bin ,  original_timestamp as timestamp , id  , linked_card_id , last_four , card_type , error , policy_name, 
 policy_actions,  external_card_ani_result,
    from (SELECT b.*, a.decision_outcome, a.policy_name, a.policy_actions, a.external_card_ani_result,
          FROM segment.move_money_service.debit_card_linking_failed b
          LEFT JOIN chime.decision_platform.instant_transfers a 
          ON DATE_TRUNC('second', CAST(b.original_timestamp AS TIMESTAMP)) = DATE_TRUNC('second', CAST(a.original_timestamp AS TIMESTAMP))
          AND LEFT(a.external_card_bin::varchar, 8) = TRIM(b.bin::varchar)
          AND a.user_id = b.user_id
          Where 1=1
          and  a.decision_outcome = 'deny'
          AND a.is_shadow_mode = 'false' 
          qualify row_number() over (partition by b.user_id, b.id order by b.original_timestamp desc)=1) where TRUE order by timestamp),
    link_successes as (select user_id , event , bin , original_timestamp as timestamp , id  , linked_card_id , last_four , null , null
    from segment.move_money_service.debit_card_linking_succeeded where TRUE order by timestamp)
    select user_id , event , bin , timestamp , id , linked_card_id , last_four , card_type , error, policy_name, policy_actions,  external_card_ani_result, from link_fails
    UNION
    select user_id , event , bin , timestamp , id  , linked_card_id , last_four , null , null, null, null, null from link_successes)
where user_id in (select * from user_info)



UNION ALL



/*pull all auth history*/
select
rta.user_id,
convert_timezone('America/Los_Angeles',rta.trans_ts) as timestamp,
rta.auth_id::varchar as id,
rta.auth_event_merchant_name_raw as merchant_name,
case when rta.MCC_CD in ('6010','6011') then 'Withdrawal'
     when rta.mti_cd in ('0400','0420') then 'Mrch_Credit'
    else 'Purchase' end as type,
concat('Card Transaction ',rta.entry_type, '; MCC_CD: ', rta.mcc_cd, '; Avail_Fund: ', rta.available_funds, '; Pin Code: ', rta.pin_result_cd, '; cashback: ', rta.cashback_amt, '; Eci: ', case when rta.ecommerce like '%05%' then '05' when rta.ecommerce like '%03%' then '03' when rta.ecommerce like '%07%' then '07' else 'n/a' end) as description, /*EMV, magnetic, contactless etc.*/
	case when dc.is_virtual=true then dc.CARD_TYPE||'(t) '||right(rta.PAN,4) else dc.CARD_TYPE||' '||right(rta.PAN,4) end as card_type,
case when rta.response_cd IN ('00','10') then 'Approved' else 'Declined' end as decision,
case when rta.response_cd IN ('00','10') then 'n/a' else concat(rta.response_cd,' '
                                                                , case when rta.response_cd='51' then 'NSF'
                                                                       when rta.response_cd='04' then 'Inactive Card'
                                                                       when rta.response_cd='05' then 'Do Not Honor'
                                                                       when rta.response_cd='30' then 'Format Error'
                                                                       when rta.response_cd='41' then 'Lost/Stolen'
                                                                       when rta.response_cd='43' then 'Lost/Stolen'
                                                                       when rta.response_cd='54' then 'Mismatched Expry'
                                                                       when rta.response_cd='55' then 'Incorrect PIN'
                                                                       when rta.response_cd='57' then 'Card Disabled'
                                                                       when rta.response_cd='59' then 'DFE'
                                                                       when rta.response_cd='61' then 'Exceeds Limit'
                                                                       when rta.response_cd='75' then 'PIN Tries Exceeded'
                                                                       when rta.response_cd='78' then 'card frozen'
                                                                       when rta.response_cd='N7' then 'Incorrect CVV'
                                                                       when rta.response_cd='01' then 'Processor Error'
                                                                       when rta.response_cd='85' then 'Address validation authorization'
                                                                       else rta.response_cd end ) ::varchar end as decline_resp_cd,
rta.risk_score::varchar as vrs,
case when rta.response_cd in ('59') then rta2.policy_name||' -'||(case when o.decision_id is null then rta2.decision_outcome
                                                                       when o.is_suppressed=true then 'suppressed'
                                                                       when o.response_signal is null then 'no response'
                                                                  else o.response_signal end)
    when rta.response_cd in ('00','10') then rta2.policy_name||' -'||rta2.decision_outcome
     else 'n/a' end as rules_denied,
     case when rta.auth_id = issuer_3ds.auth_id and rta.user_id = issuer_3ds.user_id then CONCAT_WS(' ', COALESCE(issuer_3ds."3ds", ''), COALESCE(issuer_3ds.Policy_name, ''), COALESCE(issuer_3ds.STEP_UP_STATUS, '')) else 'n/a' end AS  "3DS_IND_RULES",
rta.req_amt as amt,
case when d.authorization_code is not null then 'yes' else 'no' end as is_disputed
from edw_db.core.fct_realtime_auth_event rta
left join EDW_DB.CORE.DIM_CARD as dc on rta.USER_ID=dc.USER_ID  and right(rta.PAN,4)=right(dc.CARD_NUMBER,4)
left join edw_db.core.fct_realtime_auth_event dual_auth_settlment on rta.auth_id::varchar=dual_auth_settlment.original_auth_id::varchar and rta.user_id::varchar=dual_auth_settlment.user_id::varchar 
left join risk.prod.disputed_transactions d on (d.authorization_code=rta.auth_id or d.authorization_code=dual_auth_settlment.auth_id) and d.user_id::varchar=rta.user_id::varchar
left join chime.decision_platform.card_auth_events rta2 on 
    (rta.user_id::varchar=rta2.user_id::varchar and rta.auth_id::varchar=rta2.auth_id::varchar and rta2.is_shadow_mode='false' and policy_result='criteria_met' and policy_actions like '%'||decision_outcome||'%' and decision_outcome in ('hard_block','merchant_block','deny','prompt_override','sanction_block','allow','step_up_in_app_confirmation')) /*2021.11.10 - present*/
left join chime.decision_platform.fraud_override_service o on (rta.user_id::varchar=o.user_id::varchar and rta.auth_id::varchar=o.realtime_auth_id::varchar)
left join (select  
    a.decision_id
    , a.user_id
    , a.timestamp
    , a.txn_amt
    , d.merchant_name
    , i.policy_name
    , i.decision_outcome
    , d.auth_id
    , d.resp_code
    , case when eci_07_ind = 1 then 'eci 07' else null end as eci_07_ind
     , case when  b.recon_cat='both' and c.user_id is null then '3ds_created' 
        when c.user_id is not null then '3ds_approved' end as  "3ds"
    , case when a.action='allow' then 1 else 0 end as allowed_req_ind
    
    , case when b.recon_cat='both'  then 1 else 0 end as txn_created_ind
    , case when c.user_id is not null then 1 else 0 end as txn_appv_ind
    , e.step_up_status
        from risk.test.hding_3ds_decplat_vali_cleaned a
        left join chime.decision_platform.issuer_3ds i on (a.decision_id=i.decision_id)
        left join risk.test.hding_3ds_decplat_vali_recon b on (a.decision_id=b.authen_decision_id)
        left join risk.test.hding_3ds_auth_final c on (a.decision_id=c.authen_decision_id)
        left join risk.test.hding_3ds_decplat_vali_authorization d on (b.auth_decision_id=d.decision_id)
        left join  (WITH LatestStepUps AS (
                SELECT  decision_id,  user_id, MAX(_CREATION_TIMESTAMP) AS latest_timestamp
                FROM  streaming_platform.segment_and_hawker_production.step_ups_events_v1_status_change
                GROUP BY  decision_id, user_id)

                SELECT t.user_id, t.decision_id, t.step_up_status
                FROM streaming_platform.segment_and_hawker_production.step_ups_events_v1_status_change t
                INNER JOIN  LatestStepUps l ON  t.decision_id = l.decision_id AND t.user_id = l.user_id AND  t._CREATION_TIMESTAMP = l.latest_timestamp
                where t.event_name = 'issuer_3ds_risk_request' ) e on e.decision_id = a.decision_id 
        where 1=1
       and i.is_shadow_mode=false
        qualify row_number() over (partition by a.decision_id  order by (select null))=1) as issuer_3ds on issuer_3ds.auth_id::varchar = rta.auth_id::varchar and issuer_3ds.user_id::varchar = rta.user_id::varchar
where 1=1
and rta.original_auth_id::varchar= '0' 
and (rta.final_amt>=0 or rta.mti_cd in ('0400','0420'))
and rta.user_id IN (select * from user_info)
qualify row_number() over(partition by rta.user_id,rta.auth_event_id order by o.response_received_at) = 1



UNION ALL


/*pull false posted txn*/
select events.user_id,
convert_timezone('America/Los_Angeles',events.tran_timestamp) as timestamp,
events.auth_id::varchar as id,
events.merch_name,
'Purchase'  as type,
concat('Card Transaction ','likely force post') as description,
case when events.prog_id::varchar IN ('512','609','660','2247','2457') then 'checking '|| right(e.card_number::varchar,4)
    when events.prog_id::varchar IN ('600','278','1014','2248','2458') then 'CB '|| right(e.card_number::varchar,4)
    else events.prog_id::varchar end as card_type,
'Approved' as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
'n/a' rules_denied,
'n/a' as "3DS_IND_RULES",
events.amount as amt,
case when d.authorization_code is not null then 'yes' else 'no' end as is_disputed
from mysql_db.chime_prod.alert_authorization_events events
left join edw_db.core.fct_realtime_auth_event rta
  on events.auth_id::varchar=rta.auth_id::varchar
  and events.user_id=rta.user_id
left join risk.prod.disputed_transactions d
  on events.auth_id=d.authorization_code
  and events.user_id=d.user_id
left join  edw_db.core.dim_card e 
    on e.user_id = events.user_id 
    and events.card_id::varchar = e.card_id::varchar
where 1=1
and rta.auth_id is null
and events.type='settle'
and events.user_id IN (select * from user_info)

UNION ALL

/*pull disputed txn*/

select
user_id,
convert_timezone('America/Los_Angeles',dispute_created_at) as timestamp,
user_dispute_claim_txn_id::varchar as id,
merchant_name,
'dispute' as type,
reason||'; dispute_claim_id:'||user_dispute_claim_id||'; auth_id: '||authorization_code as description,
INTAKE_TYPE as card_type,
resolution_code as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
'n/a' rules_denied,
'n/a' as "3DS_IND_RULES",
transaction_amount as amt,
'n/a' as is_disputed
from
(
	select
	dt.*,
	d.id as r_inspector_dispute_id,
	 case
	    when coalesce(dc.intake_type,d.intake_type) = 'mobile' then 'in_app'
	    when d.intake_type in ('fax','paper_mail') then 'email'
	    when d.intake_type is not null then d.intake_type
	    when mc.interactions_str_seq ilike '%app%' then 'chat_bot'
	    when mc.contact_flow ilike '%phone%' then 'phone'
	    when mc.contact_flow ilike '%email%' then 'email'
	    else 'agent_channel_unknown'
	    end as intake_type,
	datediff(day, dt.TRANSACTION_TIMESTAMP, dt.dispute_created_at) as days_to_dispute
	from risk.prod.disputed_transactions dt
	left join fivetran.inspector_public.disputes d on dt.user_dispute_claim_id::varchar = d.claim_ext_id::varchar
	left join fivetran.mysql_rds_disputes.user_dispute_claims dc on dc.id::varchar = dt.user_dispute_claim_id::varchar
	left join analytics.test.dispute_member_contacts mc on mc.dispute_id::varchar = dt.user_dispute_claim_id::varchar and mc.dispute_contact_category = 'Filing'
	left join analytics.test.blocked_self_service_disputes bm on bm.user_dispute_claim_id::varchar = dt.user_dispute_claim_id::varchar

	qualify row_number() over (partition by dt.user_id, dt.authorization_code order by dt.DISPUTE_CREATED_AT desc)=1
) as disputes
where 1=1
and user_id IN (select * from user_info)

UNION ALL

/*pull all logins success:
  If indicated in description column:
    SMS 2FA Auth - passed 2fa auth
    Scan ID Auth - passed scan ID
    Step Down - passed password(and arkose) 
    
    How to understand the description for login events:
    atomv2 score=0 - old device login
    atomv3 score=0 - pre atomv3 launch(4.3) login
  
*/
select 
    ls.user_id,
    convert_timezone('America/Los_Angeles',coalesce(lr.login_success_at,ls.session_timestamp)) as timestamp,
    ls.device_id::varchar as id,
    'n/a' as merchant_name,
    'login' as type,
     concat(COALESCE(concat('ATOMv2 score:',ifnull(atomv2.score,0)),''),'  ',concat('ATOMv3 score:',ifnull(atomv3.score,0)),'  ',COALESCE(concat('DEVICE:',ls.device_model),''),'  ',coalesce(concat('LOCALE:',ls.locale),''),'  ',coalesce(concat('TZ:',ls.timezone),''),'',coalesce(concat('CARRIER:',ls.network_carrier),''),'  ',coalesce(concat('IP:',ls.ip,' ',loc.city_name||','||loc.time_zone),''),' ',COALESCE(concat('Platform:',ls.platform),''),' '
    ,coalesce(concat('TFA_METHOD:',lr.tfa_method_deprecated),''),' ', coalesce('TIME_SPENT:'||cast(datediff(second,login_started_at,login_success_at) as varchar),'')) as description,
    'n/a' as card_type,
    'n/a' as decision,
    'n/a' as decline_resp_cd,
    'n/a' as vrs,
    'n/a' rules_denied,
    'n/a' as "3DS_IND_RULES",
    0 as amt,
    'n/a' as is_disputed
    from edw_db.feature_store.atom_user_sessions_v2 ls
    left join partner_db.maxmind.ip_geolocation_mapping as map on ls.ip=map.ip
    left join partner_db.maxmind.GEOIP2_CITY_LOCATIONS_EN loc on loc.geoname_id = map.geoname_id
    left join ml.model_inference.ato_login_alerts atomv2 on ls.user_id::varchar=atomv2.user_id::varchar and ls.device_id=atomv2.device_id and atomv2.score<>0 and atomv2.session_timestamp between dateadd(minute, -30, ls.session_timestamp) and ls.session_timestamp
    left join streaming_platform.segment_and_hawker_production.dsml_events_predictions_segment_v2_atom_model_v3 atomv3 on ls.user_id::varchar=atomv3._user_id::varchar and ls.device_id=atomv3.device_id and atomv3.score<>0 and atomv3.snapshot_timestamp between dateadd(minute, -30, ls.session_timestamp) and ls.session_timestamp
    left join analytics.test.login_requests lr on (lr.user_id::varchar=ls.user_id::varchar and lr.segment_device_id=ls.device_id and lr.login_success_at between dateadd(second, -60, ls.session_timestamp) and ls.session_timestamp)
   where 1=1
   and ls.user_id IN (select * from user_info)
   
   qualify row_number() over (partition by ls.user_id, ls.session_timestamp, ls.device_id order by lr.login_success_at desc, atomv3.snapshot_timestamp desc)=1 



   UNION ALL


-- new login success 
select 
    new.user_id,
    convert_timezone('America/Los_Angeles',coalesce(lr.login_success_at,new.timestamp)) as timestamp,
    new.segment_device_id::varchar as id,
    'n/a' as merchant_name,
    'login' as type,
     concat(COALESCE(concat('ATOMv2 score:',ifnull(atomv2.score,0)),''),'  ',concat('ATOMv3 score:',ifnull(atomv3.score,0)),'  ',COALESCE(concat('DEVICE:',ls.device_model),''),'  ',coalesce(concat('LOCALE:',ls.locale),''),'  ',coalesce(concat('TZ:',ls.timezone),''),'',coalesce(concat('CARRIER:',ls.network_carrier),''),'  ',coalesce(concat('IP:',ls.ip,' ',loc.city_name||','||loc.time_zone),''),' ',COALESCE(concat('Platform:',ls.platform),''),' '
    ,coalesce(concat('TFA_METHOD:',lr.tfa_method_deprecated),''),' ', coalesce('TIME_SPENT:'||cast(datediff(second,login_started_at,login_success_at) as varchar),'')) as description,
    'n/a' as card_type,
    'n/a' as decision,
    'n/a' as decline_resp_cd,
    'n/a' as vrs,
    'n/a' rules_denied,
    'n/a' as "3DS_IND_RULES",
    0 as amt,
    'n/a' as is_disputed
    from segment.chime_prod.login_success new 
    left join edw_db.feature_store.atom_user_sessions_v2 ls
            on new.user_id = ls.user_id
            and new.segment_device_id = ls.device_id
            and ls.session_timestamp between dateadd(minute, -30, new.timestamp) and new.timestamp
    left join partner_db.maxmind.ip_geolocation_mapping as map 
            on new.ip=map.ip
    left join partner_db.maxmind.GEOIP2_CITY_LOCATIONS_EN loc 
            on loc.geoname_id = map.geoname_id
    left join ml.model_inference.ato_login_alerts atomv2 
            on new.user_id::varchar=atomv2.user_id::varchar 
            and new.segment_device_id=atomv2.device_id 
            and atomv2.score<>0 
            and atomv2.session_timestamp between dateadd(minute, -30, new.timestamp) and new.timestamp
    left join streaming_platform.segment_and_hawker_production.dsml_events_predictions_segment_v2_atom_model_v3 atomv3 
            on new.user_id::varchar=atomv3._user_id::varchar 
            and new.segment_device_id=atomv3.device_id and atomv3.score<>0 
            and atomv3.snapshot_timestamp between dateadd(minute, -30, new.timestamp) and new.timestamp
    left join analytics.test.login_requests lr 
            on (new.user_id::varchar=lr.user_id::varchar 
            and lr.segment_device_id=new.segment_device_id 
            and lr.login_success_at between dateadd(second, -60, new.timestamp) and new.timestamp)
   where 1=1
   and new.user_id = 12829270
   -- and ls.user_id IN (select * from user_info)
   
   qualify row_number() over (partition by new.user_id, new.timestamp, new.segment_device_id order by lr.login_success_at desc, atomv3.snapshot_timestamp desc)=1 

   UNION ALL

/*Failed logins*/
select distinct user_id,
       convert_timezone('America/Los_Angeles',login_started_at)::timestamp as timestamp,
       segment_device_id as id,
       'n/a' as merchant_name,
       'login failed' as type,
       'FALIED RSN: '||case when login_failed_before_pw_check=1 then 'prelogin fail'
                            when arkose_success=0 then 'arkose fail'
                            when pw_success=0 then 'password fail'
                            else tfa_method_deprecated end ||'; PLATFORM: '||platform ||'; ATOMV3: '||ifnull(b.score::varchar,'') as description,
       'n/a' as card_type,
       'n/a' as decision,
       'n/a' as declined_resp_cd,
       'n/a' as vrs,
       'n/a' as rule_denied,
       'n/a' as "3DS_IND_RULES",
        0 as amt,
       'n/a' as is_disputed    
    from analytics.test.login_requests a
    left join streaming_platform.segment_and_hawker_production.dsml_events_predictions_segment_v2_atom_model_v3 b on (a.user_id::varchar=b._user_id::varchar and a.account_access_attempt_id=b.account_access_attempt_id)
    where 1=1
    and user_id IN (select * from user_info)
    and login_success=0 and mfa_auth_success=0 /*exclude data issue casued fail*/


    UNION ALL

/*info chg*/
select
item_id as user_id,
convert_timezone('America/Los_Angeles',created_at)::timestamp as timestamp,
versions_id::varchar as id,
'n/a' as merchant_name,
case when item_change='status' then 'status change' else concat(trim(item_change),' ','change') end as type,
concat(concat('change from:',change_from),' ',concat('to:',change_to),' ',concat('by: ',WHODUNNIT)) as description,
'n/a' as card_type,
'n/a' as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
'n/a' rules_denied,
'n/a' as "3DS_IND_RULES",
0 as amt,
'n/a' as is_disputed
from
  (select * , split_part(split_part(object_changes,':',1),'---',2) as item_change
  from analytics.looker.versions_pivot
  where 1=1
  and ( item_change ilike '%zip_code%'
      or  item_change ilike '%status%'
      or  item_change ilike '%state_code%'
      or  item_change ilike '%phone%'
      or  item_change ilike '%last_name%'
      or  item_change ilike '%first_name%'
      or  item_change ilike '%email%'
      or  item_change ilike '%address%')
      ) pii
where 1=1
and item_type = 'User'
and item_id IN (select * from user_info)

UNION ALL

/*app view activity*/
select
try_to_number(user_id) as user_id,
convert_timezone('America/Los_Angeles',original_timestamp)::timestamp as timestamp,
context_device_id::varchar as id,
'n/a' as merchant_name,
'app_view_activity' as type,
concat(concat('app location: ',ifnull(location,''))
       ,' ',concat('; label: ',ifnull(label,''))
       ,' ',concat('; what was viewed: ',ifnull(unique_id,''))
       ,' ',concat('; city_tz: ',ifnull(c.city_name,'')||','||ifnull(c.time_zone,''))
      ) as description,
'n/a' as card_type,
'n/a' as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
'n/a' rules_denied,
'n/a' as "3DS_IND_RULES",
0 as amt,
'n/a' as is_disputed
from segment.chime_prod.menu_button_tapped a
left join partner_db.maxmind.ip_geolocation_mapping b on (a.context_ip=b.ip)
left join partner_db.maxmind.GEOIP2_CITY_LOCATIONS_EN c on (b.geoname_id=c.geoname_id)
where 1=1
--and (unique_id ilike '%account%' or  unique_id ilike '%card%')
and location<>'Dialogue'
and try_to_number(user_id) IN (select * from user_info)


union all

/*card replacement records*/
select *
from (
select
USER_ID,
lead(CARD_CREATED_TS) over (partition by user_id, CARD_TYPE order by CARD_CREATED_TS) as timestamp,
CARD_NUMBER||' to '||
    lead(CARD_NUMBER) over (partition by user_id, CARD_TYPE order by CARD_CREATED_TS) as id,
'n/a' as merchant_name,
'card_replacement' as type,
'old card status changed to '||CARD_STATUS||' on '||LAST_STATUS_CHANGE_DT
    as description,
card_type as card_type,
'n/a' as decision,
'n/a' as decline_resp_cd,
'n/a' as vrs,
'n/a' rules_denied,
'n/a' as "3DS_IND_RULES",
0 as amt,
'n/a' as is_disputed
from EDW_DB.CORE.DIM_CARD
where 1=1
and user_id IN (select * from user_info)
and SHIPPED_DT is not null
) as card_replacement
where 1=1
and timestamp is not null

union all

/*tokenization device info*/
select 
a.user_id
, a.timestamp
, a.id
, merchant_name
, type
, concat('# of users provisioned by this device(p30d): ',cnt_provisioned_user_p30d,'; ',pan_source,'; resp_cd:',response_cd,'; dvc_info:',device_info)as description
, card_type
, decision
, decline_resp_cd
, vrs
, rules_denied
, "3DS_IND_RULES"
, amt
, is_disputed
from t1 a
left join 
    (
        select 
            distinct a.* 
            , count(distinct rdl.user_id) over (partition by a.id, a.timestamp) as cnt_provisioned_user_p30d
            from (select distinct timestamp, id, user_id from t1) a
            left join chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization rdl on (a.id=rdl.device_id and rdl.original_timestamp between dateadd(day,-30,a.timestamp) and dateadd(second,-1,a.timestamp) and rdl.user_id<>a.user_id)
            where 1=1
    ) b on (a.id=b.id and a.timestamp=b.timestamp)

union all
/*biometric session record*/
select user_id
, convert_timezone('America/Los_Angeles',timestamp) as timestamp
, device_id::varchar as id
, 'n/a' as merchant_name
, type
, concat(name, ';', context_os_name, ';', context_device_type) as description
, 'n/a' as card_type
, 'n/a' as decision
, 'n/a' as decline_resp_cd
, 'n/a' as vrs
, 'n/a' rules_denied
, 'n/a' as "3DS_IND_RULES"
, 0 as amt
, 'n/a' as is_disputed
from risk.test.hs_biometric_session_info
where 1=1
and user_id IN (select * from user_info)

union all
-- pin change activity
select user_id
, convert_timezone('America/Los_Angeles',original_timestamp) as timestamp
, id::varchar as id
, 'n/a' as merchant_name
, type
, concat(action, ';', account_type, ';', source, '; ip:', context_ip) as descriptiopn
, account_type as card_type
, 'n/a' as decision
, 'n/a' as decline_resp_cd
, 'n/a' as vrs
, 'n/a' rules_denied
, 'n/a' as "3DS_IND_RULES"
, 0 as amt
, 'n/a' as is_disputed
from SEGMENT.CHIME_PROD.account_event_alert
where 1=1
and type = 'pin_change'
and user_id IN (select * from user_info)

union all
-- view virtual card
select a.user_id
, original_timestamp as timestamp
, device_id as id
, 'n/a' as merchant_name
, service_type as type
, concat(ifnull(device_ip_address,''), ';', ifnull(device_model,''), ';', ifnull(device_os_version,'')) as descriptiopn
, b.card_type as card_type
, decision_outcome as decision
, 'n/a' as decline_resp_cd
, 'n/a' as vrs
, policy_name rules_denied
, 'n/a' as "3DS_IND_RULES"
, 0 as amt
, 'n/a' as is_disputed
from chime.decision_platform.bank_account_service a
left join edw_db.core.dim_card b on (a.user_id=b.user_id and a.uuid=b.uuid)
where 1=1
and is_shadow_mode=false 
and a.user_id IN (select * from user_info)
qualify row_number() over (partition by a.decision_id order by (select null))=1

	
	
order by timestamp
;
