-- ====================================================================
-- LOAD_SAMPLE_DATA.SQL - LOAD INITIAL TEST DATA
-- CREDIT CARD PROCESSING SYSTEM
-- ====================================================================

-- Load sample credit card accounts
INSERT INTO CREDIT_ACCOUNT 
    (ACCOUNT_NUMBER, CUSTOMER_NAME, CURRENT_BALANCE, CREDIT_LIMIT, 
     LAST_PAYMENT_DATE, ACCOUNT_STATUS)
VALUES
    ('100001', 'John Smith', 500.00, 2000.00, '2026-02-10', 'A'),
    ('100002', 'Jane Doe', 200.00, 1500.00, '2026-02-12', 'A'),
    ('100003', 'Bob Johnson', 1250.00, 3000.00, '2026-01-15', 'A'),
    ('100004', 'Mary Williams', 0.00, 1000.00, NULL, 'A'),
    ('100005', 'James Brown', 750.50, 2500.00, '2026-02-01', 'A'),
    ('100006', 'Patricia Davis', 1500.00, 2000.00, '2026-01-20', 'A'),
    ('100007', 'Michael Miller', 300.00, 5000.00, '2026-02-14', 'A'),
    ('100008', 'Linda Wilson', 0.00, 1500.00, NULL, 'A'),
    ('100009', 'Robert Moore', 2500.00, 3000.00, '2026-01-25', 'A'),
    ('100010', 'Jennifer Taylor', 100.00, 1000.00, '2026-02-15', 'A');

-- Load historical transactions
INSERT INTO TRANSACTION_LOG
    (ACCOUNT_NUMBER, TRANSACTION_TYPE, AMOUNT, MERCHANT_ID, 
     BALANCE_AFTER, PROCESSED_BY)
VALUES
    ('100001', 'PURCHASE', 125.50, 'AMAZON', 625.50, 'SYSTEM'),
    ('100001', 'PAYMENT', 125.50, NULL, 500.00, 'SYSTEM'),
    ('100002', 'PURCHASE', 50.00, 'WALMART', 250.00, 'SYSTEM'),
    ('100002', 'PAYMENT', 50.00, NULL, 200.00, 'SYSTEM'),
    ('100003', 'PURCHASE', 500.00, 'BESTBUY', 1750.00, 'SYSTEM'),
    ('100003', 'PAYMENT', 500.00, NULL, 1250.00, 'SYSTEM'),
    ('100005', 'PURCHASE', 250.50, 'TARGET', 1001.00, 'SYSTEM'),
    ('100005', 'PAYMENT', 250.50, NULL, 750.50, 'SYSTEM'),
    ('100007', 'PURCHASE', 150.00, 'COSTCO', 450.00, 'SYSTEM'),
    ('100007', 'PAYMENT', 150.00, NULL, 300.00, 'SYSTEM');

-- Verify data load
SELECT COUNT(*) AS ACCOUNT_COUNT FROM CREDIT_ACCOUNT;
SELECT COUNT(*) AS TRANSACTION_COUNT FROM TRANSACTION_LOG;

-- Display loaded accounts
SELECT ACCOUNT_NUMBER, CUSTOMER_NAME, CURRENT_BALANCE, CREDIT_LIMIT
FROM CREDIT_ACCOUNT
ORDER BY ACCOUNT_NUMBER;

COMMIT;

-- ====================================================================
-- END OF LOAD_SAMPLE_DATA.SQL
-- ====================================================================
