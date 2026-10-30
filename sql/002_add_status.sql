-- Added for the March release. Run AFTER 001 but BEFORE deploying the new jar,
-- otherwise the app crashes on start (see incident from April).
ALTER TABLE orders ADD status VARCHAR(50);
UPDATE orders SET status = 'NEW' WHERE status IS NULL;
