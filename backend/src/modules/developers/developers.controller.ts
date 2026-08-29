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
}
