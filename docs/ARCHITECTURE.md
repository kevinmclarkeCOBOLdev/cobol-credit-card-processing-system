# System Architecture

## Overview

The Credit Card Processing System is a modern mainframe application demonstrating enterprise-grade batch processing, online transaction processing, and API integration.

## Architecture Layers

### 1. Presentation Layer
- **Web/Mobile Applications** - Customer-facing interfaces
- **API Gateway** - Node.js/Express server
- **CICS 3270 Terminals** - Traditional mainframe access

### 2. Integration Layer
- **REST API Endpoints** - JSON-based communication
- **z/OS Connect** (optional) - Enterprise API management
- **IBM MQ** (optional) - Asynchronous messaging

### 3. Application Layer

#### Batch Processing
- **CCARDPROC** - Daily transaction processor
  - Reads transaction file sequentially
  - Updates DB2 account balances
  - Generates processing reports
  - Logs all transactions

#### Online Processing (CICS)
- **ACIN** - Account Inquiry
  - Real-time balance lookup
  - Customer information display
  - Credit availability calculation

- **ACPM** - Payment Processing
  - Accept customer payments
  - Update balances immediately
  - Generate confirmation

### 4. Data Layer
- **DB2 Database** - Primary data store
  - CREDIT_ACCOUNT table
  - TRANSACTION_LOG table
  - BATCH_CONTROL table

## Component Interaction Flow

### Batch Processing Flow
```
Daily Transaction File
    ↓
CCARDPROC Program
    ↓
Read Transaction Record
    ↓
Query DB2 (SELECT account)
    ↓
Validate Transaction
    ├─→ Valid: Calculate New Balance
    │       ↓
    │   Check Credit Limit
    │       ↓
    │   Update DB2 (UPDATE account)
    │       ↓
    │   Insert Transaction Log
    │       ↓
    │   Write Report Detail
    └─→ Invalid: Reject & Log Error
    ↓
Generate Summary Report
```

### Online Transaction Flow (CICS)
```
User Terminal
    ↓
Enter Transaction ID (ACIN or ACPM)
    ↓
CICS Receives Map
    ↓
COBOL Program Executes
    ↓
Execute DB2 Query
    ↓
Format Response Data
    ↓
Send Map to Terminal
    ↓
Display Results to User
```

### REST API Flow
```
Web/Mobile App
    ↓
HTTP Request (JSON)
    ↓
API Gateway (Node.js)
    ├─→ Authentication Check
    │       ↓
    │   Route to Controller
    │       ↓
    │   Execute DB2 Query
    │       ↓
    │   Format JSON Response
    └─→ Return to Client
```

## Database Schema

### CREDIT_ACCOUNT
Primary table storing account information

| Column | Type | Description |
|--------|------|-------------|
| ACCOUNT_NUMBER | CHAR(6) | PK, Unique ID |
| CUSTOMER_NAME | VARCHAR(50) | Full name |
| CURRENT_BALANCE | DECIMAL(10,2) | Outstanding balance |
| CREDIT_LIMIT | DECIMAL(10,2) | Max credit |
| LAST_PAYMENT_DATE | DATE | Last payment |
| ACCOUNT_STATUS | CHAR(1) | A/C/S |
| CREATED_DATE | TIMESTAMP | Creation time |
| MODIFIED_DATE | TIMESTAMP | Last update |

### TRANSACTION_LOG
Audit trail of all transactions

| Column | Type | Description |
|--------|------|-------------|
| TRANSACTION_ID | INTEGER | PK, Auto-increment |
| ACCOUNT_NUMBER | CHAR(6) | FK to CREDIT_ACCOUNT |
| TRANSACTION_TYPE | CHAR(8) | PURCHASE/PAYMENT |
| AMOUNT | DECIMAL(10,2) | Transaction amount |
| MERCHANT_ID | VARCHAR(10) | Merchant (purchases) |
| TRANSACTION_DATE | TIMESTAMP | When processed |
| BALANCE_AFTER | DECIMAL(10,2) | Balance after |
| PROCESSED_BY | CHAR(10) | Batch/User ID |

### BATCH_CONTROL
Batch processing statistics

| Column | Type | Description |
|--------|------|-------------|
| BATCH_ID | CHAR(10) | PK, Batch identifier |
| BATCH_DATE | DATE | Processing date |
| START_TIME | TIMESTAMP | Start time |
| END_TIME | TIMESTAMP | End time |
| TRANSACTIONS_READ | INTEGER | Count read |
| TRANSACTIONS_PROC | INTEGER | Count processed |
| TRANSACTIONS_REJ | INTEGER | Count rejected |
| BATCH_STATUS | CHAR(1) | R/C/E |

## Transaction Processing Rules

### Purchase Transaction
1. Validate account exists and is active
2. Retrieve current balance and credit limit
3. Calculate new balance: `NEW = CURRENT + AMOUNT`
4. Check: `NEW <= CREDIT_LIMIT`
5. If valid:
   - Update CREDIT_ACCOUNT.CURRENT_BALANCE
   - Insert into TRANSACTION_LOG
   - COMMIT
6. If invalid:
   - Reject transaction
   - Log error
   - ROLLBACK

