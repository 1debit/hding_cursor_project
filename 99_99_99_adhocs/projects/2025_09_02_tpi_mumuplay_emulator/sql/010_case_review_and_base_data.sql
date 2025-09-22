/*
all login request(a3id) with outcome
*/

create or replace  table risk.test.hding_a3id_login_with_outcome as(
    select
    account_access_attempt_id, reconciled_outcome, decision_id, user_id
    from chime.decision_platform.authn
    where 1=1
    and is_shadow_mode=false
    and original_timestamp::date between '2025-07-01' and '2025-07-31'
    and reconciled_outcome='login_successful'
    qualify row_number() over (partition by account_access_attempt_id order by original_timestamp desc)=1
);


/*
all login request with network and ip carrer info
*/

create or replace  table risk.test.hding_a3id_login_info as(

    SELECT
    _CREATION_TIMESTAMP
    , request:atom_event:platform::varchar as platform
    , request:atom_event:network_carrier::varchar as network_carrier
    , request:atom_event:nu_risk_response:ip_carrier::varchar as ip_carrier
    , request:atom_event:nu_risk_response:ip_connection_type::varchar as ip_connection_type
    , request:atom_event:nu_risk_response:ip_country::varchar as ip_country

    , externally_loaded:computed:atom_v3_score:float_value::float as atom_v3
    , request:atom_event:session_event::varchar as session_event
    , request:atom_event:account_access_attempt_id::varchar as a3id
    , event_name
    , decision_log.decision_id
    , decision_log.user_id
    , device_id
        FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG decision_log
        inner join risk.test.hding_a3id_login_with_outcome b on (decision_log.user_id=b.user_id and decision_log.decision_id=b.decision_id)
        WHERE 1=1
        and decision_log._creation_timestamp::date between '2025-07-01' and '2025-07-31'
        AND decision_log.event_name = 'atom_event'
        AND decision_log.labels:service_names != 'shadow'
        --and decision_log.request:atom_event:account_access_attempt_id::varchar='759089da-5481-4ad5-b862-ee3f56687598'
        --AND decision_log.request:atom_event:session_event = 'SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED'
        qualify row_number() over (partition by a3id order by _creation_timestamp)=1
);




-- distribution by login date

select a._creation_timestamp::date
, count(distinct a3id) as cnt_login
, count(distinct case when a.country_code<>'USA' and country_name<>'Unknown' and mapping_status='Mapped' and ip_country='USA' then a3id end) as cnt_mismatch_carrier_ip_country
, cnt_mismatch_carrier_ip_country/cnt_login as rate_mismatch_carrier_ip_country
    from RISK.TEST.hding_a3id_login_info_enriched a
    inner join risk.test.hding_a3id_login_with_outcome b on (a.a3id=b.account_access_attempt_id)
    where 1=1
    group by all
    order by 1
    --and network_carrier ilike 'fare%'
    ;



-- top foreigne net carrier with USD ip country
select
country_code, ip_country, count(*) as cnt_login, count(distinct a.user_id) as cnt_user
from RISK.TEST.hding_a3id_login_info_enriched a
inner join risk.test.hding_a3id_login_with_outcome b on (a.a3id=b.account_access_attempt_id)
where 1=1
and country_code<>'USA' and mapping_status='Mapped' and ip_country='USA' and country_name<>'Unknown'
and reconciled_outcome='login_successful'
group by all
order by 3 desc;



-- break TWN network carrier by carrier name:86963958

select
--network_carrier
width_bucket(datediff(month, c.created_at, a._creation_timestamp), 0,24,24) as bucket
, min(datediff(month, c.created_at, a._creation_timestamp)) as min_val, max(datediff(month, c.created_at, a._creation_timestamp)) as max_val
, count(*) as cnt_login, count(distinct a.user_id) as cnt_user
from RISK.TEST.hding_a3id_login_info_enriched a
inner join risk.test.hding_a3id_login_with_outcome b on (a.a3id=b.account_access_attempt_id)
left join chime.finance.members c on (a.user_id=c.id::varchar)
where 1=1
and country_code<>'USA' and mapping_status='Mapped' and ip_country='USA' and country_name<>'Unknown'
and reconciled_outcome='login_successful' and country_code='TWN'
group by all
order by 1;




-- confirmed emulator logins for this user: 86963958
  SELECT
    _CREATION_TIMESTAMP
    , request:atom_event:platform::varchar as platform
    , externally_loaded:computed:atom_v3_score:float_value::float as atom_v3
    , externally_loaded:prediction_store:data_prediction_store_atom_v3_prediction_score_device_id_input_event_device_id_user_id_input_event_user_id:float_value::float as atom_v3_stored
    , request:atom_event:session_event::varchar as session_event
    , request:atom_event:account_access_attempt_id::varchar as a3id
    , event_name
    , decision_id
    , user_id
    , request
    , externally_loaded
    , device_id
        FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.REALTIMEDECISIONING_V1_RISK_DECISION_LOG decision_log
        WHERE decision_log._creation_timestamp::date = '2025-07-17'
        --and decision_id='d4c0318b-d873-5d9d-9170-00f51cb5d1d1'
        and user_id='86963958'
        AND decision_log.event_name = 'atom_event'
        AND decision_log.labels:service_names != 'shadow'
        --and decision_log.request:atom_event:account_access_attempt_id::varchar='759089da-5481-4ad5-b862-ee3f56687598'
        --AND decision_log.request:atom_event:session_event = 'SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED'
        order by _creation_timestamp
;
