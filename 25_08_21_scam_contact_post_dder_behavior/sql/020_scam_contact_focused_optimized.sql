-- Title: Focused & Optimized Scam Contact Analysis (2025-01 to 2025-03)
-- Intent: Identify users who reported being scammed during focused period with optimized AI processing
-- Inputs: analytics.looker.zendesk_tickets_base, analytics.looker.zendesk_tickets_comments_raw
-- Output: RISK.TEST.hding_scam_contact_confirmed_victims table (user_id, earliest_scam_contact_date, earliest_contact_channel, confirmed_scam_contacts)
-- Assumptions: Zendesk tickets capture phone transcripts and chat conversations during Q1 2025
-- Validation: Reduced dataset size, optimized AI processing, robust execution for long-running queries

-- ======================================================================================
-- FOCUSED PERIOD: 2025-01-01 to 2025-03-31 (Q1 2025)
-- OPTIMIZATION: Combined contacts per user to minimize AI calls
-- ROBUSTNESS: Server-side execution, no client dependency
-- ======================================================================================

-- Enable query timeout and ensure robust execution
SET QUERY_TIMEOUT = 3600;  -- 1 hour timeout
SET STATEMENT_TIMEOUT_IN_SECONDS = 3600;

CREATE OR REPLACE TABLE RISK.TEST.hding_scam_contact_confirmed_victims AS (
    WITH scam_contact_raw AS (
        SELECT DISTINCT 
            zendesk_ticket.member_id as user_id,
            zendesk_ticket.created_at::date as contact_date,
            zendesk_ticket.id as ticket_id,
            zendesk_ticket_text.body as raw_text,
            zendesk_ticket.subject as ticket_subject,
            -- Add metadata for analysis
            LENGTH(zendesk_ticket_text.body) as text_length,
            CASE 
                WHEN (zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') THEN 'PHONE_TRANSCRIPT'
                WHEN zendesk_ticket.subject = 'Start Live Chat' THEN 'CHAT_CONVERSATION'
                ELSE 'OTHER_CONTACT'
            END as contact_type
        FROM analytics.looker.zendesk_tickets_base AS zendesk_ticket 
        LEFT JOIN analytics.looker.zendesk_tickets_comments_raw zendesk_ticket_text 
            ON zendesk_ticket.id::varchar = zendesk_ticket_text.ticket_id::varchar
        WHERE 1=1
            -- FOCUSED PERIOD: Q1 2025 only
            AND zendesk_ticket.created_at::date BETWEEN '2025-01-01' AND '2025-03-31'
            AND zendesk_ticket_text.body ILIKE ANY ('%scam%')  -- Scam keyword filter
            -- Only include structured contact data (phone transcripts OR chat conversations)
            AND ((zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') 
                 OR (zendesk_ticket.subject = 'Start Live Chat'))
            AND zendesk_ticket.member_id IS NOT NULL
            AND zendesk_ticket.member_id::varchar != ''
            AND LENGTH(zendesk_ticket_text.body) > 100  -- Pre-filter very short texts for efficiency
    ),
    
    -- Get earliest contact channel per user first
    earliest_contact_channels AS (
        SELECT 
            user_id,
            contact_type as earliest_contact_channel
        FROM scam_contact_raw
        QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY contact_date, ticket_id) = 1
    ),
    
    -- OPTIMIZATION: Combine all contacts per user before AI processing
    user_combined_contacts AS (
        SELECT 
            scr.user_id,
            MIN(scr.contact_date) as earliest_contact_date,
            COUNT(DISTINCT scr.ticket_id) as total_scam_tickets,
            ecc.earliest_contact_channel,
            -- Combine all contact texts (limit to prevent oversized prompts)
            LISTAGG(
                CASE 
                    WHEN LENGTH(scr.raw_text) > 800 THEN LEFT(scr.raw_text, 800) || '...[TRUNCATED]' 
                    ELSE scr.raw_text 
                END, 
                '\n--- NEXT CONTACT ---\n'
            ) WITHIN GROUP (ORDER BY scr.contact_date, scr.ticket_id) as combined_contact_text
        FROM scam_contact_raw scr
        LEFT JOIN earliest_contact_channels ecc ON scr.user_id = ecc.user_id
        GROUP BY scr.user_id, ecc.earliest_contact_channel
    ),
    
    -- Remove duplicates and ensure proper grouping
    user_contacts_deduped AS (
        SELECT 
            user_id,
            earliest_contact_date,
            total_scam_tickets,
            earliest_contact_channel,
            combined_contact_text
        FROM user_combined_contacts
        QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY earliest_contact_date) = 1
    ),
    
    -- AI-powered scam claim detection using Snowflake Cortex (ONE CALL PER USER)
    user_scam_analysis AS (
        SELECT 
            user_id,
            earliest_contact_date,
            total_scam_tickets,
            earliest_contact_channel,
            combined_contact_text,
            -- OPTIMIZED: Simplified but comprehensive prompt
            TRIM(
                SNOWFLAKE.CORTEX.COMPLETE(
                    'claude-3-5-sonnet',
                    'Analyze customer service conversations to determine if the CUSTOMER claims to be a scam victim.

FOCUS: Only customer statements, ignore agent questions/responses.

OUTPUT: Y (customer explicitly claims victimization) or N (no victim claim)

GUIDELINES:
- Look for first-person claims: "I was scammed", "Someone stole my money"
- Ignore agent questions: "Were you scammed?"
- Ignore prevention talk: "How to avoid scams"

CONVERSATIONS:
' || REPLACE(LEFT(combined_contact_text, 1500), '"', '""') || '

ANSWER:'
                )
            ) AS claims_to_be_scammed
        FROM user_contacts_deduped
        WHERE LENGTH(combined_contact_text) > 50  -- Final filter for meaningful content
    )
    
    -- Final output: Only confirmed scam victims
    SELECT 
        user_id,
        earliest_contact_date as earliest_scam_contact_date,
        earliest_contact_channel,
        total_scam_tickets as confirmed_scam_contacts
    FROM user_scam_analysis
    WHERE UPPER(TRIM(claims_to_be_scammed)) = 'Y'  -- Only AI-confirmed scam victims
    ORDER BY earliest_scam_contact_date, user_id
);

