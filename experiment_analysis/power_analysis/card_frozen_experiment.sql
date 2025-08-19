begin

/*
>> this task is to update data tables for experiment: Frozen Card Override;
*/

/* Power User */
/* create auth data driver*/
create or replace table rest.test.card_frozen_override_power_user as(
with t1 as(
    -- exp dist users
    select 
        unit_id as user_id
        , variant_key
        , _creation_timestamp as exp_added_timestamp
    from  streaming_platform.segment_and_hawker_production.memberexperience_v1_experiment_bucketed_event
    where experiment_key = 'frozen_card_overrides_experiment_power_user'
    and _creation_timestamp::date >= '2025-05-22'
    qualify row_number() over (partition by user_id order by exp_added_timestamp)=1
    
)
    -- pull appv txn
    select 
    a.*
    , b.auth_type
    , b.auth_id
    , b.settled_auth_id
    , b.snapshot_timestamp
    , b.req_amt
    , b.final_amt
    , b.entry_type
    , b.merchant_name
    , case when b.merchant_name ilike '%*%' then trim(split(b.merchant_name,'*')[0]) 
      else split(REGEXP_REPLACE(REGEXP_REPLACE(b.merchant_name, '[^A-Za-z]+', ' '),'\s+', ' '),' ')[0]::varchar||' '|| split(REGEXP_REPLACE(REGEXP_REPLACE(b.merchant_name, '[^A-Za-z]+', ' '),'\s+', ' '),' ')[1]::varchar 
        end as merchant_name2 
    , b.mcc_cd
    , b.is_international
    , cast(null as varchar(100)) as allowed_policy_nm
    , cast(null as TIMESTAMP_LTZ(9)) as dispute_created_at
    , cast(null as varchar(100)) as reason
    , cast(null as numeric) as final_loss
    from t1 a
    inner join risk.test.spending_risk_master_driver_table b on (a.user_id=b.user_id 
                                                                    and 
                                                                 b.snapshot_timestamp>=exp_added_timestamp //later data
                                                                )
);

/* update auth driver table with allowed policy name */
merge into rest.test.card_frozen_override_power_user a
using (
    select a.user_id, a.auth_id, b.policy_name
        from rest.test.card_frozen_override_power_user a
        inner join chime.decision_platform.card_auth_events b on (a.user_id=b.user_id and a.auth_id=b.auth_id and b.policy_name in ('frozen_card_override_namelist_check_v2','frozen_card_override_cp_namelist_check') and b.original_timestamp::date>='2025-05-22')
        inner join (select distinct policy_name, policy_created_at
                    from chime.decision_platform.policies
                    where 1=1
                    and policy_name in ('frozen_card_override_namelist_check_v2','frozen_card_override_cp_namelist_check')
                    and event_name ='card_auth_event') c on (b.policy_name=c.policy_name) 
        qualify row_number() over (partition by a.user_id, a.auth_id order by c.policy_created_at)=1   
) b on (a.user_id=b.user_id and a.auth_id=b.auth_id)
when matched then update set allowed_policy_nm=b.policy_name
; 



/* update auth driver table with dispute ind */
merge into rest.test.card_frozen_override_power_user a
using (
    select a.user_id, a.auth_id
    , b.dispute_created_at, b.reason
    , zeroifnull(amount_final_cred)+zeroifnull(amount_final_rev) as final_loss
        from rest.test.card_frozen_override_power_user a
        inner join risk.prod.disputed_transactions b on (a.user_id=b.user_id and (b.authorization_code=a.auth_id or b.authorization_code=a.settled_auth_id) and b.transaction_timestamp::date>='2025-05-22')
        left join risk.prod.all_disputable_transactions c on (b.user_id=c.user_id and b.authorization_code=c.authorization_code and c.transaction_timestamp::date>='2025-05-22' and c.dispute_created_at is not null)
        qualify row_number() over (partition by a.user_id, a.auth_id order by b.dispute_created_at)=1
) b on (a.user_id=b.user_id and a.auth_id=b.auth_id)
when matched then update set 
    dispute_created_at=b.dispute_created_at
    , reason=b.reason
    , final_loss=b.final_loss
; 



/* delete latest not complete day's records frmo deny auth table */
delete from rest.test.card_frozen_override_power_user_denied_auth where original_timestamp::date>=(select max(original_timestamp::date) from rest.test.card_frozen_override_power_user_denied_auth);

/* insert latest deny auth data */
insert into rest.test.card_frozen_override_power_user_denied_auth
with t1 as(
    -- exp dist users
    select 
        unit_id as user_id
        , variant_key
        , _creation_timestamp as exp_added_timestamp
    from  streaming_platform.segment_and_hawker_production.memberexperience_v1_experiment_bucketed_event
    where experiment_key = 'frozen_card_overrides_experiment_power_user'
    and _creation_timestamp::date >= '2025-05-22'
    qualify row_number() over (partition by user_id order by exp_added_timestamp)=1
    
)
    -- pull appv txn
    select 
    a.*
    , b.auth_id
    , b.original_timestamp
    , abs(b.final_amt) as final_amt
    , b.updated_response_cd
    , b.policy_name
    , b.merch_descriptor
    from t1 a
    inner join chime.decision_platform.card_auth_events b on (a.user_id=b.user_id 
                                                                and b.original_timestamp::date>= a.exp_added_timestamp
                                                               -- (select max(original_timestamp::date)+1 from rest.test.trust_member_merchant_experiment_v2_denied_auth)
                                                                and b.updated_response_cd not in ('00','10')
                                                              )
    qualify row_number() over (partition by b.user_id, b.merch_descriptor, b.final_amt, trunc(b.original_timestamp,'hour') order by null)=1

