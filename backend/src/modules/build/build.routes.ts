import { Router } from 'express';
import { BuildController } from './build.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

// Public / Settings
router.get('/settings', BuildController.getSettings as any);

// User Building Operations
router.post('/requests', authenticate as any, BuildController.createRequest as any);
router.get('/my-builds', authenticate as any, BuildController.getMyBuilds as any);
router.get('/requests/:id', authenticate as any, BuildController.getBuildById as any);
router.post('/requests/:requestId/pay-consultation', authenticate as any, BuildController.payConsultation as any);
router.post('/milestones/:milestoneId/fund', authenticate as any, BuildController.fundMilestone as any);
router.post('/milestones/:milestoneId/authorize-disbursement', authenticate as any, BuildController.authorizeDisbursement as any);

// Admin Management & Approvals
router.get('/admin/requests', authenticate as any, BuildController.adminListRequests as any);
router.post('/admin/requests/:id/approve', authenticate as any, BuildController.adminApproveRequest as any);
router.patch('/admin/settings', authenticate as any, BuildController.adminUpdateSettings as any);

export const buildRoutes = router;
