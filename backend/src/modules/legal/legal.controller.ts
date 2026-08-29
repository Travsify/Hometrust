import { Request, Response } from 'express';
import { LegalService } from './legal.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class LegalController {
  static async getFeeQuote(req: Request, res: Response): Promise<void> {
    try {
      const agreedAmount = parseFloat(req.query.agreedAmount as string) || 0;
      const quote = await LegalService.getFeeQuote(agreedAmount);
      sendSuccess(res, quote, 'Legal drafting fee quote calculated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

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
        agreedAmount: req.body.agreedAmount ? parseFloat(req.body.agreedAmount) : undefined,
        supportingDocuments: req.body.supportingDocuments,
      });
      sendSuccess(res, result, 'Legal document request created', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async payWithWallet(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await LegalService.payWithWallet(req.params.id as string, req.user.id);
      if (!result.success) {
        res.status(402).json({
          success: false,
          code: result.code,
          message: 'Insufficient dedicated account balance. Please fund your dedicated NUBAN account.',
          data: result,
        });
        return;
      }
      sendSuccess(res, result, 'Legal drafting fee paid successfully from dedicated account');
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
