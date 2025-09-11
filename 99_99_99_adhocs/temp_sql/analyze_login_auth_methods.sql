-- Title: Login Authentication Method Analysis
-- Intent: Analyze login authentication methods and success rates by eligibility categories
-- Author: Data Analysis
-- Created: 2025-09-10

select
case when (variant_key='control' or (variant_key='treatment' and num_of_eligible=1)) then '1. password only'
       when num_of_eligible=3 then '3. all 3 options'
       when ml_eligible=1 then '2.1 ml + pwd'
       when otp_eligible=1 then '2.2 otp + pwd'
       else  '99. others' end as cat
, case when last_pw_attempt_outcome is null and final_session_event ilike 'otp%' then '1.otp'
       when last_pw_attempt_outcome is null and final_session_event ilike 'magic%' then '2.magiclink'
       when last_pw_attempt_outcome is null and final_session_event='username_auth_initiated' then '4.abandoned'
       when last_pw_attempt_outcome is not null then '3.pw'
       else '99.others' end as cat

--, last_pw_attempt_outcome
--, final_session_event
--, atom_decision_result
, count(*) as cnt_
, count(*)/sum(cnt_) over () as perc_of_total
, sum(case when reconciled_outcome='login_successful' then 1 else 0 end) as cnt_success_login
, sum(case when reconciled_outcome='login_successful' then 1 else 0 end)/cnt_ as login_success_rate_attempt
    from risk.test.hding_personal_login_eligibility_driver
    where 1=1
    and variant_key='treatment'
    group by all
    order by 1 desc,2,3
;

