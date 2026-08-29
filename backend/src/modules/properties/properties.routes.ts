import { Router } from 'express';
import { PropertiesController } from './properties.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/', PropertiesController.getAll);
router.get('/:id', PropertiesController.getById);
router.post('/', authenticate as any, requireRoles('DEVELOPER', 'ADMIN', 'SUPER_ADMIN') as any, PropertiesController.create as any);

export const propertyRoutes = router;
