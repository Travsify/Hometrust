import { Router } from 'express';
import { InspectionsController } from './inspections.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate as any, InspectionsController.create as any);
router.get('/my-inspections', authenticate as any, InspectionsController.getMyInspections as any);
router.get('/all', authenticate as any, InspectionsController.getAll);
router.patch('/:id/status', authenticate as any, InspectionsController.updateStatus);

export const inspectionRoutes = router;
