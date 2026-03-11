# Credit Card Processing System - Mainframe Modernization Capstone

A comprehensive demonstration of enterprise mainframe development showcasing COBOL batch processing, DB2 database integration, CICS online transactions, and REST API modernization.

## 🎯 Project Overview

This system simulates a complete credit card processing platform implementing:
- **Batch Processing** - Daily transaction processing in COBOL
- **Online Transactions** - Real-time CICS programs for account inquiries and payments
- **Database Integration** - DB2 for persistent account storage
- **API Modernization** - RESTful API gateway exposing COBOL services
- **Comprehensive Testing** - Unit, integration, and API tests

## 🏗️ System Architecture

```
┌─────────────────┐
│  Web/Mobile App │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  REST API       │  ← Node.js/Express Gateway
│  Gateway        │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Integration    │  ← z/OS Connect / MQ
│  Layer          │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ↓                  ↓                  ↓
┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
│  CICS Programs  │  │    Batch     │  │     DB2      │
│  (Online)       │  │  Processing  │  │   Database   │
│  - ACIN         │  │  - CCARDPROC │  │              │
│  - ACPM         │  │              │  │              │
└─────────────────┘  └──────────────┘  └──────────────┘
```

## 📁 Repository Structure

```
credit-card-processing-system/
├── README.md                       # This file
├── batch/
│   ├── programs/
│   │   └── CCARDPROC.cbl          # Main batch processor
│   ├── jcl/
│   │   ├── COMPILE.jcl            # Compile batch programs
│   │   ├── RUNBATCH.jcl           # Execute daily processing
│   │   └── LOADDB2.jcl            # Load initial data
│   └── copybooks/
│       ├── ACCOUNT.cpy            # Account record layout
│       └── TRANREC.cpy            # Transaction record layout
├── cics/
│   ├── programs/
│   │   ├── ACIN.cbl               # Account inquiry
│   │   └── ACPM.cbl               # Payment processing
│   ├── maps/
│   │   ├── ACINMAP.bms            # Inquiry screen map
│   │   └── ACPMMAP.bms            # Payment screen map
│   ├── jcl/
│   │   ├── COMPILEC.jcl           # Compile CICS programs
│   │   └── MAPASM.jcl             # Assemble BMS maps
│   └── copybooks/
│       └── CICSCOMM.cpy           # CICS common areas
├── db2/
│   ├── ddl/
│   │   ├── CREATE_TABLES.sql      # Table definitions
│   │   └── CREATE_INDEXES.sql     # Index definitions
│   ├── dml/
│   │   ├── LOAD_SAMPLE_DATA.sql   # Initial data load
│   │   └── QUERIES.sql            # Common queries
│   └── procedures/
│       └── UPDATE_BALANCE.sql     # Stored procedure
├── api/
│   ├── server.js                  # Express API server
│   ├── routes/
│   │   ├── accounts.js            # Account endpoints
│   │   └── payments.js            # Payment endpoints
│   ├── controllers/
│   │   ├── accountController.js   # Account logic
│   │   └── paymentController.js   # Payment logic
│   ├── middleware/
│   │   ├── auth.js                # Authentication
│   │   └── logger.js              # Request logging
│   ├── config/
│   │   └── database.js            # DB2 connection config
│   └── package.json               # Node dependencies
├── test-data/
│   ├── transactions/
│   │   ├── daily-trans-001.txt    # Sample transaction file
│   │   └── daily-trans-002.txt    # More test data
│   └── api-requests/
│       ├── get-account.json       # Sample API requests
│       └── post-payment.json
├── docs/
│   ├── ARCHITECTURE.md            # Detailed architecture
│   ├── API_GUIDE.md               # API documentation
│   ├── DEPLOYMENT.md              # Deployment guide
│   ├── TESTING.md                 # Testing strategy
│   └── SCREEN_LAYOUTS.md          # CICS screen designs
├── scripts/
│   ├── setup.sh                   # Environment setup
│   ├── deploy.sh                  # Deployment script
│   └── test.sh                    # Run all tests
└── tests/
    ├── batch/
    │   └── test_ccardproc.cbl     # Batch tests
    ├── cics/
    │   └── test_transactions.txt  # CICS test scenarios
    └── api/
        └── api.test.js            # API integration tests
```

## 🗄️ Database Schema

### CREDIT_ACCOUNT Table

| Column | Type | Description |
|--------|------|-------------|
| ACCOUNT_NUMBER | CHAR(6) | Primary key, unique account ID |
| CUSTOMER_NAME | VARCHAR(50) | Customer full name |
| CURRENT_BALANCE | DECIMAL(10,2) | Current account balance |
| CREDIT_LIMIT | DECIMAL(10,2) | Maximum credit limit |
| LAST_PAYMENT_DATE | DATE | Date of last payment |
| ACCOUNT_STATUS | CHAR(1) | A=Active, C=Closed, S=Suspended |
| CREATED_DATE | TIMESTAMP | Account creation timestamp |
| MODIFIED_DATE | TIMESTAMP | Last modification timestamp |

