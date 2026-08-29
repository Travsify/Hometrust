import { Request, Response } from 'express';
import { AdminService } from './admin.service';
import { ApiKeysService } from './api_keys.service';
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

  // Fees
  static async getPlatformFees(req: Request, res: Response): Promise<void> {
    try {
      const fees = await AdminService.getPlatformFees();
      sendSuccess(res, fees, 'Platform fee configurations retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async createPlatformFee(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const fee = await AdminService.createPlatformFee(req.body, req.user);
      sendSuccess(res, fee, 'Platform fee configuration created', 201);
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
      const fee = await AdminService.updatePlatformFee(req.params.id as string, req.body, req.user);
      sendSuccess(res, fee, 'Platform fee configuration updated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  // Dynamic API Keys Management
  static async getApiKeys(req: Request, res: Response): Promise<void> {
    try {
      const keys = await ApiKeysService.listApiKeys();
      sendSuccess(res, keys, 'API keys retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async addApiKey(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const key = await ApiKeysService.addApiKey(req.body, req.user);
      sendSuccess(res, key, 'API key added successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updateApiKey(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const key = await ApiKeysService.updateApiKey(req.params.id as string, req.body, req.user);
      sendSuccess(res, key, 'API key updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async deleteApiKey(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await ApiKeysService.deleteApiKey(req.params.id as string, req.user);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async testApiKey(req: Request, res: Response): Promise<void> {
    try {
      const result = await ApiKeysService.testApiKey(req.params.id as string);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getPayments(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        search: req.query.search as string,
        purpose: req.query.purpose as string,
        status: req.query.status as string,
      };
      const payments = await AdminService.getPaymentsLedger(filters);
      sendSuccess(res, payments, 'Payment transactions retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMilestones(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        search: req.query.search as string,
        status: req.query.status as string,
        projectId: req.query.projectId as string,
      };
      const milestones = await AdminService.getMilestonesOverview(filters);
      sendSuccess(res, milestones, 'Milestones overview retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async disburseMilestone(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await AdminService.adminDisburseMilestone(req.user, req.params.id as string, req.body);
      sendSuccess(res, result, 'Milestone status and disbursement updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
