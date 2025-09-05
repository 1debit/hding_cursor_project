-- Title: Final Comprehensive Network Carrier Mapping with Validation
-- Intent: Execute comprehensive mapping and add remaining carriers via INSERT
-- Inputs: RISK.TEST.hding_a3id_login_info
-- Output: Complete carrier mapping table with 90%+ coverage validation
-- Assumptions: Two-step process: CREATE comprehensive table, then INSERT additional carriers
-- Validation: Final coverage percentage and top carrier mapping status

-- Step 1: Run the comprehensive mapping first (recreates table)
CREATE OR REPLACE TABLE RISK.TEST.network_carrier_country_mapping AS
SELECT 
    carrier_name,
    country_code,
    country_name,
    region,
    carrier_type
FROM VALUES 
    -- Major US Network Operators (MNOs)
    ('Verizon', 'US', 'United States', 'North America', 'MNO'),
    ('T-Mobile', 'US', 'United States', 'North America', 'MNO'),
    ('AT&T', 'US', 'United States', 'North America', 'MNO'),
    ('"AT&T"', 'US', 'United States', 'North America', 'MNO'),
    ('Sprint', 'US', 'United States', 'North America', 'MNO'),
    
    -- US MVNOs and Regional
    ('Metro by T-Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('cricket', 'US', 'United States', 'North America', 'MVNO'),
    ('Cricket', 'US', 'United States', 'North America', 'MVNO'),
    ('Cricket Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('Boost', 'US', 'United States', 'North America', 'MVNO'),
    ('Boost Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('TracFone', 'US', 'United States', 'North America', 'MVNO'),
    ('Straight Talk', 'US', 'United States', 'North America', 'MVNO'),
    ('Simple Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('Virgin Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('Mint Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('Google Fi', 'US', 'United States', 'North America', 'MVNO'),
    ('Xfinity Mobile', 'US', 'United States', 'North America', 'Cable MVNO'),
    ('US Cellular', 'US', 'United States', 'North America', 'Regional'),
    ('Visible', 'US', 'United States', 'North America', 'MVNO'),
    ('Red Pocket', 'US', 'United States', 'North America', 'MVNO'),
    ('H2O Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('Ultra Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('Ting', 'US', 'United States', 'North America', 'MVNO'),
    ('Republic Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('Consumer Cellular', 'US', 'United States', 'North America', 'MVNO'),
    ('Walmart Family Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('Page Plus', 'US', 'United States', 'North America', 'MVNO'),
    ('Pure Talk', 'US', 'United States', 'North America', 'MVNO'),
    
    -- Cable/Internet Provider Mobile
    ('Spectrum', 'US', 'United States', 'North America', 'Cable MVNO'),
    ('Spectrum Mobile', 'US', 'United States', 'North America', 'Cable MVNO'),
    ('Comcast', 'US', 'United States', 'North America', 'Cable MVNO'),
    ('Optimum Mobile', 'US', 'United States', 'North America', 'Cable MVNO'),
    ('Cox Mobile', 'US', 'United States', 'North America', 'Cable MVNO'),
    ('Home', 'US', 'United States', 'North America', 'WiFi/Cable'),
    
    -- Canada
    ('Rogers', 'CA', 'Canada', 'North America', 'MNO'),
    ('Bell', 'CA', 'Canada', 'North America', 'MNO'),
    ('Bell Canada', 'CA', 'Canada', 'North America', 'MNO'),
    ('Telus', 'CA', 'Canada', 'North America', 'MNO'),
    ('Freedom Mobile', 'CA', 'Canada', 'North America', 'Regional'),
    ('Fido', 'CA', 'Canada', 'North America', 'MVNO'),
    ('Koodo', 'CA', 'Canada', 'North America', 'MVNO'),
    ('Virgin Mobile Canada', 'CA', 'Canada', 'North America', 'MVNO'),
    ('Public Mobile', 'CA', 'Canada', 'North America', 'MVNO'),
    
    -- International
    ('Vodafone', 'GB', 'United Kingdom', 'Europe', 'MNO'),
    ('EE', 'GB', 'United Kingdom', 'Europe', 'MNO'),
    ('O2', 'GB', 'United Kingdom', 'Europe', 'MNO'),
    ('Three', 'GB', 'United Kingdom', 'Europe', 'MNO'),
    ('Orange', 'FR', 'France', 'Europe', 'MNO'),
    ('Deutsche Telekom', 'DE', 'Germany', 'Europe', 'MNO'),
    ('Telefonica', 'ES', 'Spain', 'Europe', 'MNO'),
    ('Movistar', 'ES', 'Spain', 'Europe', 'MNO'),
    ('TIM', 'IT', 'Italy', 'Europe', 'MNO'),
    ('Airtel', 'IN', 'India', 'Asia', 'MNO'),
    ('Jio', 'IN', 'India', 'Asia', 'MNO'),
    ('China Mobile', 'CN', 'China', 'Asia', 'MNO'),
    ('SoftBank', 'JP', 'Japan', 'Asia', 'MNO'),
    ('NTT Docomo', 'JP', 'Japan', 'Asia', 'MNO'),
    
    -- WiFi and Unknown
    ('WiFi', 'XX', 'WiFi/Unknown', 'Global', 'WiFi'),
    ('unknown', 'XX', 'Unknown', 'Global', 'Unknown'),
    ('Unknown', 'XX', 'Unknown', 'Global', 'Unknown')
AS t(carrier_name, country_code, country_name, region, carrier_type);

-- Step 2: Insert additional carriers found in unmapped analysis
INSERT INTO RISK.TEST.network_carrier_country_mapping VALUES
    ('AirTalk', 'US', 'United States', 'North America', 'MVNO'),
    ('Assurance Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('Verizon Wireless', 'US', 'United States', 'North America', 'MNO'),
    ('CC Network', 'US', 'United States', 'North America', 'MVNO'),
    ('Mint', 'US', 'United States', 'North America', 'MVNO'),
    ('SafeLink', 'US', 'United States', 'North America', 'MVNO'),
    ('Access Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('TruConnect', 'US', 'United States', 'North America', 'MVNO'),
    ('Life Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('Q Link', 'US', 'United States', 'North America', 'MVNO'),
    ('StandUp Wireless', 'US', 'United States', 'North America', 'MVNO'),
    ('Tag Mobile', 'US', 'United States', 'North America', 'MVNO'),
    ('Cellular One', 'US', 'United States', 'North America', 'Regional'),
    ('C Spire', 'US', 'United States', 'North America', 'Regional'),
    ('Total Wireless', 'US', 'United States', 'North America', 'MVNO');

-- Step 3: Final comprehensive validation
WITH carrier_data AS (
    SELECT 
        network_carrier,
        COUNT(*) AS total_records,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
    FROM RISK.TEST.hding_a3id_login_info
    WHERE network_carrier IS NOT NULL
    GROUP BY network_carrier
),
mapping_coverage AS (
    SELECT 
        c.network_carrier,
        c.total_records,
        c.percentage,
        m.country_code,
        m.country_name,
        m.carrier_type,
        CASE WHEN m.carrier_name IS NOT NULL THEN 'Mapped' ELSE 'Unmapped' END AS mapping_status
    FROM carrier_data c
    LEFT JOIN RISK.TEST.network_carrier_country_mapping m 
        ON c.network_carrier = m.carrier_name
)
SELECT 
    'Final Coverage Summary' AS analysis_type,
    mapping_status,
    COUNT(*) AS unique_carriers,
    SUM(total_records) AS total_records,
    ROUND(SUM(total_records) * 100.0 / SUM(SUM(total_records)) OVER (), 2) AS coverage_percentage
FROM mapping_coverage
GROUP BY mapping_status
ORDER BY mapping_status;

-- Top carriers validation
SELECT 
    'Top 15 Carriers Mapping Status' AS analysis_type,
    c.network_carrier,
    c.total_records,
    c.percentage,
    COALESCE(m.country_code, 'UNMAPPED') AS country_code,
    COALESCE(m.country_name, 'UNMAPPED') AS country_name,
    COALESCE(m.carrier_type, 'UNMAPPED') AS carrier_type
FROM (
    SELECT 
        network_carrier,
        COUNT(*) AS total_records,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
    FROM RISK.TEST.hding_a3id_login_info
    WHERE network_carrier IS NOT NULL
    GROUP BY network_carrier
    ORDER BY total_records DESC
    LIMIT 15
) c
LEFT JOIN RISK.TEST.network_carrier_country_mapping m 
    ON c.network_carrier = m.carrier_name
ORDER BY c.total_records DESC;
