-- ====================================================================
-- CREATE_INDEXES.SQL - DB2 INDEX DEFINITIONS
-- CREDIT CARD PROCESSING SYSTEM
-- ====================================================================

-- Index on Customer Name for searches
CREATE INDEX IX_CREDIT_ACCOUNT_NAME 
    ON CREDIT_ACCOUNT (CUSTOMER_NAME);

-- Index on Account Status for filtering
CREATE INDEX IX_CREDIT_ACCOUNT_STATUS 
    ON CREDIT_ACCOUNT (ACCOUNT_STATUS);

-- Index on Transaction Log Account Number (for joins and lookups)
CREATE INDEX IX_TRANSACTION_ACCOUNT 
    ON TRANSACTION_LOG (ACCOUNT_NUMBER);

-- Index on Transaction Date for reporting
CREATE INDEX IX_TRANSACTION_DATE 
    ON TRANSACTION_LOG (TRANSACTION_DATE DESC);

-- Index on Transaction Type for statistics
CREATE INDEX IX_TRANSACTION_TYPE 
    ON TRANSACTION_LOG (TRANSACTION_TYPE);

-- Composite index for common query patterns
CREATE INDEX IX_ACCOUNT_STATUS_BALANCE 
    ON CREDIT_ACCOUNT (ACCOUNT_STATUS, CURRENT_BALANCE);

-- Index on Batch Control Date for cleanup jobs
CREATE INDEX IX_BATCH_DATE 
    ON BATCH_CONTROL (BATCH_DATE DESC);

-- ====================================================================
-- STATISTICS UPDATE
-- ====================================================================
RUNSTATS ON TABLE CREDIT_ACCOUNT 
    WITH DISTRIBUTION AND DETAILED INDEXES ALL;

RUNSTATS ON TABLE TRANSACTION_LOG 
    WITH DISTRIBUTION AND DETAILED INDEXES ALL;

RUNSTATS ON TABLE BATCH_CONTROL 
    WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- ====================================================================
-- END OF CREATE_INDEXES.SQL
-- ====================================================================
