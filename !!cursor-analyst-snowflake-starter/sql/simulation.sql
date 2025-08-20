/*
    context:
        https://chime.slack.com/archives/C0159HQJ8P5/p1752259728820299
        raiased by Lesley saying that since Samsung's recent AFT feature, lots of funding(debit from chime debit card, credit to merchant-samsungpay...) has been disputed and it is unknown about the fraud typology - compromised card or FPF

    This finding is align with our recent dispute trend findings by spending risk team:
        - Bin noted fraud spike from samsungpay merchant with phone change, new device login. recent provisoing signal
        - launched 2 rules(hb and sms) to mitigate on 7/8
            - https://compass.chime.com/decision-platform/policies/fc8b7d62-6d8c-42cb-a96f-a834f6a62e23?tab=details
            - https://compass.chime.com/decision-platform/policies/6fd1295d-415f-4190-a085-d56e1b28e5f9?tab=details

    Puepose of analysis:
        - how to quantify the attack scope:
            - $ disputed on samsungpay
            - $ disputed on other merchant with recent samsung manual provisioning 

        - understand fraud typology:
            - % of disputed from above, with pre-login phone change(faciliated by last4 policy due to atom zero)
            - % of disputed meeting ATO signals, for those not met, why? - with recent FPF signals? funding etc - ask Jiren for the ATO definition part
            

*/



------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

-- for dispute volume

-- scope: dispute metric related to samsungpay AFT 
with t1 as(
    select *
    from risk.prod.disputed_transactions
    where 1=1
    and transaction_timestamp::date>='2025-05-01'
    and merchant_name ilike '%samsungpay%'
    qualify row_number() over (partition by user_id, authorization_code order by null)=1
)
select 
1
--transaction_timestamp::date as txn_week
, count(distinct user_id) as cnt_user, count(distinct user_dispute_claim_id) as cnt_dispute, sum(transaction_amount*-1) as sum_auth--, sum(sum_auth) over (order by txn_week) as acumulative_disputed_sum
--trunc(transaction_timestamp::date,'week') as txn_week, count(distinct user_id) as cnt_user, count(distinct user_dispute_claim_id) as cnt_dispute, sum(transaction_amount*-1) as sum_auth, sum(sum_auth) over (order by txn_week) as acumulative_disputed_sum
--trunc(dispute_created_at::date,'week') as txn_week, count(distinct user_id) as cnt_user, count(distinct user_dispute_claim_id) as cnt_dispute, sum(transaction_amount*-1) as sum_auth, sum(sum_auth) over (order by txn_week) as acumulative_disputed_sum

    from t1
    group by all
    order by 1
;

     /*
        attack period is between 6/10 to 7/2
     
     */



select top 10 * 
    from risk.test.hding_samsung_pay_disputed_driver
    where 1=1
    and user_id='77795113'
    ;
    

------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
-- driver table creation and summary

