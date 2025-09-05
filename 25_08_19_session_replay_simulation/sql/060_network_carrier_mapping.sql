-- Title: Network Carrier Country Code Mapping
-- Intent: Get distinct network carriers and create mapping table with country codes
-- Inputs: RISK.TEST.hding_a3id_login_info
-- Output: List of carriers and mapping table with country codes
-- Assumptions: Carrier names contain regional/country indicators
-- Validation: Verify carrier coverage and country code accuracy

-- 1. Get distinct network carriers with counts
SELECT 
    network_carrier,
    COUNT(*) AS carrier_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM RISK.TEST.hding_a3id_login_info
WHERE network_carrier IS NOT NULL 
    AND TRIM(network_carrier) != ''
    AND network_carrier NOT IN ('--', '...', 'null', 'NULL')
GROUP BY network_carrier
ORDER BY carrier_count DESC
LIMIT 50;

-- 2. Create network carrier to country code mapping table
CREATE OR REPLACE TABLE RISK.TEST.network_carrier_country_mapping AS
SELECT 
    carrier_name,
    country_code,
    country_name,
    region
FROM VALUES 
    -- US Carriers
    ('Verizon', 'US', 'United States', 'North America'),
    ('T-Mobile', 'US', 'United States', 'North America'),
    ('Metro by T-Mobile', 'US', 'United States', 'North America'),
    ('AT&T', 'US', 'United States', 'North America'),
    ('"AT&T"', 'US', 'United States', 'North America'),
    ('Sprint', 'US', 'United States', 'North America'),
    ('Boost Mobile', 'US', 'United States', 'North America'),
    ('Cricket Wireless', 'US', 'United States', 'North America'),
    ('Straight Talk', 'US', 'United States', 'North America'),
    ('TracFone', 'US', 'United States', 'North America'),
    ('Virgin Mobile', 'US', 'United States', 'North America'),
    ('Mint Mobile', 'US', 'United States', 'North America'),
    ('Google Fi', 'US', 'United States', 'North America'),
    ('Xfinity Mobile', 'US', 'United States', 'North America'),
    ('US Cellular', 'US', 'United States', 'North America'),
    
    -- Mexican Carriers
    ('+Movil', 'MX', 'Mexico', 'North America'),
    ('Telcel', 'MX', 'Mexico', 'North America'),
    ('Movistar', 'MX', 'Mexico', 'North America'),
    ('AT&T Mexico', 'MX', 'Mexico', 'North America'),
    
    -- Canadian Carriers
    ('Rogers', 'CA', 'Canada', 'North America'),
    ('Bell', 'CA', 'Canada', 'North America'),
    ('Telus', 'CA', 'Canada', 'North America'),
    ('Freedom Mobile', 'CA', 'Canada', 'North America'),
    ('Fido', 'CA', 'Canada', 'North America'),
    ('Koodo', 'CA', 'Canada', 'North America'),
    
    -- UK Carriers
    ('Vodafone', 'GB', 'United Kingdom', 'Europe'),
    ('EE', 'GB', 'United Kingdom', 'Europe'),
    ('O2', 'GB', 'United Kingdom', 'Europe'),
    ('Three', 'GB', 'United Kingdom', 'Europe'),
    
    -- Other International
    ('Orange', 'FR', 'France', 'Europe'),
    ('Deutsche Telekom', 'DE', 'Germany', 'Europe'),
    ('Telefonica', 'ES', 'Spain', 'Europe'),
    ('TIM', 'IT', 'Italy', 'Europe'),
    ('Vodafone India', 'IN', 'India', 'Asia'),
    ('Airtel', 'IN', 'India', 'Asia'),
    ('Jio', 'IN', 'India', 'Asia'),
    ('China Mobile', 'CN', 'China', 'Asia'),
    ('China Unicom', 'CN', 'China', 'Asia'),
    ('SoftBank', 'JP', 'Japan', 'Asia'),
    ('KDDI', 'JP', 'Japan', 'Asia'),
    ('NTT Docomo', 'JP', 'Japan', 'Asia'),
    
    -- WiFi and Unknown cases
    ('WiFi', 'XX', 'Unknown/WiFi', 'Global'),
    ('unknown', 'XX', 'Unknown', 'Global'),
    ('', 'XX', 'Unknown', 'Global')
AS t(carrier_name, country_code, country_name, region);

-- 3. Validation - check coverage of mapping vs actual data
WITH carrier_data AS (
    SELECT 
        network_carrier,
        COUNT(*) AS total_records
    FROM RISK.TEST.hding_a3id_login_info
    WHERE network_carrier IS NOT NULL
    GROUP BY network_carrier
),
mapping_coverage AS (
    SELECT 
        c.network_carrier,
        c.total_records,
        m.country_code,
        m.country_name,
        CASE WHEN m.carrier_name IS NOT NULL THEN 'Mapped' ELSE 'Unmapped' END AS mapping_status
    FROM carrier_data c
    LEFT JOIN RISK.TEST.network_carrier_country_mapping m 
        ON c.network_carrier = m.carrier_name
)
SELECT 
    mapping_status,
    COUNT(*) AS unique_carriers,
    SUM(total_records) AS total_records,
    ROUND(SUM(total_records) * 100.0 / SUM(SUM(total_records)) OVER (), 2) AS percentage_coverage
FROM mapping_coverage
GROUP BY mapping_status
ORDER BY mapping_status;
