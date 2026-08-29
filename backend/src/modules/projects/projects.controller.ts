import { Request, Response } from 'express';
import { ProjectsService } from './projects.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class ProjectsController {
  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        state: req.query.state as string,
        city: req.query.city as string,
        status: req.query.status as string,
        isVerified: req.query.isVerified !== undefined ? req.query.isVerified === 'true' : undefined,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };

      const result = await ProjectsService.getAll(filters);
      sendSuccess(res, result.projects, 'Off-plan projects retrieved', 200, {
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
      const project = await ProjectsService.getById(req.params.id as string);
      sendSuccess(res, project, 'Project details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  static async updateMilestone(req: AuthRequest, res: Response): Promise<void> {
    try {
      const result = await ProjectsService.updateMilestone(req.params.milestoneId as string, req.body);
      sendSuccess(res, result, 'Milestone updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
