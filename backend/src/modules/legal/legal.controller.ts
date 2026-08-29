import { Request, Response } from 'express';
import { LegalService } from './legal.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class LegalController {
  static async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await LegalService.create({
        userId: req.user.id,
        documentCategory: req.body.documentCategory,
        title: req.body.title,
        requirements: req.body.requirements,
        supportingDocuments: req.body.supportingDocuments,
      });
      sendSuccess(res, result, 'Legal document request created', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const result = await LegalService.getById(req.params.idOrCode as string);
      sendSuccess(res, result, 'Legal request details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  static async getMyRequests(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const requests = await LegalService.getUserRequests(req.user.id);
      sendSuccess(res, requests, 'User legal requests retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        status: req.query.status as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };
      const result = await LegalService.getAll(filters);
      sendSuccess(res, result.requests, 'Legal requests retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updateStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await LegalService.updateStatus(req.params.id as string, req.body, req.user);
      sendSuccess(res, result, 'Legal request updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
