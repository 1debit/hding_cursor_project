-- Title: Demographic Comparison Analysis - Active Users vs Scam Victims
-- Intent: Combined analysis comparing demographics between active users and scam victims
-- Inputs: RISK.TEST.active_users_demographics, RISK.TEST.scam_victims_demographics
-- Output: Side-by-side demographic comparisons for visualization
-- Assumptions: Both temp tables exist and have been populated
-- Validation: Verify both populations have reasonable sample sizes

-- Step 1: Combined population summary
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

-- Step 2: Age distribution comparison
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

-- Step 3: State distribution comparison (Top 10 states)
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

-- Step 4: Export data for Python visualization (Age Distribution)
SELECT 
    'EXPORT_AGE_DATA' as data_type,
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
ORDER BY population_type, 
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

-- Step 5: Export data for Python visualization (State Distribution - Top 10)
WITH top_states_both AS (
    SELECT clean_state_code
    FROM (
        SELECT * FROM RISK.TEST.active_users_demographics
        UNION ALL
        SELECT * FROM RISK.TEST.scam_victims_demographics
    )
    GROUP BY clean_state_code
    ORDER BY COUNT(*) DESC
    LIMIT 10
)
SELECT 
    'EXPORT_STATE_DATA' as data_type,
    population_type,
    clean_state_code as state_code,
    COUNT(*) as user_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY population_type) as percentage
FROM (
    SELECT * FROM RISK.TEST.active_users_demographics
    UNION ALL
    SELECT * FROM RISK.TEST.scam_victims_demographics
)
WHERE clean_state_code IN (SELECT clean_state_code FROM top_states_both)
GROUP BY population_type, clean_state_code
ORDER BY population_type, COUNT(*) DESC;