-- driver table: samsungpay disputed with phone, device login, provisioning signals
create or replace table risk.test.hding_samsung_pay_disputed_driver as(

with t1 as(
    -- samsungpay dispute data
    select user_id, authorization_code
    , user_dispute_claim_id
    , merchant_name
    , merchant_category_code
    , reason
    , resolution
    , transaction_amount
    , dispute_created_at
    , transaction_timestamp
    , processor
    , b.phone, b.first_name, b.last_name
        from risk.prod.disputed_transactions a
        left join chime.finance.members b on (a.user_id=b.id)
        where 1=1
        and transaction_timestamp::date between '2025-06-12' and '2025-07-02'
        and merchant_name ilike '%samsungpay%'
        qualify row_number() over (partition by a.user_id, a.authorization_code order by null)=1
), t2 as (

    select a.*
    , b.original_timestamp as phone_chg_ts
    , b.decision_id as phone_chg_decision_id
    , b.originating_client as phone_chg_originating_client
    , b.update_context
    , b.device_id as phone_chg_dvc_id
    , b.device_model as phone_chg_device_model
    , b.ml_prediction_model as phone_chg_atom
    
    , c.original_timestamp as last4_ts
    , c.ml_prediction_model_score as last4_atom
    , c.device_id as last4_device_id
    , c.decision_id as last4_decision_id
    
    , d.device_id as mfa_device_id
    , d.ml_inference_model_score as mfa_atom
    , d.ml_prediction_model_score as mfa_atom2
    , d.platform as mfa_platform
    , d.device_manufacturer as mfa_device_manufacture
    , d.device_model as mfa_device_model
    , d.decision_outcome as mfa_decision_outcome
    , d.original_timestamp as mfa_ts
    , d.decision_id as mfa_decision_id
        from t1 a
        /*
        -- phone chg indicator
        left join analytics.looker.versions_pivot b on (b.item_type = 'User' 
                                                        and a.user_id=b.item_id
                                                        and b.event='update' 
                                                        and b.object_changes ilike '%phone%' 
                                                        and b.created_at between dateadd(day,-3,a.transaction_timestamp) and dateadd(second,-1,a.transaction_timestamp)
                                                        and b.created_at::date between '2025-06-11' and '2025-07-03'
                                                        )
        */
        -- phone chg indicator
        left join (
            select user_id, original_timestamp, decision_id
            , originating_client
            , update_context
            , device_platform
            , device_id
            , device_model
            , device_os_name
            , device_ip_address
            , device_network_carrier
            , app_version
            , remote_controlled_apps
            , ml_prediction_model
            from chime.decision_platform.user_service
            where 1=1
            and decision_outcome='allow'
            and pii_type='phone'
            and original_timestamp::date between '2025-06-11' and '2025-07-03'
            and is_shadow_mode=false
            and update_context not ilike '%eligibility_check'
        ) b on (
                a.user_id=b.user_id
                and b.original_timestamp between dateadd(day,-3,a.transaction_timestamp) and dateadd(second,-1,a.transaction_timestamp)
        )
        -- pre login phone chg indicator
        left join chime.decision_platform.authn c on (a.user_id=c.user_id
                                                        and c.is_shadow_mode=false
                                                        and c.event_name='logged_out_phone_update'
                                                        and c.policy_name='pre_login_mfa_phone_update___low_risk'
                                                        and c.decision_outcome='last4'
                                                        and c.original_timestamp::date between '2025-06-11' and '2025-07-03'
                                                        and c.original_timestamp between dateadd(day,-3, a.transaction_timestamp) and a.transaction_timestamp
                                                        
                                                    )
        -- pre login phone chg mfa login info
        left join chime.decision_platform.authn d on (c.user_id=d.user_id 
                                                     and d.is_shadow_mode=false 
                                                     and d.original_timestamp::date between '2025-06-11' and '2025-07-03'
                                                     and d.session_event='password_auth_succeeded' 
                                                     and d.original_timestamp between dateadd(hour,-1, c.original_timestamp) and c.original_timestamp
                                                     )

        qualify row_number() over (partition by a.user_id, a.authorization_code order by b.original_timestamp desc, c.original_timestamp desc, d.original_timestamp desc)=1


), t3 as(
-- finally append provisioning signal
select a.*
, b.decision_id as provision_decision_id
, b.phone_number_last_4
, b.pan_source
, b.original_timestamp as provision_ts
, b.response_cd as provision_resp_cd
, b.token_requestor_company_name as provision_token_company
, b.token_type as provision_token_type
, b.device_name as provision_device_nm
    from t2 a
    left join chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization b on (

                                a.user_id=b.user_id
                                and b.is_shadow_mode=false
                                and b.original_timestamp::date between '2025-06-11' and '2025-07-03'
                                and b.pan_source in ('key_entered','mobile_banking_app')
                                and b.original_timestamp::date between dateadd(day,-3, a.transaction_timestamp) and a.transaction_timestamp
                            )
  qualify row_number() over (partition by a.user_id, a.authorization_code order by b.original_timestamp desc)=1            
)
  -- append latest login
  select a.*
  , b.tfa_method as new_dvc_login_method
  , b.platform as new_dvc_login_platform
  , b.login_success_at as new_dvc_login_ts
  , b.segment_device_id as new_dvc_id
  , b.account_access_attempt_id as new_dvc_a3id
    from t3 a
    left join 
        (select user_id
        , login_success
        , tfa_method
        , login_success_at
        , platform
        , segment_device_id
        , account_access_attempt_id
        , lag(login_success_at) over (partition by user_id, segment_device_id order by login_success_at) as last_same_dvc_success_login_ts
            from analytics.test.login_requests
            where 1=1
            and login_success_at is not null
        ) b  on (
                a.user_id=b.user_id
                and b.last_same_dvc_success_login_ts is null
                and b.login_success_at between dateadd(day,-3,a.transaction_timestamp) and dateadd(second,-1,a.transaction_timestamp) 
        )
    qualify row_number() over (partition by a.user_id, a.authorization_code order by b.login_success_at desc)=1

);



