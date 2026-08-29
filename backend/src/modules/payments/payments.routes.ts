import { Router } from 'express';
import { PaymentsController } from './payments.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/initialize', requireAuth, PaymentsController.initialize);
router.post('/generate-virtual-account', requireAuth, PaymentsController.generateVirtualAccount);
router.get('/verify/:reference', PaymentsController.verify);
router.post('/webhook', PaymentsController.webhook);
router.get('/my-payments', requireAuth, PaymentsController.getMyPayments);
router.get('/:idOrRef', requireAuth, PaymentsController.getDetails);

export const paymentRoutes = router;
