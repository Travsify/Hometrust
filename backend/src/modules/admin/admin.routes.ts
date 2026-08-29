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
router.get('/platform-fees', AdminController.getPlatformFees);
router.patch('/platform-fees/:id', requireRoles('SUPER_ADMIN', 'FINANCE_MANAGER'), AdminController.updatePlatformFee);

export const adminRoutes = router;
