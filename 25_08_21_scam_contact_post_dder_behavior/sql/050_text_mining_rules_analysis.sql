-- Title: Text Mining Rules Development for Scam Victim Identification
-- Intent: Build ILIKE ANY() patterns based on member statement analysis
-- Based on: Analysis of 50+ phone transcripts with scam keywords
-- Output: SQL rules to replace expensive Cortex AI

/*
PATTERN ANALYSIS RESULTS from member statements:

HIGH-CONFIDENCE VICTIM PATTERNS:
- "i never" (13 occurrences) - "i never received", "i never authorized"
- "fraud" (2 occurrences) - "fraudulent charges"
- "hacked" (2 occurrences) - "my account has been hacked"  
- "unauthorized" (1 occurrence) - "unauthorized take it off my card"
- "i got scammed" (1 occurrence) - direct victim claim
- "my money was taken" (1 occurrence) - direct loss claim

FOCUS: Look for MEMBER statements ("] member:") containing victim language
*/

-- Test the text mining rules on sample data
WITH sample_conversations AS (
    SELECT 
        zendesk_ticket.member_id as user_id,
        zendesk_ticket.created_at::date as contact_date,
        zendesk_ticket.id as ticket_id,
        zendesk_ticket_text.body as raw_text
    FROM analytics.looker.zendesk_tickets_base AS zendesk_ticket
    LEFT JOIN analytics.looker.zendesk_tickets_comments_raw zendesk_ticket_text
        ON zendesk_ticket.id::varchar = zendesk_ticket_text.ticket_id::varchar
    WHERE 1=1
        AND zendesk_ticket.created_at::date BETWEEN '2024-11-01' AND '2025-04-30'
        AND zendesk_ticket_text.body ILIKE ANY ('%scam%')
        AND ((zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%')
             OR (zendesk_ticket.subject = 'Start Live Chat'))
        AND zendesk_ticket.member_id IS NOT NULL
        AND LENGTH(zendesk_ticket_text.body) > 100
        AND MOD(ABS(HASH(zendesk_ticket.id::varchar)), 100) < 1  -- 1% sample
),

text_mining_classification AS (
    SELECT 
        user_id,
        contact_date,
        ticket_id,
        raw_text,
        
        -- RULE SET 1: Direct victim claims (HIGH CONFIDENCE)
        CASE WHEN raw_text ILIKE ANY (
            '%] member:%i was scammed%',
            '%] member:%i got scammed%', 
            '%] member:%someone scammed me%',
            '%] member:%i was a victim%',
            '%] member:%i am a victim%'
        ) THEN 'DIRECT_VICTIM_CLAIM'
        
        -- RULE SET 2: Money loss claims (HIGH CONFIDENCE)  
        WHEN raw_text ILIKE ANY (
            '%] member:%my money was stolen%',
            '%] member:%my money was taken%',
            '%] member:%funds were stolen%',
            '%] member:%someone stole my money%',
            '%] member:%money is gone%',
            '%] member:%money missing%'
        ) THEN 'MONEY_LOSS_CLAIM'
        
        -- RULE SET 3: Unauthorized activity (MEDIUM-HIGH CONFIDENCE)
        WHEN raw_text ILIKE ANY (
            '%] member:%unauthorized%',
            '%] member:%i did not authorize%',
            '%] member:%i didnt authorize%', 
            '%] member:%i never authorized%',
            '%] member:%i never made%',
            '%] member:%i didnt make%',
            '%] member:%i did not make%'
        ) THEN 'UNAUTHORIZED_ACTIVITY'
        
        -- RULE SET 4: Account compromise (MEDIUM CONFIDENCE)
        WHEN raw_text ILIKE ANY (
            '%] member:%hacked%',
            '%] member:%compromised%',
            '%] member:%someone got into%',
            '%] member:%someone accessed%'
        ) THEN 'ACCOUNT_COMPROMISE'
        
        -- RULE SET 5: Fraud mentions by customer (MEDIUM CONFIDENCE)
        WHEN raw_text ILIKE ANY (
            '%] member:%fraud%',
            '%] member:%fraudulent%',
            '%] member:%fake%',
            '%] member:%phishing%',
            '%] member:%suspicious activity%'
        ) THEN 'FRAUD_MENTION'
        
        ELSE 'NO_VICTIM_PATTERN'
        END as victim_classification,
        
        -- Flag for manual review (borderline cases)
        CASE WHEN raw_text ILIKE ANY (
            '%how to avoid scam%',
            '%scam prevention%', 
            '%agent:%scam%',  -- Agent mentioning scam, not customer
            '%is this a scam%',  -- Customer asking if something is scam
            '%protect from scam%'
        ) THEN 'EXCLUDE_PREVENTION_TALK'
        ELSE 'POTENTIAL_VICTIM'
        END as review_flag
        
    FROM sample_conversations
)

-- Results analysis
SELECT 
    victim_classification,
    review_flag,
    COUNT(*) as conversation_count,
    COUNT(DISTINCT user_id) as unique_users
FROM text_mining_classification
GROUP BY victim_classification, review_flag
ORDER BY conversation_count DESC;

-- Sample of high-confidence cases for validation
SELECT 
    user_id,
    ticket_id,
    victim_classification,
    LEFT(raw_text, 200) as sample_text
FROM text_mining_classification  
WHERE victim_classification IN ('DIRECT_VICTIM_CLAIM', 'MONEY_LOSS_CLAIM')
LIMIT 10;
