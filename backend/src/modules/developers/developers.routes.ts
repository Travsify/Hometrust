import { Router } from 'express';
import { DevelopersController } from './developers.controller';
import { authenticate, optionalAuth, requireRoles } from '../../middlewares/auth.middleware';
import { ReelsController } from '../reels/reels.controller';

const router = Router();

// Public / Directory endpoints
router.get('/', DevelopersController.getAll);

// Authenticated Developer Portal Endpoints
router.get('/my-stats', authenticate as any, DevelopersController.getMyStats as any);
router.get('/my-projects', authenticate as any, DevelopersController.getMyProjects as any);
router.post('/my-projects', authenticate as any, DevelopersController.createProject as any);
router.post('/my-projects/:projectId/units', authenticate as any, DevelopersController.addUnit as any);
router.get('/my-subscribers', authenticate as any, DevelopersController.getMySubscribers as any);
router.post('/request-milestone-inspection', authenticate as any, DevelopersController.requestMilestoneInspection as any);
router.post('/submit-milestone-proof', authenticate as any, DevelopersController.submitMilestoneProofPack as any);
router.post('/request-payout', authenticate as any, DevelopersController.requestPayout as any);
router.post('/validate-boq', authenticate as any, DevelopersController.validateBoq as any);
router.get('/jv-lands', DevelopersController.getJvLandListings as any);
router.post('/subscribers/:purchaseId/remind', authenticate as any, DevelopersController.sendBuyerReminder as any);

// Follow / Unfollow developer
router.post('/:id/follow', authenticate as any, ReelsController.toggleFollow as any);

// Specific developer detail & Admin verification
router.get('/:id', optionalAuth as any, DevelopersController.getById as any);
router.patch('/:id/verify', authenticate as any, requireRoles('ADMIN', 'SUPER_ADMIN', 'VERIFICATION_MANAGER') as any, DevelopersController.verify as any);

export const developerRoutes = router;
