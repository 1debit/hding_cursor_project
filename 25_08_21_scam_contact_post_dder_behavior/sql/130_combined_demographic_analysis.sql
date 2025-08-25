-- Title: Combined Demographic Analysis - Active Users vs Scam Victims  
-- Intent: Complete demographic comparison in single session to avoid temp table expiration
-- Inputs: chime.finance.members, risk.test.hding_p2p_scam_victim_dispute_denied
-- Output: Side-by-side demographic comparisons for visualization
-- Assumptions: All source tables exist and have valid data
-- Validation: Check population sizes and data quality

-- Step 1: Create active users demographics
CREATE OR REPLACE TEMPORARY TABLE RISK.TEST.active_users_demographics AS (
    SELECT 
        id as user_id,
        date_of_birth,
        state_code,
        CURRENT_DATE() as analysis_date,
        DATEDIFF('year', date_of_birth, CURRENT_DATE()) as age,
        CASE 
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) < 18 THEN 'Under 18'
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 18 AND 24 THEN '18-24'
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 25 AND 34 THEN '25-34'
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 35 AND 44 THEN '35-44'
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 45 AND 54 THEN '45-54'
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 55 AND 64 THEN '55-64'
            WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) >= 65 THEN '65+'
            ELSE 'Unknown'
        END as age_range,
        UPPER(TRIM(state_code)) as clean_state_code,
        'ACTIVE_USER' as population_type
    FROM chime.finance.members
    WHERE status = 'active'
    AND date_of_birth IS NOT NULL
    AND state_code IS NOT NULL
    AND state_code != ''
);

-- Step 2: Create scam victims demographics
CREATE OR REPLACE TEMPORARY TABLE RISK.TEST.scam_victims_demographics AS (
    SELECT 
        a.user_id,
        b.date_of_birth,
        b.state_code,
        CURRENT_DATE() as analysis_date,
        DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) as age,
        CASE 
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) < 18 THEN 'Under 18'
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) BETWEEN 18 AND 24 THEN '18-24'
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) BETWEEN 25 AND 34 THEN '25-34'
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) BETWEEN 35 AND 44 THEN '35-44'
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) BETWEEN 45 AND 54 THEN '45-54'
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) BETWEEN 55 AND 64 THEN '55-64'
            WHEN DATEDIFF('year', b.date_of_birth, CURRENT_DATE()) >= 65 THEN '65+'
            ELSE 'Unknown'
        END as age_range,
        UPPER(TRIM(b.state_code)) as clean_state_code,
        'SCAM_VICTIM' as population_type
    FROM (
        SELECT DISTINCT user_id 
        FROM risk.test.hding_p2p_scam_victim_dispute_denied 
        WHERE dispute_type = 'p2p'
    ) a
    LEFT JOIN chime.finance.members b 
        ON a.user_id::varchar = b.id::varchar
    WHERE b.date_of_birth IS NOT NULL
    AND b.state_code IS NOT NULL
    AND b.state_code != ''
);

-- Step 3: Population summary comparison
SELECT 
    'POPULATION_SUMMARY' as analysis_type,
    population_type,
    COUNT(*) as total_users,
    AVG(age) as avg_age,
    COUNT(DISTINCT clean_state_code) as unique_states
FROM (
    SELECT * FROM RISK.TEST.active_users_demographics
    UNION ALL
    SELECT * FROM RISK.TEST.scam_victims_demographics
)
GROUP BY population_type
ORDER BY population_type;

-- Step 4: Age distribution comparison
WITH age_comparison AS (
    SELECT 
        population_type,
        age_range,
        COUNT(*) as user_count,
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY population_type) as percentage
    FROM (
        SELECT * FROM RISK.TEST.active_users_demographics
        UNION ALL
        SELECT * FROM RISK.TEST.scam_victims_demographics
    )
    GROUP BY population_type, age_range
)
SELECT 
    'AGE_COMPARISON' as analysis_type,
    age_range,
    MAX(CASE WHEN population_type = 'ACTIVE_USER' THEN user_count END) as active_user_count,
    MAX(CASE WHEN population_type = 'ACTIVE_USER' THEN percentage END) as active_user_pct,
    MAX(CASE WHEN population_type = 'SCAM_VICTIM' THEN user_count END) as scam_victim_count,
    MAX(CASE WHEN population_type = 'SCAM_VICTIM' THEN percentage END) as scam_victim_pct,
    (MAX(CASE WHEN population_type = 'SCAM_VICTIM' THEN percentage END) - 
     MAX(CASE WHEN population_type = 'ACTIVE_USER' THEN percentage END)) as percentage_diff
FROM age_comparison
GROUP BY age_range
ORDER BY 
    CASE age_range
        WHEN 'Under 18' THEN 1
        WHEN '18-24' THEN 2
        WHEN '25-34' THEN 3
        WHEN '35-44' THEN 4
        WHEN '45-54' THEN 5
        WHEN '55-64' THEN 6
        WHEN '65+' THEN 7
        WHEN 'Unknown' THEN 8
    END;

-- Step 5: State distribution comparison (Top 10 states by active users)
WITH state_comparison AS (
    SELECT 
        population_type,
        clean_state_code,
        COUNT(*) as user_count,
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY population_type) as percentage
    FROM (
        SELECT * FROM RISK.TEST.active_users_demographics
        UNION ALL
        SELECT * FROM RISK.TEST.scam_victims_demographics
    )
    GROUP BY population_type, clean_state_code
),
top_states AS (
    SELECT clean_state_code
    FROM state_comparison
    WHERE population_type = 'ACTIVE_USER'
    ORDER BY user_count DESC
    LIMIT 10
)
SELECT 
    'STATE_COMPARISON' as analysis_type,
    sc.clean_state_code as state_code,
    MAX(CASE WHEN sc.population_type = 'ACTIVE_USER' THEN sc.user_count END) as active_user_count,
    MAX(CASE WHEN sc.population_type = 'ACTIVE_USER' THEN sc.percentage END) as active_user_pct,
    MAX(CASE WHEN sc.population_type = 'SCAM_VICTIM' THEN sc.user_count END) as scam_victim_count,
    MAX(CASE WHEN sc.population_type = 'SCAM_VICTIM' THEN sc.percentage END) as scam_victim_pct,
    (MAX(CASE WHEN sc.population_type = 'SCAM_VICTIM' THEN sc.percentage END) - 
     MAX(CASE WHEN sc.population_type = 'ACTIVE_USER' THEN sc.percentage END)) as percentage_diff
FROM state_comparison sc
INNER JOIN top_states ts ON sc.clean_state_code = ts.clean_state_code
GROUP BY sc.clean_state_code
ORDER BY MAX(CASE WHEN sc.population_type = 'ACTIVE_USER' THEN sc.user_count END) DESC;
