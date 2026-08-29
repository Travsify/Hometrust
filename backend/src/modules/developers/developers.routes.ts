import { Router } from 'express';
import { DevelopersController } from './developers.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/', DevelopersController.getAll);
router.get('/:id', DevelopersController.getById);
router.patch('/:id/verify', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER') as any, DevelopersController.verify as any);

export const developerRoutes = router;
