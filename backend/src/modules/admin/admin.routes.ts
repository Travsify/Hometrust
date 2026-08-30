import { Router } from 'express';
import { AdminController } from './admin.controller';
import { requireAuth, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

// Restricted to Admin roles
router.use(requireAuth, requireRoles('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER', 'LEGAL_MANAGER', 'VERIFICATION_MANAGER'));

router.get('/metrics', AdminController.getMetrics);
router.get('/payments', AdminController.getPayments);
router.get('/users', AdminController.getUsers);
router.patch('/users/:id/status', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.updateUserStatus);
router.patch('/users/:id/role', requireRoles('SUPER_ADMIN'), AdminController.updateUserRole);
router.post('/users/:id/revoke-kyc', requireRoles('SUPER_ADMIN', 'ADMIN', 'VERIFICATION_MANAGER'), AdminController.revokeUserKyc);
router.post('/users/:id/verify-kyc', requireRoles('SUPER_ADMIN', 'ADMIN', 'VERIFICATION_MANAGER'), AdminController.verifyUserKyc);
router.get('/audit-logs', AdminController.getAuditLogs);

// Fee Configuration
router.get('/platform-fees', AdminController.getPlatformFees);
router.post('/platform-fees', requireRoles('SUPER_ADMIN', 'FINANCE_MANAGER'), AdminController.createPlatformFee);
router.patch('/platform-fees/:id', requireRoles('SUPER_ADMIN', 'FINANCE_MANAGER'), AdminController.updatePlatformFee);

// API Keys Management (Full CRUD for Admin & Super Admin)
router.get('/api-keys', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.getApiKeys);
router.post('/api-keys', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.addApiKey);
router.patch('/api-keys/:id', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.updateApiKey);
router.delete('/api-keys/:id', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.deleteApiKey);
router.post('/api-keys/:id/test', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.testApiKey);

// Construction Milestones & Escrow Governance
router.get('/milestones', AdminController.getMilestones);
router.post('/milestones/:id/disburse', requireRoles('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER'), AdminController.disburseMilestone);

export const adminRoutes = router;
