import { Router } from 'express';
import { AdminController } from './admin.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

// Protect all admin routes with RBAC
router.use(authenticate as any);
router.use(requireRoles('ADMIN', 'SUPER_ADMIN', 'FINANCE_MANAGER', 'VERIFICATION_MANAGER', 'LEGAL_MANAGER') as any);

router.get('/metrics', AdminController.getMetrics);
router.get('/users', AdminController.getUsers);
router.patch('/users/:id/status', requireRoles('ADMIN', 'SUPER_ADMIN') as any, AdminController.updateUserStatus as any);
router.get('/audit-logs', AdminController.getAuditLogs);
router.get('/platform-fees', AdminController.getPlatformFees);
router.patch('/platform-fees/:id', requireRoles('ADMIN', 'SUPER_ADMIN', 'FINANCE_MANAGER') as any, AdminController.updatePlatformFee as any);

export const adminRoutes = router;
