import { Request, Response } from 'express';
import { AdminService } from './admin.service';
import { AuditService } from '../audit/audit.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class AdminController {
  static async getMetrics(req: Request, res: Response): Promise<void> {
    try {
      const data = await AdminService.getDashboardMetrics();
      sendSuccess(res, data, 'Dashboard metrics retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getUsers(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        role: req.query.role as string,
        search: req.query.search as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 50,
      };
      const result = await AdminService.getUsers(filters);
      sendSuccess(res, result.users, 'Users retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updateUserStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const user = await AdminService.updateUserStatus(req.params.id as string, req.body.isActive, req.user);
      sendSuccess(res, user, 'User status updated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updateUserRole(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const user = await AdminService.updateUserRole(req.params.id as string, req.body.role, req.user);
      sendSuccess(res, user, 'User role updated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getAuditLogs(req: Request, res: Response): Promise<void> {
    try {
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
      const entityType = req.query.entityType as string;

      const result = await AuditService.getLogs(page, limit, entityType);
      sendSuccess(res, result.logs, 'Audit logs retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getPlatformFees(req: Request, res: Response): Promise<void> {
    try {
      const fees = await AdminService.getPlatformFees();
      sendSuccess(res, fees, 'Platform fee configurations retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updatePlatformFee(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const fee = await AdminService.updatePlatformFee(
        req.params.id as string,
        parseFloat(req.body.amount),
        req.body.isActive,
        req.user
      );
      sendSuccess(res, fee, 'Platform fee configuration updated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
