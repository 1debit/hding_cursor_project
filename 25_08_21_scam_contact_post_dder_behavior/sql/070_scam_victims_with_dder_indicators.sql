-- Title: Scam Victims with M0/M1 DDer Indicators
-- Intent: Add DDer behavior analysis to confirmed scam victims
-- Inputs: RISK.TEST.hding_scam_contact_confirmed_victims, edw_db.member.primary_account_members_rolling
-- Output: Enhanced table with M0/M1 DDer indicators (Y/N)
-- Assumptions: M0 = 0-33 days, M1 = 34-67 days after earliest scam contact
-- Validation: Check DDer retention rates across periods

CREATE OR REPLACE TABLE RISK.TEST.hding_scam_contact_confirmed_victims_with_dder AS (
    WITH scam_victims_base AS (
        -- Step 1: Base scam victims with standardized date_key
        SELECT 
            user_id,
            earliest_scam_contact_date as date_key,
            earliest_contact_channel,
            confirmed_scam_contacts
        FROM RISK.TEST.hding_scam_contact_confirmed_victims
    ),

    m0_dder_retention AS (
        -- Step 2: M0 DDer indicator (days 0-33 after scam contact)
        SELECT
            s.user_id,
            MAX(CASE WHEN e.is_dder_l30d = 'TRUE' THEN 'Y' ELSE 'N' END) AS m0_dder_indicator
        FROM scam_victims_base AS s
        INNER JOIN edw_db.member.primary_account_members_rolling AS e
            ON s.user_id = e.user_id
            AND e.date_key >= s.date_key                    -- Start: scam contact date
            AND e.date_key < DATEADD('day', 34, s.date_key) -- End: 34 days later (exclusive)
        GROUP BY s.user_id
    ),

    m1_dder_retention AS (
        -- Step 3: M1 DDer indicator (days 34-67 after scam contact)
        SELECT
            s.user_id,
            MAX(CASE WHEN e.is_dder_l30d = 'TRUE' THEN 'Y' ELSE 'N' END) AS m1_dder_indicator
        FROM scam_victims_base AS s
        INNER JOIN edw_db.member.primary_account_members_rolling AS e
            ON s.user_id = e.user_id
            AND e.date_key >= DATEADD('day', 34, s.date_key) -- Start: 34 days after scam contact
            AND e.date_key < DATEADD('day', 68, s.date_key)  -- End: 68 days later (exclusive)
        GROUP BY s.user_id
    )

    -- Step 4: Combine all data with DDer indicators
    SELECT 
        s.user_id,
        s.date_key as earliest_scam_contact_date,
        s.earliest_contact_channel,
        s.confirmed_scam_contacts,
        COALESCE(m0.m0_dder_indicator, 'N') as m0_dder_indicator,
        COALESCE(m1.m1_dder_indicator, 'N') as m1_dder_indicator
    FROM scam_victims_base s
    LEFT JOIN m0_dder_retention m0 ON s.user_id = m0.user_id
    LEFT JOIN m1_dder_retention m1 ON s.user_id = m1.user_id
    ORDER BY s.date_key, s.user_id
);

-- Validation: DDer retention analysis
SELECT 
    'DDER_RETENTION_SUMMARY' as analysis_type,
    COUNT(*) as total_scam_victims,
    
    -- M0 DDer Analysis
    COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END) as m0_dders,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_dder_rate_pct,
    
    -- M1 DDer Analysis  
    COUNT(CASE WHEN m1_dder_indicator = 'Y' THEN 1 END) as m1_dders,
    COUNT(CASE WHEN m1_dder_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m1_dder_rate_pct,
    
    -- Churn Analysis (M0 DDer who becomes non-DDer in M1)
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 1 END) as m0_to_m1_churned,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END), 0) as churn_rate_pct,
        
    -- Retention Analysis (M0 DDer who remains DDer in M1)
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'Y' THEN 1 END) as m0_to_m1_retained,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'Y' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END), 0) as retention_rate_pct
        
FROM RISK.TEST.hding_scam_contact_confirmed_victims_with_dder;

-- Sample data for validation
SELECT 
    'SAMPLE_DATA' as check_type,
    user_id,
    earliest_scam_contact_date,
    earliest_contact_channel,
    m0_dder_indicator,
    m1_dder_indicator,
    CASE 
        WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 'CHURNED'
        WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'Y' THEN 'RETAINED' 
        WHEN m0_dder_indicator = 'N' AND m1_dder_indicator = 'Y' THEN 'NEW_DDER'
        WHEN m0_dder_indicator = 'N' AND m1_dder_indicator = 'N' THEN 'NON_DDER'
    END as dder_transition
FROM RISK.TEST.hding_scam_contact_confirmed_victims_with_dder
ORDER BY earliest_scam_contact_date DESC
LIMIT 10;
