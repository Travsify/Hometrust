import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../utils/prisma';
import { config } from '../../config';

export class AuthService {
  static async register(data: any) {
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });

    if (existingUser) {
      throw new Error('An account with this email already exists');
    }

    const passwordHash = await bcrypt.hash(data.password, 10);

    const user = await prisma.user.create({
      data: {
        email: data.email.toLowerCase(),
        passwordHash,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
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
    const user = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
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

    const token = this.generateToken(user);

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        role: user.role,
        developer: user.developer,
        profile: user.profile,
      },
      token,
    };
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

    const { passwordHash, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}
