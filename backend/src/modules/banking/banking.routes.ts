import { Router } from 'express';
import { BankingController } from './banking.controller';
import { requireAuth, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

// Buyer KYC & Account Generation
router.post('/kyc/submit', requireAuth, BankingController.submitBuyerKyc);

// Developer KYB & Corporate Account Generation
router.post('/kyb/submit', requireAuth, BankingController.submitDeveloperKyb);

// Account Lookup & Details
router.get('/my-account', requireAuth, BankingController.getMyVirtualAccount);

// Name Enquiry
router.post('/resolve-account', requireAuth, BankingController.resolveBankAccount);

// Payout / Withdrawal
router.post('/withdraw', requireAuth, BankingController.requestWithdrawal);

// Fincra Webhook Listener
router.post('/webhook', BankingController.webhook);

// Admin Audits
router.get('/admin/accounts', requireAuth, requireRoles('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER'), BankingController.listAllAccounts);
router.get('/admin/withdrawals', requireAuth, requireRoles('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER'), BankingController.listAllWithdrawals);
router.get('/admin/kyc-verifications', requireAuth, requireRoles('SUPER_ADMIN', 'ADMIN', 'LEGAL_OFFICER', 'FINANCE_MANAGER'), BankingController.listAllKyc);

export const bankingRoutes = router;
