import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../utils/prisma';
import { config } from '../../config';
import { AuditService } from '../audit/audit.service';
import { ResendService } from '../notifications/resend.service';
import { TwilioService } from '../notifications/twilio.service';

export class AuthService {
  // Generate random 6-digit OTP
  private static generateOtpCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  static async sendEmailOtp(email: string, purpose: string = 'REGISTRATION_EMAIL') {
    const cleanEmail = email.toLowerCase().trim();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      throw new Error('Valid email address is required');
    }

    if (purpose === 'REGISTRATION_EMAIL') {
      const existing = await prisma.user.findUnique({ where: { email: cleanEmail } });
      if (existing) {
        throw new Error('An account with this email address already exists');
      }
    }

    const code = this.generateOtpCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    // Invalidate previous active OTPs for this identifier
    await prisma.otpVerification.deleteMany({
      where: { identifier: cleanEmail, purpose },
    });

    await prisma.otpVerification.create({
      data: {
        identifier: cleanEmail,
        code,
        channel: 'EMAIL_RESEND',
        purpose,
        expiresAt,
      },
    });

    await ResendService.sendOtpEmail(cleanEmail, code, purpose);

    return {
      message: 'Verification code sent to your email address.',
      expiresInSeconds: 600,
    };
  }

  static async verifyEmailOtp(email: string, code: string, purpose: string = 'REGISTRATION_EMAIL') {
    const cleanEmail = email.toLowerCase().trim();
    const cleanCode = code.trim();

    const otpRecord = await prisma.otpVerification.findFirst({
      where: {
        identifier: cleanEmail,
        purpose,
        isVerified: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord || otpRecord.code !== cleanCode) {
      throw new Error('Invalid or expired verification code');
    }

    const verificationToken = jwt.sign(
      { identifier: cleanEmail, purpose, type: 'OTP_VERIFIED' },
      config.jwtSecret,
      { expiresIn: '30m' }
    );

    await prisma.otpVerification.update({
      where: { id: otpRecord.id },
      data: { isVerified: true, verificationToken },
    });

    return {
      message: 'Email address verified successfully.',
      verificationToken,
    };
  }

  static async sendPhoneOtp(phone: string, purpose: string = 'REGISTRATION_PHONE') {
    const cleanPhone = phone.trim();
    if (!cleanPhone || cleanPhone.length < 10) {
      throw new Error('Valid phone number is required');
    }

    const code = this.generateOtpCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await prisma.otpVerification.deleteMany({
      where: { identifier: cleanPhone, purpose },
    });

    await prisma.otpVerification.create({
      data: {
        identifier: cleanPhone,
        code,
        channel: 'SMS_TWILIO',
        purpose,
        expiresAt,
      },
    });

    await TwilioService.sendOtpSms(cleanPhone, code, purpose);

    return {
      message: 'Verification code sent via SMS to your phone number.',
      expiresInSeconds: 600,
    };
  }

  static async verifyPhoneOtp(phone: string, code: string, purpose: string = 'REGISTRATION_PHONE') {
    const cleanPhone = phone.trim();
    const cleanCode = code.trim();

    const otpRecord = await prisma.otpVerification.findFirst({
      where: {
        identifier: cleanPhone,
        purpose,
        isVerified: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord || otpRecord.code !== cleanCode) {
      throw new Error('Invalid or expired SMS verification code');
    }

    const verificationToken = jwt.sign(
      { identifier: cleanPhone, purpose, type: 'OTP_VERIFIED' },
      config.jwtSecret,
      { expiresIn: '30m' }
    );

    await prisma.otpVerification.update({
      where: { id: otpRecord.id },
      data: { isVerified: true, verificationToken },
    });

    return {
      message: 'Phone number verified successfully.',
      verificationToken,
    };
  }

  static async register(data: any) {
    const cleanEmail = data.email.toLowerCase().trim();
    const existingUser = await prisma.user.findUnique({
      where: { email: cleanEmail },
    });

    if (existingUser) {
      throw new Error('An account with this email already exists');
    }

    const passwordHash = await bcrypt.hash(data.password, 10);

    const user = await prisma.user.create({
      data: {
        email: cleanEmail,
        passwordHash,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        isEmailVerified: true,
        role: data.role || 'BUYER',
        profile: {
          create: {},
        },
      },
      include: {
        profile: true,
      },
    });

    if (data.role === 'DEVELOPER' && data.developerInfo) {
      await prisma.developer.create({
        data: {
          userId: user.id,
          companyName: data.developerInfo.companyName,
          cacNumber: data.developerInfo.cacNumber,
          businessType: data.developerInfo.businessType || 'LTD',
          contactPerson: data.developerInfo.contactPerson || `${user.firstName} ${user.lastName}`,
          phone: data.phone || '',
          email: user.email,
          officeAddress: data.developerInfo.officeAddress,
          yearsOperating: data.developerInfo.yearsOperating || 1,
          website: data.developerInfo.website,
          about: data.developerInfo.about,
          verificationStatus: 'PENDING',
        },
      });
    }

    await AuditService.log({
      adminId: user.id,
      adminEmail: user.email,
      action: 'USER_REGISTERED',
      entityType: 'USER',
      entityId: user.id,
      details: { role: user.role, name: `${user.firstName} ${user.lastName}`, phone: user.phone },
    });

    const token = this.generateToken(user);

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        role: user.role,
      },
      token,
    };
  }

  static async login(data: { email: string; password: string }) {
    const cleanEmail = data.email.toLowerCase().trim();
    const user = await prisma.user.findUnique({
      where: { email: cleanEmail },
      include: {
        profile: true,
        developer: true,
      },
    });

    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(data.password, user.passwordHash);
    if (!isMatch) {
      throw new Error('Invalid email or password');
    }

    if (!user.isActive) {
      throw new Error('Account suspended. Please contact support.');
    }

    // Generate Login 2FA OTP
    const code = this.generateOtpCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await prisma.otpVerification.deleteMany({
      where: { identifier: cleanEmail, purpose: 'LOGIN_2FA' },
    });

    await prisma.otpVerification.create({
      data: {
        identifier: cleanEmail,
        code,
        channel: 'EMAIL_RESEND',
        purpose: 'LOGIN_2FA',
        expiresAt,
      },
    });

    // Dispatch via Resend Email
    await ResendService.sendOtpEmail(cleanEmail, code, 'LOGIN_2FA');

    // Also dispatch via Twilio SMS if phone is present
    if (user.phone) {
      await TwilioService.sendOtpSms(user.phone, code, 'LOGIN_2FA');
    }

    const twoFactorToken = jwt.sign(
      { userId: user.id, email: user.email, type: '2FA_CHALLENGE' },
      config.jwtSecret,
      { expiresIn: '10m' }
    );

    // Mask destination email (e.g. in***@travsify.com)
    const emailParts = user.email.split('@');
    const maskedName = emailParts[0].length > 2 
      ? emailParts[0].substring(0, 2) + '***' 
      : emailParts[0] + '***';
    const maskedDestination = `${maskedName}@${emailParts[1]}`;

    return {
      requires2FA: true,
      twoFactorToken,
      email: user.email,
      maskedDestination,
      message: `Security code dispatched to ${maskedDestination}`,
    };
  }

  static async verifyLogin2FA(data: { twoFactorToken: string; code: string }) {
    let decoded: any;
    try {
      decoded = jwt.verify(data.twoFactorToken, config.jwtSecret);
      if (decoded.type !== '2FA_CHALLENGE') {
        throw new Error('Invalid 2FA challenge session');
      }
    } catch (e: any) {
      throw new Error('Invalid or expired 2FA session. Please log in again.');
    }

    const otpRecord = await prisma.otpVerification.findFirst({
      where: {
        identifier: decoded.email.toLowerCase(),
        purpose: 'LOGIN_2FA',
        isVerified: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord || otpRecord.code !== data.code.trim()) {
      throw new Error('Invalid or expired 2FA security code');
    }

    // Mark OTP verified
    await prisma.otpVerification.update({
      where: { id: otpRecord.id },
      data: { isVerified: true },
    });

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: {
        profile: true,
        developer: true,
      },
    });

    if (!user) throw new Error('User not found');

    const token = this.generateToken(user);

    await AuditService.log({
      adminId: user.id,
      adminEmail: user.email,
      action: 'USER_LOGIN_2FA_SUCCESS',
      entityType: 'AUTH',
      entityId: user.id,
      details: {
        role: user.role,
        fullName: `${user.firstName} ${user.lastName}`,
        loginAt: new Date().toISOString(),
      },
    });

    const isVerified = Boolean(
      (user.profile && (user.profile.nin || user.profile.bvnVerified)) ||
      (user.developer && (user.developer.isVerified || user.developer.verificationStatus === 'VERIFIED' || user.developer.verificationStatus === 'VERIFIED_WITH_LIMITATIONS'))
    );

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        role: user.role,
        isVerified,
        developer: user.developer,
        profile: user.profile,
      },
      token,
    };
  }

  static async forgotPassword(email: string) {
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (!user) {
      // Return success to prevent user enumeration attacks
      return { message: 'If an account with that email exists, a password reset link has been dispatched.' };
    }

    const resetToken = jwt.sign(
      { id: user.id, email: user.email, type: 'PASSWORD_RESET' },
      config.jwtSecret,
      { expiresIn: '1h' }
    );

    // In production, dispatch email via SendGrid/Mailgun/Postmark:
    console.log(`[PASSWORD_RESET] Reset token for ${user.email}: ${resetToken}`);

    return {
      message: 'Password reset link dispatched.',
      resetToken: config.nodeEnv === 'development' ? resetToken : undefined,
    };
  }

  static async resetPassword(token: string, newPassword: string) {
    try {
      const decoded = jwt.verify(token, config.jwtSecret) as any;
      if (decoded.type !== 'PASSWORD_RESET') {
        throw new Error('Invalid reset token');
      }

      const passwordHash = await bcrypt.hash(newPassword, 10);
      await prisma.user.update({
        where: { id: decoded.id },
        data: { passwordHash },
      });

      return { message: 'Password updated successfully. You can now log in.' };
    } catch (err: any) {
      throw new Error(err.message || 'Invalid or expired reset token.');
    }
  }

  static generateToken(user: { id: string; email: string; role: string; firstName?: string; lastName?: string }) {
    return jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn as any }
    );
  }

  static async getCurrentUser(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        developer: {
          include: {
            directors: true,
            documents: true,
          },
        },
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const isVerified = Boolean(
      (user.profile && (user.profile.nin || user.profile.bvnVerified)) ||
      (user.developer && (user.developer.isVerified || user.developer.verificationStatus === 'VERIFIED' || user.developer.verificationStatus === 'VERIFIED_WITH_LIMITATIONS'))
    );

    const { passwordHash, ...userWithoutPassword } = user;
    return {
      ...userWithoutPassword,
      isVerified,
    };
  }

  /**
   * Upgrade an existing BUYER account to DEVELOPER.
   * Called from the in-app "Become a Developer" flow.
   * The user's existing KYC (isVerified) is honoured — no re-verification needed.
   */
  static async upgradeToDeveloper(userId: string, developerInfo: any) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('User not found');
    if (user.role === 'DEVELOPER') throw new Error('Account is already a Developer account');

    if (!developerInfo?.companyName || !developerInfo?.cacNumber || !developerInfo?.officeAddress) {
      throw new Error('Company name, CAC number, and office address are required');
    }

    // Run upgrade inside a transaction so it is atomic
    const updatedUser = await prisma.$transaction(async (tx) => {
      // 1. Update user role
      const u = await tx.user.update({
        where: { id: userId },
        data: { role: 'DEVELOPER' },
      });

      // 2. Create Developer profile
      await tx.developer.create({
        data: {
          userId,
          companyName: developerInfo.companyName,
          cacNumber: developerInfo.cacNumber,
          businessType: developerInfo.businessType || 'LTD',
          contactPerson: developerInfo.contactPerson || `${user.firstName} ${user.lastName}`,
          phone: developerInfo.phone || user.phone || '',
          email: user.email,
          officeAddress: developerInfo.officeAddress,
          yearsOperating: developerInfo.yearsOperating || 1,
          website: developerInfo.website,
          about: developerInfo.about,
          verificationStatus: 'PENDING',
        },
      });

      return u;
    });

    await AuditService.log({
      adminId: userId,
      adminEmail: user.email,
      action: 'BUYER_UPGRADED_TO_DEVELOPER',
      entityType: 'USER',
      entityId: userId,
      details: { companyName: developerInfo.companyName, cacNumber: developerInfo.cacNumber },
    });

    // Issue a new token reflecting the updated role
    const newToken = this.generateToken(updatedUser);
    const freshUser = await this.getCurrentUser(userId);

    return { user: freshUser, token: newToken };
  }

  static async changePassword(userId: string, currentPass: string, newPass: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('User not found');

    const isMatch = await bcrypt.compare(currentPass, user.passwordHash);
    if (!isMatch) throw new Error('Current password is incorrect');

    if (newPass.length < 6) {
      throw new Error('New password must be at least 6 characters long');
    }

    const passwordHash = await bcrypt.hash(newPass, 10);
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });

    await AuditService.log({
      adminId: userId,
      adminEmail: user.email,
      action: 'PASSWORD_CHANGED',
      entityType: 'USER',
      entityId: userId,
      details: { timestamp: new Date().toISOString() },
    });

    return { message: 'Password changed successfully' };
  }
}

