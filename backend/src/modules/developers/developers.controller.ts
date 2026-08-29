import { Request, Response } from 'express';
import { DevelopersService } from './developers.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class DevelopersController {
  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        isVerified: req.query.isVerified !== undefined ? req.query.isVerified === 'true' : undefined,
        status: req.query.status as string,
        search: req.query.search as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };

      const result = await DevelopersService.getAll(filters);
      sendSuccess(res, result.developers, 'Developers retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const developer = await DevelopersService.getById(req.params.id as string);
      sendSuccess(res, developer, 'Developer details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  static async verify(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const { status, categories } = req.body;
      const result = await DevelopersService.verifyDeveloper(req.params.id as string, status, categories || [], req.user);
      sendSuccess(res, result, 'Developer verification status updated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const stats = await DevelopersService.getMyStats(req.user.id);
      sendSuccess(res, stats, 'Developer cockpit statistics retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyProjects(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const projects = await DevelopersService.getMyProjects(req.user.id);
      sendSuccess(res, projects, 'Developer projects retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async createProject(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const project = await DevelopersService.createProject(req.user.id, req.body);
      sendSuccess(res, project, 'Project created successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async addUnit(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const unit = await DevelopersService.addUnitToProject(req.user.id, req.params.projectId as string, req.body);
      sendSuccess(res, unit, 'Project unit added successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMySubscribers(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const subscribers = await DevelopersService.getMySubscribers(req.user.id);
      sendSuccess(res, subscribers, 'Developer subscribers retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async requestMilestoneInspection(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const inspection = await DevelopersService.requestMilestoneInspection(req.user.id, req.body);
      sendSuccess(res, inspection, 'Milestone inspection requested successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async requestPayout(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const payout = await DevelopersService.requestPayout(req.user.id, req.body);
      sendSuccess(res, payout, 'Bank payout initiated successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
