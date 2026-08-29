import { Router } from 'express';
import { PurchasesController } from './purchases.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate as any, PurchasesController.create as any);
router.get('/my-purchases', authenticate as any, PurchasesController.getMyPurchases as any);
router.get('/:idOrCode', authenticate as any, PurchasesController.getById);
router.post('/:id/sign', authenticate as any, PurchasesController.signAgreement as any);
router.get('/:id/allocation-letter', authenticate as any, PurchasesController.getAllocationLetter as any);
router.get('/:id/contract-of-sale', authenticate as any, PurchasesController.getContractOfSale as any);
router.post('/:id/sign-contract', authenticate as any, PurchasesController.signContractOfSale as any);
router.get('/:id/receipts-ledger', authenticate as any, PurchasesController.getReceiptsLedger as any);
router.post('/milestones/vote', authenticate as any, PurchasesController.voteMilestoneReview as any);
router.get('/projects/:projectId/milestones', authenticate as any, PurchasesController.getProjectMilestones as any);

export const purchaseRoutes = router;