-- ======================================================================================
-- VALIDATION QUERIES
-- ======================================================================================

-- Summary of results
SELECT 
    'Q1_2025_SCAM_VICTIMS_SUMMARY' as summary_type,
    COUNT(*) as total_confirmed_scam_victims,
    MIN(earliest_scam_contact_date) as earliest_contact_in_q1,
    MAX(earliest_scam_contact_date) as latest_contact_in_q1,
    AVG(confirmed_scam_contacts) as avg_scam_contacts_per_user,
    MAX(confirmed_scam_contacts) as max_scam_contacts_per_user
FROM RISK.TEST.hding_scam_contact_confirmed_victims;

-- Contact channel distribution for Q1 2025
SELECT 
    'Q1_2025_CONTACT_CHANNEL_DISTRIBUTION' as summary_type,
    earliest_contact_channel,
    COUNT(*) as victim_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage_of_victims,
    AVG(confirmed_scam_contacts) as avg_contacts_per_victim
FROM RISK.TEST.hding_scam_contact_confirmed_victims
GROUP BY earliest_contact_channel
ORDER BY victim_count DESC;

-- Monthly breakdown
SELECT 
    'Q1_2025_MONTHLY_BREAKDOWN' as summary_type,
    EXTRACT(MONTH FROM earliest_scam_contact_date) as contact_month,
    MONTHNAME(earliest_scam_contact_date) as month_name,
    COUNT(*) as victim_count,
    SUM(confirmed_scam_contacts) as total_scam_contacts
FROM RISK.TEST.hding_scam_contact_confirmed_victims
GROUP BY contact_month, month_name
ORDER BY contact_month;

-- Sample results for quality check
SELECT 
    'Q1_2025_SAMPLE_RESULTS' as sample_type,
    user_id,
    earliest_scam_contact_date,
    earliest_contact_channel,
    confirmed_scam_contacts
FROM RISK.TEST.hding_scam_contact_confirmed_victims
ORDER BY earliest_scam_contact_date
LIMIT 10;

/*
======================================================================================
EXECUTION NOTES FOR LAPTOP-INDEPENDENT RUNNING:
======================================================================================

✅ QUERY DESIGNED FOR ROBUST EXECUTION:
1. Runs server-side in Snowflake (laptop can be closed after submission)
2. Query timeout set to 1 hour (should complete much faster with Q1 data)
3. All operations are database-native (no client dependencies)
4. Results written to persistent table (RISK.TEST.hding_scam_contact_confirmed_victims)

📊 EXPECTED PERFORMANCE WITH Q1 2025 DATA:
- Date range: ~60% smaller than original (3 months vs 6 months)
- Expected records: ~50K-80K instead of 220K
- AI calls: ~20K-30K users instead of 170K
- Execution time: 10-20 minutes instead of hours
- Cost: ~$20-100 instead of $150-750

🎯 OPTIMIZATION BENEFITS:
- Combined approach: Fewer AI calls per user
- Focused period: Much smaller dataset
- Pre-filtering: Only meaningful content processed
- Robust execution: Server-side processing

💡 MONITORING PROGRESS:
After starting the query, you can close your laptop. Check progress later with:
SELECT COUNT(*) FROM RISK.TEST.hding_scam_contact_confirmed_victims;

🚀 READY TO EXECUTE!
*/