-- appending latest mobile login device ID, ts; latest app acitivity device ID, ts, etc.
create or replace table risk.test.hding_samsung_pay_last_login_app_activity as(

    with t1 as(
        select a.user_id, a.authorization_code, coalesce(m.snapshot_timestamp,a.transaction_timestamp) as transaction_timestamp
        , b.segment_device_id as last_mobile_login_devcie_id
        , b.original_timestamp as last_mobile_login_ts
        , b.ip as last_mobile_login_ip
        , b.app_version as last_mobile_login_app_version
            from risk.test.hding_samsung_pay_disputed_driver a
            left join risk.test.spending_risk_master_driver_table m on (a.user_id=m.user_id and a.authorization_code=coalesce(m.settled_auth_id,m.auth_id) and m.snapshot_timestamp::date between '2025-06-10' and '2025-07-03')
            inner join segment.chime_prod.login_success b on (a.user_id::varchar=b.user_id::varchar and b.platform in ('ios','android') and b.original_timestamp<=a.transaction_timestamp)
            where 1=1
            qualify row_number() over (partition by a.user_id, a.authorization_code order by b.original_timestamp desc)=1
    )
    select a.*
    , b.context_device_id as last_app_activity_device_id
    , b.timestamp as last_app_activity_ts
    , context_traits_name as last_app_activity_traits_name
    , context_timezone as last_app_activity_tz
    , b.context_locale as last_app_activity_locale
    , b.context_device_name as last_app_activity_device_name
    , b.context_ip as last_app_activity_ip
    , b.context_app_version as last_app_activity_app_version
    , b.context_device_model as last_app_activity_device_model
    , b.location as last_app_activity_location
    
        from t1 a
        inner join segment.chime_prod.menu_button_tapped b on (a.user_id::varchar=b.user_id::varchar 
                                                                and b.timestamp between dateadd(hour,-2,a.transaction_timestamp) and a.transaction_timestamp
                                                                and b.timestamp between '2025-06-10' and '2025-07-03'
                                                                )
        qualify row_number() over (partition by a.user_id, a.authorization_code order by b.timestamp desc)=1
);


-- feature appending: for each disputed samsung with recent new dvc login(web), append nudata device device_type_mismatch indicator
--https://chime.slack.com/archives/C047TBLUBB3/p1753889474742509?thread_ts=1753290383.823869&cid=C047TBLUBB3

create or replace table risk.test.hding_samsung_pay_nudata_mismatch_dvc_type as(
    with t1 as(
    select user_id, authorization_code, new_dvc_a3id, new_dvc_login_ts, new_dvc_id
        from risk.test.hding_samsung_pay_disputed_driver
        where 1=1
        and new_dvc_login_platform ilike '%web%'
    )
    select a.*
    , request:atom_event:nu_risk_response:device_type::varchar as nudata_device_type
    , request:atom_event:nu_risk_response:device_type_mismatch::varchar as nudata_device_type_mismatch
        from t1 a
        left join STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG b on (
                        a.user_id::varchar=b.user_id::varchar
                        and a.new_dvc_id=b.device_id
                        and a.new_dvc_a3id=b.request:atom_event:account_access_attempt_id::varchar
                        and b._creation_timestamp::date between '2025-06-10' and '2025-07-03'
                        and b.labels:service_names != 'shadow' 
                        and b.event_name='atom_event'

        )
    qualify row_number() over (partition by a.user_id, a.authorization_code order by null)=1        

);




