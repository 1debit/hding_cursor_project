-- Title: Scam Contact Sample Analysis (1000 Records)
-- Intent: Extract sample conversations to build text mining rules
-- Inputs: zendesk_tickets_base, zendesk_tickets_comments_raw
-- Output: 1000 sample conversations for pattern analysis
-- Assumptions: Using full period 2024-11 to 2025-04 for representative sample
-- Validation: Check mix of phone/chat, text length distribution

-- Sample 1000 conversations for text pattern analysis
SELECT 
    zendesk_ticket.member_id as user_id,
    zendesk_ticket.created_at::date as contact_date,
    zendesk_ticket.id as ticket_id,
    zendesk_ticket_text.body as raw_text,
    LENGTH(zendesk_ticket_text.body) as text_length,
    CASE
        WHEN (zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') THEN 'PHONE_TRANSCRIPT'
        WHEN zendesk_ticket.subject = 'Start Live Chat' THEN 'CHAT_CONVERSATION'
        ELSE 'OTHER_CONTACT'
    END as contact_type,
    zendesk_ticket.subject as ticket_subject
FROM analytics.looker.zendesk_tickets_base AS zendesk_ticket
LEFT JOIN analytics.looker.zendesk_tickets_comments_raw zendesk_ticket_text
    ON zendesk_ticket.id::varchar = zendesk_ticket_text.ticket_id::varchar
WHERE 1=1
    AND zendesk_ticket.created_at::date BETWEEN '2024-11-01' AND '2025-04-30'  -- Full focal period
    AND zendesk_ticket_text.body ILIKE ANY ('%scam%')  -- Basic scam keyword filter
    AND ((zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%')
         OR (zendesk_ticket.subject = 'Start Live Chat'))  -- Phone or chat only
    AND zendesk_ticket.member_id IS NOT NULL
    AND zendesk_ticket.member_id::varchar != ''
    AND LENGTH(zendesk_ticket_text.body) > 100  -- Meaningful conversation length
    
-- Random sampling using HASH for reproducible results
    AND MOD(ABS(HASH(zendesk_ticket.id::varchar)), 100) < 5  -- ~5% sample rate
    
ORDER BY zendesk_ticket.created_at DESC
LIMIT 1000;

-- Preview the distribution
SELECT 
    'SAMPLE_OVERVIEW' as analysis_type,
    contact_type,
    COUNT(*) as count,
    AVG(text_length) as avg_text_length,
    MIN(text_length) as min_length,
    MAX(text_length) as max_length
FROM (
    -- Same query as above but with the aggregation
    SELECT 
        CASE
            WHEN (zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%') THEN 'PHONE_TRANSCRIPT'
            WHEN zendesk_ticket.subject = 'Start Live Chat' THEN 'CHAT_CONVERSATION'
            ELSE 'OTHER_CONTACT'
        END as contact_type,
        LENGTH(zendesk_ticket_text.body) as text_length
    FROM analytics.looker.zendesk_tickets_base AS zendesk_ticket
    LEFT JOIN analytics.looker.zendesk_tickets_comments_raw zendesk_ticket_text
        ON zendesk_ticket.id::varchar = zendesk_ticket_text.ticket_id::varchar
    WHERE 1=1
        AND zendesk_ticket.created_at::date BETWEEN '2024-11-01' AND '2025-04-30'
        AND zendesk_ticket_text.body ILIKE ANY ('%scam%')
        AND ((zendesk_ticket.subject ILIKE '%phone%' AND zendesk_ticket_text.body ILIKE '[%')
             OR (zendesk_ticket.subject = 'Start Live Chat'))
        AND zendesk_ticket.member_id IS NOT NULL
        AND zendesk_ticket.member_id::varchar != ''
        AND LENGTH(zendesk_ticket_text.body) > 100
        AND MOD(ABS(HASH(zendesk_ticket.id::varchar)), 100) < 5
    LIMIT 1000
) sample_data
GROUP BY contact_type
ORDER BY count DESC;
