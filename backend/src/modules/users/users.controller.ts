import { Request, Response } from 'express';
import { UsersService } from './users.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class UsersController {
  static async updateProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const user = await UsersService.updateProfile(req.user.id, req.body);
      sendSuccess(res, user, 'Profile updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
