import { Request, Response } from 'express';
import { PurchasesService } from './purchases.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class PurchasesController {
  static async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await PurchasesService.create({
        userId: req.user.id,
        propertyId: req.body.propertyId,
        projectUnitId: req.body.projectUnitId,
        paymentPlanId: req.body.paymentPlanId,
      });
      sendSuccess(res, result, 'Purchase initiated', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getById(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await PurchasesService.getById(req.params.idOrCode as string);
      if (req.user.role !== 'ADMIN' && req.user.role !== 'SUPERADMIN' && result.userId !== req.user.id) {
        sendError(res, 'Access denied: You can only view your own property purchases.', 403);
        return;
      }
      sendSuccess(res, result, 'Purchase details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  static async getMyPurchases(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const purchases = await PurchasesService.getUserPurchases(req.user.id);
      sendSuccess(res, purchases, 'Purchases retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async signAgreement(req: AuthRequest, res: Response): Promise<void> {
    try {
      const result = await PurchasesService.signAgreement(req.params.id as string, req.body.agreementDocumentUrl);
      sendSuccess(res, result, 'Agreement acknowledged and signed');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
