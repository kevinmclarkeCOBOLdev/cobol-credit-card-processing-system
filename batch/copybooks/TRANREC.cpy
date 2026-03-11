      ******************************************************************
      * TRANREC.CPY - TRANSACTION RECORD LAYOUT                       *
      * LENGTH: 80 BYTES FIXED                                        *
      ******************************************************************
       01  TRANSACTION-RECORD.
           05  TRAN-ACCOUNT-NUMBER      PIC 9(6).
           05  TRAN-TYPE                PIC X(8).
               88  TRAN-PURCHASE                VALUE 'PURCHASE'.
               88  TRAN-PAYMENT                 VALUE 'PAYMENT'.
           05  TRAN-AMOUNT              PIC 9(8)V99.
           05  TRAN-MERCHANT-ID         PIC X(10).
           05  TRAN-DATE                PIC X(10).
           05  FILLER                   PIC X(36).
