/*

context:
https://chime.slack.com/archives/C07V9H6G27P/p1754403095894859

*/
-- confirmed James bad sessions: logib + session hijacked p2p session

SELECT 
t._DEVICE_ID,
t._USER_ID,
t._CREATION_TIMESTAMP,
TRY_PARSE_JSON(t.body) AS body_json,
body_json:step_name::varchar as step_name,
body_json:identifier::varchar as identifier
FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE t
WHERE 1=1
--and body_json:step_name::varchar='login'
--and body_json:profiling.tcp_connection['HTTPS_PROFILING'].ja4='t13d190900_9dc949149365_97f8aa674fd9'
and name='VENDOR_DARWINIUM'
and _creation_timestamp::date between '2025-08-04' and '2025-08-05'
--and body_json:identity['ACCOUNT'].customer_token.customer_token= 'bah7bkkic19yywlscwy6bkvuewdjiglkyxrhbjsavekif2phbwllnta4qgdtywlslmnvbqy7afrjighwdxigowbussiszgfyd2luaxvtx2fwaqy7aey=&#x2d;&#x2d;df93b6bdbc79b1761e5e0448e5648fed06d0858a'
and body_json:device_signature['VER_1'].identifier= '540b37dbcb41451f8f1710192f0e275c'
order by _creation_timestamp
;


    /*
     > james's user id 82075425
    */








