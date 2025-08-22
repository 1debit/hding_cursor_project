-- Title: Scam Victims with Complete Behavioral Indicators (DDer, Funder, Purchaser)
-- Intent: Add M0/M1 funding and purchase indicators to existing DDer analysis
-- Inputs: RISK.TEST.hding_scam_contact_confirmed_victims_with_dder, edw_db.member.member_transaction_detail_daily
-- Output: Complete behavioral analysis table with all M0/M1 indicators
-- Assumptions: M0 = 0-33 days, M1 = 34-67 days after earliest scam contact (aligned with DDer periods)
-- Validation: Funder/Purchase rates and churn analysis

CREATE OR REPLACE TABLE RISK.TEST.hding_scam_contact_confirmed_victims_with_dder AS (
    WITH scam_victims_base AS (
        -- Step 1: Base scam victims from existing DDer table
        SELECT 
            user_id,
            earliest_scam_contact_date as date_key,
            earliest_contact_channel,
            confirmed_scam_contacts,
            m0_dder_indicator,
            m1_dder_indicator
        FROM RISK.TEST.hding_scam_contact_confirmed_victims_with_dder
    ),

    m0_funder_analysis AS (
        -- Step 2: M0 Funder indicator (days 0-33 after scam contact)
        SELECT
            s.user_id,
            CASE WHEN SUM(CASE WHEN mtd.total_deposit_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m0_funder_indicator
        FROM scam_victims_base s
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON s.user_id = mtd.user_id
            AND mtd.transaction_date >= s.date_key                    -- Start: scam contact date
            AND mtd.transaction_date < DATEADD('day', 34, s.date_key) -- End: 34 days later (exclusive)
        GROUP BY s.user_id
    ),

    m1_funder_analysis AS (
        -- Step 3: M1 Funder indicator (days 34-67 after scam contact)
        SELECT
            s.user_id,
            CASE WHEN SUM(CASE WHEN mtd.total_deposit_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m1_funder_indicator
        FROM scam_victims_base s
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON s.user_id = mtd.user_id
            AND mtd.transaction_date >= DATEADD('day', 34, s.date_key) -- Start: 34 days after scam contact
            AND mtd.transaction_date < DATEADD('day', 68, s.date_key)  -- End: 68 days later (exclusive)
        GROUP BY s.user_id
    ),

    m0_purchaser_analysis AS (
        -- Step 4: M0 Purchaser indicator (days 0-33 after scam contact)
        SELECT
            s.user_id,
            CASE WHEN SUM(CASE WHEN mtd.purchase_transaction_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m0_purchaser_indicator
        FROM scam_victims_base s
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON s.user_id = mtd.user_id
            AND mtd.transaction_date >= s.date_key                    -- Start: scam contact date
            AND mtd.transaction_date < DATEADD('day', 34, s.date_key) -- End: 34 days later (exclusive)
        GROUP BY s.user_id
    ),

    m1_purchaser_analysis AS (
        -- Step 5: M1 Purchaser indicator (days 34-67 after scam contact)
        SELECT
            s.user_id,
            CASE WHEN SUM(CASE WHEN mtd.purchase_transaction_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m1_purchaser_indicator
        FROM scam_victims_base s
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON s.user_id = mtd.user_id
            AND mtd.transaction_date >= DATEADD('day', 34, s.date_key) -- Start: 34 days after scam contact
            AND mtd.transaction_date < DATEADD('day', 68, s.date_key)  -- End: 68 days later (exclusive)
        GROUP BY s.user_id
    )

    -- Step 6: Combine all behavioral indicators
    SELECT 
        s.user_id,
        s.date_key as earliest_scam_contact_date,
        s.earliest_contact_channel,
        s.confirmed_scam_contacts,
        
        -- DDer indicators (existing)
        s.m0_dder_indicator,
        s.m1_dder_indicator,
        
        -- Funder indicators (new)
        COALESCE(m0f.m0_funder_indicator, 'N') as m0_funder_indicator,
        COALESCE(m1f.m1_funder_indicator, 'N') as m1_funder_indicator,
        
        -- Purchaser indicators (new)
        COALESCE(m0p.m0_purchaser_indicator, 'N') as m0_purchaser_indicator,
        COALESCE(m1p.m1_purchaser_indicator, 'N') as m1_purchaser_indicator
        
    FROM scam_victims_base s
    LEFT JOIN m0_funder_analysis m0f ON s.user_id = m0f.user_id
    LEFT JOIN m1_funder_analysis m1f ON s.user_id = m1f.user_id
    LEFT JOIN m0_purchaser_analysis m0p ON s.user_id = m0p.user_id
    LEFT JOIN m1_purchaser_analysis m1p ON s.user_id = m1p.user_id
    ORDER BY s.date_key, s.user_id
);

-- Validation: Complete behavioral analysis summary
SELECT 
    'COMPLETE_BEHAVIORAL_SUMMARY' as analysis_type,
    COUNT(*) as total_scam_victims,
    
    -- DDer Analysis (existing)
    COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END) as m0_dders,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_dder_rate_pct,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 1 END) as dder_churned,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END), 0) as dder_churn_rate_pct,
    
    -- Funder Analysis (new)
    COUNT(CASE WHEN m0_funder_indicator = 'Y' THEN 1 END) as m0_funders,
    COUNT(CASE WHEN m0_funder_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_funder_rate_pct,
    COUNT(CASE WHEN m0_funder_indicator = 'Y' AND m1_funder_indicator = 'N' THEN 1 END) as funder_churned,
    COUNT(CASE WHEN m0_funder_indicator = 'Y' AND m1_funder_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_funder_indicator = 'Y' THEN 1 END), 0) as funder_churn_rate_pct,
        
    -- Purchaser Analysis (new)
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' THEN 1 END) as m0_purchasers,
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_purchaser_rate_pct,
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' AND m1_purchaser_indicator = 'N' THEN 1 END) as purchaser_churned,
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' AND m1_purchaser_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_purchaser_indicator = 'Y' THEN 1 END), 0) as purchaser_churn_rate_pct
        
FROM RISK.TEST.hding_scam_contact_confirmed_victims_with_dder;

-- Sample data showing all behavioral indicators
SELECT 
    'SAMPLE_COMPLETE_DATA' as check_type,
    user_id,
    earliest_scam_contact_date,
    m0_dder_indicator,
    m1_dder_indicator,
    m0_funder_indicator,
    m1_funder_indicator,
    m0_purchaser_indicator,
    m1_purchaser_indicator,
    
    -- Behavioral transition summary
    CASE 
        WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 'DDER_CHURNED'
        WHEN m0_funder_indicator = 'Y' AND m1_funder_indicator = 'N' THEN 'FUNDER_CHURNED'
        WHEN m0_purchaser_indicator = 'Y' AND m1_purchaser_indicator = 'N' THEN 'PURCHASER_CHURNED'
        ELSE 'RETAINED_OR_INACTIVE'
    END as primary_behavioral_change
    
FROM RISK.TEST.hding_scam_contact_confirmed_victims_with_dder
ORDER BY earliest_scam_contact_date DESC
LIMIT 10;
