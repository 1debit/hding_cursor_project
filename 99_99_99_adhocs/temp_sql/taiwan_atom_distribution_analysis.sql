-- Title: Taiwan Network Carrier Login ATOM Score Distribution Analysis
-- Intent: Analyze ATOM v3 score distribution patterns for Taiwan network carrier users
-- Inputs: RISK.TEST.hding_a3id_login_info with Taiwan network carriers
-- Output: ATOM score distribution statistics and percentiles

-- ATOM Score Distribution for Taiwan Network Carriers
WITH taiwan_logins AS (
    SELECT 
        a.user_id,
        a.network_carrier,
        a.atom_v3,
        a.platform,
        a.session_event,
        a._creation_timestamp as login_timestamp,
        -- Network carrier country mapping
        CASE 
            WHEN a.network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'Taiwan Star') THEN 'TWN'
            WHEN a.network_carrier LIKE '%Taiwan%' THEN 'TWN'
            WHEN a.network_carrier LIKE '%FET%' THEN 'TWN'
            ELSE 'OTHER'
        END as carrier_country
    FROM RISK.TEST.hding_a3id_login_info a
    WHERE a.network_carrier IS NOT NULL
      AND a.atom_v3 IS NOT NULL
      AND (a.network_carrier IN ('FarEasTone', 'Chunghwa Telecom', 'Taiwan Mobile', 'Taiwan Star')
           OR a.network_carrier LIKE '%Taiwan%'
           OR a.network_carrier LIKE '%FET%')
),

atom_distribution AS (
    SELECT
        network_carrier,
        COUNT(*) as total_logins,
        -- Basic statistics
        AVG(atom_v3) as avg_atom_score,
        MEDIAN(atom_v3) as median_atom_score,
        MIN(atom_v3) as min_atom_score,
        MAX(atom_v3) as max_atom_score,
        STDDEV(atom_v3) as stddev_atom_score,
        
        -- Percentiles
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY atom_v3) as p25_atom_score,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY atom_v3) as p75_atom_score,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY atom_v3) as p90_atom_score,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY atom_v3) as p95_atom_score,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY atom_v3) as p99_atom_score,
        
        -- Risk score buckets
        SUM(CASE WHEN atom_v3 <= 0.1 THEN 1 ELSE 0 END) as very_low_risk_count,
        SUM(CASE WHEN atom_v3 > 0.1 AND atom_v3 <= 0.3 THEN 1 ELSE 0 END) as low_risk_count,
        SUM(CASE WHEN atom_v3 > 0.3 AND atom_v3 <= 0.5 THEN 1 ELSE 0 END) as medium_risk_count,
        SUM(CASE WHEN atom_v3 > 0.5 AND atom_v3 <= 0.7 THEN 1 ELSE 0 END) as high_risk_count,
        SUM(CASE WHEN atom_v3 > 0.7 THEN 1 ELSE 0 END) as very_high_risk_count,
        
        -- Platform breakdown
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT CASE WHEN platform = 'ios' THEN user_id END) as ios_users,
        COUNT(DISTINCT CASE WHEN platform = 'android' THEN user_id END) as android_users
        
    FROM taiwan_logins
    WHERE carrier_country = 'TWN'
    GROUP BY network_carrier
),

overall_stats AS (
    SELECT
        'OVERALL_TAIWAN' as network_carrier,
        COUNT(*) as total_logins,
        AVG(atom_v3) as avg_atom_score,
        MEDIAN(atom_v3) as median_atom_score,
        MIN(atom_v3) as min_atom_score,
        MAX(atom_v3) as max_atom_score,
        STDDEV(atom_v3) as stddev_atom_score,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY atom_v3) as p25_atom_score,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY atom_v3) as p75_atom_score,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY atom_v3) as p90_atom_score,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY atom_v3) as p95_atom_score,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY atom_v3) as p99_atom_score,
        SUM(CASE WHEN atom_v3 <= 0.1 THEN 1 ELSE 0 END) as very_low_risk_count,
        SUM(CASE WHEN atom_v3 > 0.1 AND atom_v3 <= 0.3 THEN 1 ELSE 0 END) as low_risk_count,
        SUM(CASE WHEN atom_v3 > 0.3 AND atom_v3 <= 0.5 THEN 1 ELSE 0 END) as medium_risk_count,
        SUM(CASE WHEN atom_v3 > 0.5 AND atom_v3 <= 0.7 THEN 1 ELSE 0 END) as high_risk_count,
        SUM(CASE WHEN atom_v3 > 0.7 THEN 1 ELSE 0 END) as very_high_risk_count,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(DISTINCT CASE WHEN platform = 'ios' THEN user_id END) as ios_users,
        COUNT(DISTINCT CASE WHEN platform = 'android' THEN user_id END) as android_users
    FROM taiwan_logins
    WHERE carrier_country = 'TWN'
)

-- Combine carrier-specific and overall statistics
SELECT * FROM atom_distribution
UNION ALL
SELECT * FROM overall_stats
ORDER BY 
    CASE WHEN network_carrier = 'OVERALL_TAIWAN' THEN 1 ELSE 2 END,
    total_logins DESC;
