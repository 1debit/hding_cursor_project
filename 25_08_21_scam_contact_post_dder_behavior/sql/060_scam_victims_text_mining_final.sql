-- Title: Scam Victims Table Creation Using Text Mining Rules
-- Intent: Replace expensive Cortex AI with pattern-based classification
-- Inputs: zendesk_tickets_base, zendesk_tickets_comments_raw (2024-11 to 2025-04)
-- Output: RISK.TEST.hding_scam_contact_confirmed_victims (text mining version)
-- Assumptions: Text patterns identified from 1000+ conversation analysis
-- Validation: Focus on member statements, exclude agent prevention talk

CREATE OR REPLACE TABLE RISK.TEST.hding_scam_contact_confirmed_victims AS (
    WITH raw_scam_contacts AS (
        -- Step 1: Get all contacts with scam keywords from full period
        SELECT DISTINCT
            zendesk_ticket.member_id as user_id,
            zendesk_ticket.created_at::date as contact_date,
            zendesk_ticket.id as ticket_id,
            zendesk_ticket_text.body as raw_text,
            zendesk_ticket.subject as ticket_subject,
            CASE
                WHEN (zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') THEN 'PHONE_TRANSCRIPT'
                WHEN zendesk_ticket.subject = 'Start Live Chat' THEN 'CHAT_CONVERSATION'
                ELSE 'OTHER_CONTACT'
            END as contact_type
        FROM analytics.looker.zendesk_tickets_base AS zendesk_ticket
        LEFT JOIN analytics.looker.zendesk_tickets_comments_raw zendesk_ticket_text
            ON zendesk_ticket.id::varchar = zendesk_ticket_text.ticket_id::varchar
        WHERE 1=1
            AND zendesk_ticket.created_at::date BETWEEN '2024-11-01' AND '2025-04-30'  -- Full focal period
            AND zendesk_ticket_text.body ILIKE ANY ('%scam%')  -- Basic scam keyword
            AND ((zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%')
                 OR (zendesk_ticket.subject = 'Start Live Chat'))  -- Phone or chat only
            AND zendesk_ticket.member_id IS NOT NULL
            AND zendesk_ticket.member_id::varchar != ''
            AND LENGTH(zendesk_ticket_text.body) > 100  -- Meaningful conversation length
    ),

    text_mining_victims AS (
        -- Step 2: Apply text mining rules to identify legitimate scam victims
        SELECT 
            user_id,
            contact_date,
            ticket_id,
            raw_text,
            contact_type,
            
            -- HIGH CONFIDENCE: Direct victim claims
            CASE WHEN raw_text ILIKE ANY (
                '%] member:%i was scammed%',
                '%] member:%i got scammed%', 
                '%] member:%someone scammed me%',
                '%] member:%i was a victim%',
                '%] member:%i am a victim%',
                '%] member:%my money was stolen%',
                '%] member:%my money was taken%',
                '%] member:%funds were stolen%',
                '%] member:%someone stole my money%'
            ) THEN 'HIGH_CONFIDENCE'
            
            -- MEDIUM-HIGH CONFIDENCE: Unauthorized activity
            WHEN raw_text ILIKE ANY (
                '%] member:%unauthorized%',
                '%] member:%i did not authorize%',
                '%] member:%i didnt authorize%', 
                '%] member:%i never authorized%',
                '%] member:%i never made%',
                '%] member:%i didnt make%',
                '%] member:%i did not make%',
                '%] member:%hacked%',
                '%] member:%compromised%'
            ) THEN 'MEDIUM_HIGH_CONFIDENCE'
            
            -- MEDIUM CONFIDENCE: Fraud mentions by customer
            WHEN raw_text ILIKE ANY (
                '%] member:%fraud%',
                '%] member:%fraudulent%',
                '%] member:%fake%',
                '%] member:%phishing%',
                '%] member:%suspicious activity%'
            ) THEN 'MEDIUM_CONFIDENCE'
            
            ELSE 'NO_VICTIM_PATTERN'
            END as confidence_level,
            
            -- EXCLUSION LOGIC: Remove prevention talk and agent-initiated scam discussions
            CASE WHEN raw_text ILIKE ANY (
                '%how to avoid scam%',
                '%scam prevention%', 
                '%protect from scam%',
                '%agent:%were you scammed%',  -- Agent asking if customer was scammed
                '%agent:%this sounds like a scam%',  -- Agent warning about scams
                '%agent:%scam alert%'
            ) THEN 'EXCLUDE'
            ELSE 'INCLUDE'
            END as inclusion_flag
            
        FROM raw_scam_contacts
    ),

    filtered_victims AS (
        -- Step 3: Keep only legitimate victim patterns, exclude prevention talk
        SELECT 
            user_id,
            contact_date,
            ticket_id,
            contact_type,
            confidence_level
        FROM text_mining_victims
        WHERE confidence_level IN ('HIGH_CONFIDENCE', 'MEDIUM_HIGH_CONFIDENCE', 'MEDIUM_CONFIDENCE')
        AND inclusion_flag = 'INCLUDE'
    ),

    earliest_contact_channels AS (
        -- Step 4a: Get earliest contact channel per user
        SELECT
            user_id,
            contact_type as earliest_contact_channel
        FROM filtered_victims
        QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY contact_date, ticket_id) = 1
    ),

    earliest_victim_contacts AS (
        -- Step 4b: Get earliest contact date and counts per user
        SELECT
            fv.user_id,
            MIN(fv.contact_date) as earliest_scam_contact_date,
            COUNT(DISTINCT fv.ticket_id) as confirmed_scam_contacts,
            ecc.earliest_contact_channel
        FROM filtered_victims fv
        LEFT JOIN earliest_contact_channels ecc ON fv.user_id = ecc.user_id
        GROUP BY fv.user_id, ecc.earliest_contact_channel
    )

    -- Step 5: Final deduplication - one record per user with earliest contact
    SELECT
        user_id,
        earliest_scam_contact_date,
        earliest_contact_channel,
        confirmed_scam_contacts
    FROM earliest_victim_contacts
    ORDER BY earliest_scam_contact_date, user_id
);

-- Validation query: Check results distribution
SELECT 
    'FINAL_RESULTS' as summary_type,
    COUNT(*) as total_confirmed_victims,
    COUNT(DISTINCT user_id) as unique_users_check,
    MIN(earliest_scam_contact_date) as earliest_date,
    MAX(earliest_scam_contact_date) as latest_date,
    COUNT(CASE WHEN earliest_contact_channel = 'PHONE_TRANSCRIPT' THEN 1 END) as phone_victims,
    COUNT(CASE WHEN earliest_contact_channel = 'CHAT_CONVERSATION' THEN 1 END) as chat_victims,
    AVG(confirmed_scam_contacts) as avg_contacts_per_user
FROM RISK.TEST.hding_scam_contact_confirmed_victims;

-- Sample of confirmed victims for spot check
SELECT 
    'SAMPLE_VICTIMS' as check_type,
    user_id,
    earliest_scam_contact_date,
    earliest_contact_channel,
    confirmed_scam_contacts
FROM RISK.TEST.hding_scam_contact_confirmed_victims
ORDER BY earliest_scam_contact_date DESC
LIMIT 10;
