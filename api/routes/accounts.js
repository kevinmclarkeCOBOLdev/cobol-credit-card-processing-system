/**
 * routes/accounts.js - Account Management Routes
 * 
 * Handles all account-related API endpoints
 */

const express = require('express');
const router = express.Router();
const accountController = require('../controllers/accountController');

/**
 * @route   GET /api/v1/accounts/:accountNumber
 * @desc    Get account details
 * @access  Private
 */
router.get('/:accountNumber', accountController.getAccount);

/**
 * @route   GET /api/v1/accounts/:accountNumber/transactions
 * @desc    Get transaction history for account
 * @access  Private
 */
router.get('/:accountNumber/transactions', accountController.getTransactions);

/**
 * @route   GET /api/v1/accounts/:accountNumber/balance
 * @desc    Get current account balance
 * @access  Private
 */
router.get('/:accountNumber/balance', accountController.getBalance);

/**
 * @route   POST /api/v1/accounts
 * @desc    Create new account (admin only)
 * @access  Private/Admin
 */
router.post('/', accountController.createAccount);

/**
 * @route   PUT /api/v1/accounts/:accountNumber
 * @desc    Update account information
 * @access  Private
 */
router.put('/:accountNumber', accountController.updateAccount);

/**
 * @route   POST /api/v1/accounts/purchase
 * @desc    Process a purchase transaction
 * @access  Private
 */
router.post('/purchase', accountController.processPurchase);

module.exports = router;
