       IDENTIFICATION DIVISION.
       PROGRAM-ID. CCARDPROC.
       AUTHOR. CAPSTONE PROJECT.
      ******************************************************************
      * PROGRAM: CCARDPROC - CREDIT CARD BATCH PROCESSOR              *
      * PURPOSE: PROCESS DAILY CREDIT CARD TRANSACTIONS                *
      *          - PURCHASES: INCREASE BALANCE (DEBIT)                *
      *          - PAYMENTS:  DECREASE BALANCE (CREDIT)               *
      *          - UPDATE DB2 CREDIT_ACCOUNT TABLE                    *
      *          - GENERATE PROCESSING REPORT                         *
      *                                                                *
      * INPUT:   TRANSACTION FILE (80-BYTE FIXED)                     *
      * OUTPUT:  PROCESSING REPORT                                    *
      * DATABASE: DB2 CREDIT_ACCOUNT TABLE                            *
      ******************************************************************
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE ASSIGN TO TRANSIN
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE IS SEQUENTIAL
                  FILE STATUS IS WS-TRANS-STATUS.
           
           SELECT REPORT-FILE ASSIGN TO RPTOUT
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE IS SEQUENTIAL
                  FILE STATUS IS WS-REPORT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       
       FD  TRANS-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       COPY TRANREC.
       
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REPORT-LINE                  PIC X(132).
       
       WORKING-STORAGE SECTION.
       
      *----------------------------------------------------------------*
      * SQL COMMUNICATION AREA                                         *
      *----------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.
       
      *----------------------------------------------------------------*
      * SQL HOST VARIABLES                                             *
      *----------------------------------------------------------------*
       01  SQL-ACCOUNT-DATA.
           05  SQL-ACCOUNT-NUMBER       PIC X(6).
           05  SQL-CUSTOMER-NAME        PIC X(50).
           05  SQL-CURRENT-BALANCE      PIC S9(8)V99 COMP-3.
           05  SQL-CREDIT-LIMIT         PIC S9(8)V99 COMP-3.
           05  SQL-LAST-PAYMENT-DATE    PIC X(10).
           05  SQL-ACCOUNT-STATUS       PIC X(1).
       
       01  SQL-TRANSACTION-LOG.
           05  SQL-TRAN-ID              PIC S9(9) COMP.
           05  SQL-TRAN-ACCOUNT         PIC X(6).
           05  SQL-TRAN-TYPE            PIC X(8).
           05  SQL-TRAN-AMOUNT          PIC S9(8)V99 COMP-3.
           05  SQL-TRAN-TIMESTAMP       PIC X(26).
           05  SQL-BALANCE-AFTER        PIC S9(8)V99 COMP-3.
           05  SQL-PROCESSED-BY         PIC X(10).
       
      *----------------------------------------------------------------*
      * FILE STATUS AND FLAGS                                          *
      *----------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05  WS-TRANS-STATUS          PIC XX.
           05  WS-REPORT-STATUS         PIC XX.
       
       01  WS-FLAGS.
           05  WS-EOF-FLAG              PIC X VALUE 'N'.
               88  END-OF-FILE                  VALUE 'Y'.
           05  WS-FIRST-TIME-FLAG       PIC X VALUE 'Y'.
               88  FIRST-TIME                   VALUE 'Y'.
       
      *----------------------------------------------------------------*
      * COUNTERS AND ACCUMULATORS                                      *
      *----------------------------------------------------------------*
       01  WS-COUNTERS.
           05  WS-TRANS-READ            PIC 9(7) VALUE ZERO.
           05  WS-TRANS-PROCESSED       PIC 9(7) VALUE ZERO.
           05  WS-TRANS-REJECTED        PIC 9(7) VALUE ZERO.
           05  WS-PURCHASE-COUNT        PIC 9(7) VALUE ZERO.
           05  WS-PAYMENT-COUNT         PIC 9(7) VALUE ZERO.
           05  WS-PURCHASE-TOTAL        PIC S9(9)V99 COMP-3 VALUE ZERO.
           05  WS-PAYMENT-TOTAL         PIC S9(9)V99 COMP-3 VALUE ZERO.
           05  WS-PAGE-COUNT            PIC 9(4) VALUE ZERO.
           05  WS-LINE-COUNT            PIC 9(3) VALUE 99.
       
      *----------------------------------------------------------------*
      * WORKING STORAGE VARIABLES                                      *
      *----------------------------------------------------------------*
       01  WS-WORK-FIELDS.
           05  WS-OLD-BALANCE           PIC S9(8)V99 COMP-3.
           05  WS-NEW-BALANCE           PIC S9(8)V99 COMP-3.
           05  WS-AVAILABLE-CREDIT      PIC S9(8)V99 COMP-3.
           05  WS-BATCH-ID              PIC X(10) VALUE 'BATCH001'.
           05  WS-RUN-DATE              PIC X(10).
           05  WS-RUN-TIME              PIC X(8).
       
      *----------------------------------------------------------------*
      * REPORT HEADER LINES                                            *
      *----------------------------------------------------------------*
       01  HDR-LINE-1.
           05  FILLER                   PIC X(30) VALUE
               'CREDIT CARD BATCH PROCESSING'.
           05  FILLER                   PIC X(20) VALUE ' REPORT'.
           05  FILLER                   PIC X(32) VALUE SPACES.
           05  FILLER                   PIC X(6) VALUE 'PAGE: '.
           05  HDR-PAGE-NO              PIC ZZZ9.
           05  FILLER                   PIC X(40) VALUE SPACES.
       
       01  HDR-LINE-2.
           05  FILLER                   PIC X(11) VALUE 'RUN DATE: '.
           05  HDR-RUN-DATE             PIC X(10).
           05  FILLER                   PIC X(111) VALUE SPACES.
       
       01  HDR-LINE-3.
           05  FILLER                   PIC X(132) VALUE ALL '='.
       
       01  HDR-DETAIL.
           05  FILLER                   PIC X(8) VALUE 'ACCOUNT '.
           05  FILLER                   PIC X(21) VALUE 'CUSTOMER NAME'.
           05  FILLER                   PIC X(13) VALUE 'OLD BALANCE'.
           05  FILLER                   PIC X(13) VALUE 'NEW BALANCE'.
           05  FILLER                   PIC X(10) VALUE 'CHANGE'.
           05  FILLER                   PIC X(67) VALUE SPACES.
       
      *----------------------------------------------------------------*
      * DETAIL LINES                                                   *
      *----------------------------------------------------------------*
       01  DTL-LINE.
           05  DTL-ACCOUNT              PIC 9(6).
           05  FILLER                   PIC X(3) VALUE SPACES.
           05  DTL-CUSTOMER-NAME        PIC X(30).
           05  FILLER                   PIC X(3) VALUE SPACES.
           05  DTL-OLD-BALANCE          PIC $$$,$$$,$$9.99-.
           05  FILLER                   PIC X(2) VALUE SPACES.
           05  DTL-NEW-BALANCE          PIC $$$,$$$,$$9.99-.
           05  FILLER                   PIC X(2) VALUE SPACES.
           05  DTL-CHANGE               PIC +$$$,$$9.99.
           05  FILLER                   PIC X(50) VALUE SPACES.
       
      *----------------------------------------------------------------*
      * SUMMARY LINES                                                  *
      *----------------------------------------------------------------*
       01  SUM-STATISTICS.
           05  FILLER                   PIC X(35) VALUE
               'PROCESSING STATISTICS:'.
           05  FILLER                   PIC X(97) VALUE SPACES.
       
       01  SUM-TRANS-PROCESSED.
           05  FILLER                   PIC X(35) VALUE
               '  Total Transactions Processed:'.
           05  SUM-PROC-COUNT           PIC ZZZ,ZZ9.
           05  FILLER                   PIC X(91) VALUE SPACES.
       
       01  SUM-PURCHASES.
           05  FILLER                   PIC X(35) VALUE
               '  Total Purchases:'.
           05  SUM-PURCH-COUNT          PIC ZZZ,ZZ9.
           05  FILLER                   PIC X(5) VALUE SPACES.
           05  FILLER                   PIC X(8) VALUE 'Amount: '.
           05  SUM-PURCH-AMOUNT         PIC $$$,$$$,$$9.99.
           05  FILLER                   PIC X(68) VALUE SPACES.
       
       01  SUM-PAYMENTS.
           05  FILLER                   PIC X(35) VALUE
               '  Total Payments:'.
           05  SUM-PYMT-COUNT           PIC ZZZ,ZZ9.
           05  FILLER                   PIC X(5) VALUE SPACES.
           05  FILLER                   PIC X(8) VALUE 'Amount: '.
           05  SUM-PYMT-AMOUNT          PIC $$$,$$$,$$9.99.
           05  FILLER                   PIC X(68) VALUE SPACES.
       
       01  SUM-REJECTED.
           05  FILLER                   PIC X(35) VALUE
               '  Rejected Transactions:'.
           05  SUM-REJ-COUNT            PIC ZZZ,ZZ9.
           05  FILLER                   PIC X(91) VALUE SPACES.
       
       PROCEDURE DIVISION.
       
      *================================================================*
      * MAIN PROCESSING LOGIC                                          *
      *================================================================*
       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-TRANSACTIONS UNTIL END-OF-FILE
           PERFORM 3000-FINALIZE
           STOP RUN.
       
      *================================================================*
      * INITIALIZATION                                                 *
      *================================================================*
       1000-INITIALIZE.
           OPEN INPUT TRANS-FILE
           OPEN OUTPUT REPORT-FILE
           
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-RUN-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-RUN-TIME
           
           PERFORM 8000-WRITE-HEADERS
           
           DISPLAY '=============================================='
           DISPLAY 'CREDIT CARD BATCH PROCESSOR STARTING'
           DISPLAY 'BATCH ID: ' WS-BATCH-ID
           DISPLAY 'RUN DATE: ' WS-RUN-DATE
           DISPLAY '=============================================='
           
           PERFORM 1100-READ-TRANSACTION.
       
       1100-READ-TRANSACTION.
           READ TRANS-FILE
               AT END
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   ADD 1 TO WS-TRANS-READ
           END-READ.
       
      *================================================================*
      * PROCESS TRANSACTIONS                                           *
      *================================================================*
       2000-PROCESS-TRANSACTIONS.
           PERFORM 2100-VALIDATE-TRANSACTION
           
           IF SQLCODE = ZERO
               PERFORM 2200-CALCULATE-NEW-BALANCE
               
               IF SQLCODE = ZERO
                   PERFORM 2300-UPDATE-ACCOUNT
                   
                   IF SQLCODE = ZERO
                       PERFORM 2400-LOG-TRANSACTION
                       PERFORM 7000-WRITE-DETAIL
                       ADD 1 TO WS-TRANS-PROCESSED
                   ELSE
                       PERFORM 9100-HANDLE-DB2-ERROR
                       ADD 1 TO WS-TRANS-REJECTED
                   END-IF
               ELSE
                   ADD 1 TO WS-TRANS-REJECTED
               END-IF
           ELSE
               ADD 1 TO WS-TRANS-REJECTED
           END-IF
           
           PERFORM 1100-READ-TRANSACTION.
       
      *----------------------------------------------------------------*
      * VALIDATE TRANSACTION                                           *
      *----------------------------------------------------------------*
       2100-VALIDATE-TRANSACTION.
           MOVE TRAN-ACCOUNT-NUMBER TO SQL-ACCOUNT-NUMBER
           
           EXEC SQL
               SELECT ACCOUNT_NUMBER,
                      CUSTOMER_NAME,
                      CURRENT_BALANCE,
                      CREDIT_LIMIT,
                      ACCOUNT_STATUS
               INTO  :SQL-ACCOUNT-NUMBER,
                     :SQL-CUSTOMER-NAME,
                     :SQL-CURRENT-BALANCE,
                     :SQL-CREDIT-LIMIT,
                     :SQL-ACCOUNT-STATUS
               FROM CREDIT_ACCOUNT
               WHERE ACCOUNT_NUMBER = :SQL-ACCOUNT-NUMBER
           END-EXEC
           
           IF SQLCODE NOT = 0
               DISPLAY 'ERROR: Account ' TRAN-ACCOUNT-NUMBER 
                       ' not found'
           ELSE IF SQL-ACCOUNT-STATUS NOT = 'A'
               DISPLAY 'ERROR: Account ' TRAN-ACCOUNT-NUMBER 
                       ' not active'
               MOVE 100 TO SQLCODE
           END-IF.
       
      *----------------------------------------------------------------*
      * CALCULATE NEW BALANCE                                          *
      *----------------------------------------------------------------*
       2200-CALCULATE-NEW-BALANCE.
           MOVE SQL-CURRENT-BALANCE TO WS-OLD-BALANCE
           MOVE SQL-CURRENT-BALANCE TO WS-NEW-BALANCE
           
           EVALUATE TRUE
               WHEN TRAN-PURCHASE
                   ADD TRAN-AMOUNT TO WS-NEW-BALANCE
                   ADD TRAN-AMOUNT TO WS-PURCHASE-TOTAL
                   ADD 1 TO WS-PURCHASE-COUNT
                   
                   COMPUTE WS-AVAILABLE-CREDIT =
                           SQL-CREDIT-LIMIT - WS-NEW-BALANCE
                   
                   IF WS-AVAILABLE-CREDIT < ZERO
                       DISPLAY 'ERROR: Purchase exceeds credit limit'
                       DISPLAY '  Account: ' TRAN-ACCOUNT-NUMBER
                       DISPLAY '  Amount: ' TRAN-AMOUNT
                       MOVE 100 TO SQLCODE
                   END-IF
               
               WHEN TRAN-PAYMENT
                   SUBTRACT TRAN-AMOUNT FROM WS-NEW-BALANCE
                   ADD TRAN-AMOUNT TO WS-PAYMENT-TOTAL
                   ADD 1 TO WS-PAYMENT-COUNT
                   
                   IF WS-NEW-BALANCE < ZERO
                       MOVE ZERO TO WS-NEW-BALANCE
                   END-IF
               
               WHEN OTHER
                   DISPLAY 'ERROR: Invalid transaction type'
                   DISPLAY '  Type: ' TRAN-TYPE
                   MOVE 100 TO SQLCODE
           END-EVALUATE.
       
      *----------------------------------------------------------------*
      * UPDATE ACCOUNT BALANCE IN DB2                                  *
      *----------------------------------------------------------------*
       2300-UPDATE-ACCOUNT.
           MOVE WS-NEW-BALANCE TO SQL-CURRENT-BALANCE
           MOVE FUNCTION CURRENT-DATE(1:10) 
                TO SQL-LAST-PAYMENT-DATE
           
           EXEC SQL
               UPDATE CREDIT_ACCOUNT
               SET CURRENT_BALANCE = :SQL-CURRENT-BALANCE,
                   LAST_PAYMENT_DATE = CURRENT DATE,
                   MODIFIED_DATE = CURRENT TIMESTAMP
               WHERE ACCOUNT_NUMBER = :SQL-ACCOUNT-NUMBER
           END-EXEC
           
           IF SQLCODE = 0
               EXEC SQL COMMIT WORK END-EXEC
               DISPLAY 'SUCCESS: Account ' SQL-ACCOUNT-NUMBER
                       ' updated. New balance: ' SQL-CURRENT-BALANCE
           ELSE
               EXEC SQL ROLLBACK WORK END-EXEC
               PERFORM 9100-HANDLE-DB2-ERROR
           END-IF.
       
      *----------------------------------------------------------------*
      * LOG TRANSACTION TO DB2                                         *
      *----------------------------------------------------------------*
       2400-LOG-TRANSACTION.
           MOVE TRAN-ACCOUNT-NUMBER TO SQL-TRAN-ACCOUNT
           MOVE TRAN-TYPE TO SQL-TRAN-TYPE
           MOVE TRAN-AMOUNT TO SQL-TRAN-AMOUNT
           MOVE WS-NEW-BALANCE TO SQL-BALANCE-AFTER
           MOVE WS-BATCH-ID TO SQL-PROCESSED-BY
           
           EXEC SQL
               INSERT INTO TRANSACTION_LOG
                   (ACCOUNT_NUMBER,
                    TRANSACTION_TYPE,
                    AMOUNT,
                    TRANSACTION_DATE,
                    BALANCE_AFTER,
                    PROCESSED_BY)
               VALUES
                   (:SQL-TRAN-ACCOUNT,
                    :SQL-TRAN-TYPE,
                    :SQL-TRAN-AMOUNT,
                    CURRENT TIMESTAMP,
                    :SQL-BALANCE-AFTER,
                    :SQL-PROCESSED-BY)
           END-EXEC
           
           IF SQLCODE = 0
               EXEC SQL COMMIT WORK END-EXEC
           ELSE
               DISPLAY 'WARNING: Transaction log insert failed'
               PERFORM 9100-HANDLE-DB2-ERROR
           END-IF.
       
      *================================================================*
      * FINALIZATION                                                   *
      *================================================================*
       3000-FINALIZE.
           PERFORM 7100-WRITE-SUMMARY
           
           CLOSE TRANS-FILE
           CLOSE REPORT-FILE
           
           DISPLAY '=============================================='
           DISPLAY 'BATCH PROCESSING COMPLETE'
           DISPLAY '  Transactions Read:      ' WS-TRANS-READ
           DISPLAY '  Transactions Processed: ' WS-TRANS-PROCESSED
           DISPLAY '  Transactions Rejected:  ' WS-TRANS-REJECTED
           DISPLAY '  Total Purchases:        ' WS-PURCHASE-COUNT
           DISPLAY '  Total Payments:         ' WS-PAYMENT-COUNT
           DISPLAY '=============================================='.
       
      *================================================================*
      * WRITE DETAIL LINE                                              *
      *================================================================*
       7000-WRITE-DETAIL.
           IF WS-LINE-COUNT > 55
               PERFORM 8000-WRITE-HEADERS
           END-IF
           
           IF FIRST-TIME
               WRITE REPORT-LINE FROM HDR-DETAIL
               ADD 2 TO WS-LINE-COUNT
               MOVE 'N' TO WS-FIRST-TIME-FLAG
           END-IF
           
           MOVE SQL-ACCOUNT-NUMBER TO DTL-ACCOUNT
           MOVE SQL-CUSTOMER-NAME TO DTL-CUSTOMER-NAME
           MOVE WS-OLD-BALANCE TO DTL-OLD-BALANCE
           MOVE WS-NEW-BALANCE TO DTL-NEW-BALANCE
           COMPUTE DTL-CHANGE = WS-NEW-BALANCE - WS-OLD-BALANCE
           
           WRITE REPORT-LINE FROM DTL-LINE
           ADD 1 TO WS-LINE-COUNT.
       
      *----------------------------------------------------------------*
      * WRITE SUMMARY SECTION                                          *
      *----------------------------------------------------------------*
       7100-WRITE-SUMMARY.
           WRITE REPORT-LINE FROM HDR-LINE-3
           WRITE REPORT-LINE FROM SUM-STATISTICS AFTER 2
           
           MOVE WS-TRANS-PROCESSED TO SUM-PROC-COUNT
           WRITE REPORT-LINE FROM SUM-TRANS-PROCESSED AFTER 1
           
           MOVE WS-PURCHASE-COUNT TO SUM-PURCH-COUNT
           MOVE WS-PURCHASE-TOTAL TO SUM-PURCH-AMOUNT
           WRITE REPORT-LINE FROM SUM-PURCHASES AFTER 1
           
           MOVE WS-PAYMENT-COUNT TO SUM-PYMT-COUNT
           MOVE WS-PAYMENT-TOTAL TO SUM-PYMT-AMOUNT
           WRITE REPORT-LINE FROM SUM-PAYMENTS AFTER 1
           
           MOVE WS-TRANS-REJECTED TO SUM-REJ-COUNT
           WRITE REPORT-LINE FROM SUM-REJECTED AFTER 1
           
           WRITE REPORT-LINE FROM HDR-LINE-3 AFTER 1.
       
      *----------------------------------------------------------------*
      * WRITE REPORT HEADERS                                           *
      *----------------------------------------------------------------*
       8000-WRITE-HEADERS.
           ADD 1 TO WS-PAGE-COUNT
           MOVE WS-PAGE-COUNT TO HDR-PAGE-NO
           MOVE WS-RUN-DATE TO HDR-RUN-DATE
           
           WRITE REPORT-LINE FROM HDR-LINE-1 AFTER PAGE
           WRITE REPORT-LINE FROM HDR-LINE-2 AFTER 1
           WRITE REPORT-LINE FROM HDR-LINE-3 AFTER 1
           
           MOVE 3 TO WS-LINE-COUNT.
       
      *================================================================*
      * ERROR HANDLING                                                 *
      *================================================================*
       9100-HANDLE-DB2-ERROR.
           DISPLAY '***** DB2 ERROR *****'
           DISPLAY 'SQLCODE: ' SQLCODE
           DISPLAY 'SQLERRM: ' SQLERRMC
           DISPLAY '*********************'.