// data profiling
-- summary: volume
select count(distinct user_id) as cnt_user
    , sum(transaction_amount*-1) as sum_disputed
    , sum(case when phone_chg_ts is not null then transaction_amount*-1 else 0 end) as sum_disputed_phone_chg
    , sum(case when phone_chg_ts is not null and last4_decision_id is not null then transaction_amount*-1 else 0 end) as sum_disputed_phone_chg_last4
    , sum(case when phone_chg_ts is not null and last4_atom=0 then transaction_amount*-1 else 0 end) as sum_disputed_phone_chg_atom0

    , sum_disputed_phone_chg/sum_disputed as perc_disputed_phone_chg
    , sum_disputed_phone_chg_last4/sum_disputed as perc_disputed_phone_chg_last4
    , sum_disputed_phone_chg_atom0/sum_disputed as perc_disputed_phone_chg_atom0
    

        from risk.test.hding_samsung_pay_disputed_driver
        where 1=1
        group by all
;


 

-- summary by category
select 
a.phone_chg_ts is not null as phn_chg_ind
, a.new_dvc_login_ts is not null as new_dvc_ind
, a.last4_decision_id is not null as last4_ind
, a.last4_atom=0 as last_4_atom0_ind
, a.provision_ts is not null as provision_ind
, count(distinct a.user_id) as cnt_user
, sum(transaction_amount*-1) as sum_disputed
, sum(case when b.last_mobile_login_devcie_id<>b.last_app_activity_device_id then transaction_amount*-1 else 0 end) as sum_unknown_devices_disputed
, sum_unknown_devices_disputed/sum_disputed as perc_unknown_devices_disputed

, sum(case when c.user_id is not null then transaction_amount*-1 else 0 end) as sum_new_dvc_nudata_mismatched_type
, sum_new_dvc_nudata_mismatched_type/sum_disputed as perc_new_dvc_nudata_mismatched_type
    from risk.test.hding_samsung_pay_disputed_driver a
    left join risk.test.hding_samsung_pay_last_login_app_activity b on (a.user_id=b.user_id and a.authorization_code=b.authorization_code)
    left join risk.test.hding_samsung_pay_nudata_mismatch_dvc_type c on (a.user_id=c.user_id and a.authorization_code=c.authorization_code)
    group by all
    order by 1,2,3,4,5
;

    -- all had phone change
    -- only 8% was last 4ed by the policy loophole(due to atom=0 and now fixed)
    -- for those with phone change signal, ~80% disputed $ cases fitting into the pattern: last mobile logged in device <> last app acitivity mobile device(unknown/no trace device) appearence 

-- pivot
-- summary by category
select 
a.phone_chg_ts is not null as phn_chg_ind
, a.new_dvc_login_ts is not null as new_dvc_ind
, a.last4_decision_id is not null as last4_ind
, a.last4_atom=0 as last_4_atom0_ind
, a.provision_ts is not null as provision_ind
, c.user_id is not null as new_dvc_login_nudata_mismatched_type
, a.*
    from risk.test.hding_samsung_pay_disputed_driver a
    left join risk.test.hding_samsung_pay_last_login_app_activity b on (a.user_id=b.user_id and a.authorization_code=b.authorization_code)
    left join risk.test.hding_samsung_pay_nudata_mismatch_dvc_type c on (a.user_id=c.user_id and a.authorization_code=c.authorization_code)
;
    
-- case review/study: with phone change but not facilitated by last 4 policy
select user_id, sum(transaction_amount*-1) as sum_disputed
    from risk.test.hding_samsung_pay_disputed_driver
    where 1=1
    and last4_decision_id is null and phone_chg_ts is not null
    group by all
    order by 2 desc
;
    
-- case review: without phone change 
select top 100 user_id, sum(transaction_amount*-1) as sum_disputed
    from risk.test.hding_samsung_pay_disputed_driver
    where 1=1
    and phone_chg_ts is null
    group by all
    --order by 2 desc
;


