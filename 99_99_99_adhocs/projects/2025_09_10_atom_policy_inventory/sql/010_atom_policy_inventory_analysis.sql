-- Title: ATOM Policy Inventory Analysis
-- Intent: Comprehensive analysis of active ATOM event policies in decision platform
-- Inputs: chime.decision_platform.policies
-- Output: Policy inventory with analysis and recommendations
-- Author: ATOM Policy Inventory Project
-- Created: 2025-09-10

-- Main query to pull all active ATOM event policies
SELECT 
    policy_name,
    policy_created_at,
    policy_outcome,
    policy_created_by,
    policy_criteria,
    policy_status,
    event_name,
    -- Additional analysis fields
    DATEDIFF('day', policy_created_at, CURRENT_DATE()) as days_since_creation,
    CASE 
        WHEN policy_criteria LIKE '%atom_v3%' THEN 'Uses ATOM v3'
        WHEN policy_criteria LIKE '%atom_v2%' THEN 'Uses ATOM v2'
        WHEN policy_criteria LIKE '%atom%' THEN 'Uses ATOM (version unclear)'
        ELSE 'No ATOM reference'
    END as atom_version_usage,
    CASE 
        WHEN policy_outcome = 'BLOCK' THEN 'Blocking Policy'
        WHEN policy_outcome = 'ALLOW' THEN 'Allowing Policy'
        WHEN policy_outcome = 'REVIEW' THEN 'Review Policy'
        WHEN policy_outcome = 'CHALLENGE' THEN 'Challenge Policy'
        ELSE 'Other Action'
    END as policy_action_type,
    -- Extract key criteria patterns
    CASE 
        WHEN policy_criteria LIKE '%>%' OR policy_criteria LIKE '%<%' THEN 'Threshold-based'
        WHEN policy_criteria LIKE '%AND%' OR policy_criteria LIKE '%OR%' THEN 'Logic-based'
        WHEN policy_criteria LIKE '%IN%' OR policy_criteria LIKE '%=' THEN 'Value-based'
        ELSE 'Complex/Other'
    END as criteria_type
FROM chime.decision_platform.policies
WHERE 1=1
    AND event_name = 'atom_event'
    AND policy_status = 'active'
ORDER BY policy_created_at DESC, policy_name;

-- Summary statistics
SELECT 
    'POLICY_SUMMARY' as analysis_type,
    COUNT(*) as total_active_policies,
    COUNT(DISTINCT policy_created_by) as unique_creators,
    COUNT(DISTINCT policy_outcome) as unique_outcomes,
    MIN(policy_created_at) as oldest_policy_date,
    MAX(policy_created_at) as newest_policy_date,
    COUNT(CASE WHEN policy_criteria LIKE '%atom_v3%' THEN 1 END) as policies_using_atom_v3,
    COUNT(CASE WHEN policy_criteria LIKE '%atom_v2%' THEN 1 END) as policies_using_atom_v2,
    COUNT(CASE WHEN policy_outcome = 'BLOCK' THEN 1 END) as blocking_policies,
    COUNT(CASE WHEN policy_outcome = 'ALLOW' THEN 1 END) as allowing_policies,
    COUNT(CASE WHEN policy_outcome = 'REVIEW' THEN 1 END) as review_policies,
    COUNT(CASE WHEN policy_outcome = 'CHALLENGE' THEN 1 END) as challenge_policies
FROM chime.decision_platform.policies
WHERE 1=1
    AND event_name = 'atom_event'
    AND policy_status = 'active';
