-- Title: Network Carrier Statistics Summary
-- Intent: Answer specific questions about carrier distribution and mapping
-- Inputs: RISK.TEST.hding_a3id_login_info, RISK.TEST.network_carrier_country_mapping
-- Output: Key statistics for carrier analysis
-- Assumptions: Empty values include NULL, empty string, and '--'
-- Validation: Provide exact counts and percentages

-- Question 1: Total number of distinct network carriers
SELECT 
    '1. Total Distinct Carriers' AS metric,
    COUNT(DISTINCT network_carrier) AS count,
    NULL AS percentage
FROM RISK.TEST.hding_a3id_login_info;

-- Question 2: Percentage of empty carrier values
WITH empty_analysis AS (
    SELECT 
        COUNT(*) AS total_records,
        COUNT(CASE 
            WHEN network_carrier IS NULL 
                OR TRIM(network_carrier) = '' 
                OR network_carrier = '--' 
            THEN 1 END) AS empty_records
    FROM RISK.TEST.hding_a3id_login_info
)
SELECT 
    '2. Empty Carrier Values' AS metric,
    empty_records AS count,
    ROUND(empty_records * 100.0 / total_records, 2) AS percentage
FROM empty_analysis;

-- Question 3: Percentage of carriers with country code mapping
WITH mapping_analysis AS (
    SELECT 
        COUNT(DISTINCT network_carrier) AS total_distinct_carriers,
        COUNT(DISTINCT CASE WHEN m.carrier_name IS NOT NULL THEN c.network_carrier END) AS mapped_carriers
    FROM RISK.TEST.hding_a3id_login_info c
    LEFT JOIN RISK.TEST.network_carrier_country_mapping m 
        ON c.network_carrier = m.carrier_name
)
SELECT 
    '3. Carriers with Country Mapping' AS metric,
    mapped_carriers AS count,
    ROUND(mapped_carriers * 100.0 / total_distinct_carriers, 2) AS percentage
FROM mapping_analysis;

-- Bonus: Breakdown by carrier type
SELECT 
    '4. Carrier Type Breakdown' AS metric,
    COALESCE(m.carrier_type, 'Unmapped') AS carrier_type,
    COUNT(DISTINCT c.network_carrier) AS distinct_carriers,
    COUNT(*) AS total_records,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_records
FROM RISK.TEST.hding_a3id_login_info c
LEFT JOIN RISK.TEST.network_carrier_country_mapping m 
    ON c.network_carrier = m.carrier_name
GROUP BY m.carrier_type
ORDER BY total_records DESC;
