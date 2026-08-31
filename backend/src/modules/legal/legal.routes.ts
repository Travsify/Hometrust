import { Router } from 'express';
import { LegalController } from './legal.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/fee-quote', LegalController.getFeeQuote);
router.post('/', authenticate as any, LegalController.create as any);
router.post('/:id/pay-wallet', authenticate as any, LegalController.payWithWallet as any);
router.get('/my-requests', authenticate as any, LegalController.getMyRequests as any);
router.get('/all', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'LEGAL_MANAGER') as any, LegalController.getAll as any);
router.get('/:idOrCode', authenticate as any, LegalController.getById);
router.post('/:id/dispatch', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'LEGAL_MANAGER', 'LAWYER') as any, LegalController.dispatchCourier as any);
router.post('/:id/confirm-delivery', LegalController.confirmDelivery as any);
router.patch('/:id/status', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'LEGAL_MANAGER') as any, LegalController.updateStatus as any);

export const legalRoutes = router;