/*
43237349
44310679
32308544
78775919
*/
-- case review from no phone change:suspected FPF segment for Alyssa review
with t1 as(

    select top 100 user_id
    , count(distinct authorization_code) as cnt_disputed_txn
    , sum(transaction_amount*-1) as sum_disputed_samsung_aft
    , listagg(authorization_code,',') as disputed_auth_id
    , listagg(user_dispute_claim_id,',') as dispute_claim_id
        from risk.test.hding_samsung_pay_disputed_driver
        where 1=1
        and phone_chg_ts is null
        group by all
)
select a.*
, b.transaction_timestamp as first_txn_ts
, b.dispute_created_at as first_disputed_ts
, b.resolution as first_resolution_outcome
, b.processor
, b.phone
, b.first_name
, b.last_name

, b.phone_chg_ts as first_phn_chg_ts
, b.change_from  
, b.change_to

, b.pan_source as first_provision_method
, b.provision_ts as first_provision_ts
, b.provision_resp_cd as first_provision_resp_cd
, b.provision_token_company as first_provision_token_company
, b.provision_device_nm as first_provision_device_nm
, b.phone_number_last_4 as first_provision_phone_last_4

, b.new_dvc_login_ts as first_new_dvc_login_ts
, b.new_dvc_login_method as first_new_dvc_login_method
, b.new_dvc_login_platform as first_new_dvc_login_platform
, b.new_dvc_id as first_new_dvc_id

    from t1 a
    left join risk.test.hding_samsung_pay_disputed_driver b on (a.user_id=b.user_id)
qualify row_number() over (partition by a.user_id order by b.transaction_timestamp)=1
;
 
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
/*OIT simulation - % of disputed $ conducted on a unknown device(device ID <> last mobile login device ID)*/
create or replace table risk.test.hding_oit_last_login_app_activity as(

    with t1 as(
        select a.user_id, a.authorization_code, a.original_timestamp as transaction_timestamp, a.transfer_amount, a.device_id as transfer_device_id
        , b.segment_device_id as last_mobile_login_devcie_id
        , b.original_timestamp as last_mobile_login_ts
        , b.ip as last_mobile_login_ip
        , b.app_version as last_mobile_login_app_version
            from risk.test.bwhite_oit_txn_overview a
            left join segment.chime_prod.login_success b on (a.user_id::varchar=b.user_id::varchar and b.platform in ('ios','android') and b.original_timestamp<=a.transaction_timestamp)
            where 1=1
            and a.dispute_ind=1
            and (a.remote_controlled_apps is not null or (a.CNT_NEWDVCSUC_P12H = 1 or a.CNT_UNIQUEDEVICE_P1D = 1)) // fitting oit dispute trend
            qualify row_number() over (partition by a.user_id, a.authorization_code order by b.original_timestamp desc)=1
    )
    select a.*
    , b.context_device_id as last_app_activity_device_id
    , b.timestamp as last_app_activity_ts
    , context_traits_name as last_app_activity_traits_name
    , context_timezone as last_app_activity_tz
    , b.context_locale as last_app_activity_locale
    , b.context_device_name as last_app_activity_device_name
    , b.context_ip as last_app_activity_ip
    , b.context_app_version as last_app_activity_app_version
    , b.context_device_model as last_app_activity_device_model
    , b.location as last_app_activity_location
    
        from t1 a
        left join segment.chime_prod.menu_button_tapped b on (a.user_id::varchar=b.user_id::varchar 
                                                                and b.timestamp between dateadd(hour,-2,a.transaction_timestamp) and a.transaction_timestamp
                                                                and b.timestamp between '2025-06-10' and '2025-07-03'
                                                                )
        qualify row_number() over (partition by a.user_id, a.authorization_code order by b.timestamp desc)=1
);

-- profiling
select count(distinct user_id) as cnt_user
, sum(transfer_amount) as sum_transfer
, sum(case when last_mobile_login_devcie_id<>transfer_device_id then transfer_amount else 0 end) as sum_unknown_device_disputed
, sum_unknown_device_disputed/sum_transfer as perc_unknown_device_disputed
    from risk.test.hding_oit_last_login_app_activity
