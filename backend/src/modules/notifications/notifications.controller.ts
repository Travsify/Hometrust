import { Request, Response } from 'express';
import { NotificationsService } from './notifications.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class NotificationsController {
  static async getMyNotifications(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const notifications = await NotificationsService.getUserNotifications(req.user.id);
      sendSuccess(res, notifications, 'Notifications retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async markAsRead(req: Request, res: Response): Promise<void> {
    try {
      const result = await NotificationsService.markAsRead(req.params.id as string);
      sendSuccess(res, result, 'Notification marked as read');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async markAllAsRead(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      await NotificationsService.markAllAsRead(req.user.id);
      sendSuccess(res, { success: true }, 'All notifications marked as read');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async deleteNotification(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      await NotificationsService.deleteNotification(req.params.id as string, req.user.id);
      sendSuccess(res, { success: true }, 'Notification dismissed');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async clearAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      await NotificationsService.clearAllNotifications(req.user.id);
      sendSuccess(res, { success: true }, 'All notifications cleared');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