### TRANSACTION_LOG Table

| Column | Type | Description |
|--------|------|-------------|
| TRANSACTION_ID | INTEGER | Auto-increment primary key |
| ACCOUNT_NUMBER | CHAR(6) | Foreign key to CREDIT_ACCOUNT |
| TRANSACTION_TYPE | CHAR(8) | PURCHASE or PAYMENT |
| AMOUNT | DECIMAL(10,2) | Transaction amount |
| TRANSACTION_DATE | TIMESTAMP | Transaction timestamp |
| BALANCE_AFTER | DECIMAL(10,2) | Balance after transaction |
| PROCESSED_BY | CHAR(10) | Batch ID or User ID |

## 💳 Transaction Processing

### Transaction File Format

Fixed-length records (80 bytes):
```
Positions   Field               Type        Description
1-6         ACCOUNT_NUMBER      Numeric     Account ID
7-14        TRANSACTION_TYPE    Alpha       PURCHASE or PAYMENT
15-24       AMOUNT              Numeric     Amount (2 decimals)
25-34       MERCHANT_ID         Alpha       Merchant (for purchases)
35-80       FILLER              Alpha       Reserved
```

### Sample Transactions

```
100001PURCHASE 000012550AMAZON    
100001PAYMENT  000005000          
100002PURCHASE 000002500WALMART   
100003PAYMENT  000010000          
```

## 🔄 Batch Processing Flow

1. **Read Transaction File** - Sequential file processing
2. **Validate Transaction** - Check account exists, valid type
3. **Read Current Balance** - DB2 SELECT query
4. **Apply Transaction**:
   - PURCHASE: Increase balance (debit)
   - PAYMENT: Decrease balance (credit)
5. **Check Credit Limit** - Reject if over limit
6. **Update Database** - DB2 UPDATE with COMMIT
7. **Write Audit Log** - Transaction log entry
8. **Generate Report** - Summary statistics

## 💻 CICS Online Transactions

### ACIN - Account Inquiry (Transaction ID: ACIN)

**Purpose**: Display account information

**Screen Layout**:
```
==============================================================================
                        CREDIT CARD ACCOUNT INQUIRY
==============================================================================

  Account Number: [______]

  Customer Name:  [__________________________________________________]
  Current Balance: $_____________
  Credit Limit:    $_____________
  Available Credit: $_____________
  Last Payment:    __/__/____

  Account Status: [_] (A=Active, C=Closed, S=Suspended)


  PF3=Exit  CLEAR=Refresh  ENTER=Inquire
==============================================================================
```

### ACPM - Payment Processing (Transaction ID: ACPM)

**Purpose**: Post payment to account

**Screen Layout**:
```
==============================================================================
                        CREDIT CARD PAYMENT PROCESSING
==============================================================================

  Account Number: [______]

  Customer Name:  [__________________________________________________]
  Current Balance: $_____________

  Payment Amount:  $_____________

  New Balance:     $_____________ (After payment)


  [_] Confirm Payment (Y/N)

  Status: [____________________________________________________]


  PF3=Exit  CLEAR=Clear  ENTER=Process Payment
==============================================================================
```

## 🌐 REST API Endpoints

### Base URL
```
http://localhost:3000/api/v1
```

### Endpoints

#### GET /accounts/:accountNumber
Get account details

**Response**:
```json
{
  "accountNumber": "100001",
  "customerName": "John Smith",
  "currentBalance": 500.00,
  "creditLimit": 2000.00,
  "availableCredit": 1500.00,
  "lastPaymentDate": "2026-02-10",
  "accountStatus": "A"
}
```

#### POST /accounts/payment
Post payment to account

**Request**:
```json
{
  "accountNumber": "100001",
  "amount": 50.00,
  "paymentDate": "2026-02-16"
}
```

**Response**:
```json
{
  "success": true,
  "transactionId": 12345,
  "accountNumber": "100001",
  "previousBalance": 500.00,
  "paymentAmount": 50.00,
  "newBalance": 450.00,
  "timestamp": "2026-02-16T14:30:00Z"
}
```

#### GET /accounts/:accountNumber/transactions
Get transaction history

**Response**:
```json
{
  "accountNumber": "100001",
  "transactions": [
    {
      "transactionId": 12345,
      "type": "PAYMENT",
      "amount": 50.00,
      "date": "2026-02-16T14:30:00Z",
      "balanceAfter": 450.00
    },
    {
      "transactionId": 12344,
      "type": "PURCHASE",
      "amount": 125.50,
      "merchant": "AMAZON",
      "date": "2026-02-15T10:15:00Z",
      "balanceAfter": 500.00
    }
  ]
}
```

## 🚀 Quick Start

### Prerequisites
- IBM z/OS with COBOL compiler (V6.1+)
- DB2 for z/OS
- CICS Transaction Server
- Node.js 14+ (for API gateway)
- Git

