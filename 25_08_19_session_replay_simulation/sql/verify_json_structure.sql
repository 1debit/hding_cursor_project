/*
    验证DWN数据JSON结构 - Session Replay字段探索
    
    目的: 验证profiling.replay_count和profiling.secure_id.signals的确切路径和数据格式
*/

-- 简化版查询 - 验证JSON结构
SELECT 
    t._DEVICE_ID,
    t._USER_ID,
    t._CREATION_TIMESTAMP,
    TRY_PARSE_JSON(t.body) AS body_json,
    body_json:step_name::varchar as step_name,
    body_json:identifier::varchar as identifier,
    
    -- 探索profiling相关字段的结构
    body_json:profiling as profiling_full,
    
    -- 尝试不同的replay_count路径
    body_json:profiling:replay_count as replay_count_v1,
    body_json:profiling.replay_count as replay_count_v2,
    body_json:profiling['replay_count'] as replay_count_v3,
    
    -- 尝试不同的secure_id.signals路径
    body_json:profiling:secure_id as secure_id_full,
    body_json:profiling:secure_id:signals as signals_v1,
    body_json:profiling:secure_id.signals as signals_v2,
    body_json:profiling['secure_id']['signals'] as signals_v3,
    
    -- 检查signals是否包含INVALID_NONCE (不同格式尝试)
    CASE 
        WHEN body_json:profiling:secure_id:signals::varchar LIKE '%INVALID_NONCE%' THEN 'FOUND_v1'
        WHEN body_json:profiling:secure_id.signals::varchar LIKE '%INVALID_NONCE%' THEN 'FOUND_v2'
        WHEN body_json:profiling['secure_id']['signals']::varchar LIKE '%INVALID_NONCE%' THEN 'FOUND_v3'
        ELSE 'NOT_FOUND'
    END as invalid_nonce_check
    
FROM STREAMING_PLATFORM.SEGMENT_AND_HAWKER_PRODUCTION.DEVICE_EVENTS_V1_VENDOR_RESPONSE t
WHERE 1=1
    and name='VENDOR_DARWINIUM'
    and _creation_timestamp::date between '2025-08-04' and '2025-08-05'
    and body_json:device_signature['VER_1'].identifier= '540b37dbcb41451f8f1710192f0e275c'
order by _creation_timestamp
LIMIT 10;  -- 限制返回行数用于结构验证
