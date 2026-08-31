import { Router } from 'express';
import { InspectionsController } from './inspections.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/', authenticate as any, InspectionsController.create as any);
router.get('/my-inspections', authenticate as any, InspectionsController.getMyInspections as any);
router.get('/all', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER') as any, InspectionsController.getAll);
router.post('/:id/assign-coren', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER') as any, InspectionsController.assignCoren as any);
router.post('/:id/coren-report', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER') as any, InspectionsController.submitCorenReport as any);
router.post('/:id/geofenced-video', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'DEVELOPER', 'VERIFICATION_MANAGER') as any, InspectionsController.submitGeofencedVideo as any);
router.patch('/:id/status', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER') as any, InspectionsController.updateStatus);

export const inspectionRoutes = router;
