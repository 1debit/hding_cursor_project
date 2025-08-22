-- Title: Simple & Clean Scam Contact Analysis (Q1 2025)
-- Intent: Create scam victims table with bulletproof SQL logic
-- Output: RISK.TEST.hding_scam_contact_confirmed_victims

-- Enable robust execution
SET QUERY_TIMEOUT = 3600;
SET STATEMENT_TIMEOUT_IN_SECONDS = 3600;

CREATE OR REPLACE TABLE RISK.TEST.hding_scam_contact_confirmed_victims AS (
    WITH raw_contacts AS (
        -- Step 1: Get all Q1 2025 scam-related contacts
        SELECT 
            zendesk_ticket.member_id as user_id,
            zendesk_ticket.created_at::date as contact_date,
            zendesk_ticket.id as ticket_id,
            zendesk_ticket_text.body as raw_text,
            CASE 
                WHEN (zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') THEN 'PHONE_TRANSCRIPT'
                WHEN zendesk_ticket.subject = 'Start Live Chat' THEN 'CHAT_CONVERSATION'
                ELSE 'OTHER_CONTACT'
            END as contact_type
        FROM analytics.looker.zendesk_tickets_base AS zendesk_ticket 
        LEFT JOIN analytics.looker.zendesk_tickets_comments_raw zendesk_ticket_text 
            ON zendesk_ticket.id::varchar = zendesk_ticket_text.ticket_id::varchar
        WHERE 1=1
            AND zendesk_ticket.created_at::date BETWEEN '2025-01-01' AND '2025-03-31'
            AND zendesk_ticket_text.body ILIKE ANY ('%scam%')
            AND ((zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') 
                 OR (zendesk_ticket.subject = 'Start Live Chat'))
            AND zendesk_ticket.member_id IS NOT NULL
            AND LENGTH(zendesk_ticket_text.body) > 100
    ),
    
    earliest_contacts AS (
        -- Step 2: Get earliest contact per user with channel
        SELECT 
            user_id,
            contact_date,
            contact_type as earliest_contact_channel
        FROM raw_contacts
        QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY contact_date, ticket_id) = 1
    ),
    
    user_aggregated AS (
        -- Step 3: Aggregate all contacts per user
        SELECT 
            rc.user_id,
            ec.contact_date as earliest_contact_date,
            ec.earliest_contact_channel,
            COUNT(DISTINCT rc.ticket_id) as total_tickets,
            LISTAGG(
                CASE WHEN LENGTH(rc.raw_text) > 800 
                     THEN LEFT(rc.raw_text, 800) || '...' 
                     ELSE rc.raw_text END, 
                '\n---\n'
            ) WITHIN GROUP (ORDER BY rc.contact_date) as combined_text
        FROM raw_contacts rc
        INNER JOIN earliest_contacts ec ON rc.user_id = ec.user_id
        GROUP BY rc.user_id, ec.contact_date, ec.earliest_contact_channel
    ),
    
    ai_analyzed AS (
        -- Step 4: AI analysis
        SELECT 
            user_id,
            earliest_contact_date,
            earliest_contact_channel,
            total_tickets,
            TRIM(
                SNOWFLAKE.CORTEX.COMPLETE(
                    'claude-3-5-sonnet',
                    'Does the CUSTOMER claim to be a scam victim? Output Y or N only.

Text: ' || LEFT(combined_text, 1500) || '

Answer:'
                )
            ) AS scam_claim
        FROM user_aggregated
        WHERE LENGTH(combined_text) > 50
    )
    
    -- Step 5: Final output - only confirmed victims
    SELECT 
        user_id,
        earliest_contact_date as earliest_scam_contact_date,
        earliest_contact_channel,
        total_tickets as confirmed_scam_contacts
    FROM ai_analyzed
    WHERE UPPER(TRIM(scam_claim)) = 'Y'
    ORDER BY earliest_scam_contact_date, user_id
);

-- Quick validation
SELECT 
    COUNT(*) as total_scam_victims,
    MIN(earliest_scam_contact_date) as earliest_date,
    MAX(earliest_scam_contact_date) as latest_date
FROM RISK.TEST.hding_scam_contact_confirmed_victims;

SELECT * FROM RISK.TEST.hding_scam_contact_confirmed_victims LIMIT 5;
