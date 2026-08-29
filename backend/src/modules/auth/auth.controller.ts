import { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class AuthController {
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.register(req.body);
      sendSuccess(res, result, 'Account registered successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.login(req.body);
      sendSuccess(res, result, 'Login successful');
    } catch (error: any) {
      sendError(res, error.message, 401);
    }
  }

  static async getMe(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const user = await AuthService.getCurrentUser(req.user.id);
      sendSuccess(res, user, 'User profile retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }
}