### Setup Steps

1. **Clone Repository**
   ```bash
   git clone https://github.com/yourusername/credit-card-processing-system.git
   cd credit-card-processing-system
   ```

2. **Create DB2 Tables**
   ```bash
   db2 -tvf db2/ddl/CREATE_TABLES.sql
   db2 -tvf db2/ddl/CREATE_INDEXES.sql
   db2 -tvf db2/dml/LOAD_SAMPLE_DATA.sql
   ```

3. **Compile COBOL Programs**
   ```
   Submit: batch/jcl/COMPILE.jcl
   Submit: cics/jcl/COMPILEC.jcl
   Submit: cics/jcl/MAPASM.jcl
   ```

4. **Install API Dependencies**
   ```bash
   cd api
   npm install
   ```

5. **Start API Server**
   ```bash
   npm start
   # Server runs on http://localhost:3000
   ```

6. **Run Batch Processing**
   ```
   Submit: batch/jcl/RUNBATCH.jcl
   ```

## 🧪 Testing

### Run All Tests
```bash
./scripts/test.sh
```

### Test Batch Processing
```
Submit: batch/jcl/RUNBATCH.jcl
Check: SYSOUT for processing summary
```

### Test CICS Transactions
```
1. Start CICS region
2. Enter transaction: ACIN
3. Input account: 100001
4. Verify account details display
```

### Test API
```bash
cd tests/api
npm test
```

Or use curl:
```bash
# Get account
curl http://localhost:3000/api/v1/accounts/100001

# Post payment
curl -X POST http://localhost:3000/api/v1/accounts/payment \
  -H "Content-Type: application/json" \
  -d '{"accountNumber":"100001","amount":50.00}'
```

## 📊 Sample Output

### Batch Processing Report
```
==============================================================================
                    CREDIT CARD BATCH PROCESSING REPORT
                           Run Date: 2026-02-16
==============================================================================

PROCESSING STATISTICS:
  Total Transactions Processed:        25
  Total Purchases:                     18    Amount: $  3,456.78
  Total Payments:                       7    Amount: $  1,200.00
  Rejected Transactions:                2

ACCOUNT SUMMARY:
  Account    Customer Name              Old Balance  New Balance  Change
  -------    -------------              -----------  -----------  ------
  100001     John Smith                    500.00       575.50    +75.50
  100002     Jane Doe                      200.00       175.00    -25.00
  100003     Bob Johnson                 1,250.00     1,150.00   -100.00

ERRORS:
  Account 100005: Account not found
  Account 100001: Credit limit exceeded (rejected $500.00 purchase)

==============================================================================
                            END OF REPORT
==============================================================================
```

## 🎓 Skills Demonstrated

### COBOL Programming ⭐⭐⭐
- Batch processing with file I/O
- CICS online transaction processing
- DB2 embedded SQL
- JSON generation for APIs
- Error handling and validation
- Structured program design

### Database Integration ⭐⭐⭐
- DB2 table design
- SQL queries (SELECT, UPDATE, INSERT)
- Transaction management (COMMIT, ROLLBACK)
- Stored procedures
- Referential integrity

### CICS Development ⭐⭐
- BMS map design
- Pseudo-conversational programming
- COMMAREA usage
- Transaction definition
- Screen handling

### API Modernization ⭐⭐⭐
- RESTful API design
- JSON request/response
- Node.js integration
- Authentication/authorization
- API documentation

### JCL & Operations ⭐⭐
- Job control language
- Cataloged procedures
- Dataset allocation
- Condition code checking
- Multi-step jobs

### Testing & Quality ⭐
- Unit testing
- Integration testing
- API testing
- Test data management

## 💼 Real-World Applications

This system demonstrates patterns used in:
- **Banking**: Credit card processing, account management
- **Retail**: Payment processing, customer accounts
- **Financial Services**: Transaction processing, balance updates
- **E-commerce**: Payment gateways, account integration

## 🔧 Customization

### Adding New Transaction Types
1. Update `TRANREC.cpy` copybook
2. Add logic in `CCARDPROC.cbl`
3. Update validation rules
4. Add to transaction log

### Adding New API Endpoints
1. Create route in `api/routes/`
2. Implement controller logic
3. Update API documentation
4. Add integration tests

### Extending CICS Functionality
1. Design new BMS map
2. Create COBOL program
3. Define transaction in CICS
4. Add to documentation

## 📝 License

This project is provided as-is for educational and portfolio purposes.

## 👤 Author

Created as a mainframe modernization capstone project demonstrating enterprise COBOL development skills.

## 🌟 Acknowledgments

- IBM for COBOL, DB2, and CICS technologies
- Enterprise architecture best practices
- Financial services processing patterns

---

**⭐ Star this repository** if you find it useful for learning mainframe development and modernization!

## 📞 Support

For questions or issues:
- Review documentation in `/docs`
- Check test examples in `/tests`
- See API guide at `/docs/API_GUIDE.md`
