import { Router } from 'express';
import { AdminController } from './admin.controller';
import { requireAuth, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

// Restricted to Admin roles
router.use(requireAuth, requireRoles('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER', 'LEGAL_MANAGER', 'VERIFICATION_MANAGER'));

router.get('/metrics', AdminController.getMetrics);
router.get('/users', AdminController.getUsers);
router.patch('/users/:id/status', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.updateUserStatus);
router.patch('/users/:id/role', requireRoles('SUPER_ADMIN'), AdminController.updateUserRole);
router.get('/audit-logs', AdminController.getAuditLogs);

// Fee Configuration
router.get('/platform-fees', AdminController.getPlatformFees);
router.post('/platform-fees', requireRoles('SUPER_ADMIN', 'FINANCE_MANAGER'), AdminController.createPlatformFee);
router.patch('/platform-fees/:id', requireRoles('SUPER_ADMIN', 'FINANCE_MANAGER'), AdminController.updatePlatformFee);

// API Keys Management
router.get('/api-keys', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.getApiKeys);
router.post('/api-keys', requireRoles('SUPER_ADMIN'), AdminController.addApiKey);
router.patch('/api-keys/:id', requireRoles('SUPER_ADMIN'), AdminController.updateApiKey);
router.delete('/api-keys/:id', requireRoles('SUPER_ADMIN'), AdminController.deleteApiKey);
router.post('/api-keys/:id/test', requireRoles('SUPER_ADMIN', 'ADMIN'), AdminController.testApiKey);

export const adminRoutes = router;