### Payment Transaction
1. Validate account exists and is active
2. Retrieve current balance
3. Calculate new balance: `NEW = CURRENT - AMOUNT`
4. If NEW < 0, set NEW = 0 (overpayment)
5. Update CREDIT_ACCOUNT.CURRENT_BALANCE
6. Update CREDIT_ACCOUNT.LAST_PAYMENT_DATE
7. Insert into TRANSACTION_LOG
8. COMMIT

## Error Handling Strategy

### Database Errors
- **SQLCODE 0**: Success, proceed
- **SQLCODE 100**: Not found, reject transaction
- **SQLCODE < 0**: Error, ROLLBACK, log details

### Application Errors
- Invalid account number → Reject with error code
- Inactive account → Reject with status message
- Over credit limit → Reject with available credit info
- Invalid transaction type → Reject with valid types

### Recovery
- All DB2 updates within transaction boundaries
- COMMIT on success
- ROLLBACK on any error
- Transaction log for audit trail

## Security Considerations

### API Security
- JWT token authentication
- HTTPS encryption (TLS 1.2+)
- Rate limiting (100 requests/15 min)
- API key validation
- CORS policy enforcement

### Database Security
- DB2 user authentication
- Row-level security (future)
- Encrypted connections
- Audit logging enabled

### CICS Security
- RACF/ACF2 authentication
- Transaction-level security
- Terminal authorization
- Audit trail

## Performance Optimization

### Batch Processing
- Block buffer optimization (BLKSIZE)
- DB2 bind with CURRENTDATA(NO)
- Commit frequency: Every 100 transactions
- Indexed columns for queries

### Online Processing
- Pseudo-conversational CICS design
- Efficient COMMAREA usage
- Optimized SQL queries
- Connection pooling

### API Layer
- Response caching (Redis optional)
- Database connection pooling
- Compressed JSON responses
- Pagination for large result sets

## Scalability

### Horizontal Scaling
- Multiple API Gateway instances
- Load balancer (Nginx/HAProxy)
- Stateless API design

### Vertical Scaling
- Increased CICS region size
- Additional DB2 buffer pools
- Batch window optimization

## Monitoring and Observability

### Metrics to Track
- Transaction volume (per hour/day)
- Average response time
- Error rate
- Database connection pool usage
- API endpoint latency
- Batch processing duration

### Logging
- Application logs (Winston for API)
- DB2 transaction logs
- CICS system logs
- Audit trail in TRANSACTION_LOG

### Alerting
- High error rate (> 5%)
- Batch job failures
- Database connection issues
- API response time > 2 seconds

## Deployment Architecture

### Development Environment
```
Developer Workstation
    ↓
Git Repository
    ↓
z/OS Dev LPAR
    ├─→ DB2 Dev Database
    ├─→ CICS Dev Region
    └─→ Batch Dev Environment
```

### Production Environment
```
Load Balancer
    ↓
API Gateway Cluster (Active-Active)
    ↓
z/OS Production LPAR
    ├─→ DB2 Production (Sysplex)
    ├─→ CICS Production Regions
    └─→ Batch Production Environment
```

## Technology Stack

### Mainframe
- **z/OS** - Operating system
- **Enterprise COBOL V6.3** - Programming language
- **DB2 for z/OS V12** - Database
- **CICS TS V5.6** - Transaction manager
- **JCL** - Job control

### Distributed
- **Node.js 18+** - API runtime
- **Express.js** - Web framework
- **IBM DB2 Driver** - Database connectivity
- **JWT** - Authentication
- **Winston** - Logging

### DevOps
- **Git** - Version control
- **GitHub Actions** - CI/CD (optional)
- **Docker** - API containerization (optional)
- **Jenkins** - Build automation (optional)

## Future Enhancements

1. **Real-time Fraud Detection**
   - Machine learning integration
   - Anomaly detection
   - Transaction blocking

2. **Mobile Push Notifications**
   - Transaction alerts
   - Balance notifications
   - Payment reminders

3. **GraphQL API**
   - Flexible data queries
   - Reduced over-fetching
   - Better mobile performance

4. **Event Streaming**
   - Kafka integration
   - Real-time analytics
   - Event-driven microservices

5. **Blockchain Integration**
   - Transaction immutability
   - Enhanced security
   - Distributed ledger

## Compliance and Regulations

### PCI DSS
- Encrypted data transmission
- Secure storage (encrypted at rest)
- Access control
- Regular security audits

### SOX
- Audit trail (TRANSACTION_LOG)
- Separation of duties
- Change management
- Backup and recovery

### GDPR (if applicable)
- Data encryption
- Right to erasure
- Data portability
- Consent management

## Disaster Recovery

### Backup Strategy
- Daily DB2 full backups
- Hourly transaction log backups
- Batch input file retention (30 days)
- Offsite backup storage

### Recovery Procedures
- RPO (Recovery Point Objective): 1 hour
- RTO (Recovery Time Objective): 4 hours
- Automated failover to DR site
- Regular DR testing (quarterly)

## Conclusion

This architecture demonstrates enterprise-grade mainframe application design with modern API integration. The system balances proven mainframe reliability with contemporary digital capabilities.
