import { Router } from 'express';
import { ProjectsController } from './projects.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/', ProjectsController.getAll);
router.get('/:id', ProjectsController.getById);
router.patch('/milestones/:milestoneId', authenticate as any, requireRoles('DEVELOPER', 'ADMIN', 'SUPER_ADMIN') as any, ProjectsController.updateMilestone as any);

export const projectRoutes = router;
