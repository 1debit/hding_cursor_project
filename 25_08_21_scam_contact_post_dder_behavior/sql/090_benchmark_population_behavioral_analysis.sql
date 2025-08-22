-- Title: Benchmark Population Behavioral Analysis (DDer, Funder, Purchaser)
-- Intent: Calculate M0/M1 churn rates for transacted users as benchmark vs scam victims
-- Inputs: edw_db.core.ftr_transaction, edw_db.member.primary_account_members_rolling, edw_db.member.member_transaction_detail_daily
-- Output: Benchmark behavioral analysis for comparison with scam victims
-- Assumptions: M0 = 0-33 days, M1 = 34-67 days after first transaction date (same methodology as scam analysis)
-- Validation: Compare churn rates between benchmark and scam victim populations

CREATE OR REPLACE TABLE RISK.TEST.hding_benchmark_transacted_users_behavioral AS (
    WITH benchmark_population AS (
        -- Step 1: Benchmark population - transacted users during same period as scam analysis
        SELECT 
            user_id, 
            transaction_timestamp::date as date_key
        FROM edw_db.core.ftr_transaction
        WHERE 1=1
            AND transaction_timestamp::date BETWEEN '2024-11-01' AND '2025-04-30'
            AND settled_amt < 0
        QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY transaction_timestamp) = 1
    ),

    -- DDer Analysis
    m0_dder_analysis AS (
        SELECT
            b.user_id,
            CASE WHEN SUM(CASE WHEN e.is_dder_l30d = 'TRUE' THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m0_dder_indicator
        FROM benchmark_population b
        LEFT JOIN edw_db.member.primary_account_members_rolling e
            ON b.user_id = e.user_id
            AND e.date_key >= b.date_key                    -- Start: first transaction date
            AND e.date_key < DATEADD('day', 34, b.date_key) -- End: 34 days later (exclusive)
        GROUP BY b.user_id
    ),

    m1_dder_analysis AS (
        SELECT
            b.user_id,
            CASE WHEN SUM(CASE WHEN e.is_dder_l30d = 'TRUE' THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m1_dder_indicator
        FROM benchmark_population b
        LEFT JOIN edw_db.member.primary_account_members_rolling e
            ON b.user_id = e.user_id
            AND e.date_key >= DATEADD('day', 34, b.date_key) -- Start: 34 days after first transaction
            AND e.date_key < DATEADD('day', 68, b.date_key)  -- End: 68 days later (exclusive)
        GROUP BY b.user_id
    ),

    -- Funder Analysis
    m0_funder_analysis AS (
        SELECT
            b.user_id,
            CASE WHEN SUM(CASE WHEN mtd.total_deposit_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m0_funder_indicator
        FROM benchmark_population b
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON b.user_id = mtd.user_id
            AND mtd.transaction_date >= b.date_key                    -- Start: first transaction date
            AND mtd.transaction_date < DATEADD('day', 34, b.date_key) -- End: 34 days later (exclusive)
        GROUP BY b.user_id
    ),

    m1_funder_analysis AS (
        SELECT
            b.user_id,
            CASE WHEN SUM(CASE WHEN mtd.total_deposit_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m1_funder_indicator
        FROM benchmark_population b
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON b.user_id = mtd.user_id
            AND mtd.transaction_date >= DATEADD('day', 34, b.date_key) -- Start: 34 days after first transaction
            AND mtd.transaction_date < DATEADD('day', 68, b.date_key)  -- End: 68 days later (exclusive)
        GROUP BY b.user_id
    ),

    -- Purchaser Analysis
    m0_purchaser_analysis AS (
        SELECT
            b.user_id,
            CASE WHEN SUM(CASE WHEN mtd.purchase_transaction_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m0_purchaser_indicator
        FROM benchmark_population b
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON b.user_id = mtd.user_id
            AND mtd.transaction_date >= b.date_key                    -- Start: first transaction date
            AND mtd.transaction_date < DATEADD('day', 34, b.date_key) -- End: 34 days later (exclusive)
        GROUP BY b.user_id
    ),

    m1_purchaser_analysis AS (
        SELECT
            b.user_id,
            CASE WHEN SUM(CASE WHEN mtd.purchase_transaction_count > 0 THEN 1 ELSE 0 END) > 0 
                 THEN 'Y' ELSE 'N' END AS m1_purchaser_indicator
        FROM benchmark_population b
        LEFT JOIN edw_db.member.member_transaction_detail_daily mtd
            ON b.user_id = mtd.user_id
            AND mtd.transaction_date >= DATEADD('day', 34, b.date_key) -- Start: 34 days after first transaction
            AND mtd.transaction_date < DATEADD('day', 68, b.date_key)  -- End: 68 days later (exclusive)
        GROUP BY b.user_id
    )

    -- Combine all behavioral indicators
    SELECT 
        b.user_id,
        b.date_key as first_transaction_date,
        
        -- DDer indicators
        COALESCE(m0d.m0_dder_indicator, 'N') as m0_dder_indicator,
        COALESCE(m1d.m1_dder_indicator, 'N') as m1_dder_indicator,
        
        -- Funder indicators
        COALESCE(m0f.m0_funder_indicator, 'N') as m0_funder_indicator,
        COALESCE(m1f.m1_funder_indicator, 'N') as m1_funder_indicator,
        
        -- Purchaser indicators
        COALESCE(m0p.m0_purchaser_indicator, 'N') as m0_purchaser_indicator,
        COALESCE(m1p.m1_purchaser_indicator, 'N') as m1_purchaser_indicator
        
    FROM benchmark_population b
    LEFT JOIN m0_dder_analysis m0d ON b.user_id = m0d.user_id
    LEFT JOIN m1_dder_analysis m1d ON b.user_id = m1d.user_id
    LEFT JOIN m0_funder_analysis m0f ON b.user_id = m0f.user_id
    LEFT JOIN m1_funder_analysis m1f ON b.user_id = m1f.user_id
    LEFT JOIN m0_purchaser_analysis m0p ON b.user_id = m0p.user_id
    LEFT JOIN m1_purchaser_analysis m1p ON b.user_id = m1p.user_id
    ORDER BY b.date_key, b.user_id
);

-- Benchmark behavioral analysis summary
SELECT 
    'BENCHMARK_BEHAVIORAL_SUMMARY' as analysis_type,
    COUNT(*) as total_benchmark_users,
    
    -- DDer Analysis
    COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END) as m0_dders,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_dder_rate_pct,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 1 END) as dder_churned,
    COUNT(CASE WHEN m0_dder_indicator = 'Y' AND m1_dder_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_dder_indicator = 'Y' THEN 1 END), 0) as dder_churn_rate_pct,
    
    -- Funder Analysis
    COUNT(CASE WHEN m0_funder_indicator = 'Y' THEN 1 END) as m0_funders,
    COUNT(CASE WHEN m0_funder_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_funder_rate_pct,
    COUNT(CASE WHEN m0_funder_indicator = 'Y' AND m1_funder_indicator = 'N' THEN 1 END) as funder_churned,
    COUNT(CASE WHEN m0_funder_indicator = 'Y' AND m1_funder_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_funder_indicator = 'Y' THEN 1 END), 0) as funder_churn_rate_pct,
        
    -- Purchaser Analysis
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' THEN 1 END) as m0_purchasers,
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' THEN 1 END) * 100.0 / COUNT(*) as m0_purchaser_rate_pct,
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' AND m1_purchaser_indicator = 'N' THEN 1 END) as purchaser_churned,
    COUNT(CASE WHEN m0_purchaser_indicator = 'Y' AND m1_purchaser_indicator = 'N' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN m0_purchaser_indicator = 'Y' THEN 1 END), 0) as purchaser_churn_rate_pct
        
FROM RISK.TEST.hding_benchmark_transacted_users_behavioral;
