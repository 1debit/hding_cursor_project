-- Title: Unmapped Network Carriers Analysis
-- Intent: Identify top unmapped carriers to improve mapping coverage
-- Inputs: RISK.TEST.hding_a3id_login_info, RISK.TEST.network_carrier_country_mapping
-- Output: Top unmapped carriers for manual country code assignment
-- Assumptions: Focus on high-volume unmapped carriers for maximum impact
-- Validation: Check patterns in unmapped carrier names for bulk assignment

-- Get top unmapped carriers
WITH carrier_data AS (
    SELECT 
        network_carrier,
        COUNT(*) AS total_records,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
    FROM RISK.TEST.hding_a3id_login_info
    WHERE network_carrier IS NOT NULL
    GROUP BY network_carrier
),
unmapped_carriers AS (
    SELECT 
        c.network_carrier,
        c.total_records,
        c.percentage
    FROM carrier_data c
    LEFT JOIN RISK.TEST.network_carrier_country_mapping m 
        ON c.network_carrier = m.carrier_name
    WHERE m.carrier_name IS NULL
        AND c.network_carrier NOT IN ('', '--', '...', 'null', 'NULL', 'unknown')
)
SELECT 
    network_carrier,
    total_records,
    percentage,
    -- Suggest country based on carrier name patterns
    CASE 
        WHEN network_carrier ILIKE '%verizon%' OR network_carrier ILIKE '%tmobile%' OR network_carrier ILIKE '%att%' THEN 'Likely US'
        WHEN network_carrier ILIKE '%rogers%' OR network_carrier ILIKE '%bell%' OR network_carrier ILIKE '%telus%' THEN 'Likely CA'
        WHEN network_carrier ILIKE '%vodafone%' AND network_carrier ILIKE '%uk%' THEN 'Likely GB'
        WHEN network_carrier ILIKE '%orange%' OR network_carrier ILIKE '%sfr%' THEN 'Likely FR'
        WHEN network_carrier ILIKE '%telekom%' OR network_carrier ILIKE '%deutsche%' THEN 'Likely DE'
        WHEN network_carrier ILIKE '%movistar%' OR network_carrier ILIKE '%telefonica%' THEN 'Likely ES'
        WHEN network_carrier ILIKE '%tim%' OR network_carrier ILIKE '%wind%' THEN 'Likely IT'
        WHEN network_carrier ILIKE '%airtel%' OR network_carrier ILIKE '%jio%' THEN 'Likely IN'
        WHEN network_carrier ILIKE '%china%' OR network_carrier ILIKE '%unicom%' THEN 'Likely CN'
        WHEN network_carrier ILIKE '%softbank%' OR network_carrier ILIKE '%docomo%' THEN 'Likely JP'
        WHEN network_carrier ILIKE '%wifi%' OR network_carrier ILIKE '%wireless%' THEN 'WiFi/Unknown'
        ELSE 'Unknown'
    END AS suggested_country
FROM unmapped_carriers
ORDER BY total_records DESC
LIMIT 100;
