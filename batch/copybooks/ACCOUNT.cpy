      ******************************************************************
      * ACCOUNT.CPY - CREDIT CARD ACCOUNT RECORD LAYOUT               *
      * USED BY: BATCH AND CICS PROGRAMS                              *
      ******************************************************************
       01  ACCOUNT-RECORD.
           05  ACCT-NUMBER              PIC 9(6).
           05  ACCT-CUSTOMER-NAME       PIC X(50).
           05  ACCT-CURRENT-BALANCE     PIC S9(8)V99 COMP-3.
           05  ACCT-CREDIT-LIMIT        PIC S9(8)V99 COMP-3.
           05  ACCT-LAST-PAYMENT-DATE   PIC X(10).
           05  ACCT-STATUS              PIC X(1).
               88  ACCT-ACTIVE                  VALUE 'A'.
               88  ACCT-CLOSED                  VALUE 'C'.
               88  ACCT-SUSPENDED               VALUE 'S'.
           05  ACCT-CREATED-DATE        PIC X(10).
           05  ACCT-MODIFIED-DATE       PIC X(10).
