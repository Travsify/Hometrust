import { Router } from 'express';
import multer from 'multer';
import { VerificationsController } from './verifications.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
});

const router = Router();

router.post('/', authenticate as any, upload.any() as any, VerificationsController.create as any);
router.get('/my-requests', authenticate as any, VerificationsController.getMyRequests as any);
router.get('/all', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER', 'LEGAL_MANAGER') as any, VerificationsController.getAll as any);
router.get('/:idOrCode', authenticate as any, VerificationsController.getById);
router.post('/:id/pay-wallet', authenticate as any, VerificationsController.payWithWallet as any);
router.post('/:id/dispatch', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER', 'LEGAL_MANAGER') as any, VerificationsController.dispatchCourier as any);
router.post('/:id/confirm-delivery', VerificationsController.confirmDelivery as any);
router.patch('/:id/status', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER', 'LEGAL_MANAGER') as any, VerificationsController.updateStatus as any);

export const verificationRoutes = router;
