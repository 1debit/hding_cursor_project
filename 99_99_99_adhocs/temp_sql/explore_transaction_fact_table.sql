-- Find the main transaction fact table that I saw in production patterns

-- Look for FCT_SETTLED_TRANSACTION (this was key in many production queries)
DESCRIBE TABLE edw_db.core.fct_settled_transaction;

-- Sample a few records to understand structure
SELECT * FROM edw_db.core.fct_settled_transaction LIMIT 2;
