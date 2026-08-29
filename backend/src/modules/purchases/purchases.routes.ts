import { Router } from 'express';
import { PurchasesController } from './purchases.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate as any, PurchasesController.create as any);
router.get('/my-purchases', authenticate as any, PurchasesController.getMyPurchases as any);
router.get('/:idOrCode', authenticate as any, PurchasesController.getById);
router.post('/:id/sign', authenticate as any, PurchasesController.signAgreement as any);

export const purchaseRoutes = router;