;   /*
        -- only 33% OIT disputed $ from 2025.06 trend has unknown device ID present
    */

-- case study
select top 10 user_id, sum(transfer_amount)
    from risk.test.hding_oit_last_login_app_activity
    where 1=1
    and transfer_device_id<>last_mobile_login_devcie_id
    group by all
    order by 2 desc;


------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
-- portfolio simulation: unknown device present(diff from last mobile login device)what's the dispute rate for offloadings(all type) within next 1 day

-- segment.chime_prod.menu_button_tapped
create or replace table risk.test.hding_unknown_device_data as(
    with t1 as(
    -- 2025.01 - 2025.06 user_id and context_device_id with its first appearence time
    select user_id
        , context_device_id 
        , timestamp 
        , context_traits_name 
        , context_timezone
        , context_locale
        , context_device_name
        , context_ip
        , context_app_version
        , context_device_model
        , location
        from segment.chime_prod.screens
        where 1=1
        and timestamp::date between '2025-01-01' and '2025-06-30'
        qualify row_number() over (partition by user_id, context_device_id order by timestamp)=1
    )
    -- for each user_id, context_device_id pair, find latest mobile login records and its corresponding device_id
    select a.*
        from t1 a
        left join segment.chime_prod.login_success b on (a.user_id=b.user_id 
                                                         and a.context_device_id=b.segment_device_id
                                                            // and b.platform in ('ios','android') -- noted that some device ID has been labledas web at login time
                                                            and b.original_timestamp<=a.timestamp)
        where 1=1
        and b.user_id is null
);




-- basic profiling:

select trunc(timestamp::date,'month') as txn_mth
, count(distinct context_device_id) as cnt_dvc
, count(distinct user_id) as cnt_user
    from risk.test.hding_unknown_device_data
    where 1=1
    group by all
    order by 1;

    /*
     -- every week there're significant # of app activity device ID does not have login history 
     -- the context_device_id might be problematic - does not mean it is a risk indicator/correct way to identify unknown devices
    
    */



-- simulating OIT offloaded from device without login history: recall and precision of dispute
create or replace table risk.test.hding_oit_offloaded_by_unknown_device as(
    select a.user_id
    , a.original_timestamp
    , transfer_amount
    , atom_v3_score_
    , dispute_ind
    , case when b.user_id is null then 1 else 0 end as unknown_device_ind
    , b.platform as oit_device_last_login_platform
    , b._creation_timestamp as oit_device_last_login_ts
        from risk.test.bwhite_oit_txn_overview a
        left join streaming_platform.segment_and_hawker_production.authentication_v1_login_request_submitted b on
        (
                                                        a.user_id=b.user_id 
                                                        and a.device_id=b.segment_device_id
                                                        --and b.original_timestamp<=a.original_timestamp
        
        )
        /*
        left join segment.chime_prod.login_success b on (a.user_id=b.user_id 
                                                        and a.device_id=b.segment_device_id
                                                        and b.original_timestamp<=a.original_timestamp
                                                        )
        */
        where 1=1
        and a.transfer_outcome='Succeeded' 
        qualify row_number() over (partition by decision_id order by b._creation_timestamp desc)=1
);

-- profiling: OIT initiated from a device without login success records
select 
trunc(original_timestamp::date,'week') as txn_week
, sum(transfer_amount) as sum_oit_overall
, sum(transfer_amount*dispute_ind) as sum_disputed_overall
, sum_disputed_overall/sum_oit_overall as rate_dispute_overall

, sum(unknown_device_ind*transfer_amount) as sum_oit_unknown_dvc
, sum(unknown_device_ind*dispute_ind*transfer_amount) as sum_oit_unknown_dvc_disputed
, sum_oit_unknown_dvc_disputed/sum_oit_unknown_dvc as rate_dispute_unknown_dvc

, sum_oit_unknown_dvc_disputed/nullifzero(sum_disputed_overall) as rate_recall_unknown_dvc

    from risk.test.hding_oit_offloaded_by_unknown_device
    where 1=1
    group by all
    order by 1;
    
    /*
    -- only have dispute recall/precision over attack period
    -- highly likely, there's data issue - OIT initiation device ID is wrongly populated or data source is failling to identify the device and assigned a new one causing the appearence of "unknown device"
    */


