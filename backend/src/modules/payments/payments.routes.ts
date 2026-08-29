import { Router } from 'express';
import { PaymentsController } from './payments.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/initialize', authenticate as any, PaymentsController.initialize as any);
router.get('/verify/:reference', PaymentsController.verify);
router.post('/webhook', PaymentsController.webhook);
router.get('/my-payments', authenticate as any, PaymentsController.getMyPayments as any);
router.get('/:idOrRef', authenticate as any, PaymentsController.getDetails);

export const paymentRoutes = router;
