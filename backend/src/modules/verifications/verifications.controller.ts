import { Request, Response } from 'express';
import { VerificationsService } from './verifications.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class VerificationsController {
  static async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await VerificationsService.create({
        userId: req.user.id,
        propertyName: req.body.propertyName,
        propertyAddress: req.body.propertyAddress,
        state: req.body.state,
        city: req.body.city,
        documentType: req.body.documentType,
        urgency: req.body.urgency,
        documents: req.body.documents || [],
      });
      sendSuccess(res, result, 'Verification request submitted', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const result = await VerificationsService.getById(req.params.idOrCode as string);
      sendSuccess(res, result, 'Verification details retrieved');
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
      const requests = await VerificationsService.getUserRequests(req.user.id);
      sendSuccess(res, requests, 'User verification requests retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        status: req.query.status as string,
        search: req.query.search as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };
      const result = await VerificationsService.getAll(filters);
      sendSuccess(res, result.requests, 'Verification requests retrieved', 200, {
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
      const result = await VerificationsService.updateStatus(req.params.id as string, req.body, req.user);
      sendSuccess(res, result, 'Verification request updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
