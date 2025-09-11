-- Let's explore the key business tables I saw in the production SQL patterns

-- Look at the structure of DIM_ACCOUNT (I saw this in the previous output)
DESCRIBE TABLE edw_db.core.dim_account;

-- Look for settled transaction table
SHOW TABLES IN edw_db.core LIKE 'FCT%';

-- Check some core dimension tables  
SHOW TABLES IN edw_db.core LIKE 'DIM%';
