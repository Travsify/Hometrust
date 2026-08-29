import { Router } from 'express';
import { VerificationsController } from './verifications.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate as any, VerificationsController.create as any);
router.get('/my-requests', authenticate as any, VerificationsController.getMyRequests as any);
router.get('/all', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER', 'LEGAL_MANAGER') as any, VerificationsController.getAll as any);
router.get('/:idOrCode', authenticate as any, VerificationsController.getById);
router.patch('/:id/status', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER', 'LEGAL_MANAGER') as any, VerificationsController.updateStatus as any);

export const verificationRoutes = router;
