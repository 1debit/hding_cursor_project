-- Simple exploration of key tables

-- Look at the structure of DIM_ACCOUNT
DESCRIBE TABLE edw_db.core.dim_account;

-- Let's see what we can learn from a small sample
SELECT * FROM edw_db.core.dim_account LIMIT 3;
