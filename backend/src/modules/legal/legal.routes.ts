import { Router } from 'express';
import { LegalController } from './legal.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate as any, LegalController.create as any);
router.get('/my-requests', authenticate as any, LegalController.getMyRequests as any);
router.get('/all', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'LEGAL_MANAGER') as any, LegalController.getAll as any);
router.get('/:idOrCode', authenticate as any, LegalController.getById);
router.patch('/:id/status', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'LEGAL_MANAGER') as any, LegalController.updateStatus as any);

export const legalRoutes = router;
