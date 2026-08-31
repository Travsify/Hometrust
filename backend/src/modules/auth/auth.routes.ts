import { Router } from 'express';
import { AuthController } from './auth.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router();

// OTP Email & Phone verification endpoints (Resend & Twilio)
router.post('/otp/send-email', AuthController.sendEmailOtp);
router.post('/otp/verify-email', AuthController.verifyEmailOtp);
router.post('/otp/send-phone', AuthController.sendPhoneOtp);
router.post('/otp/verify-phone', AuthController.verifyPhoneOtp);
router.post('/login-2fa/verify', AuthController.verifyLogin2FA);

router.post('/register', AuthController.register);
router.post('/login', AuthController.login);
router.post('/forgot-password', AuthController.forgotPassword);
router.post('/reset-password', AuthController.resetPassword);
router.get('/me', requireAuth, AuthController.getMe);
router.post('/upgrade-to-developer', requireAuth, AuthController.upgradeToDeveloper);
router.post('/change-password', requireAuth, AuthController.changePassword);
router.post('/pin/setup', requireAuth, AuthController.setupPin);
router.post('/pin/change', requireAuth, AuthController.changePin);
router.post('/pin/verify', requireAuth, AuthController.verifyPin);

export const authRoutes = router;
