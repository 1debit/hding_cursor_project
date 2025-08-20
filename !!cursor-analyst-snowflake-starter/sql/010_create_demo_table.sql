-- Title: Demo Risk Analytics Table Creation and Sample Data
-- Intent: Create demonstration table for testing RISK database connection and basic operations
-- Inputs: None (creates new table in RISK.TEST schema)
-- Output: DEMO_RISK_EVENTS table with sample risk event records
-- Assumptions: Current schema has CREATE TABLE privileges
-- Validation: Row count = 2, all columns populated, ORDER_TS in valid timestamp format
-- Author: Cursor Analyst Starter Kit
-- Created: 2024-01-15
-- Modified: 2024-01-15

-- Warehouse: XS sufficient for demo operations
-- Query tag: demo-table-creation

-- Set session parameters for consistent behavior
ALTER SESSION SET QUERY_TAG = 'demo-table-creation';

-- Create demo risk events table with proper column types and naming conventions
CREATE OR REPLACE TABLE DEMO_RISK_EVENTS (
    id INTEGER NOT NULL,
    amount NUMBER(10,2) NOT NULL,
    city VARCHAR(100) NOT NULL,
    order_ts TIMESTAMP_NTZ NOT NULL,
    created_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample risk event data for testing
INSERT INTO DEMO_RISK_EVENTS (id, amount, city, order_ts) VALUES
    (1, 125.50, 'Austin', '2025-08-01 12:00:00'::TIMESTAMP_NTZ),
    (2, 234.40, 'Chicago', '2025-08-03 16:30:00'::TIMESTAMP_NTZ),
    (3, 459.99, 'Denver', '2025-08-05 09:15:30'::TIMESTAMP_NTZ),
    (4, 678.80, 'Seattle', '2025-08-07 14:22:15'::TIMESTAMP_NTZ);

-- Validation: Verify data insertion
SELECT 
    COUNT(*) AS row_count,
    MIN(order_ts) AS earliest_order,
    MAX(order_ts) AS latest_order,
    SUM(amount) AS total_amount
FROM DEMO_RISK_EVENTS;

-- Sample output for verification
SELECT 
    id,
    amount,
    city,
    order_ts,
    created_ts
FROM DEMO_RISK_EVENTS 
ORDER BY id;
