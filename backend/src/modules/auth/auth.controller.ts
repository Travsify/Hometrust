import { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';
import { extractClientContext } from '../../utils/client-context';
import { NotificationsService } from '../notifications/notifications.service';

export class AuthController {
  static async sendEmailOtp(req: Request, res: Response): Promise<void> {
    try {
      const { email, purpose } = req.body;
      const result = await AuthService.sendEmailOtp(email, purpose);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async verifyEmailOtp(req: Request, res: Response): Promise<void> {
    try {
      const { email, code, purpose } = req.body;
      const result = await AuthService.verifyEmailOtp(email, code, purpose);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async sendPhoneOtp(req: Request, res: Response): Promise<void> {
    try {
      const { phone, purpose } = req.body;
      const result = await AuthService.sendPhoneOtp(phone, purpose);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async verifyPhoneOtp(req: Request, res: Response): Promise<void> {
    try {
      const { phone, code, purpose } = req.body;
      const result = await AuthService.verifyPhoneOtp(phone, code, purpose);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async verifyLogin2FA(req: Request, res: Response): Promise<void> {
    try {
      const { twoFactorToken, code } = req.body;
      const result = await AuthService.verifyLogin2FA({ twoFactorToken, code });

      const client = extractClientContext(req);
      if (result.user?.email) {
        NotificationsService.dispatchActivityEmail({
          email: result.user.email,
          userName: `${result.user.firstName || ''} ${result.user.lastName || ''}`.trim() || 'User',
          activityTitle: 'Successful 2FA Sign-In',
          activitySummary: 'A new session was authenticated for your Hometrust account via 2FA.',
          deviceName: client.deviceName,
          ipAddress: client.ipAddress,
          actionDetails: [
            { label: 'Authentication Type', value: 'Two-Factor OTP' },
            { label: 'Role', value: result.user.role || 'BUYER' },
          ],
        }).catch(() => {});
      }

      sendSuccess(res, result, 'Two-factor login successful');
    } catch (error: any) {
      sendError(res, error.message, 401);
    }
  }

  static async register(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.register(req.body);

      const client = extractClientContext(req);
      if (result.user?.email) {
        NotificationsService.dispatchActivityEmail({
          email: result.user.email,
          userName: `${result.user.firstName || ''} ${result.user.lastName || ''}`.trim() || 'User',
          activityTitle: 'New Account Registration',
          activitySummary: 'Your new Hometrust account was registered and activated successfully.',
          deviceName: client.deviceName,
          ipAddress: client.ipAddress,
          actionDetails: [
            { label: 'Role', value: result.user.role || 'BUYER' },
            { label: 'Email Verified', value: 'Yes ✅' },
          ],
        }).catch(() => {});
      }

      sendSuccess(res, result, 'Account registered successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.login(req.body);

      const client = extractClientContext(req);
      if (result.user?.email && !result.requireTwoFactor) {
        NotificationsService.dispatchActivityEmail({
          email: result.user.email,
          userName: `${result.user.firstName || ''} ${result.user.lastName || ''}`.trim() || 'User',
          activityTitle: 'Successful Sign-In Detected',
          activitySummary: 'A new sign-in to your Hometrust account was recorded.',
          deviceName: client.deviceName,
          ipAddress: client.ipAddress,
          actionDetails: [
            { label: 'Session Type', value: 'Standard Authentication' },
            { label: 'Role', value: result.user.role || 'BUYER' },
          ],
        }).catch(() => {});
      }

      sendSuccess(res, result, 'Login successful');
    } catch (error: any) {
      sendError(res, error.message, 401);
    }
  }

  static async forgotPassword(req: Request, res: Response): Promise<void> {
    try {
      const { email } = req.body;
      if (!email) {
        sendError(res, 'Email is required', 400);
        return;
      }
      const result = await AuthService.forgotPassword(email);
      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async resetPassword(req: Request, res: Response): Promise<void> {
    try {
      const { token, newPassword } = req.body;
      if (!token || !newPassword) {
        sendError(res, 'Token and new password are required', 400);
        return;
      }
      const result = await AuthService.resetPassword(token, newPassword);

      const client = extractClientContext(req);
      if (result.email) {
        NotificationsService.dispatchActivityEmail({
          email: result.email,
          userName: 'Hometrust User',
          activityTitle: 'Password Reset Successful',
          activitySummary: 'Your Hometrust account password was updated successfully.',
          deviceName: client.deviceName,
          ipAddress: client.ipAddress,
          actionDetails: [{ label: 'Action', value: 'Password Reset via Reset Link' }],
        }).catch(() => {});
      }

      sendSuccess(res, result, result.message);
    } catch (error: any) {
      sendError(res, error.message, 400);
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

  static async upgradeToDeveloper(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await AuthService.upgradeToDeveloper(req.user.id, req.body);

      const client = extractClientContext(req);
      if (req.user.email) {
        NotificationsService.dispatchActivityEmail({
          email: req.user.email,
          userName: `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim() || 'Developer',
          activityTitle: 'Developer Portal Upgrade',
          activitySummary: `Your account was upgraded to Developer profile for ${req.body.companyName || 'Corporate Developments'}.`,
          deviceName: client.deviceName,
          ipAddress: client.ipAddress,
          actionDetails: [
            { label: 'Company Name', value: req.body.companyName || 'Corporate' },
            { label: 'CAC Registration', value: req.body.cacNumber || 'Submitted' },
          ],
        }).catch(() => {});
      }

      sendSuccess(res, result, 'Account upgraded to Developer successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async changePassword(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const { currentPassword, newPassword } = req.body;
      if (!currentPassword || !newPassword) {
        sendError(res, 'Current password and new password are required', 400);
        return;
      }
      const result = await AuthService.changePassword(req.user.id, currentPassword, newPassword);

      const client = extractClientContext(req);
      if (req.user.email) {
        NotificationsService.dispatchActivityEmail({
          email: req.user.email,
          userName: `${req.user.firstName || ''} ${req.user.lastName || ''}`.trim() || 'User',
          activityTitle: 'Security Alert: Password Changed',
          activitySummary: 'Your account password was updated from the profile settings.',
          deviceName: client.deviceName,
          ipAddress: client.ipAddress,
          actionDetails: [{ label: 'Status', value: 'Password Updated' }],
        }).catch(() => {});
      }

      sendSuccess(res, result, 'Password changed successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
