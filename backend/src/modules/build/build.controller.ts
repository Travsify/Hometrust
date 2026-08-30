import { Request, Response } from 'express';
import { BuildService } from './build.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class BuildController {
  static async getSettings(req: Request, res: Response): Promise<void> {
    try {
      const fees = await BuildService.getBuildFees();
      sendSuccess(res, fees, 'Build fee settings retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async createRequest(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await BuildService.createRequest({
        userId: req.user.id,
        ...req.body,
      });

      if (!result.success) {
        sendError(res, 'Insufficient Escrow Wallet balance for ₦25,000 commitment fee', 400, result);
        return;
      }

      sendSuccess(res, result, 'Custom building request submitted successfully with ₦25,000 commitment fee paid', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async payConsultation(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const requestId = req.params.requestId as string;
      const result = await BuildService.payConsultationFee(requestId, req.user.id);
      sendSuccess(res, result, 'Consultation fee paid & COREN Engineer assigned');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async fundMilestone(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const milestoneId = req.params.milestoneId as string;
      const result = await BuildService.fundMilestone(milestoneId, req.user.id);
      sendSuccess(res, result, 'Milestone funded in Escrow');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async authorizeDisbursement(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const milestoneId = req.params.milestoneId as string;
      const result = await BuildService.authorizeAndDisburseMilestone(milestoneId, req.user.id);
      sendSuccess(res, result, 'Milestone payout authorized & disbursed');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyBuilds(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const builds = await BuildService.getUserBuildRequests(req.user.id);
      sendSuccess(res, builds, 'Build projects retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getBuildById(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const id = req.params.id as string;
      const build = await BuildService.getRequestById(id, req.user.id);
      sendSuccess(res, build, 'Build details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  // --- ADMIN ENDPOINTS ---
  static async adminListRequests(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { status, search, page, limit } = req.query;
      const result = await BuildService.adminListRequests({
        status: status as string,
        search: search as string,
        page: page ? parseInt(page as string) : 1,
        limit: limit ? parseInt(limit as string) : 50,
      });
      sendSuccess(res, result, 'Admin build requests retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async adminApproveRequest(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const requestId = req.params.id as string;
      const { adminNotes } = req.body;
      const result = await BuildService.adminApproveBuildRequest(requestId, req.user, adminNotes);
      sendSuccess(res, result, 'Build proposal approved and in-app chat started with user');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async adminUpdateSettings(req: AuthRequest, res: Response): Promise<void> {
    try {
      const result = await BuildService.adminUpdateSettings(req.body);
      sendSuccess(res, result, 'Build fee settings updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