-- unknown device OIT or not and atom score distribution;
select unknown_device_ind
, width_bucket(atom_v3_score_*100,0.000000001,100,10) as bucket_num
, min(atom_v3_score_*100) as min_val, max(atom_v3_score_*100) as max_val
, count(*) as cnt
, count(*)/sum(cnt) over (partition by unknown_device_ind)as perc_of_device_total

, sum(transfer_amount) as sum_oit
, sum(dispute_ind*transfer_amount) as sum_oit_dispute
, sum_oit_dispute/sum_oit as rate_dispute
    from risk.test.hding_oit_offloaded_by_unknown_device
    group by all
    order by 1,2
;
    /*
    -- OIT initiated by unknown devices, ~99% has 0 as atom v3 score, while the dispute rate is just 20 bps, not high!
    -- OIT initiated by unknown devices dispute rate is just higher during attack period: week of 6/9 and 6/16
    */



-- OIT population segmentation:
    /*
    % of OIT disputed dollar initiation device has no login submitted records at all
    % of OIT disputed dollar initiation device has WEB login records
    % of OIT disputed dollars initiation device was initiated from a mobile device with login records
    */
    
select 
case when oit_device_last_login_platform is null then '3. no login record(unknown device)' 
     when oit_device_last_login_platform ilike '%web%' then '2. recent "web" login device'
     when oit_device_last_login_platform not ilike '%web%' then '1. recent mobile login device' end as oit_device_cat
, trunc(original_timestamp::date,'week') as txn_week
, count(distinct user_id) as cnt_user
, sum(transfer_amount) as sum_oit_overall
, sum(transfer_amount*dispute_ind) as sum_disputed_overall
, sum_disputed_overall/nullifzero(sum_oit_overall) as rate_dispute_overall

, sum(unknown_device_ind*transfer_amount) as sum_oit_unknown_dvc
, sum(unknown_device_ind*dispute_ind*transfer_amount) as sum_oit_unknown_dvc_disputed
, sum_oit_unknown_dvc_disputed/nullifzero(sum_oit_unknown_dvc) as rate_dispute_unknown_dvc

, sum_oit_unknown_dvc_disputed/nullifzero(sum_disputed_overall) as rate_recall_unknown_dvc

    from risk.test.hding_oit_offloaded_by_unknown_device
    where 1=1
    group by all
    order by 1
;


select user_id, sum(transfer_amount)
    from risk.test.hding_oit_offloaded_by_unknown_device
    where 1=1
    and oit_device_last_login_platform is null
    and dispute_ind=1
    group by all
    order by 2 desc
;
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

-- adhoc

-- 63967568
-- individual case study
select *
    from risk.test.hding_samsung_pay_disputed_driver
    where 1=1
    and user_id='77795113'
    order by transaction_timestamp
;


select user_id, sum(transaction_amount*-1) as sum_disputed
    from risk.test.hding_samsung_pay_disputed_driver
    where 1=1
    and phone_chg_ts is not null and last4_decision_id is not  null and provision_ts is not null 
    group by all
    order by 2 desc;


select *
    from chime.decision_platform.mobile_wallet_provisioning_and_card_tokenization
    where 1=1
    and user_id='35081050'
    and is_shadow_mode=false
    and pan_source in ('key_entered','mobile_banking_app')
    order by original_timestamp desc
;


-- 52771097

select *
    from chime.decision_platform.authn c
    where 1=1
    and user_id='2057762'
    --and c.event_name='logged_out_phone_update'
    --and c.policy_name='pre_login_mfa_phone_update___low_risk'
    --and c.decision_outcome='last4'
    and c.original_timestamp::date between '2025-06-11' and '2025-07-03'
;

-- 60592448

