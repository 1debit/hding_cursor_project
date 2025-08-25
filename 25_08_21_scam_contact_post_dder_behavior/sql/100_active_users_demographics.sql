-- Title: Active Users Demographics Analysis
-- Intent: Extract demographic data (age, state) for all active company users
-- Inputs: chime.finance.members
-- Output: user demographics with calculated age ranges and state distribution
-- Assumptions: date_of_birth is accurate, status='active' indicates current active users
-- Validation: Check for null values, reasonable age ranges, state code validity

-- Step 1: Extract active user demographics with age calculation
CREATE OR REPLACE TEMPORARY TABLE RISK.TEST.active_users_demographics AS (
    SELECT 
        id as user_id,
        date_of_birth,
        state_code,
        CURRENT_DATE() as analysis_date,
        
        -- Calculate age
        DATEDIFF('year', date_of_birth, CURRENT_DATE()) as age,
        
        -- Create age ranges for analysis
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
        
        -- Clean state codes
        UPPER(TRIM(state_code)) as clean_state_code,
        
        'ACTIVE_USER' as population_type
        
    FROM chime.finance.members
    WHERE status = 'active'
    AND date_of_birth IS NOT NULL
    AND state_code IS NOT NULL
    AND state_code != ''
);

-- Step 2: Generate summary statistics
SELECT 
    'ACTIVE_USERS_SUMMARY' as analysis_type,
    COUNT(*) as total_active_users,
    COUNT(DISTINCT clean_state_code) as unique_states,
    MIN(age) as min_age,
    MAX(age) as max_age,
    AVG(age) as avg_age,
    MEDIAN(age) as median_age
FROM RISK.TEST.active_users_demographics;

-- Step 3: Age distribution analysis
SELECT 
    'AGE_DISTRIBUTION' as analysis_type,
    age_range,
    COUNT(*) as user_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM RISK.TEST.active_users_demographics
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

-- Step 4: State distribution analysis (Top 15 states)
SELECT 
    'STATE_DISTRIBUTION' as analysis_type,
    clean_state_code as state_code,
    COUNT(*) as user_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM RISK.TEST.active_users_demographics
GROUP BY clean_state_code
ORDER BY user_count DESC
LIMIT 15;

-- Step 5: Data quality validation
SELECT 
    'DATA_QUALITY' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN age < 0 OR age > 120 THEN 1 END) as invalid_ages,
    COUNT(CASE WHEN LENGTH(clean_state_code) != 2 THEN 1 END) as invalid_state_codes,
    COUNT(CASE WHEN date_of_birth > CURRENT_DATE() THEN 1 END) as future_birthdates
FROM RISK.TEST.active_users_demographics;
