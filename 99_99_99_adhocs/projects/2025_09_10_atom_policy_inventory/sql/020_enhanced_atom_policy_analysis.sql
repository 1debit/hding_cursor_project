-- Title: Enhanced ATOM Policy Analysis with Additional Columns
-- Intent: Load ATOM policies with is_atom_used, session_event, and policy summary columns
-- Inputs: chime.decision_platform.policies
-- Output: Enhanced policy inventory with intuitive summaries
-- Author: ATOM Policy Inventory Project
-- Created: 2025-09-10

WITH base_policies AS (
    SELECT
        policy_name,
        policy_created_at,
        policy_outcome,
        policy_created_by,
        policy_criteria,
        policy_status,
        event_name,
        DATEDIFF('day', policy_created_at, CURRENT_DATE()) as days_since_creation
    FROM chime.decision_platform.policies
    WHERE 1=1
        AND event_name = 'atom_event'
        AND policy_status = 'active'
),

enhanced_policies AS (
    SELECT
        *,
        -- 1. Check if ATOM v3 is used in policy criteria
        CASE
            WHEN policy_criteria ILIKE '%atom_v3%' THEN 'Y'
            ELSE 'N'
        END as is_atom_used,

        -- 2. Extract session_event value from policy criteria
        CASE
            WHEN policy_criteria ILIKE '%SESSION_EVENT_USERNAME_AUTH_INITIATED%' THEN 'SESSION_EVENT_USERNAME_AUTH_INITIATED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED%' THEN 'SESSION_EVENT_PASSWORD_AUTH_SUCCEEDED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_PASSWORD_AUTH_FAILED%' THEN 'SESSION_EVENT_PASSWORD_AUTH_FAILED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_OTP_AUTH_SUCCEEDED%' THEN 'SESSION_EVENT_OTP_AUTH_SUCCEEDED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_OTP_AUTH_FAILED%' THEN 'SESSION_EVENT_OTP_AUTH_FAILED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_MAGIC_LINK_AUTH_SUCCEEDED%' THEN 'SESSION_EVENT_MAGIC_LINK_AUTH_SUCCEEDED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_MAGIC_LINK_AUTH_FAILED%' THEN 'SESSION_EVENT_MAGIC_LINK_AUTH_FAILED'
            WHEN policy_criteria ILIKE '%SESSION_EVENT_%' THEN 'OTHER_SESSION_EVENT'
            ELSE 'NO_SESSION_EVENT'
        END as session_event,

        -- 3. High-level policy summary based on criteria patterns
        CASE
            -- Network carrier based policies
            WHEN policy_criteria ILIKE '%network_carrier%' AND policy_criteria ILIKE '%timezone%' AND policy_criteria ILIKE '%nunique__timezones%'
                THEN 'Detects foreign network carriers with multi-timezone travel patterns (potential emulator/VPN usage)'

            -- ATOM score threshold policies
            WHEN policy_criteria ILIKE '%atom_v3%' AND (policy_criteria ILIKE '%>%' OR policy_criteria ILIKE '%<%')
                THEN 'ATOM v3 risk score threshold-based policy'

            -- Device intelligence policies
            WHEN policy_criteria ILIKE '%device%' AND policy_criteria ILIKE '%fingerprint%'
                THEN 'Device fingerprinting and intelligence-based detection'

            -- IP geolocation policies
            WHEN policy_criteria ILIKE '%ip_country%' AND policy_criteria ILIKE '%network_carrier%'
                THEN 'IP country vs network carrier mismatch detection'

            -- Velocity-based policies
            WHEN policy_criteria ILIKE '%velocity%' OR policy_criteria ILIKE '%frequency%'
                THEN 'User behavior velocity and frequency analysis'

            -- Time-based policies
            WHEN policy_criteria ILIKE '%time%' AND (policy_criteria ILIKE '%hour%' OR policy_criteria ILIKE '%day%')
                THEN 'Time-based access pattern analysis'

            -- Feature store policies
            WHEN policy_criteria ILIKE '%feature_store%'
                THEN 'ML feature store-based risk assessment'

            -- Platform-specific policies
            WHEN policy_criteria ILIKE '%platform%' AND (policy_criteria ILIKE '%ios%' OR policy_criteria ILIKE '%android%')
                THEN 'Platform-specific (iOS/Android) risk detection'

            -- Session event policies
            WHEN policy_criteria ILIKE '%SESSION_EVENT_%'
                THEN 'Login session event-based risk detection'

            -- Complex multi-condition policies
            WHEN policy_criteria ILIKE '%AND%' AND policy_criteria ILIKE '%OR%'
                THEN 'Complex multi-condition risk assessment policy'

            -- Simple threshold policies
            WHEN policy_criteria ILIKE '%>%' OR policy_criteria ILIKE '%<%' OR policy_criteria ILIKE '%=%'
                THEN 'Threshold-based risk scoring policy'

            ELSE 'General risk assessment policy'
        END as policy_summary,

        -- Additional analysis columns
        CASE
            WHEN policy_outcome = 'BLOCK' THEN 'Blocking Policy'
            WHEN policy_outcome = 'ALLOW' THEN 'Allowing Policy'
            WHEN policy_outcome = 'REVIEW' THEN 'Review Policy'
            WHEN policy_outcome = 'CHALLENGE' THEN 'Challenge Policy'
            ELSE 'Other Action'
        END as policy_action_type,

        -- Policy complexity indicator
        CASE
            WHEN LENGTH(policy_criteria) > 1000 THEN 'High Complexity'
            WHEN LENGTH(policy_criteria) > 500 THEN 'Medium Complexity'
            ELSE 'Low Complexity'
        END as policy_complexity,

        -- Policy age category
        CASE
            WHEN days_since_creation > 365 THEN 'Legacy (>1 year)'
            WHEN days_since_creation > 180 THEN 'Mature (6-12 months)'
            WHEN days_since_creation > 90 THEN 'Recent (3-6 months)'
            ELSE 'New (<3 months)'
        END as policy_age_category

    FROM base_policies
)

-- Main results with all enhanced columns
SELECT
    policy_name,
    policy_created_at,
    policy_outcome,
    policy_created_by,
    policy_criteria,
    is_atom_used,
    session_event,
    policy_summary,
    policy_action_type,
    policy_complexity,
    policy_age_category,
    days_since_creation
FROM enhanced_policies
ORDER BY
    is_atom_used DESC,
    policy_created_at DESC,
    policy_name;

-- Summary statistics
SELECT
    'ENHANCED_SUMMARY' as analysis_type,
    COUNT(*) as total_policies,
    COUNT(CASE WHEN is_atom_used = 'Y' THEN 1 END) as policies_using_atom_v3,
    COUNT(CASE WHEN is_atom_used = 'N' THEN 1 END) as policies_not_using_atom_v3,
    COUNT(DISTINCT session_event) as unique_session_events,
    COUNT(DISTINCT policy_summary) as unique_policy_types,
    COUNT(CASE WHEN policy_action_type = 'Blocking Policy' THEN 1 END) as blocking_policies,
    COUNT(CASE WHEN policy_action_type = 'Review Policy' THEN 1 END) as review_policies,
    COUNT(CASE WHEN policy_complexity = 'High Complexity' THEN 1 END) as high_complexity_policies,
    COUNT(CASE WHEN policy_age_category = 'Legacy (>1 year)' THEN 1 END) as legacy_policies
FROM enhanced_policies;