;


/* Non Power User */
/* create auth data driver*/
create or replace table rest.test.card_frozen_override_non_power_user as(
with t1 as(
    -- exp dist users
    select 
        unit_id as user_id
        , variant_key
        , _creation_timestamp as exp_added_timestamp
    from  streaming_platform.segment_and_hawker_production.memberexperience_v1_experiment_bucketed_event
    where experiment_key = 'frozen_card_overrides_experiment_nonpower_user'
    and _creation_timestamp::date >= '2025-05-22'
    qualify row_number() over (partition by user_id order by exp_added_timestamp)=1
    
)
    -- pull appv txn
    select 
    a.*
    , b.auth_type
    , b.auth_id
    , b.settled_auth_id
    , b.snapshot_timestamp
    , b.req_amt
    , b.final_amt
    , b.entry_type
    , b.merchant_name
    , case when b.merchant_name ilike '%*%' then trim(split(b.merchant_name,'*')[0]) 
      else split(REGEXP_REPLACE(REGEXP_REPLACE(b.merchant_name, '[^A-Za-z]+', ' '),'\s+', ' '),' ')[0]::varchar||' '|| split(REGEXP_REPLACE(REGEXP_REPLACE(b.merchant_name, '[^A-Za-z]+', ' '),'\s+', ' '),' ')[1]::varchar 
        end as merchant_name2 
    , b.mcc_cd
    , b.is_international
    , cast(null as varchar(100)) as allowed_policy_nm
    , cast(null as TIMESTAMP_LTZ(9)) as dispute_created_at
    , cast(null as varchar(100)) as reason
    , cast(null as numeric) as final_loss
    from t1 a
    inner join risk.test.spending_risk_master_driver_table b on (a.user_id=b.user_id 
                                                                    and 
                                                                 b.snapshot_timestamp>=exp_added_timestamp //later data
                                                                )
);

/* update auth driver table with allowed policy name */
merge into rest.test.card_frozen_override_non_power_user a
using (
    select a.user_id, a.auth_id, b.policy_name
        from rest.test.card_frozen_override_non_power_user a
        inner join chime.decision_platform.card_auth_events b on (a.user_id=b.user_id and a.auth_id=b.auth_id and b.policy_name in ('frozen_card_override_namelist_check_v2','frozen_card_override_cp_namelist_check') and b.original_timestamp::date>='2025-05-22')
        inner join (select distinct policy_name, policy_created_at
                    from chime.decision_platform.policies
                    where 1=1
                    and policy_name in ('frozen_card_override_namelist_check_v2','frozen_card_override_cp_namelist_check')
                    and event_name ='card_auth_event') c on (b.policy_name=c.policy_name) 
        qualify row_number() over (partition by a.user_id, a.auth_id order by c.policy_created_at)=1   
) b on (a.user_id=b.user_id and a.auth_id=b.auth_id)
when matched then update set allowed_policy_nm=b.policy_name
; 



/* update auth driver table with dispute ind */
merge into rest.test.card_frozen_override_non_power_user a
using (
    select a.user_id, a.auth_id
    , b.dispute_created_at, b.reason
    , zeroifnull(amount_final_cred)+zeroifnull(amount_final_rev) as final_loss
        from rest.test.card_frozen_override_non_power_user a
        inner join risk.prod.disputed_transactions b on (a.user_id=b.user_id and (b.authorization_code=a.auth_id or b.authorization_code=a.settled_auth_id) and b.transaction_timestamp::date>='2025-05-22')
        left join risk.prod.all_disputable_transactions c on (b.user_id=c.user_id and b.authorization_code=c.authorization_code and c.transaction_timestamp::date>='2025-05-22' and c.dispute_created_at is not null)
        qualify row_number() over (partition by a.user_id, a.auth_id order by b.dispute_created_at)=1
) b on (a.user_id=b.user_id and a.auth_id=b.auth_id)
when matched then update set 
    dispute_created_at=b.dispute_created_at
    , reason=b.reason
    , final_loss=b.final_loss
; 



/* delete latest not complete day's records frmo deny auth table */
delete from rest.test.card_frozen_override_nonpower_user_denied_auth where original_timestamp::date>=(select max(original_timestamp::date) from rest.test.card_frozen_override_nonpower_user_denied_auth);

/* insert latest deny auth data */
insert into rest.test.card_frozen_override_nonpower_user_denied_auth 
with t1 as(
    -- exp dist users
    select 
        unit_id as user_id
        , variant_key
        , _creation_timestamp as exp_added_timestamp
    from  streaming_platform.segment_and_hawker_production.memberexperience_v1_experiment_bucketed_event
    where experiment_key = 'frozen_card_overrides_experiment_nonpower_user'
    and _creation_timestamp::date >= '2025-05-22'
    qualify row_number() over (partition by user_id order by exp_added_timestamp)=1
    
)
    -- pull appv txn
    select 
    a.*
    , b.auth_id
    , b.original_timestamp
    , abs(b.final_amt) as final_amt
    , b.updated_response_cd
    , b.policy_name
    , b.merch_descriptor
    from t1 a
    inner join chime.decision_platform.card_auth_events b on (a.user_id=b.user_id 
                                                                and b.original_timestamp::date>= a.exp_added_timestamp
                                                               -- (select max(original_timestamp::date)+1 from rest.test.trust_member_merchant_experiment_v2_denied_auth)
                                                                and b.updated_response_cd not in ('00','10')
                                                              )
    qualify row_number() over (partition by b.user_id, b.merch_descriptor, b.final_amt, trunc(b.original_timestamp,'hour') order by null)=1

;

end
