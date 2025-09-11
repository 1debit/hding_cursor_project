-- Explore the ATOM v2 table structure (key for fraud detection)
DESCRIBE TABLE ml.model_inference.atom_v2_batch_predictions;

-- Sample ATOM data to understand the scoring structure
SELECT * FROM ml.model_inference.atom_v2_batch_predictions LIMIT 2;