select pan_source, provision_resp_cd, processor
, sum(transaction_amount*-1) as sum_disputed
, sum(case when right(phone,4)=phone_number_last_4 then transaction_amount*-1 else 0 end)/sum_disputed as perc_same_phone_provision 
    from risk.test.hding_samsung_pay_disputed_driver
    where 1=1
    and phone_chg_ts is null and provision_ts is not null
    group by all
    order by 1,2
;




select count(*)
    from segment.chime_prod.screens
    where 1=1
    and timestamp::date='2025-06-01'
;

-- 168254205
-- 9886761
select top 100 context_device_id, context_traits_email, *
    from segment.chime_prod.menu_button_tapped
    where 1=1
    and user_id='2057762'
    and timestamp::date='2025-06-28'
;

select top 10 *
    from segment.chime_prod.login_success
    where 1=1
    and original_timestamp::date='2025-06-01'
;

select count(*)
    from segment.chime_prod.menu_button_tapped
    where 1=1
    and timestamp::date='2025-06-01'
;





select top 10 *
    from risk.test.hding_samsung_pay_last_login_app_activity
    where 1=1
    and user_id='2057762'
;
-- 2057762	10752799034	Sat, 28 Jun 2025 20:38:58 -0700

select *
    from risk.test.spending_risk_master_driver_table 
    where 1=1
    and user_id='2057762'
    and 
;





select authen_decision_id, auth_decision_id, count(*)
    from risk.test.hding_3ds_auth_final 
    group by all
    having count(*)>1;


    
    a
    left join edw_db.core.fct_realtime_auth_event b on (a.user_id=b.user_id and b.)
;


select device_id,*
    from risk.test.bwhite_oit_txn_overview
    where 1=1
    and user_id='3998824'
;


select *
    from analytics.test.login_requests
    where 1=1
    and user_id='3998824'
;

select *
    from risk.test.hding_oit_last_login_app_activity
    where 1=1
    and user_id='11294736'
;


select convert_timezone('America/Los_Angeles',login_started_at) as login_started_at
, tfa_method_deprecated
, tfa_method
, atom_decision_result
, request_id
, account_access_attempt_id
, segment_device_id
, platform
, web_breakdown
, device_manufacturer
, device_model

, login_strategy
, login_success
, convert_timezone('America/Los_Angeles',login_success_at) as login_success_at

, arkose_success
, arkose_result
, pre_pw_checks_arkose
, pw_success
, convert_timezone('America/Los_Angeles',pw_success_at) as pw_success_at

, mfa_required
, mfa_required_at
, mfa_code_submitted
, convert_timezone('America/Los_Angeles',mfa_submitted_at) as mfa_submitted_at
, mfa_auth_success

, magic_link_submitted
, convert_timezone('America/Los_Angeles',magic_link_submitted_at) as magic_link_submitted_at
, magic_link_success
, convert_timezone('America/Los_Angeles',magic_link_success_at) as magic_link_success_at

, scanid_required
, scanid_success


    from analytics.test.login_requests
    where 1=1
    and user_id='2548063'
    and convert_timezone('America/Los_Angeles',login_started_at)::date>='2025-06-07'
order by login_started_at
;


select *
    from segment.chime_prod.login_success
    where 1=1
    and user_id='2548063'
    and timestamp::date='2025-06-18'
;



select *
    from chime.decision_platform.instant_transfers
    where 1=1
    and user_id='2548063'
    and is_shadow_mode=false
;
-- acdf14e5-e72f-41f2-b3a3-8caffa837f98

select segment_device_id, _creation_timestamp, platform
    from streaming_platform.segment_and_hawker_production.authentication_v1_login_request_submitted
    where 1=1
    and user_id='2548063'
    and _creation_timestamp::date='2025-06-18'
;

select distinct original_timestamp,event_name, device_id, device_model, device_os_name
    from chime.decision_platform.bank_account_service
    where 1=1
    and is_shadow_mode=false
    and user_id='2548063'
    and original_timestamp::date='2025-06-18'
    and device_id='acdf14e5-e72f-41f2-b3a3-8caffa837f98'
;






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
;


select device_id, *
    from chime.decision_platform.execute_transfer_event 
    where 1=1
    and user_id='24631028'
; 
-- eb89de53-d43c-4b5f-9355-168f94587634


