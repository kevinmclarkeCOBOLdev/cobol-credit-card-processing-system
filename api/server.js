/**
 * server.js - Credit Card Processing API Gateway
 * 
 * RESTful API gateway that exposes COBOL credit card processing
 * services to web and mobile applications.
 * 
 * Technologies: Express.js, DB2 driver, JWT authentication
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Import routes
const accountRoutes = require('./routes/accounts');
const paymentRoutes = require('./routes/payments');

// Import middleware
const authMiddleware = require('./middleware/auth');
const loggerMiddleware = require('./middleware/logger');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// ============================================================
// MIDDLEWARE CONFIGURATION
// ============================================================

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use(morgan('combined'));
app.use(loggerMiddleware);

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later'
});
app.use('/api/', limiter);

// ============================================================
// ROUTES
// ============================================================

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'UP',
        timestamp: new Date().toISOString(),
        service: 'Credit Card Processing API',
        version: '1.0.0'
    });
});

// API version 1 routes
app.use('/api/v1/accounts', authMiddleware, accountRoutes);
app.use('/api/v1/payments', authMiddleware, paymentRoutes);

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Credit Card Processing API Gateway',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            accounts: '/api/v1/accounts',
            payments: '/api/v1/payments'
        },
        documentation: '/api/docs'
    });
});

// API documentation endpoint
app.get('/api/docs', (req, res) => {
    res.json({
        api: 'Credit Card Processing System',
        version: '1.0.0',
        baseURL: `http://localhost:${PORT}/api/v1`,
        endpoints: [
            {
                method: 'GET',
                path: '/accounts/:accountNumber',
                description: 'Get account details',
                authentication: 'Required',
                example: '/accounts/100001'
            },
            {
                method: 'GET',
                path: '/accounts/:accountNumber/transactions',
                description: 'Get transaction history',
                authentication: 'Required',
                example: '/accounts/100001/transactions'
            },
            {
                method: 'POST',
                path: '/payments',
                description: 'Process payment',
                authentication: 'Required',
                body: {
                    accountNumber: '100001',
                    amount: 50.00,
                    paymentDate: '2026-02-16'
                }
            },
            {
                method: 'POST',
                path: '/accounts/purchase',
                description: 'Process purchase',
                authentication: 'Required',
                body: {
                    accountNumber: '100001',
                    amount: 125.50,
                    merchantId: 'AMAZON'
                }
            }
        ]
    });
});

// ============================================================
// ERROR HANDLING
// ============================================================

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Cannot ${req.method} ${req.path}`,
        timestamp: new Date().toISOString()
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    
    res.status(err.status || 500).json({
        error: err.name || 'Internal Server Error',
        message: err.message || 'An unexpected error occurred',
        timestamp: new Date().toISOString(),
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// ============================================================
// SERVER STARTUP
// ============================================================

app.listen(PORT, () => {
    console.log('='.repeat(60));
    console.log('Credit Card Processing API Gateway');
    console.log('='.repeat(60));
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`API Base URL: http://localhost:${PORT}/api/v1`);
    console.log(`Health Check: http://localhost:${PORT}/health`);
    console.log(`Documentation: http://localhost:${PORT}/api/docs`);
    console.log('='.repeat(60));
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    process.exit(0);
});

module.exports = app;
